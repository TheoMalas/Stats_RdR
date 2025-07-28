library(dplyr)
library(jsonlite)

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
# Nombre d'échantillons par région #############################################
################################################################################

data_dep_region = read.csv("departements-region-france.csv")
data_pop_region = read.csv("population_region_2025.csv", sep = ";") %>%
    mutate(Population = as.double(Population))

data <- data %>%
    mutate(departement = ifelse(nchar(departement)==1, paste0("0", departement), departement)) # nolint

data_sum_reg <-data %>%
    left_join(
    data_dep_region,
    by = c("departement" = "code_departement")
    ) %>%
    left_join(
    data_pop_region,
    by = c("nom_region" = "Région")
    )%>%
    group_by(nom_region) %>%
    summarise(occurence = n(),
              nb_ech_par_millions = n() / first(Population/1e6))

################################################################################
# Export en JSON ###############################################################
################################################################################
N=sum(data_sum_reg$occurence)


json_obj <- as.list(setNames(data_sum_reg$occurence, data_sum_reg$nom_region))


# Créer le fichier JSON (on vérifie si les dossiers parents existent)
save_ouput_as_json(json_obj, outputPath)