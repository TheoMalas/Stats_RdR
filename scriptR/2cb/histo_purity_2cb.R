library(dplyr)
library(jsonlite)

source("scriptR/util/utilities.R")

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
Delta <- args_list$Delta
mode <- args_list$mode

data <- filter_data(data, args_list)
################################################################################
# Histogramme des puretés ######################################################
################################################################################
data_histo <- histo_data(data)

ratio_base_sel = 260.13/(260.13+35.453)



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
  ratio_base_sel = ratio_base_sel*100,
  count = N
)

# Créer le fichier JSON (on vérifie si les dossiers parents existent)
save_ouput_as_json(json_obj, outputPath)
