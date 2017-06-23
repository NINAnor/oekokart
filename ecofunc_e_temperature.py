#!/usr/bin/env python

import grass.script as grass

    # TEMPERATURE

def main():

    # resample 250 m raster

    r_temperature_bio01 = 'eurolst_clim.bio01@g_Meteorology_Fenoscandia_EuroLST_BIOCLIM'
    r_temperature_bio02 = 'eurolst_clim.bio02@g_Meteorology_Fenoscandia_EuroLST_BIOCLIM'
    r_temperature_bio03 = 'eurolst_clim.bio03@g_Meteorology_Fenoscandia_EuroLST_BIOCLIM'
    r_temperature_bio05 = 'eurolst_clim.bio05@g_Meteorology_Fenoscandia_EuroLST_BIOCLIM'
    r_temperature_bio06 = 'eurolst_clim.bio06@g_Meteorology_Fenoscandia_EuroLST_BIOCLIM'
    r_temperature_bio07 = 'eurolst_clim.bio07@g_Meteorology_Fenoscandia_EuroLST_BIOCLIM'
    r_temperature_bio10 = 'eurolst_clim.bio10@g_Meteorology_Fenoscandia_EuroLST_BIOCLIM'
    r_temperature_bio11 = 'eurolst_clim.bio11@g_Meteorology_Fenoscandia_EuroLST_BIOCLIM'

    # change resolution of region to 250m
    #grass.run_command('g.region', raster=r_temperature_bio01, flags='p')
    #grass.run_command('g.region', res=250, flags='p')

    # resample height to obtain average height in each 250m pixel
    r_height_250 = 'dem_250m_nosefi@g_Elevation_Fenoscandia'
    #grass.run_command('r.resamp.stats', input=r_height, output=r_height_250, flags='w', overwrite=True)

    # change resolution of region back to 10m
    #grass.run_command('g.region', raster=r_height, flags='p')
    #grass.run_command('g.region', res=10, flags='p')

    # create new temperature
    r_temperature_bio01_10m = 'eurolst_clim.bio01_10m'
    r_temperature_bio02_10m = 'eurolst_clim.bio02_10m'
    r_temperature_bio03_10m = 'eurolst_clim.bio03_10m'
    r_temperature_bio05_10m = 'eurolst_clim.bio05_10m'
    r_temperature_bio06_10m = 'eurolst_clim.bio06_10m'
    r_temperature_bio07_10m = 'eurolst_clim.bio07_10m'
    r_temperature_bio10_10m = 'eurolst_clim.bio10_10m'
    r_temperature_bio11_10m = 'eurolst_clim.bio11_10m'

    # interpolate
    #grass.run_command('r.mapcalc', overwrite=True, expression=r_temperature_bio01_10m + '=( \
    #                 '+r_temperature_bio01+'-('+r_height+'-'+r_height_250+')*0.6/10)')
    #grass.run_command('r.mapcalc', overwrite=True, expression=r_temperature_bio02_10m + '=( \
    #                 '+r_temperature_bio02+'-('+r_height+'-'+r_height_250+')*0.6/10)')
    #grass.run_command('r.mapcalc', overwrite=True, expression=r_temperature_bio03_10m + '=( \
    #                 '+r_temperature_bio03+'-('+r_height+'-'+r_height_250+')*0.6/10)')
    #grass.run_command('r.mapcalc', overwrite=True, expression=r_temperature_bio05_10m + '=( \
    #                 '+r_temperature_bio05+'-('+r_height+'-'+r_height_250+')*0.6/10)')
    #grass.run_command('r.mapcalc', overwrite=True, expression=r_temperature_bio06_10m + '=( \
    #                 '+r_temperature_bio06+'-('+r_height+'-'+r_height_250+')*0.6/10)')
    #grass.run_command('r.mapcalc', overwrite=True, expression=r_temperature_bio07_10m + '=( \
    #                 '+r_temperature_bio07+'-('+r_height+'-'+r_height_250+')*0.6/10)')
    #grass.run_command('r.mapcalc', overwrite=True, expression=r_temperature_bio10_10m + '=( \
    #                 '+r_temperature_bio10+'-('+r_height+'-'+r_height_250+')*0.6/10)')
    #grass.run_command('r.mapcalc', overwrite=True, expression=r_temperature_bio11_10m + '=( \
    #                 '+r_temperature_bio11+'-('+r_height+'-'+r_height_250+')*0.6/10)')



if __name__ == '__main__':
    main()
