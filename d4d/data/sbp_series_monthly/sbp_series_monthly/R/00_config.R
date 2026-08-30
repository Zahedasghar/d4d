# ------------------------------------------------------------------
# 00_config.R
# SBP EasyData API config + the list of series this pipeline tracks.
# ------------------------------------------------------------------

library(here)
library(tibble)

# ---- paths -----------------------------------------------------------
path_processed <- here("data", "processed")
path_master    <- here(path_processed, "sbp_series_master.csv")

# ---- API key -----------------------------------------------------------
# 1. Register free at https://easydata.sbp.org.pk (top-right "Login" ->
#    sign up), then find your API key under your account/profile.
# 2. Put it in a file called .Renviron in this project's root folder
#    (create it if it doesn't exist), as one line:
#       SBP_EASYDATA_KEY=your40characterkeyhere
# 3. Restart R / run `readRenviron(".Renviron")` so it's picked up.
# NEVER hardcode the key here or commit .Renviron to git — add
# ".Renviron" to .gitignore.
sbp_api_key <- Sys.getenv("SBP_EASYDATA_KEY")

if (identical(sbp_api_key, "")) {
  warning(
    "SBP_EASYDATA_KEY is not set. Add it to .Renviron as described in ",
    "R/00_config.R before running 01_fetch_series.R."
  )
}

api_base <- "https://easydata.sbp.org.pk/api/v1/series"

# ---- series registry ---------------------------------------------------
# Add or replace rows here for whatever monthly series you want tracked.
#
# HOW TO FIND A SERIES ID: go to https://easydata.sbp.org.pk -> Datasets,
# search for the indicator, open it, and the series ID is shown on its
# detail/chart page -- it looks like "TS_GP_XX_YYYYY_M.zzzzz".
#
# IMPORTANT: the two series IDs below are taken from EasyDataPy's own
# published usage examples, NOT verified live by this pipeline (I don't
# have an API key to test against). The very first run's audit output
# will tell you immediately if either ID is wrong -- see 01_fetch_series.R.
series_registry <- tribble(
  ~label,                       ~series_id,
  "lsm_general_index",          "TS_GP_RL_LSM1516_M.LSM000160000",
  "real_effective_exchange_rate", "TS_GP_ER_REERNEER_M.R00010"
)

# Earliest date to backfill from if a series has never been fetched before.
default_start_date <- "2015-01-01"
