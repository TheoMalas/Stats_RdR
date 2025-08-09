library(dplyr)
library(jsonlite)
library(lubridate)

source("scriptR/util/utilities.R")

data = load_data()

################################################################################
# Selection de la fenêtre de temps #############################################
################################################################################

args <- commandArgs(trailingOnly = TRUE)
args_list <- extract_args(args)
outputPath <- args_list$outputPath

data <- filter_data(data, args_list)

################################################################################
# Diagramme produit consommé ###################################################
################################################################################

data_conso = data %>%
  filter(consomme==0 | consomme==1) %>% 
  mutate(consomme = ifelse(consomme==1, "Déjà consommé","Pas encore consommé")) %>%
  group_by(consomme) %>%
  summarise(somme = n()) %>%
  mutate(
    pourcent = somme / sum(somme) * 100,
    categorie_label = paste0(consomme, " (", round(pourcent, 1), "%)")
  ) %>%
  arrange(desc(categorie_label)) %>%
  mutate(categorie_label = factor(categorie_label, levels = categorie_label))

data_conso_fin = data_conso %>% select(categorie_label, pourcent)

################################################################################
# Export en JSON ###############################################################
################################################################################

# Conversion au format souhaité
json_obj <- list(
  labels = as.character(data_conso_fin$categorie_label),
  data = data_conso_fin$pourcent
)


# Créer le fichier JSON (on vérifie si les dossiers parents existent)
save_ouput_as_json(json_obj, outputPath)
