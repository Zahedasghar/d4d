# =============================================================================
# WFP Food Prices — Pakistan
# Full pipeline: basic file reads -> clean analysis frames -> maps
# Zahid Asghar | d4d
# =============================================================================
#
# STRUCTURE
# ---------
# PART A   — read the two downloaded CSVs separately and simply (no custom
#             functions, no API calls). Produces two clean tibbles: `prices`
#             and `markets`.
# PART B   — everything downstream: the four analytical decisions, the
#             dplyr 1.2.0 verb families, inflation/affordability/dispersion
#             analysis, and the choropleth that includes Jammu & Kashmir.
#
# This replaces the earlier version of the pipeline that re-hit the HDX API
# on every run. Here the two files are assumed to already be sitting in
# data/raw/ — download them once by hand from
# https://data.humdata.org/dataset/wfp-food-prices-for-pakistan
#
# STATUS: hand-verified, NOT executed (no R interpreter available at authoring
# time). Run section by section and check each audit block before proceeding.
#
# REQUIRES: dplyr >= 1.2.0, sf, rnaturalearth + rnaturalearthhires, WDI,
#           marginaleffects, ggrepel, here
# =============================================================================

library(tidyverse)
library(sf)
library(rnaturalearth)
library(rnaturalearthhires)
library(scales)
library(here)
library(ggrepel)

theme_set(theme_minimal(base_size = 12))



# =============================================================================
# PART A — read the two files separately and simply
# =============================================================================

raw_dir <- here("data", "raw")

# See what you actually have before typing filenames from memory
list.files(raw_dir, pattern = "\\.csv$")

# -----------------------------------------------------------------------------
# A1. Prices file
# -----------------------------------------------------------------------------

prices_raw <- read_csv(
  file.path(raw_dir, "wfp_food_prices_pak.csv"),
  col_types = cols(.default = col_character())
)

# Row 1 is a HXL tag row (#date, #adm1+name, ...), not a real observation
prices_raw |> slice(1)
prices_raw <- prices_raw |> slice(-1)

glimpse(prices_raw)

prices <- prices_raw |>
  mutate(
    date      = ymd(date),
    price     = as.numeric(price),
    usdprice  = as.numeric(usdprice),
    latitude  = as.numeric(latitude),
    longitude = as.numeric(longitude),
    across(where(is.character), str_squish),
    year      = year(date),
    month_num = month(date),
    month_lab = month(date, label = TRUE, abbr = TRUE)
  )

# AUDIT — must all be 0 except where genuinely missing upstream
prices |> summarise(bad_date = sum(is.na(date)), bad_price = sum(is.na(price)))

prices |> count(pricetype, priceflag, sort = TRUE)
prices |> count(unit, sort = TRUE)
prices |> count(admin1, sort = TRUE)

# -----------------------------------------------------------------------------
# A2. Markets file
# -----------------------------------------------------------------------------

markets_raw <- read_csv(
  file.path(raw_dir, "wfp_markets_pak.csv"),
  col_types = cols(.default = col_character())
)

markets_raw |> slice(1)
markets_raw <- markets_raw |> slice(-1)

glimpse(markets_raw)

markets <- markets_raw |>
  mutate(
    latitude  = as.numeric(latitude),
    longitude = as.numeric(longitude)
  )

# markets_raw MUST be one row per market_id, or any join against it multiplies rows
markets |> count(market_id) |> filter(n > 1)

# The markets file's own contribution: markets that never reported a price
markets_no_data <- markets |>
  anti_join(prices_raw, by = join_by(market_id))

markets_no_data |> select(market_id, market, admin1, admin2)

n_distinct(prices_raw$market_id)   # markets that reported at least once
nrow(markets_raw)                  # markets in the full sampling frame
nrow(markets_no_data)               # the coverage gap

# =============================================================================
# PART B — the full analysis pipeline, built on `prices` and `markets`
# =============================================================================

# -----------------------------------------------------------------------------
# B1. The four decisions
# -----------------------------------------------------------------------------

# B1.1 actual, not aggregate
prices_actual <- prices |> filter_out(priceflag != "actual")

# B1.2 retail only — never pool with wholesale
retail <- prices_actual |> filter(pricetype == "Retail")

# B1.3 normalise units
unit_to_kg <- function(unit) {
  qty  <- coalesce(parse_number(unit), 1)
  mult <- case_when(
    str_detect(unit, regex("\\bMT\\b", ignore_case = TRUE)) ~ 1000,
    str_detect(unit, regex("\\bKG\\b", ignore_case = TRUE)) ~ 1,
    str_detect(unit, regex("\\bG\\b",  ignore_case = TRUE)) ~ 1 / 1000,
    .default = NA_real_
  )
  qty * mult
}

unit_to_litre <- function(unit) {
  qty  <- coalesce(parse_number(unit), 1)
  mult <- case_when(
    str_detect(unit, regex("\\bML\\b", ignore_case = TRUE)) ~ 1 / 1000,
    str_detect(unit, regex("\\bL\\b",  ignore_case = TRUE)) ~ 1,
    .default = NA_real_
  )
  qty * mult
}

# TEST the helpers before trusting them
tibble(
  unit  = c("KG", "20 KG", "500 G", "MT", "L", "1.5 L", "Unit", "Day", "Dozen"),
  kg    = unit_to_kg(c("KG", "20 KG", "500 G", "MT", "L", "1.5 L", "Unit", "Day", "Dozen")),
  litre = unit_to_litre(c("KG", "20 KG", "500 G", "MT", "L", "1.5 L", "Unit", "Day", "Dozen"))
)

retail <- retail |>
  mutate(
    kg_equiv     = unit_to_kg(unit),
    l_equiv      = unit_to_litre(unit),
    price_per_kg = price / kg_equiv,
    price_per_l  = price / l_equiv,
    price_std    = coalesce(price_per_kg, price_per_l),
    unit_std     = case_when(
      !is.na(price_per_kg) ~ "per kg",
      !is.na(price_per_l)  ~ "per litre",
      .default = NA_character_
    )
  )

# AUDIT — inspect everything unclassified; nothing food-and-mass-based should appear
retail |> filter(is.na(unit_std)) |> count(category, commodity, unit, sort = TRUE)

# B1.4 coverage: look before averaging
retail |>
  filter(!is.na(price_std)) |>
  summarise(n_obs = n(), n_months = n_distinct(date),
            first_obs = min(date), last_obs = max(date),
            .by = c(commodity, market))

# -----------------------------------------------------------------------------
# B2. Basket + province crosswalk
# -----------------------------------------------------------------------------

basket <- retail |>
  filter_out(category == "non-food") |>
  filter(
    when_any(
      when_all(unit_std == "per kg",    category != "milk and dairy"),
      when_all(unit_std == "per litre",
               str_detect(commodity, regex("oil|ghee", ignore_case = TRUE)))
    )
  )

# ONE lookup, used for the price data, the markets file, AND the map polygons
province_lookup <- tribble(
  ~from,                                                              ~to,
  c("Punjab"),                                                        "Punjab",
  c("Sindh"),                                                         "Sindh",
  c("Khyber Pakhtunkhwa", "N.W.F.P.", "NWFP",
    "Federally Administered Tribal Areas", "F.A.T.A."),               "KP",
  c("Balochistan", "Baluchistan"),                                    "Balochistan",
  c("Islamabad", "F.C.T.", "Islamabad Capital Territory"),            "Islamabad",
  c("Azad Kashmir", "Azad Jammu and Kashmir", "AJK"),                 "Azad Jammu & Kashmir",
  c("Gilgit-Baltistan", "Northern Areas"),                            "Gilgit-Baltistan"
)

basket <- basket |>
  mutate(province = recode_values(admin1,
                                  from = province_lookup$from,
                                  to   = province_lookup$to))

# AUDIT — must be empty; if not, extend province_lookup
basket |> filter(is.na(province), !is.na(admin1)) |> count(admin1, sort = TRUE)

# Winsorise, and always show what changed
basket <- basket |>
  mutate(
    price_w = replace_when(
      price_std,
      price_std > quantile(price_std, 0.999, na.rm = TRUE)
      ~ quantile(price_std, 0.999, na.rm = TRUE)
    ),
    .by = c(commodity, unit_std)
  )

basket |>
  filter(price_std != price_w) |>
  select(date, market, commodity, price_std, price_w) |>
  arrange(desc(price_std))

# -----------------------------------------------------------------------------
# B3. Analysis frames
# -----------------------------------------------------------------------------

# market_meta is now built from the AUTHORITATIVE markets file (Part A),
# not reconstructed from whatever rows survived filtering into `basket`.
# It also carries a `reporting` flag so markets with zero observations are
# not silently lost.
market_meta <- markets |>
  mutate(province = recode_values(admin1,
                                  from = province_lookup$from,
                                  to   = province_lookup$to)) |>
  select(market_id, market, admin1, admin2, province, latitude, longitude) |>
  mutate(reporting = !market_id %in% markets_no_data$market_id)

# AUDIT — must be empty; if not, extend province_lookup
market_meta |> filter(is.na(province), !is.na(admin1)) |> count(admin1, sort = TRUE)
market_meta |> count(reporting)

national_monthly <- basket |>
  summarise(price_pkr = mean(price_w,  na.rm = TRUE),
            price_usd = mean(usdprice, na.rm = TRUE),
            n_markets = n_distinct(market),
            .by = c(date, commodity, unit_std)) |>
  complete(commodity, date) |>                  # honest gaps before any lag()
  arrange(commodity, date) |>
  mutate(mom = price_pkr / lag(price_pkr)     - 1,
         yoy = price_pkr / lag(price_pkr, 12) - 1,
         .by = commodity)

province_year <- basket |>
  summarise(price_pkr = mean(price_w, na.rm = TRUE),
            n_markets = n_distinct(market),
            .by = c(province, commodity, year))

# Pick the reference commodity FROM THE DATA
basket |> count(commodity, sort = TRUE) |> print(n = Inf)

wheat <- basket |>
  filter(str_detect(commodity, regex("^wheat flour", ignore_case = TRUE)))

wheat_market <- wheat |>
  summarise(price_pkr = mean(price_w, na.rm = TRUE), .by = c(date, market, province))

wheat_national <- national_monthly |>
  filter(str_detect(commodity, regex("^wheat flour", ignore_case = TRUE)))

# -----------------------------------------------------------------------------
# B4. Composition-safe index (matched sample, chained)
# -----------------------------------------------------------------------------

wheat_chained <- wheat_market |>
  complete(market, date) |>
  arrange(market, date) |>
  mutate(rel = price_pkr / lag(price_pkr), .by = market) |>
  summarise(gm        = exp(mean(log(rel), na.rm = TRUE)),
            n_matched = sum(!is.na(rel)),
            .by = date) |>
  arrange(date) |>
  mutate(gm    = replace_when(gm, is.na(gm) ~ 1),
         index = 100 * cumprod(gm))

wheat_market_index <- wheat_market |>
  filter(!is.na(price_pkr)) |>
  arrange(market, date) |>                      # load-bearing: first() is order-dependent
  mutate(index = 100 * price_pkr / first(price_pkr), .by = market)

# -----------------------------------------------------------------------------
# B5. Dispersion and market integration
# -----------------------------------------------------------------------------

dispersion <- wheat_market |>
  filter(!is.na(price_pkr)) |>
  summarise(n_markets = n(),
            cheapest  = min(price_pkr),
            dearest   = max(price_pkr),
            spread    = dearest - cheapest,
            cv        = sd(price_pkr) / mean(price_pkr),
            .by = date) |>
  filter(n_markets >= 5)                        # min/max widen mechanically with n

# markets_sf uses the authoritative coordinates from the markets file
markets_sf <- market_meta |>
  filter_out(is.na(latitude) | is.na(longitude)) |>
  st_as_sf(coords = c("longitude", "latitude"), crs = 4326)

dist_km <- st_distance(markets_sf) |>
  units::set_units("km") |>
  units::drop_units()
dimnames(dist_km) <- list(markets_sf$market, markets_sf$market)

pair_distance <- dist_km |>
  as_tibble(rownames = "market_a") |>
  pivot_longer(-market_a, names_to = "market_b", values_to = "distance_km") |>
  filter(market_a < market_b)

pair_gaps <- wheat_market |>
  select(date, market, price_pkr) |>
  inner_join(wheat_market |> select(date, market, price_pkr),
             by           = join_by(date),
             relationship = "many-to-many",     # intentional cross, declared
             suffix       = c("_a", "_b")) |>
  filter(market_a < market_b) |>
  mutate(gap = abs(price_pkr_a - price_pkr_b)) |>
  summarise(mean_gap = mean(gap, na.rm = TRUE), n_months = n(),
            .by = c(market_a, market_b)) |>
  filter(n_months >= 24) |>
  inner_join(pair_distance, by = join_by(market_a, market_b))

summary(lm(mean_gap ~ distance_km, data = pair_gaps))

# -----------------------------------------------------------------------------
# B6. Affordability (kg of wheat flour per daily wage)
# -----------------------------------------------------------------------------

wages <- prices_actual |>
  filter(str_detect(commodity, regex("wage", ignore_case = TRUE))) |>
  summarise(wage_pkr = mean(price, na.rm = TRUE), .by = c(date, market))

affordability <- wheat_market |>
  inner_join(wages, by = join_by(date, market)) |>
  mutate(kg_per_day_wage = wage_pkr / price_pkr)

# How much did the inner_join cost?
c(wheat_market = nrow(wheat_market), affordability = nrow(affordability))

# -----------------------------------------------------------------------------
# B7. Base map — Pakistan + Jammu & Kashmir shown as disputed / no data
# -----------------------------------------------------------------------------

pak_states <- ne_states(country = "Pakistan", returnclass = "sf") |> st_make_valid()
ind_states <- ne_states(country = "India",    returnclass = "sf") |> st_make_valid()

# INSPECT before joining — Natural Earth spellings change between releases
pak_states |> st_drop_geometry() |> pull(name) |> unique() |> sort()

pak_admin <- pak_states |>
  mutate(province = recode_values(name,
                                  from = province_lookup$from,
                                  to   = province_lookup$to),
         status   = "Administered by Pakistan") |>
  select(province, status, geometry)

# AUDIT — polygons our lookup does not recognise
pak_admin |> st_drop_geometry() |> filter(is.na(province))

jk_geometry <- ind_states |>
  filter(str_detect(name, regex("jammu|kashmir|ladakh", ignore_case = TRUE))) |>
  st_geometry() |>
  st_union()

jammu_kashmir <- st_sf(
  province = "Jammu & Kashmir",
  status   = "Disputed territory — no reporting market",
  geometry = jk_geometry
)

base_map <- bind_rows(pak_admin, jammu_kashmir) |> st_as_sf()

province_recent <- province_year |>
  filter(str_detect(commodity, regex("^wheat flour", ignore_case = TRUE)),
         year == max(year)) |>
  summarise(price_pkr = mean(price_pkr, na.rm = TRUE), .by = province)

# AUDIT 1 — must be EMPTY: data with no polygon means data falling off the map
province_recent |> anti_join(st_drop_geometry(base_map), by = join_by(province))

# AUDIT 2 — expected to have rows: these become the grey "no data" areas
base_map |> st_drop_geometry() |> anti_join(province_recent, by = join_by(province))

# -----------------------------------------------------------------------------
# B8. Plots
# -----------------------------------------------------------------------------

top_commodities <- basket |> count(commodity, sort = TRUE) |>
  slice_head(n = 4) |> pull(commodity)

p_staples <- national_monthly |>
  filter(commodity %in% top_commodities) |>
  ggplot(aes(date, price_pkr, colour = commodity)) +
  geom_line(linewidth = 0.7) +
  scale_y_continuous(labels = label_number(prefix = "Rs ")) +
  labs(title = "Nominal staple food prices, Pakistan",
       subtitle = "Retail, actual observations, mean across reporting markets",
       x = NULL, y = "Rs per kg / litre", colour = NULL,
       caption = "Source: WFP VAM Food Prices Database via HDX")

p_markets <- wheat_market |>
  ggplot(aes(date, price_pkr)) +
  geom_line(linewidth = 0.5) +
  facet_wrap(~ fct_reorder(market, price_pkr, .fun = max, .na_rm = TRUE)) +
  scale_y_continuous(labels = label_number(prefix = "Rs ")) +
  labs(title = "Wheat flour price by market", subtitle = "Panels ordered by peak price",
       x = NULL, y = NULL, caption = "Source: WFP VAM via HDX")

p_index <- wheat_market_index |>
  ggplot(aes(date, index, group = market)) +
  geom_line(linewidth = 0.4, colour = "grey65") +
  geom_line(data = wheat_chained, aes(date, index, group = 1),
            linewidth = 1, colour = "firebrick") +
  geom_hline(yintercept = 100, linetype = "dashed", colour = "grey40") +
  labs(title = "Each market indexed to its own first observation",
       subtitle = "Grey = markets; red = matched-sample chained national index",
       x = NULL, y = "Index (= 100)", caption = "Source: WFP VAM via HDX")

p_yoy <- national_monthly |>
  filter(commodity %in% top_commodities, !is.na(yoy)) |>
  ggplot(aes(date, yoy, colour = commodity)) +
  geom_hline(yintercept = 0, colour = "grey50") +
  geom_line(linewidth = 0.7) +
  scale_y_continuous(labels = label_percent()) +
  labs(title = "Year-on-year food price inflation", x = NULL, y = NULL, colour = NULL,
       caption = "Source: WFP VAM via HDX")

p_spread <- dispersion |>
  ggplot(aes(date)) +
  geom_ribbon(aes(ymin = cheapest, ymax = dearest), alpha = 0.25, fill = "steelblue") +
  geom_line(aes(y = (cheapest + dearest) / 2), linewidth = 0.6) +
  scale_y_continuous(labels = label_number(prefix = "Rs ")) +
  labs(title = "Cheapest and dearest market for wheat flour",
       subtitle = "Months with at least five reporting markets",
       x = NULL, y = "Rs per kg", caption = "Source: WFP VAM via HDX")

p_afford <- affordability |>
  summarise(kg_per_day_wage = mean(kg_per_day_wage, na.rm = TRUE), .by = date) |>
  ggplot(aes(date, kg_per_day_wage)) +
  geom_line(linewidth = 0.7) +
  geom_smooth(method = "loess", se = FALSE, linewidth = 0.5, colour = "firebrick") +
  labs(title = "How much wheat flour does a day of unskilled labour buy?",
       subtitle = "Kilograms per daily wage, mean across reporting markets",
       x = NULL, y = "kg per day's wage", caption = "Source: WFP VAM via HDX")

# --- maps -------------------------------------------------------------------

pak_crs <- "+proj=lcc +lat_1=28 +lat_2=37 +lat_0=30 +lon_0=70 +datum=WGS84 +units=m"

map_data <- base_map |> left_join(province_recent, by = join_by(province))
disputed <- map_data |> filter(str_detect(status, "Disputed"))

map_caption <- paste(
  "Source: WFP VAM Food Prices Database via HDX; boundaries from Natural Earth.",
  "The boundaries and names shown do not imply official endorsement or acceptance.",
  "The final status of Jammu & Kashmir has not been agreed by the parties.",
  sep = "\n"
)

p_map <- ggplot(map_data) +
  geom_sf(aes(fill = price_pkr), colour = "white", linewidth = 0.3) +
  geom_sf(data = disputed, aes(linetype = status),
          fill = "grey92", colour = "grey30", linewidth = 0.5) +
  geom_sf_label(data = disputed, aes(label = str_wrap(province, 12)),
                size = 3, label.size = 0, fill = alpha("white", 0.7)) +
  scale_fill_viridis_c(option = "rocket", direction = -1, na.value = "grey88",
                       labels = label_number(prefix = "Rs "),
                       name = "Wheat flour\nRs per kg") +
  scale_linetype_manual(values = c("22"), name = NULL) +
  coord_sf(crs = pak_crs) +
  labs(title = paste0("Retail wheat flour price by province, ", max(province_year$year)),
       subtitle = "Grey areas have no reporting market in the WFP sample",
       caption = map_caption) +
  theme_void(base_size = 12) +
  theme(plot.caption = element_text(hjust = 0, size = 8, colour = "grey30"),
        plot.title   = element_text(face = "bold"))

market_recent <- wheat_market |> filter(date == max(date)) |> select(market, price_pkr)

# markets_plot distinguishes reporting from non-reporting markets, using the
# `reporting` flag carried by market_meta since Part A
markets_plot <- markets_sf |>
  left_join(market_recent, by = join_by(market))

p_points <- ggplot() +
  geom_sf(data = base_map, fill = "grey96", colour = "white", linewidth = 0.3) +
  geom_sf(data = disputed, fill = "grey92", colour = "grey30",
          linewidth = 0.4, linetype = "22") +
  geom_sf(data = filter(markets_plot, !reporting),
          shape = 21, colour = "grey60", fill = "white", size = 2) +
  geom_sf(data = filter(markets_plot, reporting, !is.na(price_pkr)),
          aes(size = price_pkr, colour = price_pkr)) +
  geom_text_repel(data = filter(markets_plot, reporting, !is.na(price_pkr)),
                  aes(label = market, geometry = geometry),
                  stat = "sf_coordinates", size = 3, min.segment.length = 0,
                  segment.colour = "grey50", max.overlaps = Inf) +
  scale_colour_viridis_c(option = "rocket", direction = -1,
                         labels = label_number(prefix = "Rs ")) +
  scale_size_continuous(range = c(2, 8), guide = "none") +
  coord_sf(crs = pak_crs) +
  labs(title = "Reporting markets and latest wheat flour price",
       subtitle = "Hollow points = markets in the sampling frame with no observations",
       colour = "Rs per kg", caption = map_caption) +
  theme_void(base_size = 12) +
  theme(plot.caption = element_text(hjust = 0, size = 8, colour = "grey30"))

snapshot_years <- c(2010, 2015, 2020, max(province_year$year))

map_panel <- province_year |>
  filter(str_detect(commodity, regex("^wheat flour", ignore_case = TRUE)),
         year %in% snapshot_years) |>
  summarise(price_pkr = mean(price_pkr, na.rm = TRUE), .by = c(province, year))

p_map_facets <- base_map |>
  cross_join(tibble(year = snapshot_years)) |>   # complete polygon-year grid
  left_join(map_panel, by = join_by(province, year)) |>
  st_as_sf() |>
  ggplot() +
  geom_sf(aes(fill = price_pkr), colour = "white", linewidth = 0.2) +
  facet_wrap(~ year) +
  scale_fill_viridis_c(option = "rocket", direction = -1, na.value = "grey88",
                       labels = label_number(prefix = "Rs ")) +
  coord_sf(crs = pak_crs) +
  labs(title = "Wheat flour price by province over time", fill = "Rs per kg",
       caption = map_caption) +
  theme_void(base_size = 11) +
  theme(plot.caption = element_text(hjust = 0, size = 8, colour = "grey30"))

# -----------------------------------------------------------------------------
# B9. Export
# -----------------------------------------------------------------------------

out_fig  <- here("outputs", "figures")
out_data <- here("outputs", "data")
walk(c(out_fig, out_data), \(d) dir.create(d, recursive = TRUE, showWarnings = FALSE))

plots <- lst(p_staples, p_markets, p_index, p_yoy, p_spread, p_afford,
             p_map, p_points, p_map_facets)

iwalk(plots, \(p, nm) {
  ggsave(file.path(out_fig, paste0(nm, ".png")), p,
         width = 9, height = 6, dpi = 300, bg = "white")
})

write_csv(national_monthly, file.path(out_data, "national_monthly.csv"))
write_csv(province_year,    file.path(out_data, "province_year.csv"))
write_csv(wheat_chained,    file.path(out_data, "wheat_flour_index.csv"))
write_csv(market_meta,      file.path(out_data, "market_meta.csv"))

sessionInfo()

# =============================================================================
# END
# =============================================================================
