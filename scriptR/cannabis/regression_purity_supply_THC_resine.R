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
# Régression pour la pureté moyenne en fonction du type de fournisseur #########
################################################################################

#Création de l'objet JSON
json_obj <- regression_json(data)

# Créer le fichier JSON (on vérifie si les dossiers parents existent)
save_ouput_as_json(json_obj, outputPath, auto_unbox=TRUE)