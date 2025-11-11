library(dplyr)
library(jsonlite)

source("psychotopia-r/util/utilities.R")

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
Delta <- args_list$Delta
mode <- args_list$mode

data <- filter_data(data, args_list)
################################################################################
# Histogramme des puretés ######################################################
################################################################################
data_histo <- histo_data(data)



################################################################################
# Evolution of the purity ######################################################
################################################################################

# Génération de la liste des datasets
list_evol <- datasets_list_evol(data, Delta, mode)
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
save_ouput_as_json(json_obj, outputPath)