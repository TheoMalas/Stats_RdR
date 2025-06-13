library(readODS)
library(tidyverse)
library(stringr)
library(dplyr)
library(ggplot2)
library(stargazer)

setwd("/Users/theomalas-danze/Desktop/Psycho")

data=read_ods("data_psychoactif.ods")
data = data %>% 
  rename(produit_attendu=`Produit attendu`) %>%
  mutate(Date = as.Date(Date , format = "%Y %m %d"))

setwd("/Users/theomalas-danze/Desktop/Psycho/Inter_substance")

data = data %>% 
  mutate(produit_attendu_simp=sub("-","", tolower(produit_attendu), fixed=T)) %>% 
  mutate(produit_attendu_simp = case_when(str_detect(produit_attendu_simp,"ecstasy")~"mdma",
                                          str_detect(produit_attendu_simp,"thc|cannabis|cbd|herbe")~"cannabis/herbe",
                                          str_detect(produit_attendu_simp, "speed")~"speed (amphétamine)",
                                          str_detect(produit_attendu_simp, "tucibi")~"2cb",
                                          str_detect(produit_attendu_simp, "xanax|alprazolam")~"xanax",
                                          str_detect(produit_attendu_simp, "lsd")~"lsd",
                                          str_detect(produit_attendu_simp, "nep|pentedrone")~"nep",
                                          .default = produit_attendu_simp))

data = data %>% 
  mutate(produit_attendu_simp=case_when(produit_attendu_simp=="2cb"~"2C-B",
                                        produit_attendu_simp=="nep"~"NEP",
                                        produit_attendu_simp=="méthamphétamine"~"Méthamphétamine",
                                        produit_attendu_simp=="lsd"~"LSD",
                                        produit_attendu_simp=="2mmc"~"2-MMC",
                                        produit_attendu_simp=="4mmc"~"4-MMC",
                                        produit_attendu_simp=="3cmc"~"3-CMC",
                                        produit_attendu_simp=="speed (amphétamine)"~"Speed (amphétamine)",
                                        produit_attendu_simp=="kétamine"~"Kétamine",
                                        produit_attendu_simp=="3mmc"~"3-MMC",
                                        produit_attendu_simp=="cannabis/herbe"~"Cannabis/Herbe",
                                        produit_attendu_simp=="héroïne"~"Héroïne",
                                        produit_attendu_simp=="mdma"~"MDMA",
                                        produit_attendu_simp=="cocaïne"~"Cocaïne",
                                        .default=produit_attendu_simp))
################################################################################
# Pie chart sur le produit #####################################################
################################################################################
lim = 15
black_list=c("err:502","aucun nom","pas de la drogue","ne sais pas",
             "autre élément","inconnu","un hallucinogène : ce n'est pas une molécule ça...",
             "aucune indications","ne sait pas","produit de coupe insoluble dans l'lsopropanol",
             "coupe?","mélange")

df_pie <- data %>% 
  mutate(produit_attendu_simp  = ifelse(produit_attendu_simp %in% black_list, "Autres",produit_attendu_simp))


df_pie <- df_pie %>%
  group_by(produit_attendu_simp) %>%
  summarise(somme = n())%>%
  arrange(desc(somme)) %>% 
  mutate(produit_attendu_simp = ifelse(row_number()>lim, "Autres",produit_attendu_simp)) %>% 
  group_by(produit_attendu_simp) %>%
  summarise(somme = sum(somme)) %>%
  arrange(desc(somme))%>% 
  mutate(
    pourcent = somme / sum(somme) * 100,
    categorie_label = paste0(produit_attendu_simp, " (", round(pourcent, 1), "%)")
  )

df_pie = df_pie %>% 
  mutate(temp=ifelse(produit_attendu_simp=="Autres",-1,somme)) %>% 
  arrange(temp) %>% 
  mutate(categorie_label = factor(categorie_label, levels = categorie_label))


ggplot(df_pie, aes(x = "", y = somme, fill = categorie_label)) +
  geom_col(width = 1) +
  coord_polar(theta = "y") +
  labs(title = paste0("Répartition des échantillons par produit (%), N=",nrow(data))) +
  theme_void() +
  guides(fill = guide_legend(reverse = TRUE))

ggsave("pie_chart_produits.pdf")

################################################################################
# Évolution des pourcentages ###################################################
################################################################################
list_focus=unique(df_pie$produit_attendu_simp)

data_bimestre <- data %>%
  mutate(
    month = month(Date),
    bimestre = 1 + (month - 1) %/% 2,  # Diviser le mois pour obtenir un bimestre (1-2, 3-4, etc.)
    date_bimestre = floor_date(Date, "year") + months((bimestre - 1) * 2)  # Calculer le premier jour du bimestre
  )

data_evol <- data_bimestre %>%
  mutate(produit_attendu_simp = ifelse(produit_attendu_simp %in% list_focus,produit_attendu_simp,"Autres")) %>%
  group_by(date_bimestre) %>%
  mutate(n_total = n()) %>%
  ungroup() %>%
  group_by(date_bimestre, produit_attendu_simp) %>%
  summarise(prop = n() / first(n_total), .groups = "drop") %>%
  complete(date_bimestre, produit_attendu_simp, fill = list(prop = 0)) %>%
  arrange(date_bimestre, produit_attendu_simp) %>% 
  filter(date_bimestre > "2023-04-01" & date_bimestre < max(date_bimestre, na.rm=T))


order=data_evol %>% 
  filter(date_bimestre==max(date_bimestre, na.rm=T)) %>%
  mutate(temp=ifelse(produit_attendu_simp=="Autres",-1,prop)) %>% 
  arrange(temp) %>% 
  select(produit_attendu_simp)

data_evol <- data_evol %>% 
  mutate(produit_attendu_simp = factor(produit_attendu_simp, levels = unlist(order)))

N=nrow(data_bimestre %>% filter(date_bimestre > "2023-04-01" & date_bimestre < max(date_bimestre, na.rm=T)))  
  
ggplot(data_evol, aes(x = date_bimestre, y = prop, fill = produit_attendu_simp)) +
  geom_area(position = "stack", color = "white", size = 0.2) +
  scale_y_continuous(labels = scales::percent_format()) +
  labs(
    title = paste0("Évolution des parts par produit attendu, N=",N),
    x = "Bimestre",
    y = "Part relative",
    fill = "Produit attendu"
  ) +
  theme_minimal(base_size = 14)

ggsave("stacked_area_prop.pdf")

################################################################################
# Évolution en absolu ##########################################################
################################################################################

data_evol_abs <- data_bimestre %>%
  mutate(produit_attendu_simp = ifelse(produit_attendu_simp %in% list_focus,produit_attendu_simp,"Autres")) %>%
  group_by(date_bimestre, produit_attendu_simp) %>%
  summarise(abs = n(), .groups = "drop") %>%
  complete(date_bimestre, produit_attendu_simp, fill = list(abs = 0)) %>%
  arrange(date_bimestre, produit_attendu_simp) %>% 
  filter(date_bimestre > "2023-04-01" & date_bimestre < max(date_bimestre, na.rm=T)) %>% 
  mutate(produit_attendu_simp = factor(produit_attendu_simp, levels = unlist(order)))

N=nrow(data_bimestre %>% filter(date_bimestre > "2023-04-01" & date_bimestre < max(date_bimestre, na.rm=T)))

ggplot(data_evol_abs, aes(x = date_bimestre, y = abs, fill = produit_attendu_simp)) +
  geom_area(position = "stack", color = "white", size = 0.2) +
  labs(
    title = paste0("Évolution du nombre d'échantillons par produit attendu, N=",N),
    x = "Bimestre",
    y = "Nombre d'échantillons",
    fill = "Produit attendu"
  ) +
  theme_minimal(base_size = 14)

ggsave("stacked_area_abs.pdf")

################################################################################
# Pie chart sur mode d'approvisionnement #######################################
################################################################################

df_pie_0 <- data %>%
  filter(`Mode d'approvisionnement` != "Produits de coupe et commentaires :" & !is.na(`Mode d'approvisionnement`)) %>% 
  filter(`Mode d'approvisionnement` != "Revendeur habituel" & `Mode d'approvisionnement` != "Revendeur occasionnel")
  
df_pie <- df_pie_0 %>% 
  group_by(`Mode d'approvisionnement`) %>%
  summarise(somme = n()) %>%
  mutate(
    pourcent = somme / sum(somme) * 100,
    categorie_label = paste0(`Mode d'approvisionnement`, " (", round(pourcent, 1), "%)")
  ) %>%
  arrange(somme) %>%
  mutate(categorie_label = factor(categorie_label, levels = categorie_label))

N=nrow(df_pie_0)

ggplot(df_pie, aes(x = "", y = somme, fill = categorie_label)) +
  geom_col(width = 1) +
  coord_polar(theta = "y") +
  labs(title = paste0("Répartition des échantillons par mode d'approvisionnement (%), N=",N),
       fill = "Mode d'approvisionnement") +
  theme_void() +
  guides(fill = guide_legend(reverse = TRUE))

ggsave("Prop_approvisionnement_inter_substance.pdf")

################################################################################
# Évolution en prop sur l'approvisionnement ####################################
################################################################################

# On se demande si on voit une hausse de l'approvisionnement par livreur

data_evol_approvisionnement <- data_bimestre %>%
  rename(mode_app=`Mode d'approvisionnement`) %>% 
  filter(mode_app != "Produits de coupe et commentaires :" & !is.na(mode_app)) %>%
  group_by(date_bimestre) %>%
  mutate(n_total = n()) %>%
  ungroup() %>%
  group_by(date_bimestre, mode_app) %>%
  summarise(prop = n() / first(n_total), .groups = "drop") %>%
  complete(date_bimestre, mode_app, fill = list(prop = 0)) %>%
  arrange(date_bimestre, mode_app) %>% 
  filter(date_bimestre > "2023-11-01" & date_bimestre < max(date_bimestre, na.rm=T))

order=data_evol_approvisionnement %>% 
  filter(date_bimestre==max(date_bimestre, na.rm=T)) %>%
  mutate(temp=prop) %>% 
  arrange(temp) %>% 
  select(mode_app)

data_evol_approvisionnement <- data_evol_approvisionnement %>% 
  mutate(mode_app = factor(mode_app, levels = unlist(order)))

N=nrow(data_bimestre %>%
         rename(mode_app=`Mode d'approvisionnement`) %>%
         filter(mode_app != "Produits de coupe et commentaires :" & !is.na(mode_app)) %>%
         filter(date_bimestre > "2023-11-01" & date_bimestre < max(date_bimestre, na.rm=T))) 

ggplot(data_evol_approvisionnement, aes(x = date_bimestre, y = prop, fill = mode_app)) +
  geom_area(position = "stack", color = "white", size = 0.2) +
  scale_y_continuous(labels = scales::percent_format()) +
  labs(
    title = paste0("Évolution des parts par mode d'approvisionnement, N=", N),
    x = "Bimestre",
    y = "Part relative",
    fill = "Mode d'approvisionnement"
  ) +
  theme_minimal(base_size = 14)

ggsave("stacked_area_prop_approvisionnement.pdf")