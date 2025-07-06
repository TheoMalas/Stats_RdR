from django.http import HttpResponse
from django.http import FileResponse
from django.http import JsonResponse

from django.shortcuts import render
from django.conf import settings

import json
import subprocess
import os
from datetime import datetime

def molecules_view(request):
    return render(request, 'pie_chart.html', { 
        'fetch_url' : 'chart-data'
    })
def chart_data(request):
    default_end = datetime.today().strftime('%Y-%m-%d') #set to today
    default_start = "2022-06-22" #first analysis done
    date_debut = request.GET.get("date_debut", default_start)
    date_fin = request.GET.get("date_fin", default_end)
    
    # Paramètre types (liste séparée par virgules dans l’URL)
    familles_str = request.GET.get("familles")
    if isinstance(familles_str, str):
        familles_list = familles_str.split(",")
    else:
        familles_list = []
    cmd=["Rscript","scriptR/all_molecules/pie_chart_all_molecules.R",date_debut,date_fin] + familles_list
    subprocess.run(cmd)
    json_file_path = os.path.join(settings.BASE_DIR, 'output/all/pie_chart_all_molecules.json')
    with open(json_file_path, 'r') as f:
        data = json.load(f)
    return JsonResponse(data)
  
  
def supply_view(request):
    return render(request, 'pie_chart.html', { 
        'fetch_url' : 'chart-data-supply'
    })
def chart_data_supply(request):
  default_end = datetime.today().strftime('%Y-%m-%d') #set to today
  default_start = "2022-06-22" #first analysis done
  date_debut = request.GET.get("date_debut", default_start)
  date_fin = request.GET.get("date_fin", default_end)

  # Paramètre types (liste séparée par virgules dans l’URL)
  familles_str = request.GET.get("familles")
  if isinstance(familles_str, str):
      familles_list = familles_str.split(",")
  else:
      familles_list = []
  cmd=["Rscript","scriptR/all_molecules/pie_chart_supply_all_molecules.R",date_debut,date_fin] + familles_list
  subprocess.run(cmd)
  json_file_path = os.path.join(settings.BASE_DIR, 'output/all/pie_chart_supply_all_molecules.json')
  with open(json_file_path, 'r') as f:
      data = json.load(f)
  return JsonResponse(data)


def cocaine_view(request):
      return render(request, 'pie_chart.html', { 
      'fetch_url' : 'chart-data-cocaine-coupe'
    })
def chart_data_cocaine_coupe(request):
  default_end = datetime.today().strftime('%Y-%m-%d') #set to today
  default_start = "2022-06-22" #first analysis done
  date_debut = request.GET.get("date_debut", default_start)
  date_fin = request.GET.get("date_fin", default_end)

  cmd=["Rscript","scriptR/cocaine/diagram_coupe_cocaine.R",date_debut,date_fin]
  subprocess.run(cmd)
  json_file_path = os.path.join(settings.BASE_DIR, 'output/cocaine/coupe_cocaine.json')
  with open(json_file_path, 'r') as f:
      data = json.load(f)
  return JsonResponse(data)


def heroine_view(request):
      return render(request, 'pie_chart.html', { 
      'fetch_url' : 'chart-data-heroine-coupe'
    })
def chart_data_heroine_coupe(request):
  default_end = datetime.today().strftime('%Y-%m-%d') #set to today
  default_start = "2022-06-22" #first analysis done
  date_debut = request.GET.get("date_debut", default_start)
  date_fin = request.GET.get("date_fin", default_end)

  cmd=["Rscript","scriptR/heroine/diagram_coupe_heroine.R",date_debut,date_fin]
  subprocess.run(cmd)
  json_file_path = os.path.join(settings.BASE_DIR, 'output/heroine/coupe_heroine.json')
  with open(json_file_path, 'r') as f:
      data = json.load(f)
  return JsonResponse(data)


def stacked_area_prop_all_molecules_view(request):
  return render(request, 'pie_chart.html', {
  'fetch_url' : 'chart-stacked-area-prop-all-molecules'
  })
def chart_stacked_area_prop_all_molecules(request):
  default_end = datetime.today().strftime('%Y-%m-%d') #set to today
  default_start = "2023-03-01" #first analysis done
  date_debut = request.GET.get("date_debut", default_start)
  date_fin = request.GET.get("date_fin", default_end)

  # Paramètre types (liste séparée par virgules dans l’URL)
  familles_str = request.GET.get("familles")
  if isinstance(familles_str, str):
      familles_list = familles_str.split(",")
  else:
      familles_list = []
      
  cmd=["Rscript","scriptR/all_molecules/stacked_area_prop_all_molecules.R",date_debut,date_fin] + familles_list
  subprocess.run(cmd)
  json_file_path = os.path.join(settings.BASE_DIR, 'output/all/stacked_area_prop_all_molecules.json')
  with open(json_file_path, 'r') as f:
      data = json.load(f)
  return JsonResponse(data)


def purity_cocaine_view(request):
  return render(request, 'pie_chart.html', {
  'fetch_url' : 'chart-purity-cocaine'
  })
def chart_purity_cocaine(request):
  default_end = datetime.today().strftime('%Y-%m-%d') #set to today
  default_start = "2022-06-22" #first analysis done
  date_debut = request.GET.get("date_debut", default_start)
  date_fin = request.GET.get("date_fin", default_end)
  
      
  cmd=["Rscript","scriptR/cocaine/histo_purity_cocaine.R",date_debut,date_fin]
  subprocess.run(cmd)
  json_file_path = os.path.join(settings.BASE_DIR, 'output/cocaine/histo_purity_cocaine.json')
  with open(json_file_path, 'r') as f:
      data = json.load(f)
  return JsonResponse(data)

def purity_heroine_view(request):
  return render(request, 'pie_chart.html', {
  'fetch_url' : 'chart-purity-heroine'
  })
def chart_purity_heroine(request):
  default_end = datetime.today().strftime('%Y-%m-%d') #set to today
  default_start = "2022-06-22" #first analysis done
  date_debut = request.GET.get("date_debut", default_start)
  date_fin = request.GET.get("date_fin", default_end)
  
      
  cmd=["Rscript","scriptR/heroine/histo_purity_heroine.R",date_debut,date_fin]
  subprocess.run(cmd)
  json_file_path = os.path.join(settings.BASE_DIR, 'output/heroine/histo_purity_heroine.json')
  with open(json_file_path, 'r') as f:
      data = json.load(f)
  return JsonResponse(data)

def purity_mdma_view(request):
  return render(request, 'pie_chart.html', {
  'fetch_url' : 'chart-purity-mdma'
  })
def chart_purity_mdma(request):
  default_end = datetime.today().strftime('%Y-%m-%d') #set to today
  default_start = "2022-06-22" #first analysis done
  date_debut = request.GET.get("date_debut", default_start)
  date_fin = request.GET.get("date_fin", default_end)
  
      
  cmd=["Rscript","scriptR/mdma/histo_purity_mdma.R",date_debut,date_fin]
  subprocess.run(cmd)
  json_file_path = os.path.join(settings.BASE_DIR, 'output/mdma/histo_purity_mdma.json')
  with open(json_file_path, 'r') as f:
      data = json.load(f)
  return JsonResponse(data)

def purity_3mmc_view(request):
  return render(request, 'pie_chart.html', {
  'fetch_url' : 'chart-purity-3mmc'
  })
def chart_purity_3mmc(request):
  default_end = datetime.today().strftime('%Y-%m-%d') #set to today
  default_start = "2022-06-22" #first analysis done
  date_debut = request.GET.get("date_debut", default_start)
  date_fin = request.GET.get("date_fin", default_end)
  
      
  cmd=["Rscript","scriptR/3mmc/histo_purity_3mmc.R",date_debut,date_fin]
  subprocess.run(cmd)
  json_file_path = os.path.join(settings.BASE_DIR, 'output/3mmc/histo_purity_3mmc.json')
  with open(json_file_path, 'r') as f:
      data = json.load(f)
  return JsonResponse(data)

def purity_ketamine_view(request):
  return render(request, 'pie_chart.html', {
  'fetch_url' : 'chart-purity-ketamine'
  })
def chart_purity_ketamine(request):
  default_end = datetime.today().strftime('%Y-%m-%d') #set to today
  default_start = "2022-06-22" #first analysis done
  date_debut = request.GET.get("date_debut", default_start)
  date_fin = request.GET.get("date_fin", default_end)
  
      
  cmd=["Rscript","scriptR/ketamine/histo_purity_ketamine.R",date_debut,date_fin]
  subprocess.run(cmd)
  json_file_path = os.path.join(settings.BASE_DIR, 'output/ketamine/histo_purity_ketamine.json')
  with open(json_file_path, 'r') as f:
      data = json.load(f)
  return JsonResponse(data)

def purity_speed_view(request):
  return render(request, 'pie_chart.html', {
  'fetch_url' : 'chart-purity-speed'
  })
def chart_purity_speed(request):
  default_end = datetime.today().strftime('%Y-%m-%d') #set to today
  default_start = "2022-06-22" #first analysis done
  date_debut = request.GET.get("date_debut", default_start)
  date_fin = request.GET.get("date_fin", default_end)
  
      
  cmd=["Rscript","scriptR/speed/histo_purity_speed.R",date_debut,date_fin]
  subprocess.run(cmd)
  json_file_path = os.path.join(settings.BASE_DIR, 'output/speed/histo_purity_speed.json')
  with open(json_file_path, 'r') as f:
      data = json.load(f)
  return JsonResponse(data)

def evol_purity_cocaine_view(request):
  return render(request, 'pie_chart.html', {
  'fetch_url' : 'chart-evol-purity-cocaine'
  })
def chart_evol_purity_cocaine(request):
  default_end = datetime.today().strftime('%Y-%m-%d') #set to today
  default_start = "2022-06-22" #first analysis done
  date_debut = request.GET.get("date_debut", default_start)
  date_fin = request.GET.get("date_fin", default_end)
  
      
  cmd=["Rscript","scriptR/cocaine/Evol_purity_cocaine.R",date_debut,date_fin]
  subprocess.run(cmd)
  json_file_path = os.path.join(settings.BASE_DIR, 'output/cocaine/evol_purity_cocaine.json')
  with open(json_file_path, 'r') as f:
      data = json.load(f)
  return JsonResponse(data)


def histo_comprime_mdma_view(request):
  return render(request, 'pie_chart.html', {
  'fetch_url' : 'chart-histo-comprime-mdma'
  })
def chart_histo_comprime_mdma(request):
  print("test")
  default_end = datetime.today().strftime('%Y-%m-%d') #set to today
  default_start = "2022-06-22" #first analysis done
  date_debut = request.GET.get("date_debut", default_start)
  date_fin = request.GET.get("date_fin", default_end)
  
      
  cmd=["Rscript","scriptR/mdma/histo_comprime_MDMA.R",date_debut,date_fin]
  subprocess.run(cmd)
  json_file_path = os.path.join(settings.BASE_DIR, 'output/mdma/histo_comprime_mdma.json')
  with open(json_file_path, 'r') as f:
      data = json.load(f)
  return JsonResponse(data)
