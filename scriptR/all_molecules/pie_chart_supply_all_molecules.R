library(DBI)
library(RMySQL)
library(dplyr)
library(jsonlite)
library(lubridate)

user <- Sys.getenv("USER")
pwd <- Sys.getenv("PASSWORD")
host <- Sys.getenv("HOST")
port <- as.integer(Sys.getenv("PORT"))


con <- dbConnect(RMySQL::MySQL(),
                 dbname = "db_psycho_test",
                 host = host,
                 port = port,
                 user = user,
                 password = pwd)

dbListTables(con)
data <- dbReadTable(con, "resultats_analyse_cleaned")
dbDisconnect(con)
data = data %>% mutate(date=as.Date(date))
################################################################################
# Selection de la fenêtre de temps et des familles #############################
################################################################################

args <- commandArgs(trailingOnly = TRUE)

date_debut <- as.Date(args[1])
date_fin <- as.Date(args[2])
data = data %>% 
  filter(date>=date_debut & date<=date_fin)  # 2 dates NA à gérer

if (length(args)>2){
  familles_vec <- args[3:length(args)]  # vecteur de familles
  print(familles_vec)
  data = data %>% filter(famille %in% familles_vec)
}
print(nrow(data))
################################################################################
# Pie chart sur mode d'approvisionnement #######################################
################################################################################

black_list=c("Produits de coupe et commentaires :","Revendeur habituel","Revendeur occasionnel","Nous ne détectons rien par HPLC / CCM","")

df_without_blacklist <- data %>%
  filter(!provenance %in% black_list)

df_pie <- df_without_blacklist %>% 
  group_by(provenance) %>%
  summarise(somme = n()) %>%
  mutate(
    pourcent = somme / sum(somme) * 100,
    categorie_label = paste0(provenance, " (", round(pourcent, 1), "%)")
  ) %>%
  arrange(somme) %>%
  mutate(categorie_label = factor(categorie_label, levels = categorie_label))


df_fin = df_pie %>% select(categorie_label, pourcent)

# Convertir en liste nommée
df_list <- setNames(as.list(df_fin$pourcent), df_fin$categorie_label)


################################################################################
# Évolution en prop sur l'approvisionnement ####################################
################################################################################


data_bimestre <- df_without_blacklist %>%
  mutate(
    month = month(date),
    bimestre = 1 + (month - 1) %/% 2,  # Diviser le mois pour obtenir un bimestre (1-2, 3-4, etc.)
    date_bimestre = floor_date(date, "year") + months((bimestre - 1) * 2)  # Calculer le premier jour du bimestre
  )

grille <- expand.grid(
  date_bimestre = unique(data_bimestre$date_bimestre),
  provenance = unique(data_bimestre$provenance)
)

# Calcul des proportions
data_evol_approvisionnement <- data_bimestre %>%
  filter(!provenance %in% black_list) %>%
  group_by(date_bimestre) %>%
  mutate(n_total = n()) %>%
  ungroup() %>%
  group_by(date_bimestre, provenance) %>%
  summarise(prop = n() / first(n_total), .groups = "drop") %>%
  right_join(grille, by = c("date_bimestre", "provenance")) %>%
  mutate(prop = ifelse(is.na(prop), 0, prop)) %>%
  arrange(date_bimestre, provenance)


order=data_evol_approvisionnement %>% 
  filter(date_bimestre==max(date_bimestre, na.rm=T)) %>%
  mutate(temp=prop) %>% 
  arrange(desc(temp)) %>% 
  select(provenance)

data_evol_approvisionnement <- data_evol_approvisionnement %>% 
  mutate(provenance = factor(provenance, levels = unlist(order)))

prov_vec=levels(data_evol_approvisionnement$provenance)

# Génération de la liste des datasets
datasets_list <- lapply(prov_vec, function(prov_i) {
  list(
    label = as.character(prov_i),
    data = (data_evol_approvisionnement %>% filter(provenance == prov_i))$prop,
    fill = "origin"
  )
})

################################################################################
# Export en JSON ###############################################################
################################################################################



N=nrow(df_without_blacklist)
# Conversion au format souhaité
json_obj <- list(
  labels = as.character(df_fin$categorie_label),
  data = df_fin$pourcent,
  labels_area = as.character(unique(data_evol_approvisionnement$date_bimestre)),
  datasets_area = datasets_list,
  count=N
)

write_json(json_obj, "output/pie_chart_supply_all_molecules.json", pretty = TRUE, auto_unbox = FALSE)




#N=nrow(df_pie_0)

#ggplot(df_pie, aes(x = "", y = somme, fill = categorie_label)) +
#  geom_col(width = 1) +
#  coord_polar(theta = "y") +
#  labs(title = paste0("Répartition des échantillons par mode d'approvisionnement (%), N=",N),
#       fill = "Mode d'approvisionnement") +
#  theme_void() +
#  guides(fill = guide_legend(reverse = TRUE))