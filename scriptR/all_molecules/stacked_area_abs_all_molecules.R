library(DBI)
library(RMySQL)
library(dplyr)
library(jsonlite)

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
  data = data %>% filter(famille %in% familles_vec)
}

################################################################################
# Évolution en absolu ##########################################################
################################################################################
lim = 15 #nombre de produits différents sur le diagramme

df_focus <- data %>%
  mutate(molecule_simp = ifelse(molecule_simp == "Problème", "Autres", molecule_simp)) %>%
  count(molecule_simp, name = "somme") %>%
  arrange(desc(somme)) %>%
  mutate(molecule_simp = ifelse(row_number() > lim, "Autres", molecule_simp)) %>%
  group_by(molecule_simp) %>%
  summarise(somme = sum(somme), .groups = "drop") %>%
  arrange(desc(somme)) %>%
  mutate(
    pourcent = somme / sum(somme) * 100,
    categorie_label = paste0(molecule_simp, " (", round(pourcent, 1), "%)")
  )

list_focus <- df_focus$molecule_simp

data_bimestre <- data %>%
  mutate(
    month = month(date),
    bimestre = 1 + (month - 1) %/% 2,  # Diviser le mois pour obtenir un bimestre (1-2, 3-4, etc.)
    date_bimestre = floor_date(date, "year") + months((bimestre - 1) * 2)  # Calculer le premier jour du bimestre
  )


data_evol_abs <- data_bimestre %>%
  mutate(molecule_simp = ifelse(molecule_simp %in% list_focus,molecule_simp,"Autres")) %>%
  group_by(date_bimestre, molecule_simp) %>%
  summarise(abs = n(), .groups = "drop") %>%
  complete(date_bimestre, molecule_simp, fill = list(abs = 0)) %>%
  arrange(date_bimestre, molecule_simp) %>% 
  filter(date_bimestre > "2023-04-01" & date_bimestre < max(date_bimestre, na.rm=T))

order=data_evol_abs %>% 
  filter(date_bimestre==max(date_bimestre, na.rm=T)) %>%
  mutate(temp=ifelse(molecule_simp=="Autres",-1,abs)) %>% 
  arrange(temp) %>% 
  select(molecule_simp)

data_evol_abs = data_evol_abs %>% mutate(molecule_simp = factor(molecule_simp, levels = unlist(order)))



#N=nrow(data_bimestre %>% filter(date_bimestre > "2023-04-01" & date_bimestre < max(date_bimestre, na.rm=T)))

#ggplot(data_evol_abs, aes(x = date_bimestre, y = abs, fill = molecule_simp)) +
#  geom_area(position = "stack", color = "white", size = 0.2) +
#  labs(
#    title = paste0("Évolution du nombre d'échantillons par produit attendu, N=",N),
#    x = "Bimestre",
#    y = "Nombre d'échantillons",
#    fill = "Produit attendu"
#  ) +
#  theme_minimal(base_size = 14)