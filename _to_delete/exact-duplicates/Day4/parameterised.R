library(quarto)
library(tidyverse)
library(gapminder)



countries <-
  gapminder |>
  distinct(country) |>
  pull(country) |>
  as.character()



reports <-
  tibble(
    input = "parameterised.qmd",
    output_file = str_glue("{countries}.html"),
    execute_params = map(countries, ~ list(country = .))
  )



pwalk(reports, quarto_render)

## Only South Asian Countries

south_asian_countries <- c("Pakistan", "India", "Bangladesh", "Sri Lanka", "Nepal", "Bhutan", "Maldives")

reports <-
  tibble(
    input = "parameterised.qmd",
    output_file = str_glue("{south_asian_countries}.html"),
    execute_params = map(south_asian_countries, ~ list(country = .))
  )

pwalk(reports, quarto_render)
