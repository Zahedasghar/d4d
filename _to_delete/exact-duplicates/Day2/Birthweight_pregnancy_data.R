library(readr)
library(tidyverse)
library(vtable)
library(gtsummary)
library(gt)
library(gtExtras)
nc <- read_csv("https://docs.google.com/spreadsheets/d/e/2PACX-1vTm2WZwNBoQdZhMgot7urbtu8eG7tzAq-60ZJsQ_nupykCAcW0OXebVpHksPWyR4x8xJTVQ8KAulAFS/pub?gid=202410847&single=true&output=csv")
nc<-as_tibble(nc)



View(nc)
glimpse(nc)

nc|>select(premie,habit) %>% tbl_summary()


nc |>tbl_cross(
  row=habit,
  col=lowbirthweight,
  percent = "cell"
) |> add_p()


nc|>tbl_cross(
  row=habit,
  col=lowbirthweight,
  percent = "cell"
) |> add_p()


nc|>tbl_cross(
  row=habit,
  col=lowbirthweight,
  percent = "cell"
) |> add_p()|> as_gt()



nc|>tbl_cross(
  row=habit,
  col=lowbirthweight,
  percent = "cell"
) |> add_p()|> as_gt()|> gt_theme_nytimes()|>
  tab_header(title="Relationship between birth weigth and smoking habits")



nc|>tbl_cross(
  row=habit,
  col=lowbirthweight,
  percent = "cell"
) |> add_p()|> as_gt()|> gt_theme_nytimes()|>
  tab_header(title="Relationship between birth weigth and smoking habits")|>
  tab_source_note(
    source_note = "Source: NC data on birtherweights")


nc |> filter(habit=="smoker")|>tbl_cross(
  row=habit,
  col=lowbirthweight,
  percent = "cell"
) 

nc |> filter(habit=="nonsmoker")|>tbl_cross(
  row=habit,
  col=lowbirthweight,
  percent = "cell"
) 






vtable(nc)
ggplot(data = nc, aes(x = weeks, y = weight)) + 
  geom_point()
ggplot(data = nc, aes(x = weeks, y = weight)) + 
  geom_point() + 
  labs(x = "Length of pregnancy (in weeks)", y = "Birth weight of baby (lbs)", 
       title = "Relationship between pregnancy duration and newborn weight")
ggplot(data = nc, aes(x = weeks, y = gained, color = premie))+ 
  geom_point() + 
  labs(x = "Pregnancy length (wks)", y = "Maternal weight gain (lbs)")


ggplot(data = nc, aes(x = weeks)) +
  geom_histogram(binwidth = 1, color = "white", fill = "steelblue") +
  facet_wrap(~ mature, ncol = 1)



ggplot(data = nc, aes(x = gender, y = gained)) +
  geom_boxplot(fill = "sienna")


ggplot(data = nc, aes(x = gender, y = gained)) +
  geom_boxplot(fill = "sienna") +
  labs(x = "Gender of baby", y = "Maternal weight gain (lbs)", 
       title = "Maternal weight gain ") + 
  theme_minimal()+ 
  theme(
    plot.title = element_text(size = 20, hjust = 0.5),
    axis.title.x = element_text(size = 16),
    axis.title.y = element_text(size = 16)
  )

