filter_description <- list(
  name = "Filtre Purity > 0",
  args = list(
    p = list(required = FALSE, action = "store_true", help = "Conserve seulement les données avec une pureté > 0")
  ),
  help = "Conserve seulement les données avec une pureté > 0"
)

filter_function <- function(data, args) {
    data %>% filter(pourcentage > 0)
}