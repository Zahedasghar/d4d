# D4D — Data for Development

Workshop materials for **Data Analysis, Automation & Evidence-Based Decision-Making
with AI-Augmented R Workflows** (SDPI × D4D, 31 August – 4 September 2026).

Everything lives in **[`d4d/`](d4d/)**. Open `d4d/d4d.Rproj` — that sets the project
root that `here::here()` anchors to.

```
d4d/
├── index.qmd        home page
├── agenda.qmd       the authoritative 5-day agenda
├── setup.qmd        software setup, to complete before Day 1
├── days/
│   ├── 01-foundations/                Day 1 — foundations, data acquisition, AI toolkit
│   ├── 02-indicators-visualisation/   Day 2 — indicators, WFP & PBS CPI prices, charts
│   ├── 03-modelling-spatial/          Day 3 — modelling and mapping
│   ├── 04-reporting-dashboards/       Day 4 — Quarto, parameterised reports, dashboards
│   └── 05-revision-presentations/     Day 5 — one hour of revision, then presentations
├── data/            the workshop data pack (survey, price, CPI, spatial)
├── reference/       R cheat sheets and the AI prompt library
├── outputs/         generated figures and report outputs
├── instructor/      facilitator guides, exercises, evaluation forms
├── talks/           standalone talks
└── archive/         superseded agendas and script variants
```

`_to_delete/` holds duplicates, superseded originals and regenerable rendered output
that were cleared out of this folder on 30 August 2026. Review it, then delete it.
See `d4d/REORGANISATION-REPORT.md` for what went where.
