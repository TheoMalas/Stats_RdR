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


ggplot(df_pie, aes(x = "", y = somme, fill = categorie_label)) +
  geom_col(width = 1) +
  coord_polar(theta = "y") +
  labs(title = paste0("Répartition des échantillons par produit (%), N=",nrow(data))) +
  theme_void() +
  guides(fill = guide_legend(reverse = TRUE))
