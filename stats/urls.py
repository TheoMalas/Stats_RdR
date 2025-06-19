from django.urls import path

from . import views

urlpatterns = [
    path("", views.index, name="index"),
    path('chart-data/', views.chart_data, name='chart_data'),
    path('chart-data-supply/', views.chart_data_supply, name='chart_data_supply'),
    path('molecules/', views.molecules_view, name='molecules_view'),
    path('supply/', views.supply_view, name='supply_view'),
]
