# ============================================================================
# DHS Data Analysis - Alternative to Pollster Package
# Using: survey and srvyr packages
# ============================================================================

# STEP 1: Install and Load Required Packages
# ============================================================================

# Install packages if not already installed
if (!require("survey")) install.packages("survey", dependencies = TRUE)
if (!require("srvyr")) install.packages("srvyr", dependencies = TRUE)
if (!require("dplyr")) install.packages("dplyr", dependencies = TRUE)
if (!require("haven")) install.packages("haven", dependencies = TRUE)

# Load packages
library(survey)
library(srvyr)
library(dplyr)
library(haven)


# STEP 2: Load Your Data
# ============================================================================

# Load the RData file
load("D:/RepTemplates/pdhs/data/pkir.RData")

# View basic information
cat("Dataset loaded successfully!\n")
cat("Number of observations:", nrow(pkir), "\n")
cat("Number of variables:", ncol(pkir), "\n")


# STEP 3: Set Up Survey Design
# ============================================================================

# DHS surveys typically use:
# - Stratification (v023 or v022)
# - Clustering (v021)
# - Sampling weights (v005)

# Create survey design object using survey package
dhs_design <- svydesign(
  id = ~v021,              # Primary sampling unit (cluster)
  strata = ~v023,          # Stratification variable
  weights = ~v005,         # Sampling weight (divide by 1000000)
  data = pkir,
  nest = TRUE
)

# Note: DHS weights (v005) need to be divided by 1,000,000
# Let's create a properly weighted version
pkir$weight <- pkir$v005 / 1000000

dhs_design <- svydesign(
  id = ~v021,
  strata = ~v023,
  weights = ~weight,
  data = pkir,
  nest = TRUE
)

cat("\nSurvey design created successfully!\n")


# STEP 4: Alternative Approach Using srvyr (Tidyverse Style)
# ============================================================================

# Create survey design with srvyr (more intuitive)
dhs_srvyr <- pkir %>%
  as_survey_design(
    ids = v021,           # Cluster
    strata = v023,        # Stratification
    weights = weight,     # Sampling weight
    nest = TRUE
  )

cat("Srvyr design created successfully!\n")


# STEP 5: Basic Analysis Examples
# ============================================================================

# Example 1: Calculate weighted mean age
cat("\n=== Example 1: Weighted Mean Age ===\n")
mean_age <- svymean(~v012, dhs_design, na.rm = TRUE)
print(mean_age)

# With srvyr (tidyverse style)
mean_age_srvyr <- dhs_srvyr %>%
  summarise(mean_age = survey_mean(v012, na.rm = TRUE))
print(mean_age_srvyr)


# Example 2: Proportions by category (e.g., educational level)
cat("\n=== Example 2: Proportions by Educational Level ===\n")
edu_prop <- svymean(~factor(v106), dhs_design, na.rm = TRUE)
print(edu_prop)

# With srvyr
edu_prop_srvyr <- dhs_srvyr %>%
  group_by(v106) %>%
  summarise(
    n = survey_total(na.rm = TRUE),
    proportion = survey_mean(na.rm = TRUE)
  )
print(edu_prop_srvyr)


# Example 3: Cross-tabulation (e.g., education by urban/rural)
cat("\n=== Example 3: Cross-tabulation ===\n")
crosstab <- svytable(~v025 + v106, dhs_design)
print(crosstab)

# Get proportions
crosstab_prop <- prop.table(crosstab, margin = 1)
print(crosstab_prop)


# Example 4: Weighted totals
cat("\n=== Example 4: Weighted Totals ===\n")
total_pop <- svytotal(~factor(v025), dhs_design, na.rm = TRUE)
print(total_pop)


# Example 5: Subsetting and analysis
cat("\n=== Example 5: Analysis by Subgroup ===\n")

# Analyze only urban areas
urban_design <- subset(dhs_design, v025 == 1)
urban_mean_age <- svymean(~v012, urban_design, na.rm = TRUE)
cat("Mean age in urban areas:", urban_mean_age, "\n")

# With srvyr
urban_analysis <- dhs_srvyr %>%
  filter(v025 == 1) %>%
  summarise(mean_age = survey_mean(v012, na.rm = TRUE))
print(urban_analysis)


# STEP 6: Advanced Analysis Examples
# ============================================================================

# Example 6: Linear regression with survey weights
cat("\n=== Example 6: Weighted Regression ===\n")
model <- svyglm(v012 ~ factor(v025) + factor(v106), 
                design = dhs_design, 
                family = gaussian())
summary(model)


# Example 7: Logistic regression (binary outcome)
# Example: Predicting electricity access
cat("\n=== Example 7: Weighted Logistic Regression ===\n")
logit_model <- svyglm(v119 ~ v012 + factor(v025) + factor(v106), 
                      design = dhs_design, 
                      family = quasibinomial())
summary(logit_model)


# Example 8: Quantiles (e.g., median)
cat("\n=== Example 8: Weighted Quantiles ===\n")
age_quantiles <- svyquantile(~v012, dhs_design, 
                              quantiles = c(0.25, 0.5, 0.75),
                              na.rm = TRUE)
print(age_quantiles)


# Example 9: Domain estimation (subgroup analysis)
cat("\n=== Example 9: Domain Estimation ===\n")
# Mean age by region
age_by_region <- svyby(~v012, ~factor(v024), dhs_design, svymean, na.rm = TRUE)
print(age_by_region)

# With srvyr
age_by_region_srvyr <- dhs_srvyr |>
  filter(!is.na(v012)) |>  # Remove missing age values
  group_by(v024) |>
  summarise(
    mean_age = survey_mean(v012, na.rm = TRUE),
    n = n()  # Check sample size per group
  )

# STEP 7: Visualization with Survey Weights
# ============================================================================

# You can extract weighted estimates for plotting
# Example: Bar plot of educational distribution

edu_for_plot <- dhs_srvyr %>%
  group_by(v106) %>%
  summarise(proportion = survey_mean(na.rm = TRUE)) %>%
  filter(!is.na(v106))

# Basic plot
if (require("ggplot2")) {
  library(ggplot2)
  
  p <- ggplot(edu_for_plot, aes(x = factor(v106), y = proportion)) +
    geom_bar(stat = "identity", fill = "steelblue") +
    geom_errorbar(aes(ymin = proportion - 1.96*proportion_se, 
                      ymax = proportion + 1.96*proportion_se),
                  width = 0.2) +
    labs(title = "Educational Level Distribution (Weighted)",
         x = "Education Level",
         y = "Proportion") +
    theme_minimal()
  
  print(p)
  
  # Save plot
  ggsave("education_distribution.png", p, width = 8, height = 6)
  cat("\nPlot saved as 'education_distribution.png'\n")
}


# STEP 8: Export Results
# ============================================================================

# Example: Save summary statistics to CSV
summary_stats <- dhs_srvyr %>%
  summarise(
    mean_age = survey_mean(v012, na.rm = TRUE),
    median_age = survey_median(v012, na.rm = TRUE),
    total_n = survey_total(na.rm = TRUE)
  )

write.csv(summary_stats, "summary_statistics.csv", row.names = FALSE)
cat("\nSummary statistics saved to 'summary_statistics.csv'\n")


# STEP 9: Tips and Best Practices
# ============================================================================

cat("\n=== Tips for Working Without Pollster ===\n")
cat("
1. The 'survey' package is the standard for complex survey analysis in R
2. The 'srvyr' package provides tidyverse-style syntax
3. Always use survey weights (v005/1000000 for DHS data)
4. Include stratification (v023) and clustering (v021) variables
5. Use svymean(), svytotal(), svyquantile() for descriptive statistics
6. Use svyglm() for regression models
7. Use svyby() for subgroup analysis
8. Use subset() to analyze specific subpopulations

Common DHS Variables:
- v005: Sampling weight (divide by 1,000,000)
- v021: Primary sampling unit (cluster)
- v022/v023: Stratification variables
- v012: Age of respondent
- v024: Region
- v025: Urban/rural (1=urban, 2=rural)
- v106: Educational level
- v190: Wealth index

For more information:
- survey package: https://cran.r-project.org/package=survey
- srvyr package: https://cran.r-project.org/package=srvyr
- DHS documentation: https://dhsprogram.com/
")


# STEP 10: Save workspace
# ============================================================================

cat("\n=== Analysis Complete ===\n")
cat("You can now perform your own analyses using the patterns above!\n")

# Optional: Save the survey design object for future use
# save(dhs_design, dhs_srvyr, file = "dhs_survey_design.RData")