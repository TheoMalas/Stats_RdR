from django.urls import path

from . import views

urlpatterns = [
    path('', views.molecules_view, name='molecules_view'),
  
    path('molecules/', views.molecules_view, name='molecules_view'),
    path('supply/', views.supply_view, name='supply_view'),
    path('cocaine-coupe/', views.cocaine_view, name='cocaine_view'),
    path('heroine-coupe/', views.heroine_view, name='heroine_view'),
    path('3mmc-coupe/', views.coupe_3mmc_view, name='3mmc_view'),
    path('purity-heroine/', views.purity_heroine_view, name='purity_heroine_view'),
    path('purity-mdma/', views.purity_mdma_view, name='purity_mdma_view'),
    path('purity-3mmc/', views.purity_3mmc_view, name='purity_3mmc_view'),
    path('purity-ketamine/', views.purity_ketamine_view, name='purity_ketamine_view'),
    path('purity-speed/', views.purity_speed_view, name='purity_speed_view'),
    path('purity-cannabis-THC-resine/', views.purity_cannabis_THC_resine_view, name='purity_cannabis_THC_resine_view'),
    path('purity-cannabis-THC-herbe/', views.purity_cannabis_THC_herbe_view, name='purity_cannabis_THC_herbe_view'),
    path('purity-cocaine/', views.purity_cocaine_view, name='purity_cocaine_view'),
    path('histo-comprime-mdma/', views.histo_comprime_mdma_view, name='histo_comprime_mdma_view'),

    path('cleanCache/', views.cleanCache, name='clean_cache'),
  ]
