# PBS CPI Indices & Inflation Rates — tidy extraction
# Source: https://www.pbs.gov.pk/wp-content/uploads/2020/07/indices_and_growth_rates_historical-1.pdf
# Old base (2007-08) series were discontinued by PBS after 2019 -> NA from then onward.

library(tidyverse)
library(pdftools)

# ---- Download PDF ----------------------------------------------------------
url <- "https://www.pbs.gov.pk/wp-content/uploads/2020/07/indices_and_growth_rates_historical-1.pdf"
destfile <- tempfile(fileext = ".pdf")
download.file(url, destfile, mode = "wb")

info <- pdf_info(destfile)
txt <- pdf_text(destfile)

# ---- Parsing helpers --------------------------------------------------------
# Data rows always start with a 4-digit year (e.g. "2017" or "2016-17").
parse_page <- function(page_text) {
  lines <- strsplit(page_text, "\n")[[1]]
  lines <- lines[str_detect(lines, "^\\s*\\d{4}")]
  map(lines, ~ str_split(str_trim(.x), "\\s+")[[1]])
}

# Rows have 6, 7, or 8 fields depending on whether the row is a monthly
# observation or an annual base-year average, and whether the discontinued
# 2007-08 old-base columns are present on that page.
to_df <- function(rows) {
  map_dfr(rows, function(r) {
    n <- length(r)
    if (n == 8) {
      tibble(year = r[1], month = r[2], national = r[3], ucpi = r[4],
             rpi = r[5], wpi = r[6], cpi_old_base = r[7], wpi_old_base = r[8])
    } else if (n == 7) {
      tibble(year = r[1], month = NA_character_, national = r[2], ucpi = r[3],
             rpi = r[4], wpi = r[5], cpi_old_base = r[6], wpi_old_base = r[7])
    } else if (n == 6) {
      tibble(year = r[1], month = r[2], national = r[3], ucpi = r[4],
             rpi = r[5], wpi = r[6], cpi_old_base = NA_character_, wpi_old_base = NA_character_)
    }
  })
}

# ---- Table 1: Historical Indices (pages 1-4) --------------------------------
idx_rows <- map(txt[1:4], parse_page) |> flatten()

indices <- to_df(idx_rows) |>
  mutate(across(-year, as.numeric), month = as.integer(month)) |>
  mutate(period = ifelse(is.na(month), year, paste0(year, "-", str_pad(month, 2, pad = "0")))) |>
  relocate(period)

# ---- Table 2: Historical Inflation Rate, Y-oY (pages 5-8) -------------------
growth_rows <- map(txt[5:8], parse_page) |> flatten()

growth <- to_df(growth_rows) |>
  rename(national_yoy = national, ucpi_yoy = ucpi, rpi_yoy = rpi, wpi_yoy = wpi,
         cpi_old_base_yoy = cpi_old_base, wpi_old_base_yoy = wpi_old_base) |>
  mutate(across(-year, as.numeric), month = as.integer(month)) |>
  mutate(period = ifelse(is.na(month), year, paste0(year, "-", str_pad(month, 2, pad = "0")))) |>
  relocate(period)

# ---- Save --------------------------------------------------------------------
out_dir <- "d4d/days/02-indicators-visualisation/data"
if (!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE)

write_csv(indices, file.path(out_dir, "pbs-cpi-historical-indices.csv"))
write_csv(growth, file.path(out_dir, "pbs-cpi-historical-inflation-yoy.csv"))
