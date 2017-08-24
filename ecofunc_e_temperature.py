#!/usr/bin/env python

import grass.script as grass

    # TEMPERATURE AND PRECIPITATION INTERPOLATION

def main():

    r_height = 'dem_10m_nosefi_float@g_Elevation_Fenoscandia'
    grass.run_command('g.region', raster=r_height)

    # TEMPERATURE: GWR
    r_temperature_bio01 = 'eurolst_clim.bio01@g_Meteorology_Fenoscandia_EuroLST_BIOCLIM'
    r_temperature_bio02 = 'eurolst_clim.bio02@g_Meteorology_Fenoscandia_EuroLST_BIOCLIM'
    r_temperature_bio10 = 'eurolst_clim.bio10@g_Meteorology_Fenoscandia_EuroLST_BIOCLIM'
    r_temperature_bio11 = 'eurolst_clim.bio11@g_Meteorology_Fenoscandia_EuroLST_BIOCLIM'

    r_bio01_estimates = 'bio01_eurolst_10m'
    r_bio02_estimates = 'bio02_eurolst_10m'
    r_bio10_estimates = 'bio10_eurolst_10m'
    r_bio11_estimates = 'bio11_eurolst_10m'

    # bandwidth estimated in R
    grass.run_command('r.gwr', overwrite=True, mapx=r_height,
                      mapy=r_temperature_bio01,estimates=r_bio01_estimates,
                      kernel='gauss',bandwidth=14,vf=1, npoints=0, memory=300)
    grass.run_command('r.gwr', overwrite=True, mapx=r_height,
                      mapy=r_temperature_bio02,estimates=r_bio02_estimates,
                      kernel='gauss',bandwidth=14,vf=1, npoints=0, memory=300)
    grass.run_command('r.gwr', overwrite=True, mapx=r_height, 
                      mapy=r_temperature_bio10,estimates=r_bio10_estimates,
                      kernel='gauss',bandwidth=14,vf=1, npoints=0, memory=300)
    grass.run_command('r.gwr', overwrite=True, mapx=r_height, 
                      mapy=r_temperature_bio11,estimates=r_bio11_estimates,
                      kernel='gauss',bandwidth=14,vf=1, npoints=0, memory=300)

    # PRECIPITATION - RESAMPLE
    r_precip_bio12 = 'WorldClim_current_bio12_1975@g_Meteorology_Fenoscandia_WorldClim_current'
    r_precip_bio15 = 'WorldClim_current_bio15_1975@g_Meteorology_Fenoscandia_WorldClim_current'
    r_precip_bio18 = 'WorldClim_current_bio18_1975@g_Meteorology_Fenoscandia_WorldClim_current'
    r_precip_bio19 = 'WorldClim_current_bio19_1975@g_Meteorology_Fenoscandia_WorldClim_current'

    r_precip_bio12_resamp = 'bio12_eurolst_10m'
    r_precip_bio15_resamp = 'bio15_eurolst_10m'
    r_precip_bio18_resamp = 'bio18_eurolst_10m'
    r_precip_bio19_resamp = 'bio19_eurolst_10m'
    
    grass.run_command('r.resamp.filter', overwrite=True, input=r_precip_bio12,
                      output=r_precip_bio12_resamp, filter='box,gauss', 
                      radius='2000,1000')
    grass.run_command('r.resamp.filter', overwrite=True, input=r_precip_bio15,
                      output=r_precip_bio15_resamp, filter='box,gauss', 
                      radius='2000,1000')
    grass.run_command('r.resamp.filter', overwrite=True, input=r_precip_bio18,
                      output=r_precip_bio18_resamp, filter='box,gauss', 
                      radius='2000,1000')
    grass.run_command('r.resamp.filter', overwrite=True, input=r_precip_bio19,
                      output=r_precip_bio19_resamp, filter='box,gauss', 
                      radius='2000,1000')


if __name__ == '__main__':
    main()
