from django.http import HttpResponse
from django.http import JsonResponse

from django.shortcuts import render
from django.conf import settings

import json
import subprocess
import os
from datetime import datetime

# FrontEnd

def molecules_view(request):
  return render(request, 'pie_chart.html', { 
      'fetch_url' : 'chart-data'
  })

def supply_view(request):
  return render(request, 'pie_chart.html', { 
      'fetch_url' : 'chart-data-supply'
  })

def cocaine_view(request):
    return render(request, 'pie_chart.html', { 
    'fetch_url' : 'chart-data-cocaine-coupe'
  })

def heroine_view(request):
    return render(request, 'pie_chart.html', { 
    'fetch_url' : 'chart-data-heroine-coupe'
  })

def stacked_area_prop_all_molecules_view(request):
  return render(request, 'pie_chart.html', {
  'fetch_url' : 'chart-stacked-area-prop-all-molecules'
  })

def purity_cocaine_view(request):
  return render(request, 'pie_chart.html', {
  'fetch_url' : 'chart-purity-cocaine'
  })

def purity_mdma_view(request):
  return render(request, 'pie_chart.html', {
  'fetch_url' : 'chart-purity-mdma'
  })

def purity_heroine_view(request):
  return render(request, 'pie_chart.html', {
  'fetch_url' : 'chart-purity-heroine'
  })

def purity_3mmc_view(request):
  return render(request, 'pie_chart.html', {
  'fetch_url' : 'chart-purity-3mmc'
  })

def purity_ketamine_view(request):
  return render(request, 'pie_chart.html', {
  'fetch_url' : 'chart-purity-ketamine'
  })

def purity_speed_view(request):
  return render(request, 'pie_chart.html', {
  'fetch_url' : 'chart-purity-speed'
  })

def purity_cannabis_THC_resine_view(request):
  return render(request, 'pie_chart.html', {
  'fetch_url' : 'chart-purity-cannabis-THC-resine'
  })

def purity_cannabis_THC_herbe_view(request):
  return render(request, 'pie_chart.html', {
  'fetch_url' : 'chart-purity-cannabis-THC-herbe'
  })

def histo_comprime_mdma_view(request):
  return render(request, 'pie_chart.html', {
  'fetch_url' : 'chart-histo-comprime-mdma'
  })

def evol_purity_cocaine_view(request):
  return render(request, 'pie_chart.html', {
  'fetch_url' : 'chart-evol-purity-cocaine'
  })

# BackEnd

def runScript(scriptID, args):

  cmd=["Rscript","scriptR/" + scriptID + ".R"] + args
  subprocess.run(cmd)

  json_file_path = os.path.join(settings.BASE_DIR, 'output/' + scriptID + '.json')
  with open(json_file_path, 'r') as f:
      data = json.load(f)

  return JsonResponse(data)

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
  
  return runScript("all/pie_chart_all_molecules", [date_debut, date_fin] + familles_list)
  
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

  return runScript("all/pie_chart_supply_all_molecules", [date_debut, date_fin] + familles_list)

def chart_data_cocaine_coupe(request):
  default_end = datetime.today().strftime('%Y-%m-%d') #set to today
  default_start = "2022-06-22" #first analysis done
  date_debut = request.GET.get("date_debut", default_start)
  date_fin = request.GET.get("date_fin", default_end)

  return runScript("cocaine/diagram_coupe_cocaine", [date_debut, date_fin])

def chart_data_heroine_coupe(request):
  default_end = datetime.today().strftime('%Y-%m-%d') #set to today
  default_start = "2022-06-22" #first analysis done
  date_debut = request.GET.get("date_debut", default_start)
  date_fin = request.GET.get("date_fin", default_end)

  return runScript("heroine/diagram_coupe_heroine", [date_debut, date_fin])

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
      
  return runScript("all/stacked_area_prop_all_molecules", [date_debut, date_fin] + familles_list)

def chart_purity_cocaine(request):
  default_start = "2022-06-22" #first analysis done
  date_debut = request.GET.get("date_debut", default_start)
  
  default_end = datetime.today().strftime('%Y-%m-%d') #set to today
  date_fin = request.GET.get("date_fin", default_end)
  
  default_Delta = "15"
  Delta=str(request.GET.get("range", default_Delta))
  
  return runScript("cocaine/histo_purity_cocaine", [date_debut, date_fin, Delta])

def chart_purity_heroine(request):
  default_start = "2022-06-22" #first analysis done
  date_debut = request.GET.get("date_debut", default_start)
  
  default_end = datetime.today().strftime('%Y-%m-%d') #set to today
  date_fin = request.GET.get("date_fin", default_end)
  
  default_Delta = "15"
  Delta=str(request.GET.get("range", default_Delta))
  
  return runScript("heroine/histo_purity_heroine", [date_debut, date_fin, Delta])

def chart_purity_mdma(request):
  default_start = "2022-06-22" #first analysis done
  date_debut = request.GET.get("date_debut", default_start)
  
  default_end = datetime.today().strftime('%Y-%m-%d') #set to today
  date_fin = request.GET.get("date_fin", default_end)
  
  default_Delta = "15"
  Delta=str(request.GET.get("range", default_Delta))
  
  return runScript("mdma/histo_purity_mdma", [date_debut, date_fin, Delta])

def chart_purity_3mmc(request):
  default_start = "2022-06-22" #first analysis done
  date_debut = request.GET.get("date_debut", default_start)
  
  default_end = datetime.today().strftime('%Y-%m-%d') #set to today
  date_fin = request.GET.get("date_fin", default_end)
  
  default_Delta = "15"
  Delta=str(request.GET.get("range", default_Delta))
  
  return runScript("3mmc/histo_purity_3mmc", [date_debut, date_fin, Delta])

def chart_purity_ketamine(request):
  default_start = "2022-06-22" #first analysis done
  date_debut = request.GET.get("date_debut", default_start)
  
  default_end = datetime.today().strftime('%Y-%m-%d') #set to today
  date_fin = request.GET.get("date_fin", default_end)
  
  default_Delta = "15"
  Delta=str(request.GET.get("range", default_Delta))
  
  return runScript("ketamine/histo_purity_ketamine", [date_debut, date_fin, Delta])

def chart_purity_speed(request):
  default_start = "2022-06-22" #first analysis done
  date_debut = request.GET.get("date_debut", default_start)
  
  default_end = datetime.today().strftime('%Y-%m-%d') #set to today
  date_fin = request.GET.get("date_fin", default_end)
  
  default_Delta = "15"
  Delta=str(request.GET.get("range", default_Delta))
  
  return runScript("speed/histo_purity_speed", [date_debut, date_fin, Delta])

def chart_purity_cannabis_THC_resine(request):
  default_start = "2022-06-22" #first analysis done
  date_debut = request.GET.get("date_debut", default_start)
  
  default_end = datetime.today().strftime('%Y-%m-%d') #set to today
  date_fin = request.GET.get("date_fin", default_end)
  
  default_Delta = "15"
  Delta=str(request.GET.get("range", default_Delta))
  
  return runScript("cannabis/histo_purity_cannabis_THC_resine", [date_debut, date_fin, Delta])

def chart_purity_cannabis_THC_herbe(request):
  default_start = "2022-06-22" #first analysis done
  date_debut = request.GET.get("date_debut", default_start)
  
  default_end = datetime.today().strftime('%Y-%m-%d') #set to today
  date_fin = request.GET.get("date_fin", default_end)
  
  default_Delta = "15"
  Delta=str(request.GET.get("range", default_Delta))
  
  return runScript("cannabis/histo_purity_cannabis_THC_herbe", [date_debut, date_fin, Delta])

def chart_evol_purity_cocaine(request):
  default_end = datetime.today().strftime('%Y-%m-%d') #set to today
  default_start = "2022-06-22" #first analysis done
  date_debut = request.GET.get("date_debut", default_start)
  date_fin = request.GET.get("date_fin", default_end)
  
  return runScript("cocaine/Evol_purity_cocaine", [date_debut, date_fin])

def chart_histo_comprime_mdma(request):
  default_start = "2022-06-22" #first analysis done
  date_debut = request.GET.get("date_debut", default_start)
  
  default_end = datetime.today().strftime('%Y-%m-%d') #set to today
  date_fin = request.GET.get("date_fin", default_end)
  
  default_Delta = "15"
  Delta=str(request.GET.get("range", default_Delta))
  
  return runScript("mdma/histo_comprime_mdma", [date_debut, date_fin, Delta])
