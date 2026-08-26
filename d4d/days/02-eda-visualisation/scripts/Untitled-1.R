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
# 1. DATA COLLECTION - Extended Demographic & Health Indicators
# ============================================================================

# Define South Asian countries
south_asia_countries <- c(
  "PK",  # Pakistan
  "IN",  # India
  "BD",  # Bangladesh
  "LK",  # Sri Lanka
  "NP",  # Nepal
  "BT",  # Bhutan
  "MV",  # Maldives
  "AF"   # Afghanistan
)

# Fetch EXTENDED demographic data for South Asian countries
extended_demographic_data <- WDI(
  country = south_asia_countries,
  indicator = c(
    # Education Indicators
    "SE.PRM.ENRR",           # Primary school enrollment rate (% gross)
    "SE.SEC.ENRR",           # Secondary school enrollment rate (% gross)
    "SE.TER.ENRR",           # Tertiary school enrollment rate (% gross)
    "SE.ADT.LITR.ZS",        # Adult literacy rate (% of people ages 15+)
    "SE.PRM.CMPT.ZS",        # Primary completion rate (% of relevant age group)
    
    # Health Indicators
    "SH.STA.MMRT",           # Maternal mortality ratio (per 100,000 live births)
    "SH.MED.PHYS.ZS",        # Physicians (per 1,000 people)
    "SH.MED.BEDS.ZS",        # Hospital beds (per 1,000 people)
    "SH.H2O.SMDW.ZS",        # Access to clean drinking water (% of population)
    "SH.STA.BASS.ZS",        # Access to basic sanitation (% of population)
    "SH.XPD.CHEX.PC.CD",     # Current health expenditure per capita (USD)
    
    # Gender & Employment
    "SL.TLF.CACT.FE.ZS",     # Female labor force participation rate (%)
    "SL.UEM.TOTL.ZS",        # Unemployment rate (% of total labor force)
    "SP.DYN.SMAM.FE",        # Mean age at first marriage, female
    "SG.GEN.PARL.ZS",        # Women in parliament (% of total seats)
    
    # Economic Indicators
    "NY.GDP.PCAP.CD",        # GDP per capita (current USD)
    "SI.POV.DDAY",           # Poverty headcount ratio at $2.15/day (% of pop)
    "SI.DST.10TH.10",        # Income share held by highest 10%
    
    # Technology & Infrastructure
    "IT.NET.USER.ZS",        # Internet users (% of population)
    "IT.CEL.SETS.P2",        # Mobile cellular subscriptions (per 100 people)
    "EG.ELC.ACCS.ZS",        # Access to electricity (% of population)
    
    # Environmental
    "EN.ATM.CO2E.PC",        # CO2 emissions (metric tons per capita)
    "AG.LND.FRST.ZS"         # Forest area (% of land area)
  ),
  start = 1990,
  end = 2024
) %>%
  as_tibble()

# # Rename variables for easier handling
# extended_demographic_data <- extended_demographic_data %>%
#   rename(
#     primary_enrollment = SE.PRM.ENRR,
#     secondary_enrollment = SE.SEC.ENRR,
#     tertiary_enrollment = SE.TER.ENRR,
#     adult_literacy = SE.ADT.LITR.ZS,
#     primary_completion = SE.PRM.CMPT.ZS,
#     maternal_mortality = SH.STA.MMRT,
#     physicians_per_1000 = SH.MED.PHYS.ZS,
#     hospital_beds_per_1000 = SH.MED.BEDS.ZS,
#     clean_water_access = SH.H2O.SMDW.ZS,
#     sanitation_access = SH.STA.BASS.ZS,
#     health_expenditure_pc = SH.XPD.CHEX.PC.CD,
#     female_labor_force = SL.TLF.CACT.FE.ZS,
#     unemployment_rate = SL.UEM.TOTL.ZS,
#     mean_marriage_age_female = SP.DYN.SMAM.FE,
#     women_in_parliament = SG.GEN.PARL.ZS,
#     gdp_per_capita = NY.GDP.PCAP.CD,
#     poverty_rate = SI.POV.DDAY,
#     income_top10_pct = SI.DST.10TH.10,
#     internet_users = IT.NET.USER.ZS,
#     mobile_subscriptions = IT.CEL.SETS.P2,
#     electricity_access = EG.ELC.ACCS.ZS,
#     co2_per_capita = EN.ATM.CO2E.PC,
#     forest_area_pct = AG.LND.FRST.ZS
#   )

## Save raw data for reference
 write_csv(extended_demographic_data, "south_asia_extended_demographic_data.csv")

# Load the data
extended_data <- read_csv("south_asia_extended_demographic_data.csv")

# ============================================================================
# 2. DATA EXPLORATION
# ============================================================================

# Structure of the data
extended_data %>% glimpse()

# Summary statistics by country
summary_by_country <- extended_data %>%
  group_by(country) %>%
  summarise(
    years_of_data = n(),
    latest_literacy = last(na.omit(adult_literacy)),
    latest_maternal_mortality = last(na.omit(maternal_mortality)),
    latest_internet_users = last(na.omit(internet_users)),
    .groups = 'drop'
  )

print(summary_by_country)

# ============================================================================
# 3. ANIMATED VISUALIZATION 1: MATERNAL MORTALITY RATE
# ============================================================================

anim_maternal <- extended_data %>%
  filter(!is.na(maternal_mortality), year >= 1990) %>%
  ggplot(aes(x = year, y = maternal_mortality, group = country)) +
  
  # Other countries' lines
  geom_line(
    data = . %>% filter(country != "Pakistan"),
    aes(color = country),
    linewidth = 1.2, 
    alpha = 0.7
  ) +
  
  # Pakistan line (thicker, dark green)
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
  
  # Pakistan points
  geom_point(
    data = . %>% filter(country == "Pakistan"),
    color = "darkgreen",
    size = 3.5, 
    alpha = 1
  ) +
  
  # Country labels at the end
  geom_text(
    data = . %>% filter(year == max(year), country != "Pakistan"),
    aes(label = country, color = country),
    hjust = -0.1, 
    size = 3.5,
    fontface = "bold",
    show.legend = FALSE
  ) +
  
  geom_text(
    data = . %>% filter(year == max(year), country == "Pakistan"),
    aes(label = country),
    color = "darkgreen",
    hjust = -0.1, 
    size = 4.5,
    fontface = "bold",
    show.legend = FALSE
  ) +
  
  theme_minimal(base_size = 14) +
  theme(
    plot.title = element_text(size = 18, face = "bold", margin = margin(b = 10)),
    plot.subtitle = element_text(size = 14, margin = margin(b = 15), color = "gray30"),
    plot.caption = element_text(size = 10, color = "gray50", hjust = 0),
    legend.position = "bottom",
    legend.direction = "horizontal",
    legend.title = element_text(size = 12, face = "bold"),
    legend.text = element_text(size = 11),
    panel.grid.minor = element_blank(),
    panel.grid.major = element_line(color = "gray90", linewidth = 0.3),
    axis.text = element_text(size = 12),
    axis.title = element_text(size = 13, face = "bold"),
    plot.margin = margin(15, 25, 15, 15),
    panel.background = element_rect(fill = "white", color = NA),
    plot.background = element_rect(fill = "white", color = NA)
  ) +
  
  scale_color_brewer(palette = "Set2") +
  scale_x_continuous(breaks = seq(1990, 2024, by = 5), 
                     expand = expansion(mult = c(0.02, 0.15))) +
  scale_y_continuous(expand = expansion(mult = c(0.02, 0.05))) +
  
  labs(
    x = "Year",
    y = "Deaths per 100,000 Live Births",
    color = "Country",
    title = "Maternal Mortality Rate in South Asia (Pakistan in Dark Green)",
    subtitle = "Progress in maternal health across the region (1990-2024)",
    caption = "Data: World Bank via {WDI}"
  ) +
  
  transition_reveal(year)

animate(
  anim_maternal, 
  nframes = 130,
  fps = 10,
  width = 900,
  height = 700,
  dpi = 150,
  renderer = gifski_renderer("maternal_mortality_animation.gif")
)

# ============================================================================
# 4. ANIMATED VISUALIZATION 2: ADULT LITERACY RATE
# ============================================================================

anim_literacy <- extended_data %>%
  filter(!is.na(adult_literacy), year >= 1990) %>%
  ggplot(aes(x = year, y = adult_literacy, group = country)) +
  
  # Other countries' lines
  geom_line(
    data = . %>% filter(country != "Pakistan"),
    aes(color = country),
    linewidth = 1.2, 
    alpha = 0.7
  ) +
  
  # Pakistan line
  geom_line(
    data = . %>% filter(country == "Pakistan"),
    color = "darkgreen",
    linewidth = 2.2, 
    alpha = 1
  ) +
  
  # Points
  geom_point(
    data = . %>% filter(country != "Pakistan"),
    aes(color = country),
    size = 2.5, 
    alpha = 0.8
  ) +
  
  geom_point(
    data = . %>% filter(country == "Pakistan"),
    color = "darkgreen",
    size = 3.5, 
    alpha = 1
  ) +
  
  # Labels
  geom_text(
    data = . %>% filter(year == max(year), country != "Pakistan"),
    aes(label = country, color = country),
    hjust = -0.1, 
    size = 3.5,
    fontface = "bold",
    show.legend = FALSE
  ) +
  
  geom_text(
    data = . %>% filter(year == max(year), country == "Pakistan"),
    aes(label = country),
    color = "darkgreen",
    hjust = -0.1, 
    size = 4.5,
    fontface = "bold",
    show.legend = FALSE
  ) +
  
  theme_minimal(base_size = 14) +
  theme(
    plot.title = element_text(size = 18, face = "bold", margin = margin(b = 10)),
    plot.subtitle = element_text(size = 14, margin = margin(b = 15), color = "gray30"),
    plot.caption = element_text(size = 10, color = "gray50", hjust = 0),
    legend.position = "bottom",
    legend.direction = "horizontal",
    panel.grid.minor = element_blank(),
    panel.grid.major = element_line(color = "gray90", linewidth = 0.3),
    plot.margin = margin(15, 25, 15, 15)
  ) +
  
  scale_color_brewer(palette = "Set2") +
  scale_x_continuous(breaks = seq(1990, 2024, by = 5), 
                     expand = expansion(mult = c(0.02, 0.15))) +
  scale_y_continuous(expand = expansion(mult = c(0.02, 0.05))) +
  
  labs(
    x = "Year",
    y = "Adult Literacy Rate (%)",
    color = "Country",
    title = "Adult Literacy Rate in South Asia (Pakistan in Dark Green)",
    subtitle = "Educational progress across the region (1990-2024)",
    caption = "Data: World Bank via {WDI}"
  ) +
  
  transition_reveal(year)

animate(
  anim_literacy, 
  nframes = 130,
  fps = 10,
  width = 900,
  height = 700,
  dpi = 150,
  renderer = gifski_renderer("adult_literacy_animation.gif")
)

# ============================================================================
# 5. ANIMATED VISUALIZATION 3: INTERNET USERS (% OF POPULATION)
# ============================================================================

anim_internet <- extended_data %>%
  filter(!is.na(internet_users), year >= 1990) %>%
  ggplot(aes(x = year, y = internet_users, group = country)) +
  
  geom_line(
    data = . %>% filter(country != "Pakistan"),
    aes(color = country),
    linewidth = 1.2, 
    alpha = 0.7
  ) +
  
  geom_line(
    data = . %>% filter(country == "Pakistan"),
    color = "darkgreen",
    linewidth = 2.2, 
    alpha = 1
  ) +
  
  geom_point(
    data = . %>% filter(country != "Pakistan"),
    aes(color = country),
    size = 2.5, 
    alpha = 0.8
  ) +
  
  geom_point(
    data = . %>% filter(country == "Pakistan"),
    color = "darkgreen",
    size = 3.5, 
    alpha = 1
  ) +
  
  geom_text(
    data = . %>% filter(year == max(year), country != "Pakistan"),
    aes(label = country, color = country),
    hjust = -0.1, 
    size = 3.5,
    fontface = "bold",
    show.legend = FALSE
  ) +
  
  geom_text(
    data = . %>% filter(year == max(year), country == "Pakistan"),
    aes(label = country),
    color = "darkgreen",
    hjust = -0.1, 
    size = 4.5,
    fontface = "bold",
    show.legend = FALSE
  ) +
  
  theme_minimal(base_size = 14) +
  theme(
    plot.title = element_text(size = 18, face = "bold", margin = margin(b = 10)),
    plot.subtitle = element_text(size = 14, margin = margin(b = 15), color = "gray30"),
    plot.caption = element_text(size = 10, color = "gray50", hjust = 0),
    legend.position = "bottom",
    legend.direction = "horizontal",
    panel.grid.minor = element_blank(),
    panel.grid.major = element_line(color = "gray90", linewidth = 0.3),
    plot.margin = margin(15, 25, 15, 15)
  ) +
  
  scale_color_brewer(palette = "Set2") +
  scale_x_continuous(breaks = seq(1990, 2024, by = 5), 
                     expand = expansion(mult = c(0.02, 0.15))) +
  scale_y_continuous(expand = expansion(mult = c(0.02, 0.05))) +
  
  labs(
    x = "Year",
    y = "Internet Users (% of Population)",
    color = "Country",
    title = "Internet Penetration in South Asia (Pakistan in Dark Green)",
    subtitle = "Digital connectivity growth (1990-2024)",
    caption = "Data: World Bank via {WDI}"
  ) +
  
  transition_reveal(year)

animate(
  anim_internet, 
  nframes = 130,
  fps = 10,
  width = 900,
  height = 700,
  dpi = 150,
  renderer = gifski_renderer("internet_users_animation.gif")
)

# ============================================================================
# 6. ANIMATED BAR CHART: ACCESS TO CLEAN DRINKING WATER
# ============================================================================

anim_water_bars <- extended_data %>%
  filter(!is.na(clean_water_access), year >= 1990) %>%
  group_by(year) %>%
  arrange(year, desc(clean_water_access)) %>%
  mutate(rank = row_number()) %>%
  ungroup() %>%
  
  ggplot(aes(x = rank, y = clean_water_access, fill = country)) +
  geom_col(width = 0.8, alpha = 0.9) +
  
  geom_text(
    aes(label = country, y = 0),
    hjust = 0,
    nudge_y = 2,
    size = 5,
    fontface = "bold",
    color = "white"
  ) +
  
  geom_text(
    aes(label = round(clean_water_access, 1)),
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
    legend.position = "none",
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
  scale_x_reverse() +
  scale_y_continuous(expand = expansion(mult = c(0.02, 0.15))) +
  
  labs(
    x = NULL,
    y = "Access to Clean Drinking Water (% of Population)",
    title = "Access to Clean Drinking Water in South Asia",
    subtitle = "Year: {as.integer(frame_time)}",
    caption = "Data: World Bank via {WDI}"
  ) +
  
  transition_time(year) +
  ease_aes('linear')

animate(
  anim_water_bars, 
  nframes = 130,
  fps = 10,
  width = 900,
  height = 700,
  dpi = 150,
  renderer = gifski_renderer("clean_water_access_bars.gif")
)

# ============================================================================
# 7. ANIMATED BAR CHART: FEMALE LABOR FORCE PARTICIPATION
# ============================================================================

anim_female_labor_bars <- extended_data %>%
  filter(!is.na(female_labor_force), year >= 1990) %>%
  group_by(year) %>%
  arrange(year, desc(female_labor_force)) %>%
  mutate(rank = row_number()) %>%
  ungroup() %>%
  
  ggplot(aes(x = rank, y = female_labor_force, fill = country)) +
  geom_col(width = 0.8, alpha = 0.9) +
  
  geom_text(
    aes(label = country, y = 0),
    hjust = 0,
    nudge_y = 1.5,
    size = 5,
    fontface = "bold",
    color = "white"
  ) +
  
  geom_text(
    aes(label = round(female_labor_force, 1)),
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
    legend.position = "none",
    axis.text.y = element_blank(),
    axis.ticks.y = element_blank(),
    panel.grid.major.y = element_blank(),
    panel.grid.minor = element_blank(),
    plot.margin = margin(20, 60, 20, 20)
  ) +
  
  scale_fill_brewer(palette = "Set2") +
  scale_x_reverse() +
  scale_y_continuous(expand = expansion(mult = c(0.02, 0.15))) +
  
  labs(
    x = NULL,
    y = "Female Labor Force Participation Rate (%)",
    title = "Female Labor Force Participation in South Asia",
    subtitle = "Year: {as.integer(frame_time)}",
    caption = "Data: World Bank via {WDI}"
  ) +
  
  transition_time(year) +
  ease_aes('linear')

animate(
  anim_female_labor_bars, 
  nframes = 130,
  fps = 10,
  width = 900,
  height = 700,
  dpi = 150,
  renderer = gifski_renderer("female_labor_participation_bars.gif")
)

# ============================================================================
# 8. ANIMATED VISUALIZATION: GDP PER CAPITA
# ============================================================================

anim_gdp <- extended_data %>%
  filter(!is.na(gdp_per_capita), year >= 1990) %>%
  ggplot(aes(x = year, y = gdp_per_capita, group = country)) +
  
  geom_line(
    data = . %>% filter(country != "Pakistan"),
    aes(color = country),
    linewidth = 1.2, 
    alpha = 0.7
  ) +
  
  geom_line(
    data = . %>% filter(country == "Pakistan"),
    color = "darkgreen",
    linewidth = 2.2, 
    alpha = 1
  ) +
  
  geom_point(
    data = . %>% filter(country != "Pakistan"),
    aes(color = country),
    size = 2.5, 
    alpha = 0.8
  ) +
  
  geom_point(
    data = . %>% filter(country == "Pakistan"),
    color = "darkgreen",
    size = 3.5, 
    alpha = 1
  ) +
  
  geom_text(
    data = . %>% filter(year == max(year), country != "Pakistan"),
    aes(label = country, color = country),
    hjust = -0.1, 
    size = 3.5,
    fontface = "bold",
    show.legend = FALSE
  ) +
  
  geom_text(
    data = . %>% filter(year == max(year), country == "Pakistan"),
    aes(label = country),
    color = "darkgreen",
    hjust = -0.1, 
    size = 4.5,
    fontface = "bold",
    show.legend = FALSE
  ) +
  
  theme_minimal(base_size = 14) +
  theme(
    plot.title = element_text(size = 18, face = "bold", margin = margin(b = 10)),
    plot.subtitle = element_text(size = 14, margin = margin(b = 15), color = "gray30"),
    plot.caption = element_text(size = 10, color = "gray50", hjust = 0),
    legend.position = "bottom",
    legend.direction = "horizontal",
    panel.grid.minor = element_blank(),
    panel.grid.major = element_line(color = "gray90", linewidth = 0.3),
    plot.margin = margin(15, 25, 15, 15)
  ) +
  
  scale_color_brewer(palette = "Set2") +
  scale_x_continuous(breaks = seq(1990, 2024, by = 5), 
                     expand = expansion(mult = c(0.02, 0.15))) +
  scale_y_continuous(labels = dollar_format(), 
                     expand = expansion(mult = c(0.02, 0.05))) +
  
  labs(
    x = "Year",
    y = "GDP per Capita (Current USD)",
    color = "Country",
    title = "GDP per Capita in South Asia (Pakistan in Dark Green)",
    subtitle = "Economic development trends (1990-2024)",
    caption = "Data: World Bank via {WDI}"
  ) +
  
  transition_reveal(year)

animate(
  anim_gdp, 
  nframes = 130,
  fps = 10,
  width = 900,
  height = 700,
  dpi = 150,
  renderer = gifski_renderer("gdp_per_capita_animation.gif")
)

# ============================================================================
# 9. ANIMATED VISUALIZATION: ELECTRICITY ACCESS
# ============================================================================

anim_electricity <- extended_data %>%
  filter(!is.na(electricity_access), year >= 1990) %>%
  ggplot(aes(x = year, y = electricity_access, group = country)) +
  
  geom_line(
    data = . %>% filter(country != "Pakistan"),
    aes(color = country),
    linewidth = 1.2, 
    alpha = 0.7
  ) +
  
  geom_line(
    data = . %>% filter(country == "Pakistan"),
    color = "darkgreen",
    linewidth = 2.2, 
    alpha = 1
  ) +
  
  geom_point(
    data = . %>% filter(country != "Pakistan"),
    aes(color = country),
    size = 2.5, 
    alpha = 0.8
  ) +
  
  geom_point(
    data = . %>% filter(country == "Pakistan"),
    color = "darkgreen",
    size = 3.5, 
    alpha = 1
  ) +
  
  geom_text(
    data = . %>% filter(year == max(year), country != "Pakistan"),
    aes(label = country, color = country),
    hjust = -0.1, 
    size = 3.5,
    fontface = "bold",
    show.legend = FALSE
  ) +
  
  geom_text(
    data = . %>% filter(year == max(year), country == "Pakistan"),
    aes(label = country),
    color = "darkgreen",
    hjust = -0.1, 
    size = 4.5,
    fontface = "bold",
    show.legend = FALSE
  ) +
  
  theme_minimal(base_size = 14) +
  theme(
    plot.title = element_text(size = 18, face = "bold", margin = margin(b = 10)),
    plot.subtitle = element_text(size = 14, margin = margin(b = 15), color = "gray30"),
    plot.caption = element_text(size = 10, color = "gray50", hjust = 0),
    legend.position = "bottom",
    legend.direction = "horizontal",
    panel.grid.minor = element_blank(),
    panel.grid.major = element_line(color = "gray90", linewidth = 0.3),
    plot.margin = margin(15, 25, 15, 15)
  ) +
  
  scale_color_brewer(palette = "Set2") +
  scale_x_continuous(breaks = seq(1990, 2024, by = 5), 
                     expand = expansion(mult = c(0.02, 0.15))) +
  scale_y_continuous(expand = expansion(mult = c(0.02, 0.05))) +
  
  labs(
    x = "Year",
    y = "Access to Electricity (% of Population)",
    color = "Country",
    title = "Electricity Access in South Asia (Pakistan in Dark Green)",
    subtitle = "Infrastructure development progress (1990-2024)",
    caption = "Data: World Bank via {WDI}"
  ) +
  
  transition_reveal(year)

animate(
  anim_electricity, 
  nframes = 130,
  fps = 10,
  width = 900,
  height = 700,
  dpi = 150,
  renderer = gifski_renderer("electricity_access_animation.gif")
)

# ============================================================================
# 10. FACETED MULTI-INDICATOR ANIMATION
# ============================================================================

anim_multi_indicator <- extended_data %>%
  filter(year >= 1990) %>%
  select(country, year, adult_literacy, maternal_mortality, 
         internet_users, electricity_access, gdp_per_capita) %>%
  pivot_longer(
    cols = c(adult_literacy, maternal_mortality, internet_users, 
             electricity_access, gdp_per_capita),
    names_to = "indicator",
    values_to = "value"
  ) %>%
  filter(!is.na(value)) %>%
  mutate(
    indicator = case_when(
      indicator == "adult_literacy" ~ "Adult Literacy Rate (%)",
      indicator == "maternal_mortality" ~ "Maternal Mortality (per 100K)",
      indicator == "internet_users" ~ "Internet Users (%)",
      indicator == "electricity_access" ~ "Electricity Access (%)",
      indicator == "gdp_per_capita" ~ "GDP per Capita (USD)",
      TRUE ~ indicator
    )
  ) %>%
  ggplot(aes(x = year, y = value, color = country, group = country)) +
  geom_line(size = 1) +
  geom_point(size = 2) +
  facet_wrap(~indicator, scales = "free_y", ncol = 2) +
  
  theme_minimal(base_size = 12) +
  theme(
    strip.text = element_text(size = 11, face = "bold"),
    strip.background = element_rect(fill = "gray95", color = NA),
    plot.title = element_text(size = 16, face = "bold"),
    plot.subtitle = element_text(size = 12),
    legend.position = "bottom",
    panel.grid.minor = element_blank()
  ) +
  
  scale_color_brewer(palette = "Set2") +
  
  labs(
    x = "",
    y = "Value",
    color = "Country",
    title = "Key Development Indicators in South Asia",
    subtitle = "Multiple dimensions of progress (1990-2024)",
    caption = "Data: World Bank via {WDI}"
  ) +
  
  transition_reveal(year)

animate(
  anim_multi_indicator, 
  nframes = 200,
  fps = 10,
  width = 1000,
  height = 900,
  dpi = 150,
  renderer = gifski_renderer("multi_indicator_animation.gif")
)

# ============================================================================
# 11. SCATTER PLOT ANIMATION: LITERACY VS MATERNAL MORTALITY
# ============================================================================

anim_scatter_lit_maternal <- extended_data %>%
  filter(!is.na(adult_literacy) & !is.na(maternal_mortality), year >= 1990) %>%
  mutate(
    is_pakistan = ifelse(country == "Pakistan", "Pakistan", "Other")
  ) %>%
  ggplot(aes(x = adult_literacy, y = maternal_mortality, 
             color = country, size = is_pakistan)) +
  geom_point(alpha = 0.8) +
  
  scale_size_manual(values = c("Pakistan" = 6, "Other" = 3), guide = "none") +
  scale_color_brewer(palette = "Set2") +
  
  theme_minimal(base_size = 14) +
  theme(
    plot.title = element_text(size = 18, face = "bold"),
    plot.subtitle = element_text(size = 14),
    legend.position = "right",
    panel.grid.minor = element_blank()
  ) +
  
  labs(
    x = "Adult Literacy Rate (%)",
    y = "Maternal Mortality (per 100,000 live births)",
    color = "Country",
    title = "Literacy vs Maternal Health in South Asia",
    subtitle = "Year: {frame_time}",
    caption = "Data: World Bank via {WDI}\nNote: Pakistan shown with larger points"
  ) +
  
  transition_time(year) +
  ease_aes('linear')

animate(
  anim_scatter_lit_maternal, 
  nframes = 130,
  fps = 10,
  width = 900,
  height = 700,
  dpi = 150,
  renderer = gifski_renderer("literacy_vs_maternal_scatter.gif")
)

# ============================================================================
# 12. SUMMARY STATISTICS
# ============================================================================

# Latest year statistics
latest_extended_stats <- extended_data %>%
  filter(year == max(year, na.rm = TRUE)) %>%
  select(country, adult_literacy, maternal_mortality, internet_users, 
         gdp_per_capita, electricity_access) %>%
  arrange(desc(gdp_per_capita))

print("Latest Statistics by Country:")
print(latest_extended_stats)

# Pakistan-specific progress analysis
pakistan_progress <- extended_data %>%
  filter(country == "Pakistan") %>%
  filter(year %in% c(1990, 2000, 2010, 2020, max(year))) %>%
  select(year, adult_literacy, maternal_mortality, internet_users, 
         electricity_access, gdp_per_capita) %>%
  arrange(year)

print("Pakistan Progress Over Time:")
print(pakistan_progress)

# ============================================================================
# 13. COMPLETION MESSAGE
# ============================================================================

print("=" * 70)
print("ANALYSIS COMPLETE!")
print("=" * 70)
print("\nAnimated GIFs created:")
print("  1. maternal_mortality_animation.gif")
print("  2. adult_literacy_animation.gif")
print("  3. internet_users_animation.gif")
print("  4. clean_water_access_bars.gif")
print("  5. female_labor_participation_bars.gif")
print("  6. gdp_per_capita_animation.gif")
print("  7. electricity_access_animation.gif")
print("  8. multi_indicator_animation.gif")
print("  9. literacy_vs_maternal_scatter.gif")
print("\nAll visualizations highlight Pakistan in dark green for easy comparison!")
print("=" * 70)