library(dplyr)
library(jsonlite)
library(stringr)
source("scriptR/util/utilities.R")

data = load_data()
data = data %>% filter(molecule_simp=="MDMA")
data = data %>% filter(comprime>0)
data = data %>% select(date, forme,coupe, comprime)


################################################################################
# Selection de la fenêtre de temps #############################################
################################################################################

args <- commandArgs(trailingOnly = TRUE)
args_list <- extract_args(args)
outputPath <- args_list$outputPath

data <- filter_data(data, args_list)

################################################################################
# Quantité de MDMA en fonction du poids des comprimés ##########################
################################################################################

extract_number_combined <- function(x) {
  x_clean <- gsub("\\s+", "", x)  # Supprimer tous les espaces
  
  # Liste des regex à tester
  patterns <- c(
    ".*?(\\d+[\\.,]?\\d*)mgdeMDMA.*",
    ".*?(\\d+[\\.,]?\\d*)mgMDMA/.*",
    ".*?(\\d+[\\.,]?\\d*)mgeqbase.*"
  )
  
  for (pattern in patterns) {
    match <- sub(pattern, "\\1", x_clean)
    match <- gsub(",", ".", match)
    if (!is.na(suppressWarnings(as.numeric(match)))) {
      return(as.numeric(match))
    }
  }
  
  return(NA_real_)  # Aucun motif trouvé
}

data = data %>% 
  filter(forme=="comprimé") %>% 
  mutate(dose = sapply(coupe, extract_number_combined))
  #filter(!is.na(dose))

data <- data %>%
  mutate(
    # on enlève la notation mg
    coupe = gsub("mg","", coupe),
    # remplacer les virgules par des points
    coupe = gsub(",", ".", coupe),
    # récupère les nombres entiers ou décimaux
    poids = sapply(
      str_extract_all(coupe, "\\b[0-9]+(?:\\.[0-9]+)?\\b"),
      function(x) {
        if (length(x) == 0) return(NA)  # si pas de nombre
        max(as.numeric(x), na.rm = TRUE)
      }
    )
  )
data = data %>% select(coupe,comprime, poids, dose)
data = data %>% filter(poids > dose/0.8) #permet d'éliminer les erreurs où le poids le plus grand est la masse de MDMA (eq base ou eq HCL)


model <- lm(dose ~ poids, data)
summar <- summary(model)
coef <- summar$coefficients
poids_lis=list()
dose_lis = list()

for (i in min(data$poids):max(data$poids)){
  poids_lis <- append(poids_lis,i)
  dose_lis <- append(dose_lis,coef[1]+coef[2]*i)
}

scatter_test <- list()
for (i in 1:length(data$poids)){
  scatter_test <- append(scatter_test,list(c(x = data$poids[[i]], y=data$dose[[i]])))
}


# Génération de la liste des datasets
datasets_list <- list(
  list(
  label = "Données",
  type = "scatter",
  data = scatter_test
 ),
 list(
  type = "line",
  label = "Régression linéaire",
  data = unlist(dose_lis),
  xAxisID = "x2"
)
)



################################################################################
# Export en JSON ###############################################################
################################################################################

json_obj <- list(
  labels = as.character(poids_lis),
  datasets = datasets_list
)
# Créer le fichier JSON (on vérifie si les dossiers parents existent)
save_ouput_as_json(json_obj, outputPath)
#library(ggplot2)

#ggplot(data, aes(x = poids, y = dose)) +
#  geom_point(color = "blue", alpha = 0.6) + # points
#  geom_smooth(method = "lm", se = TRUE, color = "red", fill = "grey70") + # droite + incertitude
#  labs(
#    x = "Masse du comprimé (mg)",
#    y = "Quantité de MDMA (mg)",
#    title = "Masse du comprimé VS Quantité de MDMA"
#  ) +
#  theme_minimal()

#ggsave("Masse_du_comprime_VS_Quantite_de_MDMA.pdf")
