filter_description <- list(
  name = "Filtre Famille",
  args = list(
    mf = list(required = TRUE, help = "Liste de familles de molécule")
  ),
  help = "Filtre les lignes d’un data.frame entre deux dates"
)

filter_function <- function(data, args) {
    molecule_families <- strsplit(args$mf, ",")[[1]]
    print(molecule_families)
    data %>% filter(famille %in% !! molecule_families)
}