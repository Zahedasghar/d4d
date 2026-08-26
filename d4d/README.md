# Data for Development (d4d)

**5-Day Workshop — Demographic Analysis Using R**

School of Economics, Quaid-i-Azam University, Islamabad
Facilitator: Prof. Dr. Zahid Asghar

---

## What this repository is

A self-contained Quarto project holding every teaching artefact for the workshop:
slides, hands-on scripts, prompt libraries, reference sheets and the data pack.
`quarto render` at the root builds the whole thing into a browsable participant site.

## Structure

```
d4d/
├── _quarto.yml                  Quarto website config — single source of navigation
├── d4d.Rproj                    project anchor (here::here() resolves from this)
├── index.qmd                    landing page
├── agenda.qmd                   THE agenda (see note on superseded variants below)
├── setup.qmd                    pre-workshop install instructions for participants
│
├── days/
│   ├── 01-foundations/          R basics, Git, data import, PDHS/NHANES first look
│   ├── 02-eda-visualisation/    gt tables, ggplot2, WDI, OWID
│   ├── 03-modelling-spatial/    regression, DHS/MICS indicators, Pakistan maps
│   ├── 04-reporting-dashboards/ Quarto, parameterised reports, dashboards
│   └── 05-ai-workflows/         prompt libraries, cheat sheets, AI-assisted analysis
│       └── each day: index.qmd (session plan) · NN-*.qmd (slides) · scripts/ (live-code)
│
├── reference/                   R essentials, five verbs, dummy-variable regression
├── talks/                       standalone presentations not tied to a workshop day
├── instructor/                  facilitator-only notes, not published to the site
├── assets/                      scss · css · img · typst templates
├── data/                        workshop data pack — see data/README.md
├── tools/                       helper scripts (deployment, migration)
└── archive/                     superseded agendas and duplicate variants
```

## Working conventions

**Paths.** Every script resolves data through `here::here("data/...")`. This is what
allows scripts to live inside `days/NN-*/scripts/` rather than the repository root —
the working directory no longer matters, only the presence of `d4d.Rproj`.

```r
survey <- haven::read_sav(here::here("data/Fertility.sav"))   # works from anywhere
survey <- haven::read_sav("data/Fertility.sav")               # breaks when sourced
```

**Rendered output is not committed.** `_site/`, `*_files/` and stray `.html` are in
`.gitignore`. Rebuild with `quarto render`; publish with `quarto publish gh-pages`.

**One agenda.** `agenda.qmd` is authoritative. Four earlier variants sit in
`archive/agendas/` — they disagreed with each other on day topics, so they were
retired rather than merged silently.

## Getting started

```bash
git clone https://github.com/Zahedasghar/d4d.git
cd d4d
```

```r
source("R/setup-packages.R")   # installs everything the workshop needs
```

```bash
quarto render                  # build the site into _site/
quarto preview                 # live preview while editing
```

## Known gaps

Several scripts read data files that are not in `data/`. They are listed in
`data/README.md` under *Referenced but missing*. Nothing has been stubbed or faked —
those scripts will fail loudly until the files are added.
