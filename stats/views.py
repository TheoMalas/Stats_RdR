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

  return render(request, 'pages/all_molecules.html', { 
      'all_molecules_data': all_molecules_data,
      'area_all_molecules_data' : area_all_molecules_data,
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
      'data' : data,
  })

def cocaine_view(request):

  date_debut, date_fin = get_dates(request)
  
  args = {
    "date_debut" : date_debut,
    "date_fin" : date_fin,
  }
    
  data = runScript("cocaine/diagram_coupe_cocaine", args)

  return render(request, 'pages/coupe.html', { 
    'data' : data,
  })

def heroine_view(request):

  date_debut, date_fin = get_dates(request)
  
  args = {
    "date_debut" : date_debut,
    "date_fin" : date_fin,
  }
  
  data = runScript("heroine/diagram_coupe_heroine", args)
  
  return render(request, 'pages/coupe.html', { 
    'data' : data,
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
  
  return render(request, 'pages/purity.html', { 
    'data' : data,
    'data_2' : data_2,
    'regression_data' : data_reg,
    'molecule_name': "Cocaïne",
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
  
  return render(request, 'pages/purity.html', { 
    'data' : data,
    'data_2' : data_2,
    'regression_data' : data_reg,
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
  
  return render(request, 'pages/purity.html', { 
    'data' : data,
    'data_2' : data_2,
    'regression_data' : data_reg,
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
  
  return render(request, 'pages/purity.html', { 
    'data' : data,
    'data_2' : data_2,
    'regression_data' : data_reg,
    'molecule_name': "3-MMC",
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
  
  return render(request, 'pages/purity.html', { 
    'data' : data,
    'data_2' : data_2,
    'regression_data' : data_reg,
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
  
  return render(request, 'pages/purity.html', { 
    'data' : data,
    'data_2' : data_2,
    'regression_data' : data_reg,
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
  
  return render(request, 'pages/purity.html', { 
    'data' : data,
    'data_2' : data_2,
    'regression_data' : data_reg,
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
  
  return render(request, 'pages/purity.html', { 
    'data' : data,
    'data_2' : data_2,
    'regression_data' : data_reg,
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
    'data' : data,
  })

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
