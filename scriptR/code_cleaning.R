library(DBI)
library(RMySQL)
library(dplyr)

# user <- Sys.getenv("USER")
# pwd <- Sys.getenv("PASSWORD")
# 
# 
# con <- dbConnect(RMySQL::MySQL(),
#                 dbname = "db_psycho_test",
#                 host     = "localhost",    # Ajouté si tu es en local
#                 port     = 3306,           # Port par défaut MySQL
#                 user = user,
#                 password = pwd,
#                 local_infile = 1)  # active LOAD DATA LOCAL INFILE)

CLIENT_LOCAL_FILES <- 128  # This constant is not predefined in RMySQL

user <- Sys.getenv("USER")
pwd <- Sys.getenv("PASSWORD")
host <- Sys.getenv("HOST")
port <- as.integer(Sys.getenv("PORT"))


con <- dbConnect(RMySQL::MySQL(),
                 dbname = "db_psycho_july_2025",
                 host = host,
                 port = port,
                 user = user,
                 password = pwd,
                 client.flag = CLIENT_LOCAL_FILES)

dbListTables(con)
data <- dbReadTable(con, "resultats_analyse")

correct_dict <- list(
  `2C-E`= c("2CE"),
  `2-MMC` = c("2-MMC", "2mmc", "2MMC", "2-mmc"),
  `3-MMC` = c("3-MMC", "3mmc"),
  `3-MMA` = c("3MMA", "3mma", "3-MMA (cathinone)", "3-MMA","3-mma"),
  `4-FMA`= c("4FMA"),
  `4-MMC (mephedrone)` = c("4-MMC", "4MMC", "4-mmc"),
  `6-APB` = c("6-APB", "6 APB", "6-APB Succinate"),
  `Alpha-PiHP` = c("alpha pihp", "ALPHA PIHP", "Alpha PIHP", "ALPHA-PIHP","Alpha-PiHP" ),
  Alprazolam = c("alprazolam", "Alprazolam"),
  Baclofène = c("baclofene", "Baclofen "),
  Bromazolam = c("Bromazolam", "bromazolam", "Bromazolam (comprimé écrasé)"),
  Cocaïne = c("Cocaine ", "Cocaine"),
  `5-MeO-DMT`= c("5-MeO-DMT Freebase", "5-meo-dmt", "5-MeO-DMT ", "5meoDMT","5-MeO-DMT Freebase "),
  DMT = c("dmt"),
  Kétamine = c("kétamine"),
  `1-cp-LSD`= c( "1cp-LSD", "1cp-lsd", "1cp-lsd ", "1cP-LSD"),
  Mescaline = c("Mescaline", "mescaline", "Mescaline "),
  Méthamphétamine = c("methamphetamine", "Méthamphétamine"),
  Modafinil = c("modafinil"),
  Morphine = c("morphine", "Morphine", "Morphine "),
  NEH = c("N-ethylHexedrone","N-Ethylhexedrone"),
  Prégabaline = c("pregabaline", "prégabaline", "Prégabaline"),
  `RC opioids: cychlorphine`=c("RC opioids: cyclorphine "),
  sildénafil = c(" sildénafil")
)

correct_df <- bind_rows(lapply(names(correct_dict), function(nom_correct) {
  data.frame(incorrect = correct_dict[[nom_correct]], correct = nom_correct, stringsAsFactors = FALSE)
}))

data_correct <- data %>%
  left_join(correct_df, by = c("molecule" = "incorrect")) %>%
  mutate(molecule_correct = ifelse(is.na(correct), molecule, correct)) %>%
  select(-correct)



alias_dict <- list(
  `2C-B` = c("TUCIBI","Tucibi"),
  `2-MMC` = c("2-MMC", "2mmc", "2MMC", "2-mmc", "pas de certitude 2 mmc peut-être ?", "cathinone genre 2mmc"),
  `2-Oxo-PCE` = c("o-pce"),
  Alprazolam = c("alprazolam", "Alprazolam", "Xanax (Alprazolam) 2mg", "Xanax"),
  Amphétamines = c("amphétamine et un élément non identifié", "Sulfate d’amphétamine ", " d-amphetamine and i-amphetamines, 3/1 ratio"),
  `Cannabis (THC/CBD)` = c("cannabis (THC)", "Cannabis / Herbe", "Cannabinoïdes naturels ", "Cannabinoides naturels ", "Fleur de CBD", "résine de cannabis fort en thc, faible en cbd", "cannabis résinne-THC, CBD ,CBN", "Huile de cannabis ", "Cannabinoïdes principaux", "Cannabis CBD", "Cbd et thc ","CBD","THC","Herbe et hash"),
  Codéine = c("Codéine/Paracétamol", "Moins d'un gramme de paracétamol et de la codéine"),
  DMT = c("5-MeO-DMT","4-aco-dmt"),
  DMXE = c("DMXE HCL","DMXE"),
  Kétamine = c("Deschloroketamine (DCK)", "2-FDCK", "2FDCK", "Deschloroéthylnorkétamine","K(+nps?)"),
  LSD = c("1-cp-LSD"),
  MDMA = c("MDMA", "Ecstasy", "Ecstasy (MDMA)"),
  Methylphénidate = c("méthylphénidate ", "4F-MPH", "4F-MPH et un élément non identifié", "Methilphenidate hydrochloride", "4-Fluoromethylphenidate"),
  MiPT = c("5meomipt","5MeO mipt","Fumarate MiPT (N-méthyl-N-isopropyltryptamine)"),
  Modafinil = c("FL-MODAFINIL"),
  Morphine = c("Sulfate de morphine"),
  NEP = c("NEP", "N-Ethylpentedrone ( NEP )", "Nep", "NEP, mais mal synthétisée, j'imagine qu'il y a des", "pentedrone","N-éthyl pentedrone","N-ethylPentedrone"),
  Oxycodone = c("Oxycodone", "Oxy"),
  Speed = c("speed","Speed (amphétamine)"),
  Synthacaïne = c("syntacaïne","Strong Synthcaine Colombia"),
  Tramadol = c("Tramadol", "tramadol hydrochloride"),
  `Viagra (Sildénafil)` = c("viagra", "sildénafil"),
  Problème = c("pas de la drogue","","aucun nom","ne sait pas","ne sais pas","autre élément","Un hallucinogène : ce n'est pas une molécule ça...","aucune indications","produit de coupe insoluble dans l'lsopropanol","Mélange","Coupe?","Ne sait pas","inconnu","mélange","stimulant")
)

alias_df <- bind_rows(lapply(names(alias_dict), function(nom_canonique) {
  data.frame(alias = alias_dict[[nom_canonique]], canonique = nom_canonique, stringsAsFactors = FALSE)
}))



data_canonique <- data_correct %>%
  left_join(alias_df, by = c("molecule_correct" = "alias")) %>%
  mutate(molecule_simp = ifelse(is.na(canonique), molecule_correct, canonique)) %>%
  select(-canonique)


familles_psychotropes <- list(
  Amphétamines = c("Amphétamines", "Méthamphétamine", "fluoroamphetamine", 
    "2FMA", "2-fluoro-méthamphétamine", "4-FMA", "3FA", "Methylphénidate",
    "Modafinil", "3-MMA","Fénéthylline", "Dextroamphetamine sulfate", "MDMA et Amphétamines", "Synthacaïne", "Bromantane"),
  Benzodiazépines_et_similaires = c("Alprazolam", "Clonazepam", "Diazepam", "Bromazolam", "Norflurazepam", "Pyrazolam", "Flubromazepam", "Flubrotizolam", "DeschloroEtizoolam", "RC Benzo: Rilmazafone", "Gidazepam"),
  Cannabinoïdes = c("Cannabis (THC/CBD)", "cannabinoïde de synthèse", "JWH-210"),
  Cathinones = c("3-MMC", "2-MMC", "3-CMC", "4-MMC (mephedrone)", "4-CMC", "NEP", "Alpha-PiHP", "4BMC", "NEH","euthylone"),
  Cocaïne = c("Cocaïne"),
  `Crack/Freebase (cocaine base)` = c("Crack/Freebase (cocaine base)"),
  Dissociatifs = c("2-Oxo-PCE", "3-MeO-PCE HCL", "DMXE", "3-HO-PCP"),
  GABAergiques_non_benzo = c("GHB", "GBL"),
  Hallucinogènes = c("LSD", "DMT", "5-MeO-DALT Freebase", "Mescaline", "2C-B", "2C-E", "2C-EF", "4-HO-MET", "DOB", "MiPT"),
  Héroïne = c("Héroïne"),
  Kétamine = c("Kétamine"),
  Speed = c("Speed"),
  MDMA = c("MDMA"),
  Opioïdes = c("Morphine", "Codéine", "Oxycodone", "Tramadol", "méthadone","Opium", "RC opioids: cychlorphine", "RC opioids: protonitazène", "dérivé opiciacé", "Fentanyl","opioides ")
)
familles_psychotropes_df <- bind_rows(lapply(names(familles_psychotropes), function(nom_famille) {
  data.frame(init = familles_psychotropes[[nom_famille]], famille = nom_famille, stringsAsFactors = FALSE)
}))



data_f <- data_canonique %>%
  left_join(familles_psychotropes_df, by = c("molecule_simp" = "init"))


# 2. Write the cleaned data into the MySQL database
dbWriteTable(con,
             name = "resultats_analyse_cleaned",  # You can replace the table name if needed
             value = data_f,
             overwrite = TRUE,  # or use append = TRUE if you want to add to existing data
             row.names = FALSE)
