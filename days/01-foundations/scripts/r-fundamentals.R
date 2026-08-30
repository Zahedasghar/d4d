# ============================================================
#  Introduction to R: Pakistan District MPI, 2019-20
#  A step-by-step first script for new R users
# ============================================================
#
#  Three core variables:
#    mpi          - overall poverty score (higher = poorer)
#    h_incidence  - H: % of population that is poor
#    a_intensity  - A: average deprivation among the poor
#
#  Relationship: MPI = H x A / 100
# ============================================================


# --- Step 1: Load tools ------------------------------------
library(tidyverse)


# --- Step 2: Import data ------------------------------------
mpi <- read_csv(here::here("data/pakistan_mpi_district_2019_20.csv"))


# --- Step 3: First look at the data -------------------------
dim(mpi)        # rows x columns
str(mpi)        # column names and types
head(mpi)       # first 6 rows
glimpse(mpi)    # compact structure view


# --- Step 4: Further inspection -----------------------------
tail(mpi)       # last 6 rows
summary(mpi)    # min/mean/max for numeric columns


# --- Step 5: Standardise column names -----------------------
mpi <- mpi |> janitor::clean_names()
names(mpi)


# --- Step 6: Focus on the three core variables --------------
mpi |>
  select(district, mpi, h_incidence, a_intensity) |>
  head(10)


# --- Step 7: Rank districts by MPI ---------------------------
mpi |>
  select(district, province, mpi) |>
  arrange(desc(mpi)) |>
  head(10)


# --- Step 8: Filter by province -------------------------------
mpi |>
  filter(province == "Balochistan") |>
  select(district, mpi, h_incidence, a_intensity) |>
  arrange(desc(mpi))


# --- Step 9: Province-level averages (.by grouping) -----------
mpi |>
  summarise(
    avg_mpi = mean(mpi),
    avg_h   = mean(h_incidence),
    avg_a   = mean(a_intensity),
    .by = province
  ) |>
  arrange(desc(avg_mpi))


# --- Step 10: Build a plot incrementally -----------------------
ggplot(mpi, aes(x = h_incidence, y = a_intensity))
# Canvas only - no data mapped to a geometry yet

ggplot(mpi, aes(x = h_incidence, y = a_intensity)) +
  geom_point()
# Each point is one district

ggplot(mpi, aes(x = h_incidence, y = a_intensity, color = province)) +
  geom_point(size = 2) +
  theme_minimal() +
  labs(
    title    = "District-Level MPI Components, 2019-20",
    subtitle = "Each point represents one district",
    x        = "H: Incidence of poverty (%)",
    y        = "A: Intensity of deprivation",
    color    = "Province"
  )


# --- Step 11: Bar chart of the 10 poorest districts -------------
top10 <- mpi |>
  arrange(desc(mpi)) |>
  head(10)

ggplot(top10, aes(x = reorder(district, mpi), y = mpi, fill = province)) +
  geom_col() +
  coord_flip() +
  theme_minimal() +
  labs(
    title = "10 Poorest Districts by MPI Score (2019-20)",
    x = NULL,
    y = "MPI Score"
  )


# --- Step 12: Export outputs -------------------------------------
province_summary <- mpi |>
  summarise(
    avg_mpi = mean(mpi),
    avg_h   = mean(h_incidence),
    avg_a   = mean(a_intensity),
    .by = province
  )

write_csv(province_summary, "province_mpi_summary.csv")
ggsave("top10_poorest_districts.png", width = 8, height = 5)


# ============================================================
#  Summary of commands covered:
#  Import      - read_csv()
#  Inspect     - dim(), str(), head(), tail(), glimpse(), summary()
#  Clean       - clean_names()
#  Transform   - select(), filter(), arrange(), summarise(), .by
#  Visualize   - ggplot(), geom_point(), geom_col(), theme_minimal()
#  Export      - write_csv(), ggsave()
# ============================================================
