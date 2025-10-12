load_data <- function(){
  library(DBI)
  library(RMariaDB)
  library(dplyr)
  user <- Sys.getenv("USER")
  pwd <- Sys.getenv("PASSWORD")
  host <- Sys.getenv("HOST")
  port <- as.integer(Sys.getenv("PORT"))
  
  con <- dbConnect(RMariaDB::MariaDB(),
                 dbname = Sys.getenv("DB_NAME"),
                 host = host,
                 port = port,
                 user = user,
                 password = pwd,
                 client.flag = CLIENT_LOCAL_FILES,
                 encoding = "utf8mb4")
  
  dbListTables(con)
  data <- dbReadTable(con, "resultats_analyse_cleaned")
  dbDisconnect(con)
  data[] <- lapply(data, function(col) {
    if (is.character(col)) {
      col <- gsub("Ã©", "é", col)
      col <- gsub("Ã¯", "ï", col)
      return(col)
    } else {
      return(col)
    }
  })
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
  no_cut<- "false"
  if (args_list["no_cut"]=="true"){no_cut=args_list[["no_cut"]]}
  return(list(
    date_debut = date_debut,
    date_fin = date_fin,
    outputPath = outputPath,
    familles_list = familles_vec,
    Delta = Delta,
    mode = mode,
    no_cut = no_cut
  ))
  
}
filter_data <- function(data, args_list){
  date_debut <- args_list$date_debut
  date_fin   <- args_list$date_fin
  familles_vec <- args_list$familles_list
  no_cut <- args_list$no_cut
  
  # Filtre
  data = data %>% 
    filter(date>=date_debut & date<=date_fin)  # 2 dates NA à gérer
  if (length(familles_vec)>1){data = data %>% filter(famille %in% familles_vec)}
  if (length(familles_vec)==1){if(!is.na(familles_vec)){data = data %>% filter(famille %in% familles_vec)}}
  if (no_cut=="true"){data = data %>% filter(pourcentage >0)}

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


regression_json <- function(data, mode="provenance"){
  if (mode=="provenance"){
  black_list=c("Produits de coupe et commentaires :","Revendeur habituel","Revendeur occasionnel","Nous ne détectons rien par HPLC / CCM","")

  data <- data %>%
    filter(!provenance %in% black_list)

  order = c("Deep web / dark web", "Dealer de rue (four)", "Livreur", "Réseaux sociaux en ligne", "Dealer en soirée", "Don entre partenaire de conso", "Boutique en ligne")
  data_reg=data %>%
    mutate(provenance = factor(provenance, levels = unlist(order)))

  model = lm(pourcentage ~ provenance, data=data_reg)
  }

  if (mode == "consommation"){
    model = lm(pourcentage ~ consomme, data=data)
  }

  summar <- summary(model)
  r_squared <- summar$r.squared
  nb_obs <- length(summar$residuals)

  res <- summar$coefficients
  var_names <- rownames(res)           # noms des variables (Intercept, poids)
  coefs <- res[, "Estimate"]            # coefficients
  std_errors <- res[, "Std. Error"]     # erreurs standards

  stars <- cut(res[, "Pr(>|t|)"],
              breaks = c(-Inf, 0.01, 0.05, 0.1, Inf),
              labels = c("***", "**", "*", " "),
              right = FALSE)
  names(stars) <- rownames(res)

  mean <- coefs[[1]]+coefs
  
  #Formating the Intercept for the table
  mean[[1]] <- coefs[[1]]
  coefs[[1]] <- NA
  stars[[1]] <- " "
  
  # Génération de la liste des datasets
  if (mode=="provenance"){
    datasets_list <- lapply(var_names, function(var_names_i) {
      list(
        "label" = ifelse(var_names_i == "(Intercept)", "Deep web / dark web", sub("provenance", "", var_names_i)),
        "mean" = unname(round(mean[var_names_i],3)),
        "coefficient" = paste(unname(round(coefs[var_names_i],3)), unname(stars[var_names_i]),sep=""),
        "standard_error" = unname(round(std_errors[var_names_i],3))
      )
    })
  }
  if (mode=="consommation"){
    datasets_list <- lapply(var_names, function(var_names_i) {
      list(
        "label" = ifelse(var_names_i == "(Intercept)", "Non consommé", "Consommé"),
        "mean" = unname(round(mean[var_names_i],3)),
        "coefficient" = paste(unname(round(coefs[var_names_i],3)), unname(stars[var_names_i]),sep=""),
        "standard_error" = unname(round(std_errors[var_names_i],3))
      )
    })
  }
  #Création de l'objet JSON
  json_obj <- list(
    data = datasets_list,
    nb_obs = nb_obs,
    r_squared = r_squared
  )
  return(json_obj)
}

regression_json_fe <- function(data){
  library(lubridate)
  library(lfe)
  data_dep_region = read.csv("departements-region-france.csv")

  order <- c(
    "Île-de-France", "Occitanie", "Provence-Alpes-Côte d'Azur",
    "Auvergne-Rhône-Alpes", "Grand Est", "Hauts-de-France",
    "Pays de la Loire", "Bourgogne-Franche-Comté", "Bretagne",
    "Nouvelle-Aquitaine", "Centre-Val de Loire", "Normandie", "Corse"
  )

  data <- data %>%
      mutate(
        departement = ifelse(
          nchar(.data$departement) == 1,
          paste0("0", .data$departement),
          .data$departement
        )
      ) %>%
      left_join(
        data_dep_region,
        by = c("departement" = "code_departement")
      ) %>%
      mutate(
        month = month(.data$date),
        bimestre = 1 + ((.data$month - 1) %/% 2) # Diviser le mois pour obtenir un bimestre
      ) %>%
      mutate(
        nom_region = factor(.data$nom_region, levels = unlist(order))
      )
  model <- felm(pourcentage ~ nom_region | bimestre + provenance, data = data)

  summar <- summary(model)
  r_squared <- summar$r.squared
  nb_obs <- length(summar$residuals)

  res <- summar$coefficients
  var_names <- rownames(res)           # noms des variables (Intercept, poids)
  coefs <- res[, "Estimate"]            # coefficients
  std_errors <- res[, "Std. Error"]     # erreurs standards

  stars <- cut(res[, "Pr(>|t|)"],
              breaks = c(-Inf, 0.01, 0.05, 0.1, Inf),
              labels = c("***", "**", "*", " "),
              right = FALSE)
  names(stars) <- rownames(res)

  datasets_list <- lapply(var_names, function(var_names_i) {
    list(
      "label" = sub("nom_region", "", var_names_i),
      "coefficient" = paste(
        unname(round(coefs[var_names_i], 3)),
        unname(stars[var_names_i]),
        sep = " "
      ),
      "standard_error" = unname(round(std_errors[var_names_i], 3))
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