analysis_description <- list(
  name = "summary",
  help = "Affiche le résumé statistique du dataset",
  args = list()  # pas d'arguments spécifiques ici
)

analysis_function <- function(data, args) {
  nrow(data)
}
