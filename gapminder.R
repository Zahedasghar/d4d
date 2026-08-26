library(gganimate)
library(gapminder)
#install.packages("ggblend")
library(ggblend)
library(tidyverse)


p = gapminder |>
  ggplot(aes(gdpPercap, lifeExp, size = pop, color = continent)) +
  list(
    geom_point(show.legend = c(size = FALSE)) |> partition(vars(continent)) |> blend("multiply"),
    geom_hline(yintercept = 70, linewidth = 1.5, color = "gray75")
  ) |> blend("hard.light") +
  scale_color_manual(
    # same as colorspace::lighten(continent_colors, 0.35)
    values = c(
      Africa = "#BE7658", Americas = "#E95866", Asia = "#7C5C86",
      Europe = "#659C5D", Oceania = "#7477CA"
    ),
    guide = guide_legend(override.aes = list(size = 4))
  ) +
  scale_size(range = c(2, 12)) +
  scale_x_log10(labels = scales::label_dollar(scale_cut = scales::cut_short_scale())) +
  scale_y_continuous(breaks = seq(20, 80, by = 10)) +
  labs(
    title = 'Gapminder with gganimate and ggblend',
    subtitle = 'Year: {frame_time}',
    x = 'GDP per capita',
    y = 'Life expectancy'
  )  +
  transition_time(year) +
  ease_aes('linear')

animate(p, type = "cairo", width = 600, height = 400, res = 100)
library(gifski)

anim_save("gapminder_ggblend.gif", animation = last_animation())

anim_save("gapminder_ggblend.gif", aimation=p)


## Have same plot for south asia region

gapminder |> filter(continent=="Asia"&country%in%c('India', 'Pakistan', 'Bangladesh', 'Nepal', 'Sri Lanka', 'Bhutan', 'Maldives')) |>
  ggplot(aes(gdpPercap, lifeExp, size = pop, color = country)) +
  list(
    geom_point(show.legend = c(size = FALSE)) |> partition(vars(country)) |> blend("multiply"),
    geom_hline(yintercept = 70, linewidth = 1.5, color = "gray75")
  ) |> blend("hard.light") +
  scale_color_manual(
    # same as colorspace::lighten(continent_colors, 0.35)
    values = c(
      'India'="#E95866", 'Pakistan'="#BE7658", 'Bangladesh'="#7C5C86",
      'Nepal'="#659C5D", 'Sri Lanka'="#7477CA", 'Bhutan'="#CA5CA3",
      'Maldives'="#5CA3A6"
    ),
    guide = guide_legend(override.aes = list(size = 4))
  ) +
  scale_size(range = c(2, 12)) +
  scale_x_log10(labels = scales::label_dollar(scale_cut = scales::cut_short_scale())) +
  scale_y_continuous(breaks = seq(20, 80, by = 10)) +
  labs(
    title = 'Gapminder South Asia with gganimate and ggblend',
    subtitle = 'Year: {frame_time}',
    x = 'GDP per capita',
    y = 'Life expectancy'
  )  +
  transition_time(year) +
  ease_aes('linear') -> p2
animate(p2, type = "cairo", width = 600, height = 400, res = 100)
