library(dplyr)
library(jsonlite)

source("scriptR/util/utilities.R")

data = load_data()
data = data %>% filter(molecule_simp=="Cannabis (THC/CBD)") %>% filter(forme=="Herbe")

data = data %>% mutate(pourcentage = ifelse(pourcentage=="THC 46, CBD 2%, CBG 7%, CBN <1%","THC 46%, CBD 2%, CBG 7%, CBN <1%",pourcentage))
data = data %>% mutate(pourcentage =  as.numeric(gsub(",", ".", sub(".*THC (.*?)\\%.*", "\\1", pourcentage))))
data = data %>% filter(! is.na(pourcentage))

################################################################################
# Selection de la fenêtre de temps #############################################
################################################################################

args <- commandArgs(trailingOnly = TRUE)

data_delta_outputPath_list = filter_data(data,args)

data=data_delta_outputPath_list[[1]]
Delta=data_delta_outputPath_list[[2]]
ouputPath=data_delta_outputPath_list[[3]]
################################################################################
# Histogramme des puretés ######################################################
################################################################################
data_histo <- histo_data(data)



################################################################################
# Evolution of the purity ######################################################
################################################################################

# Génération de la liste des datasets
list_evol <- datasets_list_evol(data, Delta)
labels_line <- list_evol[[1]]
datasets_list <- list_evol[[2]]

################################################################################
# Export en JSON ###############################################################
################################################################################
N=sum(data_histo$occurence)

json_obj <- list(
  labels = as.character(data_histo$classe),
  data = data_histo$occurence,
  labels_line = labels_line,
  datasets_line = datasets_list,
  count = N
)

# Créer le fichier JSON (on vérifie si les dossiers parents existent)
write_json_perso(json_obj, outputPath)