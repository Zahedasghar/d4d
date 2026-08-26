## dplyr (31)

# **Core verbs:** `filter()`, `mutate()`, `summarise()`, `select()`, `arrange()`, `count()`, `slice()`, `slice_head()`, `pull()`, `glimpse()`
#
# **dplyr 1.2.0 verbs (the new ones):** `filter_out()`, `when_any()`, `when_all()`, `recode_values()`, `replace_when()`
#
# **Conditional / vector helpers:** `case_when()`, `coalesce()`, `across()`, `where()`, `desc()`, `n()`, `n_distinct()`, `lag()`, `first()`
#
# **Joins:** `left_join()`, `inner_join()`, `anti_join()`, `cross_join()`, `bind_rows()`, `join_by()`
#
# **Arguments worth naming as commands in their own right:** `.by =`, `relationship =`, `suffix =`



# tibble ------------------------------------------------------------------


## tibble (4)

#  `tibble()`, `tribble()`, `as_tibble()`, `lst()`

## readr (5)

# `read_csv()`, `write_csv()`, `cols()`, `col_character()`, `parse_number()`

## tidyr (2)
# `complete()`, `pivot_longer()`

## stringr (4)

# `str_detect()`, `str_squish()`, `str_wrap()`, `regex()`

## lubridate (3)

# `ymd()`, `year()`, `month()`

## purrr (2)

#`walk()`, `iwalk()`

## forcats (1)


# `fct_reorder()`

## ggplot2 (20)
`ggplot()`, `aes()`, `geom_line()`, `geom_hline()`, `geom_ribbon()`, `geom_smooth()`, `geom_sf()`, `geom_sf_label()`, `facet_wrap()`, `labs()`, `scale_y_continuous()`, `scale_fill_viridis_c()`, `coord_sf()`, `theme_minimal()`, `theme_void()`, `theme_set()`, `ggsave()`, `alpha()`

## scales (2)
`label_number()`, `label_percent()`

## Spatial and support packages (13)

- **sf:** `st_as_sf()`, `st_sf()`, `st_distance()`, `st_drop_geometry()`, `st_geometry()`, `st_make_valid()`, `st_union()`
- **rnaturalearth:** `ne_states()`
- **ggrepel:** `geom_text_repel()`
- **here:** `here()`
- **units:** `set_units()`, `drop_units()`

## Base R and stats (28)

`as.numeric()`, `is.na()`, `sum()`, `mean()`, `min()`, `max()`, `sd()`, `quantile()`, `exp()`, `log()`, `cumprod()`, `abs()`, `sort()`, `unique()`, `nrow()`, `list()`, `dimnames()`, `dir.create()`, `file.path()`, `list.files()`, `paste()`, `paste0()`, `print()`, `packageVersion()`, `stop()`, `function()`, `lm()`, `summary()`, `sessionInfo()`

## Operators
`|>` (native pipe, 120 uses), `%in%`, `~` (formula, in `recode_values()` / `replace_when()` and `lm()`), `\(x)` lambda shorthand


# Two things worth flagging for the training. First, **`str_squish()` is passed bare** inside `across(where(is.character), str_squish)` — no parentheses. Participants who scan for `str_squish(` will miss it. Second, `distinct()`, `group_by()`, `ungroup()`, `pivot_wider()`, `map()`, `case_match()`, and `if_else()` appear **nowhere** in this pipeline — the first three because `.by =` and `summarise()` replace them, `case_match()` because it's deprecated in favour of `recode_values()`.
