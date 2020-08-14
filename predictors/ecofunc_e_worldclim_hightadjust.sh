#!/bin/bash

# Adjust world clim data by altitude, assuming 0.55 degree celsius increase every 100m
# Aggregate high resolution DEM to world clim data
grass /mnt/ecofunc-data/grass/ETRS_33N/g_Elevation_Fenoscandia --exec g.region -p raster=WorldClim_current_bio10_1975@g_Meteorology_Fenoscandia_WorldClim_current align=dem_10m_nosefi_float@g_Elevation_Fenoscandia
grass /mnt/ecofunc-data/grass/ETRS_33N/g_Elevation_Fenoscandia --exec g.region -p res=1000
grass /mnt/ecofunc-data/grass/ETRS_33N/g_Elevation_Fenoscandia r.resamp.stats --overwrite --verbose input=dem_10m_nosefi_float@g_Elevation_Fenoscandia output=dem_1000m_nosefi_wc

# Fill some NoData in World clim
grass /mnt/ecofunc-data/grass/ETRS_33N/g_Elevation_Fenoscandia --exec r.grow input=WorldClim_alt@g_Meteorology_Fenoscandia_WorldClim_current output=dem_1000m_WorldClim

# Adjust temperature by difference in altitude
grass /mnt/ecofunc-data/grass/ETRS_33N/g_Meteorology_Fenoscandia --exec g.region -p raster=WorldClim_current_bio10_1975@g_Meteorology_Fenoscandia_WorldClim_current align=dem_10m_nosefi_float@g_Elevation_Fenoscandia
grass /mnt/ecofunc-data/grass/ETRS_33N/g_Meteorology_Fenoscandia --exec r.mapcalc expression="WorldClim_current_bio10_1975_10m_hightdiff=float(WorldClim_current_bio10_1975@g_Meteorology_Fenoscandia_WorldClim_current+float((dem_1000m_WorldClim-dem_10m_nosefi_float)*(0.55/100.0)))" --o
