# Workshop data pack

Everything here is resolved from R with `here::here("data/...")`.
Do not use bare relative paths — scripts live at varying depths under `days/`.

```r
survey <- haven::read_sav(here::here("data/Fertility.sav"))
hies   <- haven::read_dta(here::here("data/hies/sec_1b_emp_income.dta"))
prices <- readr::read_csv(here::here("data/raw/wfp_food_prices_pak.csv"))
```

Everything that used to sit loose in the parent `D4D/` folder now lives here, so the
project root (`d4d.Rproj`) is what `here::here()` anchors to.

## Files

| File | Size |
|---|---|
| `data/Alifailan.csv` | 8 KB |
| `data/Birth.sav` | 643 KB |
| `data/Census.xlsx` | 3 MB |
| `data/CpI-Urban-Groupwise-Cumulative-Indices.pdf` | 5 MB |
| `data/Death.sav` | 115 KB |
| `data/Dist names.xlsx` | 13 KB |
| `data/District level Data.xlsx` | 95 KB |
| `data/Fertility.sav` | 1 MB |
| `data/PKIR71FL.DTA` | 93 MB |
| `data/Roster.sav` | 9 MB |
| `data/SLOG.sav` | 1 MB |
| `data/Sample.sav` | 16 KB |
| `data/car-prices.xlsx` | 14 KB |
| `data/cpi_urban_groupwise_tidy_annual.csv` | 54 KB |
| `data/cpi_urban_groupwise_tidy_monthly.csv` | 794 KB |
| `data/cpi_urban_groupwise_wide.csv` | 152 KB |
| `data/defense.xlsx` | 11 KB |
| `data/demographic_data.csv` | 9 KB |
| `data/dirty_data.xlsx` | 14 KB |
| `data/dist_data.xlsx` | 96 KB |
| `data/education_analysis.csv` | 13 KB |
| `data/groups_spliced.csv` | 222 KB |
| `data/groups_yoy.csv` | 229 KB |
| `data/home_dept.xlsx` | 11 KB |
| `data/housing_group_spliced.csv` | 154 KB |
| `data/majors.csv` | 27 KB |
| `data/mswep_rainfall_monthly_npl.csv` | 1 MB |
| `data/ossc.xlsx` | 57 KB |
| `data/pakistan_district_mpi_2015.csv` | 7 KB |
| `data/pakistan_mpi_district_2019_20.csv` | 13 KB |
| `data/pakistan_petrol_diesel_kerosene_daily_July_August_2026.csv` | 8 KB |
| `data/pbs_cpi_raw.csv` | 7 KB |
| `data/pkir.RData` | 11 MB |
| `data/pm_data.csv` | 2 MB |
| `data/pm_data.rds` | 72 KB |
| `data/pso_fuel_prices_history.csv` | 287 B |
| `data/pso_prices_wide.csv` | 70 B |
| `data/sbp_series_monthly.zip` | 8 KB |
| `data/south_asia_demographic_raw_data.csv` | 73 KB |
| `data/wide_data.xlsx` | 10 KB |

## Folders

| Folder | Files | What it is |
|---|---|---|
| `data/admn_shp/` | 25 | second boundary set |
| `data/hies/` | 23 | HIES 2024-25 microdata sections (Day 2) |
| `data/pdf/` | 1 | source PDFs for extraction (Day 1 & 2) |
| `data/raw/` | 2 | WFP downloads from HDX, as downloaded (Day 2) |
| `data/sbp_series_monthly/` | 6 | SBP monthly series |
| `data/shape_file/` | 25 | Pakistan administrative boundaries (Day 3) |

## Size warning

`PKIR71FL.DTA` is roughly 89 MB and the HIES `.dta` sections add more. They are
committed to Git, which makes cloning slow. Consider moving the large survey files to
Google Drive or OSF with a small download script, then adding `data/*.DTA` and
`data/*.sav` to `.gitignore`.

## Referenced but missing

These paths appear in scripts but the files are not in the repository. The scripts
using them fail at the `read_*()` call — deliberately, rather than silently producing
an empty result.

- `data/PakPMICS2018ch.RData`
- `data/caschool.dta`
- `data/demographic_indicators.xlsx`
- `data/nurses.csv`
- `data/population_data.csv`
- `data/pslm_2020.sav`
- `data/survey.csv`
- `D:/RepTemplates/AER/car_prices.rds` — absolute path in `car-price-regression.R`
