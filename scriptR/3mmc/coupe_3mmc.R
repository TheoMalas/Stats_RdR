library(dplyr)
library(jsonlite)
library(stringr)
library(lubridate)


source("scriptR/util/utilities.R")

data = load_data()
data = data %>% filter(molecule_simp=="3-MMC")

black_list_percent=c("NQ","")
data = data %>% 
 filter(!pourcentage %in% black_list_percent) %>%
 mutate(pourcentage = as.double(pourcentage))%>%
 select(date, coupe)

################################################################################
# Selection de la fenêtre de temps #############################################
################################################################################

args <- commandArgs(trailingOnly = TRUE)
args_list <- extract_args(args)
outputPath <- args_list$outputPath

data <- filter_data(data, args_list)

################################################################################
# Histogramme sur les produits de coupe ########################################
################################################################################

white_list <- c("2MMC", "3CMC", "4CMC", "4MMC", "4BMC", "2CMC", "MDMA", "NEP", "4MEC", "DMBDP", "4DMMC")
data_coupe <- data %>%
  mutate(
    coupe = gsub("-", "", coupe),
    coupe = lapply(
      str_extract_all(coupe, "\\b[A-Z0-9]+\\b"),
      function(x){
        x <- x[!grepl("^[0-9]+$", x)]        # remove pure numbers
        x <- intersect(x, white_list)        # keep only allowed terms
      }
    )
  ) %>%
  subset(sapply(coupe, length) > 0)          # keep rows with at least one match

# 3ème graphique pour l'évolution temporelle
data_bimestre <- data_coupe %>%
  mutate(
    month = month(date),
    bimestre = 1 + (month - 1) %/% 2,  # Diviser le mois pour obtenir un bimestre (1-2, 3-4, etc.)
    date_bimestre = floor_date(date, "year") + months((bimestre - 1) * 2)  # Calculer le premier jour du bimestre
  )

# Un échantillon contient des traces de Kétamine et de cocaine mais on va le négliger
coupe_bim <- data.frame(
  molecule = unlist(data_bimestre$coupe),
  bimester = rep(data_bimestre$date_bimestre, sapply(data_bimestre$coupe, length))
)

# Occurence de chaque produit de coupe par bimestre
evol_coupe <- as.data.frame(table(coupe_bim$molecule, coupe_bim$bimester))%>%
 rename(coupe_prod = Var1, date_bimestre = Var2, occurence = Freq) %>%
 group_by(date_bimestre) %>%
 mutate(pourcentage_presence = occurence/sum(occurence)*100)

prod_vec=levels(evol_coupe$coupe_prod)

# Génération de la liste des datasets
datasets_list <- lapply(prod_vec, function(prod_i) {
  list(
    label = as.character(prod_i),
    data = (evol_coupe %>% filter(coupe_prod == prod_i))$pourcentage_presence,
    fill = "origin"
  )
})

# 2ème graphique : histogramme des produits de coupe sur toute la période sélectionnée
coupe_occu <- evol_coupe %>%
    group_by(coupe_prod) %>%
    summarise(occurence = sum(occurence))
coupe_occu <- coupe_occu %>%
 mutate(prop = occurence/sum(occurence)) %>%
 arrange(desc(prop))


################################################################################
# Export en JSON ###############################################################
################################################################################

N=nrow(data)
# Conversion au format souhaité
json_obj <- list(
  labels_presence_coupe = c("Autre(s) produit(s) détecté(s)","Que de la 3-MMC détectée"),
  data_presence_coupe = c(nrow(data_coupe)/N, 1-nrow(data_coupe)/N),
  labels_prod_coupe = as.character(coupe_occu$coupe_prod),
  data_prod_coupe = coupe_occu$prop,
  labels_area = as.character(unique(evol_coupe$date_bimestre)),
  datasets_area = datasets_list,
  count = N
)

# Créer le fichier JSON (on vérifie si les dossiers parents existent)
save_ouput_as_json(json_obj, outputPath)