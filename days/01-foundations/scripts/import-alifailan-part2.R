# ============================================================
# Alif Ailan Data Analysis — Part 2: Next Level R Coding
# Topics: across(), case_when(), pivoting, purrr,
#         ggrepel, patchwork, correlation, regression
# ============================================================

# ── Libraries ───────────────────────────────────────────────

library(tidyverse)
library(janitor)
library(ggrepel)     # Non-overlapping plot labels
library(patchwork)   # Combine multiple plots
library(GGally)      # Correlation matrix plots
library(broom)       # Tidy model output
library(scales)      # Axis formatting helpers
library(gt)
library(gtExtras)

# install.packages(c("ggrepel", "patchwork", "GGally", "broom", "scales"))


# ── Load & Prepare Data ──────────────────────────────────────

alif <- read_csv(here::here("data/Alifailan.csv"), col_names = TRUE) |>
  clean_names()

alif |> glimpse()


# ============================================================
# PART A: ADVANCED DPLYR
# ============================================================

# ── A1. across() — apply functions to multiple columns ───────
# Instead of repeating summarise(mean_x = mean(x), mean_y = mean(y)…)
# use across() to do it in one line.

alif |>
  group_by(province) |>
  summarise(across(where(is.numeric), mean, na.rm = TRUE))

# Round everything to 1 decimal
alif |>
  group_by(province) |>
  summarise(across(where(is.numeric), \(x) round(mean(x, na.rm = TRUE), 1)))

# Multiple functions at once: mean AND sd
alif |>
  group_by(province) |>
  summarise(
    across(
      c(drinking_water, electricity, toilet),
      list(mean = mean, sd = sd),
      na.rm = TRUE
    )
  )

# across() inside mutate() — rescale all numeric cols to 0–100
alif |>
  mutate(across(where(is.numeric), \(x) scales::rescale(x, to = c(0, 100))))


# ── A2. case_when() — create categorical variables ───────────
# Classify drinking water access into performance tiers

alif <- alif |>
  mutate(
    water_tier = case_when(
      drinking_water >= 80 ~ "Good",
      drinking_water >= 50 ~ "Moderate",
      drinking_water >= 30 ~ "Poor",
      TRUE                 ~ "Critical"
    ),
    water_tier = factor(water_tier, levels = c("Critical", "Poor", "Moderate", "Good"))
  )

alif |> count(province, water_tier)

# How many districts are in each tier per province?
alif |>
  count(province, water_tier) |>
  pivot_wider(names_from = water_tier, values_from = n, values_fill = 0)


# ── A3. if_else() — simple binary recoding ───────────────────

alif <- alif |>
  mutate(
    electricity_flag = if_else(electricity >= 70, "High", "Low"),
    above_median_rank = if_else(rank_2016 <= median(rank_2016, na.rm = TRUE),
                                "Top Half", "Bottom Half")
  )

alif |> count(province, electricity_flag)


# ── A4. Composite index with rowwise() ───────────────────────
# Create a simple average index across three indicators

alif <- alif |>
  rowwise() |>
  mutate(
    composite_index = mean(c(drinking_water, electricity, toilet), na.rm = TRUE)
  ) |>
  ungroup()

alif |>
  select(district, province, composite_index) |>
  arrange(desc(composite_index)) |>
  slice(1:10)


# ── A5. slice_max() / slice_min() ────────────────────────────
# Top 3 districts per province by composite index

alif |>
  group_by(province) |>
  slice_max(composite_index, n = 3) |>
  select(province, district, composite_index)

# Bottom 3 per province
alif |>
  group_by(province) |>
  slice_min(composite_index, n = 3) |>
  select(province, district, composite_index)


# ============================================================
# PART B: RESHAPING DATA — pivot_longer / pivot_wider
# ============================================================

# ── B1. pivot_longer() — wide → long ─────────────────────────
# Useful when you want to plot multiple indicators side-by-side

alif_long <- alif |>
  select(district, province, drinking_water, electricity, toilet) |>
  pivot_longer(
    cols      = c(drinking_water, electricity, toilet),
    names_to  = "indicator",
    values_to = "value"
  )

alif_long |> head(10)

# Now plot all three indicators in one faceted plot
alif_long |>
  group_by(province, indicator) |>
  summarise(mean_value = mean(value, na.rm = TRUE), .groups = "drop") |>
  ggplot(aes(x = reorder(province, mean_value), y = mean_value, fill = indicator)) +
  geom_col(position = "dodge") +
  labs(
    x       = NULL,
    y       = "Mean Score",
    title   = "School Facility Indicators by Province",
    caption = "Source: Alif Ailan"
  ) +
  theme_minimal()


# ── B2. pivot_wider() — long → wide ──────────────────────────
# Go back to wide format (e.g., for a comparison table)

alif_long |>
  group_by(province, indicator) |>
  summarise(mean_val = round(mean(value, na.rm = TRUE), 1), .groups = "drop") |>
  pivot_wider(names_from = indicator, values_from = mean_val)


# ============================================================
# PART C: FUNCTIONAL PROGRAMMING WITH purrr
# ============================================================

# ── C1. map() — apply a function to each element of a list ───
# Run a summary for each province separately

province_data <- alif |>
  group_by(province) |>
  group_split()                   # Split into a list of data frames

# Get number of rows (districts) in each province
province_data |> map_int(nrow)

# Get province name from each split
province_data |> map_chr(\(df) unique(df$province))

# Compute mean drinking water for each province data frame
province_data |>
  map_dbl(\(df) mean(df$drinking_water, na.rm = TRUE)) |>
  set_names(map_chr(province_data, \(df) unique(df$province)))


# ── C2. map() + lm() — fit a model per province ──────────────
# Does electricity predict drinking water, and does it vary by province?

province_models <- alif |>
  group_by(province) |>
  group_split() |>
  set_names(map_chr(alif |> group_by(province) |> group_split(),
                    \(df) unique(df$province))) |>
  map(\(df) lm(drinking_water ~ electricity, data = df))

# Extract tidy coefficients for each model
province_models |>
  map(broom::tidy) |>
  bind_rows(.id = "province") |>
  filter(term == "electricity") |>
  select(province, estimate, std.error, p.value) |>
  mutate(across(where(is.numeric), \(x) round(x, 3)))


# ============================================================
# PART D: ADVANCED GGPLOT2
# ============================================================

# ── D1. ggrepel — non-overlapping labels ─────────────────────
# Much better than geom_text() for labelling points

ggplot(alif, aes(x = drinking_water, y = electricity, color = province)) +
  geom_point(alpha = 0.6) +
  geom_text_repel(
    data    = alif |> filter(composite_index > quantile(composite_index, 0.90, na.rm = TRUE)),
    aes(label = district),
    size    = 3,
    max.overlaps = 15
  ) +
  labs(
    title   = "Top 10% Districts: Drinking Water vs Electricity",
    caption = "Labels show top 10% composite index districts"
  ) +
  theme_minimal()


# ── D2. Annotate a plot with text and arrows ──────────────────

alif |>
  filter(province == "Balochistan") |>
  ggplot(aes(x = drinking_water, y = electricity)) +
  geom_point(color = "steelblue", size = 2) +
  geom_text_repel(aes(label = district), size = 2.8) +
  annotate(
    "text",
    x = 80, y = 10,
    label = "Low electricity,\nhigh water access",
    color = "firebrick", size = 3.5, hjust = 1
  ) +
  labs(
    title   = "Balochistan: Electricity vs Drinking Water",
    caption = "Source: Alif Ailan"
  ) +
  theme_minimal()


# ── D3. patchwork — combine plots side by side ───────────────

p1 <- alif |>
  group_by(province) |>
  summarise(mean_dw = mean(drinking_water, na.rm = TRUE)) |>
  ggplot(aes(x = reorder(province, mean_dw), y = mean_dw)) +
  geom_col(fill = "steelblue") +
  labs(x = NULL, y = "Mean Score", title = "Drinking Water") +
  theme_minimal()

p2 <- alif |>
  group_by(province) |>
  summarise(mean_el = mean(electricity, na.rm = TRUE)) |>
  ggplot(aes(x = reorder(province, mean_el), y = mean_el)) +
  geom_col(fill = "darkorange") +
  labs(x = NULL, y = NULL, title = "Electricity") +
  theme_minimal()

p3 <- alif |>
  group_by(province) |>
  summarise(mean_tl = mean(toilet, na.rm = TRUE)) |>
  ggplot(aes(x = reorder(province, mean_tl), y = mean_tl)) +
  geom_col(fill = "seagreen") +
  labs(x = NULL, y = NULL, title = "Toilet Facility") +
  theme_minimal()

# Side by side
p1 | p2 | p3

# Stacked with shared title
(p1 | p2 | p3) +
  plot_annotation(
    title    = "School Infrastructure Indicators by Province",
    caption  = "Source: Alif Ailan 2016",
    theme    = theme(plot.title = element_text(size = 14, face = "bold"))
  )


# ── D4. Ranked dot plot (Cleveland plot) — cleaner than bars ──

alif |>
  group_by(province) |>
  summarise(mean_index = round(mean(composite_index, na.rm = TRUE), 1)) |>
  ggplot(aes(x = mean_index, y = reorder(province, mean_index))) +
  geom_point(size = 5, color = "steelblue") +
  geom_segment(
    aes(x = 0, xend = mean_index, yend = province),
    color = "grey70", linewidth = 0.8
  ) +
  geom_text(aes(label = mean_index), hjust = -0.5, size = 3.5) +
  labs(
    x       = "Composite Index (avg of water, electricity, toilet)",
    y       = NULL,
    title   = "Province-wise Composite School Facility Index",
    caption = "Source: Alif Ailan 2016"
  ) +
  theme_minimal()


# ── D5. Faceted histogram with free scales ────────────────────

alif_long |>
  ggplot(aes(x = value, fill = indicator)) +
  geom_histogram(bins = 15, show.legend = FALSE) +
  facet_grid(indicator ~ province, scales = "free_y") +
  labs(
    title   = "Distribution of School Indicators across Provinces",
    x       = "Score", y = "Count"
  ) +
  theme_minimal(base_size = 9)


# ── D6. Custom theme ──────────────────────────────────────────
# Define once and reuse across all plots

theme_alif <- function() {
  theme_minimal(base_size = 12) +
    theme(
      plot.title       = element_text(face = "bold", size = 13),
      plot.caption     = element_text(color = "grey50", size = 8),
      axis.text        = element_text(color = "grey30"),
      panel.grid.minor = element_blank(),
      legend.position  = "bottom"
    )
}

# Apply to any plot
ggplot(alif, aes(x = drinking_water, y = electricity, color = province)) +
  geom_point(alpha = 0.7) +
  labs(title = "Drinking Water vs Electricity", caption = "Alif Ailan 2016") +
  theme_alif()


# ============================================================
# PART E: CORRELATION & REGRESSION
# ============================================================

# ── E1. Correlation matrix ────────────────────────────────────

alif |>
  select(drinking_water, electricity, toilet, infrastructure_score) |>
  cor(use = "complete.obs") |>
  round(2)

# Visual correlation matrix with GGally
alif |>
  select(drinking_water, electricity, toilet, infrastructure_score, province) |>
  ggpairs(
    aes(color = province, alpha = 0.5),
    columns = 1:4
  ) +
  theme_minimal()


# ── E2. Simple linear regression ─────────────────────────────
# Does electricity access predict drinking water access?

model1 <- lm(drinking_water ~ electricity, data = alif)

broom::tidy(model1)     # Coefficients table
broom::glance(model1)   # Model fit statistics

# Multiple regression — add toilet and province
model2 <- lm(drinking_water ~ electricity + toilet + province, data = alif)

broom::tidy(model2) |>
  mutate(across(where(is.numeric), \(x) round(x, 3))) |>
  filter(p.value < 0.05)

broom::glance(model2) |>
  select(r.squared, adj.r.squared, AIC, BIC)


# ── E3. Plot regression line with confidence interval ─────────

ggplot(alif, aes(x = electricity, y = drinking_water)) +
  geom_point(aes(color = province), alpha = 0.5) +
  geom_smooth(method = "lm", se = TRUE, color = "black", linewidth = 1) +
  labs(
    title   = "Does Electricity Access Predict Drinking Water Access?",
    x       = "Electricity Score",
    y       = "Drinking Water Score",
    caption = "Shaded band = 95% confidence interval | Source: Alif Ailan"
  ) +
  theme_alif()

# By province (separate regression lines)
ggplot(alif, aes(x = electricity, y = drinking_water, color = province)) +
  geom_point(alpha = 0.4) +
  geom_smooth(method = "lm", se = FALSE) +
  labs(
    title   = "Province-wise Relationship: Electricity vs Drinking Water",
    caption = "Source: Alif Ailan 2016"
  ) +
  theme_alif()


# ── E4. Coefficient plot (visualise regression output) ────────

broom::tidy(model2, conf.int = TRUE) |>
  filter(term != "(Intercept)") |>
  mutate(term = str_remove(term, "province")) |>
  ggplot(aes(x = estimate, y = reorder(term, estimate))) +
  geom_point(size = 3, color = "steelblue") +
  geom_errorbarh(aes(xmin = conf.low, xmax = conf.high), height = 0.2) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "firebrick") +
  labs(
    x       = "Coefficient Estimate (with 95% CI)",
    y       = NULL,
    title   = "Predictors of Drinking Water Access",
    caption = "Reference category: Balochistan"
  ) +
  theme_alif()
