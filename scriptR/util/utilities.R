load_data <- function(){
  library(DBI)
  library(RMySQL)
  library(dplyr)
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
  
  return(data)
}

extract_args <- function(args_string){
  args <- strsplit(args_string, " ")[[1]]
  args_list <- setNames(
    lapply(strsplit(args, "="), `[`, 2),
    sapply(strsplit(args, "="), `[`, 1)
  )
  # Extraction
  date_debut <- as.Date(args_list[["date_debut"]])
  date_fin   <- as.Date(args_list[["date_fin"]])
  outputPath <- args_list[["outputPath"]]
  if (!is.null(args_list[["familles_list"]])){
  familles_vec <- strsplit(args_list[["familles_list"]],",")[[1]]}
  else{familles_vec <- NULL}
  if (!is.null(args_list[["Delta"]])){Delta=as.numeric(args_list[["Delta"]])}
  else{Delta<- NULL}
  if (!is.null(args_list[["mode"]])){mode=args_list[["mode"]]}
  else{mode<- NULL}
  return(list(
    date_debut = date_debut,
    date_fin = date_fin,
    outputPath = outputPath,
    familles_list = familles_vec,
    Delta = Delta,
    mode = mode
  ))
  
}
filter_data <- function(data, args_list){
  date_debut <- args_list$date_debut
  date_fin   <- args_list$date_fin
  familles_vec <- args_list$familles_list
  
  # Filtre
  data = data %>% 
    filter(date>=date_debut & date<=date_fin)  # 2 dates NA à gérer
  if (length(familles_vec)>1){data = data %>% filter(famille %in% familles_vec)}
  if (length(familles_vec)==1){if(!is.na(familles_vec)){data = data %>% filter(famille %in% familles_vec)}}

  return(data)
}

histo_data <- function(data){
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
  
  return(data_histo)
}

datasets_list_evol <- function(data, Delta, mode="moyenne"){
  if (mode == "moyenne"){
    data_lis <- data %>%
      arrange(date) %>%
      mutate(
        main = sapply(date, function(d) {
          mean(pourcentage[date >= d - Delta & date <= d + Delta], na.rm = TRUE)
        }),
        ecart_type_glissant = sapply(date, function(d) {
          sd(pourcentage[date >= d - Delta & date <= d + Delta], na.rm = TRUE)
        }),
        borne_sup = main + ecart_type_glissant,
        borne_inf = main - ecart_type_glissant) %>%
      filter(date >= min(date) + Delta, date <= max(date) - Delta) %>%
      select(date, main, borne_sup, borne_inf)
    data_lis <- data_lis %>% mutate(borne_inf = ifelse(borne_inf < 0, 0, borne_inf), borne_sup = ifelse(borne_sup > 100, 100, borne_sup))
  }
  if (mode == "médiane"){
    data_lis <- data %>%
      arrange(date) %>%
      mutate(
        main = sapply(date, function(d) {
          median(pourcentage[date >= d - Delta & date <= d + Delta], na.rm = TRUE)
        }),
        borne_inf = sapply(date, function(d) {
          quantile(pourcentage[date >= d - Delta & date <= d + Delta], 0.25, na.rm = TRUE)
       }),
        borne_sup = sapply(date, function(d) {
          quantile(pourcentage[date >= d - Delta & date <= d + Delta], 0.75, na.rm = TRUE)
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
  return(list(labels_line,datasets_list))
}


regression_json <- function(data){
  black_list=c("Produits de coupe et commentaires :","Revendeur habituel","Revendeur occasionnel","Nous ne détectons rien par HPLC / CCM","")

  data <- data %>%
    filter(!provenance %in% black_list)

  #df_pie <- data %>% 
  #  group_by(provenance) %>%
  #  summarise(somme = n()) %>%
  #  mutate(
  #    pourcent = somme / sum(somme) * 100,
  #    categorie_label = paste0(provenance, " (", round(pourcent, 1), "%)")
  #  ) %>%
  #  arrange(somme) %>%
  #  mutate(categorie_label = factor(categorie_label, levels = categorie_label))
  order = c("Deep web / dark web", "Dealer de rue (four)", "Livreur", "Réseaux sociaux en ligne", "Dealer en soirée", "Don entre partenaire de conso", "Boutique en ligne")
  data_reg=data %>%
    mutate(provenance = factor(provenance, levels = unlist(order)))

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
  return(json_obj)
}




save_ouput_as_json <- function(json_obj,outputPath, auto_unbox=FALSE){
  
  json_folder<-sub("/[^/]*$", "", outputPath)
  dir.create(json_folder, recursive = TRUE, showWarnings = FALSE)
  
  write_json(json_obj, outputPath, pretty = TRUE, auto_unbox = auto_unbox)
}