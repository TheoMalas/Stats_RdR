filter_description <- list(
  name = "Filtre Molécule",
  args = list(
    m = list(required = TRUE, help = "Molécule")
  ),
  help = "Conserve seulement les données pour cette molécule"
)

filter_function <- function(data, args) {
    molecule <- args$m
    data %>% filter(molecule_simp == !!molecule)
}