# =============================================================================
# HIES 2024-25 — individual income: detailed exploration
# Section 1B (employment & income) + household info
# Run block by block. Audits print BEFORE the step they guard.
# =============================================================================

library(haven)
library(tidyverse)
library(here)
library(scales)
library(gt)
library(gtsummary)
library(srvyr)

navy <- "#0f2440"
gold <- "#c9a227"

income_raw <- read_dta(here("hies", "sec_1b_emp_income.dta"))
weight <- read_dta(here("hies", "weight.dta"))
hh_info    <- read_dta(here("hies", "section_info.dta"))

# -----------------------------------------------------------------------------
# 0. STRUCTURE — before touching anything
# -----------------------------------------------------------------------------

income_raw |> glimpse()
hh_info    |> glimpse()

names(income_raw)
names(hh_info)

# what is the unit of observation? expect one row per person-job or per person
income_raw |>
  count(prcode, hhno, idc) |>
  count(n, name = "n_keys")          # any n > 1 means idc is NOT unique -> multiple job rows

nrow(income_raw)
income_raw |> distinct(prcode, hhno) |> nrow()      # households represented
income_raw |> distinct(prcode, hhno, idc) |> nrow() # individuals represented


# -----------------------------------------------------------------------------
# 1. LABEL AUDIT — print every label BEFORE writing any string comparison
#    This is the block that prevents silent case_when() failure.
# -----------------------------------------------------------------------------


## Naive way

# --- labels for each categorical variable, one at a time ---
income_raw |> mutate(label = as.character(as_factor(province))) |> count(province, label)
income_raw |> mutate(label = as.character(as_factor(region))) |> count(region, label)
income_raw |> mutate(label = as.character(as_factor(s1bq01))) |> count(s1bq01, label)
income_raw |> mutate(label = as.character(as_factor(s1bq02))) |> count(s1bq02, label)
income_raw |> mutate(label = as.character(as_factor(s1bq05))) |> count(s1bq05, label)
income_raw |> mutate(label = as.character(as_factor(s1bq09))) |> count(s1bq09, label)
income_raw |> mutate(label = as.character(as_factor(s1bq14))) |> count(s1bq14, label)

# --- variable label (description) for each column, printed one at a time ---
attr(income_raw$province, "label")
attr(income_raw$region, "label")
attr(income_raw$s1bq01, "label")
attr(income_raw$s1bq02, "label")
attr(income_raw$s1bq05, "label")
attr(income_raw$s1bq06, "label")
attr(income_raw$s1bq07, "label")
attr(income_raw$s1bq08, "label")
attr(income_raw$s1bq09, "label")
attr(income_raw$s1bq14, "label")

# Or, if you just want every variable label in the file without typing each name:

sapply(income_raw, function(x) attr(x, "label"))



label_vars <- c("province", "region", "s1bq01", "s1bq02", "s1bq05",
                "s1bq09", "s1bq14")





walk(label_vars, \(v) {
  cat("\n---", v, "---\n")
  income_raw |>
    mutate(label = as.character(as_factor(.data[[v]]))) |>
    count(code = .data[[v]], label) |>
    print(n = Inf)
})

# variable labels straight from the .dta
income_raw |>
  select(all_of(label_vars), starts_with("s1bq0"), starts_with("s1bq1")) |>
  map_chr(\(x) attr(x, "label", exact = TRUE) %||% NA_character_) |>
  enframe(name = "variable", value = "label") |>
  print(n = Inf)


# -----------------------------------------------------------------------------
# 2. CONVERT LABELLED -> CHARACTER, then verify nothing slipped through
# -----------------------------------------------------------------------------

income <- income_raw |>
  mutate(across(
    c(province, region, s1bq01, s1bq02, s1bq05, s1bq09, s1bq91, s1bq14,
      s1bq151, s1bq152, s1bq153, s1bq154, s1bq155, s1bq156, s1bq157,
      s1bq158, s1bq159, s1bq1510, s1bq1511, s1bq1512),
    \(x) as.character(as_factor(x))
  ))

income |> select(where(haven::is.labelled)) |> names()   # expect character(0)

# unlabelled province code (Islamabad appears as bare "6")
income |> count(province)



income <- income |>
  mutate(province = if_else(province == "6", "Islamabad", province))

# guard: province must cover ALL administered units, not just four
income |> count(province)

# expect Punjab, Sindh, KP, Balochistan, Islamabad (+ AJK / GB if HIES covers them)


# -----------------------------------------------------------------------------
# 3. LOCK THE LABEL STRINGS — edit these to match the counts printed in §1
#    Every downstream filter uses these objects, not hard-coded literals.
# -----------------------------------------------------------------------------

lab_employed <- "yes"
lab_monthly  <- "monthly"
lab_daily    <- NA_character_   # doesn't exist in this data
lab_weekly   <- NA_character_   # doesn't exist in this data

stopifnot(
  sum(income$s1bq01 == lab_employed, na.rm = TRUE) > 0,
  sum(income$s1bq05 == lab_monthly,  na.rm = TRUE) > 0
)


# -----------------------------------------------------------------------------
# 4. HOW IS INCOME ACTUALLY REPORTED?
# -----------------------------------------------------------------------------

income |>
  count(s1bq05,
        has_annual  = !is.na(s1bq08),
        has_amount  = !is.na(s1bq06),
        has_periods = !is.na(s1bq07)) |>
  arrange(desc(n)) |>
  print(n = Inf)

# ranges of the raw components — catches unit confusion (Rs. vs '000 Rs.)
income |>
  summarise(across(c(s1bq06, s1bq07, s1bq08),
                   list(min    = \(x) min(x, na.rm = TRUE),
                        p50    = \(x) median(x, na.rm = TRUE),
                        max    = \(x) max(x, na.rm = TRUE),
                        n_zero = \(x) sum(x == 0, na.rm = TRUE),
                        n_na   = \(x) sum(is.na(x))))) |>
  pivot_longer(everything(),
               names_to = c("var", "stat"),
               names_pattern = "(s1bq\\d+)_(.*)") |>
  pivot_wider(names_from = stat, values_from = value)

# s1bq07 sanity: if it is "number of months", it must be 1-12
income |> count(s1bq05, s1bq07) |> filter(s1bq05 == lab_monthly) |> print(n = Inf)


# -----------------------------------------------------------------------------
# 5. BUILD ANNUAL MAIN-OCCUPATION INCOME — recover every periodicity, and
#    record WHICH rule produced each value so nothing is untraceable.
# -----------------------------------------------------------------------------

income <- income |>
  mutate(
    annual_main_income = case_when(
      !is.na(s1bq08)                                        ~ s1bq08,
      s1bq05 == lab_monthly & !is.na(s1bq06) & !is.na(s1bq07) ~ s1bq06 * s1bq07,
      s1bq05 == lab_weekly  & !is.na(s1bq06) & !is.na(s1bq07) ~ s1bq06 * s1bq07,
      s1bq05 == lab_daily   & !is.na(s1bq06) & !is.na(s1bq07) ~ s1bq06 * s1bq07,
      .default = NA_real_
    ),
    main_income_source = case_when(
      !is.na(s1bq08)              ~ "reported annual",
      !is.na(annual_main_income)  ~ "recovered amount x periods",
      s1bq01 != lab_employed      ~ "not employed",
      .default = "employed, unrecoverable"
    )
  )

income |> count(main_income_source, s1bq05) |> arrange(desc(n)) |> print(n = Inf)

# missingness among the employed
income |>
  filter(s1bq01 == lab_employed) |>
  count(main_income_source) |>
  mutate(pct = round(100 * n / sum(n), 1))


# -----------------------------------------------------------------------------
# 6. TOTAL INDIVIDUAL INCOME — all-NA must stay NA, not become 0
# -----------------------------------------------------------------------------

inc_cols <- c("annual_main_income", "s1bq10", "s1bq11", "s1bq12", "s1bq13")

income |>
  summarise(across(all_of(inc_cols),
                   list(n_nonmiss = \(x) sum(!is.na(x)),
                        n_pos     = \(x) sum(x > 0, na.rm = TRUE),
                        p50       = \(x) median(x, na.rm = TRUE))))

income <- income |>
  mutate(
    all_missing  = if_all(all_of(inc_cols), is.na),
    total_income = if_else(
      all_missing,
      NA_real_,
      rowSums(across(all_of(inc_cols)), na.rm = TRUE)
    ),
    income_status = case_when(
      is.na(total_income)  ~ "missing",
      total_income == 0    ~ "zero",
      total_income  > 0    ~ "positive"
    )
  )

# THE accounting table — every row of the file lands in exactly one cell
income |>
  count(s1bq01, income_status) |>
  mutate(pct = round(100 * n / sum(n), 1)) |>
  arrange(desc(n)) |>
  print(n = Inf)

# analysis frame kept SEPARATE from the full file
inc <- income |>
  filter(income_status == "positive") |>
  mutate(loginc = log(total_income))

nrow(income); nrow(inc)
round(100 * nrow(inc) / nrow(income), 1)   # share of file retained


# -----------------------------------------------------------------------------
# 7. WEIGHTS — join household info, audit the join, build the survey design
# -----------------------------------------------------------------------------

# locate the weight variable (name varies by round: weight / wgt / hhwt / rwt)
hh_info |> select(matches("w(ei)?ght|^wt$|^rwt")) |> names()
hh_info |> select(matches("psu|cluster|strat")) |> names()


# audit BEFORE joining
inc |> anti_join(hh_info, by = join_by(prcode, hhno)) |> nrow()   # expect 0
hh_info |> anti_join(inc, by = join_by(prcode, hhno)) |> nrow()   # households w/ no earner
## Missing join keys, if any, are printed below. If the audit fails, investigate before proceeding.
inc |> anti_join(hh_info, by = join_by(prcode, hhno)) |> select(prcode, hhno)
wt_var  <- "weight"
psu_var <- "prcode"    # this is the cluster/PSU code, not province

intersect(names(inc), names(weight))   # expect "prcode"

inc |> anti_join(weight, by = join_by(prcode)) |> nrow()   # expect 0
weight |> anti_join(inc, by = join_by(prcode)) |> nrow()   # PSUs with no earner, fine if > 0

inc <- inc |>
  left_join(weight, by = join_by(prcode), unmatched = "error")

inc |> summarise(n_missing_wt = sum(is.na(.data[[wt_var]])),
                 min_wt = min(.data[[wt_var]], na.rm = TRUE),
                 max_wt = max(.data[[wt_var]], na.rm = TRUE))

des <- inc |>
  as_survey_design(ids = prcode, weights = weight)
inc |> summarise(n_missing_wt = sum(is.na(.data[[wt_var]])),
                 min_wt = min(.data[[wt_var]], na.rm = TRUE),
                 max_wt = max(.data[[wt_var]], na.rm = TRUE))

des <- inc |>
  as_survey_design(ids = all_of(psu_var), weights = all_of(wt_var))


# -----------------------------------------------------------------------------
# 8. DOES WEIGHTING MATTER? — the comparison that justifies the extra work
# -----------------------------------------------------------------------------

unwtd <- inc |>
  summarise(n = n(),
            mean = mean(total_income),
            median = median(total_income),
            .by = province) |>
  mutate(basis = "unweighted")

wtd <- des |>
  group_by(province) |>
  summarise(n = unweighted(n()),
            mean = survey_mean(total_income, vartype = "ci"),
            median = survey_median(total_income, vartype = "ci")) |>
  select(province, n, mean, median) |>
  mutate(basis = "weighted")

bind_rows(unwtd, wtd) |>
  pivot_wider(names_from = basis, values_from = c(mean, median)) |>
  mutate(pct_diff_mean = round(100 * (mean_weighted / mean_unweighted - 1), 1)) |>
  arrange(desc(abs(pct_diff_mean))) |> View()


# -----------------------------------------------------------------------------
# 9. DISTRIBUTION
# -----------------------------------------------------------------------------

inc |>
  summarise(
    n      = n(),
    mean   = mean(total_income),
    median = median(total_income),
    sd     = sd(total_income),
    cv     = sd / mean,
    min    = min(total_income),
    max    = max(total_income)
  )

# full quantile vector, one row per quantile
inc |>
  reframe(q = c(.01, .05, .10, .25, .50, .75, .90, .95, .99),
          value = quantile(total_income, q))

# same, by province
inc |>
  reframe(q = c(.10, .25, .50, .75, .90),
          value = quantile(total_income, q),
          .by = province) |>
  pivot_wider(names_from = q, values_from = value, names_prefix = "p")


# dispersion ratios
inc |>
  summarise(
    p90_p10 = quantile(total_income, .90) / quantile(total_income, .10),
    p90_p50 = quantile(total_income, .90) / quantile(total_income, .50),
    p50_p10 = quantile(total_income, .50) / quantile(total_income, .10),
    .by = province
  ) |>
  arrange(desc(p90_p10))

# raw vs log
ggplot(inc, aes(total_income)) +
  geom_histogram(bins = 60, fill = navy) +
  scale_x_continuous(labels = label_comma()) +
  labs(title = "Annual individual income, HIES 2024-25",
       x = "Total income (Rs.)", y = "Count")

ggplot(inc, aes(loginc)) +
  geom_histogram(bins = 60, fill = navy) +
  labs(title = "Log annual individual income, HIES 2024-25",
       x = "log(total income)", y = "Count")

# is the log distribution actually normal? (lognormality is an assumption, not a fact)
ggplot(inc, aes(sample = loginc)) +
  stat_qq(colour = navy, alpha = .2) +
  stat_qq_line(colour = gold, linewidth = 1) +
  labs(title = "Q-Q plot, log income", x = "Theoretical", y = "Sample")


# -----------------------------------------------------------------------------
# 10. DATA-QUALITY DIAGNOSTICS
# -----------------------------------------------------------------------------

# (a) digit heaping — respondents round; heavy heaping limits decimal precision
inc |>
  mutate(round_to = case_when(
    total_income %% 100000 == 0 ~ "100,000",
    total_income %% 10000  == 0 ~ "10,000",
    total_income %% 1000   == 0 ~ "1,000",
    total_income %% 100    == 0 ~ "100",
    .default = "not round"
  )) |>
  count(round_to) |>
  mutate(pct = round(100 * n / sum(n), 1)) |>
  arrange(desc(n))

# (b) top-coding — a spike at the max means the value is administrative, not real
inc |> count(total_income, sort = TRUE) |> slice_head(n = 15)

# (c) implausible values: implied monthly income
inc |>
  mutate(implied_monthly = total_income / 12) |>
  filter(implied_monthly < 1000 | implied_monthly > 2000000) |>
  count(province, region, s1bq02) |>
  arrange(desc(n))

# (d) extremes with identifiers, both tails
inc |>
  slice_min(total_income, n = 15) |>
  select(prcode, province, region, hhno, idc, s1bq02, s1bq05,
         s1bq06, s1bq07, s1bq08, annual_main_income, total_income)

inc |>
  slice_max(total_income, n = 15) |>
  select(prcode, province, region, hhno, idc, s1bq02, s1bq05,
         s1bq06, s1bq07, s1bq08, annual_main_income, total_income)

# (e) how much of aggregate income sits in the top 1%? sensitivity to trimming
inc |>
  summarise(
    share_top1  = sum(total_income[total_income >= quantile(total_income, .99)]) / sum(total_income),
    share_top10 = sum(total_income[total_income >= quantile(total_income, .90)]) / sum(total_income)
  )


# -----------------------------------------------------------------------------
# 11. INEQUALITY — decile shares, Lorenz, Gini (weighted and unweighted)
# -----------------------------------------------------------------------------

# small helper: weighted Gini. Kept as a function because it is analysis, not cleaning.
gini_w <- function(x, w = rep(1, length(x))) {
  ord <- order(x)
  x <- x[ord]; w <- w[ord]
  p  <- cumsum(w) / sum(w)
  nu <- cumsum(w * x) / sum(w * x)
  sum(nu[-1] * p[-length(p)]) - sum(nu[-length(nu)] * p[-1])
}

inc |>
  summarise(
    gini_unweighted = gini_w(total_income),
    gini_weighted   = gini_w(total_income, .data[[wt_var]])
  )

inc |>
  summarise(gini = gini_w(total_income, .data[[wt_var]]), n = n(), .by = province) |>
  arrange(desc(gini))

# decile shares
decile_shares <- inc |>
  mutate(decile = ntile(total_income, 10)) |>
  summarise(n = n(),
            total = sum(total_income),
            .by = decile) |>
  mutate(share = 100 * total / sum(total)) |>
  arrange(decile)

decile_shares

ggplot(decile_shares, aes(factor(decile), share)) +
  geom_col(fill = navy) +
  geom_text(aes(label = number(share, accuracy = .1)), vjust = -0.4, size = 3) +
  labs(title = "Share of total individual income by decile",
       x = "Income decile", y = "% of aggregate income")

# Lorenz curve
inc |>
  arrange(total_income) |>
  mutate(pop_share = row_number() / n(),
         inc_share = cumsum(total_income) / sum(total_income)) |>
  ggplot(aes(pop_share, inc_share)) +
  geom_abline(slope = 1, intercept = 0, linetype = 2, colour = "grey50") +
  geom_line(colour = navy, linewidth = 1) +
  scale_x_continuous(labels = label_percent()) +
  scale_y_continuous(labels = label_percent()) +
  labs(title = "Lorenz curve, individual income, HIES 2024-25",
       x = "Cumulative population share", y = "Cumulative income share")


# -----------------------------------------------------------------------------
# 12. CUTS — province, region, employment status
# -----------------------------------------------------------------------------

inc |>
  summarise(n = n(),
            mean = mean(total_income),
            median = median(total_income),
            .by = c(province, region)) |>
  arrange(province, region)

inc |>
  summarise(n = n(),
            mean = mean(total_income),
            median = median(total_income),
            p90_p10 = quantile(total_income, .9) / quantile(total_income, .1),
            .by = s1bq02) |>
  arrange(desc(median))

# urban premium, by province
inc |>
  summarise(median = median(total_income), .by = c(province, region)) |>
  pivot_wider(names_from = region, values_from = median) |>
  mutate(across(where(is.numeric), \(x) round(x))) |>
  print(n = Inf)

ggplot(inc, aes(fct_reorder(province, total_income, .fun = median), total_income)) +
  geom_boxplot(fill = gold, outlier.alpha = 0.15) +
  scale_y_log10(labels = label_comma()) +
  coord_flip() +
  labs(title = "Income by province (log scale)",
       x = NULL, y = "Total income (Rs., log scale)")

# ECDF reads better than boxplots when distributions cross
ggplot(inc, aes(total_income, colour = province)) +
  stat_ecdf(linewidth = .8) +
  scale_x_log10(labels = label_comma()) +
  scale_y_continuous(labels = label_percent()) +
  labs(title = "Cumulative income distribution by province",
       x = "Total income (Rs., log scale)", y = "Share at or below",
       colour = NULL)

ggplot(inc, aes(loginc, fill = region)) +
  geom_density(alpha = .45) +
  scale_fill_manual(values = c(navy, gold)) +
  labs(title = "Log income density, urban vs rural",
       x = "log(total income)", y = "Density", fill = NULL)


# -----------------------------------------------------------------------------
# 13. INCOME COMPOSITION — how much comes from non-main sources?
# -----------------------------------------------------------------------------

inc |>
  summarise(across(all_of(inc_cols), \(x) sum(x, na.rm = TRUE))) |>
  pivot_longer(everything(), names_to = "source", values_to = "total") |>
  mutate(share = 100 * total / sum(total)) |>
  arrange(desc(share))

# does composition shift across the distribution?
inc |>
  mutate(decile = ntile(total_income, 10)) |>
  summarise(across(all_of(inc_cols), \(x) sum(x, na.rm = TRUE)), .by = decile) |>
  pivot_longer(-decile, names_to = "source", values_to = "total") |>
  mutate(share = 100 * total / sum(total), .by = decile) |>
  ggplot(aes(factor(decile), share, fill = source)) +
  geom_col() +
  labs(title = "Income composition by decile",
       x = "Income decile", y = "% of decile income", fill = NULL)


# -----------------------------------------------------------------------------
# 14. HOUSEHOLD LEVEL — earners per household, household income
#     NOTE: household SIZE must come from the roster (section 1A), not from this
#     file, which contains only earners. Per-capita income is NOT computable here.
# -----------------------------------------------------------------------------

hh_income <- inc |>
  summarise(n_earners = n(),
            hh_income = sum(total_income),
            .by = c(prcode, hhno, province, region))

hh_income |> count(n_earners) |> mutate(pct = round(100 * n / sum(n), 1))

hh_income |>
  summarise(n = n(),
            median_hh_income = median(hh_income),
            median_earners = median(n_earners),
            .by = c(province, region)) |>
  arrange(province, region)


# -----------------------------------------------------------------------------
# 15. PRESENTATION TABLES
# -----------------------------------------------------------------------------

inc |>
  select(province, region, total_income) |>
  tbl_strata(
    strata = region,
    .tbl_fun = ~ .x |>
      tbl_summary(
        by = province,
        type      = total_income ~ "continuous",
        statistic = total_income ~ "{mean} ({p25}, {p50}, {p75})",
        label     = total_income ~ "Total income (Rs.)",
        digits    = total_income ~ 0
      )
  )

inc |>
  summarise(n = n(),
            mean = mean(total_income),
            median = median(total_income),
            gini = gini_w(total_income, .data[[wt_var]]),
            .by = province) |>
  arrange(desc(median)) |>
  gt() |>
  fmt_number(c(mean, median), decimals = 0) |>
  fmt_number(gini, decimals = 3) |>
  tab_header(title = "Individual income by province",
             subtitle = "HIES 2024-25, positive-income individuals") |>
  tab_source_note("Source: PBS HIES 2024-25, Section 1B.")
