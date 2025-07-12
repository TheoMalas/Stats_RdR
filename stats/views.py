from django.http import HttpResponse
from django.http import JsonResponse

from django.shortcuts import render
from django.conf import settings

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
  familles_str = ",".join(familles_list)
  args_str="date_debut="+str(date_debut)+" "\
    "date_fin="+str(date_fin)+" "\
    "familles_list="+familles_str
  all_molecules_data = runScript("all/pie_chart_all_molecules", args_str)    
  area_all_molecules_data = runScript("all/stacked_area_prop_all_molecules", args_str)

  return render(request, 'pages/all_molecules.html', { 
      'all_molecules_data': all_molecules_data,
      'area_all_molecules_data' : area_all_molecules_data,
  })

def supply_view(request):

  date_debut, date_fin = get_dates(request)
  familles_list = get_familles(request)
  familles_str = ",".join(familles_list)
  args_str="date_debut="+str(date_debut)+" "\
    "date_fin="+str(date_fin)+" "\
    "familles_list="+familles_str
  data = runScript("all/pie_chart_supply_all_molecules", args_str)

  return render(request, 'pages/supply.html', { 
      'data' : data,
  })

def cocaine_view(request):

  date_debut, date_fin = get_dates(request)
  data = runScript("cocaine/diagram_coupe_cocaine", [date_debut, date_fin])

  return render(request, 'pages/coupe.html', { 
    'data' : data,
  })

def heroine_view(request):

  date_debut, date_fin = get_dates(request)
  data = runScript("heroine/diagram_coupe_heroine", [date_debut, date_fin])
  
  return render(request, 'pages/coupe.html', { 
    'data' : data,
  })

def purity_cocaine_view(request):

  date_debut, date_fin = get_dates(request)  
  data = runScript("cocaine/histo_purity_cocaine", [date_debut, date_fin, str(request.GET.get("range", default_Delta))])
  
  return render(request, 'pages/purity.html', { 
    'data' : data,
    'molecule_name': "Cocaine",
  })

def purity_mdma_view(request):

  date_debut, date_fin = get_dates(request)  
  data = runScript("mdma/histo_purity_mdma", [date_debut, date_fin, str(request.GET.get("range", default_Delta))])
  
  return render(request, 'pages/purity.html', { 
    'data' : data,
    'molecule_name': "MDMA",
  })

def purity_heroine_view(request):

  date_debut, date_fin = get_dates(request)
  data = runScript("heroine/histo_purity_heroine", [date_debut, date_fin, str(request.GET.get("range", default_Delta))])

  return render(request, 'pages/purity.html', { 
    'data' : data,
    'molecule_name': "Héroine",
  })

def purity_3mmc_view(request):

  date_debut, date_fin = get_dates(request)
  data = runScript("3mmc/histo_purity_3mmc", [date_debut, date_fin, str(request.GET.get("range", default_Delta))])

  return render(request, 'pages/purity.html', { 
    'data' : data,
    'molecule_name': "3MMC",
  })

def purity_ketamine_view(request):

  date_debut, date_fin = get_dates(request)
  data = runScript("ketamine/histo_purity_ketamine", [date_debut, date_fin, str(request.GET.get("range", default_Delta))])
  
  return render(request, 'pages/purity.html', { 
    'data' : data,
    'molecule_name': "Kétamine",
  })

def purity_speed_view(request):

  date_debut, date_fin = get_dates(request)
  data = runScript("speed/histo_purity_speed", [date_debut, date_fin, str(request.GET.get("range", default_Delta))])
  
  return render(request, 'pages/purity.html', { 
    'data' : data,
    'molecule_name': "Speed",
  })

def purity_cannabis_THC_resine_view(request):

  date_debut, date_fin = get_dates(request)  
  data = runScript("cannabis/histo_purity_cannabis_THC_resine", [date_debut, date_fin, str(request.GET.get("range", default_Delta))])
  
  return render(request, 'pages/purity.html', { 
    'data' : data,
    'molecule_name': "Cannabis Resine",
  })

def purity_cannabis_THC_herbe_view(request):

  date_debut, date_fin = get_dates(request)
  data = runScript("cannabis/histo_purity_cannabis_THC_herbe", [date_debut, date_fin, str(request.GET.get("range", default_Delta))])

  return render(request, 'pages/purity.html', { 
    'data' : data,
    'molecule_name': "Cannabis Herbe",
  })

def histo_comprime_mdma_view(request):

  date_debut, date_fin = get_dates(request)
  data = runScript("mdma/histo_comprime_mdma", [date_debut, date_fin, str(request.GET.get("range", default_Delta))])
    
  return render(request, 'pages/purity.html', { 
    'data' : data,
  })

# BackEnd

def runScript(scriptID, args):
  outputPath = 'output/' + scriptID + '.json'
  
  cachedData = basicCache(outputPath)
  if cachedData != None:
      return cachedData
  print([args])
  cmd=["Rscript","scriptR/" + scriptID + ".R"] + [args]
  print(cmd)
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
  default_end = datetime.today().strftime('%Y-%m-%d') #set to today
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
