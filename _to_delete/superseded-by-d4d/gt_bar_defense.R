library(tidyverse)
library(gt)
library(gtExtras)
library(readxl)
library(janitor)
library(gapminder)
library(countrycode)
library(ggflags)
library(ggthemes)

readxl::read_excel("data/defense.xlsx")  |> dplyr::select(2:4)|> clean_names() ->
  military
military$country <-  gsub(':',"",military$country)

military |> glimpse()

military |>     mutate(percent_military_spend_of_economy=percent_defense_of_economy*100)|> 
  select(countries,country,percent_military_spend_of_economy) |> 
  
  gt() |> 
    cols_move_to_start(columns = countries) |>   
 tab_header(title = md("**Military expenditure as percentage of GDP**"),
            subtitle=md("*Pakistan may have far lower %age of GDP if its economy has done well during last 3 decades*")) |> 
  fmt_flag(columns=countries)|> 
  cols_label(country="Country",
             countries="",
             percent_military_spend_of_economy="Military spend as % of economy",
             ) |> 
  cols_align(align = "center") |> 
  opt_stylize(style = 6, color="green" ) |> 
  opt_table_font(font=google_font("IBM Plex Sans")) |> 
  opt_align_table_header(align="left") |> 
  data_color(columns =percent_military_spend_of_economy , method = "numeric", palette = "Set3") |> 
  tab_stubhead(label="Country") |> 
  tab_source_note(
    source_note = "Source: @stat_feed") |> 
  tab_source_note(source_note = "military spend as of 5th of June 2023"
  )

library(forcats)

military |> mutate(percent_military_spend_of_economy=percent_defense_of_economy*100)|>
ggplot(aes(x = fct_rev(fct_infreq(country, percent_military_spend_of_economy)), y =
                        percent_military_spend_of_economy)) +
  geom_bar(stat = "identity")+
  coord_flip()+
  labs(
    x = " ",
    y = " ")

library(ggthemes)

military |> mutate(percent_military_spend_of_economy = percent_defense_of_economy *
                     100) |>
  ggplot(aes(
    x = percent_military_spend_of_economy,
    y = reorder(country, percent_military_spend_of_economy),
    label = round(percent_military_spend_of_economy, 2)
  )) +
  geom_segment(
    aes(
      x = 0,
      y = reorder(country, percent_military_spend_of_economy),
      xend = percent_military_spend_of_economy,
      yend = country
    ),
    color = "blue"
  ) +
  geom_point(size = 10) +
  geom_text(color = "white", size = 3) +
  labs(title = "Percent spending of economy on military",
       subtitle="Economy is key. Pakistan main issue is not large budget allocation on military but size of its economy.
       A small pie size from a large cake might have served far better ",
       caption = "Source: @stat_feed,by :Zahid Asghar") +
  theme_minimal() +
  theme(
    axis.title = element_blank(),
    panel.grid.minor = element_blank(),
    legend.position = "none",
    text = element_text(family = "Georgia"),
    axis.text.y = element_text(size = 8),
    plot.title = element_text(
      size = 20,
      margin = margin(b = 10),
      hjust = 0
    ),
    plot.subtitle = element_text(
      size = 12,
      color = "darkslategrey",
      margin = margin(b = 25, l = -25)
    ),
    plot.caption = element_text(
      size = 8,
      margin = margin(t = 10),
      color = "grey70",
      hjust = 0
    )
  )+theme_fivethirtyeight()









  
  
  ?fmt_flag
?gt
  
countrypops |>
  dplyr::filter(year == 2021)|>
  dplyr::filter(grepl("^S", country_name)) |>
  dplyr::arrange(country_name) |>
  dplyr::select(-country_code_3, -year) |>
  dplyr::slice_head(n = 10) |>
  gt() |>
  cols_move_to_start(columns = country_code_2) |>
  fmt_integer() |>
  fmt_flag(columns = country_code_2) |>
  cols_label(
    country_code_2 = "",
    country_name = "Country",
    population = "Population (2021)"
  )
