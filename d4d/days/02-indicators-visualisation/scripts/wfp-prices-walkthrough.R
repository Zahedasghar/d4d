# =============================================================================
# WFP Food Prices — Pakistan
# A complete dplyr 1.2.0 / ggplot2 / sf walkthrough
# Zahid Asghar | d4d
# =============================================================================

library(tidyverse)      # dplyr >= 1.2.0
library(sf)
library(rnaturalearth)
library(scales)
library(rnaturalearthhires)

theme_set(theme_minimal(base_size = 12))

# -----------------------------------------------------------------------------
# 1. Read
# -----------------------------------------------------------------------------

# https://data.humdata.org/dataset/wfp-food-prices-for-pakistan is the
# dataset *landing page* (HTML) — read_csv() on that just downloads the page.
# Resolve the actual CSV resource through the HDX/CKAN API instead.
pkg <- jsonlite::fromJSON(
  "https://data.humdata.org/api/3/action/package_show?id=wfp-food-prices-for-pakistan"
)
resources <- pkg$result$resources

wfp_url <- resources$url[
  str_detect(resources$url, regex("food_prices", ignore_case = TRUE)) &
    !str_detect(resources$url, regex("qc", ignore_case = TRUE))
][1]

wfp_url

raw <- read_csv(wfp_url, col_types = cols(.default = col_character()))

glimpse(raw)

# -----------------------------------------------------------------------------
# 2. Clean
# -----------------------------------------------------------------------------

# Row 1 of every HDX file is a HXL tag row (#date, #adm1+name, ...), not data.
prices <- raw |>
  filter_out(str_starts(date, "#")) |>
  mutate(
    date      = ymd(date),
    across(c(latitude, longitude, price, usdprice), as.numeric),
    year      = year(date),
    month_num = month(date),
    month_lab = month(date, label = TRUE, abbr = TRUE)
  )

prices |> count(admin1, sort = TRUE)
prices |> count(market, sort = TRUE)
prices |> count(unit, sort = TRUE)
prices |> count(priceflag, pricetype, sort = TRUE)
prices |> count(category, sort = TRUE)

prices |> summarise(across(everything(), \(x) sum(is.na(x))))

# -----------------------------------------------------------------------------
# 3. filter_out() — say what you are dropping
# -----------------------------------------------------------------------------

# "aggregate" rows are WFP-computed roll-ups, not observed market prices.
prices_actual <- prices |>
  filter_out(priceflag != "actual")

# Fuel and daily wage sit in the same file but are not food.
prices_food <- prices_actual |>
  filter_out(category == "non-food")

# Compare: the plain-filter version has to spell out the negative case *and*
# handle NA, or it silently deletes rows with a missing category.
prices_actual |>
  filter(category != "non-food" | is.na(category)) |>
  nrow()

# -----------------------------------------------------------------------------
# 4. when_any() / when_all()
# -----------------------------------------------------------------------------

# A comparable staple basket: per-kilo food, or cooking oil per litre.
staples <- prices_food |>
  filter(
    when_any(
      when_all(unit == "KG", category != "milk and dairy"),
      when_all(unit == "L",  str_detect(commodity, regex("oil", ignore_case = TRUE)))
    )
  )

staples |> count(commodity, unit, sort = TRUE)

# -----------------------------------------------------------------------------
# 5. recode_values() / replace_values() / replace_when()
# -----------------------------------------------------------------------------

staples <- staples |>
  mutate(
    province = recode_values(
      admin1,
      "Punjab"             ~ "Punjab",
      "Sindh"              ~ "Sindh",
      "Khyber Pakhtunkhwa" ~ "KP",
      "Balochistan"        ~ "Balochistan"
    ),
    staple_group = recode_values(
      category,
      "cereals and tubers"  ~ "Cereals",
      "pulses and nuts"     ~ "Pulses",
      "oil and fats"        ~ "Oils & fats",
      "meat, fish and eggs" ~ "Protein",
      "miscellaneous food"  ~ "Other food"
    )
  )
# Winsorise implausible spikes without touching the rest of the column.
staples <- staples |>
  mutate(
    price_w = replace_when(
      price,
      price > quantile(price, 0.999, na.rm = TRUE) ~ quantile(price, 0.999, na.rm = TRUE)
    ),
    .by = c(commodity, unit)
  )

staples |>
  filter(price != price_w) |>
  select(date, market, commodity, price, price_w)

# -----------------------------------------------------------------------------
# 6. Wrangling with the core verbs
# -----------------------------------------------------------------------------

market_meta <- staples |>
  distinct(market, admin1, province, latitude, longitude)

coverage <- staples |>
  summarise(
    n_obs      = n(),
    first_obs  = min(date),
    last_obs   = max(date),
    .by = c(commodity, market)
  ) |>
  arrange(commodity, market)

national_monthly <- staples |>
  summarise(
    price_pkr = mean(price_w, na.rm = TRUE),
    price_usd = mean(usdprice, na.rm = TRUE),
    n_markets = n_distinct(market),
    .by = c(date, commodity, unit)
  ) |>
  arrange(commodity, date)

# Month-on-month and year-on-year change, per commodity.
national_monthly <- national_monthly |>
  mutate(
    mom = price_pkr / lag(price_pkr) - 1,
    yoy = price_pkr / lag(price_pkr, 12) - 1,
    .by = commodity
  )

province_year <- staples |>
  summarise(
    price_pkr = mean(price_w, na.rm = TRUE),
    price_usd = mean(usdprice, na.rm = TRUE),
    .by = c(province, commodity, year)
  )

# Wheat flour is the reference staple throughout.
wheat_flour <- staples |>
  filter(str_detect(commodity, regex("wheat flour", ignore_case = TRUE)))

wheat_flour_market <- wheat_flour |>
  summarise(price_pkr = mean(price_w, na.rm = TRUE), .by = c(date, market, province))

# Price dispersion across markets: a market-integration diagnostic.
dispersion <- wheat_flour_market |>
  summarise(
    cheapest = min(price_pkr),
    dearest  = max(price_pkr),
    spread   = dearest - cheapest,
    cv       = sd(price_pkr) / mean(price_pkr),
    .by = date
  )

# Widest-spread months.
dispersion |> slice_max(spread, n = 10)

# Index each market to its own first observation.
wheat_index <- wheat_flour_market |>
  arrange(market, date) |>
  mutate(index = 100 * price_pkr / first(price_pkr), .by = market)

wheat_wide <- wheat_flour_market |>
  pivot_wider(names_from = market, values_from = price_pkr)

# -----------------------------------------------------------------------------
# 7. ggplot2
# -----------------------------------------------------------------------------

p_staples <- national_monthly |>
  filter(commodity %in% c("Wheat flour", "Rice (coarse)", "Sugar", "Oil (cooking)")) |>
  ggplot(aes(date, price_pkr, colour = commodity)) +
  geom_line(linewidth = 0.7) +
  scale_y_continuous(labels = label_number(prefix = "Rs ")) +
  labs(
    title    = "Nominal staple food prices, Pakistan",
    subtitle = "Mean across reporting markets",
    x = NULL, y = "Price per KG / L", colour = NULL,
    caption  = "Source: WFP VAM Food Prices Database via HDX"
  )

p_markets <- wheat_flour_market |>
  ggplot(aes(date, price_pkr)) +
  geom_line(linewidth = 0.6) +
  facet_wrap(~ market) +
  scale_y_continuous(labels = label_number(prefix = "Rs ")) +
  labs(title = "Wheat flour price by market", x = NULL, y = NULL)

p_index <- wheat_index |>
  ggplot(aes(date, index, colour = market)) +
  geom_line(linewidth = 0.7) +
  geom_hline(yintercept = 100, linetype = "dashed", colour = "grey50") +
  labs(
    title = "Wheat flour, indexed to each market's first observation (= 100)",
    x = NULL, y = "Index", colour = NULL
  )

p_nominal_real <- national_monthly |>
  filter(commodity == "Wheat flour") |>
  pivot_longer(c(price_pkr, price_usd), names_to = "series", values_to = "value") |>
  mutate(series = recode_values(series,
                                "price_pkr" ~ "PKR",
                                "price_usd" ~ "USD")) |>
  ggplot(aes(date, value)) +
  geom_line(linewidth = 0.7) +
  facet_wrap(~ series, scales = "free_y") +
  labs(
    title    = "Wheat flour in local currency vs USD",
    subtitle = "The gap between the two panels is the exchange rate story",
    x = NULL, y = NULL
  )

p_season <- staples |>
  filter(commodity == "Wheat flour") |>
  ggplot(aes(month_lab, price_w)) +
  geom_boxplot(outlier.size = 0.6) +
  labs(title = "Wheat flour seasonality", x = NULL, y = "Price (Rs/KG)")

p_yoy <- national_monthly |>
  filter(commodity %in% c("Wheat flour", "Rice (coarse)", "Sugar")) |>
  ggplot(aes(date, yoy, colour = commodity)) +
  geom_line(linewidth = 0.7) +
  geom_hline(yintercept = 0, colour = "grey50") +
  scale_y_continuous(labels = label_percent()) +
  labs(title = "Year-on-year food price inflation", x = NULL, y = NULL, colour = NULL)

p_spread <- dispersion |>
  ggplot(aes(date, spread)) +
  geom_area(alpha = 0.5) +
  labs(
    title    = "Wheat flour price spread across markets",
    subtitle = "Dearest minus cheapest market, each month",
    x = NULL, y = "Rs/KG"
  )

p_heat <- province_year |>
  filter(commodity == "Wheat flour") |>
  ggplot(aes(year, province, fill = price_pkr)) +
  geom_tile(colour = "white") +
  scale_fill_viridis_c(option = "magma", direction = -1) +
  labs(title = "Wheat flour by province and year", x = NULL, y = NULL, fill = "Rs/KG")

# -----------------------------------------------------------------------------
# 8. Spatial
# -----------------------------------------------------------------------------

pak_adm1 <- ne_states(country = "Pakistan", returnclass = "sf")

# Natural Earth uses its own province spellings. Check before joining.
pak_adm1 |> st_drop_geometry() |> distinct(name) |> arrange(name)

pak_adm1 <- pak_adm1 |>
  mutate(
    province = replace_values(
      name,
      "Baluchistan"                 ~ "Balochistan",
      "N.W.F.P."                    ~ "KP",
      "Khyber Pakhtunkhwa"          ~ "KP",
      "Federally Administered Tribal Areas" ~ "KP"
    )
  )

# Anything unmatched shows up here — fix the mapping above until it is empty.
province_year |>
  distinct(province) |>
  anti_join(st_drop_geometry(pak_adm1), by = "province")

province_recent <- province_year |>
  filter(commodity == "Wheat flour", year == max(year)) |>
  summarise(price_pkr = mean(price_pkr), .by = province)

pak_choropleth <- pak_adm1 |>
  left_join(province_recent, by = "province")

p_map_choropleth <- ggplot(pak_choropleth) +
  geom_sf(aes(fill = price_pkr), colour = "white", linewidth = 0.3) +
  scale_fill_viridis_c(option = "rocket", direction = -1, na.value = "grey90") +
  labs(
    title    = "Wheat flour price by province, most recent year",
    fill     = "Rs/KG",
    caption  = "Grey = no reporting market in that province"
  ) +
  theme_void()

markets_sf <- market_meta |>
  filter_out(is.na(latitude) | is.na(longitude)) |>
  st_as_sf(coords = c("longitude", "latitude"), crs = 4326)

market_recent <- wheat_flour_market |>
  filter(date == max(date)) |>
  select(market, price_pkr)

markets_sf <- markets_sf |>
  left_join(market_recent, by = "market")

p_map_points <- ggplot() +
  geom_sf(data = pak_adm1, fill = "grey95", colour = "white", linewidth = 0.3) +
  geom_sf(data = markets_sf, aes(size = price_pkr, colour = price_pkr)) +
  geom_sf_text(data = markets_sf, aes(label = market), nudge_y = 0.6, size = 3) +
  scale_colour_viridis_c(option = "rocket", direction = -1) +
  scale_size_continuous(range = c(3, 8)) +
  labs(
    title  = "Reporting markets, latest wheat flour price",
    colour = "Rs/KG", size = "Rs/KG"
  ) +
  theme_void()

p_map_facets <- pak_adm1 |>
  left_join(
    province_year |>
      filter(commodity == "Wheat flour", year %in% c(2010, 2015, 2020, max(year))),
    by = "province",
    relationship = "many-to-many"
  ) |>
  filter_out(is.na(year)) |>
  ggplot() +
  geom_sf(aes(fill = price_pkr), colour = "white", linewidth = 0.2) +
  facet_wrap(~ year) +
  scale_fill_viridis_c(option = "rocket", direction = -1, na.value = "grey90") +
  labs(title = "Wheat flour price by province over time", fill = "Rs/KG") +
  theme_void()

# -----------------------------------------------------------------------------
# 9. Export
# -----------------------------------------------------------------------------

dir.create("outputs", showWarnings = FALSE)

walk2(
  list(p_staples, p_markets, p_index, p_nominal_real, p_season, p_yoy,
       p_spread, p_heat, p_map_choropleth, p_map_points, p_map_facets),
  c("staples", "markets", "index", "nominal_real", "season", "yoy",
    "spread", "heat", "map_choropleth", "map_points", "map_facets"),
  \(p, nm) ggsave(here::here("outputs", paste0(nm, ".png")), p,
                  width = 9, height = 6, dpi = 300)
)

write_csv(national_monthly, here::here("outputs", "national_monthly.csv"))
write_csv(province_year,    here::here("outputs", "province_year.csv"))
