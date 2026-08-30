# Install and load required packages
# install.packages(c("rgeoboundaries", "sf", "tidyverse", "leaflet"))

library(rgeoboundaries)
library(sf)
library(tidyverse)
library(leaflet)

# Get Pakistan districts (admin level 2)
pakistan_sf <- geoboundaries("Pakistan", adm_lvl = 2)

# Inspect the data structure
print("Column names in the dataset:") 

names(pakistan_sf)

print("\nFirst few rows:")
head(pakistan_sf)

print("\nNumber of districts:")
nrow(pakistan_sf)

# Check unique shape names
print("\nSample district names:")
print(head(unique(pakistan_sf$shapeName), 20))

# Define provinces and their districts
# We'll assign provinces based on district names
pakistan_sf <- pakistan_sf %>%
  mutate(
    district = shapeName,
    province = case_when(
      # Punjab districts
      str_detect(district, "Lahore|Faisalabad|Rawalpindi|Multan|Gujranwala|Sialkot|Bahawalpur|Sargodha|Sheikhupura|Jhang|Rahim Yar Khan|Sahiwal|Okara|Gujrat|Kasur|Mianwali|Dera Ghazi Khan|Vehari|Bahawalnagar|Pakpattan|Khanewal|Hafizabad|Mandi Bahauddin|Chiniot|Jhelum|Attock|Chakwal|Toba Tek Singh|Khushab|Lodhran|Muzaffargarh|Narowal|Nankana Sahib|Rajanpur|Layyah") ~ "Punjab",

      # Sindh districts
      str_detect(district, "Karachi|Hyderabad|Sukkur|Larkana|Mirpur Khas|Nawabshah|Shaheed Benazirabad|Shikarpur|Jacobabad|Khairpur|Dadu|Thatta|Badin|Sanghar|Ghotki|Kashmore|Tharparkar|Umerkot|Tando Allahyar|Tando Muhammad Khan|Matiari|Jamshoro|Naushahro Feroze|Qambar|Shahdadkot|Sujawal") ~ "Sindh",

      # Khyber Pakhtunkhwa districts
      str_detect(district, "Peshawar|Mardan|Abbottabad|Kohat|Bannu|Swat|Dera Ismail Khan|Charsadda|Nowshera|Mansehra|Swabi|Malakand|Dir|Chitral|Haripur|Karak|Hangu|Buner|Lakki Marwat|Tank|Battagram|Shangla|Kohistan|Tor Ghar|Torghar") ~ "Khyber Pakhtunkhwa",

      # Balochistan districts
      str_detect(district, "Quetta|Khuzdar|Turbat|Sibi|Zhob|Gwadar|Nasirabad|Jaffarabad|Loralai|Kharan|Kalat|Mastung|Pishin|Kech|Lasbela|Awaran|Panjgur|Chagai|Nushki|Washuk|Dera Bugti|Kohlu|Barkhan|Musakhel|Ziarat|Harnai|Jhal Magsi|Killa Abdullah|Killa Saifullah|Sherani|Duki") ~ "Balochistan",

      # Gilgit-Baltistan districts
      str_detect(district, "Gilgit|Skardu|Hunza|Nagar|Ghanche|Shigar|Kharmang|Astore|Diamer|Ghizer") ~ "Gilgit-Baltistan",

      # Azad Kashmir districts
      str_detect(district, "Muzaffarabad|Mirpur|Rawalakot|Kotli|Bhimber|Bagh|Neelum|Sudhnati|Poonch|Haveli") ~ "Azad Kashmir",

      # Islamabad
      str_detect(district, "Islamabad") ~ "Islamabad Capital Territory",

      TRUE ~ "Other"
    )
  )

# Check province assignment
print("\nDistricts by Province:")
table(pakistan_sf$province)

# Province color palette
province_pal <- c(
  "Punjab" = "#1a5f3f",
  "Sindh" = "#0077b6",
  "Khyber Pakhtunkhwa" = "#ae2012",
  "Balochistan" = "#f77f00",
  "Gilgit-Baltistan" = "#6a4c93",
  "Azad Kashmir" = "#2a9d8f",
  "Islamabad Capital Territory" = "#8b0000",
  "Other" = "#999999"
)

# Create static ggplot2 map - Districts colored by province
ggplot_districts <- pakistan_sf %>%
  ggplot() +
  geom_sf(aes(fill = province), linewidth = 0.3, color = "white") +
  scale_fill_manual(values = province_pal) +
  theme_minimal() +
  labs(
    title = "Districts of Pakistan",
    subtitle = "Colored by Province (Administrative Level 2)",
    fill = "Province",
    caption = "Data source: geoBoundaries"
  ) +
  theme(
    plot.title = element_text(hjust = 0.5, face = "bold", size = 18),
    plot.subtitle = element_text(hjust = 0.5, size = 12, color = "grey40"),
    legend.position = "right",
    legend.title = element_text(face = "bold"),
    panel.grid = element_blank(),
    axis.text = element_blank(),
    axis.ticks = element_blank()
  )

print(ggplot_districts)

# Save the static map
ggsave("pakistan_districts_map.png", ggplot_districts,
       width = 12, height = 10, dpi = 300, bg = "white")

# Create interactive leaflet map with districts
province_colorFactor <- colorFactor(
  palette = province_pal,
  domain = pakistan_sf$province
)

leaflet_map <- leaflet(pakistan_sf) %>%
  addProviderTiles(providers$CartoDB.Positron) %>%
  addPolygons(
    fillColor = ~province_colorFactor(province),
    weight = 1,
    color = "white",
    opacity = 1,
    fillOpacity = 0.7,
    popup = ~paste0(
      "<strong>District: ", district, "</strong><br>",
      "<strong>Province: ", province, "</strong><br>",
      "Shape ID: ", shapeID
    ),
    highlightOptions = highlightOptions(
      weight = 3,
      color = "#333",
      fillOpacity = 0.9,
      bringToFront = TRUE
    ),
    label = ~paste0(district, " (", province, ")"),
    labelOptions = labelOptions(
      style = list("font-weight" = "normal", padding = "3px 8px"),
      textsize = "12px",
      direction = "auto"
    ),
    group = "Districts"
  ) %>%
  addLegend(
    pal = province_colorFactor,
    values = ~province,
    title = "Province",
    position = "bottomright",
    opacity = 0.8
  ) %>%
  addLayersControl(
    overlayGroups = "Districts",
    options = layersControlOptions(collapsed = FALSE)
  ) %>%
  setView(lng = 69.3451, lat = 30.3753, zoom = 5)

# Display the leaflet map
leaflet_map

# Save the leaflet map as HTML
library(htmlwidgets)
saveWidget(leaflet_map, "pakistan_districts_interactive.html",
           selfcontained = TRUE)

# Calculate statistics
pakistan_sf <- pakistan_sf %>%
  mutate(
    area_sqkm = as.numeric(st_area(geometry)) / 1e6
  )

# District count and area by province
province_stats <- pakistan_sf %>%
  st_drop_geometry() %>%
  group_by(province) %>%
  summarise(
    num_districts = n(),
    total_area_sqkm = sum(area_sqkm, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(desc(total_area_sqkm))

print("\nProvince Statistics:")
print(province_stats)

# Top 20 largest districts
largest_districts <- pakistan_sf %>%
  st_drop_geometry() %>%
  select(district, province, area_sqkm) %>%
  arrange(desc(area_sqkm)) %>%
  head(20)

print("\nTop 20 Largest Districts:")
print(largest_districts)

# Create visualization of districts per province
district_count_plot <- ggplot(province_stats,
                              aes(x = reorder(province, num_districts),
                                  y = num_districts,
                                  fill = province)) +
  geom_col(show.legend = FALSE) +
  geom_text(aes(label = num_districts), hjust = -0.3, size = 4, fontface = "bold") +
  scale_fill_manual(values = province_pal) +
  coord_flip() +
  theme_minimal() +
  labs(
    title = "Number of Districts by Province",
    x = "Province",
    y = "Number of Districts",
    caption = "Data source: geoBoundaries"
  ) +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    axis.title = element_text(face = "bold")
  ) +
  ylim(0, max(province_stats$num_districts) * 1.1)

print(district_count_plot)

# Save the count plot
ggsave("pakistan_districts_count.png", district_count_plot,
       width = 8, height = 6, dpi = 300, bg = "white")

# Create a faceted map by province
facet_map <- pakistan_sf %>%
  filter(province != "Other") %>%
  ggplot() +
  geom_sf(aes(fill = province), linewidth = 0.2, color = "white", show.legend = FALSE) +
  scale_fill_manual(values = province_pal) +
  facet_wrap(~province, ncol = 3) +
  theme_minimal() +
  labs(
    title = "Districts by Province",
    caption = "Data source: geoBoundaries"
  ) +
  theme(
    plot.title = element_text(face = "bold", size = 16, hjust = 0.5),
    strip.text = element_text(face = "bold", size = 11),
    panel.grid = element_blank(),
    axis.text = element_blank(),
    axis.ticks = element_blank()
  )

print(facet_map)

# Save faceted map
ggsave("pakistan_districts_faceted.png", facet_map,
       width = 14, height = 10, dpi = 300, bg = "white")

cat("\n✓ District-level maps created successfully!\n")
cat("- District map saved as: pakistan_districts_map.png\n")
cat("- Interactive map saved as: pakistan_districts_interactive.html\n")
cat("- District count chart saved as: pakistan_districts_count.png\n")
cat("- Faceted map saved as: pakistan_districts_faceted.png\n")
cat("\nTotal districts mapped:", nrow(pakistan_sf), "\n")
