# =============================================================================
# Tutorial: Accessing Our World in Data - Working Methods (2025)
# Alternative Approaches when owidR or GitHub APIs Fail
# School of Economics, Quaid-i-Azam University
# =============================================================================

# =============================================================================
# PART 1: SETUP AND INSTALLATION
# =============================================================================

# Install once if not already installed
# install.packages(c("tidyverse", "scales", "plotly", "ggrepel", "httr", "jsonlite"))

# Load libraries
library(tidyverse)
library(scales)
library(httr)
library(jsonlite)

options(scipen = 999)
theme_set(theme_minimal())

# =============================================================================
# PART 2: METHOD 1 – Direct CSV Downloads from OWID Grapher
# =============================================================================
# The most stable and recommended way.
# Each OWID chart has a .csv export under https://ourworldindata.org/grapher/[chart-name].csv

get_owid_chart <- function(chart_name) {
  url <- paste0("https://ourworldindata.org/grapher/", chart_name, ".csv")
  message("Trying: ", url)
  tryCatch({
    data <- read_csv(url, show_col_types = FALSE)
    message("✓ Downloaded: ", chart_name)
    return(data)
  }, error = function(e) {
    message("✗ Failed: ", chart_name)
    return(NULL)
  })
}

# Working datasets
life_exp <- get_owid_chart("life-expectancy")
gdp_data <- get_owid_chart("gdp-per-capita-worldbank")
population <- get_owid_chart("population")
# ---- Replace this in your code ----

# Correct CO₂ dataset link (works)
co2_data <- get_owid_chart("annual-co2-emissions")
glimpse(co2_data)
# COVID-19 dataset (new official source)
covid_url <- "https://raw.githubusercontent.com/owid/covid-19-data/master/public/data/owid-covid-data.csv"
covid_data <- read_csv(covid_url, show_col_types = FALSE)

glimpse(life_exp)
glimpse(gdp_data)
glimpse(population)

# =============================================================================
# PART 3: METHOD 2 – COVID-19 Dedicated Dataset (Daily Updated)
# =============================================================================
glimpse(covid_data)

covid_data %>%
  filter(location == "Pakistan") %>%
  arrange(desc(date)) %>%
  select(date, total_cases, total_deaths, total_vaccinations, new_cases) %>%
  head(10)

# =============================================================================
# PART 4: METHOD 3 – Data Cleaning and Harmonization
# =============================================================================

clean_owid_data <- function(data, value_col_name = "value") {
  cols <- names(data)
  entity_col <- cols[str_detect(cols, "Entity|Country|Location")]
  code_col <- cols[str_detect(cols, "Code")]
  year_col <- cols[str_detect(cols, "Year|Date")]
  value_col <- cols[!cols %in% c(entity_col, code_col, year_col)]
  
  if(length(entity_col) > 0 & length(year_col) > 0 & length(value_col) > 0) {
    data <- data %>%
      rename(
        entity = !!entity_col[1],
        year = !!year_col[1]
      )
    if(length(code_col) > 0) {
      data <- data %>% rename(code = !!code_col[1])
    }
    if(length(value_col) == 1) {
      data <- data %>% rename(!!value_col_name := !!value_col[1])
    }
  }
  return(data)
}

life_exp_clean <- clean_owid_data(life_exp, "life_expectancy")
gdp_clean <- clean_owid_data(gdp_data, "gdp_per_capita")
pop_clean <- clean_owid_data(population, "population")
co2_clean <- clean_owid_data(co2_data, "co2_emissions")

glimpse(life_exp_clean)

# =============================================================================
# PART 5: COMBINING KEY INDICATORS INTO ONE DATASET
# =============================================================================
gdp_clean <- gdp_clean %>%
  rename(gdp_per_capita = `GDP per capita, PPP (constant 2021 international $)`)

WorldProgress <- gdp_clean %>%
  left_join(life_exp_clean, by = c("entity", "year")) %>%
  left_join(pop_clean, by = c("entity", "year")) %>%
  left_join(co2_clean, by = c("entity", "year")) %>%
  rename(
    gdpPercap = gdp_per_capita,
    lifeExp = life_expectancy,
    pop = population,
    co2 = co2_emissions
  ) %>%
  mutate(continent = countrycode::countrycode(entity, "country.name", "continent")) %>%
  filter(!is.na(gdpPercap), !is.na(lifeExp))

write_csv(WorldProgress, "WorldProgress.csv")
cat("✅ WorldProgress dataset created with GDP, Life Expectancy, Population, and CO₂\n")

# =============================================================================
# PART 6: EXPLORATORY ANALYSIS
# =============================================================================

WorldProgress %>%
  filter(year == 2020, gdpPercap > 500, gdpPercap < 150000) %>%  # filter outliers
  ggplot(aes(x = gdpPercap, y = lifeExp, color = continent, size = pop)) +
  geom_point(alpha = 0.7) +
  scale_x_log10(
    labels = scales::label_dollar(scale = 1, accuracy = 1),
    breaks = c(1000, 5000, 10000, 25000, 50000, 100000)
  ) +
  scale_y_continuous(limits = c(40, 90)) +
  labs(
    title = "Life Expectancy vs GDP per Capita (2020)",
    subtitle = "PPP-adjusted GDP per capita (constant 2021 international $)",
    x = "GDP per capita (PPP)",
    y = "Life Expectancy (years)",
    caption = "Source: Our World in Data"
  ) +  theme_minimal(base_size = 13) +
  theme(legend.position = "bottom") ->p9


plotly::ggplotly(p9)

## View this data nd sort, then you will find anomaly

# distinct countries in 2020

WorldProgress %>%
  filter(year == 2020) %>%
  distinct(entity) %>%
  arrange(entity) %>%
  print(n = Inf)

## Remove aggregate regions

WorldProgress_clean <- WorldProgress |> 
  filter(
    !entity %in% c(
      "World", "Africa", "Asia", "Europe", "North America", "South America",
      "Oceania", "European Union", "High-income countries",
      "Upper-middle-income countries", "Lower-middle-income countries",
      "Low-income countries", "World Bank income groups", "Small states",
      "Land-locked developing countries (LLDCs)", "Least developed countries (LDCs)",
      "World (excluding China)", "World (excluding high income)",
      "OECD countries"
    )
  ) 

WorldProgress_clean %>%
  filter(year == 2023, gdpPercap > 500, gdpPercap < 150000) %>%
  ggplot(aes(x = gdpPercap, y = lifeExp, color = continent, size = pop)) +
  geom_point(alpha = 0.75, stroke = 0.25) +
  scale_x_log10(
    breaks = c(1000, 3000, 10000, 30000, 100000),
    labels = label_dollar(scale = 1, accuracy = 1)
  ) +
  scale_y_continuous(limits = c(40, 90)) +
  labs(
    title = "Life Expectancy vs GDP per Capita (2020)",
    subtitle = "PPP-adjusted GDP per capita (constant 2021 international $)",
    x = "GDP per capita (PPP, log scale)",
    y = "Life Expectancy (years)",
    caption = "Source: Our World in Data"
  ) +
  theme_minimal(base_size = 14) +
  theme(
    legend.position = "right",                # move to side
    legend.box = "vertical",
    legend.justification = "center",
    legend.key.size = unit(0.35, "cm"),       # compact legend keys
    legend.title = element_text(size = 10),
    legend.text = element_text(size = 9),
    plot.title = element_text(size = 18, face = "bold", hjust = 0.5),
    plot.subtitle = element_text(size = 12, hjust = 0.5, margin = margin(b = 8)),
    plot.caption = element_text(size = 9, hjust = 1, color = "gray40"),
    panel.grid.minor = element_blank(),
    panel.grid.major = element_line(linewidth = 0.25, color = "gray80"),
    plot.margin = margin(20, 15, 20, 15)
  ) +
  guides(
    size = guide_legend(
      title = "Population",
      override.aes = list(alpha = 0.6, size = 4)
    ),
    color = guide_legend(
      title = "Continent",
      override.aes = list(size = 4)
    )
  )
## Visualisation after removing aggregate regions

library(ggplot2)
library(dplyr)
library(scales)

# ---- Select countries ----
focus_countries <- c("China", "India", "Pakistan", "Bangladesh")

gdp_trends <- WorldProgress_clean %>%
  filter(entity %in% focus_countries,
         !is.na(gdpPercap),
         year >= 1960, year <= 2024) %>%
  select(entity, year, gdpPercap)

# ---- Plot ----
ggplot(gdp_trends, aes(x = year, y = gdpPercap, color = entity)) +
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
    title = "GDP per Capita (PPP, constant 2021 $): 1960 – 2020",
    subtitle = "China, India, Pakistan, and Bangladesh — PPP-adjusted (log scale)",
    x = "Year",
    y = "GDP per Capita (PPP, log scale)",
    color = "Country",
    caption = "Source: Our World in Data – World Bank (2023 revision)"
  ) +
  theme_minimal(base_size = 14) +
  theme(
    legend.position = "right",
    legend.title = element_text(size = 10),
    legend.text  = element_text(size = 9),
    plot.title   = element_text(size = 18, face = "bold", hjust = 0.5),
    plot.subtitle= element_text(size = 12, hjust = 0.5, margin = margin(b = 10)),
    plot.caption = element_text(size = 9, hjust = 1, color = "gray40"),
    panel.grid.minor = element_blank(),
    panel.grid.major = element_line(linewidth = 0.25, color = "gray85"),
    plot.margin = margin(15, 20, 15, 15)
  ) 


# ---- Remove OWID aggregate regions ----


# =============================================================================
# PART 7: COVID-19 ANALYSIS EXAMPLES
# =============================================================================

south_asia <- c("Pakistan", "India", "Bangladesh", "Sri Lanka",
                "Nepal", "Afghanistan", "Bhutan", "Maldives")

covid_sa <- covid_data %>%
  filter(location %in% south_asia)

# Latest statistics
covid_latest <- covid_sa %>%
  group_by(location) %>%
  filter(date == max(date)) %>%
  select(location, date, total_cases, total_deaths, total_vaccinations,
         people_fully_vaccinated, population) %>%
  mutate(
    cases_per_million = (total_cases / population) * 1e6,
    deaths_per_million = (total_deaths / population) * 1e6,
    vax_per_100 = (total_vaccinations / population) * 100,
    fully_vax_pct = (people_fully_vaccinated / population) * 100
  ) %>%
  arrange(desc(cases_per_million))

print(covid_latest)

# Visualization
covid_sa %>%
  ggplot(aes(date, total_cases, color = location)) +
  geom_line(size = 1) +
  scale_y_log10(labels = comma) +
  labs(
    title = "COVID-19 Total Cases in South Asia",
    x = "Date", y = "Total Cases (log scale)",
    caption = "Source: Our World in Data"
  )

# =============================================================================
# PART 8: SAVING WORK
# =============================================================================

write_csv(covid_data, "owid_covid_data.csv")
write_csv(covid_sa, "covid_south_asia.csv")
write_csv(WorldProgress, "WorldProgress.csv")

ggsave("covid_cases_south_asia.png", width = 10, height = 6, dpi = 300)

# =============================================================================
# PART 9: TROUBLESHOOTING NOTES
# =============================================================================
cat("
=== OWID Access Troubleshooting ===
✅ If owidR fails, use grapher CSVs like: https://ourworldindata.org/grapher/life-expectancy.csv
✅ COVID dataset always works: https://covid.ourworldindata.org/data/owid-covid-data.csv
✅ Check connection or use VPN if blocked
✅ Always save data locally for reproducibility
")

# =============================================================================
# END OF TUTORIAL
# =============================================================================

cat('
✓ Tutorial Complete — Our World in Data Practical Access Guide (2025)
Includes:
1. Stable OWID Grapher CSV downloads
2. COVID-19 analysis examples
3. Data harmonization workflow
4. Visualizations and saving outputs
5. Troubleshooting and alternatives
')

