analysis_description <- list(
  name = "avg",
  help = "Affiche le résumé statistique du dataset",
  args = list(
    delta = list(required = TRUE, help = "Delta")
  )
)

analysis_function <- function(data, args) {

    delta <- as.double(args$delta)

    source("util/utilities.R")

    black_list_percent <- c("NQ", "NA", "", "ND")
    data = data %>% mutate(pourcentage = gsub(",", ".", sub(".*?(\\d+[\\.,]?\\d*)%.*", "\\1", pourcentage)))
    data <- data %>%mutate(pourcentage_num = as.double(ifelse(grepl("^[0-9.]+$", pourcentage), pourcentage, NA)))
    data = data %>% filter(!pourcentage %in% black_list_percent) %>% mutate(pourcentage = as.double(pourcentage))

    return(datasets_list_evol(data, delta, "moyenne"))
}
