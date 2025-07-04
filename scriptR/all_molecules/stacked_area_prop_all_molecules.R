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
  data = data %>% filter(famille %in% familles_vec)
}


################################################################################
# Évolution des pourcentages ###################################################
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

grille <- expand.grid(
  date_bimestre = unique(data_bimestre$date_bimestre),
  molecule_simp = unique(c(list_focus, "Autres"))
)

data_evol <- data_bimestre %>%
  mutate(molecule_simp = ifelse(molecule_simp %in% list_focus, molecule_simp, "Autres")) %>%
  group_by(date_bimestre) %>%
  mutate(n_total = n()) %>%
  ungroup() %>%
  group_by(date_bimestre, molecule_simp) %>%
  summarise(prop = n() / first(n_total), .groups = "drop") %>%
  right_join(grille, by = c("date_bimestre", "molecule_simp")) %>%
  mutate(prop = ifelse(is.na(prop), 0, prop)) %>%
  arrange(date_bimestre, molecule_simp)


order=data_evol %>% 
  filter(date_bimestre==max(date_bimestre, na.rm=T)) %>%
  mutate(temp=ifelse(molecule_simp=="Autres",-1,prop)) %>% 
  arrange(desc(temp)) %>% 
  select(molecule_simp)

data_evol <- data_evol %>% 
  mutate(molecule_simp = factor(molecule_simp, levels = unlist(order)))

N=nrow(data)

prod_vec=levels(data_evol$molecule_simp)

# Génération de la liste des datasets
datasets_list <- lapply(prod_vec, function(prod_i) {
  list(
    label = as.character(prod_i),
    data = (data_evol %>% filter(molecule_simp == prod_i))$prop,
    fill = "origin"
  )
})

# Objet JSON final
json_obj <- list(
  labels_area = as.character(unique(data_evol$date_bimestre)),
  datasets_area = datasets_list,
  count = N
)

write_json(json_obj, "output/stacked_area_prop_all_molecules.json", pretty = TRUE, auto_unbox = TRUE)

#ggplot(data_evol, aes(x = date_bimestre, y = prop, fill = molecule_simp)) +
#  geom_area(position = "stack", color = "white", size = 0.2) +
#  scale_y_continuous(labels = scales::percent_format()) +
#  labs(
#    title = paste0("Évolution des parts par produit attendu, N=",N),
#    x = "Bimestre",
#    y = "Part relative",
#    fill = "Produit attendu"
#  ) +
#  theme_minimal(base_size = 14)

#ggsave("stacked_area_prop.pdf")