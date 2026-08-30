# ------------------------------------------------------------------
# 01_fetch_series.R
# Pull every series in series_registry from SBP EasyData and merge
# into data/processed/sbp_series_master.csv.
#
# Unlike the PBS CPI pipeline (manual PDF drop), this hits a live API,
# so each run just asks for "everything since my last observation" --
# no file-naming convention needed.
# ------------------------------------------------------------------

library(tidyverse)
library(httr2)
library(here)

source(here("R", "00_config.R"))

if (identical(sbp_api_key, "")) {
  stop("SBP_EASYDATA_KEY is not set. See R/00_config.R for setup steps.")
}

# ---- load existing master (if any) --------------------------------
if (file.exists(path_master)) {
  master_existing <- read_csv(path_master, show_col_types = FALSE) |>
    mutate(observation_date = as.Date(observation_date))
} else {
  master_existing <- tibble()
}

# ---- fetch one series --------------------------------------------------
fetch_one_series <- function(label, series_id) {

  start_date <- if (nrow(master_existing) > 0) {
    prior_max <- master_existing |>
      filter(label == !!label) |>
      pull(observation_date) |>
      max(na.rm = TRUE)
    if (is.finite(prior_max)) as.character(prior_max + 1) else default_start_date
  } else {
    default_start_date
  }
  end_date <- as.character(Sys.Date())

  if (as.Date(start_date) > as.Date(end_date)) {
    message("[", label, "] already up to date, skipping.")
    return(tibble())
  }

  message("[", label, "] fetching ", start_date, " to ", end_date, " ...")

  req <- request(api_base) |>
    req_url_path_append(series_id, "data") |>
    req_url_query(
      api_key    = sbp_api_key,
      start_date = start_date,
      end_date   = end_date,
      format     = "csv"
    ) |>
    req_error(is_error = \(resp) FALSE)  # handle errors ourselves, don't throw

  resp <- req_perform(req)

  if (resp_status(resp) == 401) {
    stop(
      "[", label, "] HTTP 401 Unauthorized -- your SBP_EASYDATA_KEY is ",
      "missing/invalid. Check .Renviron."
    )
  }
  if (resp_status(resp) == 404) {
    warning(
      "[", label, "] HTTP 404 -- series ID '", series_id, "' not found. ",
      "Look it up again on easydata.sbp.org.pk (Datasets -> search -> ",
      "detail page) and fix R/00_config.R. Skipping this series for now."
    )
    return(tibble())
  }
  if (resp_status(resp) >= 400) {
    warning(
      "[", label, "] HTTP ", resp_status(resp), " -- unexpected error. ",
      "Raw response (first 300 chars): ",
      substr(resp_body_string(resp), 1, 300)
    )
    return(tibble())
  }

  raw_text <- resp_body_string(resp)
  raw <- tryCatch(
    read_csv(raw_text, show_col_types = FALSE),
    error = function(e) {
      warning("[", label, "] Could not parse response as CSV: ", conditionMessage(e))
      tibble()
    }
  )

  if (nrow(raw) == 0) {
    message("[", label, "] no new observations returned.")
    return(tibble())
  }

  # ---- AUDIT: print the raw columns we actually got back --------------
  cat("\n--- audit:", label, "( raw columns from API ) ---\n")
  print(names(raw))
  print(head(raw, 3))

  # find the date and value columns robustly rather than assuming exact
  # names, since this API's column names aren't documented anywhere
  date_col  <- names(raw)[str_detect(names(raw), regex("date", ignore_case = TRUE))][1]
  value_col <- names(raw)[str_detect(names(raw), regex("value", ignore_case = TRUE))][1]

  if (is.na(date_col) || is.na(value_col)) {
    warning(
      "[", label, "] Could not identify date/value columns automatically. ",
      "Inspect the printed column names above and adjust ",
      "01_fetch_series.R's date_col/value_col detection. Skipping."
    )
    return(tibble())
  }

  raw |>
    transmute(
      label            = label,
      series_id        = series_id,
      observation_date = as.Date(.data[[date_col]]),
      observation_value = as.numeric(.data[[value_col]])
    ) |>
    filter(!is.na(observation_date))
}

# ---- run for every configured series ------------------------------
new_rows <- pmap(
  series_registry,
  \(label, series_id) fetch_one_series(label, series_id)
) |>
  list_rbind()

if (nrow(new_rows) == 0) {
  message("\nNo new data fetched for any series. Master file unchanged.")
} else {
  cat("\n--- new rows fetched across all series ---\n")
  print(new_rows |> count(label, name = "n_new_obs"))

  master_updated <- bind_rows(master_existing, new_rows) |>
    distinct(label, observation_date, .keep_all = TRUE) |>
    arrange(label, observation_date)

  write_csv(master_updated, path_master)

  cat("\nDone. sbp_series_master.csv now has", nrow(master_updated),
      "rows across", n_distinct(master_updated$label), "series.\n")
}
