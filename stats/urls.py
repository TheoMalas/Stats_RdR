from django.urls import path

from . import views

urlpatterns = [
    path("", views.index, name="index"),
    path('chart-data/', views.chart_data, name='chart_data'),
    path('chart-data-supply/', views.chart_data_supply, name='chart_data_supply'),
    path('chart-data-cocaine-coupe/', views.chart_data_cocaine_coupe, name='chart_data_cocaine_coupe'),
    path('molecules/', views.molecules_view, name='molecules_view'),
    path('supply/', views.supply_view, name='supply_view'),
    path('cocaine-coupe/', views.cocaine_view, name='cocaine_view'),
]
