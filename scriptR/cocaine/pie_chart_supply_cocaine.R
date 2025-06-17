library(DBI)
library(RMySQL)
library(tidyverse)

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

################################################################################
# Selection de la fenêtre de temps et des familles #############################
################################################################################

args <- commandArgs(trailingOnly = TRUE)

date_debut <- as.Date(args[1])
date_fin <- as.Date(args[2])
data = data %>% 
  filter(date>=date_debut & date<=date_fin)  # 2 dates NA à gérer


################################################################################
# Pie chart sur mode d'approvisionnement #######################################
################################################################################

black_list=c("Produits de coupe et commentaires :","Revendeur habituel","Revendeur occasionnel","Nous ne détectons rien par HPLC / CCM","")

df_pie_0 <- data %>%
  filter(!provenance %in% black_list)

df_pie <- df_pie_0 %>% 
  group_by(provenance) %>%
  summarise(somme = n()) %>%
  mutate(
    pourcent = somme / sum(somme) * 100,
    categorie_label = paste0(provenance, " (", round(pourcent, 1), "%)")
  ) %>%
  arrange(somme) %>%
  mutate(categorie_label = factor(categorie_label, levels = categorie_label))

N=nrow(df_pie_0)

ggplot(df_pie, aes(x = "", y = somme, fill = categorie_label)) +
  geom_col(width = 1) +
  coord_polar(theta = "y") +
  labs(title = paste0("Répartition des échantillons par mode d'approvisionnement (%), N=",N),
       fill = "Mode d'approvisionnement") +
  theme_void() +
  guides(fill = guide_legend(reverse = TRUE))