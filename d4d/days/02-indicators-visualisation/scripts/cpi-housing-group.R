# =====================================================================
# CPI Urban — Group 04: Housing, Water, Electricity, Gas and Other Fuels
# Comprehensive analysis, Jul 2015 – Jun 2026
# Data: cpi_urban_groupwise_tidy_monthly.csv (extracted from PBS PDF)
# =====================================================================

library(tidyverse)
library(scales)

cpi <- read_csv(here::here("data/cpi_urban_groupwise_tidy_monthly.csv"), show_col_types = FALSE)


# ---------------------------------------------------------------------
# 1. Extract the housing group and check coverage
# ---------------------------------------------------------------------

housing <- cpi |> filter(group_code == "04")

housing |> count(base_year, cmdty_code, description)

housing |> count(fiscal_year, base_year)

housing |>
  summarise(
    n_months = n(),
    first    = min(date),
    last     = max(date),
    .by      = c(base_year, description)
  ) |>
  arrange(base_year, description)


# ---------------------------------------------------------------------
# 2. Patch the one known extraction gap
#    The group aggregate row (04/00) for FY2015-16 was dropped during
#    PDF parsing. Values below are typed from the source PDF.
# ---------------------------------------------------------------------

patch <- tibble(
  date = seq(as.Date("2015-07-01"), as.Date("2016-06-01"), by = "month"),
  fiscal_year = "2015-2016",
  base_year   = "2007-08",
  group_code  = "04",
  cmdty_code  = "00",
  description = "Housing, water, Elec., Gas and other fuels",
  index_value = c(179.77, 180.31, 181.10, 182.62, 182.66, 182.69,
                  185.36, 185.49, 185.48, 187.08, 187.12, 187.17)
)

housing <- bind_rows(housing, patch) |> arrange(description, date)


# ---------------------------------------------------------------------
# 3. IMPORTANT: commodity codes are NOT stable across the base change
#    Old base (2007-08): 55 = Electricity, 56 = Gas, 57 = Kerosene Oil,
#                        58 = Firewood Whole
#    New base (2015-16): 55 = Garbage collection, 56 = Electricity charges,
#                        57 = Gas charges, 58 = Liquified Hydrocarbons,
#                        59 = Solid Fuel
#    So we must match on the DESCRIPTION, never on cmdty_code.
# ---------------------------------------------------------------------

housing <- housing |>
  mutate(
    item = case_match(
      description,
      c("Housing, water, Elec., Gas and other fuels") ~ "Housing group (all)",
      c("House Rent", "House rent") ~ "House rent",
      c("Construction Input Items", "Construcion input items") ~ "Construction input items",
      c("Construction Wage Rates", "Construction wage rates") ~ "Construction wage rates",
      c("Water Supply", "Water supply") ~ "Water supply",
      c("Electricity", "Electricity charges") ~ "Electricity",
      c("Gas", "Gas charges") ~ "Gas",
      "Kerosene Oil" ~ "Kerosene oil (old base only)",
      "Firewood Whole" ~ "Firewood (old base only)",
      "Solid Fuel" ~ "Solid fuel (new base only)",
      "Liquified Hydrocarbons" ~ "Liquified hydrocarbons (new base only)",
      "Garbage collection" ~ "Garbage collection (new base only)",
      .default = description
    )
  )

housing |> count(item, base_year)


# ---------------------------------------------------------------------
# 4. Raw levels — the two base periods plotted separately
#    (levels are NOT comparable across the break)
# ---------------------------------------------------------------------

housing |>
  filter(item == "Housing group (all)") |>
  ggplot(aes(date, index_value, colour = base_year)) +
  geom_line(linewidth = 0.9) +
  scale_x_date(date_breaks = "1 year", date_labels = "%Y") +
  labs(
    title = "Urban CPI: Housing, water, electricity, gas and other fuels",
    subtitle = "Raw published index — note the base-year break in July 2019",
    x = NULL, y = "Index", colour = "Base year"
  ) +
  theme_minimal(base_size = 12)


# ---------------------------------------------------------------------
# 5. Splice the two bases into one continuous series
#    Old-base values are rescaled so that the FY2015-16 average = 100,
#    which is exactly what the new base is anchored to.
# ---------------------------------------------------------------------

rebase_factors <- housing |>
  filter(base_year == "2007-08", fiscal_year == "2015-2016") |>
  summarise(fy1516_avg = mean(index_value), .by = item) |>
  mutate(factor = 100 / fy1516_avg)

rebase_factors

housing_spliced <- housing |>
  left_join(rebase_factors, by = join_by(item)) |>
  mutate(
    index_spliced = if_else(base_year == "2007-08", index_value * factor, index_value)
  ) |>
  filter(!is.na(index_spliced))

housing_spliced |>
  filter(item %in% c("Housing group (all)", "House rent", "Electricity",
                     "Gas", "Water supply", "Construction input items")) |>
  ggplot(aes(date, index_spliced, colour = item)) +
  geom_line(linewidth = 0.9) +
  geom_vline(xintercept = as.Date("2019-07-01"), linetype = "dashed", colour = "grey40") +
  scale_y_log10(labels = label_number()) +
  scale_x_date(date_breaks = "1 year", date_labels = "%Y") +
  labs(
    title = "Housing group components, spliced to 2015-16 = 100",
    subtitle = "Log scale. Dashed line marks the base change; splice is approximate",
    x = NULL, y = "Index (2015-16 = 100, log scale)", colour = NULL
  ) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "bottom")


# ---------------------------------------------------------------------
# 6. Year-on-year inflation
# ---------------------------------------------------------------------

housing_yoy <- housing_spliced |>
  arrange(item, date) |>
  mutate(
    index_lag12 = lag(index_spliced, 12),
    yoy = (index_spliced / index_lag12 - 1) * 100,
    .by = item
  ) |>
  filter(!is.na(yoy))

general_yoy <- cpi |>
  filter(group_code == "00", cmdty_code == "00") |>
  arrange(date) |>
  mutate(yoy_general = (index_value / lag(index_value, 12) - 1) * 100) |>
  select(date, yoy_general) |>
  filter(!is.na(yoy_general))

housing_yoy |>
  filter(item == "Housing group (all)") |>
  left_join(general_yoy, by = join_by(date)) |>
  pivot_longer(c(yoy, yoy_general), names_to = "series", values_to = "rate") |>
  mutate(series = if_else(series == "yoy", "Housing group", "General CPI")) |>
  ggplot(aes(date, rate, colour = series)) +
  geom_hline(yintercept = 0, colour = "grey60") +
  geom_line(linewidth = 0.9) +
  scale_x_date(date_breaks = "1 year", date_labels = "%Y") +
  labs(
    title = "Housing group inflation vs headline urban CPI inflation",
    x = NULL, y = "Y-o-Y %", colour = NULL
  ) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "bottom")


# ---------------------------------------------------------------------
# 7. Component inflation, faceted
# ---------------------------------------------------------------------

housing_yoy |>
  filter(item != "Housing group (all)") |>
  ggplot(aes(date, yoy)) +
  geom_hline(yintercept = 0, colour = "grey70") +
  geom_line(linewidth = 0.7, colour = "steelblue4") +
  facet_wrap(vars(item), scales = "free_y", ncol = 3) +
  scale_x_date(date_breaks = "2 years", date_labels = "%Y") +
  labs(title = "Y-o-Y inflation by housing component", x = NULL, y = "Y-o-Y %") +
  theme_minimal(base_size = 11)


# ---------------------------------------------------------------------
# 8. Summary statistics table per component
# ---------------------------------------------------------------------

housing_summary <- housing_yoy |>
  summarise(
    n_obs      = n(),
    mean_yoy   = mean(yoy),
    median_yoy = median(yoy),
    sd_yoy     = sd(yoy),
    min_yoy    = min(yoy),
    max_yoy    = max(yoy),
    .by = item
  ) |>
  arrange(desc(sd_yoy))

housing_summary

# When was each component's inflation peak?
housing_yoy |>
  slice_max(yoy, n = 1, by = item) |>
  select(item, date, yoy, index_spliced) |>
  arrange(desc(yoy))

# and its trough
housing_yoy |>
  slice_min(yoy, n = 1, by = item) |>
  select(item, date, yoy) |>
  arrange(yoy)


# ---------------------------------------------------------------------
# 9. Cumulative price change over the new-base era (Jul 2019 = 100)
# ---------------------------------------------------------------------

cumulative <- housing_spliced |>
  filter(base_year == "2015-16") |>
  arrange(item, date) |>
  mutate(rebased_2019 = index_spliced / first(index_spliced) * 100, .by = item)

cumulative |>
  slice_max(date, n = 1, by = item) |>
  mutate(total_change_pct = rebased_2019 - 100) |>
  select(item, date, total_change_pct) |>
  arrange(desc(total_change_pct))

cumulative |>
  filter(item != "Housing group (all)") |>
  ggplot(aes(date, rebased_2019, colour = item)) +
  geom_line(linewidth = 0.8) +
  geom_hline(yintercept = 100, colour = "grey60", linetype = "dashed") +
  scale_y_log10(labels = label_number()) +
  labs(
    title = "Cumulative price change since July 2019 (Jul 2019 = 100)",
    x = NULL, y = "Index, log scale", colour = NULL
  ) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "bottom")


# ---------------------------------------------------------------------
# 10. Month-on-month changes and structural jumps
#     Administered prices (gas, electricity) move in large discrete steps
# ---------------------------------------------------------------------

housing_mom <- housing_spliced |>
  arrange(item, date) |>
  mutate(mom = (index_spliced / lag(index_spliced) - 1) * 100, .by = item) |>
  filter(!is.na(mom))

# The ten biggest single-month jumps anywhere in the group
housing_mom |>
  slice_max(abs(mom), n = 10) |>
  select(item, date, index_spliced, mom) |>
  arrange(desc(abs(mom)))

# How often does each component actually change price?
housing_mom |>
  summarise(
    share_months_unchanged = mean(abs(mom) < 0.01) * 100,
    share_months_up        = mean(mom > 0.01) * 100,
    share_months_down      = mean(mom < -0.01) * 100,
    .by = item
  ) |>
  arrange(desc(share_months_unchanged))


# ---------------------------------------------------------------------
# 11. Volatility ranking — administered vs market-determined items
# ---------------------------------------------------------------------

housing_mom |>
  summarise(sd_mom = sd(mom), mean_abs_mom = mean(abs(mom)), .by = item) |>
  arrange(desc(sd_mom)) |>
  ggplot(aes(sd_mom, fct_reorder(item, sd_mom))) +
  geom_col(fill = "steelblue4") +
  labs(
    title = "Month-on-month volatility by housing component",
    x = "Standard deviation of m-o-m % change", y = NULL
  ) +
  theme_minimal(base_size = 12)


# ---------------------------------------------------------------------
# 12. Seasonality: average m-o-m change by calendar month
# ---------------------------------------------------------------------

housing_mom |>
  mutate(month_name = month(date, label = TRUE)) |>
  summarise(avg_mom = mean(mom), .by = c(item, month_name)) |>
  ggplot(aes(month_name, fct_rev(item), fill = avg_mom)) +
  geom_tile(colour = "white") +
  scale_fill_gradient2(low = "steelblue4", mid = "white", high = "firebrick", midpoint = 0) +
  labs(
    title = "Average month-on-month change by calendar month",
    x = NULL, y = NULL, fill = "Avg m-o-m %"
  ) +
  theme_minimal(base_size = 11)


# ---------------------------------------------------------------------
# 13. Fiscal-year averages and fiscal-year inflation
# ---------------------------------------------------------------------

fy_avg <- housing_spliced |>
  summarise(fy_index = mean(index_spliced), .by = c(item, fiscal_year, base_year)) |>
  arrange(item, fiscal_year) |>
  mutate(fy_inflation = (fy_index / lag(fy_index) - 1) * 100, .by = item)

fy_avg |>
  filter(item == "Housing group (all)") |>
  print(n = Inf)

fy_avg |>
  filter(!is.na(fy_inflation)) |>
  ggplot(aes(fiscal_year, fy_inflation, fill = fy_inflation > 0)) +
  geom_col() +
  facet_wrap(vars(item), scales = "free_y", ncol = 3) +
  scale_fill_manual(values = c(`TRUE` = "firebrick", `FALSE` = "steelblue4"), guide = "none") +
  labs(title = "Fiscal-year inflation by housing component", x = NULL, y = "%") +
  theme_minimal(base_size = 10) +
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5))

# Wide table for reporting
fy_avg |>
  select(item, fiscal_year, fy_inflation) |>
  pivot_wider(names_from = fiscal_year, values_from = fy_inflation) |>
  print(width = Inf)


# ---------------------------------------------------------------------
# 14. Housing versus the other eleven major groups
# ---------------------------------------------------------------------

groups_new <- cpi |>
  filter(cmdty_code == "00", base_year == "2015-16") |>
  arrange(description, date) |>
  mutate(yoy = (index_value / lag(index_value, 12) - 1) * 100, .by = description) |>
  filter(!is.na(yoy))

groups_new |>
  summarise(
    mean_yoy = mean(yoy),
    sd_yoy   = sd(yoy),
    max_yoy  = max(yoy),
    .by = description
  ) |>
  arrange(desc(mean_yoy))

groups_new |>
  mutate(is_housing = description == "Housing, water, Elec., Gas and other fuels") |>
  ggplot(aes(date, yoy, group = description, colour = is_housing, linewidth = is_housing)) +
  geom_hline(yintercept = 0, colour = "grey70") +
  geom_line() +
  scale_colour_manual(values = c(`TRUE` = "firebrick", `FALSE` = "grey75"), guide = "none") +
  scale_linewidth_manual(values = c(`TRUE` = 1.1, `FALSE` = 0.5), guide = "none") +
  labs(
    title = "Housing group inflation against all other major CPI groups",
    subtitle = "Housing highlighted in red",
    x = NULL, y = "Y-o-Y %"
  ) +
  theme_minimal(base_size = 12)


# ---------------------------------------------------------------------
# 15. Export
# ---------------------------------------------------------------------

write_csv(housing_spliced, "housing_group_spliced.csv")
write_csv(housing_yoy,     "housing_group_yoy.csv")
write_csv(fy_avg,          "housing_group_fiscal_year.csv")
