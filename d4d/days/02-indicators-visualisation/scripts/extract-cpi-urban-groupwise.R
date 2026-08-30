# CPI Urban Groupwise Cumulative Indices — PDF extraction to tidy data
# Source: https://www.pbs.gov.pk/wp-content/uploads/2020/07/CpI-Urban-Groupwise-Cumulative-Indices.pdf
#
# Structure: one repeating block per fiscal year (Jul-Jun). Each block has a
# header row ("SrNo MG Cmdty Description Jul XX Aug XX ... Jun XX Jul-Jun XX-XX")
# that repeats on every page break within the block, followed by data rows:
#   SrNo  MG  Cmdty  Description  <12 monthly indices>  <Jul-Jun annual avg>
# Base year is 2007-08 through FY2018-19, then switches to 2015-16 from
# FY2019-20 onward — commodity codes/descriptions are NOT comparable across
# that break without a crosswalk (item counts go from 102 to 107, several
# commodities are renamed/replaced, e.g. "Kerosene Oil" -> "Liquified
# Hydrocarbons" group). This script keeps base_year as an explicit column
# rather than assuming continuity.
#
# NOTE: written and hand-verified against sample lines from the PDF text,
# but not executed in a live R session (no R interpreter available here).
# Run it, check the QA counts at the bottom, and report back any parsing
# gaps (e.g. dropped rows from wrapped descriptions) for a fix.

library(tidyverse)
library(pdftools)

pdf_url  <- "https://www.pbs.gov.pk/wp-content/uploads/2020/07/CpI-Urban-Groupwise-Cumulative-Indices.pdf"
pdf_path <- here::here("data/pdf/cpi_urban_groupwise.pdf")

if (!file.exists(pdf_path)) {
  download.file(pdf_url, pdf_path, mode = "wb")
}

lines <- pdf_text(pdf_path) |>
  str_split("\n") |>
  unlist() |>
  str_trim()

header_pattern <- "^SrNo\\s*MG\\s*Cmdty\\s*Description"
fy_pattern     <- "Jul-Jun\\s+(\\d{2})-(\\d{2})"
# SrNo, MG, Cmdty, Description (non-greedy), then exactly 13 decimal numbers
# (12 months + Jul-Jun average) at end of line
data_pattern   <- "^(\\d+)\\s+(\\d{2})\\s+(\\d{2})\\s+(.+?)\\s+((?:-?\\d+\\.\\d+\\s+){12}-?\\d+\\.\\d+)\\s*$"

current_fy   <- NA_character_
current_base <- NA_character_
parsed_rows  <- vector("list", length(lines))
n_parsed     <- 0L

for (ln in lines) {
  if (ln == "") next

  if (str_detect(ln, header_pattern)) {
    m <- str_match(ln, fy_pattern)
    if (!is.na(m[1, 1])) {
      yy1 <- as.integer(m[1, 2])
      start_year   <- 2000L + yy1
      current_fy   <- str_glue("{start_year}-{start_year + 1}")
      current_base <- if (start_year >= 2019) "2015-16" else "2007-08"
    }
    next
  }

  m <- str_match(ln, data_pattern)
  if (!is.na(m[1, 1])) {
    vals <- as.numeric(str_split(str_trim(m[1, 6]), "\\s+")[[1]])
    if (length(vals) == 13 && !anyNA(vals) && !is.na(current_fy)) {
      n_parsed <- n_parsed + 1L
      parsed_rows[[n_parsed]] <- tibble(
        fiscal_year = current_fy,
        base_year   = current_base,
        sr_no       = as.integer(m[1, 2]),
        group_code  = m[1, 3],
        cmdty_code  = m[1, 4],
        description = str_squish(m[1, 5]),
        month_1 = vals[1],  month_2 = vals[2],  month_3 = vals[3],
        month_4 = vals[4],  month_5 = vals[5],  month_6 = vals[6],
        month_7 = vals[7],  month_8 = vals[8],  month_9 = vals[9],
        month_10 = vals[10], month_11 = vals[11], month_12 = vals[12],
        fy_avg_index = vals[13]
      )
    }
  }
}

cpi_wide <- list_rbind(parsed_rows[seq_len(n_parsed)])

# --- QA: rows parsed per fiscal year (expect ~102 for old-base years,
# ~107 for new-base years; investigate any block that's noticeably short) ---
count(cpi_wide, fiscal_year, base_year) |> print(n = Inf)

# --- Monthly tidy long format ---
cpi_monthly <- cpi_wide |>
  select(-fy_avg_index) |>
  pivot_longer(
    cols = starts_with("month_"),
    names_to = "fy_month_col",
    values_to = "index_value"
  ) |>
  mutate(
    fy_month_index = as.integer(str_remove(fy_month_col, "month_")),
    fy_start_year  = as.integer(str_extract(fiscal_year, "^\\d{4}")),
    calendar_month = ((fy_month_index - 1L + 6L) %% 12L) + 1L,       # 1 (Jul) -> 7
    calendar_year  = fy_start_year + if_else(fy_month_index <= 6L, 0L, 1L),
    date = make_date(calendar_year, calendar_month, 1)
  ) |>
  select(
    date, fiscal_year, base_year,
    group_code, cmdty_code, description,
    index_value
  ) |>
  arrange(base_year, group_code, cmdty_code, date)

# --- Annual (Jul-Jun) average, kept separately from the monthly series ---
cpi_annual_avg <- cpi_wide |>
  select(fiscal_year, base_year, group_code, cmdty_code, description, fy_avg_index) |>
  arrange(base_year, group_code, cmdty_code, fiscal_year)

# --- Handy subsets ---
cpi_general <- cpi_monthly |>
  filter(group_code == "00", cmdty_code == "00")   # overall Urban CPI (all groups)

cpi_groups <- cpi_monthly |>
  filter(cmdty_code == "00", group_code != "00")    # the 12 major expenditure groups

write_csv(cpi_wide,        here::here("data/cpi_urban_groupwise_wide.csv"))
write_csv(cpi_monthly,     here::here("data/cpi_urban_groupwise_tidy_monthly.csv"))
write_csv(cpi_annual_avg,  here::here("data/cpi_urban_groupwise_tidy_annual.csv"))

glimpse(cpi_monthly)
