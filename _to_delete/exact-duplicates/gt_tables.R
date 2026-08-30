library(tidyverse)
library(gt)
library(gtExtras)
## Haemorrhaging
sector2<-c("power (2-decades)","gas (2-decades)","commodity operations (2-decades)",
           "PIA per year)",
           "PSMill per year","textile cartel(subsidies couple of yrs)", "fertilizer cartel(per year)")
Haemorrhaging<-c(2500,1500,800, 67,134,1000,150)  ## Losses to the economy 
hamo<-bind_cols(sector2,Haemorrhaging) ## Combining two columns
colnames(hamo)<-c("sector","Rs_in_bill") ## Rename the two columns
hamo|>gt()|> ## to have a title, subtitle, caption, theme, source
  tab_header(title = 'Haemorrhaging Pak Economy',
             subtitle = 'Exact sources of bleeding are known, but surgeons are missing') |> 
  tab_footnote(footnote = 'Public Sector Enterprizes (PSEs) debt now stands at Rs2 trillion'
  )|>gt_theme_pff()|>tab_source_note("Source : After the IMF by Dr. Farrukh Saleem")
## Loans obtained by Pakistan
trans<-c("United States","Multilaterals", "China", "International bonds", "IMF outstanding with 23 prog")
amount<-c(78.3,60,37,10,7.8)  
transf<-bind_cols(trans,amount)
colnames(transf)<-c("Transfusion provider", "Amount_bill_USD")
transf|>gt()|> tab_header(title = 'Blood transfusion: Pak Haemorrhaging Economy',
                          subtitle = 'No more blood available and urgent need to have surgery to stop haemorrhaging') |> 
  tab_footnote(footnote = 'Are there competent surgeons available?'
  )|>gt_theme_pff()|>tab_source_note("Source : After the IMF by Dr. Farrukh Saleem")


