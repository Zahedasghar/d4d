# Reorganisation report

What changed when `Zahedasghar/d4d` became a Quarto project, and why.

---

## The problems this fixes

**1. Two incompatible workshops in one repository.** `README.md` described a five-day
workshop on *Demographic Analysis Using R* (import → EDA → modelling → reporting → AI).
`5day_data_prompt_workshop.qmd` described a five-day workshop on *Data Analysis Using
AI Prompts* with a completely different day breakdown. Two more agenda variants sat in
`docs/`. Four documents, four schedules, no way to tell which was current.

*Fix:* `agenda.qmd` is now authoritative and reconciles them — the AI prompting material
becomes Day 5 of the demographic workshop rather than a competing curriculum. The four
old variants are in `archive/agendas/` rather than deleted.

**2. `docs/` was doing two incompatible jobs.** It held both source `.qmd` files and
rendered `.html`/`.pdf` output. `docs/` is also Quarto's conventional publish target,
so the folder could never be used for its normal purpose.

*Fix:* sources redistributed to `days/`, `reference/` and `archive/`; `docs/` removed.
Build output goes to `_site/`, which is gitignored.

**3. Thirty files at the repository root.** Nineteen loose `.R` scripts with no
indication of which day they belonged to, sitting next to three SCSS files, a
PowerShell script, a PNG and four rendered HTML files.

*Fix:* every script now sits under the day that teaches it.

**4. Rendered output was committed.** Seven `*_files/` directories held roughly
30 MB of vendored JavaScript, CSS and web fonts — Reveal.js, Bootstrap and MathJax,
committed as if they were source.

*Fix:* removed and gitignored. `quarto render` regenerates all of it.

**5. Duplicated content.** `WDI.R`, `gt_summary.R`, `gt_tables.R` and `owid_tutorial.R`
existed byte-identically at the root and in `Day2/`. `custom-theme.scss` existed in four
places. The complete Pakistan shapefile set existed twice, as `data/admn_shp/` and
`data/shape_file/` — and no script referenced the first.

*Fix:* one copy of each, in one place.

**6. No project definition.** No `_quarto.yml`, so there was no way to render the
material as a set, no navigation, and no participant-facing site.

*Fix:* `_quarto.yml` defines a website with per-day navigation.

---

## New structure

```
d4d/
├── _quarto.yml · index.qmd · agenda.qmd · setup.qmd · README.md
├── R/setup-packages.R
├── days/01-foundations … 05-ai-workflows/   index.qmd · NN-*.qmd · scripts/
├── reference/ · talks/ · instructor/
├── assets/{scss,css,img,typst}
├── data/          (+ README.md manifest)
├── tools/         (migrate-d4d.sh, push-to-github.ps1)
└── archive/{agendas,variants}
```

---

## New files created

| File | Purpose |
|---|---|
| `_quarto.yml` | website project: render list, navbar, sidebar, shared HTML format |
| `index.qmd` | landing page |
| `agenda.qmd` | the single reconciled agenda |
| `setup.qmd` | participant pre-workshop instructions with a verification block |
| `days/*/index.qmd` | five session plans, one per day |
| `R/setup-packages.R` | grouped package installer that errors loudly on failure |
| `assets/scss/website.scss` | site theme, kept separate from the revealjs slide theme |
| `data/README.md` | data manifest + missing/unused audit |
| `.gitignore` | rewritten to exclude `_site/`, `*_files/`, `.quarto/`, stray HTML |
| `.gitattributes` | line-ending normalisation (the repo currently mixes CRLF and LF) |
| `tools/migrate-d4d.sh` | applies this reorganisation to the live repo via `git mv` |

---

## File moves

### `days/01-foundations/`

| From | To |
|---|---|
| `day1_session1/rstudio-git-session.qmd` | `days/01-foundations/01-rstudio-git-session.qmd` |
| `day1_session2/demographic-analysis-nhanes.qmd` | `days/01-foundations/02-demographic-analysis-nhanes.qmd` |
| `day1_session2/demographic-analysis-workbook.qmd` | `days/01-foundations/03-demographic-analysis-workbook.qmd` |
| `dirty_excel.R` | `days/01-foundations/scripts/clean-dirty-excel.R` |
| `day1_session2/create_practice_data.R` | `days/01-foundations/scripts/create-practice-data.R` |
| `day1_session2/session2_data_packages_fundamental.R` | `days/01-foundations/scripts/data-packages-fundamentals.R` |
| `alif-b.R` | `days/01-foundations/scripts/import-alifailan.R` |
| `wide_long_data.R` | `days/01-foundations/scripts/wide-to-long.R` |

### `days/02-eda-visualisation/`

| From | To |
|---|---|
| `Day2/10_highly_useful_commands.R` | `days/02-eda-visualisation/scripts/10-useful-commands.R` |
| `Day2/Birthweight_pregnancy_data.R` | `days/02-eda-visualisation/scripts/birthweight-pregnancy.R` |
| `gt_bar_defense.R` | `days/02-eda-visualisation/scripts/gt-bar-defence.R` |
| `Day2/gt_summary.R` | `days/02-eda-visualisation/scripts/gt-summary-tables.R` |
| `Day2/gt_tables.R` | `days/02-eda-visualisation/scripts/gt-tables-basics.R` |
| `nhanes1.r` | `days/02-eda-visualisation/scripts/nhanes-ggplot-advanced.R` |
| `nhanes.r` | `days/02-eda-visualisation/scripts/nhanes-ggplot-basics.R` |
| `Day2/owid_tutorial.R` | `days/02-eda-visualisation/scripts/owid-tutorial.R` |
| `Day2/WDI.R` | `days/02-eda-visualisation/scripts/wdi-indicators.R` |

### `days/03-modelling-spatial/`

| From | To |
|---|---|
| `docs/DHS_Workshop_Tutorial.qmd` | `days/03-modelling-spatial/01-dhs-model-datasets.qmd` |
| `car-price.R` | `days/03-modelling-spatial/scripts/car-price-regression.R` |
| `demographic_svy.r` | `days/03-modelling-spatial/scripts/fertility-analysis.R` |
| `Linear-regression.R` | `days/03-modelling-spatial/scripts/linear-regression.R` |
| `Day3/mics_child.R` | `days/03-modelling-spatial/scripts/mics-child.R` |
| `pakistan-chore.R` | `days/03-modelling-spatial/scripts/pakistan-district-choropleth.R` |
| `pak-map.R` | `days/03-modelling-spatial/scripts/pakistan-maps-geoboundaries.R` |
| `Day3/PDHS.R` | `days/03-modelling-spatial/scripts/pdhs-indicators.R` |
| `demo_survey.R` | `days/03-modelling-spatial/scripts/survey-health-indicators.R` |

### `days/04-reporting-dashboards/`

| From | To |
|---|---|
| `Day4/quarto_learning.qmd` | `days/04-reporting-dashboards/01-quarto-basics.qmd` |
| `Day4/parameterised.qmd` | `days/04-reporting-dashboards/02-parameterised-reports.qmd` |
| `Day4/ODI.qmd` | `days/04-reporting-dashboards/03-odi-report.qmd` |
| `Day4/R-user-group.qmd` | `days/04-reporting-dashboards/04-r-user-group.qmd` |
| `penguin_dashboard.Rmd` | `days/04-reporting-dashboards/dashboards/penguin-dashboard.Rmd` |
| `gif.R` | `days/04-reporting-dashboards/scripts/animated-gif.R` |
| `Day4/parameterised.R` | `days/04-reporting-dashboards/scripts/render-parameterised.R` |

### `days/05-ai-workflows/`

| From | To |
|---|---|
| `5day_data_prompt_workshop.qmd` | `days/05-ai-workflows/01-data-prompt-manual.qmd` |
| `docs/ai-prompts-library.qmd` | `days/05-ai-workflows/02-ai-prompts-library.qmd` |
| `docs/ai-prompts-library_comprehensive.qmd` | `days/05-ai-workflows/03-ai-prompts-library-full.qmd` |
| `docs/Master_Data_Prompt_Pack.qmd` | `days/05-ai-workflows/04-master-data-prompt-pack.qmd` |
| `AI_Prompt_CheatSheet_Poster.qmd` | `days/05-ai-workflows/05-prompt-cheatsheet-poster.qmd` |

### `reference/`

| From | To |
|---|---|
| `docs/dummy_reg.qmd` | `reference/dummy-variable-regression.qmd` |
| `docs/learnR.qmd` | `reference/five-verbs-data-wrangling.qmd` |
| `docs/R-essentials.qmd` | `reference/r-essentials.qmd` |
| `docs/teachR.R` | `reference/scripts/teach-r.R` |

### `talks/`

| From | To |
|---|---|
| `demystifying_202511.qmd` | `talks/2025-11-survey-to-insights.qmd` |

### `instructor/`

| From | To |
|---|---|
| `day1_session1/CHANGES-SUMMARY.md` | `instructor/day1-changes-summary.md` |
| `day1_session2/INSTRUCTOR-GUIDE.md` | `instructor/instructor-guide.md` |
| `day1_session2/PACKAGE-SUMMARY.md` | `instructor/package-summary.md` |
| `day1_session2/WORKSHOP-README.md` | `instructor/session2-readme.md` |

### `assets/`

| From | To |
|---|---|
| `day1_session1/quarto-styles.css` | `assets/css/quarto-styles.css` |
| `docs/imgs/` | `assets/img/` |
| `custom-theme.scss` | `assets/scss/custom-theme.scss` |
| `custom.scss` | `assets/scss/custom.scss` |
| `custom2.scss` | `assets/scss/custom2.scss` |
| `docs/styles.scss` | `assets/scss/styles.scss` |
| `docs/typst-show.typ` | `assets/typst/typst-show.typ` |
| `docs/typst-template.typ` | `assets/typst/typst-template.typ` |

### `data/`

| From | To |
|---|---|
| `home_dept.xlsx` | `data/home_dept.xlsx` |
| `majors.csv` | `data/majors.csv` |

### `tools/`

| From | To |
|---|---|
| `push_to_github.ps1` | `tools/push-to-github.ps1` |

### `archive/`

| From | To |
|---|---|
| `docs/workshop_agenda.qmd` | `archive/agendas/pre-workshop-agenda.qmd` |
| `docs/Workshop_Agenda_R_Training.docx` | `archive/agendas/workshop-agenda-r-training.docx` |
| `docs/Workshop_Agenda_R_Training.pdf` | `archive/agendas/workshop-agenda-r-training.pdf` |
| `docs/Workshop_Agenda_R_Training.qmd` | `archive/agendas/workshop-agenda-r-training.qmd` |
| `docs/workshop-demographic-analysis-agenda.pdf` | `archive/agendas/workshop-demographic-analysis-agenda.pdf` |
| `docs/workshop-demographic-analysis.qmd` | `archive/agendas/workshop-demographic-analysis.qmd` |
| `docs/demo_survey.R` | `archive/variants/demo_survey--docs-version.R` |
| `docs/rstudio-git-session.qmd` | `archive/variants/rstudio-git-session--docs-version.qmd` |

---

## Removals

| Removed | Reason |
|---|---|
| `conversation-export.md`, `data_import_exprt.R`, `day1_session2/session2_data_packages.R` | zero bytes |
| `WDI.R`, `gt_summary.R`, `gt_tables.R`, `owid_tutorial.R` (root) | byte-identical to the `Day2/` copies |
| `custom-theme.scss` ×3, `docs/custom.scss`, `docs/custom2.scss`, `docs/my.scss`, `docs/quarto-styles.css` | byte-identical duplicates; one copy now in `assets/` |
| `data/admn_shp/` | byte-identical to `data/shape_file/`, which is the one scripts reference |
| 7 × `*_files/` directories, 9 × `.html`, 1 × `.pdf`, `diabetes_plot.png` | rendered output — `quarto render` regenerates it |
| `docs/~WRL0003.tmp` | Word autosave artefact |

Nothing was removed that was not either empty, byte-identical to a retained file, or
reproducible by rendering.

---

## Path rewrites

Moving scripts off the root broke every relative `"data/..."` path. All of them now
resolve through `here::here()`, which anchors to `d4d.Rproj` and therefore works
regardless of where the script sits or what the working directory is.


31 literal path(s) rewritten across 16 file(s).

All relative data paths now resolve through `here::here()`, which anchors to the
project root via `d4d.Rproj`. This is what makes it safe for scripts to live in
`days/NN-*/scripts/` instead of the repository root.


## `archive/variants/rstudio-git-session--docs-version.qmd`

- `"data/survey.csv"` → `here::here("data/survey.csv")`
- `"data/survey.csv"` → `here::here("data/survey.csv")`

## `days/01-foundations/01-rstudio-git-session.qmd`

- `"data/survey.csv"` → `here::here("data/survey.csv")`
- `"data/survey.csv"` → `here::here("data/survey.csv")`

## `days/01-foundations/scripts/clean-dirty-excel.R`

- `"data/nurses.csv"` → `here::here("data/nurses.csv")`
- `"data/dirty_data.xlsx"` → `here::here("data/dirty_data.xlsx")`
- `"data/dirty_data.xlsx"` → `here::here("data/dirty_data.xlsx")`

## `days/01-foundations/scripts/data-packages-fundamentals.R`

- `"data/defense.xlsx"` → `here::here("data/defense.xlsx")`
- `"data/education_analysis.csv"` → `here::here("data/education_analysis.csv")`
- `"data/pakistan_districts.shp"` → `here::here("data/pakistan_districts.shp")`

## `days/01-foundations/scripts/import-alifailan.R`

- `"data/Alifailan.csv"` → `here::here("data/Alifailan.csv")`

## `days/01-foundations/scripts/wide-to-long.R`

- `"data/wide_data.xlsx"` → `here::here("data/wide_data.xlsx")`
- `read_excel("wide_data.xlsx"` → `read_excel(here::here("data/wide_data.xlsx")`

## `days/02-eda-visualisation/scripts/gt-bar-defence.R`

- `"data/defense.xlsx"` → `here::here("data/defense.xlsx")`

## `days/03-modelling-spatial/01-dhs-model-datasets.qmd`

- `"data/pkir.RData"` → `here::here("data/pkir.RData")`
- `"data/pkir.RData"` → `here::here("data/pkir.RData")`

## `days/03-modelling-spatial/scripts/car-price-regression.R`

- `"data/car-prices.xlsx"` → `here::here("data/car-prices.xlsx")`

## `days/03-modelling-spatial/scripts/fertility-analysis.R`

- `read_sav("Fertility.sav"` → `read_sav(here::here("data/Fertility.sav")`

## `days/03-modelling-spatial/scripts/linear-regression.R`

- `read_dta("caschool.dta"` → `read_dta(here::here("data/caschool.dta")`

## `days/03-modelling-spatial/scripts/mics-child.R`

- `"data/PakPMICS2018ch.RData"` → `here::here("data/PakPMICS2018ch.RData")`

## `days/03-modelling-spatial/scripts/pakistan-district-choropleth.R`

- `"data/shape_file/District_Boundary.shp"` → `here::here("data/shape_file/District_Boundary.shp")`
- `"data/dist_data.xlsx"` → `here::here("data/dist_data.xlsx")`

## `days/03-modelling-spatial/scripts/survey-health-indicators.R`

- `"data/Fertility.sav"` → `here::here("data/Fertility.sav")`

## `days/05-ai-workflows/02-ai-prompts-library.qmd`

- `"data/population_data.csv"` → `here::here("data/population_data.csv")`
- `"data/demographic_indicators.xlsx"` → `here::here("data/demographic_indicators.xlsx")`
- `"data/PKIR71FL.DTA"` → `here::here("data/PKIR71FL.DTA")`
- `"data/pslm_2020.sav"` → `here::here("data/pslm_2020.sav")`

## `days/05-ai-workflows/03-ai-prompts-library-full.qmd`

- `"data/population_data.csv"` → `here::here("data/population_data.csv")`
- `"data/demographic_indicators.xlsx"` → `here::here("data/demographic_indicators.xlsx")`
- `"data/PKIR71FL.DTA"` → `here::here("data/PKIR71FL.DTA")`
- `"data/pslm_2020.sav"` → `here::here("data/pslm_2020.sav")`

### Asset references

Nine YAML references to theme and template files were repointed:

| File | Change |
|---|---|
| `days/01-foundations/01-rstudio-git-session.qmd` | `custom-theme.scss` → `../../assets/scss/custom-theme.scss` |
| `days/01-foundations/02-demographic-analysis-nhanes.qmd` | same |
| `talks/2025-11-survey-to-insights.qmd` | `custom-theme.scss` → `../assets/scss/custom-theme.scss` |
| `days/05-ai-workflows/02-ai-prompts-library.qmd` | typst template + show file → `../../assets/typst/` |
| `days/05-ai-workflows/03-ai-prompts-library-full.qmd` | same |
| `reference/five-verbs-data-wrangling.qmd` | `styles.scss` → `../assets/scss/styles.scss`; **`custom.css` dropped** |
| `reference/dummy-variable-regression.qmd` | same |

`custom.css` was referenced by two files but does not exist anywhere in the repository —
those documents could never have rendered. It was removed from the theme lists rather
than stubbed, because a stub would hide a real break.

---

## Still needs your attention

**1. Ten data files are referenced but absent.** Listed in `data/README.md`. The
scripts that read them will fail at the `read_*()` call. Nothing was stubbed.

**2. `data/PKIR71FL.DTA` is 89 MB and committed to Git.** Every clone pays for it and
it makes any future history rewrite painful. Consider hosting the large survey files
externally with a download script, then uncommenting the `data/*.DTA` and `data/*.sav`
lines in `.gitignore`.

**3. Two script pairs are near-duplicates, not exact ones, so both were kept.**
`demo_survey.R` differs between root and `docs/` by 602 diff lines;
`rstudio-git-session.qmd` differs between `day1_session1/` and `docs/` by 42.
The root/`day1_session1` versions are live; the `docs/` versions are in
`archive/variants/`. Decide which is canonical and delete the other.

**4. `nhanes.r` / `nhanes1.r` and `demo_survey.R` / `demographic_svy.r` look like
iterations of the same material.** They were renamed descriptively
(`nhanes-ggplot-basics.R` / `nhanes-ggplot-advanced.R`,
`survey-health-indicators.R` / `fertility-analysis.R`) on a reading of their headers,
but the day assignments are a guess. Check they land where you teach them.

**5. Line endings are mixed.** Some files are CRLF, some LF, a few mix both.
`.gitattributes` normalises this going forward, but a one-time `git add --renormalize .`
will show a large diff the first time.

**6. `renv` is not set up.** `.gitignore` anticipates it. If participants are to get
identical package versions, `renv::init()` before the workshop is worth the ten minutes.
