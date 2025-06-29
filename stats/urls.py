from django.urls import path

from . import views

urlpatterns = [
    path('chart-data/', views.chart_data, name='chart_data'),
    path('molecules/', views.molecules_view, name='molecules_view'),
    path('chart-data-supply/', views.chart_data_supply, name='chart_data_supply'),
    path('supply/', views.supply_view, name='supply_view'),
    path('chart-data-cocaine-coupe/', views.chart_data_cocaine_coupe, name='chart_data_cocaine_coupe'),
    path('cocaine-coupe/', views.cocaine_view, name='cocaine_view'),
    path('chart-stacked-area-prop-all-molecules/', views.chart_stacked_area_prop_all_molecules, name='chart_stacked_area_prop_all_molecules'),
    path('stacked-area-prop-all-molecules/', views.stacked_area_prop_all_molecules_view, name='stacked_area_prop_all_molecules'),
    path('chart-purity-cocaine/', views.chart_purity_cocaine, name='chart_purity_cocaine'),
    path('purity-cocaine/', views.purity_cocaine_view, name='purity_cocaine_view'),
    path('chart-evol-purity-cocaine/', views.chart_evol_purity_cocaine, name='chart_evol_purity_cocaine'),
    path('evol-purity-cocaine/', views.evol_purity_cocaine_view, name='evol_purity_cocaine_view'),
  ]
