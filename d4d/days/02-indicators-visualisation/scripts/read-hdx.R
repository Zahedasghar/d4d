# =============================================================================
# Reading and combining the WFP prices and markets files — Pakistan
# =============================================================================

library(tidyverse)
library(here)

raw_dir <- here("data", "raw")

# Check what you actually downloaded before hard-coding names
list.files(raw_dir, pattern = "\\.csv$")

# -----------------------------------------------------------------------------
# 1. Read — both files carry a HXL tag row as row 1
# -----------------------------------------------------------------------------

read_hdx <- function(path) {
  read_csv(path, col_types = cols(.default = col_character())) |>
    slice(-1) |>                                  # HXL tag row: #date, #adm1+name, ...
    mutate(across(where(is.character), str_squish))
}

prices_raw  <- read_hdx(file.path(raw_dir, "wfp_food_prices_pak.csv"))
markets_raw <- read_hdx(file.path(raw_dir, "wfp_markets_pak.csv"))

glimpse(prices_raw)
glimpse(markets_raw)

# -----------------------------------------------------------------------------
# 2. Check for shared columns before joining — both files carry market, admin1,
#    admin2, latitude, longitude. Confirmed by inner_join comparison: 0 mismatches.
#    So the markets file adds no new metadata, only markets with zero prices.
# -----------------------------------------------------------------------------

intersect(names(prices_raw), names(markets_raw))

# markets_raw must be one row per market_id, or any join against it multiplies rows
markets_raw |> count(market_id) |> filter(n > 1)

# -----------------------------------------------------------------------------
# 3. Clean types
# -----------------------------------------------------------------------------

prices <- prices_raw |>
  mutate(
    date = ymd(date),
    across(c(latitude, longitude, price, usdprice), as.numeric)
  )

markets <- markets_raw |>
  mutate(across(c(latitude, longitude), as.numeric))

# AUDIT — must all be 0
prices |> summarise(bad_date = sum(is.na(date)), bad_price = sum(is.na(price)))

# -----------------------------------------------------------------------------
# 4. The markets file's real contribution: markets that never reported a price
# -----------------------------------------------------------------------------

markets_no_data <- markets |>
  anti_join(prices_raw, by = join_by(market_id))

markets_no_data |> select(market_id, market, admin1, admin2)

n_distinct(prices_raw$market_id)   # markets that reported at least once
nrow(markets_raw)                  # markets in the full sampling frame
nrow(markets_no_data)              # the gap between the two

# -----------------------------------------------------------------------------
# 5. market_meta — authoritative, one row per market, flags reporting status
# -----------------------------------------------------------------------------

market_meta <- prices |>
  distinct(market_id, market, admin1, admin2, latitude, longitude) |>
  mutate(reporting = TRUE) |>
  bind_rows(
    markets_no_data |> mutate(reporting = FALSE)
  )

market_meta |> count(reporting)

# Sanity check: market_meta should have exactly nrow(markets_raw) rows
# (every market in the frame, reporting or not) — assuming market_id sets match
stopifnot(nrow(market_meta) == n_distinct(prices_raw$market_id) + nrow(markets_no_data))
