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
# Histogramme des puretés ######################################################
################################################################################

ggplot(data, aes(x = pourcentage)) +
  geom_histogram(binwidth = 5, fill = "firebrick2", color = "white", boundary = 0, closed = "left") +
  scale_x_continuous(limits = c(0, 100), breaks = seq(0, 100, by = 10)) +
  labs(
    title = paste0("Distribution de la pureté de la cocaïne (en équivalent base), N=",nrow(data)),
    x = "Pureté (%)",
    y = "Occurence"
  ) +
  geom_vline(xintercept = 100*ratio_base_sel, linetype="dashed")+
  theme_minimal(base_size = 14)
