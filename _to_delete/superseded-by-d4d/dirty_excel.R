# https://albert-rapp.de/posts/07_janitor_showcase/07_janitor_showcase.html
library(tidyverse)
library(readr)
library(janitor)
nurses <- readr::read_csv('https://raw.githubusercontent.com/rfordatascience/tidytuesday/master/data/2021/2021-10-05/nurses.csv')

View(nurses)

## Save as excel

#write_excel_csv(nurses, "data/nurses.csv")

names(nurses)

nurses |> clean_names() |> names()



glimpse(nurses)

library(readxl)


# dirty_excel <- read_excel("data/dirty_data.xlsx")
dirty_excel <- read_excel("data/dirty_data.xlsx", skip = 1) 
dirty_excel|> 
  clean_names() |> 
  remove_empty() |> 
  remove_constant() -> clean_xl
clean_xl |> 
  mutate(hire_date=excel_numeric_to_date(hire_date))


# Rounding

round(seq(0.5,4.5,1))

round_half_up(seq(0.5,4.5,1))


## Find matches in multiple characters

starwars %>% 
  get_dupes(eye_color, hair_color, skin_color, sex, homeworld) %>% 
  select(1:8)




tbl <- tribble(~Region,	~Tax,	~Amount,
'Lahore',	'CD',	40,
'Gujranwala',	'ST',	54,
'Peshawar',	'FED',	86,
'Larkana',	'IT',	65,
'Zhob',	'CD',	43,
'Lahore',	'ST',	91,
'Gujranwala',	'FED',	17,
'Peshawar',	'IT',	99,
'Larkana',	'CD',	41,
'Zhob',	'ST',	56,
'Lahore',	'FED',	90,
'Gujranwala',	'IT',	35,
'Peshawar',	'CD',	63,
'Larkana',	'ST',92,
'Zhob',	'FED',	45)

tbl
