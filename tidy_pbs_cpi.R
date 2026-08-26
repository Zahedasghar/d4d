# PBS CPI Indices & Inflation Rates — tidy extraction
# Source: https://www.pbs.gov.pk/wp-content/uploads/2020/07/indices_and_growth_rates_historical-1.pdf
# Data hand-verified against the PDF text (2016-17 annual avg through June 2026).
# Old base (2007-08) series were discontinued by PBS after Aug 2019 -> NA from Sep 2019 onward.

library(tidyverse)
library(lubridate)

raw <- read_csv("pbs_cpi_raw.csv", show_col_types = FALSE)

tidy_cpi <- raw |>
  mutate(
    fiscal_year_avg = is.na(month),
    date = if_else(fiscal_year_avg, as.Date(NA), make_date(year, month, 1))
  ) |>
  pivot_longer(
    cols = ends_with(c("_index", "_inflation")),
    names_to = c("series", "indicator"),
    names_pattern = "^(.*)_(index|inflation)$",
    values_to = "value"
  ) |>
  mutate(
    base = if_else(series %in% c("cpi_oldbase", "wpi_oldbase"), "2007-08 (old)", "2015-16 (new)"),
    series = series |>
      str_remove("_oldbase") |>
      str_to_upper(),
    indicator = if_else(indicator == "index", "index", "inflation_yoy")
  ) |>
  filter(!is.na(value)) |>
  arrange(base, series, indicator, year, month) |>
  select(date, year, month, fiscal_year_avg, base, series, indicator, value)

write_csv(tidy_cpi, "pbs_cpi_tidy.csv")

glimpse(tidy_cpi)
count(tidy_cpi, base, series, indicator)
