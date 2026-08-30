# install.packages("devtools")
# 
# devtools::install_github("Oluwayomi-Olaitan/wdiexplorer")

library(wdiexplorer)

## timeout for WDI API calls

options(timeout=600)



WDI::WDIsearch("air pollution")

# pm_data <- get_wdi_data(indicator = "EN.ATM.PM25.MC.M3")

plot_missing(wdi_data = pm_data, group_var = "region")


get_valid_data(pm_data)


pm_diagnostic_metrics_group <- add_group_info(
  metric_summary = pm_diagnostic_metrics,
  pm_data
)


plot_metric_distribution(
  metric_summary = pm_diagnostic_metrics_group, 
  metric_var = "linearity",
  colour_var = "region"
)


plot_metric_partition(
  metric_summary = pm_diagnostic_metrics_group,
  metric_var = "sil_width",
  group_var = "region"
)


plot_data_trajectories(pm_data, group_var = "region")


plot_data_trajectories(
  pm_data, 
  metric_summary = pm_diagnostic_metrics, 
  metric_var = "country_avg_dist"
)
