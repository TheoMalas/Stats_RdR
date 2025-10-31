from django.http import HttpResponse
from django.http import JsonResponse

from django.shortcuts import render
from django.conf import settings

import hashlib
import base64
import json
import subprocess
import os
import shutil

from datetime import datetime

default_Delta = 15
default_no_cut = 'false'
default_unit = 'pourcent'

#Dictionary for the titles of each page
dict_title = {
  'All molecules' : "Analyse par type de molécules",
  'Supply' : "Analyse par mode d'approvisionnement",
  'Cocaïne' : "Statistiques sur la pureté de la cocaïne",
  'Cocaïne_coupe' : "Analyse des produits de coupe sur la cocaïne",
  'Héroïne' : "Statistiques sur la pureté de l'héroïne", 
  'Héroïne_coupe' : "Analyse des produits de coupe sur l'héroïne",
  'Héroïne_sous_produit' : "Analyse des sous-produits de la synthèse de l'héroïne",
  '3-MMC' : "Statistiques sur la pureté de la 3-MMC",
  '3-MMC_coupe' : "Analyse des produits de coupe sur la 3-MMC",
  'MDMA' : "Statistiques sur la pureté de la MDMA sous forme cristal/poudre",
  'Comprimés de MDMA' : "Statistiques sur la teneur en MDMA des cachets d'ecstasy",
  'Kétamine' : "Statistiques sur la pureté de la kétamine",
  'Speed' : "Statistiques sur la pureté du speed",
  'Speed_coupe' : "Analyse des produits de coupe sur le speed", 
  'Résine de Cannabis' : "Statistiques sur la teneur en THC de la résine de cannabis",
  'Herbe de Cannabis' : "Statistiques sur la teneur en THC des fleurs séchées de cannabis",
  '2C-B' : "Statistiques sur la pureté de la 2C-B",
  'Comprimés de 2C-B' : "Statistiques sur la teneur en 2C-B des comprimés"
}

#Dictionary for the urls of the Psychowiki
dict_urls = {
  'Cocaïne' : 'https://www.psychoactif.org/psychowiki/index.php?title=Cocaine,_effets,_risques,_t%C3%A9moignages',
  'Héroïne' : 'https://www.psychoactif.org/psychowiki/index.php?title=H%C3%A9ro%C3%AFne,_effets,_risques,_t%C3%A9moignages',
  '3-MMC' : 'https://www.psychoactif.org/psychowiki/index.php?title=3-MMC,_effets,_risques,_t%C3%A9moignages',
  'MDMA' : 'https://www.psychoactif.org/psychowiki/index.php?title=Ecstasy-MDMA,_effets,_risques,_t%C3%A9moignages',
  'Comprimés de MDMA' : 'https://www.psychoactif.org/psychowiki/index.php?title=Ecstasy-MDMA,_effets,_risques,_t%C3%A9moignages',
  'Kétamine' : 'https://www.psychoactif.org/psychowiki/index.php?title=K%C3%A9tamine,_effets,_risques,_t%C3%A9moignages',
  'Speed' : 'https://www.psychoactif.org/psychowiki/index.php?title=Amph%C3%A9tamine-M%C3%A9thamph%C3%A9tamine,_effets,_risques,_t%C3%A9moignages',
  'Résine de Cannabis' : 'https://www.psychoactif.org/psychowiki/index.php?title=Cannabis,_effets,_risques,_t%C3%A9moignages',
  'Herbe de Cannabis' : 'https://www.psychoactif.org/psychowiki/index.php?title=Cannabis,_effets,_risques,_t%C3%A9moignages',
  '2C-B' : 'https://www.psychoactif.org/psychowiki/index.php?title=2C-B,_effets,_risques,_t%C3%A9moignages',
  'Comprimés de 2C-B' : 'https://www.psychoactif.org/psychowiki/index.php?title=2C-B,_effets,_risques,_t%C3%A9moignages'
}
#Dictionary for the presentation of each substance
dict_pres = {
  'Cocaïne' : """La cocaïne est un produit psychoactif de la classe des stimulants du système nerveux central.
               Elle est issue de la feuille du cocaïer et se présente comme une poudre de couleur blanche scintillante.""",
  'Héroïne' : """L'héroïne est un opiacé synthétisé à partir de la morphine naturellement présente dans l'opium (suc du pavot).
               Elle est surtout recherchée pour le bien être psychique et physique qu'elle procure.
               En France, elle se présente généralement sous la forme de poudre allant du beige clair au brun foncé.""",
  '3-MMC' : """La 3-MMC est une molécule de synthèse de la famille des cathinones. Cette drogue psychostimulante et entactogène est 
                apparue en 2011 et peut se présenter comme une poudre planche ou comme de petits cristaux blancs.""",
  'MDMA' : """La MDMA est une molécule de synthèse de la famille des amphétamines et se présente sous deux formes : soit sous forme de cristaux/poudre
            translucide, soit sous forme de cachets de taille et de couleur variable appelés "ecstasy". Sur cette page, vous retrouverez l'analyse
             pour la forme cristal/poudre. L'analyse des cachets d'ecstasy possède aussi sa <a href="http://psychotopia.psychoactif.org/histo-comprime-mdma/" target="_blank">page dédiée</a>.""",
  'Comprimés de MDMA' : """La MDMA est une molécule de synthèse de la famille des amphétamines et se présente sous deux formes : soit sous forme de cristaux/poudre
            translucide, soit sous forme de cachets de taille et de couleur variable appelés "ecstasy". Sur cette page, vous retrouverez l'analyse
             pour les cachets d'ecstasy. L'analyse des échantillons sous forme de cristal ou de poudre possède aussi sa <a href="http://psychotopia.psychoactif.org/purity-mdma/" target="_blank">page dédiée</a>.""",
  'Kétamine' : """La kétamine est une molécule de la famille des cycloalkylarylamines utilisée comme anesthésique général en médecine humaine et en médecine vétérinaire.
               Elle provoque une anesthésie dissociative (dissociation entre le cortex frontal et le reste du cerveau), ainsi que des possibles hallucinations lors de la période de réveil.
                Elle se présente sous la forme d'une poudre cristalline ou d'un liquide incolore, inodore et sans saveur.""",
  'Speed' : """Le "speed" est une appellation généraliste pour désigner principalement l'amphétamine et la méthamphétamine. Il s'agit
             d'une drogue euphorisante et stimulante qui peut se présenter sous la forme de poudre jaunâtre avec une forte odeur chimique, mais aussi sous la forme de cristaux ou de cachets. 
             L'analyse présentée ici se restreint aux formes poudre et cristal.""",
  'Résine de Cannabis' : """Le cannabis est un genre botanique qui rassemble des plantes annuelles de la famille des Cannabaceae.
                         C'est le taux de THC présent dans chaque variété botanique qui détermine si elle est utilisée comme chanvre 
                         à usage agricole (taux faible) ou pour ses effets psychoactives (taux élevé). Ces effets sont variés et dépendants de la variété : citons entre autres 
                         euphorie, excitation, relaxation, augmentation des sensations, sommeil, ... Le cannabis se présente sous différentes formes dont les plus fréquentes sont
                         la fleur séchée et la résine. Sur cette page, vous retrouverez l'analyse de la résine de cannabis mais l'analyse des fleurs séchées possède aussi sa page dédiée.""",
  'Herbe de Cannabis' : """Le cannabis est un genre botanique qui rassemble des plantes annuelles de la famille des Cannabaceae.
                         C'est le taux de THC présent dans chaque variété botanique qui détermine si elle est utilisée comme chanvre 
                         à usage agricole (taux faible) ou pour ses effets psychoactives (taux élevé). Ces effets sont variés et dépendants de la variété : citons entre autres 
                         euphorie, excitation, relaxation, augmentation des sensations, sommeil, ... Le cannabis se présente sous différentes formes dont les plus fréquentes sont
                         la fleur séchée et la résine. Sur cette page, vous retrouverez l'analyse de les fleurs séchées de cannabis mais l'analyse de la résine possède aussi sa page dédiée.""",
  '2C-B' :"""La 2C-B est une substance psychédélique synthétique de la classe des phénéthylamines recherchée pour ses  effets psychédéliques et entactogènes. Elle se présente sous la forme de poudre ou de comprimé.
             Sur cette page, vous retrouverez l'analyse
             pour la forme poudre. L'analyse des comprimés de 2C-B possède aussi sa <a href="http://psychotopia.psychoactif.org/histo-comprime-2cb/" target="_blank">page dédiée</a>.""",
  'Comprimés de 2C-B' : """ La 2C-B est une substance psychédélique synthétique de la classe des phénéthylamines recherchée pour ses  effets psychédéliques et entactogènes. Elle se présente sous la forme de poudre ou de comprimé.
                        Sur cette page, vous retrouverez l'analyse
                        pour les comprimés de 2C-B. L'analyse des échantillons sous forme de poudre possède aussi sa <a href="http://psychotopia.psychoactif.org/purity-2cb/" target="_blank">page dédiée</a>.""",
}

# FrontEnd

def molecules_view(request):

  date_debut, date_fin = get_dates(request)
  familles_list = get_familles(request)

  args = {
    "date_debut" : date_debut,
    "date_fin" : date_fin,
    "familles_list" : ",".join(familles_list),
  }
  
  all_molecules_data = runScript("all/pie_chart_all_molecules", args)    
  area_all_molecules_data = runScript("all/stacked_area_prop_all_molecules", args)
  conso_all_molecules_data = runScript("all/pie_chart_conso_all_molecules", args)

  args["mode"] = "abs"
  map_data_abs = runScript("all/carte_region_france_all_molecules", args)

  args["mode"] = "prop"
  map_data_prop = runScript("all/carte_region_france_all_molecules", args)
  page_name="All molecules"

  return render(request, 'pages/all_molecules.html', {
      'all_molecules_data_count' : all_molecules_data["count"][0],
      'all_molecules_data': json.dumps(all_molecules_data),
      'area_all_molecules_data' : json.dumps(area_all_molecules_data),
      'map_data_abs' : json.dumps(map_data_abs),
      'map_data_abs_color' : json.dumps(generate_color_map(map_data_abs, (120,60,85), (200,100,30), "number")),
      'map_data_prop' : json.dumps(map_data_prop),
      'map_data_prop_color' : json.dumps(generate_color_map(map_data_prop, (50,100,70), (0, 100, 40), "number")),
      'conso_all_molecules_data' : json.dumps(conso_all_molecules_data),
      'page_title' : dict_title[page_name]
  })

def supply_view(request):

  date_debut, date_fin = get_dates(request)
  familles_list = get_familles(request)
  
  args = {
    "date_debut" : date_debut,
    "date_fin" : date_fin,
    "familles_list" : ",".join(familles_list),
  }

  data = runScript("all/pie_chart_supply_all_molecules", args)
  page_name="Supply"
  
  return render(request, 'pages/supply.html', { 
      'data_count' : data["count"][0],
      'data' : json.dumps(data),
      'page_title' : dict_title[page_name]
  })

def coupe_cocaine_view(request):

  date_debut, date_fin = get_dates(request)
  
  args = {
    "date_debut" : date_debut,
    "date_fin" : date_fin,
  }
    
  data = runScript("cocaine/diagram_coupe_cocaine", args)
  molecule_name = 'Cocaïne'
  page_name = 'Cocaïne_coupe'

  return render(request, 'pages/coupe.html', { 
    'data_count' : data["count"][0],
    'molecule_name' : molecule_name,
    'data' : json.dumps(data),
    'page_title' : dict_title[page_name],
    'url_wiki' : dict_urls[molecule_name],
    'presentation' : dict_pres[molecule_name]
  })

def coupe_heroine_view(request):

  date_debut, date_fin = get_dates(request)
  
  args = {
    "date_debut" : date_debut,
    "date_fin" : date_fin,
  }
  
  data = runScript("heroine/diagram_coupe_heroine", args)
  molecule_name = 'Héroïne'
  page_name = 'Héroïne_coupe'
  
  return render(request, 'pages/coupe.html', { 
    'data_count' : data["count"][0],
    'molecule_name': molecule_name,
    'data' : json.dumps(data),
    'page_title' : dict_title[page_name],
    'url_wiki' : dict_urls[molecule_name],
    'presentation' : dict_pres[molecule_name]
  })

def coupe_speed_view(request):

  date_debut, date_fin = get_dates(request)
  
  args = {
    "date_debut" : date_debut,
    "date_fin" : date_fin,
  }
  
  data = runScript("speed/diagram_coupe_speed", args)
  molecule_name = 'Speed'
  page_name = 'Speed_coupe'
  
  return render(request, 'pages/coupe.html', { 
    'data_count' : data["count"][0],
    'molecule_name': molecule_name,
    'data' : json.dumps(data),
    'page_title' : dict_title[page_name],
    'url_wiki' : dict_urls[molecule_name],
    'presentation' : dict_pres[molecule_name]
  })

def coupe_3mmc_view(request):
  date_debut, date_fin = get_dates(request)
  
  args = {
    "date_debut" : date_debut,
    "date_fin" : date_fin,
  }

  data = runScript("3mmc/coupe_3mmc", args)
  molecule_name = '3-MMC'
  page_name = '3-MMC_coupe'

  return render(request, 'pages/coupe.html',{
    'data_count' : data["count"][0],
    'molecule_name': molecule_name,
    'data' : json.dumps(data),
    'page_title' : dict_title[page_name],
    'url_wiki' : dict_urls[molecule_name],
    'presentation' : dict_pres[molecule_name]
  })


def purity_cocaine_view(request):

  date_debut, date_fin = get_dates(request)
  Delta = request.GET.get("range", default_Delta)
  
  args_1 = {
    "date_debut" : date_debut,
    "date_fin" : date_fin,
    "Delta" : Delta,
    "mode" : "moyenne"
  }
  data = runScript("cocaine/histo_purity_cocaine", args_1)

  args_2 = {
    "date_debut" : date_debut,
    "date_fin" : date_fin,
    "Delta" : Delta,
    "mode" : "médiane"
  }
  data_2 = runScript("cocaine/histo_purity_cocaine", args_2)

  data_reg = runScript("cocaine/regression_purity_supply_cocaine", args_1)

  args_3 = {
    "date_debut" : date_debut,
    "date_fin" : date_fin
  }
  map_data = runScript("cocaine/purity_region_cocaine", args_3)

  reg_map_data = runScript("cocaine/regression_purity_vs_region_fe_cocaine", args_3)
  molecule_name = "Cocaïne"

  return render(request, 'pages/purity.html', { 
    'data_count' : data["count"][0],
    'data' : json.dumps(data),
    'data_2' : json.dumps(data_2),
    'regression_data' : json.dumps(data_reg),
    'molecule_name': molecule_name,
    'map_data' : json.dumps(map_data),
    'map_data_color' : json.dumps(generate_color_map(map_data, (120,60,85), (200,100,30))),
    'reg_map_data' : json.dumps(reg_map_data),
    'page_title' : dict_title[molecule_name],
    'url_wiki' : dict_urls[molecule_name],
    'presentation' : dict_pres[molecule_name],
    'unit' : default_unit,
    'Delta' : Delta
  })

def purity_mdma_view(request):

  date_debut, date_fin = get_dates(request)
  Delta = request.GET.get("range", default_Delta)
  
  args_1 = {
    "date_debut" : date_debut,
    "date_fin" : date_fin,
    "Delta" : Delta,
    "mode" : "moyenne"
  }
  data = runScript("mdma/histo_purity_mdma", args_1)
  
  args_2 = {
    "date_debut" : date_debut,
    "date_fin" : date_fin,
    "Delta" : Delta,
    "mode" : "médiane"
  }
  data_2 = runScript("mdma/histo_purity_mdma", args_2)

  data_reg = runScript("mdma/regression_purity_supply_mdma", args_1)

  args_3 = {
    "date_debut" : date_debut,
    "date_fin" : date_fin,
  }
  map_data = runScript("mdma/purity_region_mdma", args_3)
  reg_map_data = runScript("mdma/regression_purity_vs_region_fe_mdma", args_3)
  molecule_name = "MDMA"
  
  return render(request, 'pages/purity.html', { 
    'data_count' : data["count"][0],
    'data' : json.dumps(data),
    'data_2' : json.dumps(data_2),
    'regression_data' : json.dumps(data_reg),
    'map_data' : json.dumps(map_data),
    'map_data_color' : json.dumps(generate_color_map(map_data, (120,60,85), (200,100,30))),
    'molecule_name': molecule_name,
    'reg_map_data' : json.dumps(reg_map_data),
    'page_title' : dict_title[molecule_name],
    'url_wiki' : dict_urls[molecule_name],
    'presentation' : dict_pres[molecule_name],
    'unit' : default_unit,
    'Delta' : Delta
  })

def purity_heroine_view(request):

  date_debut, date_fin = get_dates(request)
  Delta = request.GET.get("range", default_Delta)
  
  args_1 = {
    "date_debut" : date_debut,
    "date_fin" : date_fin,
    "Delta" : Delta,
    "mode" : "moyenne"
  }
  data = runScript("heroine/histo_purity_heroine", args_1)

  args_2 = {
    "date_debut" : date_debut,
    "date_fin" : date_fin,
    "Delta" : Delta,
    "mode" : "médiane"
  }
  data_2 = runScript("heroine/histo_purity_heroine", args_2)
  data_reg = runScript("heroine/regression_purity_supply_heroine", args_1)
  regression_data_consommation = runScript("heroine/regression_conso_purity_heroine", args_1)

  args_3 = {
    "date_debut" : date_debut,
    "date_fin" : date_fin,
  }
  map_data = runScript("heroine/purity_region_heroine", args_3)
  reg_map_data = runScript("heroine/regression_purity_vs_region_fe_heroine", args_3)
  molecule_name = "Héroïne"
  
  return render(request, 'pages/purity.html', { 
    'data_count' : data["count"][0],
    'data' : json.dumps(data),
    'data_2' : json.dumps(data_2),
    'regression_data' : json.dumps(data_reg),
    'regression_data_consommation' : json.dumps(regression_data_consommation),
    'map_data' : json.dumps(map_data),
    'map_data_color' : json.dumps(generate_color_map(map_data, (120,60,85), (200,100,30))),
    'molecule_name': molecule_name,
    'reg_map_data' : json.dumps(reg_map_data),
    'page_title' : dict_title[molecule_name],
    'url_wiki' : dict_urls[molecule_name],
    'presentation' : dict_pres[molecule_name],
    'unit' : default_unit,
    'Delta' : Delta
  })

def purity_3mmc_view(request):

  date_debut, date_fin = get_dates(request)
  Delta = request.GET.get("range", default_Delta)
  no_cut = request.GET.get("no_cut", default_no_cut)

  args_1 = {
    "date_debut" : date_debut,
    "date_fin" : date_fin,
    "Delta" : Delta,
    "mode" : "moyenne",
    "no_cut" : no_cut
  }
  print(args_1)

  data = runScript("3mmc/histo_purity_3mmc", args_1)

  args_1["mode"] = "médiane"
  
  data_2 = runScript("3mmc/histo_purity_3mmc", args_1)
  data_reg = runScript("3mmc/regression_purity_supply_3mmc", args_1)
  
  args_3 = {
    "date_debut" : date_debut,
    "date_fin" : date_fin,
    "no_cut" : no_cut
  }
  map_data = runScript("3mmc/purity_region_3mmc", args_3)
  reg_map_data = runScript("3mmc/regression_purity_vs_region_fe_3mmc", args_3)
  molecule_name = '3-MMC'

  return render(request, 'pages/purity.html', { 
    'data_count' : data["count"][0],
    'data' : json.dumps(data),
    'data_2' : json.dumps(data_2),
    'regression_data' : json.dumps(data_reg),
    'molecule_name': molecule_name,
    'map_data' : json.dumps(map_data),
    'map_data_color' : json.dumps(generate_color_map(map_data, (120,60,85), (200,100,30))),
    'reg_map_data' : json.dumps(reg_map_data),
    'page_title' : dict_title[molecule_name],
    'url_wiki' : dict_urls[molecule_name],
    'presentation' : dict_pres[molecule_name],
    'unit' : default_unit,
    'Delta' : Delta
  })

def purity_ketamine_view(request):

  date_debut, date_fin = get_dates(request)
  Delta = request.GET.get("range", default_Delta)
  
  args_1 = {
    "date_debut" : date_debut,
    "date_fin" : date_fin,
    "Delta" : Delta,
    "mode" : "moyenne"
  }
  data = runScript("ketamine/histo_purity_ketamine", args_1)

  args_2 = {
    "date_debut" : date_debut,
    "date_fin" : date_fin,
    "Delta" : Delta,
    "mode" : "médiane"
  }
  data_2 = runScript("ketamine/histo_purity_ketamine", args_2)

  data_reg = runScript("ketamine/regression_purity_supply_ketamine", args_1)

  args_3 = {
    "date_debut" : date_debut,
    "date_fin" : date_fin,
  }
  map_data = runScript("ketamine/purity_region_ketamine", args_3)
  reg_map_data = runScript("ketamine/regression_purity_vs_region_fe_ketamine", args_3)
  molecule_name = "Kétamine"
  
  return render(request, 'pages/purity.html', { 
    'data_count' : data["count"][0],
    'data' : json.dumps(data),
    'data_2' : json.dumps(data_2),
    'regression_data' : json.dumps(data_reg),
    'map_data' : json.dumps(map_data),
    'map_data_color' : json.dumps(generate_color_map(map_data, (120,60,85), (200,100,30))),
    'molecule_name': molecule_name,
    'reg_map_data' : json.dumps(reg_map_data),
    'page_title' : dict_title[molecule_name],
    'url_wiki' : dict_urls[molecule_name],
    'presentation' : dict_pres[molecule_name],
    'unit' : default_unit,
    'Delta' : Delta
  })
  

def purity_speed_view(request):

  date_debut, date_fin = get_dates(request)
  Delta = request.GET.get("range", default_Delta)
  
  args_1 = {
    "date_debut" : date_debut,
    "date_fin" : date_fin,
    "Delta" : Delta,
    "mode" : "moyenne"
  }

  data = runScript("speed/histo_purity_speed", args_1)

  args_2 = {
    "date_debut" : date_debut,
    "date_fin" : date_fin,
    "Delta" : Delta,
    "mode" : "médiane"
  }

  data_2 = runScript("speed/histo_purity_speed", args_2)
  data_reg = runScript("speed/regression_purity_supply_speed", args_1)

  args_3 = {
    "date_debut" : date_debut,
    "date_fin" : date_fin,
  }
  map_data = runScript("speed/purity_region_speed", args_3)
  reg_map_data = runScript("speed/regression_purity_vs_region_fe_speed", args_3)
  molecule_name = "Speed"
  
  return render(request, 'pages/purity.html', {
    'data_count' : data["count"][0], 
    'data' : json.dumps(data),
    'data_2' : json.dumps(data_2),
    'regression_data' : json.dumps(data_reg),
    'map_data' : json.dumps(map_data),
    'map_data_color' : json.dumps(generate_color_map(map_data, (120,60,85), (200,100,30))),
    'molecule_name': molecule_name,
    'reg_map_data' : json.dumps(reg_map_data),
    'page_title' : dict_title[molecule_name],
    'url_wiki' : dict_urls[molecule_name],
    'presentation' : dict_pres[molecule_name],
    'unit' : default_unit,
    'Delta' : Delta
  })  
  

def purity_cannabis_THC_resine_view(request):

  date_debut, date_fin = get_dates(request)
  Delta = request.GET.get("range", default_Delta)
  
  args_1 = {
    "date_debut" : date_debut,
    "date_fin" : date_fin,
    "Delta" : Delta,
    "mode" : "moyenne"
  }
  data = runScript("cannabis/histo_purity_cannabis_THC_resine", args_1)

  args_2 = {
    "date_debut" : date_debut,
    "date_fin" : date_fin,
    "Delta" : Delta,
    "mode" : "médiane"
  }
  data_2 = runScript("cannabis/histo_purity_cannabis_THC_resine", args_2)
  data_reg = runScript("cannabis/regression_purity_supply_THC_resine", args_1)

  args_3 = {
    "date_debut" : date_debut,
    "date_fin" : date_fin,
  }
  map_data = runScript("cannabis/purity_region_cannabis_THC_resine", args_3)
  molecule_name = "Résine de Cannabis"
  
  return render(request, 'pages/purity.html', { 
    'data_count' : data["count"][0],
    'data' : json.dumps(data),
    'data_2' : json.dumps(data_2),
    'regression_data' : json.dumps(data_reg),
    'map_data' : json.dumps(map_data),
    'map_data_color' : json.dumps(generate_color_map(map_data, (120,60,85), (200,100,30))),
    'molecule_name': molecule_name,
    'page_title' : dict_title[molecule_name],
    'url_wiki' : dict_urls[molecule_name],
    'presentation' : dict_pres[molecule_name],
    'unit' : default_unit,
    'Delta' : Delta
  })  
  

def purity_cannabis_THC_herbe_view(request):

  date_debut, date_fin = get_dates(request)
  Delta = request.GET.get("range", default_Delta)
  
  args_1 = {
    "date_debut" : date_debut,
    "date_fin" : date_fin,
    "Delta" : Delta,
    "mode" : "moyenne"
  }
  data = runScript("cannabis/histo_purity_cannabis_THC_herbe", args_1)

  args_2 = {
    "date_debut" : date_debut,
    "date_fin" : date_fin,
    "Delta" : Delta,
    "mode" : "médiane"
  }
  data_2 = runScript("cannabis/histo_purity_cannabis_THC_herbe", args_2)
  
  data_reg = runScript("cannabis/regression_purity_supply_THC_herbe", args_1)

  args_3 = {
    "date_debut" : date_debut,
    "date_fin" : date_fin,
  }
  map_data = runScript("cannabis/purity_region_cannabis_THC_herbe", args_3)
  molecule_name = "Herbe de Cannabis"
  
  return render(request, 'pages/purity.html', { 
    'data_count' : data["count"][0],
    'data' : json.dumps(data),
    'data_2' : json.dumps(data_2),
    'regression_data' : json.dumps(data_reg),
    'map_data' : json.dumps(map_data),
    'map_data_color' : json.dumps(generate_color_map(map_data, (120,60,85), (200,100,30))),
    'molecule_name': molecule_name,
    'page_title' : dict_title[molecule_name],
    'url_wiki' : dict_urls[molecule_name],
    'presentation' : dict_pres[molecule_name],
    'unit' : default_unit,
    'Delta' : Delta
  })

def purity_2cb_view(request):

  date_debut, date_fin = get_dates(request)
  Delta = request.GET.get("range", default_Delta)
  
  args_1 = {
    "date_debut" : date_debut,
    "date_fin" : date_fin,
    "Delta" : Delta,
    "mode" : "moyenne"
  }

  data = runScript("2cb/histo_purity_2cb", args_1)

  args_2 = {
    "date_debut" : date_debut,
    "date_fin" : date_fin,
    "Delta" : Delta,
    "mode" : "médiane"
  }

  data_2 = runScript("2cb/histo_purity_2cb", args_2)
  data_reg = runScript("2cb/regression_purity_supply_2cb", args_1)

  args_3 = {
    "date_debut" : date_debut,
    "date_fin" : date_fin,
  }
  map_data = runScript("2cb/purity_region_2cb", args_3)
  reg_map_data = runScript("2cb/regression_purity_vs_region_fe_2cb", args_3)
  molecule_name = "2C-B"
  
  return render(request, 'pages/purity.html', {
    'data_count' : data["count"][0], 
    'data' : json.dumps(data),
    'data_2' : json.dumps(data_2),
    'regression_data' : json.dumps(data_reg),
    'map_data' : json.dumps(map_data),
    'map_data_color' : json.dumps(generate_color_map(map_data, (120,60,85), (200,100,30))),
    'molecule_name': molecule_name,
    'reg_map_data' : json.dumps(reg_map_data),
    'page_title' : dict_title[molecule_name],
    'url_wiki' : dict_urls[molecule_name],
    'presentation' : dict_pres[molecule_name],
    'unit' : default_unit,
    'Delta' : Delta
  })  

def histo_comprime_mdma_view(request):

  date_debut, date_fin = get_dates(request)
  Delta = request.GET.get("range", default_Delta)

  args = {    
    "date_debut" : date_debut,
    "date_fin" : date_fin,
    }
  
  data_reg_dose_poids = runScript("mdma/regression_poids_comprime_quantite_mdma", args)
  
  args["Delta"] = Delta
  args["mode"] = "moyenne"

  data = runScript("mdma/histo_comprime_mdma", args)

  args["mode"] = "médiane"
  data_2 = runScript("mdma/histo_comprime_mdma", args)

  molecule_name = "Comprimés de MDMA"
    
  return render(request, 'pages/purity.html', { 
    'data_count' : data["count"][0],
    'data' : json.dumps(data),
    'data_2' : json.dumps(data_2),
    'data_reg_dose_poids' : json.dumps(data_reg_dose_poids),
    'molecule_name': molecule_name,
    'page_title' : dict_title[molecule_name],
    'url_wiki' : dict_urls[molecule_name],
    'presentation' : dict_pres[molecule_name],
    'unit' : "poids",
    'Delta' : Delta
  })

def histo_comprime_2cb_view(request):

  date_debut, date_fin = get_dates(request)
  Delta = request.GET.get("range", default_Delta)

  args = {    
    "date_debut" : date_debut,
    "date_fin" : date_fin,
    }
  
  data_reg_dose_poids = runScript("2cb/regression_poids_comprime_quantite_2cb", args)
  
  args["Delta"] = Delta
  args["mode"] = "moyenne"

  data = runScript("2cb/histo_comprime_2cb", args)

  args["mode"] = "médiane"
  data_2 = runScript("2cb/histo_comprime_2cb", args)

  molecule_name = "Comprimés de 2C-B"
    
  return render(request, 'pages/purity.html', { 
    'data_count' : data["count"][0],
    'data' : json.dumps(data),
    'data_2' : json.dumps(data_2),
    'data_reg_dose_poids' : json.dumps(data_reg_dose_poids),
    'molecule_name': molecule_name,
    'page_title' : dict_title[molecule_name],
    'url_wiki' : dict_urls[molecule_name],
    'presentation' : dict_pres[molecule_name],
    'unit' : "poids",
    'Delta' : Delta
  })

def sous_produit_heroine_view(request):

  date_debut, date_fin = get_dates(request)
  
  args = {
    "date_debut" : date_debut,
    "date_fin" : date_fin,
  }
  
  data = runScript("heroine/diagram_sous_produit_heroine", args)
  molecule_name = 'Héroïne'
  page_name = 'Héroïne_sous_produit'
  
  return render(request, 'pages/sous_produit.html', { 
    'data_count' : data["count"][0],
    'molecule_name': molecule_name,
    'data' : json.dumps(data),
    'page_title' : dict_title[page_name],
    'url_wiki' : dict_urls[molecule_name],
    'presentation' : dict_pres[molecule_name]
  })

def accueil_view(request):
  return render(request, 'pages/accueil.html',{})

def faq_view(request):
  return render(request, 'pages/faq.html',{})

# Map Functions

def generate_color_map(data, start_hsl=(120, 60, 85), end_hsl=(120, 100, 25), mode="pourcent"):
    # Extraire la valeur scalaire depuis les listes
    scalar_data = {k: v[0] for k, v in data.items()}

    values = list(scalar_data.values())
    values = [v[0] for v in data.values() if isinstance(v[0], (float, int))]

    min_val = min(values)
    max_val = max(values)

    color_map = {}

    for key, value in scalar_data.items():
        if (not isinstance(value, (float, int))):
          continue
        
        t = (value - min_val) / (max_val - min_val) if max_val != min_val else 0

        # Interpolation HSL
        h = start_hsl[0] + t * (end_hsl[0] - start_hsl[0])
        s = start_hsl[1] + t * (end_hsl[1] - start_hsl[1])
        l = start_hsl[2] + t * (end_hsl[2] - start_hsl[2])

        color_map[key] = f"hsl({h:.0f}, {s:.1f}%, {l:.1f}%)"
    color_map["start_hsl"] = start_hsl
    color_map["end_hsl"] = end_hsl
    color_map["mode"] = mode

    return color_map

# BackEnd

def obj_to_string(obj):

  res = ''

  for key, value in obj.items():
    res += str(key) + "=" + str(value) + " "

  return res[:-1]



def obj_to_hash(obj, length=16):
  obj_str = str(sorted(obj.items()))
  hash_bytes = hashlib.sha256(obj_str.encode()).digest()
  base64_hash = base64.urlsafe_b64encode(hash_bytes).decode('utf-8')
  return base64_hash[:length]



def runScript(scriptID, args):

  # Update OutputPath
  outputPath = 'output/' + scriptID + '_' + obj_to_hash(args) + '.json'
  args["outputPath"] = outputPath

  # Check the cache
  cachedData = basicCache(outputPath)
  if cachedData != None:
     return cachedData
  
  cmd=["Rscript","scriptR/" + scriptID + ".R"] + [obj_to_string(args)]

  subprocess.run(cmd)

  json_file_path = os.path.join(settings.BASE_DIR, outputPath)
  with open(json_file_path, 'r') as f:
      data = json.load(f)

  return data

def basicCache(path):

  if not os.path.exists(path):
    return None

  json_file_path = os.path.join(settings.BASE_DIR, path)
  with open(json_file_path, 'r') as f:
      data = json.load(f)

  return data

def cleanCache(request):

  path = os.path.join(settings.BASE_DIR, 'output')

  if not os.path.exists(path):
    return HttpResponse(status = 201)

  shutil.rmtree(path)
  return HttpResponse(status = 200)

def get_dates(request):
  default_end = "2026-07-22" #datetime.today().strftime('%Y-%m-%d') #set a specific date
  default_start = "2022-06-22" #first analysis done
  date_debut = request.GET.get("date_debut", default_start)
  date_fin = request.GET.get("date_fin", default_end)

  return date_debut, date_fin

def get_familles(request): 
  familles_str = request.GET.get("familles")
  if isinstance(familles_str, str):
      familles_list = familles_str.split(",")
  else:
      familles_list = []

  return familles_list