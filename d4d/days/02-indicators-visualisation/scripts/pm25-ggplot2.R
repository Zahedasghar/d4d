# =============================================================================
# PM2.5 Air Pollution — WDI Analysis with explicit ggplot2
# Replaces all wdiexplorer plot_*() calls with ggplot2 equivalents
# Modern tidyverse: R 4.3+, dplyr 1.1+, native pipe |>
# =============================================================================

# --- 0. Setup ----------------------------------------------------------------

library(WDI)
library(wdiexplorer)   # still needed for compute_*() and get_*() functions
library(dplyr)
library(tidyr)
library(stringr)
library(naniar)
library(readr)
library(purrr)
library(ggplot2)
library(scales)        # for label_percent(), comma_format()
library(GGally)        # for ggparcoord() — parallel coordinate plots

#options(timeout = 600)

INDICATOR <- "EN.ATM.PM25.MC.M3"
INDICATOR_LABEL <- "PM2.5 Air Pollution (μg/m³)"

# Shared theme applied to every plot
theme_wdi <- function() {
  theme_minimal(base_size = 11) +
    theme(
      plot.title       = element_text(face = "bold", size = 13),
      plot.subtitle    = element_text(colour = "grey40", size = 10),
      strip.text       = element_text(face = "bold"),
      legend.position  = "bottom",
      legend.title     = element_text(face = "bold"),
      panel.grid.minor = element_blank()
    )
}

# --- 1. Search & Load Data ---------------------------------------------------

WDIsearch("air pollution")

# pm_data <- get_wdi_data(indicator = INDICATOR)
# saveRDS(pm_data, "pm_data.rds")
pm_data <- readRDS(here::here("data/pm_data.rds"))

glimpse(pm_data)

# --- 2. Compute derived objects (wdiexplorer non-plot functions) --------------

pm_valid            <- get_valid_data(pm_data)
pm_diss_mat         <- compute_dissimilarity(pm_data)
pm_variation        <- compute_variation(pm_data, diss_matrix = pm_diss_mat,
                                         group_var = "region")
pm_trend_shape      <- compute_trend_shape_features(pm_data)
pm_temporal         <- compute_temporal_features(pm_data)
pm_diagnostic_metrics <- compute_diagnostic_indices(pm_data, group_var = "region")
pm_diagnostic_metrics_group <- add_group_info(
  metric_summary = pm_diagnostic_metrics, pm_data
)

# =============================================================================
# SECTION 3 — MISSINGNESS  (replaces plot_missing())
# =============================================================================

# ---- 3a. Tile heatmap: country × year, coloured by NA vs observed ----------

miss_tile <- pm_data |>
  select(country, region, year, all_of(INDICATOR)) |>
  rename(value = all_of(INDICATOR)) |>
  mutate(is_missing = is.na(value))

ggplot(miss_tile, aes(x = year, y = reorder(country, is_missing), fill = is_missing)) +
  geom_tile(colour = "white", linewidth = 0.1) +
  scale_fill_manual(
    values = c("FALSE" = "#2196F3", "TRUE" = "#EF5350"),
    labels = c("FALSE" = "Observed", "TRUE" = "Missing")
  ) +
  facet_wrap(~ region, scales = "free_y", ncol = 2) +
  labs(
    title    = "Missingness by Country and Year",
    subtitle = str_glue("Indicator: {INDICATOR}"),
    x        = "Year",
    y        = NULL,
    fill     = NULL
  ) +
  theme_wdi() +
  theme(axis.text.y = element_text(size = 6))

# ---- 3b. Bar chart: % missing per region -----------------------------------

pm_data |>
  select(region, all_of(INDICATOR)) |>
  rename(value = all_of(INDICATOR)) |>
  summarise(
    pct_missing = mean(is.na(value)),
    .by = region
  ) |>
  arrange(desc(pct_missing)) |>
  ggplot(aes(x = pct_missing, y = reorder(region, pct_missing), fill = region)) +
  geom_col(show.legend = FALSE, width = 0.7) +
  geom_text(aes(label = label_percent(accuracy = 1)(pct_missing)),
            hjust = -0.15, size = 3.5) +
  scale_x_continuous(labels = label_percent(), expand = expansion(mult = c(0, 0.15))) +
  scale_fill_brewer(palette = "Set2") +
  labs(
    title    = "Percentage of Missing Observations by Region",
    subtitle = str_glue("Indicator: {INDICATOR}"),
    x        = "% Missing",
    y        = NULL
  ) +
  theme_wdi()

# ---- 3c. Tabular summary: top countries by n_miss --------------------------

pm_data |>
  select(country, region, year, all_of(INDICATOR)) |>
  group_by(region, country) |>
  miss_var_summary() |>
  filter(variable == INDICATOR) |>
  arrange(desc(n_miss))

# =============================================================================
# SECTION 5 — VARIATION  (replaces country_avg_dist slice print)
# =============================================================================

# ---- 5a. Dot plot: top 20 most dissimilar countries ------------------------

pm_variation |>
  slice_max(country_avg_dist, n = 20) |>
  ggplot(aes(x = country_avg_dist, y = reorder(country, country_avg_dist),
             colour = region)) +
  geom_point(size = 3) +
  geom_segment(aes(xend = 0, yend = reorder(country, country_avg_dist)),
               linewidth = 0.4, linetype = "dotted") +
  scale_colour_brewer(palette = "Set1") +
  labs(
    title    = "Top 20 Most Dissimilar Countries",
    subtitle = "Ranked by average distance from all other countries",
    x        = "Average Pairwise Distance",
    y        = NULL,
    colour   = "Region"
  ) +
  theme_wdi()

country_region_lkp <- pm_data |>
  distinct(country, region)

pm_variation |>
  left_join(country_region_lkp, by = join_by(country)) |>
  slice_max(country_avg_dist, n = 20) |>
  ggplot(aes(x = country_avg_dist, y = reorder(country, country_avg_dist),
             colour = region)) +
  geom_point(size = 3) +
  geom_segment(aes(xend = 0, yend = reorder(country, country_avg_dist)),
               linewidth = 0.4, linetype = "dotted") +
  scale_colour_brewer(palette = "Set1") +
  labs(
    title    = "Top 20 Most Dissimilar Countries",
    subtitle = "Ranked by average distance from all other countries",
    x        = "Average Pairwise Distance",
    y        = NULL,
    colour   = "Region"
  ) +
  theme_wdi()

# =============================================================================
# SECTION 6 — TREND & SHAPE FEATURES  (replaces trend_strength slice)
# =============================================================================

# ---- 6a. Bar chart: top 20 countries by trend strength ---------------------

pm_trend_shape |>
  slice_max(trend_strength, n = 20) |>
  ggplot(aes(x = trend_strength, y = reorder(country, trend_strength),
             fill = trend_strength)) +
  geom_col(width = 0.7, show.legend = FALSE) +
  scale_fill_gradient(low = "#AED6F1", high = "#1A5276") +
  labs(
    title    = "Top 20 Countries by Trend Strength",
    subtitle = str_glue("{INDICATOR_LABEL}"),
    x        = "Trend Strength",
    y        = NULL
  ) +
  theme_wdi()

# =============================================================================
# SECTION 7 — TEMPORAL FEATURES  (replaces flat_spot slice)
# =============================================================================

# ---- 7a. Dumbbell: top & bottom flat-spot countries ------------------------

flat_extremes <- pm_temporal |>
  arrange(desc(flat_spot)) |>
  slice(c(1:10, (n() - 9):n())) |>
  mutate(group = if_else(row_number() <= 10, "High flat-spot", "Low flat-spot"))

ggplot(flat_extremes,
       aes(x = flat_spot, y = reorder(country, flat_spot), colour = group)) +
  geom_point(size = 3) +
  geom_segment(aes(xend = 0, yend = reorder(country, flat_spot)),
               linewidth = 0.4, linetype = "dotted") +
  scale_colour_manual(values = c("High flat-spot" = "#E74C3C",
                                 "Low flat-spot"  = "#2ECC71")) +
  labs(
    title    = "Countries with Highest and Lowest Flat-Spot Index",
    subtitle = "Flat-spot = proportion of series with near-zero change",
    x        = "Flat-Spot Index",
    y        = NULL,
    colour   = NULL
  ) +
  theme_wdi()

# =============================================================================
# SECTION 9 — METRIC DISTRIBUTION  (replaces plot_metric_distribution())
# =============================================================================

# Pivot diagnostic metrics to long format for faceting
metrics_long <- pm_diagnostic_metrics_group |>
  select(country, region, where(is.numeric)) |>
  pivot_longer(
    cols      = -c(country, region),
    names_to  = "metric",
    values_to = "value"
  )

# ---- 9a. All metrics, coloured by region (density ridges) ------------------

ggplot(metrics_long,
       aes(x = value, fill = region, colour = region)) +
  geom_density(alpha = 0.3, linewidth = 0.5) +
  facet_wrap(~ metric, scales = "free", ncol = 3) +
  scale_fill_brewer(palette  = "Set1") +
  scale_colour_brewer(palette = "Set1") +
  labs(
    title    = "Distribution of All Diagnostic Metrics by Region",
    x        = "Value",
    y        = "Density",
    fill     = "Region",
    colour   = "Region"
  ) +
  theme_wdi()

# ---- 9b. All metrics, faceted by region (boxplots) -------------------------

ggplot(metrics_long,
       aes(x = region, y = value, fill = region)) +
  geom_boxplot(alpha = 0.7, outlier.size = 1, show.legend = FALSE) +
  facet_wrap(~ metric, scales = "free_y", ncol = 3) +
  scale_fill_brewer(palette = "Set2") +
  labs(
    title    = "Metric Distributions Faceted by Region",
    x        = NULL,
    y        = "Value"
  ) +
  theme_wdi() +
  theme(axis.text.x = element_text(angle = 35, hjust = 1, size = 8))

# ---- 9c. Single metric: linearity ------------------------------------------

metrics_long |>
  filter(metric == "linearity") |>
  ggplot(aes(x = value, fill = region, colour = region)) +
  geom_density(alpha = 0.35, linewidth = 0.6) +
  scale_fill_brewer(palette  = "Set1") +
  scale_colour_brewer(palette = "Set1") +
  labs(
    title    = "Distribution of Linearity by Region",
    subtitle = str_glue("{INDICATOR_LABEL}"),
    x        = "Linearity",
    y        = "Density",
    fill     = "Region",
    colour   = "Region"
  ) +
  theme_wdi()

# ---- 9d. Two metrics (linearity + curvature), faceted by region ------------

metrics_long |>
  filter(metric %in% c("linearity", "curvature")) |>
  ggplot(aes(x = value, fill = region, colour = region)) +
  geom_density(alpha = 0.35, linewidth = 0.5) +
  facet_grid(region ~ metric, scales = "free") +
  scale_fill_brewer(palette  = "Set1") +
  scale_colour_brewer(palette = "Set1") +
  labs(
    title    = "Linearity and Curvature by Region",
    subtitle = str_glue("{INDICATOR_LABEL}"),
    x        = "Value",
    y        = "Density",
    fill     = "Region",
    colour   = "Region"
  ) +
  theme_wdi() +
  theme(legend.position = "none")

# =============================================================================
# SECTION 10 — METRIC PARTITION  (replaces plot_metric_partition())
# =============================================================================

# ---- 10a. Silhouette width: jitter strip + region mean ---------------------

sil_summary <- pm_diagnostic_metrics_group |>
  summarise(mean_sil = mean(sil_width, na.rm = TRUE), .by = region)

pm_diagnostic_metrics_group |>
  ggplot(aes(x = reorder(region, sil_width, median), y = sil_width,
             colour = region)) +
  geom_jitter(width = 0.2, alpha = 0.6, size = 2) +
  geom_point(data = sil_summary,
             aes(x = reorder(region, mean_sil), y = mean_sil),
             shape = 18, size = 5, colour = "black") +
  geom_hline(yintercept = 0, linetype = "dashed", colour = "grey50") +
  scale_colour_brewer(palette = "Set1") +
  labs(
    title    = "Silhouette Width by Region",
    subtitle = "Diamond = regional mean · Dashed line = 0 (no cluster structure)",
    x        = NULL,
    y        = "Silhouette Width",
    colour   = "Region"
  ) +
  theme_wdi() +
  theme(legend.position = "none")

# =============================================================================
# SECTION 11 — DATA TRAJECTORIES  (replaces plot_data_trajectories())
# =============================================================================

# ---- 11a. All countries — spaghetti plot ------------------------------------

pm_data |>
  rename(value = all_of(INDICATOR)) |>
  filter(!is.na(value)) |>
  ggplot(aes(x = year, y = value, group = country)) +
  geom_line(alpha = 0.25, colour = "#1565C0", linewidth = 0.4) +
  labs(
    title    = "PM2.5 Trajectories — All Countries",
    subtitle = str_glue("{INDICATOR_LABEL}"),
    x        = "Year",
    y        = INDICATOR_LABEL
  ) +
  theme_wdi()

# ---- 11b. Faceted by region ------------------------------------------------

pm_data |>
  rename(value = all_of(INDICATOR)) |>
  filter(!is.na(value)) |>
  ggplot(aes(x = year, y = value, group = country, colour = region)) +
  geom_line(alpha = 0.5, linewidth = 0.4, show.legend = FALSE) +
  facet_wrap(~ region, scales = "free_y", ncol = 2) +
  scale_colour_brewer(palette = "Set1") +
  labs(
    title    = "PM2.5 Trajectories by Region",
    subtitle = str_glue("{INDICATOR_LABEL}"),
    x        = "Year",
    y        = INDICATOR_LABEL
  ) +
  theme_wdi()

# ---- 11c. Coloured by country_avg_dist (ungrouped) -------------------------

pm_data |>
  rename(value = all_of(INDICATOR)) |>
  filter(!is.na(value)) |>
  left_join(
    pm_diagnostic_metrics |> select(country, country_avg_dist),
    by = join_by(country)
  ) |>
  ggplot(aes(x = year, y = value, group = country, colour = country_avg_dist)) +
  geom_line(alpha = 0.6, linewidth = 0.5) +
  scale_colour_viridis_c(
    option = "C",
    name   = "Avg Distance",
    labels = number_format(accuracy = 0.1)
  ) +
  labs(
    title    = "PM2.5 Trajectories Coloured by Country Average Distance",
    subtitle = "Brighter = more dissimilar from other countries",
    x        = "Year",
    y        = INDICATOR_LABEL
  ) +
  theme_wdi()

# ---- 11d. Coloured by within_group_avg_dist, faceted by region -------------

pm_data |>
  rename(value = all_of(INDICATOR)) |>
  filter(!is.na(value)) |>
  left_join(
    pm_diagnostic_metrics_group |> select(country, region, within_group_avg_dist),
    by = join_by(country, region)
  ) |>
  ggplot(aes(x = year, y = value, group = country,
             colour = within_group_avg_dist)) +
  geom_line(alpha = 0.7, linewidth = 0.5) +
  facet_wrap(~ region, scales = "free_y", ncol = 2) +
  scale_colour_viridis_c(
    option = "D",
    name   = "Within-Group\nAvg Distance",
    labels = number_format(accuracy = 0.1)
  ) +
  labs(
    title    = "PM2.5 Trajectories by Region — Within-Group Dissimilarity",
    subtitle = "Brighter = more dissimilar from regional peers",
    x        = "Year",
    y        = INDICATOR_LABEL
  ) +
  theme_wdi()

# =============================================================================
# SECTION 12 — PARALLEL COORDINATES  (replaces plot_parallel_coords())
# =============================================================================

# Prepare: select only numeric diagnostic columns + region for colouring
metrics_for_pcp <- pm_diagnostic_metrics_group |>
  select(country, region, where(is.numeric)) |>
  drop_na()

numeric_cols <- metrics_for_pcp |>
  select(where(is.numeric)) |>
  names()

# Column index positions for ggparcoord (excludes country/region)
col_idx <- which(names(metrics_for_pcp) %in% numeric_cols)

# ---- 12a. All countries, coloured by region --------------------------------

ggparcoord(
  data        = metrics_for_pcp,
  columns     = col_idx,
  groupColumn = "region",
  scale       = "uniminmax",   # scale each axis 0–1 for comparability
  alphaLines  = 0.35,
  splineFactor = FALSE
) +
  scale_colour_brewer(palette = "Set1") +
  labs(
    title    = "Parallel Coordinate Plot — All Diagnostic Metrics",
    subtitle = "Each line = one country; axes scaled 0–1",
    x        = "Metric",
    y        = "Scaled Value",
    colour   = "Region"
  ) +
  theme_wdi() +
  theme(axis.text.x = element_text(angle = 30, hjust = 1))

# ---- 12b. Faceted by region ------------------------------------------------

ggparcoord(
  data        = metrics_for_pcp,
  columns     = col_idx,
  groupColumn = "region",
  scale       = "uniminmax",
  alphaLines  = 0.4,
  splineFactor = FALSE
) +
  scale_colour_brewer(palette = "Set1") +
  facet_wrap(~ region, ncol = 2) +
  labs(
    title    = "Parallel Coordinates Faceted by Region",
    subtitle = "Axes scaled 0–1 within each panel",
    x        = "Metric",
    y        = "Scaled Value",
    colour   = "Region"
  ) +
  theme_wdi() +
  theme(
    axis.text.x  = element_text(angle = 30, hjust = 1),
    legend.position = "none"
  )
