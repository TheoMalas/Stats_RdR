library(dplyr)
library(jsonlite)
library(lubridate)

source("psychotopia-r/util/utilities.R")

data = load_data()
data = data %>% filter(molecule_simp=="Héroïne")

black_list_percent=c("NQ")
data = data %>% mutate(pourcentage = gsub(",", ".", sub(".*?(\\d+[\\.,]?\\d*)%.*", "\\1", pourcentage)))
data = data %>% filter(!pourcentage %in% black_list_percent) %>% mutate(pourcentage = as.double(pourcentage))

################################################################################
# Selection de la fenêtre de temps #############################################
################################################################################

args <- commandArgs(trailingOnly = TRUE)
args_list <- extract_args(args)
outputPath <- args_list$outputPath

data <- filter_data(data, args_list)

################################################################################
# Histogramme des produits de coupe ############################################
################################################################################

# First chart: histogramme avec barres à l'horizontale, une ligne par produit de coupe, rangé par ordre décroissant

liste_prod_coupe = c("X6MAM","noscapine","papaverine","morphine")

data_coupe = data %>% filter(presencecoupe==1) %>%  select(all_of(liste_prod_coupe),date)

data_coupe<- data_coupe %>%
  rename("6-MAM" = X6MAM, 
         "Noscapine" = noscapine,
         "Papavérine" = papaverine,
         "Morphine" = morphine)

pourcentage_non_nuls <- data.frame(
  prod = character(),
  pourcentage_non_nuls = numeric()
)

for (col in names(data_coupe)) {
  vec <- data_coupe[[col]]
  if (is.numeric(vec)) {
    pourcentage <- mean(vec != 0, na.rm = TRUE) * 100
    pourcentage_non_nuls <- rbind(pourcentage_non_nuls,
                                  data.frame(prod = col,
                                             pourcentage_non_nul = round(pourcentage, 2)))
  }
}

# Tri décroissant
pourcentage_non_nuls <- pourcentage_non_nuls %>%
  arrange(desc(pourcentage_non_nul))


################################################################################################################

data_bimestre <- data_coupe %>%
  mutate(
    month = month(date),
    bimestre = 1 + (month - 1) %/% 2,  # Diviser le mois pour obtenir un bimestre (1-2, 3-4, etc.)
    date_bimestre = floor_date(date, "year") + months((bimestre - 1) * 2)  # Calculer le premier jour du bimestre
  )


cols_coupe_prod <- setdiff(names(data_bimestre), c("date", "date_bimestre", "month", "bimestre"))

# Étape 2 : Boucle pour chaque nom
evol_coupe <- lapply(cols_coupe_prod, function(coupe_prod) {
  data_bimestre %>%
    group_by(date_bimestre) %>%
    summarise(
      total_dates = n(),
      dates_present = sum(!!sym(coupe_prod) > 0, na.rm = TRUE),
      pourcentage_presence = 100 * dates_present / total_dates,
      coupe_prod = coupe_prod,
      .groups = "drop"
    )
}) %>%
  bind_rows()


order=evol_coupe %>% 
  filter(date_bimestre==max(date_bimestre, na.rm=T)) %>%
  arrange(desc(pourcentage_presence)) %>% 
  select(coupe_prod)

evol_coupe <- evol_coupe %>% 
  mutate(coupe_prod = factor(coupe_prod, levels = unlist(order)))


prod_vec=levels(evol_coupe$coupe_prod)

# Génération de la liste des datasets
datasets_list <- lapply(prod_vec, function(prod_i) {
  list(
    label = as.character(prod_i),
    data = (evol_coupe %>% filter(coupe_prod == prod_i))$pourcentage_presence,
    fill = "origin"
  )
})





################################################################################
N=nrow(data)
# Conversion au format souhaité
json_obj <- list(
  labels_prod_coupe = as.character(pourcentage_non_nuls$prod),
  data_prod_coupe = pourcentage_non_nuls$pourcentage_non_nul,
  labels_area = as.character(unique(evol_coupe$date_bimestre)),
  datasets_area = datasets_list,
  count = N
)

# Créer le fichier JSON (on vérifie si les dossiers parents existent)
save_ouput_as_json(json_obj, outputPath)

