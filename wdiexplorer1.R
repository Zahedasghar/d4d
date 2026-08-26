# install.packages("devtools")
#
# devtools::install_github("Oluwayomi-Olaitan/wdiexplorer")

library(wdiexplorer)

## timeout for WDI API calls

options(timeout=600)



WDI::WDIsearch("air pollution")

# pm_data <- get_wdi_data(indicator = "EN.ATM.PM25.MC.M3")

## Save this pm_data

write.csv(pm_data, "pm_data.csv", row.names = FALSE)

saveRDS(pm_data, "pm_data.rds")

# =============================================================================
# PM2.5 Air Pollution — WDI Explorer Analysis
# Modern tidyverse style: R 4.3+, dplyr 1.1+, native pipe |>
# =============================================================================

# --- 0. Setup ----------------------------------------------------------------

# install.packages("devtools")
# devtools::install_github("Oluwayomi-Olaitan/wdiexplorer")

library(wdiexplorer)
library(WDI)
library(dplyr)
library(tidyr)
library(stringr)
library(naniar)
library(readr)
library(purrr)

options(timeout = 600)

# Indicator code (single source of truth — change here to reuse script)
INDICATOR <- "EN.ATM.PM25.MC.M3"

# --- 1. Search & Pull Data ---------------------------------------------------

WDIsearch("air pollution")

# Pull data from WDI API (comment out once saved)
# pm_data <- get_wdi_data(indicator = INDICATOR)

# Persist locally to avoid repeated API calls
# write_csv(pm_data, "pm_data.csv")p
# saveRDS(pm_data, "pm_data.rds")

# Load from disk (use whichever format you saved)
pm_data <- readRDS("pm_data.rds")
# pm_data <- read_csv("pm_data.csv")

# --- 2. Inspect ---------------------------------------------------------------

glimpse(pm_data)

# --- 3. Missingness -----------------------------------------------------------

# Visual overview by region
plot_missing(wdi_data = pm_data, group_var = "region")

# Tabular missingness summary: top countries by missing observations
pm_data |>
  select(country, region, year, all_of(INDICATOR)) |>
  group_by(region, country) |>
  miss_var_summary() |>
  filter(variable == INDICATOR) |>
  arrange(desc(n_miss))

# --- 4. Valid Data -----------------------------------------------------------

pm_valid <- get_valid_data(pm_data)

# --- 5. Dissimilarity & Variation --------------------------------------------

pm_diss_mat <- compute_dissimilarity(pm_data)

pm_variation <- compute_variation(
  pm_data,
  diss_matrix = pm_diss_mat,
  group_var   = "region"
)

# Top 3 most dissimilar countries (highest average distance from peers)
pm_variation |>
  arrange(desc(country_avg_dist)) |>
  slice_head(n = 3)

# --- 6. Trend & Shape Features -----------------------------------------------

pm_trend_shape <- compute_trend_shape_features(pm_data)

# Top 3 countries with strongest temporal trend
pm_trend_shape |>
  arrange(desc(trend_strength)) |>
  slice_head(n = 3)

# --- 7. Temporal Features ----------------------------------------------------

pm_temporal <- compute_temporal_features(pm_data)

# Countries with the most "flat" periods (top 3) and least flat (bottom 3)
pm_temporal |>
  arrange(desc(flat_spot)) |>
  slice(c(1:3, (n() - 2):n()))

# --- 8. Diagnostic Indices ---------------------------------------------------

pm_diagnostic_metrics <- compute_diagnostic_indices(
  pm_data,
  group_var = "region"
)

pm_diagnostic_metrics_group <- add_group_info(
  metric_summary = pm_diagnostic_metrics,
  pm_data
)

# --- 9. Distribution Plots ---------------------------------------------------

# All metrics, coloured by region (ungrouped facets)
plot_metric_distribution(
  metric_summary = pm_diagnostic_metrics_group,
  colour_var     = "region"
)

# All metrics, coloured and faceted by region
plot_metric_distribution(
  metric_summary = pm_diagnostic_metrics_group,
  colour_var     = "region",
  group_var      = "region"
)

# Single metric: linearity
plot_metric_distribution(
  metric_summary = pm_diagnostic_metrics_group,
  metric_var     = "linearity",
  colour_var     = "region"
)

# Two metrics, faceted by region
plot_metric_distribution(
  metric_summary = pm_diagnostic_metrics_group,
  metric_var     = c("linearity", "curvature"),
  colour_var     = "region",
  group_var      = "region"
)

# --- 10. Metric Partition Plot -----------------------------------------------

plot_metric_partition(
  metric_summary = pm_diagnostic_metrics_group,
  metric_var     = "sil_width",
  group_var      = "region"
)

# --- 11. Data Trajectories ---------------------------------------------------

# All countries
plot_data_trajectories(pm_data)

# Faceted by region
plot_data_trajectories(pm_data, group_var = "region")

# Coloured by average country distance (ungrouped)
plot_data_trajectories(
  pm_data,
  metric_summary = pm_diagnostic_metrics,
  metric_var     = "country_avg_dist"
)

# Coloured by within-group average distance, faceted by region
plot_data_trajectories(
  pm_data,
  metric_summary = pm_diagnostic_metrics_group,
  metric_var     = "within_group_avg_dist",
  group_var      = "region"
)

# --- 12. Parallel Coordinate Plots -------------------------------------------

# All countries, coloured by region
plot_parallel_coords(
  diagnostic_summary = pm_diagnostic_metrics_group,
  colour_var         = "region"
)

# Faceted by region
plot_parallel_coords(
  diagnostic_summary = pm_diagnostic_metrics_group,
  colour_var         = "region",
  group_var          = "region"
)
