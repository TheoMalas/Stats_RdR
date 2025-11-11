library(dplyr)
library(jsonlite)

source("psychotopia-r/util/utilities.R")

data = load_data()
data = data %>% filter(molecule_simp=="Speed")

black_list_percent=c("NQ","")
data = data %>% mutate(pourcentage = gsub(",", ".", sub(".*?(\\d+[\\.,]?\\d*)%.*", "\\1", pourcentage)))
data = data %>% filter(!pourcentage %in% black_list_percent) %>% mutate(pourcentage = as.double(pourcentage))

################################################################################
# Selection de la fenêtre de temps #############################################
################################################################################

args <- commandArgs(trailingOnly = TRUE)
args_list <- extract_args(args)
outputPath <- args_list$outputPath

data <- filter_data(data, args_list)

################################################################################
# Régreession pureté par région ################################################
################################################################################

#Création de l'objet JSON
json_obj <- regression_json_fe(data)

# Créer le fichier JSON (on vérifie si les dossiers parents existent)
save_ouput_as_json(json_obj, outputPath, auto_unbox=TRUE)