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

df_fin = df_pie %>% select(categorie_label, pourcent)

# Convertir en liste nommée
df_list <- setNames(as.list(df_fin$pourcent), df_fin$categorie_label)

# Conversion au format souhaité
json_obj <- list(
  labels = as.character(df_fin$categorie_label),
  data = df_fin$pourcent
)

write_json(json_obj, "output/pie_chart_all_molecules.json", pretty = TRUE, auto_unbox = FALSE)

#ggplot(df_pie, aes(x = "", y = somme, fill = categorie_label)) +
#  geom_col(width = 1) +
#  coord_polar(theta = "y") +
#  labs(title = paste0("Répartition des échantillons par produit (%), N=",nrow(data))) +
#  theme_void() +
#  guides(fill = guide_legend(reverse = TRUE))
#ggsave("output/pie_chart_all_molecules.png")
