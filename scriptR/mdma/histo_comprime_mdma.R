library(dplyr)
library(jsonlite)

source("scriptR/util/utilities.R")

data = load_data()
data = data %>% filter(molecule_simp=="MDMA")
################################################################################
# Selection de la fenêtre de temps #############################################
################################################################################

args <- commandArgs(trailingOnly = TRUE)

data = filter_data(data,args)


################################################################################
# Histogramme des dosages de comprimés #########################################
################################################################################

data = data %>% filter(grepl("mg", coupe))

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

data_comprime = data %>% 
  filter(forme=="comprimé") %>% 
  select(coupe, date) %>% 
  mutate(dose = sapply(coupe, extract_number_combined)) %>% 
  filter(!is.na(dose))


min_dose=0
max_dose=max(data_comprime$dose)
step=20

tranches <- tibble(classe = seq(min_dose, max_dose, by = step))

data_histo <- data_comprime %>%
  select(dose) %>% 
  mutate(classe = cut(dose,
                      breaks = seq(min_dose, max_dose+step, by = step),
                      include.lowest = TRUE,
                      right = FALSE,  # [x, y[
                      labels = seq(min_dose, max_dose, by = step)))%>%
  count(classe, name = "occurence") %>%
  mutate(classe = as.integer(as.character(classe))) %>% 
  right_join(tranches, by = "classe") %>%
  mutate(occurence = ifelse(is.na(occurence), 0, occurence)) %>% 
  arrange(classe)

################################################################################
# Evolution moyenne et variance ################################################
################################################################################

Delta=15

data_mean_lis <- data_comprime %>%
  arrange(date) %>%
  mutate(moyenne_glissante = sapply(date, function(d) {
    mean(dose[date >= d - Delta & date <= d + Delta], na.rm = TRUE)
  }))%>%
  filter(date >= min(date) + Delta, date <= max(date) - Delta) %>% 
  select(date,moyenne_glissante)

# Génération de la liste des datasets
datasets_list <-list(list(
  label = "",
  data = data_mean_lis$moyenne_glissante,
  fill = "false"
))

################################################################################
# Export en JSON ###############################################################
################################################################################

N=sum(data_histo$occurence)

json_obj <- list(
  labels = as.character(data_histo$classe),
  data = data_histo$occurence,
  labels_line = as.character(data_mean_lis$date),
  datasets_line = datasets_list,
  count = N
)


# Créer les dossiers si nécessaire
dir.create("output/mdma", recursive = TRUE, showWarnings = FALSE)
write_json(json_obj, "output/mdma/histo_comprime_mdma.json", pretty = TRUE, auto_unbox = TRUE)
