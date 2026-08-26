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
  patchwork,
  gganimate,
  gifski,
  transformr
)

# ============================================================================
# 1. DATA COLLECTION - South Asian Countries
# ============================================================================

# Define South Asian countries
# south_asia_countries <- c(
#   "PK",  # Pakistan
#   "IN",  # India
#   "BD",  # Bangladesh
#   "LK",  # Sri Lanka
#   "NP",  # Nepal
#   "BT",  # Bhutan
#   "MV",  # Maldives
#   "AF"   # Afghanistan
# )

# Fetch demographic data for South Asian countries
# demographic_data <- WDI(
#   country = south_asia_countries,
#   indicator = c(
#     "SP.POP.TOTL",        # Total population
#     "SP.POP.GROW",        # Population growth (annual %)
#     "SP.DYN.CBRT.IN",     # Birth rate, crude (per 1,000 people)
#     "SP.DYN.CDRT.IN",     # Death rate, crude (per 1,000 people)
#     "SP.DYN.LE00.IN",     # Life expectancy at birth, total (years)
#     "SP.DYN.TFRT.IN",     # Fertility rate, total (births per woman)
#     "SP.URB.TOTL.IN.ZS",  # Urban population (% of total)
#     "SP.POP.DPND",        # Age dependency ratio (% of working-age population)
#     "SP.POP.0014.TO.ZS",  # Population ages 0-14 (% of total)
#     "SP.POP.65UP.TO.ZS",  # Population ages 65 and above (% of total)
#     "SP.DYN.IMRT.IN",     # Infant mortality rate (per 1,000 live births)
#     "SH.DYN.MORT"         # Under-5 mortality rate (per 1,000 live births)
#   ),
#   start = 1960,
#   end = 2024
# ) %>%
#   as_tibble()

# # Rename variables for easier handling
# demographic_data <- demographic_data %>%
#   rename(
#     total_pop = SP.POP.TOTL,
#     pop_growth = SP.POP.GROW,
#     birth_rate = SP.DYN.CBRT.IN,
#     death_rate = SP.DYN.CDRT.IN,
#     life_expectancy = SP.DYN.LE00.IN,
#     fertility_rate = SP.DYN.TFRT.IN,
#     urban_pop_pct = SP.URB.TOTL.IN.ZS,
#     dependency_ratio = SP.POP.DPND,
#     pop_0_14_pct = SP.POP.0014.TO.ZS,
#     pop_65_plus_pct = SP.POP.65UP.TO.ZS,
#     infant_mortality = SP.DYN.IMRT.IN,
#     under5_mortality = SH.DYN.MORT
#   )

## Save raw data for reference

#  write_csv(demographic_data, "south_asia_demographic_raw_data.csv")

demographic_data1 <- read_csv("south_asia_demographic_raw_data.csv")

# ============================================================================
# 2. DATA EXPLORATION - Basic Statistics
# ============================================================================

# Structure of the data
demographic_data1 %>% glimpse()

# Summary statistics by country
summary_by_country <- demographic_data1 %>%
  group_by(country) %>%
  summarise(
    years_of_data = n(),
    avg_pop_growth = mean(pop_growth, na.rm = TRUE),
    latest_fertility = last(na.omit(fertility_rate)),
    latest_infant_mortality = last(na.omit(infant_mortality)),
    .groups = 'drop'
  )

print(summary_by_country)

# Missing data analysis
missing_summary <- demographic_data %>%
  group_by(country) %>%
  summarise(across(where(is.numeric), ~sum(is.na(.)))) %>%
  pivot_longer(-country, names_to = "Variable", values_to = "Missing_Count") %>%
  arrange(country, desc(Missing_Count))

print(missing_summary)

# ============================================================================
# 3. STATIC VISUALIZATIONS - Comparative Analysis
# ============================================================================

# Plot 1: Fertility Rate Comparison (All South Asian Countries)
p1 <- demographic_data1 %>%
  filter(!is.na(fertility_rate)) %>%
  ggplot(aes(x = year, y = fertility_rate, color = country)) +
  geom_line(linewidth = 1.2) +
  theme_steve_web() + post_bg() +
  scale_x_continuous(breaks = seq(1960, 2024, by = 10)) +
  scale_color_brewer(palette = "Set2") +
  labs(
    x = "",
    y = "Births per Woman",
    color = "Country",
    title = "Total Fertility Rate in South Asia, 1960-2024",
    subtitle = "All countries show declining trends, with varying speeds",
    caption = "Data: World Bank via {WDI}"
  ) +
  theme(legend.position = "right")

print(p1)

# Plot 2: Birth Rate Comparison
p2 <- demographic_data1 %>%
  filter(!is.na(birth_rate)) %>%
  ggplot(aes(x = year, y = birth_rate, color = country)) +
  geom_line(size = 1.2) +
  theme_steve_web() + post_bg() +
  scale_x_continuous(breaks = seq(1960, 2024, by = 10)) +
  scale_color_brewer(palette = "Set2") +
  labs(
    x = "",
    y = "Birth Rate (per 1,000 people)",
    color = "Country",
    title = "Crude Birth Rate in South Asia, 1960-2024",
    subtitle = "Convergence of birth rates across the region",
    caption = "Data: World Bank via {WDI}"
  ) +
  theme(legend.position = "right")

print(p2)

# Plot 3: Population Growth Comparison
p3 <- demographic_data1 %>%
  filter(!is.na(pop_growth)) %>%
  ggplot(aes(x = year, y = pop_growth, color = country)) +
  geom_line(size = 1.2) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  theme_steve_web() + post_bg() +
  scale_x_continuous(breaks = seq(1960, 2024, by = 10)) +
  scale_color_brewer(palette = "Set2") +
  labs(
    x = "",
    y = "Annual Population Growth (%)",
    color = "Country",
    title = "Population Growth Rate in South Asia, 1960-2024",
    subtitle = "Declining growth rates across all countries",
    caption = "Data: World Bank via {WDI}"
  ) +
  theme(legend.position = "right")

print(p3)

# Plot 4: Infant Mortality Comparison
p4 <- demographic_data1 %>%
  filter(!is.na(infant_mortality)) %>%
  ggplot(aes(x = year, y = infant_mortality, color = country)) +
  geom_line(size = 1.2) +
  theme_steve_web() + post_bg() +
  scale_x_continuous(breaks = seq(1960, 2024, by = 10)) +
  scale_color_brewer(palette = "Set2") +
  labs(
    x = "",
    y = "Deaths per 1,000 Live Births",
    color = "Country",
    title = "Infant Mortality Rate in South Asia, 1960-2024",
    subtitle = "Dramatic improvements in child survival across the region",
    caption = "Data: World Bank via {WDI}"
  ) +
  theme(legend.position = "right")

print(p4)

# Plot 5: Under-5 Mortality Comparison
p5 <- demographic_data %>%
  filter(!is.na(under5_mortality)) %>%
  ggplot(aes(x = year, y = under5_mortality, color = country)) +
  geom_line(size = 1.2) +
  theme_steve_web() + post_bg() +
  scale_x_continuous(breaks = seq(1960, 2024, by = 10)) +
  scale_color_brewer(palette = "Set2") +
  labs(
    x = "",
    y = "Deaths per 1,000 Live Births",
    color = "Country",
    title = "Under-5 Mortality Rate in South Asia, 1960-2024",
    subtitle = "Significant progress in reducing child mortality",
    caption = "Data: World Bank via {WDI}"
  ) +
  theme(legend.position = "right")

print(p5)

# Combined plot using patchwork
(p1 + p2) / (p3 + p4) +
  plot_annotation(
    title = "Demographic Indicators in South Asia: 1960-2024",
    theme = theme(plot.title = element_text(size = 16, face = "bold"))
  )

# ============================================================================
# 4. ANIMATED VISUALIZATIONS using gganimate
# ============================================================================

# Animation 1: Fertility Rate Over Time (Animated)
anim_fertility <- demographic_data1 %>%
  filter(!is.na(fertility_rate), year >= 1960) %>%
  ggplot(aes(x = country, y = fertility_rate, fill = country)) +
  geom_col(show.legend = FALSE) + coord_flip() +
  theme_steve_web() + post_bg() +
  scale_fill_brewer(palette = "Set2") +
  labs(
    x = "",
    y = "Births per Woman",
    title = "Total Fertility Rate in South Asia",
    subtitle = "Year: {frame_time}",
    caption = "Data: World Bank via {WDI}"
  ) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  transition_time(year) +
  ease_aes('linear')







# Animation 1: Fertility Rate Over Time (Animated) with Flag Colors
# Animation 1: Fertility Rate Over Time (Animated) with Flag Colors

anim_fertility <- demographic_data1 %>%
  filter(!is.na(fertility_rate), year >= 1960) %>%
  ggplot(aes(x = country, y = fertility_rate, fill = country)) +
  geom_col(show.legend = FALSE) + 
  #coord_flip() +
  theme_steve_web() + 
  post_bg() +
  scale_fill_manual(values = c(
    "Afghanistan" = "#000000",
    "Bangladesh" = "#006A4E",
    "Bhutan"     = "#FF4E12",
    "India"      = "#FF9933",
    "Maldives"   = "#D21034",
    "Nepal"      = "#DC143C",
    "Pakistan"   = "#01411C",
    "Sri Lanka"  = "#8B4513"
  )) +
  labs(
    x = "",
    y = "Births per Woman",
    title = "Total Fertility Rate in South Asia",
    subtitle = "Year: {round(frame_time)}",   # FIX HERE
    caption = "Data: World Bank via {WDI}"
  ) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, size = 14),
    axis.text.y = element_text(size = 14),
    axis.title.x = element_text(size = 16),
    axis.title.y = element_text(size = 16)
  ) +
  transition_time(year) +
  ease_aes('linear')

anim_fertility

animate(anim_fertility, 
        nframes = 200, 
        fps = 10, 
        width = 800, 
        height = 600,
        renderer = gifski_renderer("firtility_rate_animation.gif")) 


# Animation 2: Birth Rate Racing Bar Chart
anim_birth <- demographic_data1 %>%
  filter(!is.na(birth_rate), year >= 1960) %>%
  ggplot(aes(x = country, y = birth_rate, fill = country)) +
  geom_col(show.legend = FALSE) +
  theme_steve_web() + post_bg() +
  scale_fill_brewer(palette = "Set2") +
  labs(
    x = "",
    y = "Birth Rate (per 1,000 people)",
    title = "Crude Birth Rate in South Asia",
    subtitle = "Year: {frame_time}",
    caption = "Data: World Bank via {WDI}"
  ) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  transition_time(year) +
  ease_aes('linear')

anim_birth



# Animation 1: Fertility Rate Over Time (Animated) with Flag Colors
anim_fertility <- demographic_data1 %>%
  filter(!is.na(fertility_rate), year >= 1960) %>%
  ggplot(aes(x = country, y = fertility_rate, fill = country)) +
  geom_col(show.legend = FALSE) + 
  coord_flip() +
  theme_steve_web() + 
  post_bg() +
  scale_fill_manual(values = c(
    "Afghanistan" = "#000000",      # Black (predominant in Afghan flag)
    "Bangladesh" = "#006A4E",       # Green (from Bangladesh flag)
    "Bhutan" = "#FF4E12",          # Orange/Saffron (from Bhutan flag)
    "India" = "#FF9933",           # Saffron (from Indian flag)
    "Maldives" = "#D21034",        # Red (from Maldives flag)
    "Nepal" = "#DC143C",           # Crimson (from Nepal flag)
    "Pakistan" = "#01411C",        # Dark green (from Pakistan flag)
    "Sri Lanka" = "#8B4513"        # Maroon/Brown (from Sri Lankan flag)
  )) +
  labs(
    x = "",
    y = "Births per Woman",
    title = "Total Fertility Rate in South Asia",
    subtitle = "Year: {frame_time}",
    caption = "Data: World Bank via {WDI}"
  ) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, size = 14),  # Increased x-axis text size
    axis.text.y = element_text(size = 14),                          # Increased y-axis (country names) text size
    axis.title.x = element_text(size = 16),                         # Increased x-axis title size
    axis.title.y = element_text(size = 16)                          # Increased y-axis title size
  ) +
  transition_time(year) +
  ease_aes('linear') 

animate(anim_fertility, 
        nframes = 200, 
        fps = 10, 
        width = 800, 
        height = 600,
        renderer = gifski_renderer("birth_rate_animation.gif"))


# Animation 1: Fertility Rate Over Time (Animated) with Flag Colors
anim_fertility <- demographic_data1 %>%
  filter(!is.na(fertility_rate), year >= 1960) %>%
  ggplot(aes(x = country, y = fertility_rate, fill = country)) +
  geom_col(show.legend = FALSE) + 
  coord_flip() +
  theme_steve_web() + 
  post_bg() +
  scale_fill_manual(values = c(
    "Afghanistan" = "#000000",   # Black
  "Bangladesh" = "#006A4E",    # Green (Bangladesh flag)
  "Bhutan" = "#FF4E12",        # Orange/Saffron
  "India" = "#FF9933",         # Saffron
  "Maldives" = "#D21034",      # Red
  "Nepal" = "#DC143C",         # Crimson
  "Pakistan" = "#01411C",      # Dark Green
  "Sri Lanka" = "#8B4513"      # Maroon/Brown  )) +
  labs(
    x = "",
    y = "Births per Woman",
    title = "Total Fertility Rate in South Asia",
    subtitle = "Year: {frame_time}",
    caption = "Data: World Bank via {WDI}"
  ) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, size = 14),  # Increased x-axis text size
    axis.text.y = element_text(size = 14),                          # Increased y-axis (country names) text size
    axis.title.x = element_text(size = 16),                         # Increased x-axis title size
    axis.title.y = element_text(size = 16)                          # Increased y-axis title size
  ) +
  transition_time(year) +
  ease_aes('linear')

# Animation 3: Population Growth with Line Reveal
anim_pop_growth <- demographic_data1 %>%
  filter(!is.na(pop_growth), year >= 1960) %>%
  ggplot(aes(x = year, y = pop_growth, color = country, group = country)) +
  geom_line(size = 1.2) +
  geom_point(size = 3) +
  theme_steve_web() + post_bg() +
  scale_color_brewer(palette = "Set2") +
  scale_x_continuous(breaks = seq(1960, 2024, by = 10)) +
  labs(
    x = "",
    y = "Annual Population Growth (%)",
    color = "Country",
    title = "Population Growth Rate in South Asia, 1960-2024",
    subtitle = "Revealing trends over time",
    caption = "Data: World Bank via {WDI}"
  ) +
  transition_reveal(year)

animate(anim_pop_growth, 
        nframes = 200, 
        fps = 10, 
        width = 800, 
        height = 600,
        renderer = gifski_renderer("pop_growth_animation.gif"))

# Animation 4: Infant Mortality Racing Lines
anim_infant <- demographic_data1 %>%
  filter(!is.na(infant_mortality), year >= 1960) %>%
  ggplot(aes(x = year, y = infant_mortality, color = country, group = country)) +
  geom_line(size = 1.5) +
  geom_point(size = 3) +
  theme_steve_web() + post_bg() +
  scale_color_brewer(palette = "Set2") +
  scale_x_continuous(breaks = seq(1960, 2024, by = 10)) +
  labs(
    x = "",
    y = "Deaths per 1,000 Live Births",
    color = "Country",
    title = "Infant Mortality Rate in South Asia",
    subtitle = "Progress over time",
    caption = "Data: World Bank via {WDI}"
  ) +
  transition_reveal(year)

animate(anim_infant, 
        nframes = 200, 
        fps = 10, 
        width = 800, 
        height = 600,
        renderer = gifski_renderer("infant_mortality_animation.gif"))

# Animation 5: Under-5 Mortality with Trail Effect
anim_under5 <- demographic_data1 %>%
  filter(!is.na(under5_mortality), year >= 1960) %>%
  ggplot(aes(x = year, y = under5_mortality, color = country, group = country)) +
  geom_line(line_width = 1.5) +
  geom_point(size = 3) +
  theme_steve_web() + post_bg() +
  scale_color_brewer(palette = "Set2") +
  scale_x_continuous(breaks = seq(1960, 2024, by = 10)) +
  labs(
    x = "",
    y = "Deaths per 1,000 Live Births",
    color = "Country",
    title = "Under-5 Mortality Rate in South Asia",
    subtitle = "Declining child mortality across the region",
    caption = "Data: World Bank via {WDI}"
  ) +
  transition_reveal(year)

animate(
  anim_faceted,
  nframes = 250,
  fps = 12,
  width = 1200,
  height = 1600,    # perfect for mobile screens
  dpi = 200,
  renderer = gifski_renderer("all_indicators_animation_highres.gif")
)




animate(anim_under5, 
        nframes = 250, 
        fps = 12, 
        width = 1200, 
        height = 1600,
        dpi=200,
        renderer = gifski_renderer("under5_mortality_animation.gif"))

# ============================================================================
# 5. SCATTER PLOT ANIMATIONS - Relationship Between Variables
# ============================================================================

# Animation 6: Fertility Rate vs Infant Mortality (Animated Scatter)
anim_scatter1 <- demographic_data1 %>%
  filter(!is.na(fertility_rate) & !is.na(infant_mortality), year >= 1960) %>%
  ggplot(aes(x = fertility_rate, y = infant_mortality, 
             color = country, size = total_pop)) +
  geom_point(alpha = 0.7) +
  theme_steve_web() + post_bg() +
  scale_color_brewer(palette = "Set2") +
  scale_size_continuous(range = c(3, 15), labels = comma) +
  labs(
    x = "Fertility Rate (births per woman)",
    y = "Infant Mortality Rate (per 1,000 live births)",
    color = "Country",
    size = "Population",
    title = "Fertility Rate vs Infant Mortality in South Asia",
    subtitle = "Year: {frame_time}",
    caption = "Data: World Bank via {WDI}"
  ) +
  transition_time(year) +
  ease_aes('linear')


animate(anim_scatter1, 
        nframes = 200, 
        fps = 10, 
        width = 800, 
        height = 600,
        renderer = gifski_renderer("fertility_vs_mortality_animation.gif"))

# Animation 7: Birth Rate vs Population Growth
anim_scatter2 <- demographic_data %>%
  filter(!is.na(birth_rate) & !is.na(pop_growth), year >= 1960) %>%
  ggplot(aes(x = birth_rate, y = pop_growth, 
             color = country, size = total_pop)) +
  geom_point(alpha = 0.7) +
  theme_steve_web() + post_bg() +
  scale_color_brewer(palette = "Set2") +
  scale_size_continuous(range = c(3, 15), labels = comma) +
  labs(
    x = "Birth Rate (per 1,000 people)",
    y = "Population Growth (%)",
    color = "Country",
    size = "Population",
    title = "Birth Rate vs Population Growth in South Asia",
    subtitle = "Year: {frame_time}",
    caption = "Data: World Bank via {WDI}"
  ) +
  transition_time(year) +
  ease_aes('linear')

animate(anim_scatter2, 
        nframes = 200, 
        fps = 10, 
        width = 800, 
        height = 600,
        renderer = gifski_renderer("birthrate_vs_popgrowth_animation.gif"))

# ============================================================================
# 6. FACETED ANIMATIONS
# ============================================================================

# Animation 8: All Key Indicators in One View (Faceted)
anim_faceted <- demographic_data1 %>%
  filter(year >= 1960) %>%
  select(country, year, fertility_rate, birth_rate, pop_growth, 
         infant_mortality, under5_mortality) %>%
  pivot_longer(cols = c(fertility_rate, birth_rate, pop_growth, 
                        infant_mortality, under5_mortality),
               names_to = "indicator",
               values_to = "value") %>%
  filter(!is.na(value)) %>%
  ggplot(aes(x = year, y = value, color = country, group = country)) +
  geom_line(size = 1) +
  geom_point(size = 2) +
  facet_wrap(~indicator, scales = "free_y", ncol = 2) +
  theme_steve_web() + post_bg() +
  scale_color_brewer(palette = "Set2") +
  labs(
    x = "",
    y = "Value",
    color = "Country",
    title = "Key Demographic Indicators in South Asia",
    subtitle = "Multiple indicators showing regional trends",
    caption = "Data: World Bank via {WDI}"
  ) +
  theme(legend.position = "bottom") +
  transition_reveal(year)

animate(anim_faceted, 
        nframes = 200, 
        fps = 10, 
        width = 1000, 
        height = 800,
        renderer = gifski_renderer("all_indicators_animation.gif"))

# ============================================================================
# 7. SUMMARY STATISTICS TABLE
# ============================================================================

# Latest year statistics
latest_stats <- demographic_data1 %>%
  filter(year == max(year, na.rm = TRUE)) %>%
  select(country, fertility_rate, birth_rate, pop_growth, 
         infant_mortality, under5_mortality) %>%
  arrange(fertility_rate)

print(latest_stats)

# Decade-wise comparison
decade_comparison <- demographic_data1 %>%
  filter(year %in% c(1970, 1980, 1990, 2000, 2010, 2020)) %>%
  group_by(country, year) %>%
  summarise(
    fertility = mean(fertility_rate, na.rm = TRUE),
    birth = mean(birth_rate, na.rm = TRUE),
    pop_growth = mean(pop_growth, na.rm = TRUE),
    infant_mort = mean(infant_mortality, na.rm = TRUE),
    under5_mort = mean(under5_mortality, na.rm = TRUE),
    .groups = 'drop'
  ) %>%
  arrange(country, year)

print(decade_comparison)

# ============================================================================
# 8. REGIONAL AVERAGES
# ============================================================================

# Calculate South Asia regional average
regional_avg <- demographic_data %>%
  group_by(year) %>%
  summarise(
    avg_fertility = mean(fertility_rate, na.rm = TRUE),
    avg_birth = mean(birth_rate, na.rm = TRUE),
    avg_pop_growth = mean(pop_growth, na.rm = TRUE),
    avg_infant_mort = mean(infant_mortality, na.rm = TRUE),
    avg_under5_mort = mean(under5_mortality, na.rm = TRUE),
    .groups = 'drop'
  )

# Plot regional average
p_regional <- regional_avg %>%
  select(year, avg_fertility, avg_infant_mort, avg_under5_mort) %>%
  pivot_longer(cols = -year, names_to = "indicator", values_to = "value") %>%
  ggplot(aes(x = year, y = value, color = indicator)) +
  geom_line(size = 1.2) +
  geom_point(size = 2) +
  facet_wrap(~indicator, scales = "free_y", ncol = 1) +
  theme_steve_web() + post_bg() +
  scale_color_brewer(palette = "Set1") +
  labs(
    x = "",
    y = "Value",
    color = "Indicator",
    title = "South Asia Regional Averages, 1960-2024",
    subtitle = "Weighted average of key demographic indicators",
    caption = "Data: World Bank via {WDI}"
  ) +
  theme(legend.position = "none")

print(p_regional)

# ============================================================================
# 9. CORRELATION ANALYSIS BY COUNTRY
# ============================================================================

# Create correlation analysis for Pakistan
pak_cor <- demographic_data %>%
  filter(country == "Pakistan") %>%
  select(pop_growth, birth_rate, fertility_rate, 
         infant_mortality, under5_mortality) %>%
  na.omit() %>%
  cor()

corrplot(pak_cor, method = "color", type = "upper",
         tl.col = "black", tl.srt = 45,
         addCoef.col = "black", number.cex = 0.7,
         title = "Correlation Matrix: Pakistan Demographic Indicators",
         mar = c(0, 0, 2, 0))


library(gganimate)

# Bigger text for mobile
mobile_theme <- theme(
  text = element_text(size = 18),
  axis.text = element_text(size = 14),
  strip.text = element_text(size = 20),
  legend.text = element_text(size = 14),
  legend.title = element_text(size = 16)
)

anim_faceted <- demographic_data1 %>%
  filter(year >= 1960) %>%
  select(
    country, year,
    fertility_rate,
    birth_rate,
    infant_mortality,
    under5_mortality
  ) %>%
  pivot_longer(
    cols = c(fertility_rate, birth_rate, infant_mortality, under5_mortality),
    names_to = "indicator",
    values_to = "value"
  ) %>%
  filter(!is.na(value)) %>%
  ggplot(aes(x = year, y = value, color = country, group = country)) +
  geom_line(size = 1.2) +
  geom_point(size = 2.8) +
  facet_wrap(~indicator, scales = "free_y", ncol = 2) +
  theme_steve_web() + post_bg() +
  mobile_theme +
  scale_color_manual(values = sa_colors) +
  labs(
    x = "",
    y = "Value",
    color = "Country",
    title = "Key Demographic Indicators in South Asia",
    subtitle = "1960–Present",
    caption = "Data: World Bank via {WDI}"
  ) +
  theme(legend.position = "bottom") +
  transition_reveal(year)

animate(
  anim_faceted,
  nframes = 250,
  fps = 12,
  width = 1200,
  height = 1600,    # perfect for mobile screens
  dpi = 200,
  renderer = gifski_renderer("all_indicators_animation_highres.gif")
)



  
  
library(ggplot2)
library(gganimate)
library(dplyr)
  
# ============================================================================
# VERSION 1: IMPROVED geom_line (Current Code Enhanced)
# ============================================================================
anim_under5_improved <- demographic_data1 %>%
  filter(!is.na(under5_mortality), year >= 1960) %>%
  mutate(
    # Create variables for conditional styling
    line_size = ifelse(country == "Pakistan", 2.2, 1.2),
    point_size = ifelse(country == "Pakistan", 3.5, 2.5),
    line_alpha = ifelse(country == "Pakistan", 1, 0.7)
  ) %>%
  ggplot(aes(x = year, y = under5_mortality, group = country)) +
  
  # Other countries' lines (using Set2 palette)
  geom_line(
    data = . %>% filter(country != "Pakistan"),
    aes(color = country),
    linewidth = 1.2, 
    alpha = 0.7
  ) +
  
  # Pakistan line (thicker, dark green, drawn on top)
  geom_line(
    data = . %>% filter(country == "Pakistan"),
    color = "darkgreen",
    linewidth = 2.2, 
    alpha = 1
  ) +
  
  # Other countries' points
  geom_point(
    data = . %>% filter(country != "Pakistan"),
    aes(color = country),
    size = 2.5, 
    alpha = 0.8
  ) +
  
  # Pakistan points (larger, dark green)
  geom_point(
    data = . %>% filter(country == "Pakistan"),
    color = "darkgreen",
    size = 3.5, 
    alpha = 1
  ) +
  
  # Other countries' labels at the end
  geom_text(
    data = . %>% filter(year == max(year), country != "Pakistan"),
    aes(label = country, color = country),
    hjust = -0.1, 
    size = 3.5,
    fontface = "bold",
    show.legend = FALSE
  ) +
  
  # Pakistan label (dark green, larger and bolder)
  geom_text(
    data = . %>% filter(year == max(year), country == "Pakistan"),
    aes(label = country),
    color = "darkgreen",
    hjust = -0.1, 
    size = 4.5,  # Larger size for Pakistan
    fontface = "bold",
    show.legend = FALSE
  ) +
  
  theme_minimal(base_size = 14) +
  theme(
    # Responsive text sizing
    plot.title = element_text(size = 18, face = "bold", margin = margin(b = 10)),
    plot.subtitle = element_text(size = 14, margin = margin(b = 15), color = "gray30"),
    plot.caption = element_text(size = 10, color = "gray50", hjust = 0),
    
    # Legend improvements
    legend.position = "bottom",
    legend.direction = "horizontal",
    legend.title = element_text(size = 12, face = "bold"),
    legend.text = element_text(size = 11),
    legend.key.width = unit(1.5, "cm"),
    legend.box.spacing = unit(0.5, "cm"),
    
    # Grid and axes
    panel.grid.minor = element_blank(),
    panel.grid.major = element_line(color = "gray90", linewidth = 0.3),
    axis.text = element_text(size = 12),
    axis.title = element_text(size = 13, face = "bold"),
    
    # Mobile-friendly spacing
    plot.margin = margin(15, 25, 15, 15),
    panel.background = element_rect(fill = "white", color = NA),
    plot.background = element_rect(fill = "white", color = NA)
  ) +
  
  # Manual color scale: Set2 for other countries
  scale_color_brewer(palette = "Set2") +
  
  scale_x_continuous(breaks = seq(1960, 2020, by = 10), expand = expansion(mult = c(0.02, 0.15))) +
  scale_y_continuous(expand = expansion(mult = c(0.02, 0.05))) +
  
  labs(
    x = "Year",
    y = "Deaths per 1,000 Live Births",
    color = "Country",
    title = "Under-5 Mortality Rate in South Asia (Pakistan Dark Green)",
    subtitle = "Declining child mortality across the region (1960-2024)",
    caption = "Data: World Bank via {WDI}"
  ) +
  
  transition_reveal(year)

# Render with responsive dimensions
animate(
  anim_under5_improved, 
  nframes = 130,
  fps = 10,
  width = 900,
  height = 700,
  dpi = 150,
  renderer = gifski_renderer("under5_mortality_improved.gif")
)
# ============================================================================
# VERSION 2: geom_col (Bar Chart Race Style)
# ============================================================================

anim_under5_col <- demographic_data1 %>%
  filter(!is.na(under5_mortality), year >= 1960) %>%
  group_by(year) %>%
  arrange(year, desc(under5_mortality)) %>%
  mutate(rank = row_number()) %>%
  ungroup() %>%
  
  ggplot(aes(x = rank, y = under5_mortality, fill = country)) +
  geom_col(width = 0.8, alpha = 0.9) +
  
  # Add country labels inside bars
  geom_text(
    aes(label = country, y = 0),
    hjust = 0,
    nudge_y = 2,
    size = 5,
    fontface = "bold",
    color = "white"
  ) +
  
  # Add value labels at the end of bars
  geom_text(
    aes(label = round(under5_mortality, 1)),
    hjust = -0.1,
    size = 4.5,
    fontface = "bold"
  ) +
  
  coord_flip(clip = "off") +
  
  theme_minimal(base_size = 14) +
  theme(
    plot.title = element_text(size = 20, face = "bold", margin = margin(b = 10)),
    plot.subtitle = element_text(size = 14, margin = margin(b = 15)),
    plot.caption = element_text(size = 11, color = "gray50"),
    
    # Remove legend since labels are on bars
    legend.position = "none",
    
    # Clean axes
    axis.text.y = element_blank(),
    axis.ticks.y = element_blank(),
    axis.text.x = element_text(size = 12),
    axis.title.x = element_text(size = 13, face = "bold", margin = margin(t = 10)),
    
    panel.grid.major.y = element_blank(),
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_line(color = "gray90", linewidth = 0.3),
    
    plot.margin = margin(20, 60, 20, 20),
    panel.background = element_rect(fill = "white", color = NA),
    plot.background = element_rect(fill = "white", color = NA)
  ) +
  
  scale_fill_brewer(palette = "Set2") +
  scale_x_reverse() +  # Highest at top
  scale_y_continuous(expand = expansion(mult = c(0.02, 0.15))) +
  
  labs(
    x = NULL,
    y = "Deaths per 1,000 Live Births",
    title = "Under-5 Mortality Rate in South Asia",
    subtitle = "Year: {as.integer(frame_time)}",  # INTEGER YEAR FIX
    caption = "Data: World Bank via {WDI}"
  ) +
  
  transition_time(year) +
  ease_aes('linear')

# Render bar chart with OPTIMIZED DURATION
# Total duration: ~13 seconds (perfect for social media/presentations)
animate(
  anim_under5_col, 
  nframes = 130,     # Reduced from 250 (2 frames per year for smooth motion)
  fps = 10,          # Slightly slower for better readability
  width = 900, 
  height = 700,
  dpi = 150,
  renderer = gifski_renderer("under5_mortality_bars.gif")
)


# ============================================================================
# BONUS: Static faceted version (great for reports/presentations)
# ============================================================================

plot_faceted <- demographic_data1 %>%
  filter(!is.na(under5_mortality), year >= 1960) %>%
  ggplot(aes(x = year, y = under5_mortality, color = country, group = country)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 1.5) +
  facet_wrap(~country, scales = "free_y", ncol = 2) +
  theme_minimal(base_size = 12) +
  theme(
    strip.text = element_text(size = 13, face = "bold"),
    strip.background = element_rect(fill = "gray95", color = NA),
    legend.position = "none",
    panel.grid.minor = element_blank()
  ) +
  scale_color_brewer(palette = "Set2") +
  scale_x_continuous(breaks = seq(1960, 2020, by = 20)) +
  labs(
    x = "Year",
    y = "Deaths per 1,000 Live Births",
    title = "Under-5 Mortality Rate in South Asia (1960-2024)",
    caption = "Data: World Bank via {WDI}"
  )

ggsave("under5_mortality_faceted.png", plot_faceted, 
       width = 10, height = 12, dpi = 300)
# ============================================================================
# 10. SAVE OUTPUTS
# ============================================================================

# Save static plots
# ggsave("south_asia_fertility.png", p1, width = 12, height = 6)
# ggsave("south_asia_birth_rate.png", p2, width = 12, height = 6)
# ggsave("south_asia_pop_growth.png", p3, width = 12, height = 6)
# ggsave("south_asia_infant_mortality.png", p4, width = 12, height = 6)
# ggsave("south_asia_under5_mortality.png", p5, width = 12, height = 6)

# Export data
# write_csv(demographic_data, "south_asia_demographic_data.csv")
# write_csv(latest_stats, "south_asia_latest_statistics.csv")
# write_csv(regional_avg, "south_asia_regional_averages.csv")

# Make this plot for infant mortality similar as for under-5 mortality

# ============================================================================
# VERSION 1: IMPROVED geom_line (Current Code Enhanced)
# ============================================================================
anim_infant_improved <- demographic_data1 %>%
  filter(!is.na(under5_mortality), year >= 1960) %>%
  mutate(
    # Create variables for conditional styling
    line_size = ifelse(country == "Pakistan", 2.2, 1.2),
    point_size = ifelse(country == "Pakistan", 3.5, 2.5),
    line_alpha = ifelse(country == "Pakistan", 1, 0.7)
  ) %>%
  ggplot(aes(x = year, y = under5_mortality, group = country)) +
  
  # Other countries' lines (using Set2 palette)
  geom_line(
    data = . %>% filter(country != "Pakistan"),
    aes(color = country),
    linewidth = 1.2, 
    alpha = 0.7
  ) +
  
  # Pakistan line (thicker, dark green, drawn on top)
  geom_line(
    data = . %>% filter(country == "Pakistan"),
    color = "darkgreen",
    linewidth = 2.2, 
    alpha = 1
  ) +
  
  # Other countries' points
  geom_point(
    data = . %>% filter(country != "Pakistan"),
    aes(color = country),
    size = 2.5, 
    alpha = 0.8
  ) +
  
  # Pakistan points (larger, dark green)
  geom_point(
    data = . %>% filter(country == "Pakistan"),
    color = "darkgreen",
    size = 3.5, 
    alpha = 1
  ) +
  
  # Other countries' labels at the end
  geom_text(
    data = . %>% filter(year == max(year), country != "Pakistan"),
    aes(label = country, color = country),
    hjust = -0.1, 
    size = 3.5,
    fontface = "bold",
    show.legend = FALSE
  ) +
  
  # Pakistan label (dark green, larger and bolder)
  geom_text(
    data = . %>% filter(year == max(year), country == "Pakistan"),
    aes(label = country),
    color = "darkgreen",
    hjust = -0.1, 
    size = 4.5,  # Larger size for Pakistan
    fontface = "bold",
    show.legend = FALSE
  ) +
  
  theme_minimal(base_size = 14) +
  theme(
    # Responsive text sizing
    plot.title = element_text(size = 18, face = "bold", margin = margin(b = 10)),
    plot.subtitle = element_text(size = 14, margin = margin(b = 15), color = "gray30"),
    plot.caption = element_text(size = 10, color = "gray50", hjust = 0),
    
    # Legend improvements
    legend.position = "bottom",
    legend.direction = "horizontal",
    legend.title = element_text(size = 12, face = "bold"),
    legend.text = element_text(size = 11),
    legend.key.width = unit(1.5, "cm"),
    legend.box.spacing = unit(0.5, "cm"),
    
    # Grid and axes
    panel.grid.minor = element_blank(),
    panel.grid.major = element_line(color = "gray90", linewidth = 0.3),
    axis.text = element_text(size = 12),
    axis.title = element_text(size = 13, face = "bold"),
    
    # Mobile-friendly spacing
    plot.margin = margin(15, 25, 15, 15),
    panel.background = element_rect(fill = "white", color = NA),
    plot.background = element_rect(fill = "white", color = NA)
  ) +
  
  # Manual color scale: Set2 for other countries
  scale_color_brewer(palette = "Set2") +
  
  scale_x_continuous(breaks = seq(1960, 2020, by = 10), expand = expansion(mult = c(0.02, 0.15))) +
  scale_y_continuous(expand = expansion(mult = c(0.02, 0.05))) +
  
  labs(
    x = "Year",
    y = "Deaths per 1,000 Live Births",
    color = "Country",
    title = "Under-5 Mortality Rate in South Asia (Pakistan Dark Green)",
    subtitle = "Declining child mortality across the region (1960-2024)",
    caption = "Data: World Bank via {WDI}"
  ) +
  
  transition_reveal(year)

# Render with responsive dimensions
animate(
  anim_under5_improved, 
  nframes = 130,
  fps = 10,
  width = 900,
  height = 700,
  dpi = 150,
  renderer = gifski_renderer("under5_mortality_improved.gif")
)


anim_infant_improved <- demographic_data1 %>%
  filter(!is.na(infant_mortality), year >= 1960) %>%
  mutate(
    # Create variables for conditional styling
    line_size = ifelse(country == "Pakistan", 2.2, 1.2),
    point_size = ifelse(country == "Pakistan", 3.5, 2.5),
    line_alpha = ifelse(country == "Pakistan", 1, 0.7)
  ) %>%
  ggplot(aes(x = year, y = infant_mortality, group = country)) +
  
  # Other countries' lines (using Set2 palette)
  geom_line(
    data = . %>% filter(country != "Pakistan"),
    aes(color = country),
    linewidth = 1.2, 
    alpha = 0.7
  ) +
  
  # Pakistan line (thicker, dark green, drawn on top)
  geom_line(
    data = . %>% filter(country == "Pakistan"),
    color = "darkgreen",
    linewidth = 2.2, 
    alpha = 1
  ) +
  
  # Other countries' points
  geom_point(
    data = . %>% filter(country != "Pakistan"),
    aes(color = country),
    size = 2.5, 
    alpha = 0.8
  ) +
  
  # Pakistan points (larger, dark green)
  geom_point(
    data = . %>% filter(country == "Pakistan"),
    color = "darkgreen",
    size = 3.5, 
    alpha = 1
  ) +
  
  # Other countries' labels at the end
  geom_text(
    data = . %>% filter(year == max(year), country != "Pakistan"),
    aes(label = country, color = country),
    hjust = -0.1, 
    size = 3.5,
    fontface = "bold",
    show.legend = FALSE
  ) +
  
  # Pakistan label (dark green, larger and bolder)
  geom_text(
    data = . %>% filter(year == max(year), country == "Pakistan"),
    aes(label = country),
    color = "darkgreen",
    hjust = -0.1, 
    size = 4.5,  # Larger size for Pakistan
    fontface = "bold",
    show.legend = FALSE
  ) +
  
  theme_minimal(base_size = 14) +
  theme(
    # Responsive text sizing
    plot.title = element_text(size = 18, face = "bold", margin = margin(b = 10)),
    plot.subtitle = element_text(size = 14, margin = margin(b = 15), color = "gray30"),
    plot.caption = element_text(size = 10, color = "gray50", hjust = 0),
    
    # Legend improvements
    legend.position = "bottom",
    legend.direction = "horizontal",
    legend.title = element_text(size = 12, face = "bold"),
    legend.text = element_text(size = 11),
    legend.key.width = unit(1.5, "cm"),
    legend.box.spacing = unit(0.5, "cm"),
    
    # Grid and axes
    panel.grid.minor = element_blank(),
    panel.grid.major = element_line(color = "gray90", linewidth = 0.3),
    axis.text = element_text(size = 12),
    axis.title = element_text(size = 13, face = "bold"),
    
    # Mobile-friendly spacing
    plot.margin = margin(15, 25, 15, 15),
    panel.background = element_rect(fill = "white", color = NA),
    plot.background = element_rect(fill = "white", color = NA)
  ) +
  
  # Manual color scale: Set2 for other countries
  scale_color_brewer(palette = "Set2") +
  
  scale_x_continuous(breaks = seq(1960, 2020, by = 10), expand = expansion(mult = c(0.02, 0.15))) +
  scale_y_continuous(expand = expansion(mult = c(0.02, 0.05))) +
  
  labs(
    x = "Year",
    y = "Deaths per 1,000 Live Births",
    color = "Country",
    title = "Infant Mortality Rate in South Asia (Pakistan Dark Green)",
    subtitle = "Declining infant mortality across the region (1960-2024)",
    caption = "Data: World Bank via {WDI}"
  ) +
  
  transition_reveal(year)

# Render with responsive dimensions
animate(
  anim_infant_improved, 
  nframes = 130,
  fps = 10,
  width = 900,
  height = 700,
  dpi = 150,
  renderer = gifski_renderer("infant_mortality_improved.gif")
)









  
print("Analysis complete! All animations have been saved.")
print("Animation files created:")
print("  - fertility_rate_animation.gif")
print("  - birth_rate_animation.gif")
print("  - pop_growth_animation.gif")
print("  - infant_mortality_animation.gif")
print("  - under5_mortality_animation.gif")
print("  - fertility_vs_mortality_animation.gif")
print("  - birthrate_vs_popgrowth_animation.gif")
print("  - all_indicators_animation.gif")