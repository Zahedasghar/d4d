#!/usr/bin/env bash
# =============================================================================
# migrate-d4d.sh — reorganise the d4d repository in place
#
#   Applies the same rearrangement as the supplied d4d-reorganised.zip, but with
#   `git mv`, so every file keeps its commit history and `git log --follow` still
#   works after the move.
#
# Usage
#   bash migrate-d4d.sh --dry-run     # print every action, change nothing
#   bash migrate-d4d.sh               # apply
#
# Safety
#   * Refuses to run unless the working tree is clean, so you can always
#     `git reset --hard` back.
#   * Every move is guarded: a missing source is reported, not silently skipped.
#   * Scaffold files (_quarto.yml, index.qmd, day index pages, ...) are NOT
#     created here — copy them from the zip. This script only moves and removes.
#
# After running:
#   1. copy the scaffold files from d4d-reorganised.zip over the repo
#   2. quarto render
#   3. git add -A && git commit -m "Reorganise into Quarto project structure"
# =============================================================================
set -euo pipefail

DRY=0
[[ "${1:-}" == "--dry-run" ]] && DRY=1

if [[ ! -d .git ]]; then
  echo "ERROR: run this from the root of the d4d repository." >&2
  exit 1
fi

if [[ $DRY -eq 0 && -n "$(git status --porcelain)" ]]; then
  echo "ERROR: working tree is not clean. Commit or stash first — this script" >&2
  echo "       moves ~70 files and you want a clean point to reset to." >&2
  exit 1
fi

moved=0; skipped=0; removed=0

run() {
  if [[ $DRY -eq 1 ]]; then echo "  DRY: $*"; else eval "$@"; fi
}

mv_file() {  # mv_file <src> <dst>
  local src="$1" dst="$2"
  if [[ ! -e "$src" ]]; then
    echo "  SKIP (no such source): $src"
    skipped=$((skipped+1))
    return
  fi
  run "mkdir -p \"$(dirname "$dst")\""
  run "git mv -f \"$src\" \"$dst\""
  echo "  mv   $src -> $dst"
  moved=$((moved+1))
}

rm_path() {  # rm_path <path>
  local p="$1"
  if [[ ! -e "$p" ]]; then return; fi
  run "git rm -r -q --ignore-unmatch \"$p\""
  echo "  rm   $p"
  removed=$((removed+1))
}

echo "=== d4d reorganisation ==="
[[ $DRY -eq 1 ]] && echo "(dry run — nothing will be changed)"
echo
echo "--- moving files ---"

echo "  [days/01-foundations]"
mv_file "day1_session1/rstudio-git-session.qmd" "days/01-foundations/01-rstudio-git-session.qmd"
mv_file "day1_session2/demographic-analysis-nhanes.qmd" "days/01-foundations/02-demographic-analysis-nhanes.qmd"
mv_file "day1_session2/demographic-analysis-workbook.qmd" "days/01-foundations/03-demographic-analysis-workbook.qmd"
mv_file "day1_session2/create_practice_data.R" "days/01-foundations/scripts/create-practice-data.R"
mv_file "day1_session2/session2_data_packages_fundamental.R" "days/01-foundations/scripts/data-packages-fundamentals.R"
mv_file "alif-b.R" "days/01-foundations/scripts/import-alifailan.R"
mv_file "dirty_excel.R" "days/01-foundations/scripts/clean-dirty-excel.R"
mv_file "wide_long_data.R" "days/01-foundations/scripts/wide-to-long.R"

echo "  [days/02-eda-visualisation]"
mv_file "Day2/10_highly_useful_commands.R" "days/02-eda-visualisation/scripts/10-useful-commands.R"
mv_file "Day2/Birthweight_pregnancy_data.R" "days/02-eda-visualisation/scripts/birthweight-pregnancy.R"
mv_file "Day2/WDI.R" "days/02-eda-visualisation/scripts/wdi-indicators.R"
mv_file "Day2/gt_summary.R" "days/02-eda-visualisation/scripts/gt-summary-tables.R"
mv_file "Day2/gt_tables.R" "days/02-eda-visualisation/scripts/gt-tables-basics.R"
mv_file "Day2/owid_tutorial.R" "days/02-eda-visualisation/scripts/owid-tutorial.R"
mv_file "gt_bar_defense.R" "days/02-eda-visualisation/scripts/gt-bar-defence.R"
mv_file "nhanes.r" "days/02-eda-visualisation/scripts/nhanes-ggplot-basics.R"
mv_file "nhanes1.r" "days/02-eda-visualisation/scripts/nhanes-ggplot-advanced.R"

echo "  [days/03-modelling-spatial]"
mv_file "Day3/PDHS.R" "days/03-modelling-spatial/scripts/pdhs-indicators.R"
mv_file "Day3/mics_child.R" "days/03-modelling-spatial/scripts/mics-child.R"
mv_file "Linear-regression.R" "days/03-modelling-spatial/scripts/linear-regression.R"
mv_file "car-price.R" "days/03-modelling-spatial/scripts/car-price-regression.R"
mv_file "demo_survey.R" "days/03-modelling-spatial/scripts/survey-health-indicators.R"
mv_file "demographic_svy.r" "days/03-modelling-spatial/scripts/fertility-analysis.R"
mv_file "pak-map.R" "days/03-modelling-spatial/scripts/pakistan-maps-geoboundaries.R"
mv_file "pakistan-chore.R" "days/03-modelling-spatial/scripts/pakistan-district-choropleth.R"
mv_file "docs/DHS_Workshop_Tutorial.qmd" "days/03-modelling-spatial/01-dhs-model-datasets.qmd"

echo "  [days/04-reporting-dashboards]"
mv_file "Day4/quarto_learning.qmd" "days/04-reporting-dashboards/01-quarto-basics.qmd"
mv_file "Day4/parameterised.qmd" "days/04-reporting-dashboards/02-parameterised-reports.qmd"
mv_file "Day4/parameterised.R" "days/04-reporting-dashboards/scripts/render-parameterised.R"
mv_file "Day4/ODI.qmd" "days/04-reporting-dashboards/03-odi-report.qmd"
mv_file "Day4/R-user-group.qmd" "days/04-reporting-dashboards/04-r-user-group.qmd"
mv_file "penguin_dashboard.Rmd" "days/04-reporting-dashboards/dashboards/penguin-dashboard.Rmd"
mv_file "gif.R" "days/04-reporting-dashboards/scripts/animated-gif.R"

echo "  [days/05-ai-workflows]"
mv_file "5day_data_prompt_workshop.qmd" "days/05-ai-workflows/01-data-prompt-manual.qmd"
mv_file "docs/ai-prompts-library.qmd" "days/05-ai-workflows/02-ai-prompts-library.qmd"
mv_file "docs/ai-prompts-library_comprehensive.qmd" "days/05-ai-workflows/03-ai-prompts-library-full.qmd"
mv_file "docs/Master_Data_Prompt_Pack.qmd" "days/05-ai-workflows/04-master-data-prompt-pack.qmd"
mv_file "AI_Prompt_CheatSheet_Poster.qmd" "days/05-ai-workflows/05-prompt-cheatsheet-poster.qmd"

echo "  [reference]"
mv_file "docs/R-essentials.qmd" "reference/r-essentials.qmd"
mv_file "docs/learnR.qmd" "reference/five-verbs-data-wrangling.qmd"
mv_file "docs/dummy_reg.qmd" "reference/dummy-variable-regression.qmd"
mv_file "docs/teachR.R" "reference/scripts/teach-r.R"

echo "  [talks]"
mv_file "demystifying_202511.qmd" "talks/2025-11-survey-to-insights.qmd"

echo "  [instructor]"
mv_file "day1_session2/INSTRUCTOR-GUIDE.md" "instructor/instructor-guide.md"
mv_file "day1_session2/PACKAGE-SUMMARY.md" "instructor/package-summary.md"
mv_file "day1_session2/WORKSHOP-README.md" "instructor/session2-readme.md"
mv_file "day1_session1/CHANGES-SUMMARY.md" "instructor/day1-changes-summary.md"

echo "  [assets]"
mv_file "custom-theme.scss" "assets/scss/custom-theme.scss"
mv_file "custom.scss" "assets/scss/custom.scss"
mv_file "custom2.scss" "assets/scss/custom2.scss"
mv_file "docs/styles.scss" "assets/scss/styles.scss"
mv_file "day1_session1/quarto-styles.css" "assets/css/quarto-styles.css"
mv_file "docs/typst-template.typ" "assets/typst/typst-template.typ"
mv_file "docs/typst-show.typ" "assets/typst/typst-show.typ"

echo "  [tools]"
mv_file "push_to_github.ps1" "tools/push-to-github.ps1"

echo "  [archive/agendas]"
mv_file "docs/Workshop_Agenda_R_Training.qmd" "archive/agendas/workshop-agenda-r-training.qmd"
mv_file "docs/Workshop_Agenda_R_Training.docx" "archive/agendas/workshop-agenda-r-training.docx"
mv_file "docs/Workshop_Agenda_R_Training.pdf" "archive/agendas/workshop-agenda-r-training.pdf"
mv_file "docs/workshop_agenda.qmd" "archive/agendas/pre-workshop-agenda.qmd"
mv_file "docs/workshop-demographic-analysis.qmd" "archive/agendas/workshop-demographic-analysis.qmd"
mv_file "docs/workshop-demographic-analysis-agenda.pdf" "archive/agendas/workshop-demographic-analysis-agenda.pdf"

echo "  [archive/variants]"
mv_file "docs/rstudio-git-session.qmd" "archive/variants/rstudio-git-session--docs-version.qmd"
mv_file "docs/demo_survey.R" "archive/variants/demo_survey--docs-version.R"

echo "  [data]"
mv_file "majors.csv" "data/majors.csv"
mv_file "home_dept.xlsx" "data/home_dept.xlsx"

echo
echo "--- moving directories ---"
mv_file "docs/imgs" "assets/img"

echo
echo "--- removing ---"
echo "  [empty placeholder files]"
rm_path "conversation-export.md"
rm_path "data_import_exprt.R"
rm_path "day1_session2/session2_data_packages.R"
echo "  [exact duplicates — Day2/ copy kept]"
rm_path "WDI.R"
rm_path "gt_summary.R"
rm_path "gt_tables.R"
rm_path "owid_tutorial.R"
echo "  [exact duplicates — assets/ copy kept]"
rm_path "day1_session1/custom-theme.scss"
rm_path "day1_session2/custom-theme.scss"
rm_path "docs/custom-theme.scss"
rm_path "docs/custom.scss"
rm_path "docs/custom2.scss"
rm_path "docs/my.scss"
rm_path "docs/quarto-styles.css"
echo "  [duplicate shapefile set — data/shape_file kept (scripts reference it)]"
rm_path "data/admn_shp"
echo "  [rendered output — regenerate with quarto render]"
rm_path "5day_data_prompt_workshop.html"
rm_path "5day_data_prompt_workshop_files"
rm_path "AI_Prompt_CheatSheet_Poster.html"
rm_path "AI_Prompt_CheatSheet_Poster_files"
rm_path "demystifying_202511.html"
rm_path "demystifying_202511_files"
rm_path "penguin_dashboard.html"
rm_path "penguin_dashboard_files"
rm_path "day1_session1/rstudio-git-session.html"
rm_path "day1_session2/demographic-analysis-nhanes.html"
rm_path "day1_session2/demographic-analysis-nhanes1.html"
rm_path "Day4/ODI.html"
rm_path "docs/Master_Data_Prompt_Pack.html"
rm_path "docs/rstudio-git-session.html"
rm_path "docs/ai-prompts-library.pdf"
rm_path "diabetes_plot.png"
echo "  [editor temp file]"
rm_path "docs/~WRL0003.tmp"

echo
echo "--- sweeping any remaining rendered artefacts ---"
while IFS= read -r p; do rm_path "$p"; done < <(
  find . -type d \( -name "*_files" -o -name "*_cache" \) -not -path "./.git/*" | sort
)
while IFS= read -r p; do rm_path "$p"; done < <(
  find . -maxdepth 3 -type f -name "*.html" -not -path "./.git/*" | sort
)

echo
echo "--- cleaning empty directories left behind ---"
for d in day1_session1 day1_session2 Day2 Day3 Day4 docs; do
  if [[ -d "$d" ]]; then
    if [[ -z "$(find "$d" -type f 2>/dev/null)" ]]; then
      run "rmdir -p --ignore-fail-on-non-empty \"$d\" 2>/dev/null || true"
      echo "  rmdir $d"
    else
      echo "  KEPT  $d — still contains files:"
      find "$d" -type f | sed 's/^/          /'
    fi
  fi
done

echo
echo "=== done: $moved moved, $skipped skipped, $removed removed ==="
if [[ $DRY -eq 1 ]]; then
  echo "Dry run only. Re-run without --dry-run to apply."
else
  echo "Next: copy scaffold files from d4d-reorganised.zip, then 'quarto render'."
  echo "Review with 'git status' before committing."
fi
