library(dplyr)
library(jsonlite)

source("scriptR/util/utilities.R")

data = load_data()
data = data %>% filter(molecule_simp=="Cocaïne")

black_list_percent=c("NQ","NQ ","")
data = data %>% filter(!pourcentage %in% black_list_percent) %>% mutate(pourcentage = as.double(pourcentage))

################################################################################
# Selection de la fenêtre de temps #############################################
################################################################################

args <- commandArgs(trailingOnly = TRUE)
args_list <- extract_args(args)
outputPath <- args_list$outputPath

data <- filter_data(data, args_list)

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
summar <- summary(model)
r_squared <- summar$r.squared
nb_obs <- length(summar$residuals)

res <- summar$coefficients
var_names <- rownames(res)            # noms des variables (Intercept, poids)
coefs <- res[, "Estimate"]            # coefficients
std_errors <- res[, "Std. Error"]     # erreurs standards

stars <- cut(res[, "Pr(>|t|)"],
             breaks = c(-Inf, 0.01, 0.05, 0.1, Inf),
             labels = c("***", "**", "*", " "),
             right = FALSE)
names(stars) <- rownames(res)

# Génération de la liste des datasets
datasets_list <- lapply(var_names, function(var_names_i) {
  list(
    "label" = ifelse(var_names_i == "(Intercept)", "Constante (Deep web / dark web)", sub("provenance", "", var_names_i)),
    "coefficient" = paste(unname(round(coefs[var_names_i],3)), unname(stars[var_names_i]),sep=""),
    "standard_error" = unname(round(std_errors[var_names_i],3))
  )
})

#Création de l'objet JSON
json_obj <- list(
  data = datasets_list,
  nb_obs = nb_obs,
  r_squared = r_squared
)

# Créer le fichier JSON (on vérifie si les dossiers parents existent)
save_ouput_as_json(json_obj, outputPath, auto_unbox=TRUE)