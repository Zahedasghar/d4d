# =============================================================================
# Temperature Analysis: Lahore vs New Delhi (1950-2024)
# =============================================================================
# A comprehensive comparison of temperature trends between two major South Asian cities
# Data source: Open-Meteo API
# Author: Climate Analysis
# Date: 2024
# =============================================================================

# Load Required Libraries -----------------------------------------------------
library(openmeteo)
library(tidyverse)
library(xts)
library(forecast)
library(patchwork)  # For combining plots

# Data Collection -------------------------------------------------------------

# Fetch historical weather data for Lahore
lahore <- weather_history(
  location = "Lahore",
  start    = "1950-01-01",
  end      = "2026-08-21",
  daily    = c("temperature_2m_min", "temperature_2m_max",
               "temperature_2m_mean", "precipitation_sum")
)

# Fetch historical weather data for New Delhi
delhi <- weather_history(
  location = "New Delhi",
  start    = "1950-01-01",
  end      = "2026-08-21",
  daily    = c("temperature_2m_min", "temperature_2m_max",
               "temperature_2m_mean", "precipitation_sum")
)

# Data Preparation ------------------------------------------------------------

# Rename columns for clarity
colnames(lahore) <- c("date", "min_temp", "max_temp", "mean_temp", "precipitation")
colnames(delhi) <- c("date", "min_temp", "max_temp", "mean_temp", "precipitation")

# Remove missing values
lahore <- lahore %>% na.omit()
delhi <- delhi %>% na.omit()

# Add location identifier
lahore$location <- "Lahore"
delhi$location <- "New Delhi"

# Combine datasets
combined_data <- bind_rows(lahore, delhi)

# Add temporal features
combined_data <- combined_data %>%
  mutate(
    year = year(date),
    month = month(date),
    month_day = format(date, "%m-%d"),
    decade = floor(year / 10) * 10
  )

# Time Series Conversion -----------------------------------------------------

# Filter data from 1980 onwards for detailed analysis
combined_filtered <- combined_data %>%
  filter(date >= as.Date("1980-01-01"))

# Create separate XTS objects for each city
lahore_xts <- xts(lahore[, c("min_temp", "max_temp", "mean_temp")],
                  order.by = lahore$date)

delhi_xts <- xts(delhi[, c("min_temp", "max_temp", "mean_temp")],
                 order.by = delhi$date)

# Aggregate to yearly averages
lahore_yearly <- apply.yearly(lahore_xts, FUN = mean)
delhi_yearly <- apply.yearly(delhi_xts, FUN = mean)

# Convert XTS to data frame for ggplot
lahore_yearly_df <- data.frame(
  date = index(lahore_yearly),
  min_temp = coredata(lahore_yearly[, "min_temp"]),
  max_temp = coredata(lahore_yearly[, "max_temp"]),
  mean_temp = coredata(lahore_yearly[, "mean_temp"]),
  location = "Lahore"
)

delhi_yearly_df <- data.frame(
  date = index(delhi_yearly),
  min_temp = coredata(delhi_yearly[, "min_temp"]),
  max_temp = coredata(delhi_yearly[, "max_temp"]),
  mean_temp = coredata(delhi_yearly[, "mean_temp"]),
  location = "New Delhi"
)

# Combine yearly data
yearly_comparison <- bind_rows(lahore_yearly_df, delhi_yearly_df)

# Visualization ---------------------------------------------------------------

# Theme setup
custom_theme <- theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold", hjust = 0.5),
    plot.subtitle = element_text(size = 11, hjust = 0.5, color = "gray40"),
    plot.caption = element_text(size = 9, color = "gray50", hjust = 1),
    legend.position = "bottom",
    legend.title = element_blank(),
    panel.grid.minor = element_blank()
  )

# 1. Yearly Mean Temperature Comparison ---------------------------------------
plot1 <- ggplot(yearly_comparison, aes(x = date, y = mean_temp, color = location)) +
  geom_line(size = 1, alpha = 0.7) +
  geom_smooth(method = "loess", se = TRUE, alpha = 0.2) +
  scale_color_manual(values = c("Lahore" = "#E74C3C", "New Delhi" = "#3498DB")) +
  labs(
    title = "Yearly Mean Temperature: Lahore vs New Delhi (1950-2024)",
    subtitle = "Long-term temperature trends with smoothed trend lines",
    x = NULL,
    y = "Mean Temperature (°C)",
    caption = "Data source: Open-Meteo API"
  ) +
  custom_theme

# 2. Minimum Temperature Comparison -------------------------------------------
plot2 <- ggplot(yearly_comparison, aes(x = date, y = min_temp, color = location)) +
  geom_line(size = 1, alpha = 0.7) +
  geom_smooth(method = "loess", se = TRUE, alpha = 0.2) +
  scale_color_manual(values = c("Lahore" = "#E74C3C", "New Delhi" = "#3498DB")) +
  labs(
    title = "Yearly Minimum Temperature Trends",
    subtitle = "Average annual minimum temperatures",
    x = NULL,
    y = "Min Temperature (°C)",
    caption = "Data source: Open-Meteo API"
  ) +
  custom_theme

# 3. Maximum Temperature Comparison -------------------------------------------
plot3 <- ggplot(yearly_comparison, aes(x = date, y = max_temp, color = location)) +
  geom_line(size = 1, alpha = 0.7) +
  geom_smooth(method = "loess", se = TRUE, alpha = 0.2) +
  scale_color_manual(values = c("Lahore" = "#E74C3C", "New Delhi" = "#3498DB")) +
  labs(
    title = "Yearly Maximum Temperature Trends",
    subtitle = "Average annual maximum temperatures",
    x = "Year",
    y = "Max Temperature (°C)",
    caption = "Data source: Open-Meteo API"
  ) +
  custom_theme

# 4. Seasonal Analysis: Summer Months (May-September) ------------------------
summer_data <- combined_data %>%
  filter(month %in% 5:9) %>%
  group_by(year, location) %>%
  summarise(
    avg_max_temp = mean(max_temp, na.rm = TRUE),
    .groups = "drop"
  )

plot4 <- ggplot(summer_data, aes(x = year, y = avg_max_temp, color = location)) +
  geom_line(size = 1, alpha = 0.7) +
  geom_smooth(method = "lm", se = TRUE, alpha = 0.2, linetype = "dashed") +
  scale_color_manual(values = c("Lahore" = "#E74C3C", "New Delhi" = "#3498DB")) +
  labs(
    title = "Summer Maximum Temperatures (May-September)",
    subtitle = "Linear trend showing warming patterns",
    x = "Year",
    y = "Avg Max Temperature (°C)",
    caption = "Data source: Open-Meteo API"
  ) +
  custom_theme

# 5. Winter Analysis: January Minimum Temperatures ---------------------------
winter_data <- combined_data %>%
  filter(month == 1) %>%
  group_by(year, location) %>%
  summarise(
    avg_min_temp = mean(min_temp, na.rm = TRUE),
    .groups = "drop"
  )

plot5 <- ggplot(winter_data, aes(x = year, y = avg_min_temp, color = location)) +
  geom_line(size = 1, alpha = 0.7) +
  geom_smooth(method = "lm", se = TRUE, alpha = 0.2, linetype = "dashed") +
  scale_color_manual(values = c("Lahore" = "#E74C3C", "New Delhi" = "#3498DB")) +
  labs(
    title = "January Minimum Temperatures",
    subtitle = "Winter warming trends over time",
    x = "Year",
    y = "Avg Min Temperature (°C)",
    caption = "Data source: Open-Meteo API"
  ) +
  custom_theme

# 6. Temperature Distribution by Decade ---------------------------------------
plot6 <- ggplot(combined_data, aes(x = factor(decade), y = mean_temp, fill = location)) +
  geom_boxplot(alpha = 0.7, outlier.alpha = 0.3) +
  scale_fill_manual(values = c("Lahore" = "#E74C3C", "New Delhi" = "#3498DB")) +
  labs(
    title = "Temperature Distribution by Decade",
    subtitle = "Boxplots showing median, quartiles, and outliers",
    x = "Decade",
    y = "Mean Temperature (°C)",
    caption = "Data source: Open-Meteo API"
  ) +
  custom_theme

# 7. Recent Years Comparison (2000-2024) --------------------------------------
recent_data <- combined_data %>%
  filter(year >= 2000) %>%
  group_by(year, location) %>%
  summarise(
    mean_temp = mean(mean_temp, na.rm = TRUE),
    .groups = "drop"
  )

plot7 <- ggplot(recent_data, aes(x = year, y = mean_temp, color = location)) +
  geom_line(size = 1.2) +
  geom_point(size = 2) +
  scale_color_manual(values = c("Lahore" = "#E74C3C", "New Delhi" = "#3498DB")) +
  scale_x_continuous(breaks = seq(2000, 2024, 5)) +
  labs(
    title = "21st Century Temperature Trends",
    subtitle = "Annual mean temperatures since 2000",
    x = "Year",
    y = "Mean Temperature (°C)",
    caption = "Data source: Open-Meteo API"
  ) +
  custom_theme

# Statistical Summary ---------------------------------------------------------

# Calculate summary statistics
summary_stats <- combined_data %>%

  group_by(location) %>%
  summarise(
    mean_temperature = mean(mean_temp, na.rm = TRUE),
    min_temperature = min(min_temp, na.rm = TRUE),
    max_temperature = max(max_temp, na.rm = TRUE),
    sd_temperature = sd(mean_temp, na.rm = TRUE),
    median_temperature = median(mean_temp, na.rm = TRUE)
  )

# Calculate decadal trends
decadal_trends <- combined_data %>%
  group_by(location, decade) %>%
  summarise(
    avg_temp = mean(mean_temp, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(location, decade)

# Print summaries
cat("\n=== SUMMARY STATISTICS ===\n")
print(summary_stats)

cat("\n=== DECADAL AVERAGE TEMPERATURES ===\n")
print(decadal_trends)

# Save Plots ------------------------------------------------------------------


# Save individual plots
ggsave("plot1_yearly_mean_temp.png", plot1, width = 12, height = 6, dpi = 300)
ggsave("plot2_yearly_min_temp.png", plot2, width = 12, height = 6, dpi = 300)
ggsave("plot3_yearly_max_temp.png", plot3, width = 12, height = 6, dpi = 300)
ggsave("plot4_summer_temps.png", plot4, width = 12, height = 6, dpi = 300)
ggsave("plot5_winter_temps.png", plot5, width = 12, height = 6, dpi = 300)
ggsave("plot6_decade_distribution.png", plot6, width = 12, height = 6, dpi = 300)
ggsave("plot7_recent_trends.png", plot7, width = 12, height = 6, dpi = 300)

# Create comprehensive dashboard
dashboard <- (plot1 | plot7) / (plot4 | plot5) / (plot6)

ggsave("comprehensive_dashboard.png", dashboard, width = 16, height = 14, dpi = 300)

cat("\n✓ All plots saved successfully!\n")
cat("✓ Analysis complete!\n")

# =============================================================================
# End of Script
# =============================================================================
