library(DBI)
library(RMySQL)
library(dplyr)
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


df_fin = df_pie %>% select(categorie_label, pourcent)

# Convertir en liste nommée
df_list <- setNames(as.list(df_fin$pourcent), df_fin$categorie_label)

N=nrow(data)
# Conversion au format souhaité
json_obj <- list(
  labels = as.character(df_fin$categorie_label),
  data = df_fin$pourcent,
  count=N
)

write_json(json_obj, "output/pie_chart_supply_all_molecules.json", pretty = TRUE, auto_unbox = FALSE)




#N=nrow(df_pie_0)

#ggplot(df_pie, aes(x = "", y = somme, fill = categorie_label)) +
#  geom_col(width = 1) +
#  coord_polar(theta = "y") +
#  labs(title = paste0("Répartition des échantillons par mode d'approvisionnement (%), N=",N),
#       fill = "Mode d'approvisionnement") +
#  theme_void() +
#  guides(fill = guide_legend(reverse = TRUE))