from django.http import HttpResponse
from django.http import FileResponse
from django.http import JsonResponse

from django.shortcuts import render
from django.conf import settings

import json
import subprocess
import os


def index(request):
    subprocess.Popen(["Rscript","scriptR/Pie_chart_all_molecules.R"])

    # Lecture du fichier image généré
    image_path = "output/pie_chart_all_molecules.png"
    if os.path.exists(image_path):
        return FileResponse(open(image_path, 'rb'), content_type='image/png')
    else:
        return JsonResponse({"error": "Le fichier image n'existe pas."}, status=500)

def chart_data(request):
    json_file_path = os.path.join(settings.BASE_DIR, 'output/pie_chart_all_molecules.json')
    with open(json_file_path, 'r') as f:
        data = json.load(f)
    return JsonResponse(data)

def pie_chart_view(request):
    return render(request, 'pie_chart.html')
