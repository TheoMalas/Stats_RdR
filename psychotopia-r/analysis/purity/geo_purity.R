analysis_description <- list(
  name = "geo_purity",
  help = "Affiche le résumé statistique du dataset",
  args = list()
)

analysis_function <- function(data, args) {

  black_list_percent <- c("NQ", "NA", "", "ND")
  data = data %>% mutate(pourcentage = gsub(",", ".", sub(".*?(\\d+[\\.,]?\\d*)%.*", "\\1", pourcentage)))
  data <- data %>%mutate(pourcentage_num = as.double(ifelse(grepl("^[0-9.]+$", pourcentage), pourcentage, NA)))
  data = data %>% filter(!pourcentage %in% black_list_percent) %>% mutate(pourcentage = as.double(pourcentage))

  data_dep_region = read.csv("../departements-region-france.csv")

  data <- data %>%
      mutate(departement = ifelse(nchar(departement)==1, paste0("0", departement), departement))

  data_sum_reg <- left_join(
    data,
    data_dep_region,
    by = c("departement" = "code_departement")
  )%>%
  group_by(nom_region) %>%
  summarise(moyenne = mean(pourcentage, na.rm = TRUE))

  as.list(setNames(data_sum_reg$moyenne, data_sum_reg$nom_region))
}
