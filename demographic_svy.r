# ==============================================================================
# FERTILITY DATA ANALYSIS IN R
# ==============================================================================

# INSTALLATION (run once if needed)
# install.packages(c("haven", "tidyverse", "ggplot2", "gridExtra", 
#                    "corrplot", "scales", "RColorBrewer"))

# Load required libraries
library(haven)        # For reading SPSS files
library(tidyverse)    # Data manipulation
library(ggplot2)      # Advanced visualization
library(gridExtra)    # Multiple plots
library(corrplot)     # Correlation matrices
library(scales)       # Axis formatting

# ==============================================================================
# 1. LOAD AND EXPLORE DATA
# ==============================================================================

# Load the SPSS data file
data <- read_sav("Fertility.sav")

# Initial exploration
print("=== VARIABLE NAMES ===")
names(data)

print("\n=== DATA STRUCTURE ===")
str(data)

print("\n=== SUMMARY STATISTICS ===")
summary(data)

print("\n=== MISSING VALUES ===")
colSums(is.na(data))

print("\n=== FIRST FEW ROWS ===")
head(data)

# ==============================================================================
# 2. AGE AT MARRIAGE ANALYSIS
# ==============================================================================

# Note: Adjust variable names (age_marriage, marriage_age, etc.) based on your data

# Histogram with mean and median
p1 <- ggplot(data, aes(x = age_marriage)) +
  geom_histogram(binwidth = 2, fill = "steelblue", color = "black", alpha = 0.7) +
  geom_vline(aes(xintercept = mean(age_marriage, na.rm = TRUE)), 
             color = "red", linetype = "dashed", linewidth = 1) +
  geom_vline(aes(xintercept = median(age_marriage, na.rm = TRUE)), 
             color = "green", linetype = "dashed", linewidth = 1) +
  labs(title = "Distribution of Age at Marriage",
       subtitle = "Red = Mean, Green = Median",
       x = "Age at Marriage (years)",
       y = "Frequency") +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5, face = "bold"))

# Density plot
p2 <- ggplot(data, aes(x = age_marriage)) +
  geom_density(fill = "lightblue", alpha = 0.6, color = "darkblue", linewidth = 1) +
  geom_vline(aes(xintercept = mean(age_marriage, na.rm = TRUE)), 
             color = "red", linetype = "dashed") +
  labs(title = "Density Distribution of Age at Marriage",
       x = "Age at Marriage (years)",
       y = "Density") +
  theme_minimal()

# Box plot
p3 <- ggplot(data, aes(x = "", y = age_marriage)) +
  geom_boxplot(fill = "coral", alpha = 0.7, outlier.color = "red") +
  stat_summary(fun = mean, geom = "point", shape = 23, size = 3, fill = "blue") +
  labs(title = "Box Plot of Age at Marriage",
       y = "Age at Marriage (years)") +
  theme_minimal() +
  coord_flip()

# Display plots
print(p1)
print(p2)
print(p3)

# Statistics
cat("\n=== AGE AT MARRIAGE STATISTICS ===\n")
cat("Mean:", round(mean(data$age_marriage, na.rm = TRUE), 2), "years\n")
cat("Median:", round(median(data$age_marriage, na.rm = TRUE), 2), "years\n")
cat("SD:", round(sd(data$age_marriage, na.rm = TRUE), 2), "years\n")
cat("Range:", min(data$age_marriage, na.rm = TRUE), "to", 
    max(data$age_marriage, na.rm = TRUE), "years\n")
cat("IQR:", round(IQR(data$age_marriage, na.rm = TRUE), 2), "years\n")

# ==============================================================================
# 3. FERTILITY PATTERNS
# ==============================================================================

# Bar chart
p4 <- ggplot(data, aes(x = factor(num_children))) +
  geom_bar(fill = "purple", alpha = 0.7) +
  geom_text(stat = "count", aes(label = after_stat(count)), vjust = -0.5) +
  labs(title = "Distribution of Number of Children",
       x = "Number of Children",
       y = "Frequency") +
  theme_minimal()

# Histogram
p5 <- ggplot(data, aes(x = num_children)) +
  geom_histogram(binwidth = 1, fill = "darkgreen", color = "black", alpha = 0.7) +
  labs(title = "Histogram of Number of Children",
       x = "Number of Children",
       y = "Frequency") +
  theme_minimal()

# Cumulative distribution
p6 <- ggplot(data, aes(x = num_children)) +
  stat_ecdf(geom = "step", color = "darkgreen", linewidth = 1.2) +
  labs(title = "Cumulative Distribution of Number of Children",
       x = "Number of Children",
       y = "Cumulative Proportion") +
  scale_y_continuous(labels = scales::percent) +
  theme_minimal()

print(p4)
print(p5)
print(p6)

# Statistics
cat("\n=== FERTILITY STATISTICS ===\n")
cat("Mean children:", round(mean(data$num_children, na.rm = TRUE), 2), "\n")
cat("Median children:", median(data$num_children, na.rm = TRUE), "\n")
cat("SD:", round(sd(data$num_children, na.rm = TRUE), 2), "\n")
cat("Range:", min(data$num_children, na.rm = TRUE), "to", 
    max(data$num_children, na.rm = TRUE), "\n")

# Frequency table
cat("\nFREQUENCY TABLE:\n")
print(table(data$num_children))
cat("\nPROPORTION TABLE (%):\n")
print(round(prop.table(table(data$num_children)) * 100, 2))

# ==============================================================================
# 4. MARRIAGE DURATION AND FERTILITY RELATIONSHIP
# ==============================================================================

# Calculate marriage duration if needed
# data$marriage_duration <- data$current_age - data$age_marriage

# Scatter plot with regression
p7 <- ggplot(data, aes(x = marriage_duration, y = num_children)) +
  geom_point(alpha = 0.4, color = "darkblue", size = 2) +
  geom_smooth(method = "lm", color = "red", se = TRUE, alpha = 0.2) +
  geom_smooth(method = "loess", color = "green", se = FALSE, linetype = "dashed") +
  labs(title = "Marriage Duration vs Number of Children",
       subtitle = "Red = Linear fit (95% CI), Green = LOESS curve",
       x = "Marriage Duration (years)",
       y = "Number of Children") +
  theme_minimal()

print(p7)

# Correlation test
cor_result <- cor.test(data$marriage_duration, data$num_children, 
                       use = "complete.obs", method = "pearson")
cat("\n=== CORRELATION: Marriage Duration vs Children ===\n")
cat("Pearson r:", round(cor_result$estimate, 3), "\n")
cat("p-value:", format(cor_result$p.value, scientific = TRUE), "\n")
cat("95% CI: [", round(cor_result$conf.int[1], 3), ",", 
    round(cor_result$conf.int[2], 3), "]\n")

# Create duration groups
data$duration_group <- cut(data$marriage_duration, 
                           breaks = c(-1, 5, 10, 15, 20, 25, 100),
                           labels = c("0-5", "6-10", "11-15", "16-20", "21-25", "25+"))

# Boxplot by duration
p8 <- ggplot(data, aes(x = duration_group, y = num_children, fill = duration_group)) +
  geom_boxplot(alpha = 0.7, outlier.color = "red") +
  stat_summary(fun = mean, geom = "point", shape = 23, size = 3, fill = "white") +
  scale_fill_brewer(palette = "Set2") +
  labs(title = "Number of Children by Marriage Duration",
       subtitle = "White diamond = Mean, Line = Median",
       x = "Marriage Duration (years)",
       y = "Number of Children") +
  theme_minimal() +
  theme(legend.position = "none")

print(p8)

# Summary by duration group
cat("\nMEAN CHILDREN BY DURATION GROUP:\n")
duration_summary <- data %>%
  group_by(duration_group) %>%
  summarise(
    n = n(),
    mean_children = mean(num_children, na.rm = TRUE),
    median_children = median(num_children, na.rm = TRUE),
    sd = sd(num_children, na.rm = TRUE)
  )
print(duration_summary)

# ==============================================================================
# 5. CHILD MORTALITY PATTERNS
# ==============================================================================

# Distribution of child deaths
p9 <- ggplot(data, aes(x = factor(child_deaths))) +
  geom_bar(fill = "darkred", alpha = 0.7) +
  geom_text(stat = "count", aes(label = after_stat(count)), vjust = -0.5) +
  labs(title = "Distribution of Child Deaths",
       x = "Number of Child Deaths",
       y = "Frequency") +
  theme_minimal()

print(p9)

# Calculate mortality rate
data$mortality_rate <- ifelse(data$num_children > 0, 
                              data$child_deaths / data$num_children, 
                              NA)

# Histogram of mortality rate
p10 <- ggplot(data[data$num_children > 0, ], aes(x = mortality_rate)) +
  geom_histogram(bins = 20, fill = "orange", color = "black", alpha = 0.7) +
  geom_vline(aes(xintercept = mean(mortality_rate, na.rm = TRUE)),
             color = "red", linetype = "dashed", linewidth = 1) +
  labs(title = "Distribution of Child Mortality Rate",
       subtitle = "Among families with at least one child (Red = Mean)",
       x = "Mortality Rate (Deaths/Total Children)",
       y = "Frequency") +
  scale_x_continuous(labels = scales::percent) +
  theme_minimal()

print(p10)

# Statistics
cat("\n=== CHILD MORTALITY STATISTICS ===\n")
cat("Total child deaths:", sum(data$child_deaths, na.rm = TRUE), "\n")
cat("Mean deaths per family:", round(mean(data$child_deaths, na.rm = TRUE), 2), "\n")
cat("Median deaths:", median(data$child_deaths, na.rm = TRUE), "\n")
cat("Families with deaths:", sum(data$child_deaths > 0, na.rm = TRUE), "\n")
cat("% families affected:", 
    round(mean(data$child_deaths > 0, na.rm = TRUE) * 100, 1), "%\n")
cat("Overall mortality rate:", 
    round(sum(data$child_deaths, na.rm = TRUE) / 
          sum(data$num_children, na.rm = TRUE) * 100, 2), "%\n")

# Mortality by family size
p11 <- ggplot(data, aes(x = factor(num_children), y = child_deaths)) +
  geom_boxplot(fill = "salmon", alpha = 0.7) +
  stat_summary(fun = mean, geom = "point", color = "darkred", size = 3) +
  labs(title = "Child Deaths by Total Number of Children",
       subtitle = "Red dot = Mean",
       x = "Total Number of Children",
       y = "Number of Child Deaths") +
  theme_minimal()

print(p11)

# Scatter plot
p12 <- ggplot(data, aes(x = num_children, y = child_deaths)) +
  geom_jitter(alpha = 0.3, width = 0.2, height = 0.2, color = "darkred") +
  geom_smooth(method = "lm", color = "blue", se = TRUE) +
  labs(title = "Total Children vs Child Deaths",
       x = "Total Number of Children",
       y = "Number of Child Deaths") +
  theme_minimal()

print(p12)

# Correlation
cor_mortality <- cor.test(data$num_children, data$child_deaths, 
                          use = "complete.obs")
cat("\nCORRELATION: Family Size vs Deaths\n")
cat("r =", round(cor_mortality$estimate, 3), "\n")
cat("p-value:", format(cor_mortality$p.value, scientific = TRUE), "\n")

# ==============================================================================
# 6. CHILD MORTALITY CORRELATES
# ==============================================================================

# Mortality by age at marriage
p13 <- ggplot(data, aes(x = age_marriage, y = child_deaths)) +
  geom_jitter(alpha = 0.3, width = 0.3, height = 0.2) +
  geom_smooth(method = "loess", color = "blue", se = TRUE) +
  labs(title = "Child Deaths vs Age at Marriage",
       x = "Age at Marriage",
       y = "Number of Child Deaths") +
  theme_minimal()

print(p13)

# Create age groups
data$age_group <- cut(data$age_marriage,
                      breaks = c(0, 18, 22, 26, 30, 100),
                      labels = c("<18", "18-22", "23-26", "27-30", "30+"))

# Mortality rate by age group
p14 <- ggplot(data[data$num_children > 0, ], aes(x = age_group, y = mortality_rate)) +
  geom_boxplot(fill = "lightcoral", alpha = 0.7) +
  stat_summary(fun = mean, geom = "point", size = 3, color = "darkred") +
  labs(title = "Child Mortality Rate by Age at Marriage",
       x = "Age at Marriage Group",
       y = "Mortality Rate") +
  scale_y_continuous(labels = scales::percent) +
  theme_minimal()

print(p14)

# Summary by age group
cat("\nMORTALITY BY AGE AT MARRIAGE GROUP:\n")
age_mortality <- data %>%
  filter(num_children > 0) %>%
  group_by(age_group) %>%
  summarise(
    n = n(),
    mean_deaths = mean(child_deaths, na.rm = TRUE),
    mean_mortality_rate = mean(mortality_rate, na.rm = TRUE)
  )
print(age_mortality)

# Heatmap
heatmap_data <- data %>%
  filter(!is.na(age_group) & !is.na(duration_group) & num_children > 0) %>%
  group_by(age_group, duration_group) %>%
  summarise(
    avg_mortality = mean(mortality_rate, na.rm = TRUE),
    .groups = "drop"
  )

p15 <- ggplot(heatmap_data, aes(x = duration_group, y = age_group, fill = avg_mortality)) +
  geom_tile(color = "white") +
  scale_fill_gradient(low = "lightyellow", high = "darkred", 
                      labels = scales::percent) +
  geom_text(aes(label = paste0(round(avg_mortality * 100, 1), "%")), 
            color = "black", size = 3) +
  labs(title = "Average Child Mortality Rate Heatmap",
       subtitle = "By Age at Marriage and Marriage Duration",
       x = "Marriage Duration",
       y = "Age at Marriage",
       fill = "Mortality\nRate") +
  theme_minimal()

print(p15)

# ==============================================================================
# 7. FAMILY SIZE DISTRIBUTION
# ==============================================================================

# Create family size categories
data$family_size_cat <- cut(data$num_children,
                            breaks = c(-1, 0, 2, 4, 6, 100),
                            labels = c("None", "1-2", "3-4", "5-6", "7+"))

# Bar chart
p16 <- ggplot(data, aes(x = family_size_cat, fill = family_size_cat)) +
  geom_bar(alpha = 0.8) +
  geom_text(stat = "count", aes(label = after_stat(count)), vjust = -0.5) +
  scale_fill_brewer(palette = "Set3") +
  labs(title = "Family Size Categories",
       x = "Number of Children",
       y = "Number of Families") +
  theme_minimal() +
  theme(legend.position = "none")

print(p16)

# Pie chart
family_dist <- data %>%
  group_by(family_size_cat) %>%
  summarise(count = n()) %>%
  mutate(percentage = count / sum(count) * 100)

p17 <- ggplot(family_dist, aes(x = "", y = count, fill = family_size_cat)) +
  geom_bar(stat = "identity", width = 1) +
  coord_polar("y", start = 0) +
  scale_fill_brewer(palette = "Set3") +
  labs(title = "Family Size Distribution",
       fill = "Children") +
  theme_void() +
  geom_text(aes(label = paste0(round(percentage, 1), "%")),
            position = position_stack(vjust = 0.5), size = 4)

print(p17)

cat("\n=== FAMILY SIZE DISTRIBUTION ===\n")
print(family_dist)

# ==============================================================================
# 8. GENDER COMPOSITION ANALYSIS
# ==============================================================================

# Distribution of boys
p18 <- ggplot(data, aes(x = factor(num_boys))) +
  geom_bar(fill = "steelblue", alpha = 0.7) +
  geom_text(stat = "count", aes(label = after_stat(count)), vjust = -0.5) +
  labs(title = "Distribution of Number of Boys per Family",
       x = "Number of Boys",
       y = "Frequency") +
  theme_minimal()

# Distribution of girls
p19 <- ggplot(data, aes(x = factor(num_girls))) +
  geom_bar(fill = "pink", alpha = 0.7) +
  geom_text(stat = "count", aes(label = after_stat(count)), vjust = -0.5) +
  labs(title = "Distribution of Number of Girls per Family",
       x = "Number of Girls",
       y = "Frequency") +
  theme_minimal()

# Side by side
grid.arrange(p18, p19, ncol = 2)

# Combined comparison
gender_long <- data %>%
  select(num_boys, num_girls) %>%
  pivot_longer(cols = everything(), names_to = "gender", values_to = "count")

p20 <- ggplot(gender_long, aes(x = factor(count), fill = gender)) +
  geom_bar(position = "dodge", alpha = 0.7) +
  scale_fill_manual(values = c("num_boys" = "steelblue", "num_girls" = "pink"),
                    labels = c("Boys", "Girls")) +
  labs(title = "Gender Distribution in Families",
       x = "Number of Children",
       y = "Frequency",
       fill = "Gender") +
  theme_minimal()

print(p20)

# Gender ratio
data$gender_ratio <- ifelse(data$num_children > 0,
                            data$num_boys / (data$num_boys + data$num_girls),
                            NA)

p21 <- ggplot(data[data$num_children > 0, ], aes(x = gender_ratio)) +
  geom_histogram(bins = 20, fill = "purple", color = "black", alpha = 0.7) +
  geom_vline(xintercept = 0.5, color = "red", linetype = "dashed", linewidth = 1.2) +
  labs(title = "Distribution of Gender Ratio in Families",
       subtitle = "Red line = 50% (expected ratio)",
       x = "Proportion of Boys",
       y = "Frequency") +
  scale_x_continuous(labels = scales::percent) +
  theme_minimal()

print(p21)

# Statistics
cat("\n=== GENDER COMPOSITION STATISTICS ===\n")
cat("Total boys:", sum(data$num_boys, na.rm = TRUE), "\n")
cat("Total girls:", sum(data$num_girls, na.rm = TRUE), "\n")
cat("Mean boys per family:", round(mean(data$num_boys, na.rm = TRUE), 2), "\n")
cat("Mean girls per family:", round(mean(data$num_girls, na.rm = TRUE), 2), "\n")
cat("Overall sex ratio (boys:girls):", 
    round(sum(data$num_boys, na.rm = TRUE) / 
          sum(data$num_girls, na.rm = TRUE), 3), "\n")
cat("Mean gender ratio:", round(mean(data$gender_ratio, na.rm = TRUE), 3), "\n")

# Chi-square test for sex ratio
total_boys <- sum(data$num_boys, na.rm = TRUE)
total_girls <- sum(data$num_girls, na.rm = TRUE)
sex_ratio_test <- chisq.test(c(total_boys, total_girls))

cat("\n=== SEX RATIO TEST (Chi-square) ===\n")
cat("Testing for 1:1 ratio\n")
cat("Chi-square =", round(sex_ratio_test$statistic, 3), "\n")
cat("p-value =", format(sex_ratio_test$p.value, scientific = TRUE), "\n")
if(sex_ratio_test$p.value < 0.05) {
  cat("Result: Significant deviation from 1:1 ratio\n")
} else {
  cat("Result: No significant deviation from 1:1 ratio\n")
}

# Gender by family size
gender_by_size <- data %>%
  filter(num_children > 0 & num_children <= 10) %>%
  group_by(num_children) %>%
  summarise(
    avg_boys = mean(num_boys, na.rm = TRUE),
    avg_girls = mean(num_girls, na.rm = TRUE)
  ) %>%
  pivot_longer(cols = c(avg_boys, avg_girls), 
               names_to = "gender", 
               values_to = "average")

p22 <- ggplot(gender_by_size, aes(x = factor(num_children), y = average, fill = gender)) +
  geom_bar(stat = "identity", position = "dodge", alpha = 0.7) +
  scale_fill_manual(values = c("avg_boys" = "steelblue", "avg_girls" = "pink"),
                    labels = c("Boys", "Girls")) +
  labs(title = "Average Gender Composition by Total Family Size",
       x = "Total Number of Children",
       y = "Average Count",
       fill = "Gender") +
  theme_minimal()

print(p22)

# ==============================================================================
# 9. CORRELATION MATRIX
# ==============================================================================

# Select numeric variables
numeric_vars <- data %>%
  select(where(is.numeric)) %>%
  select(-matches("^id$|case|index", ignore.case = TRUE))

# Correlation matrix
cor_matrix <- cor(numeric_vars, use = "pairwise.complete.obs")

# Visualize
corrplot(cor_matrix, method = "color", type = "upper",
         tl.col = "black", tl.srt = 45, tl.cex = 0.8,
         col = colorRampPalette(c("blue", "white", "red"))(200),
         title = "Correlation Matrix",
         mar = c(0, 0, 2, 0),
         addCoef.col = "black", number.cex = 0.7)

cat("\n=== CORRELATION MATRIX ===\n")
print(round(cor_matrix, 3))

# ==============================================================================
# 10. COMPREHENSIVE SUMMARY REPORT
# ==============================================================================

cat("\n")
cat(rep("=", 75), "\n", sep = "")
cat("         FERTILITY DATA ANALYSIS - SUMMARY REPORT\n")
cat(rep("=", 75), "\n", sep = "")

cat("\n1. SAMPLE OVERVIEW\n")
cat("   Total observations:", nrow(data), "\n")
cat("   Complete cases:", sum(complete.cases(data)), "\n")

cat("\n2. AGE AT MARRIAGE\n")
cat("   Mean:", round(mean(data$age_marriage, na.rm = TRUE), 2), "years\n")
cat("   Median:", round(median(data$age_marriage, na.rm = TRUE), 2), "years\n")
cat("   Range:", min(data$age_marriage, na.rm = TRUE), "-", 
    max(data$age_marriage, na.rm = TRUE), "years\n")

cat("\n3. FERTILITY OUTCOMES\n")
cat("   Mean children:", round(mean(data$num_children, na.rm = TRUE), 2), "\n")
cat("   Median children:", median(data$num_children, na.rm = TRUE), "\n")
cat("   Childless families:", sum(data$num_children == 0, na.rm = TRUE),
    "(", round(mean(data$num_children == 0, na.rm = TRUE) * 100, 1), "%)\n")

cat("\n4. MARRIAGE DURATION & FERTILITY\n")
cat("   Correlation (r):", 
    round(cor(data$marriage_duration, data$num_children, use = "complete.obs"), 3), "\n")
cat("   Mean duration:", round(mean(data$marriage_duration, na.rm = TRUE), 1), "years\n")

cat("\n5. CHILD MORTALITY\n")
cat("   Total deaths:", sum(data$child_deaths, na.rm = TRUE), "\n")
cat("   Families affected:", sum(data$child_deaths > 0, na.rm = TRUE),
    "(", round(mean(data$child_deaths > 0, na.rm = TRUE) * 100, 1), "%)\n")
cat("   Overall mortality rate:", 
    round(sum(data$child_deaths, na.rm = TRUE) / 
          sum(data$num_children, na.rm = TRUE) * 100, 2), "%\n")

cat("\n6. GENDER COMPOSITION\n")
cat("   Total boys:", sum(data$num_boys, na.rm = TRUE), "\n")
cat("   Total girls:", sum(data$num_girls, na.rm = TRUE), "\n")
cat("   Sex ratio (boys:girls):", 
    round(sum(data$num_boys, na.rm = TRUE) / 
          sum(data$num_girls, na.rm = TRUE), 3), "\n")

cat("\n")
cat(rep("=", 75), "\n", sep = "")
cat("Analysis Complete!\n")
cat("Note: Adjust variable names to match your actual dataset.\n")
cat(rep("=", 75), "\n", sep = "")

# ==============================================================================
# SAVE PLOTS (Optional - uncomment and modify paths as needed)
# ==============================================================================

# ggsave("01_age_marriage_histogram.png", p1, width = 10, height = 6, dpi = 300)
# ggsave("02_age_marriage_density.png", p2, width = 10, height = 6, dpi = 300)
# ggsave("03_fertility_distribution.png", p4, width = 10, height = 6, dpi = 300)
# ggsave("04_duration_fertility_scatter.png", p7, width = 10, height = 6, dpi = 300)
# ggsave("05_duration_fertility_boxplot.png", p8, width = 10, height = 6, dpi = 300)
# ggsave("06_child_mortality_dist.png", p9, width = 10, height = 6, dpi = 300)
# ggsave("07_mortality_rate_histogram.png", p10, width = 10, height = 6, dpi = 300)
# ggsave("08_mortality_by_size.png", p11, width = 10, height = 6, dpi = 300)
# ggsave("09_mortality_heatmap.png", p15, width = 10, height = 8, dpi = 300)
# ggsave("10_family_size_pie.png", p17, width = 8, height = 8, dpi = 300)
# ggsave("11_boys_distribution.png", p18, width = 10, height = 6, dpi = 300)
# ggsave("12_girls_distribution.png", p19, width = 10, height = 6, dpi = 300)
# ggsave("13_gender_ratio.png", p21, width = 10, height = 6, dpi = 300)
# ggsave("14_gender_by_size.png", p22, width = 10, height = 6, dpi = 300)

cat("\nAll visualizations generated successfully!\n")