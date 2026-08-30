# SBP EasyData — Monthly Series Report

Pulls one or more monthly time series directly from the SBP EasyData API
and renders a full HTML report. No manual file downloads — it's a live
API call.

## One-time setup

1. Register a free account at <https://easydata.sbp.org.pk> and find your
   API key (under your account/profile once logged in).
2. Copy `.Renviron.example` to `.Renviron` in this project's root and
   paste your key in:
   ```
   SBP_EASYDATA_KEY=your40characterkeyhere
   ```
3. Add `.Renviron` to `.gitignore` (never commit it).
4. Install packages:
   ```r
   install.packages(c("tidyverse", "httr2", "here", "gt", "quarto"))
   ```
5. **Verify the default series IDs.** `R/00_config.R` ships with two
   example series (LSM general index, real effective exchange rate)
   taken from third-party documentation, not verified live against a key.
   Browse *Datasets* on easydata.sbp.org.pk, find the indicators you
   actually want, and copy their exact series ID (format
   `TS_GP_XX_YYYYY_M.zzzzz`) from each dataset's detail page into
   `series_registry` in `R/00_config.R`.

## Each month, do this

```r
Rscript run_monthly_update.R
```

That's it — it fetches only the observations newer than what's already
saved (or backfills from scratch for a series you just added), then
re-renders `report.qmd` → `report.html` with trend charts and a
latest-value snapshot table for every series you've configured.

## If a series fails to fetch

- **HTTP 401**: your API key is missing or wrong — check `.Renviron`.
- **HTTP 404**: the series ID is wrong — look it up again on the portal.
- Either way, the script prints exactly which series failed and keeps
  going with the others; nothing is silently dropped.

## Adding more series

Add a row to `series_registry` in `R/00_config.R`:

```r
series_registry <- tribble(
  ~label,              ~series_id,
  "your_label_here",   "TS_GP_....",
  ...
)
```

Re-run `Rscript run_monthly_update.R` — it will backfill the new series
from `default_start_date` automatically.
