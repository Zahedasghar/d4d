# ==============================================================================
# setup-packages.R — install everything the d4d workshop needs
#
# Run once, before Day 1:      source("R/setup-packages.R")
#
# Design notes
#   * Fails loudly. Anything that will not install is reported at the end as an
#     explicit error, rather than being skipped with a warning nobody reads.
#   * Grouped by workshop day so a participant short on time or bandwidth can
#     install only what the next session needs.
#   * Spatial packages are separated because they carry system dependencies
#     (GDAL/GEOS/PROJ) that fail differently on Windows, macOS and Linux.
# ==============================================================================

core <- c(
  "tidyverse",   # dplyr, ggplot2, tidyr, readr, purrr, stringr, forcats
  "here",        # project-root-relative paths — used by every script here
  "janitor",     # clean_names(), tabyl(), messy-data helpers
  "haven",       # .sav / .dta import
  "readxl",      # .xlsx import
  "quarto"       # render from R
)

day2_tables_and_charts <- c(
  "gt", "gtExtras", "gtsummary",
  "scales", "ggthemes", "ggrepel", "patchwork",
  "plotly", "DT"
)

day2_data_access <- c(
  "WDI",         # World Bank indicators API
  "httr2", "jsonlite",
  "gapminder", "NHANES", "palmerpenguins", "countrycode"
)

day3_modelling <- c(
  "broom", "car", "survey", "srvyr", "marginaleffects", "performance"
)

day3_spatial <- c(
  "sf", "leaflet", "tmap", "rgeoboundaries", "fuzzyjoin"
)

day4_reporting <- c(
  "knitr", "rmarkdown", "flexdashboard", "gganimate", "magick"
)

all_pkgs <- unique(c(
  core,
  day2_tables_and_charts,
  day2_data_access,
  day3_modelling,
  day3_spatial,
  day4_reporting
))

# ------------------------------------------------------------------------------

install_missing <- function(pkgs) {
  missing <- pkgs[!pkgs %in% rownames(installed.packages())]

  if (length(missing) == 0) {
    message("All ", length(pkgs), " packages already installed.")
    return(invisible(character()))
  }

  message("Installing ", length(missing), " package(s): ",
          paste(missing, collapse = ", "))
  install.packages(missing)

  still_missing <- missing[!missing %in% rownames(installed.packages())]
  invisible(still_missing)
}

failed <- install_missing(all_pkgs)

if (length(failed) > 0) {
  stop(
    "These packages did not install:\n  ",
    paste(failed, collapse = "\n  "),
    "\n\nSpatial packages (sf, terra, tmap) usually fail because of missing system ",
    "libraries.\n  Ubuntu/Debian: sudo apt install libgdal-dev libgeos-dev libproj-dev libudunits2-dev",
    "\n  macOS:         brew install gdal geos proj udunits",
    "\n  Windows:       binaries are prebuilt — retry, or update R to >= 4.3.",
    call. = FALSE
  )
}

# `rgeoboundaries` is not on CRAN; it powers the Day 3 mapping session.
if (!requireNamespace("rgeoboundaries", quietly = TRUE)) {
  message("Installing rgeoboundaries from GitHub (not on CRAN)...")
  if (!requireNamespace("remotes", quietly = TRUE)) install.packages("remotes")
  remotes::install_github("wmgeolab/rgeoboundaries")
}

message("\nSetup complete. Versions:")
message("  R       ", getRversion())
message("  Quarto  ", tryCatch(as.character(quarto::quarto_version()),
                               error = \(e) "not found on PATH"))
