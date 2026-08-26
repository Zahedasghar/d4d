# ============================================================================
# Media Exposure and Modern Family Planning Analysis
# Pakistan Demographic Health Survey 2017-18
# Author: Zahid Asghar, School of Economics, QAU
# ============================================================================

# SETUP ======================================================================

# Install packages (uncomment if needed)
# install.packages(c("tidyverse", "haven", "survey", "srvyr", "gt", 
#                    "gtExtras", "broom", "corrplot", "gtsummary", "car"))

# Load packages
library(tidyverse)    # Data manipulation and visualization
library(haven)        # Read STATA/SPSS data
library(survey)       # Complex survey analysis
library(srvyr)        # Tidyverse-friendly survey package
library(gt)           # Beautiful tables
library(gtExtras)     # Additional gt features
library(gtsummary)    # Summary tables for regression
library(broom)        # Tidy model outputs
library(corrplot)     # Correlation plots
library(scales)       # Scale functions
library(car)          # VIF calculation

# Set options
options(survey.lonely.psu = "adjust")


# LOAD DATA ==================================================================

# Load the Pakistan DHS data
load("data/pkir.RData")

# Check dimensions
cat("Dataset dimensions:", nrow(pkir), "rows ×", ncol(pkir), "columns\n")


# DATA PREPARATION ===========================================================

# Create binary modern contraceptive use variable
pkir <- pkir %>%
  mutate(
    modfp = case_when(
      v313 == 3 ~ 1,    # Modern method
      v313 < 3 ~ 0,     # No method or traditional method
      TRUE ~ NA_real_
    ),
    modfp_label = factor(modfp, levels = 0:1, labels = c("No", "Yes"))
  )

# Create survey weight variable (DHS weights / 1,000,000)
pkir <- pkir %>%
  mutate(wt = v005 / 1000000)

# Recode education: combine secondary and higher
pkir <- pkir %>%
  mutate(
    edu = case_when(
      v106 == 0 ~ 0,   # No education
      v106 == 1 ~ 1,   # Primary
      v106 >= 2 ~ 2,   # Secondary or higher
      TRUE ~ NA_real_
    ),
    edu_label = factor(edu, 
                      levels = 0:2, 
                      labels = c("No education", "Primary", "Secondary+"))
  )

# Create family planning message exposure variable
pkir <- pkir %>%
  mutate(
    fpmessage = case_when(
      v384a == 1 | v384b == 1 | v384c == 1 ~ 1,  # Exposed
      v384a == 0 & v384b == 0 & v384c == 0 ~ 0,  # Not exposed
      TRUE ~ NA_real_
    ),
    fpmessage_label = factor(fpmessage, 
                            levels = 0:1, 
                            labels = c("No", "Yes"))
  )

# Create labeled versions of other variables
pkir <- pkir %>%
  mutate(
    age_group = factor(v013, 
                      levels = 1:7,
                      labels = c("15-19", "20-24", "25-29", "30-34", 
                                "35-39", "40-44", "45-49")),
    wealth = factor(v190,
                   levels = 1:5,
                   labels = c("Poorest", "Poorer", "Middle", "Richer", "Richest")),
    residence = factor(v025,
                      levels = 1:2,
                      labels = c("Urban", "Rural")),
    region = factor(v024,
                   levels = 1:8,
                   labels = c("Punjab", "Sindh", "KPK", "Balochistan",
                             "Gilgit Baltistan", "ICT", "FATA", "AJK"))
  )

# Filter to currently married women and select variables
mydata <- pkir %>%
  filter(v502 == 1) %>%
  select(
    modfp, modfp_label,
    fpmessage, fpmessage_label,
    edu, edu_label,
    age_group, wealth, residence, region,
    v021, v022, wt
  ) %>%
  drop_na()

cat("Final analytical sample:", nrow(mydata), "women\n")


# CREATE SURVEY DESIGN =======================================================

# Create survey design object
mysurvey <- mydata %>%
  as_survey_design(
    ids = v021,        # Cluster
    strata = v022,     # Stratification
    weights = wt,      # Weight
    nest = TRUE
  )

cat("Survey design created successfully!\n")


# DESCRIPTIVE STATISTICS =====================================================

# Table 1: Sample characteristics
desc_table <- mysurvey %>%
  tbl_svysummary(
    include = c(modfp_label, fpmessage_label, edu_label, 
                age_group, wealth, residence, region),
    label = list(
      modfp_label ~ "Modern contraceptive use",
      fpmessage_label ~ "FP message exposure",
      edu_label ~ "Education level",
      age_group ~ "Age group",
      wealth ~ "Wealth quintile",
      residence ~ "Place of residence",
      region ~ "Region"
    ),
    statistic = list(all_categorical() ~ "{n_unweighted} ({p}%)"),
    digits = all_categorical() ~ c(0, 1)
  ) %>%
  bold_labels()

print(desc_table)

# Weighted prevalence of modern contraceptive use
modfp_prev <- mysurvey %>%
  summarise(
    prevalence = survey_mean(modfp, na.rm = TRUE, vartype = "ci") * 100
  )

print(modfp_prev)


# BIVARIATE ANALYSIS =========================================================

# Create bivariate table
bivariate_table <- mysurvey %>%
  tbl_svysummary(
    by = modfp_label,
    include = c(fpmessage_label, edu_label, age_group, 
                wealth, residence, region),
    statistic = list(all_categorical() ~ "{p}%"),
    digits = all_categorical() ~ 1
  ) %>%
  add_p(test = list(all_categorical() ~ "svy.chisq.test")) %>%
  bold_p(t = 0.05) %>%
  bold_labels()

print(bivariate_table)

# Visualizations
plot_data <- mysurvey %>%
  group_by(fpmessage_label, edu_label) %>%
  summarise(prop = survey_mean(modfp, na.rm = TRUE, vartype = "ci"))

p1 <- ggplot(plot_data, aes(x = fpmessage_label, y = prop, fill = fpmessage_label)) +
  geom_col(show.legend = FALSE) +
  geom_errorbar(aes(ymin = prop_low, ymax = prop_upp), width = 0.2) +
  scale_y_continuous(labels = percent_format()) +
  scale_fill_brewer(palette = "Set2") +
  facet_wrap(~edu_label) +
  labs(
    title = "Modern Contraceptive Use by FP Message Exposure and Education",
    x = "FP Message Exposure",
    y = "Proportion"
  ) +
  theme_minimal()

print(p1)


# CORRELATION ANALYSIS =======================================================

# Create numeric versions for correlation
corr_data <- mydata %>%
  select(modfp, fpmessage, edu, wealth = v190, 
         residence = v025, age = v013) %>%
  mutate(across(everything(), as.numeric))

# Calculate and plot correlation matrix
cor_matrix <- cor(corr_data, use = "complete.obs")

corrplot(
  cor_matrix, 
  method = "color",
  type = "upper",
  addCoef.col = "black",
  number.cex = 0.7,
  tl.col = "black",
  tl.srt = 45,
  title = "Correlation Matrix",
  mar = c(0,0,2,0)
)


# REGRESSION ANALYSIS ========================================================

# Model 1: Unadjusted
model1 <- svyglm(
  modfp ~ fpmessage,
  design = mysurvey,
  family = quasibinomial(link = "logit")
)

tbl_model1 <- model1 %>%
  tbl_regression(
    exponentiate = TRUE,
    label = list(fpmessage ~ "FP message exposure (Yes vs No)")
  ) %>%
  bold_p(t = 0.05)

print(tbl_model1)

# Model 2: Adjusted
model2 <- svyglm(
  modfp ~ fpmessage + edu_label + age_group + wealth + residence + region,
  design = mysurvey,
  family = quasibinomial(link = "logit")
)

tbl_model2 <- model2 %>%
  tbl_regression(
    exponentiate = TRUE,
    label = list(
      fpmessage ~ "FP message exposure",
      edu_label ~ "Education level",
      age_group ~ "Age group",
      wealth ~ "Wealth quintile",
      residence ~ "Place of residence",
      region ~ "Region"
    )
  ) %>%
  bold_p(t = 0.10)

print(tbl_model2)

# Combined model comparison
tbl_merge <- tbl_merge(
  list(tbl_model1, tbl_model2),
  tab_spanner = c("**Unadjusted**", "**Adjusted**")
)

print(tbl_merge)


# ODDS RATIO PLOT ============================================================

# Extract and plot odds ratios
model2_tidy <- tidy(model2, conf.int = TRUE, exponentiate = TRUE) %>%
  filter(term != "(Intercept)") %>%
  mutate(
    term = case_when(
      term == "fpmessage" ~ "FP message: Yes",
      str_detect(term, "edu_label") ~ str_replace(term, "edu_label", "Education: "),
      str_detect(term, "age_group") ~ str_replace(term, "age_group", "Age: "),
      str_detect(term, "wealth") ~ str_replace(term, "wealth", "Wealth: "),
      str_detect(term, "residence") ~ str_replace(term, "residence", "Residence: "),
      str_detect(term, "region") ~ str_replace(term, "region", "Region: "),
      TRUE ~ term
    )
  )

p2 <- ggplot(model2_tidy, aes(x = estimate, y = reorder(term, estimate))) +
  geom_vline(xintercept = 1, linetype = "dashed", color = "red", alpha = 0.5) +
  geom_point(size = 3, color = "steelblue") +
  geom_errorbarh(aes(xmin = conf.low, xmax = conf.high), height = 0.2) +
  scale_x_continuous(trans = "log", breaks = c(0.5, 1, 2, 3, 4)) +
  labs(
    title = "Adjusted Odds Ratios for Modern Contraceptive Use",
    x = "Odds Ratio (log scale)",
    y = NULL
  ) +
  theme_minimal()

print(p2)


# MODEL DIAGNOSTICS ==========================================================

# Calculate VIF
model_unweighted <- glm(
  modfp ~ fpmessage + edu_label + age_group + wealth + residence + region,
  data = mydata,
  family = binomial
)

vif_values <- vif(model_unweighted)

vif_table <- data.frame(
  Variable = names(vif_values),
  VIF = vif_values
) %>%
  arrange(desc(VIF))

print(vif_table)


# RESULTS SUMMARY ============================================================

# Extract key statistics
unadj_or <- exp(coef(model1)["fpmessage"])
unadj_ci <- exp(confint(model1)["fpmessage", ])

adj_or <- exp(coef(model2)["fpmessage"])
adj_ci <- exp(confint(model2)["fpmessage", ])
adj_p <- summary(model2)$coefficients["fpmessage", "Pr(>|t|)"]

# Create summary
summary_table <- data.frame(
  Model = c("Unadjusted", "Adjusted"),
  OR = c(unadj_or, adj_or),
  CI_Lower = c(unadj_ci[1], adj_ci[1]),
  CI_Upper = c(unadj_ci[2], adj_ci[2])
)

print(summary_table)

# Print interpretation
cat("\n=== KEY FINDINGS ===\n\n")
cat("Unadjusted OR:", round(unadj_or, 2), 
    "(95% CI:", round(unadj_ci[1], 2), "-", round(unadj_ci[2], 2), ")\n")
cat("Adjusted OR:", round(adj_or, 2), 
    "(95% CI:", round(adj_ci[1], 2), "-", round(adj_ci[2], 2), ")\n")
cat("P-value:", round(adj_p, 3), "\n\n")

cat("INTERPRETATION:\n")
cat("Women exposed to FP messages through media had", round(adj_or, 2), 
    "times the odds\n")
cat("of using modern contraceptives after adjusting for confounders.\n")


# SAVE RESULTS ===============================================================

# Save key results
write_csv(summary_table, "results_summary.csv")
write_csv(model2_tidy, "odds_ratios.csv")
write_csv(vif_table, "vif_diagnostics.csv")

# Save plots
ggsave("contraceptive_use_by_exposure.png", p1, width = 10, height = 6)
ggsave("odds_ratios_plot.png", p2, width = 10, height = 8)

cat("\nAnalysis complete! Results saved.\n")


# SESSION INFO ===============================================================

sessionInfo()