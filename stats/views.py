from django.http import HttpResponse
from django.http import FileResponse

import subprocess
import os


def index(request):
    subprocess.Popen(["Rscript","scriptR/simple.R"])

    # Lecture du fichier image généré
    image_path = "output/output.png"
    if os.path.exists(image_path):
        return FileResponse(open(image_path, 'rb'), content_type='image/png')
    else:
        return JsonResponse({"error": "Le fichier image n'existe pas."}, status=500)