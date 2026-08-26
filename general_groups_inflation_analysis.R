# =====================================================================
# Urban CPI — General index and all 12 major groups
# Comprehensive inflation analysis, Jul 2015 – Jun 2026
# Data: cpi_urban_groupwise_tidy_monthly.csv (extracted from PBS PDF)
# =====================================================================

library(tidyverse)
library(scales)

cpi <- read_csv("cpi_urban_groupwise_tidy_monthly.csv", show_col_types = FALSE)


# ---------------------------------------------------------------------
# 1. Keep only the aggregate rows: General plus the 12 major groups
# ---------------------------------------------------------------------

groups <- cpi |> filter(cmdty_code == "00")

groups |> count(base_year, group_code, description)

groups |>
  summarise(n_months = n(), first = min(date), last = max(date),
            .by = c(base_year, group_code, description)) |>
  arrange(base_year, group_code)

# Which group-years are missing? (13 groups x 12 months = 156 expected)
groups |>
  count(fiscal_year, base_year) |>
  mutate(expected = 13 * 12, shortfall = expected - n)


# ---------------------------------------------------------------------
# 2. Patch the known extraction gaps
#    Three group-aggregate blocks were dropped by the PDF parser.
#    Values below are typed from the source PDF.
#    Still missing and NOT patchable: group 05 for FY2025-26.
# ---------------------------------------------------------------------

patch <- bind_rows(
  tibble(
    fiscal_year = "2015-2016", base_year = "2007-08",
    group_code = "04", description = "Housing, water, Elec., Gas and other fuels",
    index_value = c(179.77, 180.31, 181.10, 182.62, 182.66, 182.69,
                    185.36, 185.49, 185.48, 187.08, 187.12, 187.17)
  ),
  tibble(
    fiscal_year = "2015-2016", base_year = "2007-08",
    group_code = "05", description = "Furnishing and household equipment maintenance",
    index_value = c(213.53, 214.22, 214.88, 215.49, 215.78, 216.78,
                    217.23, 218.83, 219.50, 220.09, 220.71, 221.48)
  ),
  tibble(
    fiscal_year = "2021-2022", base_year = "2015-16",
    group_code = "05", description = "Furnishing and household equipment maintenance",
    index_value = c(142.29, 142.88, 144.03, 144.99, 147.02, 149.61,
                    150.95, 154.01, 155.73, 158.29, 161.43, 165.68)
  )
) |>
  mutate(
    cmdty_code = "00",
    fy_start   = as.integer(str_sub(fiscal_year, 1, 4)),
    date       = rep(seq(as.Date("2000-07-01"), by = "month", length.out = 12), 3),
    date       = make_date(fy_start + if_else(month(date) >= 7, 0L, 1L), month(date), 1)
  ) |>
  select(date, fiscal_year, base_year, group_code, cmdty_code, description, index_value)

groups <- bind_rows(groups, patch) |> arrange(group_code, date)

groups |> count(fiscal_year, base_year) |> mutate(shortfall = 156 - n)


# ---------------------------------------------------------------------
# 3. Standardise group labels across the two bases and set an order
#    Group names are stable here (unlike commodity codes inside groups),
#    so group_code is a safe key at this level.
# ---------------------------------------------------------------------

groups <- groups |>
  mutate(
    group = case_match(
      group_code,
      "00" ~ "General",
      "01" ~ "Food & non-alcoholic bev.",
      "02" ~ "Alcohol & tobacco",
      "03" ~ "Clothing & footwear",
      "04" ~ "Housing, water, elec., gas",
      "05" ~ "Furnishing & household eq.",
      "06" ~ "Health",
      "07" ~ "Transport",
      "08" ~ "Communication",
      "09" ~ "Recreation & culture",
      "10" ~ "Education",
      "11" ~ "Restaurants & hotels",
      "12" ~ "Misc. goods & services"
    )
  )

groups |> count(group, base_year)


# ---------------------------------------------------------------------
# 4. Splice the two base periods into one continuous series
#    Old-base values are rescaled so FY2015-16 average = 100, which is
#    exactly the anchor of the new base. Approximate: the basket changed
#    too, so treat pre-2019 spliced levels as indicative.
# ---------------------------------------------------------------------

rebase_factors <- groups |>
  filter(base_year == "2007-08", fiscal_year == "2015-2016") |>
  summarise(fy1516_avg = mean(index_value), .by = group) |>
  mutate(factor = 100 / fy1516_avg)

rebase_factors

spliced <- groups |>
  left_join(rebase_factors, by = join_by(group)) |>
  mutate(index = if_else(base_year == "2007-08", index_value * factor, index_value))


# ---------------------------------------------------------------------
# 5. Long-run levels
# ---------------------------------------------------------------------

spliced |>
  ggplot(aes(date, index, group = group,
             colour = group == "General", linewidth = group == "General")) +
  geom_vline(xintercept = as.Date("2019-07-01"), linetype = "dashed", colour = "grey50") +
  geom_line() +
  scale_colour_manual(values = c(`TRUE` = "firebrick", `FALSE` = "grey75"), guide = "none") +
  scale_linewidth_manual(values = c(`TRUE` = 1.2, `FALSE` = 0.5), guide = "none") +
  scale_y_log10(labels = label_number()) +
  scale_x_date(date_breaks = "1 year", date_labels = "%Y") +
  labs(title = "Urban CPI by major group, spliced to 2015-16 = 100",
       subtitle = "General index in red; dashed line marks the base change",
       x = NULL, y = "Index (log scale)") +
  theme_minimal(base_size = 12)


# ---------------------------------------------------------------------
# 6. Year-on-year inflation for every group
# ---------------------------------------------------------------------

yoy <- spliced |>
  arrange(group, date) |>
  mutate(yoy = (index / lag(index, 12) - 1) * 100, .by = group) |>
  filter(!is.na(yoy))

yoy |>
  filter(group == "General") |>
  ggplot(aes(date, yoy)) +
  geom_hline(yintercept = 0, colour = "grey60") +
  geom_line(linewidth = 1, colour = "firebrick") +
  scale_x_date(date_breaks = "1 year", date_labels = "%Y") +
  labs(title = "Headline urban CPI inflation", x = NULL, y = "Y-o-Y %") +
  theme_minimal(base_size = 12)

# Every group as a small multiple, with the General line behind for reference
general_line <- yoy |> filter(group == "General") |> select(date, general = yoy)

yoy |>
  filter(group != "General") |>
  left_join(general_line, by = join_by(date)) |>
  ggplot(aes(date)) +
  geom_hline(yintercept = 0, colour = "grey80") +
  geom_line(aes(y = general), colour = "grey70", linewidth = 0.5) +
  geom_line(aes(y = yoy), colour = "steelblue4", linewidth = 0.8) +
  facet_wrap(vars(group), ncol = 3) +
  scale_x_date(date_breaks = "2 years", date_labels = "%Y") +
  labs(title = "Group inflation (blue) against headline inflation (grey)",
       x = NULL, y = "Y-o-Y %") +
  theme_minimal(base_size = 11)


# ---------------------------------------------------------------------
# 7. League table over the new-base era
# ---------------------------------------------------------------------

league <- yoy |>
  filter(base_year == "2015-16") |>
  summarise(
    n_obs      = n(),
    mean_yoy   = mean(yoy),
    median_yoy = median(yoy),
    sd_yoy     = sd(yoy),
    min_yoy    = min(yoy),
    max_yoy    = max(yoy),
    .by = group
  ) |>
  arrange(desc(mean_yoy))

league

# Cumulative price change since July 2019
spliced |>
  filter(base_year == "2015-16") |>
  arrange(group, date) |>
  mutate(rebased = index / first(index) * 100, .by = group) |>
  slice_max(date, n = 1, by = group) |>
  mutate(cumulative_pct = rebased - 100) |>
  select(group, date, cumulative_pct) |>
  arrange(desc(cumulative_pct))

# When did each group peak, and where was headline at that moment?
yoy |>
  filter(base_year == "2015-16") |>
  slice_max(yoy, n = 1, by = group) |>
  select(group, date, peak_yoy = yoy) |>
  left_join(general_line, by = join_by(date)) |>
  arrange(date)


# ---------------------------------------------------------------------
# 8. How broad-based is inflation? Cross-group dispersion each month
#    Narrow IQR = everything rising together. Wide IQR = a few groups
#    doing the work.
# ---------------------------------------------------------------------

dispersion <- yoy |>
  filter(group != "General") |>
  summarise(
    median_group = median(yoy),
    q1           = quantile(yoy, 0.25),
    q3           = quantile(yoy, 0.75),
    lowest       = min(yoy),
    highest      = max(yoy),
    n_groups     = n(),
    .by = date
  ) |>
  mutate(iqr = q3 - q1) |>
  left_join(general_line, by = join_by(date))

dispersion |> print(n = Inf)

dispersion |>
  ggplot(aes(date)) +
  geom_ribbon(aes(ymin = lowest, ymax = highest), fill = "grey88") +
  geom_ribbon(aes(ymin = q1, ymax = q3), fill = "grey70") +
  geom_line(aes(y = median_group), linewidth = 0.8, colour = "grey25") +
  geom_line(aes(y = general), linewidth = 1, colour = "firebrick") +
  geom_hline(yintercept = 0, colour = "grey50") +
  labs(title = "Spread of inflation across the 12 major groups",
       subtitle = "Light band = full range, dark band = interquartile range, red = headline",
       x = NULL, y = "Y-o-Y %") +
  theme_minimal(base_size = 12)

# Share of groups running above headline each month
yoy |>
  filter(group != "General") |>
  left_join(general_line, by = join_by(date)) |>
  summarise(share_above_headline = mean(yoy > general) * 100, .by = date) |>
  ggplot(aes(date, share_above_headline)) +
  geom_hline(yintercept = 50, linetype = "dashed", colour = "grey50") +
  geom_line(linewidth = 0.8, colour = "steelblue4") +
  labs(title = "Share of major groups inflating faster than headline",
       x = NULL, y = "% of groups") +
  theme_minimal(base_size = 12)


# ---------------------------------------------------------------------
# 9. Relative prices — which groups got dearer relative to the basket
# ---------------------------------------------------------------------

general_index <- spliced |> filter(group == "General") |> select(date, general_index = index)

spliced |>
  filter(group != "General", base_year == "2015-16") |>
  left_join(general_index, by = join_by(date)) |>
  mutate(relative = index / general_index * 100) |>
  arrange(group, date) |>
  mutate(relative = relative / first(relative) * 100, .by = group) |>
  ggplot(aes(date, relative, colour = group)) +
  geom_hline(yintercept = 100, colour = "grey50", linetype = "dashed") +
  geom_line(linewidth = 0.8) +
  labs(title = "Relative prices: group index divided by General index",
       subtitle = "Jul 2019 = 100. Above 100 = dearer than the basket overall",
       x = NULL, y = "Relative price index", colour = NULL) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "bottom")


# ---------------------------------------------------------------------
# 10. Fiscal-year inflation table and heatmap
# ---------------------------------------------------------------------

fy <- spliced |>
  summarise(fy_index = mean(index), .by = c(group, fiscal_year, base_year)) |>
  arrange(group, fiscal_year) |>
  mutate(fy_inflation = (fy_index / lag(fy_index) - 1) * 100, .by = group)

fy |>
  filter(!is.na(fy_inflation)) |>
  select(group, fiscal_year, fy_inflation) |>
  pivot_wider(names_from = fiscal_year, values_from = fy_inflation) |>
  print(width = Inf)

fy |>
  filter(!is.na(fy_inflation)) |>
  ggplot(aes(fiscal_year, fct_rev(group), fill = fy_inflation)) +
  geom_tile(colour = "white") +
  geom_text(aes(label = round(fy_inflation, 1)), size = 3) +
  scale_fill_gradient2(low = "steelblue4", mid = "white", high = "firebrick",
                       midpoint = 0) +
  labs(title = "Fiscal-year inflation by major group (%)",
       x = NULL, y = NULL, fill = "%") +
  theme_minimal(base_size = 11) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))


# ---------------------------------------------------------------------
# 11. Episode comparison
#     Pick the phases visible in the headline series and compare groups
# ---------------------------------------------------------------------

episodes <- yoy |>
  filter(base_year == "2015-16") |>
  mutate(
    episode = case_when(
      date <  as.Date("2021-07-01") ~ "1. Pre-surge (to Jun 2021)",
      date <  as.Date("2023-07-01") ~ "2. Surge (Jul 2021-Jun 2023)",
      date <  as.Date("2025-07-01") ~ "3. Disinflation (Jul 2023-Jun 2025)",
      .default                      ~ "4. Re-acceleration (Jul 2025-)"
    )
  )

episodes |>
  summarise(mean_yoy = mean(yoy), .by = c(group, episode)) |>
  pivot_wider(names_from = episode, values_from = mean_yoy) |>
  print(width = Inf)

episodes |>
  summarise(mean_yoy = mean(yoy), .by = c(group, episode)) |>
  ggplot(aes(mean_yoy, fct_reorder(group, mean_yoy), fill = episode)) +
  geom_col(position = "dodge") +
  labs(title = "Average group inflation by episode", x = "Mean Y-o-Y %",
       y = NULL, fill = NULL) +
  theme_minimal(base_size = 11) +
  theme(legend.position = "bottom")


# ---------------------------------------------------------------------
# 12. Persistence and volatility
# ---------------------------------------------------------------------

league |>
  filter(group != "General") |>
  ggplot(aes(mean_yoy, sd_yoy)) +
  geom_point(size = 3, colour = "steelblue4") +
  geom_text(aes(label = group), hjust = -0.08, size = 3) +
  expand_limits(x = 30) +
  labs(title = "Average inflation versus its volatility, by group",
       subtitle = "Top-right: high and erratic. Bottom-left: low and steady",
       x = "Mean Y-o-Y %", y = "SD of Y-o-Y %") +
  theme_minimal(base_size = 12)

# Correlation of each group's inflation with headline
yoy |>
  filter(base_year == "2015-16", group != "General") |>
  left_join(general_line, by = join_by(date)) |>
  summarise(corr_with_headline = cor(yoy, general), .by = group) |>
  arrange(desc(corr_with_headline))


# ---------------------------------------------------------------------
# 13. Momentum — 3-month annualised versus year-on-year
#     Momentum turns before the annual rate does
# ---------------------------------------------------------------------

momentum <- spliced |>
  arrange(group, date) |>
  mutate(
    mom3_annualised = ((index / lag(index, 3))^4 - 1) * 100,
    yoy             = (index / lag(index, 12) - 1) * 100,
    .by = group
  ) |>
  filter(!is.na(mom3_annualised), !is.na(yoy), base_year == "2015-16")

momentum |>
  filter(group == "General") |>
  pivot_longer(c(mom3_annualised, yoy), names_to = "measure", values_to = "rate") |>
  mutate(measure = if_else(measure == "yoy", "Year-on-year",
                           "3-month annualised")) |>
  ggplot(aes(date, rate, colour = measure)) +
  geom_hline(yintercept = 0, colour = "grey60") +
  geom_line(linewidth = 0.9) +
  labs(title = "Headline inflation: annual rate versus short-run momentum",
       x = NULL, y = "%", colour = NULL) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "bottom")

# Latest reading for every group, momentum against annual rate
momentum |>
  slice_max(date, n = 1, by = group) |>
  select(group, date, yoy, mom3_annualised) |>
  mutate(momentum_gap = mom3_annualised - yoy) |>
  arrange(desc(momentum_gap))


# ---------------------------------------------------------------------
# 14. Weighted contributions — NOT possible from this file
#     The PDF carries indices only, no expenditure weights, so a group's
#     contribution to headline cannot be computed here. If you obtain the
#     official CPI weights, fill them in below and the rest follows.
#
# weights <- tribble(
#   ~group,                        ~weight,
#   "Food & non-alcoholic bev.",   NA,
#   ...
# )
#
# yoy |>
#   filter(group != "General") |>
#   left_join(weights, by = join_by(group)) |>
#   mutate(contribution = yoy * weight / 100) |>
#   summarise(implied_headline = sum(contribution), .by = date)
# ---------------------------------------------------------------------


# ---------------------------------------------------------------------
# 15. Export
# ---------------------------------------------------------------------

write_csv(spliced,    "groups_spliced.csv")
write_csv(yoy,        "groups_yoy.csv")
write_csv(fy,         "groups_fiscal_year.csv")
write_csv(dispersion, "groups_dispersion.csv")
