library(readxl)
library(readr)
library(tidyverse)
library(forcats)
car_prices <- read_excel("data/car-prices.xlsx")



 View(car_prices)
# Remove missing values as t 

car_prices <- car_prices |> na.omit()

#remove dollar signs from sales column
#https://uc-r.github.io/lollipop
#https://www.statology.org/remove-dollar-sign-in-r/
 
# Lets have an overview of car price data
car_prices |> glimpse()

# Price is a character variable and we want it to be numeric variable

car_prices <- 
  car_prices |> mutate(prices=parse_number(Prices))





# car_prices$Prices <-  parse_number(car_prices$Prices)

car_prices|>glimpse() ## Now Prices is a double (numeric variable) and it has PKR written before it
## This is another way of doing the same thing
#car_prices$Prices = as.numeric(gsub("[\\PKR,]", "", car_prices$Prices))

# View(car_prices)
## To get first letter as Make
car_prices|>
  separate(
    col = Cars,
    into = c("first", "last"),
    sep = " ",
    remove = FALSE
  )|>head()    ## stringr 

car_prices |> mutate(make=gsub("([A-Za-z]+).*", "\\1", Cars)) -> car_prices

# car_prices$Make <- gsub("([A-Za-z]+).*", "\\1", car_prices$Cars)
# car_prices|> head()
## To convert price into millions of Rs.
carp <-
  car_prices |> mutate(prices = prices / 1000000) |> 
  mutate(make = factor(make))

carp |> glimpse()

ggplot(carp) +
  aes(x=make) +
  geom_bar() +
  coord_flip()
ggplot(carp, aes(x = make)) + geom_bar() + coord_flip()

library(forcats)
## Write data in csv to save final cleaned data
# write_csv(car_prices,file="car_prices.csv")
# saveRDS(car_prices,file="car_prices.rds")

#readRDS("D:/RepTemplates/AER/car_prices.rds")
ggplot(carp, aes(x = fct_infreq(make))) +
  geom_bar()




ggplot(carp, aes(x = fct_infreq(make))) +
  geom_bar(fill = "steelblue") + coord_flip()

library(ggthemes)

ggplot(carp, aes(x = fct_rev(fct_infreq(make)))) +
  geom_bar(fill = "steelblue") + coord_flip() +
  geom_text(stat = 'count', aes(label = after_stat(count)), hjust = -0.1) +
  labs(
    x = " ",
    y = " ",
    title = "Number of vehicles manufactured by \n each company",
    caption = "brecorder, by Zahid Asghar"
  )+
  theme_tufte()


ggplot(carp, aes(x = fct_rev(fct_infreq(make)))) +
  geom_bar(fill = "steelblue",
           just = 1,
           width = 0.4) + coord_flip() +
  geom_text(
    data = count(carp, make),
    mapping = aes(x = make,
                  y = n,
                  label = n),
    hjust = 1,
    vjust = 0,
    nudge_y = 0.1,
    color = 'grey30',
    fontface = 'bold',
    size = 5.5
  ) +
  geom_text(
    data = count(carp, make),
    mapping = aes(x = make,
                  y = 0,
                  label = str_to_title(make)),
    hjust = 0,
    vjust = 0,
    nudge_y = 0.1,
    nudge_x = 0.05,
    color = 'grey30',
    fontface = 'bold',
    size = 5.5
  ) +
  labs(y = element_blank(),
       x = element_blank(),
       title = 'Type of vehicles manufactured by each make in Pakistan') +
  theme_minimal(base_size = 20,
                base_family = 'Source Sans Pro') +
  theme(
    panel.grid = element_blank(),
    plot.title = element_text(family = 'Merriweather',
                              size = rel(1.2)),
    plot.title.position = 'plot'
  ) + geom_vline(xintercept = 0) +
  scale_y_continuous(breaks = NULL,
                     expand = expansion(mult = c(0, 0.01))) +
  scale_x_discrete(breaks = NULL)

  

data(mpg)
  
  
  

ggsave("bar_graph.png")


carp |> filter(make == "Suzuki") |> mutate(Cars = fct_reorder(Cars, prices)) |>
  ggplot(aes(x = Cars, y = prices)) + geom_bar(stat = "identity") + coord_flip()
+
  geom_text(stat = 'count', aes(label = after_stat(count)), vjust = -1)


carp |> filter(make == "Honda") |> mutate(Cars = fct_reorder(Cars, prices)) |>
  ggplot(aes(x = Cars, y = prices)) + geom_col() + coord_flip()

carp |> filter(make == "Honda") |> mutate(Cars = fct_reorder(Cars, prices)) |>
  ggplot(aes(
    y = Cars,
    x = prices,
    label = round(prices, 2)
  )) +
  geom_segment(aes(
    x = 0,
    y = Cars,
    xend = prices,
    yend = Cars
  ), color = "blue") +
  geom_point(size = 10) +
  geom_text(color = "white", size = 3) +
  labs(title = "Toyota vehicles pricess Jan-2023 in million of Rs.",
       caption = "Zahid Asghar") +
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
  )+theme_tufte()

## How to create beautifull tables

library(gt)
library(gtExtras)

carp |> filter(make == "Honda") |> select(Cars, prices) |>  mutate(Cars = fct_reorder(Cars, prices)) |>
  gt() |> gt_theme_pff() |> tab_header("Honda vehicles prices(mill. of PKR) in Jan-2023")


## Same table with New York times theme

carp |> filter(make == "Honda") |> select(Cars, prices) |>  mutate(Cars = fct_reorder(Cars, prices)) |>
  gt() |> gt_theme_nytimes() |> tab_header("Honda vehicles prices(mill. of PKR) in Jan-2023")


carp |> filter(make == "Honda") |> select(Cars, prices) |>  mutate(Cars = fct_reorder(Cars, prices)) |>
  gt() |> gt_theme_pff() |>
  tab_source_note("Business Recorder") |> tab_caption("Honda vehicels prices (mill. of PKR) Jan 2023")


library(dataxray)

carp |> select(prices) |> 
  make_xray() |>
  view_xray()
library(palmerpenguins)
penguins |>
  make_xray() |>
  view_xray()

diamonds |> 
  make_xray() |> 
  view_xray()



diamonds <- diamonds %>% 
  mutate(price = structure(price, label = 'price in US dollars'),
         carat = structure(carat, label = 'weight of the diamond'),
         cut = structure(cut, label = 'quality of the cut (Fair, Good, Very Good, Premium, Ideal)'),
         color = structure(color, label = 'diamond colour, from D (best) to J (worst)'),
         clarity = structure(clarity, label = 'a measurement of how clear the diamond is 
                                               (I1 (worst), SI2, SI1, VS2, VS1, VVS2, VVS1, IF (best))'),
         x = structure(x, label = 'length in mm'),
         y = structure(y, label = 'width in mm'),
         z = structure(z, label = 'depth in mm'),
         depth = structure(depth, label = 'total depth percentage = z / mean(x, y) = 2 * z / (x + y)'),
         table = structure(table, label = 'width of top of diamond relative to widest point'))

library(flexdashboard)

diamonds %>% 
  report_xray(data_name = 'Diamonds', study = 'ggplot2')

diamonds |> add_count()

diamonds |> mutate(rn = row_number())



mtcars |> 
  report_xray(data_name = 'mtcars', study = 'ggplot2')

