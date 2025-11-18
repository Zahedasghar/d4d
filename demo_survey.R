# ====================================================================
# COMPREHENSIVE HEALTH DATA ANALYSIS
# Fertility, Mortality, and Child Health Analysis
# ====================================================================
if(!require(pacman)) install.packages("pacman")
pacman::p_load(haven, dplyr, ggplot2, tidyr, readr)


# Set theme for all plots
theme_set(theme_minimal())

# Define color palettes
fertility_colors <- c("#1f78b4", "#33a02c")
mortality_color <- "#d73027"
birth_color <- "#66bd63"

# ====================================================================
# 1. FERTILITY ANALYSIS - Fertility.sav
# ====================================================================

cat("\n=== FERTILITY ANALYSIS ===\n")

# Load data
fertility <- read_sav("data/Fertility.sav")

# --- 1.1 Age at First Marriage and First Birth -----------------------

# Calculate summary statistics (filtered for valid ages)
fertility_summary <- fertility %>%
  filter(AGE_AT_FIRST_BRITH > 0, AGE_AT_FIRST_MARRIAGE > 0) %>%
  summarise(
    n = n(),
    mean_age_marriage = round(mean(AGE_AT_FIRST_MARRIAGE, na.rm = TRUE), 2),
    sd_age_marriage = round(sd(AGE_AT_FIRST_MARRIAGE, na.rm = TRUE), 2),
    mean_age_first_birth = round(mean(AGE_AT_FIRST_BRITH, na.rm = TRUE), 2),
    sd_age_first_birth = round(sd(AGE_AT_FIRST_BRITH, na.rm = TRUE), 2)
  )

print(fertility_summary)

# --- 1.2 Visualizations -----------------------------------------------

# Histogram: Age at First Birth 
fertility %>%
 # filter(AGE_AT_FIRST_BRITH > 0, AGE_AT_FIRST_BRITH < 50) %>%
  ggplot(aes(x = AGE_AT_FIRST_BRITH)) +
  geom_histogram(binwidth = 1, fill = "#f03b20", color = "white", alpha = 0.8) +
  labs(
    title = "Distribution of Age at First Birth",
    x = "Age (years)",
    y = "Count"
  ) +
  theme_minimal()
p1 <- fertility %>%
  filter(AGE_AT_FIRST_BRITH > 0, AGE_AT_FIRST_BRITH < 50) %>%
  ggplot(aes(x = AGE_AT_FIRST_BRITH)) +
  geom_histogram(binwidth = 1, fill = "#f03b20", color = "white", alpha = 0.8) +
  labs(
    title = "Distribution of Age at First Birth",
    x = "Age (years)",
    y = "Count"
  ) +
  theme_minimal()

print(p1)

# Histogram: Age at First Marriage
p2 <- fertility %>%
  filter(AGE_AT_FIRST_MARRIAGE > 0, AGE_AT_FIRST_MARRIAGE < 50) %>%
  ggplot(aes(x = AGE_AT_FIRST_MARRIAGE)) +
  geom_histogram(binwidth = 1, fill = "#2b8cbe", color = "white", alpha = 0.8) +
  labs(
    title = "Distribution of Age at First Marriage",
    x = "Age (years)",
    y = "Count"
  ) +
  theme_minimal()

print(p2)

# Comparative Boxplot: Marriage vs Birth Age
fertility_long <- fertility %>%
  filter(AGE_AT_FIRST_MARRIAGE > 0, AGE_AT_FIRST_MARRIAGE < 50,
         AGE_AT_FIRST_BRITH > 0, AGE_AT_FIRST_BRITH < 50) %>%
  select(AGE_AT_FIRST_MARRIAGE, AGE_AT_FIRST_BRITH) %>%
  pivot_longer(
    cols = everything(),
    names_to = "Event",
    values_to = "Age"
  ) %>%
  mutate(Event = recode(Event,
                        "AGE_AT_FIRST_MARRIAGE" = "First Marriage",
                        "AGE_AT_FIRST_BRITH" = "First Birth"
  ))

p3 <- ggplot(fertility_long, aes(x = Event, y = Age, fill = Event)) +
  geom_boxplot(alpha = 0.7, outlier.alpha = 0.5) +
  stat_summary(fun = mean, geom = "point", shape = 23, size = 3, fill = "white") +
  labs(
    title = "Age at First Marriage vs First Birth",
    subtitle = "Diamond indicates mean value",
    x = "Life Event",
    y = "Age (years)"
  ) +
  scale_fill_manual(values = fertility_colors) +
  theme_minimal() +
  theme(legend.position = "none")

print(p3)

# --- 1.3 Children Ever Born and Living --------------------------------

children_summary <- fertility %>%
  summarise(
    n = n(),
    mean_boys_born = round(mean(BOYS_BORN_ALIVE, na.rm = TRUE), 2),
    mean_girls_born = round(mean(GIRLS_BORN_ALIVE, na.rm = TRUE), 2),
    mean_total_born = round(mean(BOYS_BORN_ALIVE + GIRLS_BORN_ALIVE, na.rm = TRUE), 2),
    mean_boys_living = round(mean(BOYS_BORN_ALIVE - BOYS_DIED, na.rm = TRUE), 2),
    mean_girls_living = round(mean(GIRLS_BORN_ALIVE - GIRLS_DIED, na.rm = TRUE), 2)
  )

print(children_summary)

# Visualization: Distribution of Total Children
p4 <- fertility %>%
  mutate(total_children = BOYS_BORN_ALIVE + GIRLS_BORN_ALIVE) %>%
  filter(total_children <= 15) %>%  # Remove extreme outliers for better visualization
  ggplot(aes(x = total_children)) +
  geom_bar(fill = "#74a9cf", alpha = 0.8) +
  labs(
    title = "Distribution of Children Ever Born",
    x = "Number of Children",
    y = "Number of Women"
  ) +
  scale_x_continuous(breaks = 0:15) +
  theme_minimal()

print(p4)

# --- 1.4 Stillbirths and Child Deaths ---------------------------------

mortality_summary <- fertility %>%
  summarise(
    n = n(),
    pct_stillbirth = round(100 * mean(HAD_STILL_BIRHT == 1, na.rm = TRUE), 2),
    mean_boys_died = round(mean(BOYS_DIED, na.rm = TRUE), 2),
    mean_girls_died = round(mean(GIRLS_DIED, na.rm = TRUE), 2),
    mean_total_died = round(mean(BOYS_DIED + GIRLS_DIED, na.rm = TRUE), 2)
  )

mortality_summary <- fertility %>%
  mutate(
    HAD_STILL_BIRHT_num = as.numeric(readr::parse_number(HAD_STILL_BIRHT))
  ) %>%
  summarise(
    n = n(),
    pct_stillbirth = round(100 * mean(HAD_STILL_BIRHT_num == 1, na.rm = TRUE), 2),
    mean_boys_died = round(mean(BOYS_DIED, na.rm = TRUE), 2),
    mean_girls_died = round(mean(GIRLS_DIED, na.rm = TRUE), 2),
    mean_total_died = round(mean(BOYS_DIED + GIRLS_DIED, na.rm = TRUE), 2)
  )




print(mortality_summary)

# ====================================================================
# 2. CHILD HEALTH ANALYSIS - Birth.sav
# ====================================================================

cat("\n=== CHILD HEALTH ANALYSIS ===\n")

# Load data
birth <- read_sav("Data/SPSS Data/Birth.sav")

# --- 2.1 Basic Summary ------------------------------------------------

birth_summary <- birth %>%
  summarise(
    total_births = n(),
    pct_alive = round(100 * mean(IS_ALIVE == 1, na.rm = TRUE), 2),
    mean_birth_year = round(mean(BIRTH_YEAR_BI, na.rm = TRUE), 0),
    median_birth_year = median(BIRTH_YEAR_BI, na.rm = TRUE)
  )

print(birth_summary)

# --- 2.2 Survival Outcomes --------------------------------------------

survival_stats <- birth %>%
  count(IS_ALIVE) %>%
  mutate(
    Status = if_else(IS_ALIVE == 1, "Alive", "Deceased"),
    percentage = round(100 * n / sum(n), 2)
  )

print(survival_stats)

p5 <- ggplot(survival_stats, aes(x = Status, y = n, fill = Status)) +
  geom_col(alpha = 0.8) +
  geom_text(aes(label = paste0(percentage, "%")), vjust = -0.5) +
  labs(
    title = "Child Survival Status",
    x = "Status",
    y = "Number of Children"
  ) +
  scale_fill_manual(values = c("Alive" = "#66bd63", "Deceased" = "#d73027")) +
  theme_minimal() +
  theme(legend.position = "none")

print(p5)

# --- 2.3 Place of Birth -----------------------------------------------

birth_place <- birth %>%
  count(BIRTH_PLACE) %>%
  mutate(
    percentage = round(100 * n / sum(n), 2),
    BIRTH_PLACE = as_factor(BIRTH_PLACE)
  ) %>%
  arrange(desc(percentage))

print(birth_place)

p6 <- ggplot(birth_place, aes(x = reorder(BIRTH_PLACE, percentage), y = percentage)) +
  geom_col(fill = "#1a9850", alpha = 0.8) +
  coord_flip() +
  labs(
    title = "Place of Birth Distribution",
    x = "Location",
    y = "Percentage (%)"
  ) +
  theme_minimal()

print(p6)

# --- 2.4 Delivery Assistance ------------------------------------------

delivery_assist <- birth %>%
  count(PERSON_ASSIS_DELIVERY) %>%
  mutate(
    percentage = round(100 * n / sum(n), 2),
    PERSON_ASSIS_DELIVERY = as_factor(PERSON_ASSIS_DELIVERY)
  ) %>%
  arrange(desc(percentage))

print(delivery_assist)

p7 <- ggplot(delivery_assist, aes(x = reorder(PERSON_ASSIS_DELIVERY, percentage), y = percentage)) +
  geom_col(fill = "#31a354", alpha = 0.8) +
  coord_flip() +
  labs(
    title = "Type of Delivery Assistance",
    x = "Assistance Type",
    y = "Percentage (%)"
  ) +
  theme_minimal()

print(p7)


# ====================================================================
# 3. MORTALITY ANALYSIS - Death.sav
# ====================================================================

cat("\n=== MORTALITY ANALYSIS ===\n")

# Load data
death <- read_sav("Data/SPSS Data/Death.sav")

# --- 3.1 Summary Statistics -------------------------------------------

death_summary <- death %>%
  summarise(
    total_deaths = n(),
    mean_age = round(mean(AGE_AT_DEATH, na.rm = TRUE), 2),
    median_age = round(median(AGE_AT_DEATH, na.rm = TRUE), 2),
    sd_age = round(sd(AGE_AT_DEATH, na.rm = TRUE), 2),
    min_age = min(AGE_AT_DEATH, na.rm = TRUE),
    max_age = max(AGE_AT_DEATH, na.rm = TRUE)
  )

print(death_summary)

# --- 3.2 Age at Death Distribution ------------------------------------

p8 <- ggplot(death, aes(x = AGE_AT_DEATH)) +
  geom_histogram(binwidth = 5, fill = mortality_color, color = "white", alpha = 0.8) +
  geom_vline(aes(xintercept = mean(AGE_AT_DEATH, na.rm = TRUE)),
             color = "blue", linetype = "dashed", size = 1) +
  geom_vline(aes(xintercept = median(AGE_AT_DEATH, na.rm = TRUE)),
             color = "darkgreen", linetype = "dashed", size = 1) +
  labs(
    title = "Age at Death Distribution",
    subtitle = "Blue = Mean, Green = Median",
    x = "Age (years)",
    y = "Frequency"
  ) +
  theme_minimal()

print(p8)

# --- 3.3 Deaths by Gender ---------------------------------------------

gender_stats <- death %>%
  count(GENDER) %>%
  mutate(
    Gender = as_factor(GENDER),
    percentage = round(100 * n / sum(n), 2)
  )

print(gender_stats)

p9 <- ggplot(gender_stats, aes(x = Gender, y = n, fill = Gender)) +
  geom_col(alpha = 0.8) +
  geom_text(aes(label = paste0(percentage, "%")), vjust = -0.5) +
  labs(
    title = "Distribution of Deaths by Gender",
    x = "Gender",
    y = "Number of Deaths"
  ) +
  scale_fill_manual(values = c("#fdae61", "#abd9e9")) +
  theme_minimal() +
  theme(legend.position = "none")

print(p9)

# --- 3.4 Leading Causes of Death --------------------------------------

cause_stats <- death %>%
  count(DEATH_CAUSE, sort = TRUE) %>%
  mutate(
    DEATH_CAUSE = as_factor(DEATH_CAUSE),
    percentage = round(100 * n / sum(n), 2)
  ) %>%
  top_n(10, n)

print(cause_stats)

p10 <- ggplot(cause_stats, aes(x = reorder(DEATH_CAUSE, n), y = n)) +
  geom_col(fill = "#4575b4", alpha = 0.8) +
  geom_text(aes(label = percentage), hjust = -0.2, size = 3) +
  coord_flip() +
  labs(
    title = "Top 10 Causes of Death",
    x = "Cause of Death",
    y = "Number of Deaths"
  ) +
  theme_minimal()

print(p10)


# ====================================================================
# 4. SAVE ALL PLOTS (Optional)
# ====================================================================

# Uncomment to save plots
# ggsave("fertility_age_first_birth.png", plot = p1, width = 10, height = 6)
# ggsave("fertility_age_first_marriage.png", plot = p2, width = 10, height = 6)
# ggsave("fertility_comparison_boxplot.png", plot = p3, width = 10, height = 6)
# ggsave("fertility_children_distribution.png", plot = p4, width = 10, height = 6)
# ggsave("birth_survival_status.png", plot = p5, width = 8, height = 6)
# ggsave("birth_place_distribution.png", plot = p6, width = 10, height = 6)
# ggsave("birth_delivery_assistance.png", plot = p7, width = 10, height = 6)
# ggsave("death_age_distribution.png", plot = p8, width = 10, height = 6)
# ggsave("death_by_gender.png", plot = p9, width = 8, height = 6)
# ggsave("death_top_causes.png", plot = p10, width = 10, height = 8)

cat("\n=== ANALYSIS COMPLETE ===\n")
