# Create NHANES practice dataset for workshop
library(tidyverse)
library(NHANES)

set.seed(2024)

# Load and prepare data
data("NHANES")

practice_data <- NHANES %>%
  as_tibble() %>%
  distinct(ID, .keep_all = TRUE) %>%
  select(
    ID, Gender, Age, Race1, Education, MaritalStatus,
    Height, Weight, BMI, BPSysAve, BPDiaAve,
    Diabetes, PhysActive, SmokeNow, HHIncome, Poverty
  ) %>%
  # Sample 1000 rows for practice
  slice_sample(n = 1000)

# Save as CSV
write_csv(practice_data, "nhanes_practice_data.csv")

cat("Practice dataset created: nhanes_practice_data.csv\n")
cat("Rows:", nrow(practice_data), "\n")
cat("Columns:", ncol(practice_data), "\n")
