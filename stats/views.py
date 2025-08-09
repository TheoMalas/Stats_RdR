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

  return render(request, 'pages/all_molecules.html', { 
      'all_molecules_data': json.dumps(all_molecules_data),
      'area_all_molecules_data' : json.dumps(area_all_molecules_data),
      'map_data_abs' : json.dumps(map_data_abs),
      'map_data_abs_color' : json.dumps(generate_color_map(map_data_abs, (120,60,85), (200,100,30))),
      'map_data_prop' : json.dumps(map_data_prop),
      'map_data_prop_color' : json.dumps(generate_color_map(map_data_prop, (50,100,70), (0, 100, 40))),
      'conso_all_molecules_data' : json.dumps(conso_all_molecules_data)
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
  
  return render(request, 'pages/supply.html', { 
      'data' : json.dumps(data),
  })

def cocaine_view(request):

  date_debut, date_fin = get_dates(request)
  
  args = {
    "date_debut" : date_debut,
    "date_fin" : date_fin,
  }
    
  data = runScript("cocaine/diagram_coupe_cocaine", args)

  return render(request, 'pages/coupe.html', { 
    'data' : json.dumps(data),
  })

def heroine_view(request):

  date_debut, date_fin = get_dates(request)
  
  args = {
    "date_debut" : date_debut,
    "date_fin" : date_fin,
  }
  
  data = runScript("heroine/diagram_coupe_heroine", args)
  
  return render(request, 'pages/coupe.html', { 
    'data' : json.dumps(data),
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

  return render(request, 'pages/purity.html', { 
    'data' : json.dumps(data),
    'data_2' : json.dumps(data_2),
    'regression_data' : json.dumps(data_reg),
    'molecule_name': "Cocaïne",
    'map_data' : json.dumps(map_data),
    'map_data_color' : json.dumps(generate_color_map(map_data, (120,60,85), (200,100,30))),
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
  
  return render(request, 'pages/purity.html', { 
    'data' : json.dumps(data),
    'data_2' : json.dumps(data_2),
    'regression_data' : json.dumps(data_reg),
    'map_data' : json.dumps(map_data),
    'map_data_color' : json.dumps(generate_color_map(map_data, (120,60,85), (200,100,30))),
    'molecule_name': "MDMA",
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
  
  return render(request, 'pages/purity.html', { 
    'data' : json.dumps(data),
    'data_2' : json.dumps(data_2),
    'regression_data' : json.dumps(data_reg),
    'regression_data_consommation' : json.dumps(regression_data_consommation),
    'map_data' : json.dumps(map_data),
    'map_data_color' : json.dumps(generate_color_map(map_data, (120,60,85), (200,100,30))),
    'molecule_name': "Héroïne",
  })

def purity_3mmc_view(request):

  date_debut, date_fin = get_dates(request)
  Delta = request.GET.get("range", default_Delta)
  
  args_1 = {
    "date_debut" : date_debut,
    "date_fin" : date_fin,
    "Delta" : Delta,
    "mode" : "moyenne"
  }

  data = runScript("3mmc/histo_purity_3mmc", args_1)

  args_2 = {
    "date_debut" : date_debut,
    "date_fin" : date_fin,
    "Delta" : Delta,
    "mode" : "médiane"
  }
  data_2 = runScript("3mmc/histo_purity_3mmc", args_2)
  data_reg = runScript("3mmc/regression_purity_supply_3mmc", args_2)
  
  args_3 = {
    "date_debut" : date_debut,
    "date_fin" : date_fin,
  }
  map_data = runScript("3mmc/purity_region_3mmc", args_3)

  return render(request, 'pages/purity.html', { 
    'data' : json.dumps(data),
    'data_2' : json.dumps(data_2),
    'regression_data' : json.dumps(data_reg),
    'molecule_name': "3-MMC",
    'map_data' : json.dumps(map_data),
    'map_data_color' : json.dumps(generate_color_map(map_data, (120,60,85), (200,100,30))),
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
  
  return render(request, 'pages/purity.html', { 
    'data' : json.dumps(data),
    'data_2' : json.dumps(data_2),
    'regression_data' : json.dumps(data_reg),
    'map_data' : json.dumps(map_data),
    'map_data_color' : json.dumps(generate_color_map(map_data, (120,60,85), (200,100,30))),
    'molecule_name': "Kétamine",
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
  
  return render(request, 'pages/purity.html', { 
    'data' : json.dumps(data),
    'data_2' : json.dumps(data_2),
    'regression_data' : json.dumps(data_reg),
    'map_data' : json.dumps(map_data),
    'map_data_color' : json.dumps(generate_color_map(map_data, (120,60,85), (200,100,30))),
    'molecule_name': "Speed",
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
  
  return render(request, 'pages/purity.html', { 
    'data' : json.dumps(data),
    'data_2' : json.dumps(data_2),
    'regression_data' : json.dumps(data_reg),
    'map_data' : json.dumps(map_data),
    'map_data_color' : json.dumps(generate_color_map(map_data, (120,60,85), (200,100,30))),
    'molecule_name': "Cannabis Résine",
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
  
  return render(request, 'pages/purity.html', { 
    'data' : json.dumps(data),
    'data_2' : json.dumps(data_2),
    'regression_data' : json.dumps(data_reg),
    'map_data' : json.dumps(map_data),
    'map_data_color' : json.dumps(generate_color_map(map_data, (120,60,85), (200,100,30))),
    'molecule_name': "Cannabis Herbe",
  })

def histo_comprime_mdma_view(request):

  date_debut, date_fin = get_dates(request)
  Delta = request.GET.get("range", default_Delta)
  
  args = {
    "date_debut" : date_debut,
    "date_fin" : date_fin,
    "Delta" : Delta,
  }

  data = runScript("mdma/histo_comprime_mdma", args)
    
  return render(request, 'pages/purity.html', { 
    'data' : json.dumps(data),
  })

# Map Functions

def generate_color_map(data, start_hsl=(120, 60, 85), end_hsl=(120, 100, 25)):
    # Extraire la valeur scalaire depuis les listes
    scalar_data = {k: v[0] for k, v in data.items()}

    values = list(scalar_data.values())
    min_val = min(values)
    max_val = max(values)

    color_map = {}

    for key, value in scalar_data.items():
        t = (value - min_val) / (max_val - min_val) if max_val != min_val else 0

        # Interpolation HSL
        h = start_hsl[0] + t * (end_hsl[0] - start_hsl[0])
        s = start_hsl[1] + t * (end_hsl[1] - start_hsl[1])
        l = start_hsl[2] + t * (end_hsl[2] - start_hsl[2])

        color_map[key] = f"hsl({h:.0f}, {s:.1f}%, {l:.1f}%)"

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
  default_end = "2025-07-22" #datetime.today().strftime('%Y-%m-%d') #set a specific date
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
