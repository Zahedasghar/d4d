# Reorganisation report — 30 August 2026

The parent `D4D/` folder held about sixty loose files alongside this already-organised
site. They have been folded in, duplicates cleared out, and the day structure aligned
with the SDPI agenda of 24 August 2026 (31 Aug – 4 Sep, Day 5 closing at 13:00).

## Day structure

| Folder | `.qmd` | `.R` |
|---|---|---|
| `days/01-foundations/` | 8 | 8 |
| `days/02-indicators-visualisation/` | 5 | 25 |
| `days/03-modelling-spatial/` | 2 | 12 |
| `days/04-reporting-dashboards/` | 11 | 2 |
| `days/05-revision-presentations/` | 3 | 0 |

`days/05-ai-workflows/` no longer exists. AI assistance is not a separate day in the
SDPI agenda — it runs through Days 1–4 — so its prompt libraries moved to
`reference/ai-prompts/`, and Day 5 is now revision (one hour), group presentations and
closing.

## Where the new material went

**Day 1 — R fundamentals and acquisition**

- `R-fundamentals.qmd` → `days/01-foundations/01-r-fundamentals.qmd` (+ `d4d_theme.scss`)
- `R-fundamentals.R` → `days/01-foundations/scripts/r-fundamentals.R`
- `data_import_export.qmd` → `days/01-foundations/03-data-import-export.qmd`
- `pakistan-floods-dplyr-1-2-0.qmd` → `days/01-foundations/04-dplyr-wrangling-floods.qmd`
- `alifailan_part2.R`, `session2_data_packages.R` → `days/01-foundations/scripts/`
- the two workshop PDFs → `days/01-foundations/handouts/`
- existing Day 1 files renumbered 00–06 so the new material sits in teaching order

**Day 2 — WFP prices and PBS CPI** (folder renamed `02-eda-visualisation` → `02-indicators-visualisation`)

- `wfp-pipeline-tutorial.qmd` → `01-wfp-prices-pipeline.qmd` (+ `d4d-navy-gold.scss`)
- `pak-food-prices-tutorial.qmd` → `02-pak-food-prices-workflow.qmd`
- `combining-prices-markets.qmd` → `03-combining-prices-markets.qmd`
- `index_number/index_numbers_session.qmd` → `04-index-numbers.qmd` (+ `d4d-theme.scss`)
- `tidy_pbs_cpi.R`, `extract_cpi_urban_groupwise.R`, `general_groups_inflation_analysis.R`,
  `housing_cpi_analysis.R`, `wfp_food_prices_pakistan.R`,
  `wfp_food_prices_pakistan_commands.R`, `read_hdx.R`, `prices_data.R`, `income_2024.R`,
  `gapminder.R`, `pm25_ggplot2.R`, `wdiexplorer*.R`, `temprature.R` → `scripts/`, renamed
  to kebab-case
- `animated-gif.R` moved here from Day 4 — `gganimate` is a Day 2 session in the SDPI agenda

**Day 3 — modelling and spatial**

- `Day3/pdhs0.R`, `Day3/pdhs01.R`, `Day3/wdi_demographic_sa.R`, `demographic_svy.r` → `scripts/`

**Day 4 — reporting**

- `Day4/quarto_document_writing_tutorial.qmd`, `project_outline.qmd`,
  `demographic_survey_outline.qmd`, `references.bib` → `days/04-reporting-dashboards/`
- `trade_report/` → `days/04-reporting-dashboards/trade-report/` (nested `.git` removed)
- `intro-to-quarto/` → `days/04-reporting-dashboards/intro-to-quarto/`
- `Aawaam Stats App _standalone_.html` → `dashboards/aawaam-stats-app.html`
- `demystifying_202511.qmd` → `talks/2025-11-demystifying-data.qmd`
- existing Day 4 files renumbered 01–07

**Day 5 — new**

- `days/05-revision-presentations/index.qmd`, `01-week-in-review.qmd` (the one-hour
  revision deck), `02-group-presentation-brief.qmd`

**Data, outputs, instructor material**

- the whole of `D4D/data/` plus `hies/`, the CPI and price CSVs, `pm_data.*`,
  `sbp_series_monthly/` and `cpi_urban_groupwise.pdf` → `d4d/data/`
- animation GIFs, `pbs_outputs/`, `outputs/` → `d4d/outputs/`
- facilitator guides, exercises workbook, pre-training evaluation, flyer and outline →
  `d4d/instructor/` and `d4d/instructor/promo/`
- old agendas → `d4d/archive/agendas/`

## Path fixes applied

Scripts that read data with bare relative paths were rewritten to
`here::here("data/...")` so they run from anywhere in the project:
`r-fundamentals.R`, `import-alifailan-part2.R`, `cpi-groups-inflation.R`,
`cpi-housing-group.R`, `tidy-pbs-cpi.R`, `hies-income-2024.R`, `pm25-ggplot2.R`,
`wdi-explorer-1.R`, `wdi-explorer-comprehensive.R`, `extract-cpi-urban-groupwise.R`,
`wdi-demographic-south-asia.R`, `survey-demographics.R`, `survey-health-indicators.R`.

One absolute path remains and needs your attention:
`days/03-modelling-spatial/scripts/car-price-regression.R` reads
`D:/RepTemplates/AER/car_prices.rds`.

## What was quarantined, not deleted

`../_to_delete/` holds four folders. Nothing was deleted — review and remove it yourself.

| Folder | What is in it |
|---|---|
| `exact-duplicates/` | 37 files byte-identical to a copy already inside `d4d/` |
| `superseded-by-d4d/` | 20 original scripts whose cleaned-up version is already in `d4d/` |
| `rendered-output/` | 39 `.html` files and `*_files` folders regenerable with `quarto render` |
| `empty-or-scratch/` | zero-byte files, probe folders, Word lock files, the emptied `Day2`–`Day4` folders |
| `empty-dirs/` | the emptied `data/`, `Day2/`–`Day4/`, `day1_session*/`, `index_number/` folders |
| `nested-vcs/` | the `.git` and `.Rproj.user` that came inside `intro-to-quarto/` |

## Still to check

- `Exercises_D4D_workshop.docx` was open in Word during the move, so it was **copied**
  to `d4d/instructor/exercises-workbook.docx` and the original is still in the parent
  folder. Close Word and delete the original.
- `days/01-foundations/scripts/` has both `data-packages.R` and
  `data-packages-fundamentals.R` — near-duplicates worth merging.
- `scripts/wdi-explorer.R`, `wdi-explorer-1.R` and `wdi-explorer-comprehensive.R` are
  three passes at the same thing; keep one.
