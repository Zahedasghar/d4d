# ============================================================================
# GRAPHING FOR BEGINNERS - Complete Visual Guide
# Making Beautiful Charts with ggplot2
# ============================================================================

library(tidyverse)
library(NHANES)

# Load and prepare data
data("NHANES")

my_data <- NHANES %>%
  select(ID, Gender, Age, Race1, Education, MaritalStatus,
         Height, Weight, BMI, BPSysAve, BPDiaAve,
         Diabetes, PhysActive, SmokeNow,
         HHIncome, Poverty) %>%
  distinct(ID, .keep_all = TRUE) %>%
  mutate(
    age_group = case_when(
      Age < 18 ~ "Under 18",
      Age >= 18 & Age < 35 ~ "18-34",
      Age >= 35 & Age < 50 ~ "35-49",
      Age >= 50 & Age < 65 ~ "50-64",
      Age >= 65 ~ "65+"
    ),
    bmi_category = case_when(
      BMI < 18.5 ~ "Underweight",
      BMI >= 18.5 & BMI < 25 ~ "Normal",
      BMI >= 25 & BMI < 30 ~ "Overweight",
      BMI >= 30 ~ "Obese"
    ),
    education_simple = case_when(
      Education %in% c("8th Grade", "9 - 11th Grade") ~ "Less than High School",
      Education == "High School" ~ "High School",
      Education == "Some College" ~ "Some College",
      Education == "College Grad" ~ "College Graduate"
    )
  )

# ============================================================================
# PART 1: BASIC BAR CHARTS
# ============================================================================

# Graph 1: Simple bar chart - Count by gender
my_data %>%
  filter(!is.na(Gender)) %>%
  ggplot(aes(x = Gender)) +
  geom_bar()

# Graph 2: Add color
my_data %>%
  filter(!is.na(Gender)) %>%
  ggplot(aes(x = Gender)) +
  geom_bar(fill = "steelblue")

# Graph 3: Add labels
my_data %>%
  filter(!is.na(Gender)) %>%
  ggplot(aes(x = Gender)) +
  geom_bar(fill = "steelblue") +
  labs(
    title = "Number of People by Gender",
    x = "Gender",
    y = "Number of People"
  )

# Graph 4: Color by category
my_data %>%
  filter(!is.na(Gender)) %>%
  ggplot(aes(x = Gender, fill = Gender)) +
  geom_bar() +
  labs(
    title = "Gender Distribution",
    x = "Gender",
    y = "Count"
  ) +
  theme_minimal()

# Graph 5: Count by age group
my_data %>%
  filter(!is.na(age_group)) %>%
  ggplot(aes(x = age_group)) +
  geom_bar(fill = "coral") +
  labs(
    title = "Number of People by Age Group",
    x = "Age Group",
    y = "Count"
  ) +
  theme_minimal()

# Graph 6: Horizontal bar chart
my_data %>%
  filter(!is.na(age_group)) %>%
  ggplot(aes(x = age_group)) +
  geom_bar(fill = "darkgreen") +
  coord_flip() +  # This makes it horizontal
  labs(
    title = "People by Age Group",
    x = "Age Group",
    y = "Count"
  ) +
  theme_minimal()

# ============================================================================
# PART 2: BAR CHARTS WITH PRE-CALCULATED VALUES
# ============================================================================

# Graph 7: Average BMI by gender
my_data %>%
  filter(!is.na(Gender), !is.na(BMI)) %>%
  group_by(Gender) %>%
  summarise(avg_bmi = mean(BMI)) %>%
  ggplot(aes(x = Gender, y = avg_bmi)) +
  geom_col(fill = "purple") +
  labs(
    title = "Average BMI by Gender",
    x = "Gender",
    y = "Average BMI"
  ) +
  theme_minimal()

# Graph 8: Diabetes percentage by age group
my_data %>%
  filter(!is.na(age_group), !is.na(Diabetes)) %>%
  group_by(age_group) %>%
  summarise(percent_diabetes = mean(Diabetes == "Yes") * 100) %>%
  ggplot(aes(x = age_group, y = percent_diabetes)) +
  geom_col(fill = "tomato") +
  labs(
    title = "Diabetes Prevalence by Age Group",
    x = "Age Group",
    y = "Percent with Diabetes (%)"
  ) +
  theme_minimal()

# Graph 9: Add value labels on bars
my_data %>%
  filter(!is.na(age_group), !is.na(Diabetes)) %>%
  group_by(age_group) %>%
  summarise(percent_diabetes = mean(Diabetes == "Yes") * 100) %>%
  ggplot(aes(x = age_group, y = percent_diabetes)) +
  geom_col(fill = "steelblue") +
  geom_text(aes(label = round(percent_diabetes, 1)), 
            vjust = -0.5, size = 4) +
  labs(
    title = "Diabetes Prevalence by Age",
    x = "Age Group",
    y = "Percent (%)"
  ) +
  theme_minimal()

# ============================================================================
# PART 3: GROUPED BAR CHARTS
# ============================================================================

# Graph 10: Count by age and gender
my_data %>%
  filter(!is.na(age_group), !is.na(Gender)) %>%
  ggplot(aes(x = age_group, fill = Gender)) +
  geom_bar(position = "dodge") +
  labs(
    title = "People by Age Group and Gender",
    x = "Age Group",
    y = "Count"
  ) +
  theme_minimal()

# Graph 11: Diabetes by age and gender
my_data %>%
  filter(!is.na(age_group), !is.na(Gender), !is.na(Diabetes)) %>%
  group_by(age_group, Gender) %>%
  summarise(percent_diabetes = mean(Diabetes == "Yes") * 100, .groups = "drop") %>%
  ggplot(aes(x = age_group, y = percent_diabetes, fill = Gender)) +
  geom_col(position = "dodge") +
  labs(
    title = "Diabetes Prevalence by Age and Gender",
    x = "Age Group",
    y = "Percent with Diabetes (%)",
    fill = "Gender"
  ) +
  theme_minimal()

# Graph 12: BMI categories by gender
my_data %>%
  filter(!is.na(Gender), !is.na(bmi_category)) %>%
  count(Gender, bmi_category) %>%
  group_by(Gender) %>%
  mutate(percent = n / sum(n) * 100) %>%
  ggplot(aes(x = Gender, y = percent, fill = bmi_category)) +
  geom_col(position = "dodge") +
  labs(
    title = "BMI Categories by Gender",
    x = "Gender",
    y = "Percent (%)",
    fill = "BMI Category"
  ) +
  theme_minimal()

# ============================================================================
# PART 4: STACKED BAR CHARTS
# ============================================================================

# Graph 13: Stacked bars - BMI by gender
my_data %>%
  filter(!is.na(Gender), !is.na(bmi_category)) %>%
  ggplot(aes(x = Gender, fill = bmi_category)) +
  geom_bar() +
  labs(
    title = "BMI Categories by Gender (Stacked)",
    x = "Gender",
    y = "Count",
    fill = "BMI Category"
  ) +
  theme_minimal()

# Graph 14: Stacked percentages
my_data %>%
  filter(!is.na(Gender), !is.na(bmi_category)) %>%
  ggplot(aes(x = Gender, fill = bmi_category)) +
  geom_bar(position = "fill") +
  labs(
    title = "BMI Categories by Gender (100% Stacked)",
    x = "Gender",
    y = "Proportion",
    fill = "BMI Category"
  ) +
  scale_y_continuous(labels = scales::percent) +
  theme_minimal()

# ============================================================================
# PART 5: HISTOGRAMS
# ============================================================================

# Graph 15: Simple histogram - BMI distribution
my_data %>%
  filter(!is.na(BMI), BMI < 60) %>%
  ggplot(aes(x = BMI)) +
  geom_histogram() +
  labs(
    title = "Distribution of BMI",
    x = "BMI",
    y = "Count"
  ) +
  theme_minimal()

# Graph 16: Histogram with more bins
my_data %>%
  filter(!is.na(BMI), BMI < 60) %>%
  ggplot(aes(x = BMI)) +
  geom_histogram(bins = 40, fill = "steelblue", color = "white") +
  labs(
    title = "Distribution of BMI",
    x = "BMI",
    y = "Count"
  ) +
  theme_minimal()

# Graph 17: Histogram by gender (overlapping)
my_data %>%
  filter(!is.na(BMI), BMI < 60, !is.na(Gender)) %>%
  ggplot(aes(x = BMI, fill = Gender)) +
  geom_histogram(bins = 30, alpha = 0.6, position = "identity") +
  labs(
    title = "BMI Distribution by Gender",
    x = "BMI",
    y = "Count"
  ) +
  theme_minimal()

# Graph 18: Age distribution
my_data %>%
  filter(!is.na(Age)) %>%
  ggplot(aes(x = Age)) +
  geom_histogram(bins = 30, fill = "darkgreen", color = "white") +
  labs(
    title = "Age Distribution",
    x = "Age (years)",
    y = "Count"
  ) +
  theme_minimal()

# ============================================================================
# PART 6: BOX PLOTS
# ============================================================================

# Graph 19: Simple box plot - BMI by gender
my_data %>%
  filter(!is.na(Gender), !is.na(BMI), BMI < 60) %>%
  ggplot(aes(x = Gender, y = BMI)) +
  geom_boxplot() +
  labs(
    title = "BMI Distribution by Gender",
    x = "Gender",
    y = "BMI"
  ) +
  theme_minimal()

# Graph 20: Box plot with color
my_data %>%
  filter(!is.na(Gender), !is.na(BMI), BMI < 60) %>%
  ggplot(aes(x = Gender, y = BMI, fill = Gender)) +
  geom_boxplot() +
  labs(
    title = "BMI by Gender",
    x = "Gender",
    y = "BMI"
  ) +
  theme_minimal()

# Graph 21: Blood pressure by age group
my_data %>%
  filter(!is.na(age_group), !is.na(BPSysAve), BPSysAve < 200) %>%
  ggplot(aes(x = age_group, y = BPSysAve)) +
  geom_boxplot(fill = "lightblue") +
  labs(
    title = "Blood Pressure by Age Group",
    x = "Age Group",
    y = "Systolic Blood Pressure (mmHg)"
  ) +
  theme_minimal()

# Graph 22: Box plot by two variables (using facets)
my_data %>%
  filter(!is.na(age_group), !is.na(Gender), !is.na(BPSysAve), BPSysAve < 200) %>%
  ggplot(aes(x = age_group, y = BPSysAve, fill = age_group)) +
  geom_boxplot() +
  facet_wrap(~Gender) +
  labs(
    title = "Blood Pressure by Age and Gender",
    x = "Age Group",
    y = "Systolic Blood Pressure"
  ) +
  theme_minimal() +
  theme(legend.position = "none",
        axis.text.x = element_text(angle = 45, hjust = 1))

# ============================================================================
# PART 7: LINE CHARTS
# ============================================================================

# Graph 23: Diabetes trend by age
my_data %>%
  filter(!is.na(age_group), !is.na(Diabetes)) %>%
  group_by(age_group) %>%
  summarise(percent_diabetes = mean(Diabetes == "Yes") * 100) %>%
  ggplot(aes(x = age_group, y = percent_diabetes, group = 1)) +
  geom_line(color = "blue", size = 1.2) +
  geom_point(size = 3, color = "blue") +
  labs(
    title = "Diabetes Prevalence by Age",
    x = "Age Group",
    y = "Percent with Diabetes (%)"
  ) +
  theme_minimal()

# Graph 24: Line chart by gender
my_data %>%
  filter(!is.na(age_group), !is.na(Gender), !is.na(Diabetes)) %>%
  group_by(age_group, Gender) %>%
  summarise(percent_diabetes = mean(Diabetes == "Yes") * 100, .groups = "drop") %>%
  ggplot(aes(x = age_group, y = percent_diabetes, 
             color = Gender, group = Gender)) +
  geom_line(size = 1.2) +
  geom_point(size = 3) +
  labs(
    title = "Diabetes Prevalence by Age and Gender",
    x = "Age Group",
    y = "Percent with Diabetes (%)"
  ) +
  theme_minimal()

# Graph 25: Average BMI by age and gender
my_data %>%
  filter(!is.na(age_group), !is.na(Gender), !is.na(BMI)) %>%
  group_by(age_group, Gender) %>%
  summarise(avg_bmi = mean(BMI), .groups = "drop") %>%
  ggplot(aes(x = age_group, y = avg_bmi, 
             color = Gender, group = Gender)) +
  geom_line(size = 1.2) +
  geom_point(size = 3) +
  labs(
    title = "Average BMI by Age and Gender",
    x = "Age Group",
    y = "Average BMI"
  ) +
  theme_minimal()

# ============================================================================
# PART 8: SCATTER PLOTS
# ============================================================================

# Graph 26: Height vs Weight
my_data %>%
  filter(!is.na(Height), !is.na(Weight), Weight < 200) %>%
  ggplot(aes(x = Height, y = Weight)) +
  geom_point(alpha = 0.5) +
  labs(
    title = "Relationship Between Height and Weight",
    x = "Height (cm)",
    y = "Weight (kg)"
  ) +
  theme_minimal()

# Graph 27: Scatter plot with color by gender
my_data %>%
  filter(!is.na(Height), !is.na(Weight), !is.na(Gender), Weight < 200) %>%
  ggplot(aes(x = Height, y = Weight, color = Gender)) +
  geom_point(alpha = 0.5) +
  labs(
    title = "Height vs Weight by Gender",
    x = "Height (cm)",
    y = "Weight (kg)"
  ) +
  theme_minimal()

# Graph 28: Add trend line
my_data %>%
  filter(!is.na(Height), !is.na(Weight), Weight < 200) %>%
  ggplot(aes(x = Height, y = Weight)) +
  geom_point(alpha = 0.3) +
  geom_smooth(method = "lm", color = "red") +
  labs(
    title = "Height vs Weight with Trend Line",
    x = "Height (cm)",
    y = "Weight (kg)"
  ) +
  theme_minimal()

# Graph 29: Age vs Blood Pressure
my_data %>%
  filter(!is.na(Age), !is.na(BPSysAve), BPSysAve < 200) %>%
  ggplot(aes(x = Age, y = BPSysAve)) +
  geom_point(alpha = 0.3, color = "darkblue") +
  geom_smooth(method = "loess", color = "red") +
  labs(
    title = "Age vs Blood Pressure",
    x = "Age (years)",
    y = "Systolic Blood Pressure (mmHg)"
  ) +
  theme_minimal()

# ============================================================================
# PART 9: POPULATION PYRAMID
# ============================================================================

# Graph 30: Population pyramid (age-sex structure)
my_data %>%
  filter(!is.na(age_group), !is.na(Gender)) %>%
  count(age_group, Gender) %>%
  mutate(n = ifelse(Gender == "male", -n, n)) %>%
  ggplot(aes(x = age_group, y = n, fill = Gender)) +
  geom_col() +
  coord_flip() +
  scale_y_continuous(
    labels = abs,
    name = "Population Count"
  ) +
  labs(
    title = "Population Pyramid by Age and Gender",
    x = "Age Group"
  ) +
  theme_minimal()

# ============================================================================
# PART 10: FACETED PLOTS (SMALL MULTIPLES)
# ============================================================================

# Graph 31: BMI distribution by age group
my_data %>%
  filter(!is.na(BMI), BMI < 60, !is.na(age_group)) %>%
  ggplot(aes(x = BMI)) +
  geom_histogram(bins = 30, fill = "steelblue") +
  facet_wrap(~age_group) +
  labs(
    title = "BMI Distribution by Age Group",
    x = "BMI",
    y = "Count"
  ) +
  theme_minimal()

# Graph 32: Diabetes by education across genders
my_data %>%
  filter(!is.na(education_simple), !is.na(Gender), !is.na(Diabetes)) %>%
  group_by(education_simple, Gender) %>%
  summarise(percent_diabetes = mean(Diabetes == "Yes") * 100, .groups = "drop") %>%
  ggplot(aes(x = education_simple, y = percent_diabetes)) +
  geom_col(fill = "coral") +
  facet_wrap(~Gender) +
  labs(
    title = "Diabetes by Education Level and Gender",
    x = "Education",
    y = "Percent with Diabetes (%)"
  ) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

# ============================================================================
# PART 11: CUSTOMIZING COLORS
# ============================================================================

# Graph 33: Custom colors - manual
my_data %>%
  filter(!is.na(Gender)) %>%
  ggplot(aes(x = Gender, fill = Gender)) +
  geom_bar() +
  scale_fill_manual(values = c("male" = "steelblue", "female" = "coral")) +
  labs(title = "Gender Distribution with Custom Colors") +
  theme_minimal()

# Graph 34: Color palette
my_data %>%
  filter(!is.na(bmi_category), !is.na(Gender)) %>%
  count(Gender, bmi_category) %>%
  group_by(Gender) %>%
  mutate(percent = n / sum(n) * 100) %>%
  ggplot(aes(x = Gender, y = percent, fill = bmi_category)) +
  geom_col(position = "dodge") +
  scale_fill_brewer(palette = "Set2") +
  labs(
    title = "BMI Categories by Gender",
    x = "Gender",
    y = "Percent (%)",
    fill = "BMI Category"
  ) +
  theme_minimal()

# Graph 35: Gradient colors for continuous data
my_data %>%
  filter(!is.na(Age), !is.na(BMI), BMI < 60) %>%
  ggplot(aes(x = Age, y = BMI, color = BMI)) +
  geom_point(alpha = 0.5) +
  scale_color_gradient(low = "green", high = "red") +
  labs(
    title = "Age vs BMI (colored by BMI value)",
    x = "Age",
    y = "BMI"
  ) +
  theme_minimal()

# ============================================================================
# PART 12: THEMES AND STYLING
# ============================================================================

# Graph 36: Different themes
# Theme: minimal
my_data %>%
  filter(!is.na(Gender)) %>%
  ggplot(aes(x = Gender, fill = Gender)) +
  geom_bar() +
  labs(title = "Theme: Minimal") +
  theme_minimal()

# Theme: classic
my_data %>%
  filter(!is.na(Gender)) %>%
  ggplot(aes(x = Gender, fill = Gender)) +
  geom_bar() +
  labs(title = "Theme: Classic") +
  theme_classic()

# Theme: dark
my_data %>%
  filter(!is.na(Gender)) %>%
  ggplot(aes(x = Gender, fill = Gender)) +
  geom_bar() +
  labs(title = "Theme: Dark") +
  theme_dark()

# Graph 37: Custom text sizes
my_data %>%
  filter(!is.na(age_group), !is.na(Diabetes)) %>%
  group_by(age_group) %>%
  summarise(percent_diabetes = mean(Diabetes == "Yes") * 100) %>%
  ggplot(aes(x = age_group, y = percent_diabetes)) +
  geom_col(fill = "steelblue") +
  labs(
    title = "Diabetes by Age Group",
    x = "Age Group",
    y = "Percent (%)"
  ) +
  theme_minimal(base_size = 16) +  # Larger text
  theme(
    plot.title = element_text(face = "bold", size = 20),
    axis.text.x = element_text(angle = 45, hjust = 1)
  )

# ============================================================================
# PART 13: COMBINING MULTIPLE PLOT TYPES
# ============================================================================

# Graph 38: Points and lines together
my_data %>%
  filter(!is.na(age_group), !is.na(BPSysAve)) %>%
  group_by(age_group) %>%
  summarise(
    avg_bp = mean(BPSysAve, na.rm = TRUE),
    se = sd(BPSysAve, na.rm = TRUE) / sqrt(n())
  ) %>%
  ggplot(aes(x = age_group, y = avg_bp, group = 1)) +
  geom_line(size = 1.2, color = "blue") +
  geom_point(size = 4, color = "red") +
  geom_errorbar(aes(ymin = avg_bp - se, ymax = avg_bp + se), width = 0.2) +
  labs(
    title = "Average Blood Pressure by Age (with error bars)",
    x = "Age Group",
    y = "Systolic BP (mmHg)"
  ) +
  theme_minimal()

# ============================================================================
# PART 14: SAVING YOUR PLOTS
# ============================================================================

# Save a single plot
my_plot <- my_data %>%
  filter(!is.na(age_group), !is.na(Diabetes)) %>%
  group_by(age_group) %>%
  summarise(percent_diabetes = mean(Diabetes == "Yes") * 100) %>%
  ggplot(aes(x = age_group, y = percent_diabetes)) +
  geom_col(fill = "steelblue") +
  labs(
    title = "Diabetes Prevalence by Age Group",
    x = "Age Group",
    y = "Percent with Diabetes (%)"
  ) +
  theme_minimal()

# Save as PNG (good for presentations)
ggsave("diabetes_plot.png", my_plot, width = 10, height = 6, dpi = 300)

# Save as PDF (good for publications)
ggsave("diabetes_plot.pdf", my_plot, width = 10, height = 6)

# Save as JPG
ggsave("diabetes_plot.jpg", my_plot, width = 10, height = 6, dpi = 300)

# ============================================================================
# PRACTICE EXERCISES
# ============================================================================

# Exercise 1: Create a bar chart showing count of people by education level
# Your code here:


# Exercise 2: Create a histogram of blood pressure
# Your code here:


# Exercise 3: Create a box plot comparing BMI between smokers and non-smokers
# Your code here:


# Exercise 4: Create a line chart showing obesity prevalence by age group
# Your code here:


# Exercise 5: Create a scatter plot of Age vs BMI, colored by Gender
# Your code here:


print("All graphs completed!")
print("Check the Plots pane in RStudio to see your visualizations")