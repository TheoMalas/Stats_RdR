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

Delta=15#as.numeric(args[3])

################################################################################
# Histogramme des puretés ######################################################
################################################################################
tranches <- tibble(classe = seq(0, 100, by = 5))

data_histo <- data %>%
  select(pourcentage) %>% 
  mutate(classe = cut(pourcentage,
                      breaks = seq(0, 105, by = 5),
                      include.lowest = TRUE,
                      right = FALSE,  # [x, y[
                      labels = seq(0, 100, by = 5))) %>%
  count(classe, name = "occurence") %>%
  mutate(classe = as.integer(as.character(classe))) %>% 
  right_join(tranches, by = "classe") %>%
  mutate(occurence = ifelse(is.na(occurence), 0, occurence)) %>% 
  arrange(classe)

ratio_base_sel = 303.352/(303.352+35.453)



################################################################################
# Evolution of the purity ######################################################
################################################################################



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




################################################################################
# Export en JSON ###############################################################
################################################################################
N=sum(data_histo$occurence)

json_obj <- list(
  labels = as.character(data_histo$classe),
  data = data_histo$occurence,
  labels_line = as.character(data_cocaine_lis$date),
  datasets_line = datasets_list,
  ratio_base_sel = ratio_base_sel*100,
  count = N
)

# Créer les dossiers si nécessaire
dir.create("output/cocaine", recursive = TRUE, showWarnings = FALSE)

# Export en JSON
write_json(json_obj, "output/cocaine/histo_purity_cocaine.json", pretty = TRUE, auto_unbox = FALSE)

#ggplot(data, aes(x = pourcentage)) +
#  geom_histogram(binwidth = 5, fill = "firebrick2", color = "white", boundary = 0, closed = "left") +
#  scale_x_continuous(limits = c(0, 100), breaks = seq(0, 100, by = 10)) +
#  labs(
#    title = paste0("Distribution de la pureté de la cocaïne (en équivalent base), N=",nrow(data)),
#    x = "Pureté (%)",
#    y = "Occurence"
#  ) +
#  geom_vline(xintercept = 100*ratio_base_sel, linetype="dashed")+
#  theme_minimal(base_size = 14)
