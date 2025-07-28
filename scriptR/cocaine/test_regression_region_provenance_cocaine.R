library(dplyr)
library(jsonlite)

source("scriptR/util/utilities.R")

data = load_data()
data = data %>% filter(molecule_simp=="Héroïne")

black_list_percent=c("NQ")
data = data %>% mutate(pourcentage = gsub(",", ".", sub(".*?(\\d+[\\.,]?\\d*)%.*", "\\1", pourcentage)))
data = data %>% filter(!pourcentage %in% black_list_percent) %>% mutate(pourcentage = as.double(pourcentage))

################################################################################
# Selection de la fenêtre de temps #############################################
################################################################################

#args <- commandArgs(trailingOnly = TRUE)
#args_list <- extract_args(args)
#outputPath <- args_list$outputPath

#data <- filter_data(data, args_list)

################################################################################
# Pureté par région ############################################################
################################################################################

data_dep_region = read.csv("departements-region-france.csv")

data <- data %>%
    mutate(departement = ifelse(nchar(departement)==1, paste0("0", departement), departement)) # nolint

data_reg <- left_join(
  data,
  data_dep_region,
  by = c("departement" = "code_departement")
)

model <- lm(pourcentage ~ nom_region + provenance + provenance * nom_region, data = data_reg)
summary(model)
stargazer(model, type = "text", title = "Regression of Cocaine Purity by Region and Provenance",
          dep.var.labels = "Cocaine Purity (%)",
          covariate.labels = c("Region", "Provenance", "Region * Provenance"),
          out = "output/regression_region_provenance_heroine.txt")
