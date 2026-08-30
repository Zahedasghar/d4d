# ══════════════════════════════════════════════════════════════════════════════
#   PBS TRADE JOURNAL PARSER
#   File  : parse_pbs_trade_journal.R
#   Author: Prof. Dr. Zahid Asghar, Member Economic Statistics, PBS
#   Purpose: Download the PBS "Exports by Commodities and Countries" fixed-width
#            report and convert it into tidy CSV files suitable for further
#            analytical processing.
#
#   Source file structure:
#     - Page headers repeat every ~50 lines (PAGE N, column rulers, etc.)
#     - HS-code rows:      8-digit code + commodity + UNIT + 8 numeric columns
#     - Country rows:      indented, country name + same 8 numeric columns
#     - 8 numeric columns = [Dec qty, Dec val, JulDec qty, JulDec val]
#                           for current year then previous year
#     - Values are in RUPEES THOUSANDS; "--" denotes zero / missing
#     - GRAND TOTAL row has only 4 numeric values (totals only)
# ══════════════════════════════════════════════════════════════════════════════

# ── 0. Dependencies ───────────────────────────────────────────────────────────
required <- c("tidyverse", "glue")
missing  <- setdiff(required, rownames(installed.packages()))
if (length(missing)) install.packages(missing, repos = "https://cloud.r-project.org")

library(tidyverse)
library(glue)

options(scipen = 999)


# ── 1. Download the source file ───────────────────────────────────────────────
PBS_URL <- paste0(
  "https://www.pbs.gov.pk/wp-content/uploads/2020/07/",
  "exports_commodities_and_countries_2018july_december-1.txt"
)

LOCAL_FILE <- "pbs_exports_2018_julydec.txt"

if (!file.exists(LOCAL_FILE)) {
  message("Downloading PBS extract ...")
  download.file(PBS_URL, LOCAL_FILE, mode = "wb", quiet = TRUE)
}

raw <- read_lines(LOCAL_FILE)
message(glue("  Raw lines read : {length(raw)}"))


# ── 2. Strip page headers and blank lines ─────────────────────────────────────
header_patterns <- c(
  "^\\s*PAGE\\s+\\d+",
  "EXPORTS BY COMMODITIES",
  "^\\s*\\*{4,}",
  "^\\s*HSCODE",
  "^\\s*QUANTITY\\s+VALUE",
  "PAKISTAN\\s*$",
  "RUPEES IN THOUSANDS",
  "2 0 1 8",
  "2 0 1 7",
  "^\\s*$"
)

skip_regex  <- paste(header_patterns, collapse = "|")
data_lines  <- raw[!str_detect(raw, skip_regex)]

# Drop the GRAND TOTAL row — doesn't fit the 8-column schema
data_lines <- data_lines[!str_detect(data_lines, "G R A N D")]

message(glue("  Data lines     : {length(data_lines)}"))


# ── 3. Line-level parser ──────────────────────────────────────────────────────
VAL_COLS <- c(
  "qty_cur_dec",  "val_cur_dec",
  "qty_cur_cum",  "val_cur_cum",
  "qty_prev_dec", "val_prev_dec",
  "qty_prev_cum", "val_prev_cum"
)

parse_line <- function(line) {

  tokens <- str_split(str_trim(line), "\\s+")[[1]]
  n      <- length(tokens)
  if (n < 9) return(NULL)

  # Last 8 tokens are the numeric fields; convert "--" to NA
  data_tok <- tokens[(n - 7):n]
  vals     <- suppressWarnings(
    as.numeric(ifelse(data_tok == "--", NA_character_, data_tok))
  )

  descriptor <- tokens[1:(n - 8)]
  is_hs      <- str_detect(descriptor[1], "^\\d{8}$")

  if (is_hs) {
    hs_code   <- descriptor[1]
    rest      <- descriptor[-1]
    unit      <- tail(rest, 1)                    # last descriptor token
    commodity <- str_c(head(rest, -1), collapse = " ")
    tibble(
      row_type = "hs",
      hs_code, commodity, unit,
      country  = NA_character_,
      !!!setNames(as.list(vals), VAL_COLS)
    )
  } else {
    country <- str_c(descriptor, collapse = " ")
    tibble(
      row_type = "country",
      hs_code  = NA_character_,
      commodity = NA_character_,
      unit      = NA_character_,
      country,
      !!!setNames(as.list(vals), VAL_COLS)
    )
  }
}


# ── 4. Apply parser and carry HS context forward ──────────────────────────────
parsed_long <- map_dfr(data_lines, parse_line)

df <- parsed_long |>
  mutate(
    hs_code   = if_else(row_type == "hs", hs_code,   NA_character_),
    commodity = if_else(row_type == "hs", commodity, NA_character_),
    unit      = if_else(row_type == "hs", unit,      NA_character_)
  ) |>
  fill(hs_code, commodity, unit, .direction = "down") |>
  filter(row_type == "country") |>
  select(-row_type)

message(glue(
  "  Parsed rows    : {nrow(df)}",
  "  HS-8 codes     : {n_distinct(df$hs_code)}",
  "  Destinations   : {n_distinct(df$country)}",
  .sep = "\n"
))


# ── 5. Cross-check against published GRAND TOTAL ──────────────────────────────
published_total <- 1446166321   # Rs '000, as printed in the report
parsed_total    <- sum(df$val_cur_cum, na.rm = TRUE)

message(glue(
  "\n  Reconciliation (Rs '000):",
  "    Published : {format(published_total, big.mark = ',')}",
  "    Parsed    : {format(parsed_total,    big.mark = ',')}",
  "    Diff (%)  : {round((parsed_total - published_total) / published_total * 100, 3)} %",
  .sep = "\n"
))


# ── 6. Derive monthly series and convert to USD millions ──────────────────────
# Period-average exchange rate for Jul-Dec 2018 (SBP). Replace with month-end
# vector if you have the full series.
PKR_USD <- 136.0

df_out <- df |>
  mutate(
    # Jul–Nov = Cumulative − December
    val_cur_julnov = val_cur_cum - coalesce(val_cur_dec, 0),
    # Rs thousands → USD millions
    val_cur_dec_musd    = val_cur_dec     * 1e3 / PKR_USD / 1e6,
    val_cur_julnov_musd = val_cur_julnov  * 1e3 / PKR_USD / 1e6,
    val_cur_cum_musd    = val_cur_cum     * 1e3 / PKR_USD / 1e6,
    avg_monthly_musd    = val_cur_julnov_musd / 5
  )


# ── 7. Write outputs ──────────────────────────────────────────────────────────
write_csv(df_out, "pbs_exports_tidy.csv")

# Country-level monthly rollup (all HS codes combined)
monthly_by_country <- df_out |>
  group_by(country) |>
  summarise(
    n_hs_codes       = n_distinct(hs_code),
    dec_musd         = sum(val_cur_dec_musd,    na.rm = TRUE),
    julnov_musd      = sum(val_cur_julnov_musd, na.rm = TRUE),
    cum_musd         = sum(val_cur_cum_musd,    na.rm = TRUE),
    avg_monthly_musd = sum(avg_monthly_musd,    na.rm = TRUE),
    .groups = "drop"
  ) |>
  arrange(desc(cum_musd))

write_csv(monthly_by_country, "pbs_exports_by_country_monthly.csv")

# HS-2 chapter rollup
monthly_by_hs2 <- df_out |>
  mutate(hs2 = str_sub(hs_code, 1, 2)) |>
  group_by(hs2) |>
  summarise(
    dec_musd         = sum(val_cur_dec_musd,    na.rm = TRUE),
    julnov_musd      = sum(val_cur_julnov_musd, na.rm = TRUE),
    cum_musd         = sum(val_cur_cum_musd,    na.rm = TRUE),
    avg_monthly_musd = sum(avg_monthly_musd,    na.rm = TRUE),
    .groups = "drop"
  ) |>
  arrange(desc(cum_musd))

write_csv(monthly_by_hs2, "pbs_exports_by_hs2_monthly.csv")


# ── 8. Console summary ────────────────────────────────────────────────────────
cat("\n─────────────────────────────────────────────────────────────\n")
cat("  PBS EXPORTS — JULY-DECEMBER 2018 (Current Year = 2018-19)\n")
cat("─────────────────────────────────────────────────────────────\n")

cat(glue(
  "  December 2018 exports   : USD {format(round(sum(df_out$val_cur_dec_musd,    na.rm = TRUE), 0), big.mark = ',')} million",
  "  Jul-Dec 2018 cumulative : USD {format(round(sum(df_out$val_cur_cum_musd,    na.rm = TRUE), 0), big.mark = ',')} million",
  "  Avg monthly (Jul-Nov)   : USD {format(round(sum(df_out$avg_monthly_musd,    na.rm = TRUE), 0), big.mark = ',')} million",
  .sep = "\n"
), "\n\n")

cat("Top 10 destinations, cumulative Jul-Dec 2018 (USD million):\n")
print(
  monthly_by_country |>
    slice_head(n = 10) |>
    mutate(across(where(is.numeric), ~ round(.x, 1))),
  n = 10
)

cat("\nTop 10 HS-2 chapters, cumulative Jul-Dec 2018 (USD million):\n")
print(
  monthly_by_hs2 |>
    slice_head(n = 10) |>
    mutate(across(where(is.numeric), ~ round(.x, 1))),
  n = 10
)

cat("\n Files written:\n",
    " - pbs_exports_tidy.csv               (row-level, HS8 x country)\n",
    " - pbs_exports_by_country_monthly.csv (country rollup)\n",
    " - pbs_exports_by_hs2_monthly.csv     (HS-2 rollup)\n")
