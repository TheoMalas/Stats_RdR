from django.urls import path

from . import views

urlpatterns = [
    path('', views.molecules_view, name='molecules_view'),
    path('cleanCache/', views.cleanCache, name='clean_cache'),
    path('molecules/', views.molecules_view, name='molecules_view'),
    path('supply/', views.supply_view, name='supply_view'),
    path('cocaine-coupe/', views.cocaine_view, name='cocaine_view'),
    path('heroine-coupe/', views.heroine_view, name='heroine_view'),
    path('stacked-area-prop-all-molecules/', views.stacked_area_prop_all_molecules_view, name='stacked_area_prop_all_molecules'),
    path('purity-heroine/', views.purity_heroine_view, name='purity_heroine_view'),
    path('purity-mdma/', views.purity_mdma_view, name='purity_mdma_view'),
    path('purity-3mmc/', views.purity_3mmc_view, name='purity_3mmc_view'),
    path('purity-ketamine/', views.purity_ketamine_view, name='purity_ketamine_view'),
    path('purity-speed/', views.purity_speed_view, name='purity_speed_view'),
    path('purity-cannabis-THC-resine/', views.purity_cannabis_THC_resine_view, name='purity_cannabis_THC_resine_view'),
    path('purity-cannabis-THC-herbe/', views.purity_cannabis_THC_herbe_view, name='purity_cannabis_THC_herbe_view'),
    path('purity-cocaine/', views.purity_cocaine_view, name='purity_cocaine_view'),
    path('evol-purity-cocaine/', views.evol_purity_cocaine_view, name='evol_purity_cocaine_view'),
    path('histo-comprime-mdma/', views.histo_comprime_mdma_view, name='histo_comprime_mdma_view'),

    path('chart-data/', views.chart_data, name='chart_data'),
    path('chart-data-supply/', views.chart_data_supply, name='chart_data_supply'),
    path('chart-data-cocaine-coupe/', views.chart_data_cocaine_coupe, name='chart_data_cocaine_coupe'),
    path('chart-data-heroine-coupe/', views.chart_data_heroine_coupe, name='chart_data_heroine_coupe'),
    path('chart-stacked-area-prop-all-molecules/', views.chart_stacked_area_prop_all_molecules, name='chart_stacked_area_prop_all_molecules'),
    path('chart-purity-cocaine/', views.chart_purity_cocaine, name='chart_purity_cocaine'),
    path('chart-purity-heroine/', views.chart_purity_heroine, name='chart_purity_heroine'),
    path('chart-purity-mdma/', views.chart_purity_mdma, name='chart_purity_mdma'),
    path('chart-purity-3mmc/', views.chart_purity_3mmc, name='chart_purity_3mmc'),
    path('chart-purity-ketamine/', views.chart_purity_ketamine, name='chart_purity_ketamine'),
    path('chart-purity-speed/', views.chart_purity_speed, name='chart_purity_speed'),
    path('chart-purity-cannabis-THC-resine/', views.chart_purity_cannabis_THC_resine, name='chart_purity_cannabis_THC_resine'),
    path('chart-purity-cannabis-THC-herbe/', views.chart_purity_cannabis_THC_herbe, name='chart_purity_cannabis_THC_herbe'),    
    path('chart-evol-purity-cocaine/', views.chart_evol_purity_cocaine, name='chart_evol_purity_cocaine'),
    path('chart-histo-comprime-mdma/', views.chart_histo_comprime_mdma, name='chart_histo_comprime_mdma'),
  ]
