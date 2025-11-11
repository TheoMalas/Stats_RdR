#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(argparse)
  library(crayon)
})

source("util/utilities.R")

data = load_data()

load_filters <- function(path = "filters") {
  filter_files <- list.files(path, full.names = TRUE, pattern = "\\.R$", recursive = TRUE)
  filters <- list()
  for (file in filter_files) {
    env <- new.env()
    source(file, local = env)
    filters[[env$filter_description$name]] <- list(
      description = env$filter_description,
      fn = env$filter_function
    )
  }
  filters
}

filters <- load_filters()

# --- Définition des arguments principaux ---
parser <- ArgumentParser(description = 'Pipeline d’analyse de données')

for (f in filters) {
  for (arg_name in names(f$description$args)) {
    arg_def <- f$description$args[[arg_name]]

    arg_list <- list(paste0("--", arg_name))

    if (!is.null(arg_def$alias)) {
      arg_list <- c(paste0("-", arg_def$alias), arg_list)
    }

    arg_list$help <- arg_def$help
    arg_list$dest <- arg_name

    if (!is.null(arg_def$action) && arg_def$action == "store_true") {
      arg_list$action <- "store_true"
    }

    do.call(parser$add_argument, arg_list)
  }
}

parser$add_argument("--output", help = "Dossier de sortie pour sauvegarder les résultats", default = NULL)
parser$add_argument("--format", help = "Formats de sortie séparés par des virgules (ex: csv,json,txt)", default = NULL)

parser$add_argument("--verbose", "-v", help = "Activer le mode verbeux", action = "store_true", dest = "verbose")

load_analyses <- function(path = "analysis") {
  files <- list.files(path, full.names = TRUE, pattern = "\\.R$", recursive = TRUE)
  analyses <- list()
  for (file in files) {
    env <- new.env()
    source(file, local = env)
    analyses[[env$analysis_description$name]] <- list(
      description = env$analysis_description,
      fn = env$analysis_function
    )
  }
  analyses
}

save_result <- function(result, name, output_dir = "results", formats , verbose) {
 
  if (is.null(output_dir)) {
    
    if (verbose) {
      cat(yellow$bold("💬 Aucun dossier de sortie précisé\n\n"))
    }

    print(result)
    
    return(invisible(NULL))
  }

  if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

  if (is.null(formats)) formats <- c("json")
  
  for (fmt in formats) {
    file_path <- file.path(output_dir, paste0(name, ".", fmt))

    if (verbose) {
      cat(green$bold(paste0("💾 Sauvegarde de ", name, " au format ", fmt, "\n\n")))
    }

    tryCatch({
      if (fmt == "csv" && is.data.frame(result)) {
        write.csv(result, file_path, row.names = FALSE)
      } else if (fmt == "json") {
        jsonlite::write_json(result, file_path, pretty = TRUE, auto_unbox = TRUE)
      } else if (fmt == "rds") {
        saveRDS(result, file_path)
      } else if (fmt == "txt") {
        capture.output(print(result), file = file_path)
      } else {
        warning("Format non supporté : ", fmt)
      }
    }, error = function(e) {
      warning("Erreur lors de la sauvegarde de ", name, " au format ", fmt, " : ", e$message)
    })
  }
}

subparsers <- parser$add_subparsers(dest="analysis", help="Analyse à exécuter", required=TRUE, metavar="analysis")

analyses <- load_analyses()
for (a in analyses) {

    sub_parser <- subparsers$add_parser(a$description$name, help = a$description$help)

    for (arg_name in names(a$description$args)) {
        arg_def <- a$description$args[[arg_name]]
        sub_parser$add_argument(paste0("--", arg_name), help = arg_def$help)
    }
}

args <- parser$parse_args()
args <- as.list(args)

if (args$verbose){
  cat(blue$bold("##### Applications des filtres #####"))
  cat("\n\n")
}

for (f in filters) {
  arg_defs <- f$description$args
  arg_names <- names(arg_defs)
  
  # Vérifie si le filtre doit s’activer
  should_run <- FALSE
  
  # Si c’est un flag store_true : actif si TRUE
  if (any(sapply(arg_defs, function(a) identical(a$action, "store_true")))) {
    flag_names <- names(Filter(function(a) identical(a$action, "store_true"), arg_defs))
    should_run <- any(sapply(flag_names, function(n) isTRUE(args[[n]])))
  } else {
    # Autres cas : s’active si tous les arguments requis sont présents
    required_args <- names(Filter(function(a) isTRUE(a$required), arg_defs))
    should_run <- all(!sapply(required_args, function(n) is.null(args[[n]])))
  }

  if (should_run) {
    if (args$verbose){
      cat(green$bold("✅  Filtre appliqué : "), bold(f$description$name), "\n")
    }

    data <- f$fn(data, args)
  } else if (args$verbose) {
    cat(yellow$bold("⚠️  Filtre ignoré : "), yellow(f$description$name), "\n")
  }
}

if (args$verbose){
  cat("\n")
}


selected_analyse <- args$analysis

formats <- if (!is.null(args$format)) unlist(strsplit(args$format, ",")) else NULL
output_dir <- args$output

if (selected_analyse %in% names(analyses)) {

    if (args$verbose) {
      cat(green$bold("🚀 Exécution de l’analyse : "), bold(selected_analyse), "\n\n")
    }

    a <- analyses[[selected_analyse]]
    res <- a$fn(data, args)
    save_result(res, selected_analyse, output_dir, formats, args$verbose)
} else {
    warning("Analyse inconnue : ", selected_analyse)
}
