# Workshop data pack

Everything here is resolved from R with `here::here("data/...")`.
Do not use bare relative paths — scripts live at varying depths under `days/`.

```r
survey <- haven::read_sav(here::here("data/Fertility.sav"))
```

## Contents

| File | Size |
|---|---|
| `Alifailan.csv` | 8 KB |
| `Birth.sav` | 628 KB |
| `Census.xlsx` | 3 MB |
| `Death.sav` | 112 KB |
| `Dist names.xlsx` | 13 KB |
| `District level Data.xlsx` | 93 KB |
| `Fertility.sav` | 1 MB |
| `PKIR71FL.DTA` | 89 MB |
| `Roster.sav` | 8 MB |
| `SLOG.sav` | 996 KB |
| `Sample.sav` | 16 KB |
| `car-prices.xlsx` | 13 KB |
| `defense.xlsx` | 11 KB |
| `dirty_data.xlsx` | 13 KB |
| `dist_data.xlsx` | 94 KB |
| `education_analysis.csv` | 13 KB |
| `ossc.xlsx` | 55 KB |
| `shape_file/District_Boundary.cpg` | 5 B |
| `shape_file/District_Boundary.dbf` | 63 KB |
| `shape_file/District_Boundary.prj` | 306 B |
| `shape_file/District_Boundary.sbn` | 2 KB |
| `shape_file/District_Boundary.sbx` | 228 B |
| `shape_file/District_Boundary.shp` | 2 MB |
| `shape_file/District_Boundary.shp.xml` | 20 KB |
| `shape_file/District_Boundary.shx` | 1 KB |
| `shape_file/National_Boundary.cpg` | 5 B |
| `shape_file/National_Boundary.dbf` | 308 B |
| `shape_file/National_Boundary.prj` | 306 B |
| `shape_file/National_Boundary.sbn` | 156 B |
| `shape_file/National_Boundary.sbx` | 124 B |
| `shape_file/National_Boundary.shp` | 324 KB |
| `shape_file/National_Boundary.shp.xml` | 25 KB |
| `shape_file/National_Boundary.shx` | 116 B |
| `shape_file/Provincial_Boundary.cpg` | 5 B |
| `shape_file/Provincial_Boundary.dbf` | 2 KB |
| `shape_file/Provincial_Boundary.prj` | 306 B |
| `shape_file/Provincial_Boundary.sbn` | 204 B |
| `shape_file/Provincial_Boundary.sbx` | 124 B |
| `shape_file/Provincial_Boundary.shp` | 456 KB |
| `shape_file/Provincial_Boundary.shp.xml` | 22 KB |
| `shape_file/Provincial_Boundary.shx` | 164 B |
| `shape_file/Tehsil_Boundary.cpg` | 5 B |
| `wide_data.xlsx` | 10 KB |

## Spatial data

`shape_file/` holds the Pakistan administrative boundaries (national, provincial,
district, tehsil) used on Day 3. An identical second copy previously existed at
`data/admn_shp/`; it was removed because no script referenced it and it doubled
the repository's spatial footprint.

## Referenced but missing

These paths appear in scripts but the files are not in the repository. The
scripts using them will fail at the `read_*()` call — deliberately, rather than
silently producing an empty result. Supply the file or fix the reference.

- `data/PakPMICS2018ch.RData`
- `data/caschool.dta`
- `data/demographic_indicators.xlsx`
- `data/nurses.csv`
- `data/pakistan_districts.shp`
- `data/pkir.RData`
- `data/population_data.csv`
- `data/pslm_2020.sav`
- `data/survey.csv`

## Present but unreferenced

Not currently read by any script. Kept in case they belong to sessions still
being written; safe to remove if not.

- `data/Birth.sav`
- `data/Census.xlsx`
- `data/Death.sav`
- `data/Dist names.xlsx`
- `data/District level Data.xlsx`
- `data/Roster.sav`
- `data/SLOG.sav`
- `data/Sample.sav`
- `data/ossc.xlsx`

## Size warning

`PKIR71FL.DTA` is roughly 89 MB. It is committed to Git, which makes cloning slow
and every future rewrite of history painful. Consider moving the large survey
files to Google Drive or OSF and adding a small download script, then uncommenting
the `data/*.DTA` and `data/*.sav` lines in `.gitignore`.
