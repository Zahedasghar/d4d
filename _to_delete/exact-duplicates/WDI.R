
library(tidyverse)
library(WDI)
library(ggthemes)
Data<-WDI(country="all",indicator = c("EG.ELC.ACCS.ZS", # access to electricity
                        "BN.CAB.XOKA.GD.ZS", # current account balance
                        "IC.BUS.DFRN.XQ", # ease of doing business
                        "FP.CPI.TOTL.ZG", # CPI
                        "FR.INR.LNDP"), # interest rate spread
          start = 1960, end = 2022) %>% as_tibble() 

Data <- WDI(country="all",indicator =   "FP.CPI.TOTL.ZG", # CPI
                                      start = 1960, end = 2022) %>% as_tibble() 

  
  
  
Data<-Data %>%
  rename(elecperpop = 5,
         cab = 6,
         edb = 7,
         cpi = 8,
         ratespread = 9) 
Data |> glimpse()

library(stevemisc)
Data %>%
  filter(country == "Pakistan") %>%
  mutate(cpiprop = cpi/100) %>% # going somewhere with this...
  ggplot()+aes(year, cpiprop)+ 
  theme_steve_web() + post_bg() +
  geom_bar(stat="identity", alpha=.8, fill="#619cff", color="black") +
  scale_x_continuous(breaks = seq(1960, 2020, by = 10)) +
  # Below is why I like proportions
  scale_y_continuous(labels = scales::percent) +
  labs(x = "", y = "Consumer Price Index (Annual %)",
       caption = "Data: International Monetary Fund, via {WDI}",
       title = "The Consumer Price Index (Annual %) in Pakistan, 1960-2020",
       subtitle = "International events,debt and currency devaluations will account for the spikes you see.")














WDIsearch(string='Export ', field='name', cache=NULL)

#Ahha, seems like "NE.EXP.GNFS.CD" (Export of Goods and Services) will do it...
NE.EXP.GNFS.CD
#(There are also codes for Export of Goods and Services for males and females separately)

df.exp=WDI(country="all", indicator=c("NE.EXP.GNFS.CD"), start=1980, end=2020)
df.exp |> filter(country=="Pakistan")


