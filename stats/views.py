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
    json_file_path = os.path.join(settings.BASE_DIR, 'output/pie_chart_all_molecules.json')
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
  json_file_path = os.path.join(settings.BASE_DIR, 'output/pie_chart_supply_all_molecules.json')
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
  json_file_path = os.path.join(settings.BASE_DIR, 'output/coupe_cocaine.json')
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
  json_file_path = os.path.join(settings.BASE_DIR, 'output/stacked_area_prop_all_molecules.json')
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
  json_file_path = os.path.join(settings.BASE_DIR, 'output/histo_purity_cocaine.json')
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
  json_file_path = os.path.join(settings.BASE_DIR, 'output/evol_purity_cocaine.json')
  with open(json_file_path, 'r') as f:
      data = json.load(f)
  return JsonResponse(data)
