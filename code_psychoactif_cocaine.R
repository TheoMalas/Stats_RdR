library(readODS)
library(tidyverse)
library(stringr)
library(dplyr)
library(ggplot2)
library(stargazer)

setwd("/Users/theomalas-danze/Desktop/Psycho")

data=read_ods("data_psychoactif.ods")
glimpse(data)

setwd("/Users/theomalas-danze/Desktop/Psycho/Cocaine")


data_cocaine = data %>% filter(`Produit attendu`=="Cocaïne") %>% rename(Percent_plus=`Pourcentage (equivalent base)`, commentaire=`Produits de coupe & Commentaire`)
ratio_base_sel= 303.353/(303.353+35.453)
data_cocaine = data_cocaine %>% 
  mutate(pos_pourcent=  unlist(lapply(gregexpr("%",data_cocaine$Percent_plus),min))) %>% 
  mutate(pos_pourcent_bis=  unlist(lapply(gregexpr("%",data_cocaine$commentaire),min))) %>% 
  mutate(Percent_plus = sub(",",".",Percent_plus, fixed=T)) %>% 
  mutate(commentaire = sub(",",".",commentaire, fixed=T)) %>% 
  mutate(percentage = case_when(pos_pourcent!=-1  ~ifelse(str_detect(Percent_plus,"chlorhydrate") | str_detect(Percent_plus,"sel"),paste0(substr(Percent_plus,pos_pourcent-5,pos_pourcent-1), "sel"), substr(Percent_plus,pos_pourcent-5,pos_pourcent-1)),
                                ! is.na(as.integer(Percent_plus)) ~ Percent_plus,
                                .default="test")) %>% 
  mutate(percentage = ifelse(percentage == "test", case_when(str_detect(commentaire,"base") ~ substr(commentaire,pos_pourcent_bis-5,pos_pourcent_bis-1)), percentage)) %>% 
  mutate(percentage = case_when(grepl("^.ne",percentage)~substr(percentage,4,nchar(percentage)),
                              grepl("^.e",percentage)~substr(percentage,3,nchar(percentage)),
                              grepl("^e",percentage)~substr(percentage,2,nchar(percentage)),
                              .default = percentage)) %>% 
  mutate(percentage = ifelse(str_detect(percentage,"sel"),ratio_base_sel*as.double(substr(percentage,1,nchar(percentage)-3)),as.double(percentage))) %>% 
  mutate(percentage = ifelse(percentage<=1, percentage*100, percentage)) %>% 
  mutate(percentage = ifelse(percentage==100,100*ratio_base_sel,percentage))

  #mutate(percentage = case_when(str_detect(percentage,"ïne")~substr(percentage,4,nchar(percentage)),
  #                              str_detect(percentage,"ine")~substr(percentage,4,nchar(percentage)),
  #                              str_detect(percentage,"ne")~substr(percentage,3,nchar(percentage)),
  #                              str_detect(percentage,"de")~substr(percentage,3,nchar(percentage)),
  #                              str_detect(percentage,"te")~substr(percentage,3,nchar(percentage)),
  #                              str_detect(percentage,"e")~substr(percentage,2,nchar(percentage)),
  #                              .default = percentage)) 

#data_cocaine = data_cocaine %>% mutate(percentage = sapply(str_extract_all(Percent_plus, "\\d"), function(x) paste0(x[1:2], collapse = "")))
data_cocaine = data_cocaine %>% mutate(Date = as.Date(Date , format = "%Y %m %d"))
data_cocaine_r = data_cocaine %>% select(Date, percentage) %>% filter(! is.na(percentage))

data_cocaine_coarse= data_cocaine_r %>%
  mutate(date_months = floor_date(Date, "month")) %>%   # arrondi à la date du 1er du mois
  group_by(date_months) %>%
  summarise(mean = mean(percentage, na.rm = TRUE))%>%
  arrange(date_months) %>%
  slice(2:(n() - 1))


Delta=15
  
data_cocaine_lis <- data_cocaine_r %>%
  arrange(Date) %>%
  mutate(moyenne_glissante = sapply(Date, function(d) {
    mean(percentage[Date >= d - Delta & Date <= d + Delta], na.rm = TRUE)
  }))%>%
  filter(Date >= min(Date) + Delta, Date <= max(Date) - Delta)


# lisser pour avoir une valeur moyenne à chaque semaine
n <- 2      # pas entre les dates (ex : 7 jours)
delta <- 100  # demi-largeur de la fenêtre glissante (ex : 3 jours)

# Dates de référence tous les n jours
dates_ref <- seq(min(data_cocaine$Date), max(data_cocaine$Date), by = n)

# Moyenne glissante autour de chaque date de référence
df_moyenne <- lapply(dates_ref, function(t) {
  data_cocaine %>%
    filter(Date >= t - days(delta), Date <= t + days(delta)) %>%
    summarise(date_centrale = t, moyenne = mean(percentage, na.rm = TRUE))
}) %>%
  bind_rows() %>% 
  filter(date_centrale >= min(date_centrale) + delta, date_centrale <= max(date_centrale) - delta)





################################################################################
# PLOTS ########################################################################
################################################################################

plot_coarse = ggplot(data_cocaine_coarse, aes(x = date_months, y = mean)) +
  geom_point() +
  geom_line() +
  labs(x = "Mois",
       y = "Pureté de la cocaïne (équivalent base)",
       title = paste0("Évolution mensuelle de la pureté de la cocaïne, N=",nrow(data_cocaine_r))) +
  theme_minimal()

ggsave("plot_purete_cocaine_coarse.pdf",plot_coarse)

plot_lis = ggplot(data_cocaine_lis, aes(x = Date, y = moyenne_glissante)) +
  geom_point() +
  geom_line() +
  labs(x = "Date",
       y = "Pureté de la cocaïne (équivalent base) en %",
       title = paste0("Évolution lissée sur 1 mois de la pureté de la cocaïne, N=",nrow(data_cocaine_r))) +
  theme_minimal()

ggsave("plot_purete_cocaine_lis.pdf",plot_lis)

################################################################################
# calculer pourcentage ou cocaïne !=0 ##########################################
################################################################################

data_zero = data_cocaine %>% filter(percentage == 0)
nrow(data_zero)/nrow(data_cocaine_r)

data_no_cocaine=data_cocaine %>% 
  filter(percentage == 0 | (grepl("^[^0-9]",Percent_plus) & !str_detect(Percent_plus,"Coca")))
#9 échantillons problèmatiques parmi les 528, 3 sans cocaïne (ketamine, 2MMC, tétracaïne)


################################################################################
# Histogramme des puretés ######################################################
################################################################################

ggplot(data_cocaine_r, aes(x = percentage)) +
  geom_histogram(binwidth = 5, fill = "firebrick2", color = "white", boundary = 0, closed = "left") +
  scale_x_continuous(limits = c(0, 100), breaks = seq(0, 100, by = 10)) +
  labs(
    title = paste0("Distribution de la pureté de la cocaïne (en équivalent base), N=",nrow(data_cocaine_r)),
    x = "Pureté (%)",
    y = "Occurence"
  ) +
  geom_vline(xintercept = 100*ratio_base_sel, linetype="dashed")+
  theme_minimal(base_size = 14)

ggsave("histo_purete_cocaine.pdf")



################################################################################
# Pie chart sur mode d'approvisionnement #######################################
################################################################################

df_pie <- data_cocaine %>%
  filter(`Mode d'approvisionnement` != "Produits de coupe et commentaires :" & !is.na(`Mode d'approvisionnement`)) %>% 
  filter(`Mode d'approvisionnement` != "Revendeur habituel" & `Mode d'approvisionnement` != "Revendeur occasionnel") %>% 
  #filter(year(Date) == year(Sys.Date()) - 1) %>% 
  group_by(`Mode d'approvisionnement`) %>%
  summarise(somme = n()) %>%
  mutate(
    pourcent = somme / sum(somme) * 100,
    categorie_label = paste0(`Mode d'approvisionnement`, " (", round(pourcent, 1), "%)")
  ) %>%
  arrange(somme) %>%
  mutate(categorie_label = factor(categorie_label, levels = categorie_label))

ggplot(df_pie, aes(x = "", y = somme, fill = categorie_label)) +
  geom_col(width = 1) +
  coord_polar(theta = "y") +
  labs(title = paste0("Répartition des échantillons par mode d'approvisionnement (%), N=",nrow(data_cocaine_r)),
       fill = "Mode d'approvisionnement") +
  theme_void() +
  guides(fill = guide_legend(reverse = TRUE))

ggsave("Prop_approvisionnement_cocaine.pdf")


################################################################################
# régression pour la pureté moyenne en fonction du type de fournisseur #########
################################################################################
data_reg=data_cocaine %>%
  filter(`Mode d'approvisionnement` != "Produits de coupe et commentaires :" & !is.na(`Mode d'approvisionnement`)) %>% 
  filter(`Mode d'approvisionnement` != "Revendeur habituel" & `Mode d'approvisionnement` != "Revendeur occasionnel") %>% 
  mutate(`Mode d'approvisionnement` = factor(`Mode d'approvisionnement`, levels = rev(unlist(df_pie %>% select(`Mode d'approvisionnement`)))))

model = lm(percentage ~ `Mode d'approvisionnement`, data=data_reg)
stargazer(model, type="latex")


################################################################################
# Pie chart sur le support #####################################################
################################################################################
df_support_0=data_cocaine %>% 
  filter(! is.na(Support))

df_support=df_support_0 %>% 
  group_by(Support) %>%
  summarise(somme = n()) %>%
  mutate(
    pourcent = somme / sum(somme) * 100,
    categorie_label = paste0(Support, " (", round(pourcent, 1), "%)")
  ) %>%
  arrange(somme) %>%
  mutate(categorie_label = factor(categorie_label, levels = categorie_label))

ggplot(df_support, aes(x = "", y = somme, fill = categorie_label)) +
  geom_col(width = 1) +
  coord_polar(theta = "y") +
  labs(title = paste0("Répartition des échantillons par support (%), N=",nrow(df_support_0)),
       fill = "Support") +
  theme_void() +
  guides(fill = guide_legend(reverse = TRUE))

ggsave("Prop_support_cocaine.pdf")


################################################################################
# Pie chart sur l'aspect #####################################################
################################################################################
df_aspect_0=data_cocaine %>% 
  filter(! is.na(Aspect)) %>% 
  mutate(Aspect = tolower(Aspect)) %>% 
  mutate(Aspect = case_when(str_detect(Aspect,"blanc")~"blanc",
                            .default=Aspect))
         
df_aspect=df_aspect_0 %>% 
  group_by(Aspect) %>%
  summarise(somme = n()) %>%
  mutate(
    pourcent = somme / sum(somme) * 100,
    categorie_label = paste0(Aspect, " (", round(pourcent, 1), "%)")
  ) %>%
  arrange(somme) %>%
  mutate(categorie_label = factor(categorie_label, levels = categorie_label))

ggplot(df_aspect, aes(x = "", y = somme, fill = categorie_label)) +
  geom_col(width = 1) +
  coord_polar(theta = "y") +
  labs(title = paste0("Répartition des échantillons par aspect (%), N=",nrow(df_aspect_0)),
       fill = "Aspect") +
  theme_void() +
  guides(fill = guide_legend(reverse = TRUE))

ggsave("Prop_aspect_cocaine.pdf")



##############################################################################
##############################################################################
##############################################################################
##############################################################################
##############################################################################
data_bimestre <- data_cocaine %>%
  mutate(
    month = month(Date),
    bimestre = 1 + (month - 1) %/% 2,  # Diviser le mois pour obtenir un bimestre (1-2, 3-4, etc.)
    date_bimestre = floor_date(Date, "year") + months((bimestre - 1) * 2)  # Calculer le premier jour du bimestre
  )

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