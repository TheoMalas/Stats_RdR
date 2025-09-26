FROM rocker/r-ver:latest

# Installer packages R
RUN R -e "install.packages(c('DBI', 'dplyr', 'RMariaDB', 'jsonlite', 'purrr', 'lubridate'))"

# Installer Python, Pip & MariaDB
RUN apt-get update && apt-get install -y \
    python3 python3-venv python3-pip libmysqlclient-dev default-libmysqlclient-dev

# Créer un dossier pour l'app
WORKDIR /app

# Créer un environnement virtuel
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

COPY requirements.txt /app/requirements.txt
RUN pip install --upgrade pip && pip install -r /app/requirements.txt

RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Copier le reste de l'application
COPY . /app

# Exposer le port utilisé par Django
EXPOSE 8000

# Lancer le serveur Django
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]
