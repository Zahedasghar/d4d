# ============================================================================
# MICS Punjab 2018 Workshop: Exploring, Summarizing & Visualizing Data
# ============================================================================

# 1. SETUP AND PACKAGE INSTALLATION ==========================================

# Install and load required packages
Packages <- c(
  "janitor", "pdftools", "readxl", "stringi", "stringr", 
  "tidytable", "tidyverse", "tidyr", "gt", "gtsummary", 
  "haven", "broom", "vtable", "labelled", "sjlabelled", 
  "kableExtra", "ggplot2", "scales", "patchwork"
)

# Check and install missing packages
if (!require("pacman")) install.packages("pacman")
pacman::p_load(Packages, character.only = TRUE)

# Install PakPMICS2018 package
if(!require("remotes")) install.packages("remotes")
if(!require("PakPMICS2018")) {
  devtools::install_github("myaseen208/PakPMICS2018mm")
}

library(PakPMICS2018)

# 2. DATA LOADING =============================================================

# Load data from GitHub
options(timeout = 200)
load(url(
  "https://github.com/myaseen208/PakPMICS2018Data/raw/master/PakPMICS2018ch.RData"
))

# Optional: Save locally for faster access
# save(PakPMICS2018ch, file = 'data/PakPMICS2018ch.RData')
# load("data/PakPMICS2018ch.RData")

# 3. INITIAL DATA EXPLORATION =================================================

cat("\n=== DATA STRUCTURE ===\n")
# Check dimensions
dim(PakPMICS2018ch)
cat("Rows:", nrow(PakPMICS2018ch), "| Columns:", ncol(PakPMICS2018ch), "\n")

# View column names
cat("\n=== VARIABLE NAMES (First 20) ===\n")
head(colnames(PakPMICS2018ch), 20)

# Data structure
cat("\n=== DATA STRUCTURE ===\n")
glimpse(PakPMICS2018ch)

# Convert to factor for better labeling
PakPMICS2018ch <- PakPMICS2018ch |> haven::as_factor()

# 4. VARIABLE DOCUMENTATION ===================================================

# View variable table (shows labels and value ranges)
vtable::vtable(PakPMICS2018ch)

# Check specific variable labels
cat("\n=== KEY VARIABLES ===\n")
cat("UB2: ", attr(PakPMICS2018ch$UB2, "label"), "\n")
cat("UB6: ", attr(PakPMICS2018ch$UB6, "label"), "\n")
cat("windex5: ", attr(PakPMICS2018ch$windex5, "label"), "\n")

# 5. CREATE WORKING DATASET ===================================================

# Select key variables for analysis
dfch <- PakPMICS2018ch |> 
  select(
    UB2,      # Age of child
    UB6,      # Ever attended pre-school/katchi/ECE
    UB8,      # Currently attending ECE program
    UB9,      # Covered by any health insurance
    EC1,      # No. of children's books or picture books
    EC2A,     # Homemade toys
    EC5EA,    # Played with Mother
    EC5EB,    # Played with Father
    UCF2,     # Child wear glasses
    windex5,  # Wealth index quintiles
    IM2,      # Child had immunization card
    IM3       # Ever received any vaccinations
  )

cat("\n=== WORKING DATASET CREATED ===\n")
cat("Dimensions:", dim(dfch), "\n")

# 6. UNIVARIATE ANALYSIS ======================================================

cat("\n=== UNIVARIATE ANALYSIS ===\n")

## 6.1 Child Wears Glasses (UCF2)
table_ucf2 <- dfch |> 
  select(UCF2) |> 
  haven::as_factor() |> 
  tbl_summary(
    label = list(UCF2 ~ "Child Wears Glasses")
  ) |> 
  as_gt() |> 
  tab_header(
    title = "Child Eyewear Usage",
    subtitle = "Pakistan MICS 2018-19"
  ) |>
  tab_source_note(source_note = "Source: PakPMICS2018 Child Dataset")

print(table_ucf2)

## 6.2 Pre-school Attendance (UB6)
table_ub6 <- dfch |> 
  select(UB6) |> 
  haven::as_factor() |> 
  tbl_summary(
    label = list(UB6 ~ "Ever Attended Pre-school/ECE")
  ) |> 
  as_gt() |> 
  tab_header(
    title = "Pre-school Attendance",
    subtitle = "Pakistan MICS 2018-19"
  )

print(table_ub6)

## 6.3 Immunization Card (IM2)
table_im2 <- dfch |> 
  select(IM2) |> 
  haven::as_factor() |> 
  tbl_summary(
    label = list(IM2 ~ "Has Immunization Card")
  ) |> 
  as_gt() |> 
  tab_header(
    title = "Immunization Card Possession",
    subtitle = "Pakistan MICS 2018-19"
  )

print(table_im2)

# 7. BIVARIATE ANALYSIS =======================================================

cat("\n=== BIVARIATE ANALYSIS ===\n")

## 7.1 Child Glasses by Wealth Quintile
cross_glasses_wealth <- dfch |> 
  select(UCF2, windex5) |> 
  haven::as_factor() |> 
  tbl_cross(
    row = UCF2, 
    col = windex5,
    percent = "row",
    label = list(
      UCF2 ~ "Child Wears Glasses",
      windex5 ~ "Wealth Quintile"
    )
  ) |> 
  as_gt() |> 
  tab_header(
    title = "Child Eyewear by Wealth Quintile",
    subtitle = "Row percentages shown"
  )

print(cross_glasses_wealth)

## 7.2 Pre-school Attendance by Wealth Quintile
cross_preschool_wealth <- dfch |> 
  select(UB6, windex5) |> 
  haven::as_factor() |> 
  tbl_cross(
    row = UB6, 
    col = windex5,
    percent = "row",
    label = list(
      UB6 ~ "Ever Attended Pre-school",
      windex5 ~ "Wealth Quintile"
    )
  ) |> 
  as_gt() |> 
  tab_header(
    title = "Pre-school Attendance by Wealth Quintile",
    subtitle = "Pakistan MICS 2018-19"
  )

print(cross_preschool_wealth)

## 7.3 Immunization Card by Vaccination Status
cross_im2_im3 <- dfch |> 
  select(IM2, IM3) |> 
  haven::as_factor() |> 
  tbl_cross(
    row = IM2, 
    col = IM3,
    percent = "row",
    label = list(
      IM2 ~ "Has Immunization Card",
      IM3 ~ "Ever Received Vaccinations"
    )
  ) |> 
  as_gt() |> 
  tab_header(
    title = "Immunization Card vs Vaccination Status",
    subtitle = "Pakistan MICS 2018-19"
  )

print(cross_im2_im3)

# 8. MULTIVARIATE ANALYSIS ====================================================

cat("\n=== MULTIVARIATE ANALYSIS ===\n")

## Summary table by Wealth Quintile
summary_by_wealth <- dfch |> 
  select(UB6, UB8, UB9, UCF2, windex5) |> 
  haven::as_factor() |> 
  tbl_summary(
    by = windex5,
    label = list(
      UB6 ~ "Attended Pre-school",
      UB8 ~ "Currently in ECE",
      UB9 ~ "Health Insurance",
      UCF2 ~ "Wears Glasses"
    ),
    statistic = list(all_categorical() ~ "{n} ({p}%)")
  ) |> 
  add_overall() |>
  as_gt() |> 
  tab_header(
    title = "Child Characteristics by Wealth Quintile",
    subtitle = "Pakistan MICS 2018-19"
  )

print(summary_by_wealth)

# 9. DATA VISUALIZATION =======================================================

cat("\n=== DATA VISUALIZATION ===\n")

## 9.1 Bar Chart: Pre-school Attendance
p1 <- dfch |> 
  filter(!is.na(UB6)) |>
  haven::as_factor() |>
  ggplot(aes(x = UB6, fill = UB6)) +
  geom_bar(stat = "count") +
  geom_text(stat = 'count', aes(label = after_stat(count)), vjust = -0.5) +
  scale_fill_brewer(palette = "Set2") +
  labs(
    title = "Pre-school Attendance Distribution",
    subtitle = "Pakistan MICS 2018-19",
    x = "Ever Attended Pre-school/ECE",
    y = "Number of Children"
  ) +
  theme_minimal() +
  theme(legend.position = "none")

print(p1)

## 9.2 Stacked Bar Chart: Pre-school by Wealth
p2 <- dfch |> 
  filter(!is.na(UB6) & !is.na(windex5)) |>
  haven::as_factor() |>
  ggplot(aes(x = windex5, fill = UB6)) +
  geom_bar(position = "fill") +
  scale_y_continuous(labels = scales::percent) +
  scale_fill_brewer(palette = "Set1") +
  labs(
    title = "Pre-school Attendance by Wealth Quintile",
    subtitle = "Proportion within each wealth group",
    x = "Wealth Quintile",
    y = "Percentage",
    fill = "Attended Pre-school"
  ) +
  theme_minimal() +
  theme(legend.position = "bottom")

print(p2)

## 9.3 Immunization Analysis
p3 <- dfch |> 
  filter(!is.na(IM2) & !is.na(IM3)) |>
  haven::as_factor() |>
  count(IM2, IM3) |>
  ggplot(aes(x = IM2, y = n, fill = IM3)) +
  geom_col(position = "dodge") +
  geom_text(aes(label = n), position = position_dodge(width = 0.9), vjust = -0.5) +
  scale_fill_manual(values = c("#E74C3C", "#3498DB", "#95A5A6")) +
  labs(
    title = "Immunization Card and Vaccination Status",
    subtitle = "Pakistan MICS 2018-19",
    x = "Has Immunization Card",
    y = "Count",
    fill = "Ever Vaccinated"
  ) +
  theme_minimal() +
  theme(legend.position = "bottom")

print(p3)

## 9.4 Child Activities by Wealth
p4 <- dfch |> 
  filter(!is.na(EC5EA) & !is.na(windex5)) |>
  haven::as_factor() |>
  ggplot(aes(x = windex5, fill = EC5EA)) +
  geom_bar(position = "fill") +
  scale_y_continuous(labels = scales::percent) +
  scale_fill_brewer(palette = "Pastel1") +
  labs(
    title = "Child Played with Mother by Wealth Quintile",
    subtitle = "Last 3 days before survey",
    x = "Wealth Quintile",
    y = "Percentage",
    fill = "Played with Mother"
  ) +
  theme_minimal() +
  theme(legend.position = "bottom")

print(p4)

# 10. SUBSET CREATION FOR ADVANCED ANALYSIS ===================================

cat("\n=== CREATING ANALYSIS SUBSETS ===\n")

# Create Punjab subset (if region variable available)
# Note: Adjust based on actual province/region variable in dataset
# punj <- dfch |> filter(province == "Punjab")

# Filter children age 0-2 years with valid immunization data
punj_subset <- dfch |> 
  filter(!is.na(UB2)) |>
  mutate(age_years = as.numeric(as.character(UB2))) |>
  filter(age_years <= 2) |>
  filter(!is.na(IM2) & !is.na(IM3))

cat("Punjab subset created with", nrow(punj_subset), "children aged 0-2\n")

# Summary of subset
summary_subset <- punj_subset |> 
  select(UB2, IM2, IM3, windex5) |>
  haven::as_factor() |>
  tbl_summary(
    label = list(
      UB2 ~ "Age (years)",
      IM2 ~ "Has Immunization Card",
      IM3 ~ "Ever Vaccinated",
      windex5 ~ "Wealth Quintile"
    )
  ) |>
  as_gt() |>
  tab_header(
    title = "Characteristics of Children Aged 0-2",
    subtitle = "With Valid Immunization Data"
  )

print(summary_subset)

# 11. KEY INSIGHTS & STATISTICS ===============================================

cat("\n=== KEY INSIGHTS ===\n")

# Calculate key metrics
preschool_rate <- dfch |> 
  filter(!is.na(UB6)) |>
  summarise(rate = mean(UB6 == "Yes", na.rm = TRUE) * 100)

glasses_rate <- dfch |> 
  filter(!is.na(UCF2)) |>
  summarise(rate = mean(UCF2 == "Yes", na.rm = TRUE) * 100)

insurance_rate <- dfch |> 
  filter(!is.na(UB9)) |>
  summarise(rate = mean(UB9 == "Yes", na.rm = TRUE) * 100)

cat("Pre-school Attendance Rate:", round(preschool_rate$rate, 2), "%\n")
cat("Children Wearing Glasses:", round(glasses_rate$rate, 2), "%\n")
cat("Health Insurance Coverage:", round(insurance_rate$rate, 2), "%\n")

# Wealth gradient analysis
wealth_gradient <- dfch |> 
  filter(!is.na(UB6) & !is.na(windex5)) |>
  haven::as_factor() |>
  group_by(windex5) |>
  summarise(
    preschool_pct = mean(UB6 == "Yes", na.rm = TRUE) * 100,
    n = n()
  )

cat("\n=== Pre-school Attendance by Wealth Quintile ===\n")
print(wealth_gradient)

# 12. EXPORT RESULTS ==========================================================

# Save key tables and plots
# ggsave("preschool_attendance.png", p1, width = 10, height = 6)
# ggsave("preschool_by_wealth.png", p2, width = 10, height = 6)
# ggsave("immunization_status.png", p3, width = 10, height = 6)

cat("\n=== WORKSHOP COMPLETE ===\n")
cat("Explore further by:\n")
cat("1. Examining other variables in the dataset\n")
cat("2. Creating additional cross-tabulations\n")
cat("3. Building regression models\n")
cat("4. Filtering by specific subgroups\n")
cat("5. Creating custom visualizations\n")

# 13. PRACTICE EXERCISES ======================================================

cat("\n=== PRACTICE EXERCISES ===\n")
cat("1. Create a table showing health insurance coverage by wealth quintile\n")
cat("2. Visualize the relationship between books at home (EC1) and wealth\n")
cat("3. Analyze father's playtime (EC5EB) vs mother's playtime (EC5EA)\n")
cat("4. Compare current ECE attendance (UB8) across wealth groups\n")
cat("5. Create a comprehensive dashboard with multiple visualizations\n")

# Example solution for Exercise 1:
cat("\n--- Exercise 1 Solution ---\n")
dfch |> 
  select(UB9, windex5) |> 
  haven::as_factor() |> 
  tbl_cross(
    row = UB9, 
    col = windex5,
    percent = "column",
    label = list(
      UB9 ~ "Health Insurance Coverage",
      windex5 ~ "Wealth Quintile"
    )
  ) |> 
  as_gt() |> 
  tab_header(
    title = "Health Insurance Coverage by Wealth Quintile",
    subtitle = "Column percentages shown"
  ) |>
  print()
# End of Script
