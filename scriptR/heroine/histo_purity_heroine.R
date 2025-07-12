library(dplyr)
library(jsonlite)

source("scriptR/util/utilities.R")

data = load_data()
data = data %>% filter(molecule_simp=="Héroïne")

black_list_percent=c("NQ")
data = data %>% mutate(pourcentage = gsub(",", ".", sub(".*?(\\d+[\\.,]?\\d*)%.*", "\\1", pourcentage)))
data = data %>% filter(!pourcentage %in% black_list_percent) %>% mutate(pourcentage = as.double(pourcentage))

################################################################################
# Selection de la fenêtre de temps #############################################
################################################################################

args <- commandArgs(trailingOnly = TRUE)

data = filter_data(data,args)

Delta=15#as.numeric(args[3])

################################################################################
# Histogramme des puretés ######################################################
################################################################################
data_histo <- histo_data(data)

ratio_base_sel = 369.411/(369.411+35.453)



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
  ratio_base_sel = ratio_base_sel*100,
  count = N
)

# Créer les dossiers si nécessaire
dir.create("output/heroine", recursive = TRUE, showWarnings = FALSE)
# Export en JSON
write_json(json_obj, "output/heroine/histo_purity_heroine.json", pretty = TRUE, auto_unbox = FALSE)
