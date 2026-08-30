library(haven) ## Package required to upload STATA/SPSS data 
library(kableExtra) ## For better tabular presentations
library(tidyverse) 

library(janitor)
library(gt)
library(gtExtras)
require(gtsummary)

caschool <- read_dta("caschool.dta") ## Read Data


caschool |> clean_names()-> caschool

colnames(caschool)
## Save as csv
# write_csv(caschool, file="caschool.csv")

## Save as SPSS 

# write_sav(caschool, file="caschool.sav")

## Save as STAT

# write_dta(caschool, file="caschool.dta")

caschool ## First 10 rows of a tibble

head(caschool) ## Top 6 rows

caschool |> glimpse()  ## To get an overview of data

colnames(caschool)

## Select to retain few needed columns 
caschool |> select(testscr, str, avginc, el_pct, meal_pct, 
                   calw_pct) -> caschool_sm ## To select only required variables

caschool_sm |> select(testscr, str) |> summarise(avg=mean(testscr),sd=sd(testscr))


caschool_sm |> summarise(across(where(is.numeric),min,na.rm=TRUE))

caschool_sm |> glimpse()

library(dataxray)

caschool_sm |> make_xray() |>  view_xray()




caschool_sm |> gt_plt_summary() |> 
  tab_header("Summary statistics of caschool small data") |> 
  gt_theme_pff()## summary and plot

library(skimr)
caschool_sm |> skim()

library(modelsummary)  ## For presenting regression results in nice tables
library(rstatix)  ## For testing of hypothesis 

#library(help=rstatix) 

caschool_sm <- caschool_sm |> mutate(elq1 = ifelse(el_pct <= 1.9, 1, 0))

caschool_sm <-
  caschool_sm |> mutate(elq2 = ifelse(el_pct >= 1.9 &
                                        el_pct < 8.8, 1, 0))

caschool_sm <-
  caschool_sm |> mutate(elq3 = ifelse(el_pct >= 8.8 & el_pct < 23, 1, 0))

caschool_sm <- caschool_sm |> mutate(elq4 = ifelse(el_pct >= 23, 1, 0))

caschool_sm <- caschool_sm |>   mutate(str_20 = ifelse(str < 20, 1, 0))


caschool_sm |> mutate(elpct = case_when(el_pct<=1.9 ~ "low",
                                        el_pct >=1.9 & el_pct <8.8  ~ "medium",
                                        el_pct >=8.8 & el_pct <23  ~ "high",
                                        el_pct >23~"very high")) -> caschool_sm
caschool_sm


#testscore with class size less than 20 vs those testscr class size >20

## Testing of hypothesis

overall <- caschool_sm |> t_test(testscr ~ str_20, var.equal = T)


el_1.9 <-
  caschool_sm |> filter(elq1 == 1) |> t_test(testscr ~ str_20, var.equal =
                                               T)

el_8.8<-caschool_sm |> filter(elq2==1) |> t_test(testscr~str_20,var.equal=T) 

el_23<-caschool_sm |> filter(elq3==1) |> t_test(testscr~str_20,var.equal=T) 

el_gr23<-caschool_sm |> filter(elq4==1) |> t_test(testscr~str_20,var.equal=T)




table_6.1 <- bind_rows(overall, el_1.9, el_8.8, el_23, el_gr23)



df_tbl<- as_tibble(table_6.1) 

ggplot(caschool_sm) +aes(x=str,y=testscr)+geom_point()



caschool_sm |> mutate(elpct=as_factor(elpct)) -> caschool_sm

ggplot(caschool_sm) +aes(x=str,y=testscr, color=elpct)+geom_point()+  facet_grid(~elpct)


caschool_sm |> filter(elpct=="high", str>19)



ggplot(caschool_sm)+aes(x=str,y=testscr)+geom_point()+
  geom_smooth(method='lm')



df_tbl 

df_tbl<-df_tbl |> select(-".y.") 

df_tbl |> gt() |> fmt_number(columns=2:6,decimals=3)

df_tbl$statistic <- round(df_tbl$statistic, 2) 

df_tbl$p <- round(df_tbl$p, 3)

df_tbl 

library(broom)

lm(testscr ~ str, data = caschool_sm)




tidy(lm(testscr~str,data=caschool_sm))

models <- list(
  mod1 <- lm(testscr ~ str, data = caschool_sm),
  mod2 <- lm(testscr ~ str + el_pct, data = caschool_sm)
)

mod1 <- lm(testscr ~ str, data = caschool_sm)


mod2 <- lm(testscr ~ str + el_pct, data = caschool_sm)

modelsummary(models, fmt=2)

modelsummary(
  models,
  fmt = 2,
  estimate  = c(
    "{estimate} ({std.error}){stars}"),
  statistic = NULL)

# estimate the multiple regression model

library(car) 

model <- lm(testscr ~ str + el_pct + meal_pct, data = caschool_sm)

# execute the function on the model object and provide both linear restrictions 
# to be tested as strings

linearHypothesis(model, c("str=0", "el_pct=0"))


linearHypothesis(model,c('el_pct+meal_pct=1'))

## Correlations 

library(corrr) 

caschool_sm |> select(testscr, str, el_pct, meal_pct, calw_pct) |>
  correlate() 

## gt, gtsummary, gtExtras

caschool_sm |> select(testscr, str, el_pct, meal_pct, calw_pct) |>
  correlate()  |> gt() |> fmt_number(columns = 2:6, decimals = 2)



## title of table
caschool_sm |> select(testscr, str, el_pct, meal_pct, calw_pct) |>
  correlate()  |> gt()|> fmt_number(columns = 2:6, decimals = 2) |> 
  tab_header(title="Correlation between variables") |> gt_theme_guardian()

## theme of a table
library(gtExtras)

caschool_sm |> select(testscr, str, el_pct, meal_pct, calw_pct) |>
  correlate()  |> gt()|> fmt_number(columns = 2:6, decimals = 2) |> 
  tab_header(title="Correlation between variables") |> 
  gt_theme_pff()

## Correlation plot plot 
caschool_sm |> select(testscr, str, el_pct, meal_pct, calw_pct) |>
  correlate() |>
  autoplot() + geom_text(aes(label = round(r, digits = 2)), size = 2)


## Plots (Arrange plots easily)

p1 <- ggplot(caschool_sm) + aes(x = el_pct, y = testscr) + geom_point() +
  labs(x = "percent", y = "Test Score")

p2 <- ggplot(caschool_sm) + aes(x = meal_pct, y = testscr) + geom_point() +
  labs(x = "percent", y = "Test Score")

p3 <- ggplot(caschool_sm) + aes(x = calw_pct, y = testscr) + geom_point() +
  labs(x = "percent", y = "Test Score") +geom_smooth()


## Plots in a row

library(patchwork)

p1

p2

p3 

p1/p2/p3

(p1+p2)/p3

## Regression Models

m1 <- lm(testscr ~ str, data = caschool_sm)
m2 <- lm(testscr ~ str + el_pct, data = caschool_sm)
m3 <- lm(testscr ~ str + el_pct + meal_pct, data = caschool_sm)
m4 <- lm(testscr ~ str + el_pct + calw_pct, data = caschool_sm)
m5 <- lm(testscr ~ str + el_pct + meal_pct + calw_pct, data = caschool_sm)
library(fixest)
library(modelsummary)
models<-list(m1,m2,m3,m4,m5)

swirl()

library(huxtable)
#etable(m1,m2,m3,m4)
modelsummary(models,estimate = "{estimate}{stars}", output="huxtable")
#modelsummary(models, fmt=4)
#modelsummary(models,
#            statistic = "{std.error} ({p.value})")
#modelsummary(models,
#            estimate = "{estimate}{stars}",
#           gof_omit = ".*")


