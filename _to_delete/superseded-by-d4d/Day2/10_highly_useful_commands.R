#Top 10 favorite dplyr commands
##https://datacornering.com/my-top-10-favorite-dplyr-tips-and-tricks/
## favorite 1

require(dplyr)

iris |>
  select(
    SL = Sepal.Length,
    PL = Petal.Length,
    SW = Sepal.Width,
    PW = Petal.Width,
    Species
  ) |> head()


## favorite 2
# rowwise
randu |>
  rowwise() |>
  mutate(min_xy = min(x, y)) |>
  as.data.frame() |>
  head()


## favorite 3
#Rearrange columns quickly with dplyr everything , to move newly created column before others

randu |>
  rowwise() |>
  mutate(min_xy = min(x, y)) |>
  select(min_xy, everything()) |>
  as.data.frame() |>
  head()

## favorite 4
##Drop unnecessary columns with dplyr

iris |>
  select(-contains("Width")) |>
  head()

## favorite 5
## Use dplyr count or add_count instead of group_by and summarize

iris |> count(Species, name = "Species.count") |> head()



## favorite 6
##Replace nested ifelse with dplyr case_when function

airquality |>
  mutate(temp_cat = case_when(Temp > 70 ~ "high",
                              Temp <= 70 & Temp > 60 ~ "medium",
                              TRUE ~ "LOW")) |> head()


## favorite 7
# Execute calculations across columns conditionally with dplyr (max value where is numeric)

iris |> summarise(across(where(is.numeric),max,na.rm=TRUE))

iris %>%
  summarise(across(where(is.numeric), ~max(., na.rm = TRUE)))


## Here is a text transformation after which every character column contains
## text with capital letters.

starwars |>glimpse()

starwars |> 
  select(1:5) |> 
  as.data.frame() |> 
  head()

starwars |> 
  mutate_if(is.character,toupper) |>
  select(1:5)|>
  as.data.frame()|>
  head()

## favorite 8

## Filter by calculation of grouped data inside the filter function

mtcars |> count(cyl)

mtcars <- mtcars |> count(cyl) |> filter(n > 10)
mtcars |> as.data.frame()


# favorite 9
## Get top and bottom values by each group with dplyr 

starwars |> select(gender, mass) |>
  group_by(gender) |>
  slice_max(mass, n = 3, with_ties = F) |>
  arrange(gender, desc(mass)) |>
  tidyr::drop_na() |>
  mutate(cat = "top3") |>
  as.data.frame()

-## favorite 10 
# Reflow your dplyr code

# ctrl+shift+A 
  starwars |> select(gender, mass) |>  group_by(gender) |>
  slice_max(mass, n = 3, with_ties = F) |>  arrange(gender, desc(mass)) |>
  tidyr::drop_na() |>  mutate(cat = "top3") |>  as.data.frame()
