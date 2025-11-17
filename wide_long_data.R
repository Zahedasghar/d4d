library(tidyverse)
library(readxl)
library(lubridate)

# Load data
wide_data <- read_excel("data/wide_data.xlsx")

# Ensure numeric columns
wide_data <- wide_data |> mutate(Dec = as.numeric(Dec))

# Wide → long
cpi_long <- wide_data %>%
  pivot_longer(Jan:Dec, names_to = "Month", values_to = "CPI")

# Month order + date
cpi_long <- cpi_long %>%
  mutate(
    Month = factor(Month, levels = month.abb),
    Date = ym(paste(year, Month))
  )

# Avg CPI by month
avg_by_month <- cpi_long %>%
  group_by(Month) %>%
  summarise(Average_CPI = mean(CPI, na.rm = TRUE))

# Avg CPI by year
avg_by_year <- cpi_long %>%
  group_by(year) %>%
  summarise(Annual_Avg = mean(CPI, na.rm = TRUE))

# Plot 1: Time series
ggplot(cpi_long, aes(Date, CPI)) +
  geom_line(color = "steelblue") +
  labs(title = "Monthly CPI Over Time", x = "Year", y = "CPI")

# Plot 2: Yearly small multiples
ggplot(cpi_long, aes(Month, CPI, group = year, color = factor(year))) +
  geom_line() +
  facet_wrap(~year) +
  theme(legend.position = "none") +
  labs(title = "CPI Pattern Across Years")

# Plot 3: Seasonality
ggplot(cpi_long, aes(Month, CPI)) +
  geom_boxplot(fill = "lightblue") +
  labs(title = "Seasonality in CPI (Month-wise)")
wide_df |>
  pivot_longer(cols =!year, names_to = "month",values_to = "index_number")  |>
  mutate(date=ym(paste(year, month, sep = "-"))) -> df_long


df_long |> ggplot(aes(x=date,y=index_number))+
  geom_line(linewidth=1)+ labs(x="", y="index number", title = "Month time seires plot of an index",
                               caption = "source: dummy, @zahedasghar")+theme_minimal()

read_excel("wide_data.xlsx") |> mutate(Dec=as.numeric(Dec)) |> na.omit() |>
  pivot_longer(cols =!year, names_to = "month",values_to = "index_number") |>
  mutate(date=ym(paste(year, month, sep = "-"))) |> ggplot(aes(x=date,y=index_number))+
  geom_line(linewidth=1)+ labs(x="", y="index number", title = "Month time seires plot of an index",
                               caption = "source: dummy, @zahedasghar")+
  theme(plot.title = element_text(size = 15)) |> theme_minimal()





camcorder::gg_record(
  dir = 'images',
  width = 12,
  height = 12 * 9 / 16,
  dpi = 300,
  bg = 'white'
)
