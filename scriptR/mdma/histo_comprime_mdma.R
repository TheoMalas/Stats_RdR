library(dplyr)
library(jsonlite)

source("scriptR/util/utilities.R")

data = load_data()
data = data %>% filter(molecule_simp=="MDMA")
################################################################################
# Selection de la fenêtre de temps #############################################
################################################################################

args <- commandArgs(trailingOnly = TRUE)
args_list <- extract_args(args)
outputPath <- args_list$outputPath
Delta <- args_list$Delta
mode <- args_list$mode

data <- filter_data(data, args_list)

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

if (mode == "moyenne"){
  data_lis <- data_comprime %>%
    arrange(date) %>%
    mutate(
      main = sapply(date, function(d) {
        mean(dose[date >= d - Delta & date <= d + Delta], na.rm = TRUE)
      }),
      ecart_type_glissant = sapply(date, function(d) {
        sd(dose[date >= d - Delta & date <= d + Delta], na.rm = TRUE)
      }),
      borne_sup = main + ecart_type_glissant,
      borne_inf = main - ecart_type_glissant) %>%
    filter(date >= min(date) + Delta, date <= max(date) - Delta) %>%
    select(date, main, borne_sup, borne_inf)
  data_lis <- data_lis %>% mutate(borne_inf = ifelse(borne_inf < 0, 0, borne_inf))
}

if (mode == "médiane"){
  data_lis <- data_comprime %>%
    arrange(date) %>%
    mutate(
      main = sapply(date, function(d) {
        median(dose[date >= d - Delta & date <= d + Delta], na.rm = TRUE)
      }),
      borne_inf = sapply(date, function(d) {
        quantile(dose[date >= d - Delta & date <= d + Delta], 0.25, na.rm = TRUE)
      }),
      borne_sup = sapply(date, function(d) {
        quantile(dose[date >= d - Delta & date <= d + Delta], 0.75, na.rm = TRUE)
      })) %>%
    filter(date >= min(date) + Delta, date <= max(date) - Delta) %>%
    select(date, main, borne_sup, borne_inf)
}

# Génération de la liste des datasets
datasets_list <-list(
  list(
  label = paste(mode, "glissante"),
  data = data_lis$main,
  fill = "false"
  ),
  list(
  label = "borne sup",
  data = data_lis$borne_sup,
  fill = "false"
  ),
  list(
  label = "borne inf",
  data = data_lis$borne_inf,
  fill = "false"
  )
)
labels_line = as.character(data_lis$date)
################################################################################
# Export en JSON ###############################################################
################################################################################

N=sum(data_histo$occurence)

json_obj <- list(
  labels = as.character(data_histo$classe),
  data = data_histo$occurence,
  labels_line = labels_line,
  datasets_line = datasets_list,
  count = N
)


# Créer le fichier JSON (on vérifie si les dossiers parents existent)
save_ouput_as_json(json_obj, outputPath)