# =============================================================================
# Tutorial: Accessing Our World in Data (OWID) — Beginner-Friendly Version
# School of Economics, Quaid-i-Azam University
# =============================================================================
# This version is written for a FIRST-TIME R learner.
# Rules followed throughout:
#   - No custom functions — every step is a plain, sequential command
#   - Each block can be run on its own, top to bottom
#   - Every dataset is downloaded, cleaned, and checked the SAME simple way
# =============================================================================


# =============================================================================
# STEP 0: Install packages (only once — run this line by itself if needed)
# =============================================================================
# install.packages(c("tidyverse", "janitor", "scales", "plotly", "countrycode"))


# =============================================================================
# STEP 1: Load the libraries we need
# =============================================================================
library(tidyverse)   # read_csv(), dplyr, ggplot2, etc.
library(janitor)     # clean_names() — turns messy column names into tidy ones
library(scales)      # label_dollar(), comma() for nicer axis labels
library(countrycode) # look up continent for each country
library(plotly)      # ggplotly() for interactive charts

options(scipen = 999)
theme_set(theme_minimal())


# =============================================================================
# STEP 2: Download Life Expectancy data
# =============================================================================
# Every OWID chart has a stable CSV export at:
#   https://ourworldindata.org/grapher/<chart-name>.csv

life_exp <- read_csv("https://ourworldindata.org/grapher/life-expectancy.csv",
                     show_col_types = FALSE)




glimpse(life_exp)   # look at column names before cleaning


# =============================================================================
# STEP 3: Clean up the Life Expectancy column names
# =============================================================================
# clean_names() lowercases everything and replaces spaces/symbols with "_"
# Then we rename the last column (the actual value column) to something clear
life_exp_clean <- life_exp |>
  clean_names() |>
  select(entity, year, life_expectancy = life_expectancy)   # replace with the real name you saw

glimpse(life_exp_clean)


# =============================================================================
# STEP 4: Download and clean GDP per capita data (same two-step pattern)
# =============================================================================
gdp_data <- read_csv("https://ourworldindata.org/grapher/gdp-per-capita-worldbank.csv",
                     show_col_types = FALSE)

gdp_clean <- gdp_data |>
  clean_names()

 glimpse(gdp_clean)


# =============================================================================
# STEP 5: Download and clean Population data
# =============================================================================
population <- read_csv("https://ourworldindata.org/grapher/population.csv",
                       show_col_types = FALSE)

pop_clean <- population |>
  clean_names()

glimpse(pop_clean)


# =============================================================================
# STEP 6: Download and clean CO2 emissions data
# =============================================================================
co2_data <- read_csv("https://ourworldindata.org/grapher/annual-co2-emissions.csv",
                     show_col_types = FALSE)

co2_clean <- co2_data |>
  clean_names() |>
  rename(co2_emissions = last_col())

glimpse(co2_clean)


# =============================================================================
# STEP 7: Download the COVID-19 dataset
# =============================================================================
# NOTE (important): OWID archived the "covid-19-data" GitHub repository on
# 24 March 2026. The repo is now READ-ONLY, so the file below still
# downloads, but it is FROZEN at its last update — it is no longer
# refreshed daily. Treat this as a historical snapshot, not live data.

covid_url <- "https://raw.githubusercontent.com/owid/covid-19-data/master/public/data/owid-covid-data.csv"
covid_data <- read_csv(covid_url, show_col_types = FALSE)

glimpse(covid_data)

covid_data |>
  filter(location == "Pakistan") |>
  arrange(desc(date)) |>
  select(date, total_cases, total_deaths, total_vaccinations, new_cases) |>
  head(10)


# =============================================================================
# STEP 8: Join the four indicators into one dataset
# =============================================================================
# All four cleaned datasets share "entity" and "year" columns, so we can
# join them together using join_by().

world_progress <- gdp_clean |>
  left_join(life_exp_clean, by = join_by(entity, year)) |>
  left_join(pop_clean,      by = join_by(entity, year)) |>
  left_join(co2_clean,      by = join_by(entity, year))

glimpse(world_progress)


# =============================================================================
# STEP 9: Add continent, drop rows missing key values, and save
# =============================================================================
world_progress <- world_progress |>
  mutate(continent = countrycode(entity, "country.name", "continent")) |>
  filter(!is.na(gdp_per_capita), !is.na(life_expectancy))

write_csv(world_progress, "WorldProgress.csv")

cat("Dataset created with GDP, Life Expectancy, Population, and CO2\n")


# =============================================================================
# STEP 10: Look at the data — spot the aggregate "countries"
# =============================================================================
# OWID includes regions like "World", "Asia", "High-income countries" as if
# they were countries. We need to look at the list and remove them.

world_progress |>
  filter(year == 2020) |>
  distinct(entity) |>
  arrange(entity) |>
  print(n = Inf)


# =============================================================================
# STEP 11: Remove aggregate regions (keep only actual countries)
# =============================================================================
aggregate_regions <- c(
  "World", "Africa", "Asia", "Europe", "North America", "South America",
  "Oceania", "European Union", "High-income countries",
  "Upper-middle-income countries", "Lower-middle-income countries",
  "Low-income countries", "World Bank income groups", "Small states",
  "Land-locked developing countries (LLDCs)", "Least developed countries (LDCs)",
  "World (excluding China)", "World (excluding high income)",
  "OECD countries"
)

world_progress_clean <- world_progress |>
  filter(!entity %in% aggregate_regions)


# =============================================================================
# STEP 12: Plot 1 — Life Expectancy vs GDP per capita (bubble chart)
# =============================================================================
p9 <- world_progress_clean |>
  filter(year == 2023, gdp_per_capita > 500, gdp_per_capita < 150000) |>
  ggplot(aes(x = gdp_per_capita, y = life_expectancy,
             color = continent, size = population)) +
  geom_point(alpha = 0.75, stroke = 0.25) +
  scale_x_log10(
    breaks = c(1000, 3000, 10000, 30000, 100000),
    labels = label_dollar(scale = 1, accuracy = 1)
  ) +
  scale_y_continuous(limits = c(40, 90)) +
  labs(
    title = "Life Expectancy vs GDP per Capita (2023)",
    subtitle = "PPP-adjusted GDP per capita (constant 2021 international $)",
    x = "GDP per capita (PPP, log scale)",
    y = "Life Expectancy (years)",
    caption = "Source: Our World in Data"
  ) +
  theme_minimal(base_size = 13) +
  theme(legend.position = "bottom")

p9                    # static version
ggplotly(p9)          # interactive version


# =============================================================================
# STEP 13: Plot 2 — GDP trends for selected South Asian countries + China
# =============================================================================
focus_countries <- c("China", "India", "Pakistan", "Bangladesh")

gdp_trends <- world_progress_clean |>
  filter(entity %in% focus_countries,
         !is.na(gdp_per_capita),
         year >= 1960, year <= 2024) |>
  select(entity, year, gdp_per_capita)

ggplot(gdp_trends, aes(x = year, y = gdp_per_capita, color = entity)) +
  geom_line(linewidth = 1.1) +
  scale_y_log10(
    labels = label_dollar(scale = 1, accuracy = 1),
    breaks = c(500, 1000, 3000, 10000, 30000, 100000)
  ) +
  scale_color_manual(
    values = c(
      "China" = "#E41A1C",
      "India" = "#377EB8",
      "Pakistan" = "#4DAF4A",
      "Bangladesh" = "#984EA3"
    )
  ) +
  labs(
    title = "GDP per Capita (PPP, constant 2021 $): 1960 - 2024",
    subtitle = "China, India, Pakistan, and Bangladesh (log scale)",
    x = "Year",
    y = "GDP per Capita (PPP, log scale)",
    color = "Country",
    caption = "Source: Our World in Data - World Bank"
  ) +
  theme_minimal(base_size = 14) +
  theme(legend.position = "right")


# =============================================================================
# STEP 14: COVID-19 — South Asia summary table
# =============================================================================
south_asia <- c("Pakistan", "India", "Bangladesh", "Sri Lanka",
                "Nepal", "Afghanistan", "Bhutan", "Maldives")

covid_sa <- covid_data |>
  filter(location %in% south_asia)

covid_latest <- covid_sa |>
  filter(date == max(date), .by = location) |>
  select(location, date, total_cases, total_deaths, total_vaccinations,
         people_fully_vaccinated, population) |>
  mutate(
    cases_per_million  = (total_cases / population) * 1e6,
    deaths_per_million = (total_deaths / population) * 1e6,
    vax_per_100        = (total_vaccinations / population) * 100,
    fully_vax_pct      = (people_fully_vaccinated / population) * 100
  ) |>
  arrange(desc(cases_per_million))

print(covid_latest)


# =============================================================================
# STEP 15: COVID-19 — South Asia chart
# =============================================================================
covid_sa |>
  ggplot(aes(date, total_cases, color = location)) +
  geom_line(linewidth = 1) +
  scale_y_log10(labels = comma) +
  labs(
    title = "COVID-19 Total Cases in South Asia",
    subtitle = "Data frozen as of the OWID repository archive date (March 2026)",
    x = "Date", y = "Total Cases (log scale)",
    caption = "Source: Our World in Data"
  )

ggsave("covid_cases_south_asia.png", width = 10, height = 6, dpi = 300)


# =============================================================================
# STEP 16: Save all outputs
# =============================================================================
write_csv(covid_data, "owid_covid_data.csv")
write_csv(covid_sa, "covid_south_asia.csv")
write_csv(world_progress_clean, "WorldProgress_clean.csv")


# =============================================================================
# STEP 17: Troubleshooting notes
# =============================================================================
cat("
=== OWID Access Troubleshooting ===
- Every OWID chart has a stable CSV at:
    https://ourworldindata.org/grapher/<chart-name>.csv
- The COVID-19 repo (owid/covid-19-data) was archived on 24 March 2026.
  The file still downloads, but it is a FROZEN snapshot, not live data.
- If a download fails, check your internet connection or try again later.
- Always save data locally (write_csv) so your analysis is reproducible.
")

cat("
Tutorial complete - OWID practical access guide
Steps covered:
1. Downloading four OWID indicators (no custom functions)
2. Cleaning column names the same simple way each time (janitor::clean_names)
3. Joining datasets with join_by()
4. Removing OWID aggregate regions before plotting
5. Two ggplot visualisations (bubble chart + line chart)
6. COVID-19 South Asia table and chart
7. Saving all outputs to disk
")

# =============================================================================
# END OF TUTORIAL
# =============================================================================
