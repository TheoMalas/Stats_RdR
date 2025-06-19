from django.urls import path

from . import views

urlpatterns = [
    path("", views.index, name="index"),
    path('chart-data/', views.chart_data, name='chart_data'),
    path('chart-data-supply/', views.chart_data_supply, name='chart_data_supply'),
    path('pie-chart/', views.pie_chart_view, name='pie_chart'),
]
