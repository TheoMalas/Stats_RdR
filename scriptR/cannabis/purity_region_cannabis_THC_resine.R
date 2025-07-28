library(dplyr)
library(jsonlite)

source("scriptR/util/utilities.R")

data = load_data()
data = data %>% filter(molecule_simp=="Cannabis (THC/CBD)") %>% filter(forme=="Résine")

data = data %>% mutate(pourcentage = ifelse(pourcentage=="THC 46, CBD 2%, CBG 7%, CBN <1%","THC 46%, CBD 2%, CBG 7%, CBN <1%",pourcentage))
data = data %>% mutate(pourcentage = as.numeric(gsub(",", ".", sub(".*THC (.*?)\\%.*", "\\1", pourcentage))))
data = data %>% filter(! is.na(pourcentage))

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