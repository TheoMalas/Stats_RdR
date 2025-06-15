library(DBI)
library(RMySQL)
library(tidyverse)
library(stargazer)

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
# Régression pour la pureté moyenne en fonction du type de fournisseur #########
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

data_reg=data %>%
  filter(! provenance %in% black_list) %>% 
  mutate(provenance = factor(provenance, levels = rev(unlist(df_pie %>% select(provenance)))))

model = lm(pourcentage ~ provenance, data=data_reg)
stargazer(model, type="text")