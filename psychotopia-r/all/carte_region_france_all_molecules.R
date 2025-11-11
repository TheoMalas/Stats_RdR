library(dplyr)
library(jsonlite)

source("psychotopia-r/util/utilities.R")

data = load_data()
################################################################################
# Selection de la fenêtre de temps #############################################
################################################################################

args <- commandArgs(trailingOnly = TRUE)
args_list <- extract_args(args)
outputPath <- args_list$outputPath
mode <- args_list$mode

data <- filter_data(data, args_list)

################################################################################
# Nombre d'échantillons par région #############################################
################################################################################

data_dep_region = read.csv("departements-region-france.csv")

data <- data %>%
    filter(departement != "0") %>%
    mutate(departement = ifelse(nchar(departement)==1, paste0("0", departement), departement))

data_sum_reg <-data %>%
    left_join(
    data_dep_region,
    by = c("departement" = "code_departement")
    )

if (mode=="abs"){
    data_sum_reg <- data_sum_reg %>%
        group_by(nom_region) %>%
        summarise(occurence = n())
}

if (mode=="prop"){
    data_pop_region = read.csv("population_region_2025.csv", sep = ";") %>%
        mutate(Population = as.double(Population))
    
    data_sum_reg <- data_sum_reg%>%
        left_join(
        data_pop_region,
        by = c("nom_region" = "Région")
        )%>%
        group_by(nom_region) %>%
        summarise(occurence = n() / first(Population/1e6)) #nombre d'échantillons par million d'habitants
}

################################################################################
# Export en JSON ###############################################################
################################################################################

json_obj <- as.list(setNames(data_sum_reg$occurence, data_sum_reg$nom_region))


# Créer le fichier JSON (on vérifie si les dossiers parents existent)
save_ouput_as_json(json_obj, outputPath)