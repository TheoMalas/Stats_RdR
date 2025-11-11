library(dplyr)
library(jsonlite)

source("psychotopia-r/util/utilities.R")


args <- commandArgs(trailingOnly = TRUE)
args_list <- extract_args_2(args)
molecule_name <- args_list$molecule_name
outputPath <- args_list$outputPath
Delta <- args_list$Delta
mode <- args_list$mode

################################################################################
#Loading and filter ############################################################
################################################################################

data = load_data()

data = data %>% filter(molecule_simp==molecule_name)

black_list_percent= black_list_percent_dict[molecule_name]
data = data %>% filter(!pourcentage %in% black_list_percent) %>% mutate(pourcentage = as.double(pourcentage))

data <- filter_data(data, args_list)

################################################################################
# Histogramme des puretés ######################################################
################################################################################
data_histo <- histo_data(data)

ratio_base_sel = ratio_base_sel_dict[molecule_name]



################################################################################
# Evolution of the purity ######################################################
################################################################################

# Génération de la liste des datasets pour la moyenne et la médiane
list_evol_mean <- datasets_list_evol(data, Delta, "moyenne")
labels_line_mean <- list_evol_mean[[1]]
datasets_list_mean <- list_evol_mean[[2]]

list_evol_med <- datasets_list_evol(data, Delta, "médiane")
labels_line_med <- list_evol_med[[1]]
datasets_list_med <- list_evol_med[[2]]

################################################################################
# Export en JSON ###############################################################
################################################################################
N=sum(data_histo$occurence)

json_obj <- list(
  labels = as.character(data_histo$classe),
  data = data_histo$occurence,
  labels_line_mean = labels_line_mean,
  datasets_line_mean = datasets_list_mean,
  labels_line_med = labels_line_med,
  datasets_line_med = datasets_list_med,
  ratio_base_sel = ratio_base_sel*100,
  count = N
)

print(outputPath)
# Créer le fichier JSON (on vérifie si les dossiers parents existent)
save_ouput_as_json(json_obj, outputPath)
