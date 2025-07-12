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
# Pie chart sur le produit #####################################################
################################################################################
lim = 15 #nombre de produits différents sur le diagramme

df_pie <- data %>% 
  mutate(molecule_simp  = ifelse(molecule_simp == "Problème", "Autres",molecule_simp))


df_pie <- df_pie %>%
  group_by(molecule_simp) %>%
  summarise(somme = n())%>%
  arrange(desc(somme)) %>% 
  mutate(molecule_simp = ifelse(row_number()>lim, "Autres",molecule_simp)) %>% 
  group_by(molecule_simp) %>%
  summarise(somme = sum(somme)) %>%
  arrange(desc(somme))%>% 
  mutate(
    pourcent = somme / sum(somme) * 100,
    categorie_label = paste0(molecule_simp, " (", round(pourcent, 1), "%)")
  )

df_pie = df_pie %>% 
  mutate(temp=ifelse(molecule_simp=="Autres",-1,somme)) %>% 
  arrange(temp) %>% 
  mutate(categorie_label = factor(categorie_label, levels = categorie_label))

N=nrow(data)

df_fin = df_pie %>% select(categorie_label, pourcent)

# Convertir en liste nommée
df_list <- setNames(as.list(df_fin$pourcent), df_fin$categorie_label)


################################################################################
# Area-stacked chart ###########################################################
################################################################################
list_focus <- df_pie$molecule_simp


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


data_evol_abs <- data_bimestre %>%
  mutate(molecule_simp = ifelse(molecule_simp %in% list_focus,molecule_simp,"Autres")) %>%
  group_by(date_bimestre, molecule_simp) %>%
  summarise(abs = n(), .groups = "drop") %>%
  right_join(grille, by = c("date_bimestre", "molecule_simp")) %>%
  mutate(abs = ifelse(is.na(abs), 0, abs)) %>%
  arrange(date_bimestre, molecule_simp)

order=data_evol_abs %>% 
  filter(date_bimestre==max(date_bimestre, na.rm=T)) %>%
  mutate(temp=ifelse(molecule_simp=="Autres",-1,abs)) %>% 
  arrange(desc(temp)) %>% 
  select(molecule_simp)

data_evol_abs = data_evol_abs %>% mutate(molecule_simp = factor(molecule_simp, levels = unlist(order)))

prod_vec=levels(data_evol_abs$molecule_simp)

# Génération de la liste des datasets
datasets_list <- lapply(prod_vec, function(prod_i) {
  list(
    label = as.character(prod_i),
    data = (data_evol_abs %>% filter(molecule_simp == prod_i))$abs,
    fill = "origin"
  )
})

################################################################################
# Export en JSON ###############################################################
################################################################################


# Conversion au format souhaité
json_obj <- list(
  labels = as.character(df_fin$categorie_label),
  data = df_fin$pourcent,
  labels_area = as.character(unique(data_evol_abs$date_bimestre)),
  datasets_area = datasets_list,
  count=N
)

# Créer les dossiers si nécessaire
dir.create("output/all", recursive = TRUE, showWarnings = FALSE)

write_json(json_obj, "output/all/pie_chart_all_molecules.json", pretty = TRUE, auto_unbox = FALSE)

#ggplot(df_pie, aes(x = "", y = somme, fill = categorie_label)) +
#  geom_col(width = 1) +
#  coord_polar(theta = "y") +
#  labs(title = paste0("Répartition des échantillons par produit (%), N=",nrow(data))) +
#  theme_void() +
#  guides(fill = guide_legend(reverse = TRUE))
#ggsave("output/pie_chart_all_molecules.png")
