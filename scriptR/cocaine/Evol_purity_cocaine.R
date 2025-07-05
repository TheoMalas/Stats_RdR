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
data = data %>% filter(molecule_simp=="Cocaïne")

black_list_percent=c("NQ","NQ ","")
data = data %>% filter(!pourcentage %in% black_list_percent) %>% mutate(pourcentage = as.double(pourcentage))

################################################################################
# Selection de la fenêtre de temps et des familles #############################
################################################################################

args <- commandArgs(trailingOnly = TRUE)

date_debut <- as.Date(args[1])
date_fin <- as.Date(args[2])
data = data %>% 
  filter(date>=date_debut & date<=date_fin)  # 2 dates NA à gérer


################################################################################
# Evolution of the purity ######################################################
################################################################################
ratio_base_sel = 303.352/(303.352+35.453) 

Delta=15

data_cocaine_lis <- data %>%
  arrange(date) %>%
  mutate(moyenne_glissante = sapply(date, function(d) {
    mean(pourcentage[date >= d - Delta & date <= d + Delta], na.rm = TRUE)
  }))%>%
  filter(date >= min(date) + Delta, date <= max(date) - Delta) %>% 
  select(date,moyenne_glissante)

# Génération de la liste des datasets
datasets_list <-list(list(
    label = "",
    data = data_cocaine_lis$moyenne_glissante,
    fill = "false"
  ))

N=nrow(data)

# Objet JSON final
json_obj <- list(
  labels_line = as.character(data_cocaine_lis$date),
  datasets_line = datasets_list,
  ratio_base_sel = ratio_base_sel*100,
  count = N
)

# Export en JSON
write_json(json_obj, "output/evol_purity_cocaine.json", pretty = TRUE, auto_unbox = TRUE)

#ggplot(data_cocaine_lis, aes(x = date, y = moyenne_glissante)) +
#  geom_point() +
#  geom_line() +
#  labs(x = "Date",
#       y = "Pureté de la cocaïne (équivalent base) en %",
#       title = paste0("Évolution lissée sur 1 mois de la pureté de la cocaïne, N=",nrow(data))) +
#  theme_minimal()
