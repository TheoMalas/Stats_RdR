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
# Évolution en prop sur l'approvisionnement ####################################
################################################################################

data_bimestre <- data %>%
  mutate(
    month = month(date),
    bimestre = 1 + (month - 1) %/% 2,  # Diviser le mois pour obtenir un bimestre (1-2, 3-4, etc.)
    date_bimestre = floor_date(date, "year") + months((bimestre - 1) * 2)  # Calculer le premier jour du bimestre
  )

black_list=c("Produits de coupe et commentaires :","Revendeur habituel","Revendeur occasionnel","Nous ne détectons rien par HPLC / CCM","")


data_evol_approvisionnement <- data_bimestre %>%
  filter(!provenance %in% black_list) %>% 
  group_by(date_bimestre) %>%
  mutate(n_total = n()) %>%
  ungroup() %>%
  group_by(date_bimestre, provenance) %>%
  summarise(prop = n() / first(n_total), .groups = "drop") %>%
  complete(date_bimestre, provenance, fill = list(prop = 0)) %>%
  arrange(date_bimestre, provenance)

order=data_evol_approvisionnement %>% 
  filter(date_bimestre==max(date_bimestre, na.rm=T)) %>%
  mutate(temp=prop) %>% 
  arrange(temp) %>% 
  select(provenance)

data_evol_approvisionnement <- data_evol_approvisionnement %>% 
  mutate(provenance = factor(provenance, levels = unlist(order)))

N=nrow(data_bimestre %>%
         filter(provenance != "Produits de coupe et commentaires :" & !is.na(provenance)) %>%
         filter(date_bimestre > "2023-11-01" & date_bimestre < max(date_bimestre, na.rm=T))) 
