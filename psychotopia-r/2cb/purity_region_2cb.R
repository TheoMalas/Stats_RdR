library(dplyr)
library(jsonlite)

source("psychotopia-r/util/utilities.R")

data = load_data()
data = data %>% filter(molecule_simp=="2C-B")

black_list_percent=c("NQ","MDMA 25% + Kétamine 24% + Paracétamol 6%","Kétamine 20,56% équivalent base","")
grey_list_percent=list("6,14%" = 6.14, "2C-B 1.35% équivalent base" = 1.35) 

data <- data %>%
  filter(!pourcentage %in% black_list_percent, forme=="Poudre") %>%
  mutate(
    pourcentage = ifelse(
      pourcentage %in% names(grey_list_percent),
      unlist(grey_list_percent[pourcentage]),
      pourcentage
    ),
    pourcentage = sub(',','.',pourcentage),
    pourcentage = as.double(pourcentage)
  )

################################################################################
# Selection de la fenêtre de temps #############################################
################################################################################

args <- commandArgs(trailingOnly = TRUE)
args_list <- extract_args(args)
outputPath <- args_list$outputPath

data <- filter_data(data, args_list)

################################################################################
# Pureté par région ############################################################
################################################################################

data_dep_region = read.csv("departements-region-france.csv")

data <- data %>%
    mutate(departement = ifelse(nchar(departement)==1, paste0("0", departement), departement)) # nolint

data_sum_reg <- left_join(
  data,
  data_dep_region,
  by = c("departement" = "code_departement")
)%>%
group_by(nom_region) %>%
summarise(moyenne = mean(pourcentage, na.rm = TRUE))

################################################################################
# Export en JSON ###############################################################
################################################################################

json_obj <- as.list(setNames(data_sum_reg$moyenne, data_sum_reg$nom_region))

# Créer le fichier JSON (on vérifie si les dossiers parents existent)
save_ouput_as_json(json_obj, outputPath)