## What are packages in R and Python?
# Packages are collections of functions, data, and documentation that extend the capabilities of R and Python. They allow users to perform specific tasks without having to write code from scratch. 

## Installing and Loading Packages in R using pacman 

if(!requireNamespace("pacman", quietly = TRUE)) {
  install.packages("pacman")
}



pacman::p_load(tidyverse, data.table, readxl, janitor, ggplot2, sf, leaflet, rio, lubridate) 

# We will first learn how to import data having different formats 

# Importing Excel file
readxl::read_excel("data/defense.xlsx") %>%
  as.data.frame() -> military_data 

# Importing CSV file

readr::read_csv("data/education_analysis.csv") %>%
  as.data.frame() -> education_data

# Importing data dta/sav/sas files  using haven 
haven::read_dta()

# Importing various data formats using rio 

#Importing data from web URLs 

# Importing shapefiles using sf package
library(sf)
pakistan_sf <- sf::st_read("data/pakistan_districts.shp")

## Importing data from web APIs
# Using httr and jsonlite packages
library(httr)
library(jsonlite)
response <- httr::GET("https://api.example.com/data")

data_json <- httr::content(response, as = "text")

data_parsed <- jsonlite::fromJSON(data_json)

# Importing data from web APIs like WDI, World Bank, etc.
# Using WDI package
if(!requireNamespace("WDI", quietly = TRUE)) {
  install.packages("WDI")
}
library(WDI)
wdi_data <- WDI::WDI(country = "PK", indicator = "SP.POP.TOTL", start = 2000, end = 2020)

# Inspect the imported data  

dim()

str()

head()

summary()

tail()

glimpse()

# Cleaning data using janitor package

library(janitor)

clean_names()
# Renaming columns

rename()

## 5 Main verbs of dplyr package 
filter()
select()
mutate()
summarise()
group_by()
arrange()

# Data visualization using ggplot2 package

ggplot()
geom_bar()
geom_line()
geom_point()
labs()
theme_minimal()
scale_fill_manual()
facet_wrap()
# Mapping using sf and leaflet packages
leaflet()
addTiles()
addPolygons()
setView()
# Saving and exporting data using rio package

export()
# Exporting to CSV
rio::export(education_data, "education_analysis_exported.csv")
# Exporting to Excel
rio::export(military_data, "military_data_exported.xlsx")
# Exporting to shapefile
sf::st_write(pakistan_sf, "pakistan_districts_exported.shp")
# Exporting to RDS
saveRDS(military_data, "military_data_exported.rds")
# Exporting to RData
save(military_data, file = "military_data_exported.RData")
# Exporting to JSON
jsonlite::write_json(military_data, "military_data_exported.json")
# Exporting to Stata
haven::write_dta(military_data, "military_data_exported.dta")
# Exporting to SPSS
haven::write_sav(military_data, "military_data_exported.sav")

# 

