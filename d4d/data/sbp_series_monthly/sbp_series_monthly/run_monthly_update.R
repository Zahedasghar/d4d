# ------------------------------------------------------------------
# run_monthly_update.R
#
# THE ONE COMMAND TO RUN EACH MONTH:
#   Rscript run_monthly_update.R
#
# No file to drop in -- this pulls fresh data directly from the
# SBP EasyData API (requires SBP_EASYDATA_KEY in .Renviron; see
# R/00_config.R).
# ------------------------------------------------------------------

here::i_am("run_monthly_update.R")

message(">> Step 1/2: fetching new observations from SBP EasyData")
source(here::here("R", "01_fetch_series.R"))

message(">> Step 2/2: rendering report.qmd")
quarto::quarto_render(here::here("report.qmd"))

message(">> Done. Open report.html")
