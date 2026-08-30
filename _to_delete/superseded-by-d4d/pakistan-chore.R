# install packages (Assuming these are run once to install)
# install.packages("sf")
# install.packages("readxl")
# install.packages("fuzzyjoin")
# install.packages("tidyverse")


# Load necessary libraries
library(sf)
library(readxl)
library(fuzzyjoin)
library(tidyverse)
library(stringr)

# --- 1. Data Preparation and Fuzzy Join ---

# Load and prepare the shapefile
shape_file <- st_read("data/shape_file/District_Boundary.shp") %>%
  # Standardize the district name in the shapefile for joining
  mutate(Dist_shp = str_to_title(tolower(DISTRICT)))

## Rename DISTRICT as District
shape_file <- shape_file %>%
  rename(District = DISTRICT)

# Load and prepare Excel data
xl_data <- read_excel("data/dist_data.xlsx")

# Perform fuzzy join between shape file and Excel data
joined_data <- stringdist_left_join(
  shape_file, xl_data,
  by = c("Dist_shp" = "District"),
  method = "jw", max_dist = 0.1
) %>%
  # Data cleaning logic to set indicator columns to NA if no good match was found
  mutate(
    District.y = ifelse(is.na(District.y), Dist_shp, District.y),
    across(
      # Select all columns EXCEPT for these key identifier/geometry columns
      .cols = -c(District.x, Shape_Leng, Shape_Area, Dist_shp, Sno, Province, District.y, geometry),
      # Set data to NA where the fuzzy join failed (using a reasonable check)
      .fns = ~ ifelse(is.na(District.y) | District.y != Dist_shp, NA, .)
    )
  )

# Select final columns and ensure the key indicator is numeric
map_data <- joined_data %>%
  select(Dist_shp, Shape_Area, Province, starts_with("Stunting-MICS"), geometry) %>% # Select all Stunting-MICS columns for the time-series plot
  # Apply as.numeric to all columns starting with "Stunting-MICS"
  mutate(across(starts_with("Stunting-MICS"), as.numeric))

if (!inherits(map_data, "sf")) {
  map_data <- st_as_sf(map_data)
}

# --- 2. Choropleth Map: All of Pakistan ---
# Assumes 'Stunting-MICS' is the column for a single time point

ggplot(data = map_data) +
  geom_sf(aes(fill = `Stunting-MICS`), color = "black") +
  scale_fill_viridis_c(option = "plasma", na.value = "grey", direction = -1) + # Added direction=-1 for better contrast (optional)
  labs(
    title = "Stunting Levels by District in Pakistan (MICS)",
    fill = "Stunting (%)"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(hjust = 0.5),
    # Remove map junk
    axis.text = element_blank(),
    axis.ticks = element_blank(),
    panel.grid = element_blank()
  )


##############################################################3
# --- 3. Choropleth Map: Punjab Province (Basic) ---

# Filter data for Punjab province only
punjab_data <- map_data %>%
  filter(Province == "Punjab") # Ensure the province name matches exactly

# Plot the map for Punjab
ggplot(data = punjab_data) +
  geom_sf(aes(fill = `Stunting-MICS`), color = "black") +
  scale_fill_viridis_c(option = "plasma", na.value = "grey", direction = -1) +
  labs(
    title = "Stunting Levels by District in Punjab (MICS)",
    fill = "Stunting (%)"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(hjust = 0.5)
  )


#### --- 4. Choropleth Map: Punjab Province (Improved Aesthetics) ---
ggplot(data = punjab_data) +
  geom_sf(aes(fill = `Stunting-MICS`), color = "black") +
  scale_fill_viridis_c(option = "plasma", na.value = "grey", direction = -1) +
  labs(
    title = "Stunting Levels by District in Punjab",
    fill = "Stunting (%)"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(hjust = 0.5),
    axis.text = element_blank(),    # Remove axis labels (numbers)
    axis.ticks = element_blank(),   # Remove axis ticks
    axis.title = element_blank(),   # Remove axis titles (X, Y)
    panel.grid = element_blank()    # Remove grid lines
  )


##########################
# --- 5. Choropleth Map: Punjab Province for Two Time Points (Faceted) ---

# Filter the data for Punjab province only (Already done above, but for robustness)
punjab_data_time <- map_data %>%
  filter(Province == "Punjab")

# Reshape the data for time-based visualization (from wide to long format)
punjab_long <- punjab_data_time %>%
  pivot_longer(
    cols = starts_with("Stunting-MICS"),
    names_to = "Year",
    values_to = "Percentage"
  ) %>%
  # Clean the 'Year' column: convert "Stunting-MICS-2014" to "2014"
  mutate(Year = str_replace(Year, "Stunting-MICS-", "")) # ASSUMES columns are named 'Stunting-MICS-YYYY'

# PLOT CORRECTION: The fill aesthetic in geom_sf must use the new 'values_to' column name, which is 'Percentage'.
ggplot(data = punjab_long) +
  geom_sf(aes(fill = Percentage), color = "black") + # CORRECTED: Changed 'fill = Stunting' to 'fill = Percentage'
  scale_fill_viridis_c(option = "plasma", na.value = "grey", direction = -1) +
  labs(
    title = "Stunting Levels by District in Punjab (Time-Series Comparison)",
    fill = "Stunting (%)"
  ) +
  facet_wrap(~ Year) + # No need for scales="free" here, fixed scale is best for maps
  theme_minimal() +
  theme(
    plot.title = element_text(hjust = 0.5),
    strip.text = element_text(size = 12, face = "bold"),
    axis.text = element_blank(),
    axis.ticks = element_blank(),
    axis.title = element_blank(),
    panel.grid = element_blank()
  )
# Note: Ensure your column names in the Excel file match the patterns used in the code.



# --- Prerequisites (Libraries and Data Loading assumed to be correct) ---
# ... (shape_file, xl_data, joined_data, map_data, punjab_data_time, punjab_long are prepared) ...
# ... (punjab_long is the long format data ready for faceting) ...


########################################################
# EXTENSION 1: Enhanced Choropleth Map for Punjab (Single Time Point)
# This uses discrete color bins and labels for better readability.

# 1. Calculate Quantiles for Binning (e.g., into 4 groups)
# This step determines the cut-off points based on the distribution of stunting
quantiles <- quantile(punjab_data_time$`Stunting-MICS`, probs = seq(0, 1, by = 0.25), na.rm = TRUE)

# 2. Create a new binned column using the calculated quantiles
punjab_data_binned <- punjab_data_time %>%
  mutate(Stunting_Bin = cut(`Stunting-MICS`,
                            breaks = unique(quantiles),
                            include.lowest = TRUE,
                            labels = c("Lowest Q1", "Low Q2", "High Q3", "Highest Q4"),
                            right = TRUE)) # Q1 contains lowest values

# 3. Plot the Binned Map with District Labels
ggplot(data = punjab_data_binned) +
  # Layer 1: Draw the Map with Discrete Colors
  geom_sf(aes(fill = Stunting_Bin), color = "white", size = 0.2) +

  # Layer 2: Add District Labels (showing the actual percentage)
  geom_sf_text(aes(label = round(`Stunting-MICS`, 1)), # Label with the stunting percentage
               color = "black",
               size = 2.5,
               check_overlap = TRUE) + # Prevents too much overlap

  # Use a discrete color scale (e.g., 'Dark2' from RColorBrewer)
  scale_fill_brewer(palette = "YlOrRd",
                    name = "Stunting Level",
                    na.value = "grey80") +

  # Add titles and theme enhancements
  labs(
    title = "Stunting Level Categorization in Punjab Districts",
    subtitle = "Based on Quartiles (Q1=Lowest Stunting, Q4=Highest Stunting)",
    caption = "Data Source: MICS (Single Year)"
  ) +
  theme_void() + # Clean map background
  theme(
    plot.title = element_text(hjust = 0.5, face = "bold"),
    plot.subtitle = element_text(hjust = 0.5),
    legend.position = "bottom"
  )

########################################################
# EXTENSION 2: Enhanced Time-Series Comparison (Faceted Map)
# Use a common, fixed scale for the 'fill' aesthetic across all years for true comparison.

# 1. Determine the Min/Max Stunting Value across ALL time points in the long data
max_stunting <- max(punjab_long$Percentage, na.rm = TRUE)
min_stunting <- min(punjab_long$Percentage, na.rm = TRUE)

# 2. Plot the Faceted Map with Labels and Fixed Color Scale
ggplot(data = punjab_long) +
  # Layer 1: Draw the Map with Common Continuous Colors
  geom_sf(aes(fill = Percentage), color = "black", size = 0.1) +

  # Layer 2: Add District Labels (The district name for context)
  geom_sf_text(aes(label = Dist_shp),
               color = "white", # Use white text for better contrast against fill
               size = 1.8,
               check_overlap = TRUE) +

  # Apply the continuous color scale with fixed limits
  scale_fill_viridis_c(
    option = "plasma",
    name = "Stunting (%)",
    na.value = "grey",
    limits = c(min_stunting, max_stunting) # FIXED LIMITS for comparison!
  ) +

  # Use faceting to split by time point
  facet_wrap(~ Year, ncol = 2) +

  # Add titles and theme enhancements
  labs(
    title = "Change in Stunting Levels Across Punjab Districts",
    subtitle = "Comparing District Stunting (%) Between MICS Years",
    caption = "Note: Colors are consistent across both maps for direct comparison."
  ) +
  theme_void() +
  theme(
    plot.title = element_text(hjust = 0.5, face = "bold"),
    plot.subtitle = element_text(hjust = 0.5),
    strip.text = element_text(size = 10, face = "bold", margin = margin(t = 5, b = 5)), # Label above each map
    legend.position = "bottom"
  )

# ====================================================================
# EXTENSION 3: Correlation Heatmap - Stunting vs Other Indicators
# ====================================================================

library(corrplot)

# Select key variables for correlation analysis
cor_vars <- joined_data %>%
  st_drop_geometry() %>%
  select(`Stunting-MICS`, Wasting, Exclusive_breastfeeding,
         literacy, `Literacy rate women (15-49)`,
         `Basic drinking water facility`, `Basic sanitation`,
         `Open Defecation`, `ANC (Health Professional)`,
         `Skilled attendant at delivery`, `Institutional deliveries`,
         `Neonatal mortality rate  (per thousands)`,
         `Minimum Acceptabe Diet (MAD) All children`) %>%
  mutate(across(everything(), as.numeric))

# Calculate correlations
cor_matrix <- cor(cor_vars, use = "pairwise.complete.obs")

# Visualize correlation matrix
corrplot(cor_matrix, method = "color", type = "upper",
         tl.col = "black", tl.srt = 45, tl.cex = 0.7,
         title = "Correlation: Stunting with Health & Socioeconomic Indicators",
         mar = c(0,0,2,0))


# ====================================================================
# EXTENSION 4: Multi-Indicator Dashboard (Small Multiples)
# ====================================================================

# Prepare data for multiple indicators
# ====================================================================
# EXTENSION 4: Multi-Indicator Dashboard (Small Multiples) - FIXED
# ====================================================================

# Prepare data for multiple indicators - USE joined_data, not punjab_data
multi_indicators <- joined_data %>%
  filter(Province == "Punjab") %>%
  select(Dist_shp, Province, geometry,
         `Stunting-MICS`, Wasting,
         `Open Defecation`, `Basic sanitation`,
         `Minimum Acceptabe Diet (MAD) All children`,
         `Exclusive_breastfeeding`) %>%
  # Convert to numeric BEFORE pivot_longer
  mutate(across(c(`Stunting-MICS`, Wasting, `Open Defecation`,
                  `Basic sanitation`, `Minimum Acceptabe Diet (MAD) All children`,
                  `Exclusive_breastfeeding`), as.numeric)) %>%
  # Pivot to long format
  pivot_longer(cols = c(`Stunting-MICS`, Wasting, `Open Defecation`,
                        `Basic sanitation`, `Minimum Acceptabe Diet (MAD) All children`,
                        `Exclusive_breastfeeding`),
               names_to = "Indicator",
               values_to = "Value")

# Ensure it's still an sf object after pivot_longer
if (!inherits(multi_indicators, "sf")) {
  multi_indicators <- st_as_sf(multi_indicators)
}

# Plot multiple indicators at once
ggplot(multi_indicators) +
  geom_sf(aes(fill = Value), color = "black", size = 0.1) +
  scale_fill_viridis_c(option = "plasma", na.value = "grey") +
  facet_wrap(~ Indicator, ncol = 3) +
  labs(title = "Child Nutrition & Health Indicators in Punjab",
       fill = "Value (%)") +
  theme_void() +
  theme(
    plot.title = element_text(hjust = 0.5, face = "bold", size = 14),
    strip.text = element_text(size = 8, face = "bold"),
    legend.position = "bottom"
  )

# ====================================================================
# EXTENSION 5: Scatter Plot - Stunting vs Key Predictors
# ====================================================================

# Stunting vs. Women's Literacy with Provincial colors
ggplot(joined_data %>% st_drop_geometry(),
       aes(x = `Literacy rate women (15-49)`,
           y = `Stunting-MICS`,
           color = Province)) +
  geom_point(size = 3, alpha = 0.7) +
  geom_smooth(method = "lm", se = TRUE, color = "black", linetype = "dashed") +
  labs(
    title = "Stunting vs. Women's Literacy Rate by District",
    x = "Women's Literacy Rate (%)",
    y = "Stunting (%)",
    color = "Province"
  ) +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5, face = "bold"))

# Additional scatter: Stunting vs Open Defecation
ggplot(joined_data %>% st_drop_geometry(),
       aes(x = `Open Defecation`,
           y = `Stunting-MICS`,
           color = Province)) +
  geom_point(size = 3, alpha = 0.7) +
  geom_smooth(method = "lm", se = TRUE, color = "black", linetype = "dashed") +
  labs(
    title = "Stunting vs. Open Defecation by District",
    x = "Open Defecation (%)",
    y = "Stunting (%)",
    color = "Province"
  ) +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5, face = "bold"))


# ====================================================================
# EXTENSION 6: Composite Vulnerability Index
# ====================================================================

# Create composite health vulnerability index
# ====================================================================
# EXTENSION 6: Composite Vulnerability Index - FIXED
# ====================================================================

# Create composite health vulnerability index
vulnerability_data <- joined_data %>%
  mutate(
    # Normalize indicators (higher = worse outcomes)
    stunt_norm = as.numeric(scale(`Stunting-MICS`))[1:n()],
    wast_norm = as.numeric(scale(Wasting))[1:n()],
    sanit_norm = -as.numeric(scale(`Basic sanitation`))[1:n()],  # Reverse: lower sanitation = worse
    water_norm = -as.numeric(scale(`Basic drinking water facility`))[1:n()],
    mort_norm = as.numeric(scale(`Neonatal mortality rate  (per thousands)`))[1:n()],

    # Calculate composite index (average of normalized scores)
    Vulnerability_Index = (stunt_norm + wast_norm + sanit_norm +
                             water_norm + mort_norm) / 5
  )

# Ensure it's still an sf object
if (!inherits(vulnerability_data, "sf")) {
  vulnerability_data <- st_as_sf(vulnerability_data)
}

# Map the vulnerability index - ALL PAKISTAN
ggplot(vulnerability_data) +
  geom_sf(aes(fill = Vulnerability_Index), color = "black") +
  scale_fill_gradient2(low = "green", mid = "yellow", high = "red",
                       midpoint = 0, na.value = "grey",
                       name = "Vulnerability\nIndex") +
  labs(title = "Composite Child Health Vulnerability Index",
       subtitle = "Combining Stunting, Wasting, Sanitation, Water & Mortality") +
  theme_void() +
  theme(
    plot.title = element_text(hjust = 0.5, face = "bold"),
    plot.subtitle = element_text(hjust = 0.5),
    legend.position = "bottom"
  )

# Map the vulnerability index - PUNJAB ONLY
vulnerability_punjab <- vulnerability_data %>%
  filter(Province == "Punjab")

ggplot(vulnerability_punjab) +
  geom_sf(aes(fill = Vulnerability_Index), color = "black") +
  scale_fill_gradient2(low = "green", mid = "yellow", high = "red",
                       midpoint = 0, na.value = "grey",
                       name = "Vulnerability\nIndex") +
  labs(title = "Child Health Vulnerability Index - Punjab",
       subtitle = "Combining Multiple Health Indicators") +
  theme_void() +
  theme(
    plot.title = element_text(hjust = 0.5, face = "bold"),
    plot.subtitle = element_text(hjust = 0.5),
    legend.position = "bottom"
  )
# Map the vulnerability index - PUNJAB ONLY
vulnerability_punjab <- vulnerability_data %>%
  filter(Province == "Punjab")

ggplot(vulnerability_punjab) +
  geom_sf(aes(fill = Vulnerability_Index), color = "black") +
  scale_fill_gradient2(low = "green", mid = "yellow", high = "red",
                       midpoint = 0, na.value = "grey",
                       name = "Vulnerability\nIndex") +
  labs(title = "Child Health Vulnerability Index - Punjab",
       subtitle = "Combining Multiple Health Indicators") +
  theme_void() +
  theme(
    plot.title = element_text(hjust = 0.5, face = "bold"),
    plot.subtitle = element_text(hjust = 0.5),
    legend.position = "bottom"
  )


# ====================================================================
# EXTENSION 7: District Rankings & League Table
# ====================================================================

# Create ranking table for Punjab
district_rankings <- joined_data %>%
  st_drop_geometry() %>%
  filter(Province == "Punjab") %>%
  select(District.y, `Stunting-MICS`, literacy,
         `Basic sanitation`, `Skilled attendant at delivery`) %>%
  mutate(across(-District.y, as.numeric)) %>%
  arrange(`Stunting-MICS`) %>%
  mutate(Rank = row_number(),
         Performance = case_when(
           Rank <= 10 ~ "Top 10 (Best)",
           Rank > n() - 10 ~ "Bottom 10 (Worst)",
           TRUE ~ "Middle"
         ))

# View the top and bottom performers
print("Best Performing Districts (Lowest Stunting):")
print(head(district_rankings, 10))

print("Worst Performing Districts (Highest Stunting):")
print(tail(district_rankings, 10))

# Visualize top/bottom performers
ggplot(district_rankings %>% filter(Performance != "Middle"),
       aes(x = reorder(District.y, `Stunting-MICS`),
           y = `Stunting-MICS`,
           fill = Performance)) +
  geom_col() +
  coord_flip() +
  scale_fill_manual(values = c("Top 10 (Best)" = "darkgreen",
                               "Bottom 10 (Worst)" = "darkred")) +
  labs(title = "Best and Worst Performing Districts in Punjab",
       subtitle = "Based on Stunting Prevalence",
       x = NULL, y = "Stunting (%)") +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5, face = "bold"))


# ====================================================================
# EXTENSION 8: Provincial Comparison Boxplots
# ====================================================================

# Provincial comparison
province_comparison <- joined_data %>%
  st_drop_geometry() %>%
  select(Province, `Stunting-MICS`, Wasting,
         literacy, `Basic sanitation`) %>%
  pivot_longer(cols = -Province,
               names_to = "Indicator",
               values_to = "Value") %>%
  mutate(Value = as.numeric(Value))

# Boxplot comparison
ggplot(province_comparison, aes(x = Province, y = Value, fill = Province)) +
  geom_boxplot() +
  facet_wrap(~ Indicator, scales = "free_y", ncol = 2) +
  labs(title = "Distribution of Key Indicators by Province",
       y = "Value (%)") +
  theme_minimal() +
  theme(
    plot.title = element_text(hjust = 0.5, face = "bold"),
    axis.text.x = element_text(angle = 45, hjust = 1),
    legend.position = "none"
  )


# ====================================================================
# EXTENSION 9: Gap Analysis - Priority Districts for Intervention
# ====================================================================

# Create priority classification
priority_data <- joined_data %>%
  st_drop_geometry() %>%
  mutate(
    High_Stunting = `Stunting-MICS` > median(`Stunting-MICS`, na.rm = TRUE),
    Low_Sanitation = `Basic sanitation` < median(`Basic sanitation`, na.rm = TRUE),
    Priority_Level = case_when(
      High_Stunting & Low_Sanitation ~ "High Priority",
      High_Stunting | Low_Sanitation ~ "Medium Priority",
      TRUE ~ "Low Priority"
    )
  )

# Map priority areas - ALL PAKISTAN
# ====================================================================
# EXTENSION 9: Gap Analysis - Priority Districts for Intervention - FIXED
# ====================================================================

# Create priority classification
priority_data <- joined_data %>%
  st_drop_geometry() %>%
  mutate(
    High_Stunting = `Stunting-MICS` > median(`Stunting-MICS`, na.rm = TRUE),
    Low_Sanitation = `Basic sanitation` < median(`Basic sanitation`, na.rm = TRUE),
    Priority_Level = case_when(
      High_Stunting & Low_Sanitation ~ "High Priority",
      High_Stunting | Low_Sanitation ~ "Medium Priority",
      TRUE ~ "Low Priority"
    )
  ) %>%
  distinct(District.y, .keep_all = TRUE) %>%  # Remove duplicates
  select(District.y, Priority_Level)

# Map priority areas - ALL PAKISTAN
priority_map_data <- joined_data %>%
  left_join(priority_data, by = "District.y", relationship = "many-to-one")

# Ensure it's still an sf object
if (!inherits(priority_map_data, "sf")) {
  priority_map_data <- st_as_sf(priority_map_data)
}

# Plot the map
ggplot(priority_map_data) +
  geom_sf(aes(fill = Priority_Level), color = "black") +
  scale_fill_manual(values = c("High Priority" = "#d73027",
                               "Medium Priority" = "#fee08b",
                               "Low Priority" = "#1a9850"),
                    na.value = "grey") +
  labs(title = "Priority Districts for Intervention",
       subtitle = "Based on Stunting & Sanitation Levels",
       fill = "Priority") +
  theme_void() +
  theme(
    plot.title = element_text(hjust = 0.5, face = "bold"),
    plot.subtitle = element_text(hjust = 0.5),
    legend.position = "bottom"
  )

# ====================================================================
# EXTENSION 10: Cluster Analysis - Group Similar Districts - FIXED
# ====================================================================

# Load required libraries
library(cluster)
library(factoextra)

# Prepare data for clustering (remove NAs)
cluster_input <- joined_data %>%
  st_drop_geometry() %>%
  select(District.y, `Stunting-MICS`, literacy, `Basic sanitation`,
         `Open Defecation`, `Skilled attendant at delivery`,
         `Minimum Acceptabe Diet (MAD) All children`) %>%
  mutate(across(-District.y, as.numeric)) %>%
  na.omit()

# Scale the data
cluster_data_scaled <- cluster_input %>%
  select(-District.y) %>%
  scale()

# Determine optimal number of clusters
fviz_nbclust(cluster_data_scaled, kmeans, method = "wss") +
  labs(title = "Elbow Method for Optimal Clusters")

# Perform k-means clustering (using 4 clusters)
set.seed(123)
kmeans_result <- kmeans(cluster_data_scaled, centers = 4, nstart = 25)

# Add cluster assignment back to data
cluster_input$Cluster <- as.factor(kmeans_result$cluster)

# Merge with spatial data - KEEP THE SF CLASS
joined_data_clustered <- joined_data %>%
  left_join(cluster_input %>% select(District.y, Cluster),
            by = "District.y")

# IMPORTANT: Re-set as sf object if needed
if (!inherits(joined_data_clustered, "sf")) {
  joined_data_clustered <- st_sf(joined_data_clustered)
}

# Map clusters - ALL PAKISTAN
ggplot(joined_data_clustered) +
  geom_sf(aes(fill = Cluster), color = "white", size = 0.2) +
  scale_fill_brewer(palette = "Set3", na.value = "grey") +
  labs(title = "District Clusters Based on Health & Socioeconomic Profile",
       subtitle = "K-means Clustering (k=4)",
       fill = "Cluster") +
  theme_void() +
  theme(
    plot.title = element_text(hjust = 0.5, face = "bold"),
    plot.subtitle = element_text(hjust = 0.5),
    legend.position = "bottom"
  )

p11 <- ggplot(joined_data_clustered) +
  geom_sf(aes(fill = Cluster), color = "white", size = 0.2) +
  scale_fill_brewer(palette = "Set3", na.value = "grey") +
  labs(title = "District Clusters Based on Health & Socioeconomic Profile",
       subtitle = "K-means Clustering (k=4)",
       fill = "Cluster") +
  theme_void() +
  theme(
    plot.title = element_text(hjust = 0.5, face = "bold"),
    plot.subtitle = element_text(hjust = 0.5),
    legend.position = "bottom"
  )

plotly::ggplotly(p11)


# Cluster characteristics
cluster_summary <- cluster_input %>%
  group_by(Cluster) %>%
  summarise(
    n_districts = n(),
    avg_stunting = mean(`Stunting-MICS`, na.rm = TRUE),
    avg_literacy = mean(literacy, na.rm = TRUE),
    avg_sanitation = mean(`Basic sanitation`, na.rm = TRUE),
    avg_open_defecation = mean(`Open Defecation`, na.rm = TRUE)
  )

print("Cluster Characteristics:")
print(cluster_summary)
