library(DBI)
library(RMySQL)
library(tidyverse)
library(jsonlite)

user <- Sys.getenv("USER")
pwd <- Sys.getenv("PASSWORD")


con <- dbConnect(RMySQL::MySQL(),
                 dbname = "db_psycho_test",
                 host = "localhost",
                 port = 3306,
                 user = user,
                 password = pwd)

dbListTables(con)
data <- dbReadTable(con, "resultats_analyse_cleaned")
dbDisconnect(con)
data = data %>% mutate(date=as.Date(date))
data = data %>% filter(molecule_simp=="Cocaïne")

black_list_percent=c("NQ","NQ ","")
data = data %>% filter(!pourcentage %in% black_list_percent) %>% mutate(pourcentage = as.double(pourcentage))

################################################################################
# Selection de la fenêtre de temps et des familles #############################
################################################################################

#args <- commandArgs(trailingOnly = TRUE)

#date_debut <- as.Date(args[1])
#date_fin <- as.Date(args[2])
#data = data %>% 
#  filter(date>=date_debut & date<=date_fin)  # 2 dates NA à gérer

################################################################################
# Histogramme des produits de coupe ############################################
################################################################################

# Premier pie chart sur la présence de produit de coupe

data_presence_coupe = data %>% select(presencecoupe) %>%
  filter(presencecoupe==0 | presencecoupe==1) %>% 
  mutate(presencecoupe = ifelse(presencecoupe==1, "Produit(s) de coupe détecté(s)","Pas de produit de coupe détecté"))

df_pie_presence_coupe <- data_presence_coupe %>% 
  group_by(presencecoupe) %>%
  summarise(somme = n()) %>%
  mutate(
    pourcent = somme / sum(somme) * 100,
    categorie_label = paste0(presencecoupe, " (", round(pourcent, 1), "%)")
  ) %>%
  arrange(somme) %>%
  mutate(categorie_label = factor(categorie_label, levels = categorie_label))

df_fin_presence_coupe = df_pie_presence_coupe %>% select(categorie_label, pourcent)


################################################################################

# Second chart: histogramme avec barres à l'horizontale, une ligne par produit de coupe, rangé par ordre décroissant

liste_prod_coupe = c("paracetamol","cafeine","levamisole","phenacetine","hydroxyzine", "lidocaine","procaine")

data_coupe = data %>% filter(presencecoupe==1) %>%  select(all_of(liste_prod_coupe))

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

################################################################################

# Conversion au format souhaité
json_obj <- list(
  labels_presence_coupe = as.character(df_fin_presence_coupe$categorie_label),
  data_presence_coupe = df_fin_presence_coupe$pourcent,
  labels_prod_coupe = as.character(pourcentage_non_nuls$prod),
  data_prod_coupe = pourcentage_non_nuls$pourcentage_non_nul
)

# Export en JSON
write_json(json_obj, "output/coupe_cocaine.json", pretty = TRUE, auto_unbox = FALSE)

