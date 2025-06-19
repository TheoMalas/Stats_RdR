# 🧠 Django + R Integration – Analyse de Substances Psychoactives

Ce projet est une application Django permettant d’exécuter des scripts **R** pour analyser des données sur les substances psychoactives. Il combine la puissance d’un backend Python/Django avec l’analyse statistique et la visualisation en **R**.

---

## 🗂️ Structure du projet

```
.
├── data/                    # Données d'entrée
│   ├── raw/                # Données brutes
│   └── processed/          # Données nettoyées / formatées
├── output/                 # Résultats produits par les scripts R
│   └── output.png              # Exemple de visualisation générée
├── scriptR/                # Scripts R principaux
│   ├── code_psychoactif_cocaine.R
│   ├── code_psychoactif_inter_substance.R
│   └── simple.R
├── stats/                  # Application Django
│   ├── views.py, models.py, urls.py, etc.
├── webapp/                 # Paramètres et configuration du projet Django
│   ├── settings.py, urls.py, wsgi.py, etc.
├── db.sqlite3              # Base de données SQLite
├── manage.py
└── README.md
```

---

## ⚙️ Installation

### Prérequis

* Python 3.10+
* Django 4.x+
* R (et `Rscript`) installés sur le système
* Bibliothèques R nécessaires (`RMySQL`, `DBI`, `tidyverse`, `jsonlite`)


### Étapes

1. **Cloner le dépôt :**

```bash
git clone https://github.com/ton-utilisateur/nom-du-projet.git
cd nom-du-projet
```

2. **Installer les dépendances Python :**

```bash
pip install -r requirements.txt
```

3. **Configurer et lancer Django :**

```bash
python manage.py migrate
python manage.py runserver
```

4. **Tester l’exécution d’un script R :**

```bash
Rscript scriptR/simple.R
```

---

## 🧪 Fonctionnement

* Les données sont placées dans `data/raw/`
* Les scripts R lisent ces données, effectuent des traitements, et produisent :

  * Des fichiers `.csv` ou `.txt` dans `output/`
  * Des visualisations (`output.png`, `Rplots.pdf`, etc.)
* Django (via `stats/views.py`) peut déclencher l'exécution des scripts R avec `subprocess.run()` et afficher les résultats.

---