from django.http import HttpResponse
from django.http import FileResponse
from django.http import JsonResponse

from django.shortcuts import render
from django.conf import settings

import json
import subprocess
import os
from datetime import datetime

def index(request):
    date_debut = "2023-08-07"
    date_fin = "2023-11-02"
    subprocess.run(["Rscript","scriptR/all_molecules/pie_chart_all_molecules.R",date_debut,date_fin])

    # Lecture du fichier image généré
    image_path = "output/pie_chart_all_molecules.png"
    if os.path.exists(image_path):
        return FileResponse(open(image_path, 'rb'), content_type='image/png')
    else:
        return JsonResponse({"error": "Le fichier image n'existe pas."}, status=500)

def chart_data(request):
    default_end = datetime.today().strftime('%Y-%m-%d') #set to today
    default_start = "2022-06-22" #first analysis done
    date_debut = request.GET.get("date_debut", default_start)
    date_fin = request.GET.get("date_fin", default_end)
    print(date_fin)
    
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

def pie_chart_view(request):
    return render(request, 'pie_chart.html')
