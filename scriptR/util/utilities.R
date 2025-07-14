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
  return(list(
    date_debut = date_debut,
    date_fin = date_fin,
    outputPath = outputPath,
    familles_list = familles_vec,
    Delta = Delta
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

datasets_list_evol <- function(data, Delta){
  data_lis <- data %>%
    arrange(date) %>%
    mutate(
      moyenne_glissante = sapply(date, function(d) {
        mean(pourcentage[date >= d - Delta & date <= d + Delta], na.rm = TRUE)
      }),
      ecart_type_glissant = sapply(date, function(d) {
        sd(pourcentage[date >= d - Delta & date <= d + Delta], na.rm = TRUE)
      }),
      borne_sup = moyenne_glissante + ecart_type_glissant,
      borne_inf = moyenne_glissante - ecart_type_glissant) %>%
    filter(date >= min(date) + Delta, date <= max(date) - Delta) %>%
    select(date, moyenne_glissante, borne_sup, borne_inf)

  

  # Génération de la liste des datasets
  datasets_list <-list(
    list(
    label = "moyenne glissante",
    data = data_lis$moyenne_glissante,
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

save_ouput_as_json <- function(json_obj,outputPath, auto_unbox=FALSE){
  
  json_folder<-sub("/[^/]*$", "", outputPath)
  dir.create(json_folder, recursive = TRUE, showWarnings = FALSE)
  
  write_json(json_obj, outputPath, pretty = TRUE, auto_unbox = auto_unbox)
}