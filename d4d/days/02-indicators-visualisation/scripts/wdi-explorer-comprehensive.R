# =============================================================================
# wdiexplorer — Comprehensive Workflow with Interactive Plots
# All 15 package functions covered · Static plots wrapped with ggplotly()
# Modern tidyverse: R 4.3+, dplyr 1.1+, native pipe |>
# =============================================================================
#
# FUNCTION INVENTORY (15 total)
# ─────────────────────────────
# DATA        : get_wdi_data(), get_valid_data(), plot_missing()
# COMPUTE     : compute_dissimilarity(), compute_variation(),
#               compute_trend_shape_features(), compute_temporal_features(),
#               compute_diagnostic_indices(), add_group_info()
# PLOT STATIC : plot_metric_distribution(), plot_metric_partition()
#               → wrapped with plotly::ggplotly() for interactivity
# PLOT NATIVE : plot_data_trajectories(), plot_parallel_coords(),
#               plot_metric_linkview()
#               → already return interactive plotly objects
# DATASETS    : pm_data (PM2.5), pisa_data (PISA mathematics)
# =============================================================================

# --- 0. Installation & Setup -------------------------------------------------

# install.packages("devtools")
# devtools::install_github("Oluwayomi-Olaitan/wdiexplorer")

library(wdiexplorer)   # core package
library(WDI)           # indicator search
library(dplyr)         # data wrangling
library(tidyr)         # pivoting
library(stringr)       # string helpers
library(naniar)        # missingness summaries
library(readr)         # write_csv / read_csv
library(plotly)        # make static ggplots interactive via ggplotly()

options(timeout = 600) # allow long WDI downloads

# Indicator of interest — change here to reuse entire script
INDICATOR       <- "EN.ATM.PM25.MC.M3"
INDICATOR_LABEL <- "PM2.5 Air Pollution (μg/m³)"
GROUP_VAR       <- "region"

# =============================================================================
# STAGE 1 — DATA SOURCING AND PREPARATION
# =============================================================================

# ── 1.1  Search for indicator codes ──────────────────────────────────────────

WDIsearch("air pollution")
WDIsearch("PM2.5")

# ── 1.2  Download data via get_wdi_data() ────────────────────────────────────
# get_wdi_data() wraps WDI::WDI() and attaches region, income, lending columns.
# verbose = TRUE prints a progress message.

pm_data <- get_wdi_data(indicator = INDICATOR, verbose = TRUE)

# Persist locally — avoids repeated API calls in future sessions
write_csv(pm_data, "pm_data.csv")
saveRDS(pm_data,   "pm_data.rds")

# Reload (comment out the download block above once saved)
 pm_data <- readRDS(here::here("data/pm_data.rds"))

dplyr::glimpse(pm_data)

# ── 1.3  Built-in datasets ───────────────────────────────────────────────────
# The package ships two ready-to-use datasets you can load without any download.

data("pm_data",   package = "wdiexplorer")  # PM2.5 air pollution
data("pisa_data", package = "wdiexplorer")  # PISA mathematics scores

# ── 1.4  Missingness — plot_missing() ────────────────────────────────────────
# Returns a static ggplot2 object; wrap with ggplotly() for hover tooltips.

p_missing <- plot_missing(wdi_data = pm_data, group_var = GROUP_VAR)

# Interactive version — hover to read country names and % missing
ggplotly(p_missing) |>
  layout(title = list(text = "PM2.5 Data Missingness by Region",
                      font = list(size = 14)))

# ── 1.5  Missingness table ────────────────────────────────────────────────────
# Which countries have the most missing years?

pm_data |>
  select(country, region, year, all_of(INDICATOR)) |>
  group_by(region, country) |>
  miss_var_summary() |>
  filter(variable == INDICATOR) |>
  arrange(desc(n_miss))

# ── 1.6  Valid data — get_valid_data() ───────────────────────────────────────
# Removes countries and years where ALL values are NA.
# verbose = TRUE prints excluded countries and years.

pm_valid <- get_valid_data(pm_data, verbose = TRUE)

glimpse(pm_valid)

# =============================================================================
# STAGE 2 — DIAGNOSTIC INDICES
# =============================================================================

# ── 2.1  Dissimilarity matrix — compute_dissimilarity() ──────────────────────
# Returns a symmetric matrix of pairwise DTW-based distances between countries.

pm_diss_mat <- compute_dissimilarity(pm_data)

# Quick peek at the matrix dimensions and a 4×4 corner
dim(pm_diss_mat)
pm_diss_mat[1:4, 1:4]

# ── 2.2  Variation features — compute_variation() ────────────────────────────
# Returns: country_avg_dist | within_group_avg_dist | sil_width
# Pass the pre-computed matrix to avoid recomputation.

pm_variation <- compute_variation(
  pm_data,
  diss_matrix = pm_diss_mat,
  group_var   = GROUP_VAR
)

# Top 3 most globally dissimilar countries
pm_variation |>
  arrange(desc(country_avg_dist)) |>
  slice_head(n = 3)

# Top 3 most dissimilar within their own region
pm_variation |>
  arrange(desc(within_group_avg_dist)) |>
  slice_head(n = 3)

# Countries that fit best within their regional group (highest sil_width)
pm_variation |>
  arrange(desc(sil_width)) |>
  slice_head(n = 5)

# Countries that fit worst within their regional group (lowest sil_width)
pm_variation |>
  arrange(sil_width) |>
  slice_head(n = 5)

# ── 2.3  Trend & shape features — compute_trend_shape_features() ─────────────
# Returns: trend_strength | linearity | curvature | smoothness

pm_trend_shape <- compute_trend_shape_features(pm_data)

# Strongest trends
pm_trend_shape |>
  arrange(desc(trend_strength)) |>
  slice_head(n = 3)

# Most linear decrease (negative linearity = downward trend)
pm_trend_shape |>
  arrange(linearity) |>
  slice_head(n = 3)

# Highest curvature (most non-linear series)
pm_trend_shape |>
  arrange(desc(abs(curvature))) |>
  slice_head(n = 3)

# Smoothest series (least volatility)
pm_trend_shape |>
  arrange(smoothness) |>
  slice_head(n = 3)

# ── 2.4  Sequential temporal features — compute_temporal_features() ──────────
# Returns: crossing_points | flat_spot | acf

pm_temporal <- compute_temporal_features(pm_data)

# Most and least "flat" countries (long vs short consecutive stable periods)
pm_temporal |>
  arrange(desc(flat_spot)) |>
  slice(c(1:3, (n() - 2):n()))

# Most autocorrelated series (persistent, slow-changing)
pm_temporal |>
  arrange(desc(acf)) |>
  slice_head(n = 5)

# Most volatile series (many crossing points = frequent direction changes)
pm_temporal |>
  arrange(desc(crossing_points)) |>
  slice_head(n = 5)

# ── 2.5  All indices at once — compute_diagnostic_indices() ──────────────────
# Combines all three compute_*() functions into a single call.
# Returns all 10 indices: country_avg_dist, within_group_avg_dist, sil_width,
#   trend_strength, linearity, curvature, smoothness,
#   crossing_points, flat_spot, acf

pm_diagnostic_metrics <- compute_diagnostic_indices(
  pm_data,
  group_var = GROUP_VAR
)

glimpse(pm_diagnostic_metrics)

# ── 2.6  Attach group info — add_group_info() ─────────────────────────────────
# The compute_*() functions return only country + metrics, no region column.
# add_group_info() joins the grouping variable from pm_data back in.
# Required before any plot function that takes group_var.

pm_diagnostic_metrics_group <- add_group_info(
  metric_summary = pm_diagnostic_metrics,
  pm_data
)

glimpse(pm_diagnostic_metrics_group)

# =============================================================================
# STAGE 3 — INTERACTIVE VISUALISATIONS
# =============================================================================

# ┌─────────────────────────────────────────────────────────────────────────┐
# │  PLOT 1 — plot_metric_distribution()  [STATIC → ggplotly()]            │
# │  Shows the distribution of diagnostic index values across countries.    │
# │  Dots = countries, coloured by region.                                  │
# └─────────────────────────────────────────────────────────────────────────┘

# 3a. All 10 metrics — ungrouped (all countries pooled) ----------------------
p_dist_all <- plot_metric_distribution(
  metric_summary = pm_diagnostic_metrics_group,
  colour_var     = GROUP_VAR
)

ggplotly(p_dist_all) |>
  layout(
    title  = list(text = "Distribution of All Diagnostic Indices (Ungrouped)",
                  font = list(size = 13)),
    legend = list(title = list(text = "Region"))
  )

# 3b. All 10 metrics — grouped by region (within-region spread) --------------
p_dist_grouped <- plot_metric_distribution(
  metric_summary = pm_diagnostic_metrics_group,
  colour_var     = GROUP_VAR,
  group_var      = GROUP_VAR
)

ggplotly(p_dist_grouped) |>
  layout(
    title = list(text = "Distribution of All Diagnostic Indices by Region",
                 font = list(size = 13))
  )

# 3c. Single metric: linearity -----------------------------------------------
p_dist_linearity <- plot_metric_distribution(
  metric_summary = pm_diagnostic_metrics_group,
  metric_var     = "linearity",
  colour_var     = GROUP_VAR
)

ggplotly(p_dist_linearity) |>
  layout(title = list(text = "Linearity Distribution by Region",
                      font = list(size = 13)))

# 3d. Two metrics: linearity + curvature, grouped by region ------------------
p_dist_lin_curv <- plot_metric_distribution(
  metric_summary = pm_diagnostic_metrics_group,
  metric_var     = c("linearity", "curvature"),
  colour_var     = GROUP_VAR,
  group_var      = GROUP_VAR
)

ggplotly(p_dist_lin_curv) |>
  layout(title = list(text = "Linearity & Curvature by Region",
                      font = list(size = 13)))

# 3e. Trend and temporal metrics only ----------------------------------------
p_dist_trend <- plot_metric_distribution(
  metric_summary = pm_diagnostic_metrics_group,
  metric_var     = c("trend_strength", "smoothness", "flat_spot", "acf"),
  colour_var     = GROUP_VAR,
  group_var      = GROUP_VAR
)

ggplotly(p_dist_trend) |>
  layout(title = list(text = "Trend & Temporal Metrics by Region",
                      font = list(size = 13)))


# ┌─────────────────────────────────────────────────────────────────────────┐
# │  PLOT 2 — plot_metric_partition()  [STATIC → ggplotly()]               │
# │  Bar chart of metric values per country, ordered within each region.    │
# │  Group-level average shown as a lighter background bar.                 │
# └─────────────────────────────────────────────────────────────────────────┘

# 3f. Silhouette width — regional cluster fit --------------------------------
p_part_sil <- plot_metric_partition(
  metric_summary = pm_diagnostic_metrics_group,
  metric_var     = "sil_width",
  group_var      = GROUP_VAR
)

ggplotly(p_part_sil) |>
  layout(title = list(text = "Silhouette Width by Country and Region",
                      font = list(size = 13)))

# 3g. Country average distance — global dissimilarity -----------------------
p_part_avg_dist <- plot_metric_partition(
  metric_summary = pm_diagnostic_metrics_group,
  metric_var     = "country_avg_dist",
  group_var      = GROUP_VAR
)

ggplotly(p_part_avg_dist) |>
  layout(title = list(text = "Country Average Dissimilarity by Region",
                      font = list(size = 13)))

# 3h. Trend strength ---------------------------------------------------------
p_part_trend <- plot_metric_partition(
  metric_summary = pm_diagnostic_metrics_group,
  metric_var     = "trend_strength",
  group_var      = GROUP_VAR
)

ggplotly(p_part_trend) |>
  layout(title = list(text = "Trend Strength by Country and Region",
                      font = list(size = 13)))

# 3i. Flat spot (stable consecutive periods) ---------------------------------
p_part_flat <- plot_metric_partition(
  metric_summary = pm_diagnostic_metrics_group,
  metric_var     = "flat_spot",
  group_var      = GROUP_VAR
)

ggplotly(p_part_flat) |>
  layout(title = list(text = "Flat Spot Index by Country and Region",
                      font = list(size = 13)))


# ┌─────────────────────────────────────────────────────────────────────────┐
# │  PLOT 3 — plot_data_trajectories()  [NATIVELY INTERACTIVE]             │
# │  Line plot of every country's time series. Hover = country name.       │
# │  Mode 2: highlights top-percentile countries by chosen metric.          │
# └─────────────────────────────────────────────────────────────────────────┘

# 3j. All countries — plain spaghetti ----------------------------------------
plot_data_trajectories(pm_data)

# 3k. Faceted by region -------------------------------------------------------
plot_data_trajectories(pm_data, group_var = GROUP_VAR)

# 3l. Highlight top 5% by country_avg_dist (global threshold) ----------------
plot_data_trajectories(
  pm_data,
  metric_summary = pm_diagnostic_metrics,
  metric_var     = "country_avg_dist"
)

# 3m. Highlight top 5% by within_group_avg_dist (regional threshold) ---------
plot_data_trajectories(
  pm_data,
  metric_summary = pm_diagnostic_metrics_group,
  metric_var     = "within_group_avg_dist",
  group_var      = GROUP_VAR
)

# 3n. Highlight by trend_strength (which regions trend most strongly?) --------
plot_data_trajectories(
  pm_data,
  metric_summary = pm_diagnostic_metrics,
  metric_var     = "trend_strength"
)

# 3o. Highlight by flat_spot, grouped by region --------------------------------
plot_data_trajectories(
  pm_data,
  metric_summary = pm_diagnostic_metrics_group,
  metric_var     = "flat_spot",
  group_var      = GROUP_VAR
)


# ┌─────────────────────────────────────────────────────────────────────────┐
# │  PLOT 4 — plot_parallel_coords()  [NATIVELY INTERACTIVE]               │
# │  All 10 metrics on parallel axes; each line = one country.             │
# │  Values normalised 0–1 for cross-metric comparability.                  │
# └─────────────────────────────────────────────────────────────────────────┘

# 3p. Ungrouped — global normalisation, coloured by region -------------------
plot_parallel_coords(
  diagnostic_summary = pm_diagnostic_metrics_group,
  colour_var         = GROUP_VAR
)

# 3q. Grouped — within-region normalisation, faceted by region ---------------
plot_parallel_coords(
  diagnostic_summary = pm_diagnostic_metrics_group,
  colour_var         = GROUP_VAR,
  group_var          = GROUP_VAR
)


# ┌─────────────────────────────────────────────────────────────────────────┐
# │  PLOT 5 — plot_metric_linkview()  [NATIVELY INTERACTIVE]               │
# │  Linked scatterplot (two metrics) + line trajectories.                  │
# │  Hover a dot in the scatterplot → its series highlights in line panel.  │
# └─────────────────────────────────────────────────────────────────────────┘

# 3r. Ungrouped: linearity vs curvature -------------------------------------
plot_metric_linkview(
  pm_data,
  metric_summary = pm_diagnostic_metrics,
  metric_var     = c("linearity", "curvature")
)

# 3s. Grouped: linearity vs curvature, faceted by region --------------------
plot_metric_linkview(
  pm_data,
  metric_summary = pm_diagnostic_metrics_group,
  metric_var     = c("linearity", "curvature"),
  group_var      = GROUP_VAR
)

# 3t. Ungrouped: trend_strength vs smoothness --------------------------------
plot_metric_linkview(
  pm_data,
  metric_summary = pm_diagnostic_metrics,
  metric_var     = c("trend_strength", "smoothness")
)

# 3u. Grouped: country_avg_dist vs sil_width, faceted by region -------------
plot_metric_linkview(
  pm_data,
  metric_summary = pm_diagnostic_metrics_group,
  metric_var     = c("country_avg_dist", "sil_width"),
  group_var      = GROUP_VAR
)

# 3v. Ungrouped: flat_spot vs acf (temporal behaviour) ----------------------
plot_metric_linkview(
  pm_data,
  metric_summary = pm_diagnostic_metrics,
  metric_var     = c("flat_spot", "acf")
)

# =============================================================================
# BONUS — PISA Mathematics Dataset (built-in)
# =============================================================================
# Repeat the full pipeline on the bundled PISA data to illustrate
# how the package generalises to any WDI indicator.

data("pisa_data", package = "wdiexplorer")
dplyr::glimpse(pisa_data)

# Missingness
plot_missing(wdi_data = pisa_data, group_var = "region") |> ggplotly()

# Valid data
pisa_valid <- get_valid_data(pisa_data, verbose = TRUE)

# Diagnostic indices
pisa_diag <- compute_diagnostic_indices(pisa_data, group_var = "region")

pisa_diag_group <- add_group_info(
  metric_summary = pisa_diag,
  pisa_data
)

# Distribution — all metrics
plot_metric_distribution(
  metric_summary = pisa_diag_group,
  colour_var     = "region"
) |> ggplotly()

# Partition — silhouette width
plot_metric_partition(
  metric_summary = pisa_diag_group,
  metric_var     = "sil_width",
  group_var      = "region"
) |> ggplotly()

# Trajectories — faceted by region
plot_data_trajectories(pisa_data, group_var = "region")

# Parallel coordinates
plot_parallel_coords(
  diagnostic_summary = pisa_diag_group,
  colour_var         = "region",
  group_var          = "region"
)

# Link view — trend_strength vs linearity
plot_metric_linkview(
  pisa_data,
  metric_summary = pisa_diag_group,
  metric_var     = c("trend_strength", "linearity"),
  group_var      = "region"
)

