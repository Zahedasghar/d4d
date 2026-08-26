if(!requireNamespace("pacman", quietly = TRUE)) {
  install.packages("pacman")
}
pacman::p_load(
  tidyverse,
  WDI,
  ggthemes,
  stevemisc,
  scales,
  corrplot,
  patchwork
)

library(tidyverse)
library(WDI)
library(ggthemes)
library(stevemisc)
library(scales)
library(corrplot)
library(patchwork)

# ============================================================================
# 1. DATA COLLECTION - Multiple Demographic Indicators
# ============================================================================

# Search for relevant demographic indicators
WDIsearch(string='population', field='name', cache=NULL)
WDIsearch(string='mortality', field='name', cache=NULL)
WDIsearch(string='birth', field='name', cache=NULL)

# Fetch comprehensive demographic data for Pakistan
demographic_data <- WDI(
  country = "PK",
  indicator = c(
    "SP.POP.TOTL",        # Total population
    "SP.POP.GROW",        # Population growth (annual %)
    "SP.DYN.CBRT.IN",     # Birth rate, crude (per 1,000 people)
    "SP.DYN.CDRT.IN",     # Death rate, crude (per 1,000 people)
    "SP.DYN.LE00.IN",     # Life expectancy at birth, total (years)
    "SP.DYN.TFRT.IN",     # Fertility rate, total (births per woman)
    "SP.URB.TOTL.IN.ZS",  # Urban population (% of total)
    "SP.POP.DPND",        # Age dependency ratio (% of working-age population)
    "SP.POP.0014.TO.ZS",  # Population ages 0-14 (% of total)
    "SP.POP.65UP.TO.ZS",  # Population ages 65 and above (% of total)
    "SP.DYN.IMRT.IN",     # Infant mortality rate (per 1,000 live births)
    "SH.DYN.MORT"         # Under-5 mortality rate (per 1,000 live births)
  ),
  start = 1960,
  end = 2024
) %>%
  as_tibble()

# Rename variables for easier handling
demographic_data <- demographic_data %>%
  rename(
    total_pop = SP.POP.TOTL,
    pop_growth = SP.POP.GROW,
    birth_rate = SP.DYN.CBRT.IN,
    death_rate = SP.DYN.CDRT.IN,
    life_expectancy = SP.DYN.LE00.IN,
    fertility_rate = SP.DYN.TFRT.IN,
    urban_pop_pct = SP.URB.TOTL.IN.ZS,
    dependency_ratio = SP.POP.DPND,
    pop_0_14_pct = SP.POP.0014.TO.ZS,
    pop_65_plus_pct = SP.POP.65UP.TO.ZS,
    infant_mortality = SP.DYN.IMRT.IN,
    under5_mortality = SH.DYN.MORT
  )

# ============================================================================
# 2. DATA EXPLORATION - Basic Statistics
# ============================================================================

# Structure of the data
demographic_data %>% glimpse()

# Summary statistics
summary(demographic_data)

# Missing data analysis
missing_summary <- demographic_data %>%
  summarise(across(where(is.numeric), ~sum(is.na(.)))) %>%
  pivot_longer(everything(), names_to = "Variable", values_to = "Missing_Count") %>%
  arrange(desc(Missing_Count))

print(missing_summary)

# Data completeness by year
completeness_by_year <- demographic_data %>%
  group_by(year) %>%
  summarise(
    variables_with_data = sum(!is.na(total_pop)) + sum(!is.na(pop_growth)) +
      sum(!is.na(birth_rate)) + sum(!is.na(death_rate)),
    .groups = 'drop'
  )

# ============================================================================
# 3. VISUALIZATIONS - Time Series Analysis
# ============================================================================

# Plot 1: Population Growth Over Time
p1 <- demographic_data %>%
  filter(!is.na(total_pop)) %>%
  ggplot(aes(x = year, y = total_pop / 1e6)) +
  geom_line(color = "#619cff", size = 1.2) +
  geom_point(color = "#619cff", size = 2, alpha = 0.6) +
  theme_steve_web() + post_bg() +
  scale_x_continuous(breaks = seq(1960, 2024, by = 10)) +
  scale_y_continuous(labels = comma) +
  labs(
    x = "",
    y = "Population (Millions)",
    title = "Pakistan's Population Growth, 1960-2024",
    subtitle = "Steady growth from 45M to over 240M people",
    caption = "Data: World Bank via {WDI}"
  )

p1
# Plot 2: Birth vs Death Rates
p2 <- demographic_data %>%
  filter(!is.na(birth_rate) & !is.na(death_rate)) %>%
  select(year, birth_rate, death_rate) %>%
  pivot_longer(cols = c(birth_rate, death_rate),
               names_to = "rate_type",
               values_to = "rate") %>%
  ggplot(aes(x = year, y = rate, color = rate_type)) +
  geom_line(size = 1.2) +
  theme_steve_web() + post_bg() +
  scale_color_manual(
    values = c("birth_rate" = "#00BA38", "death_rate" = "#F8766D"),
    labels = c("Birth Rate", "Death Rate")
  ) +
  scale_x_continuous(breaks = seq(1960, 2024, by = 10)) +
  labs(
    x = "",
    y = "Rate (per 1,000 people)",
    color = "Rate Type",
    title = "Birth and Death Rates in Pakistan",
    subtitle = "Both rates declining, but birth rate remains significantly higher",
    caption = "Data: World Bank via {WDI}"
  )

p2
# Plot 3: Life Expectancy Trend
p3 <- demographic_data %>%
  filter(!is.na(life_expectancy)) %>%
  ggplot(aes(x = year, y = life_expectancy)) +
  geom_area(fill = "#F8766D", alpha = 0.6) +
  geom_line(color = "#F8766D", size = 1.2) +
  theme_steve_web() + post_bg() +
  scale_x_continuous(breaks = seq(1960, 2024, by = 10)) +
  labs(
    x = "",
    y = "Years",
    title = "Life Expectancy at Birth in Pakistan",
    subtitle = "Remarkable improvement from ~45 years to ~67 years",
    caption = "Data: World Bank via {WDI}"
  )

p3

plotly::ggplotly(p3)

# Plot 4: Fertility Rate Decline
p4 <- demographic_data %>%
  filter(!is.na(fertility_rate)) %>%
  ggplot(aes(x = year, y = fertility_rate)) +
  geom_bar(stat = "identity", fill = "#00BFC4", alpha = 0.8, color = "black") +
  theme_steve_web() + post_bg() +
  scale_x_continuous(breaks = seq(1960, 2024, by = 10)) +
  labs(
    x = "",
    y = "Births per Woman",
    title = "Total Fertility Rate in Pakistan",
    subtitle = "Dramatic decline from ~7 births per woman to ~3.3",
    caption = "Data: World Bank via {WDI}"
  )

# Display individual plots
print(p1)
print(p2)
print(p3)
print(p4)

# Combined plot using patchwork
(p1 + p2) / (p3 + p4) +
  plot_annotation(
    title = "Demographic Transition in Pakistan: 1960-2024",
    theme = theme(plot.title = element_text(size = 16, face = "bold"))
  )

# ============================================================================
# 4. URBANIZATION ANALYSIS
# ============================================================================

p5 <- demographic_data %>%
  filter(!is.na(urban_pop_pct)) %>%
  mutate(urban_prop = urban_pop_pct / 100) %>%
  ggplot(aes(x = year, y = urban_prop)) +
  geom_area(fill = "#C77CFF", alpha = 0.6) +
  geom_line(color = "#C77CFF", size = 1.2) +
  theme_steve_web() + post_bg() +
  scale_x_continuous(breaks = seq(1960, 2024, by = 10)) +
  scale_y_continuous(labels = percent) +
  labs(
    x = "",
    y = "Urban Population (%)",
    title = "Urbanization in Pakistan, 1960-2024",
    subtitle = "Urban population increased from ~22% to ~38%",
    caption = "Data: World Bank via {WDI}"
  )

print(p5)

# ============================================================================
# 5. MORTALITY INDICATORS
# ============================================================================

p6 <- demographic_data %>%
  filter(!is.na(infant_mortality) & !is.na(under5_mortality)) %>%
  select(year, infant_mortality, under5_mortality) %>%
  pivot_longer(cols = c(infant_mortality, under5_mortality),
               names_to = "mortality_type",
               values_to = "rate") %>%
  ggplot(aes(x = year, y = rate, color = mortality_type)) +
  geom_line(size = 1.2) +
  theme_steve_web() + post_bg() +
  scale_color_manual(
    values = c("infant_mortality" = "#F8766D", "under5_mortality" = "#00BA38"),
    labels = c("Infant Mortality", "Under-5 Mortality")
  ) +
  scale_x_continuous(breaks = seq(1960, 2024, by = 10)) +
  labs(
    x = "",
    y = "Deaths per 1,000 Live Births",
    color = "Mortality Type",
    title = "Child Mortality Rates in Pakistan",
    subtitle = "Significant improvements in child survival rates",
    caption = "Data: World Bank via {WDI}"
  )

print(p6)

# ============================================================================
# 6. AGE STRUCTURE ANALYSIS
# ============================================================================

p7 <- demographic_data %>%
  filter(!is.na(pop_0_14_pct) & !is.na(pop_65_plus_pct)) %>%
  select(year, pop_0_14_pct, pop_65_plus_pct) %>%
  pivot_longer(cols = c(pop_0_14_pct, pop_65_plus_pct),
               names_to = "age_group",
               values_to = "percentage") %>%
  ggplot(aes(x = year, y = percentage, fill = age_group)) +
  geom_area(alpha = 0.6, position = "identity") +
  theme_steve_web() + post_bg() +
  scale_fill_manual(
    values = c("pop_0_14_pct" = "#619cff", "pop_65_plus_pct" = "#F8766D"),
    labels = c("Ages 0-14", "Ages 65+")
  ) +
  scale_x_continuous(breaks = seq(1960, 2024, by = 10)) +
  labs(
    x = "",
    y = "Percentage of Total Population",
    fill = "Age Group",
    title = "Age Structure Changes in Pakistan",
    subtitle = "Youth population declining, elderly population slowly increasing",
    caption = "Data: World Bank via {WDI}"
  )

print(p7)

# ============================================================================
# 7. CORRELATION ANALYSIS
# ============================================================================

# Create correlation matrix
cor_data <- demographic_data %>%
  select(pop_growth, birth_rate, death_rate, life_expectancy,
         fertility_rate, urban_pop_pct, infant_mortality, under5_mortality) %>%
  na.omit()

cor_matrix <- cor(cor_data)

# Visualize correlation matrix
corrplot(cor_matrix, method = "color", type = "upper",
         tl.col = "black", tl.srt = 45,
         addCoef.col = "black", number.cex = 0.7,
         title = "Correlation Matrix of Demographic Indicators",
         mar = c(0, 0, 2, 0))

# ============================================================================
# 8. RECENT TRENDS (Last 20 Years)
# ============================================================================

recent_trends <- demographic_data %>%
  filter(year >= 2004) %>%
  select(year, pop_growth, fertility_rate, life_expectancy, urban_pop_pct) %>%
  pivot_longer(cols = -year, names_to = "indicator", values_to = "value")

p8 <- recent_trends %>%
  ggplot(aes(x = year, y = value)) +
  geom_line(color = "#619cff", size = 1.2) +
  geom_point(color = "#619cff", size = 2) +
  facet_wrap(~indicator, scales = "free_y", ncol = 2) +
  theme_steve_web() + post_bg() +
  labs(
    x = "",
    y = "Value",
    title = "Recent Demographic Trends in Pakistan (2004-2024)",
    subtitle = "Small-multiple view of key indicators",
    caption = "Data: World Bank via {WDI}"
  )

print(p8)

# ============================================================================
# 9. SUMMARY STATISTICS TABLE
# ============================================================================

summary_stats <- demographic_data %>%
  summarise(
    across(
      c(total_pop, pop_growth, birth_rate, death_rate, life_expectancy,
        fertility_rate, urban_pop_pct, infant_mortality),
      list(
        mean = ~mean(., na.rm = TRUE),
        min = ~min(., na.rm = TRUE),
        max = ~max(., na.rm = TRUE),
        latest = ~last(na.omit(.))
      ),
      .names = "{.col}_{.fn}"
    )
  )

print(summary_stats)

# ============================================================================
# 10. DEMOGRAPHIC DIVIDEND ANALYSIS
# ============================================================================

# Calculate working-age population percentage
demographic_data <- demographic_data %>%
  mutate(
    working_age_pct = 100 - pop_0_14_pct - pop_65_plus_pct,
    demographic_window = working_age_pct > 60 & dependency_ratio < 50
  )

p9 <- demographic_data %>%
  filter(!is.na(working_age_pct)) %>%
  ggplot(aes(x = year, y = working_age_pct)) +
  geom_line(size = 1.2, color = "#00BA38") +
  geom_hline(yintercept = 60, linetype = "dashed", color = "red") +
  annotate("text", x = 1980, y = 62, label = "Demographic Dividend Threshold",
           color = "red") +
  theme_steve_web() + post_bg() +
  scale_x_continuous(breaks = seq(1960, 2024, by = 10)) +
  labs(
    x = "",
    y = "Working Age Population (%)",
    title = "Working-Age Population in Pakistan",
    subtitle = "Approaching demographic dividend window (>60% threshold)",
    caption = "Data: World Bank via {WDI}"
  )

print(p9)

# ============================================================================
# Save the plots
# ============================================================================

# Uncomment to save
# ggsave("pakistan_population.png", p1, width = 10, height = 6)
# ggsave("pakistan_birth_death.png", p2, width = 10, height = 6)
# ggsave("pakistan_life_expectancy.png", p3, width = 10, height = 6)
# ggsave("pakistan_combined_demographics.png",
#        (p1 + p2) / (p3 + p4), width = 14, height = 10)

print("Analysis complete!")
