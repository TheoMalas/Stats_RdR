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
# Evolution of the purity ######################################################
################################################################################

Delta=15

data_cocaine_lis <- data %>%
  arrange(date) %>%
  mutate(moyenne_glissante = sapply(date, function(d) {
    mean(pourcentage[date >= d - Delta & date <= d + Delta], na.rm = TRUE)
  }))%>%
  filter(date >= min(date) + Delta, date <= max(date) - Delta)


ggplot(data_cocaine_lis, aes(x = date, y = moyenne_glissante)) +
  geom_point() +
  geom_line() +
  labs(x = "Date",
       y = "Pureté de la cocaïne (équivalent base) en %",
       title = paste0("Évolution lissée sur 1 mois de la pureté de la cocaïne, N=",nrow(data))) +
  theme_minimal()
