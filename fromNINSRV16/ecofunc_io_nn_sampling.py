#!/usr/bin/env python

import grass.script as grass

# SAMPLE EXPLANATORY VARIABLES IN 3x3km GRID AND 
# EXPORT TO CSV FILE TO USE IN R

def main():
    r_landcover = 'forest_open_fenoscandia_10m@g_LandCover_Fenoscandia'
    
    # set region
    grass.run_command('g.region', raster=r_landcover, res=3000, flags='a')

    # set mask to 50 km from mountains
    r_mountain_mask = 'mountain_areas_50m@g_LandCover_Fenoscandia'
    grass.run_command('r.mask', overwrite=True,
                      raster=r_mountain_mask)
    
    # resample forest / open
    r_landcover_samp = 'forest_open_fenoscandia_nn_3000m'
    #grass.run_command('r.resample', input=r_landcover, 
    #                  output=r_landcover_samp, overwrite=True)

    # vectorize mask
    v_sample_mask = 'temp_forest_open_mask'
    #grass.run_command('r.to.vect', flags='t', input=r_landcover_samp,
    #                  output=v_sample_mask, type='area')

    # create 3x3 km vector sampling grid
    v_sample_grid = 'sample_grid_3000m'
    #grass.run_command('v.mkgrid', map=v_sample_grid, box='3000,3000',
    #                  type='point', overwrite=True)

    # clip vector sampling grid with mask
    v_sample_grid_clip = 'sample_grid_3000m_clip'
    #grass.run_command('v.clip', input=v_sample_grid, 
    #                  clip=v_sample_mask, output=v_sample_grid_clip,
    #                  overwrite=True)

    grass.run_command('g.remove', flags='f', type='vector', name=v_sample_grid)
    grass.run_command('g.remove', flags='f', type='vector', name=v_sample_mask)


    # resample all other variables
    predictors = ['dem_10m_nosefi_float_profc@g_Elevation_Fenoscandia',
                  'dem_10m_nosefi_float_slope@g_Elevation_Fenoscandia',
                  'dem_10m_nosefi_float_aspect_sin@g_Elevation_Fenoscandia',
                  'dem_10m_nosefi_float_aspect_cos@g_Elevation_Fenoscandia',
                  'dem_10m_topex_E@g_Elevation_Fenoscandia_TOPEX',
                  'dem_10m_topex_N@g_Elevation_Fenoscandia_TOPEX',
                  'dem_10m_topex_NE@g_Elevation_Fenoscandia_TOPEX',
                  'dem_10m_topex_NW@g_Elevation_Fenoscandia_TOPEX',
                  'dem_10m_topex_S@g_Elevation_Fenoscandia_TOPEX',
                  'dem_10m_topex_SE@g_Elevation_Fenoscandia_TOPEX',
                  'dem_10m_topex_SW@g_Elevation_Fenoscandia_TOPEX',
                  'dem_10m_topex_W@g_Elevation_Fenoscandia_TOPEX',
                  'dem_10m_topex_exposure@g_Elevation_Fenoscandia_TOPEX',
                  'dem_tpi_250_50m@g_Elevation_Fenoscandia_TPI',
                  'dem_tpi_500_50m@g_Elevation_Fenoscandia_TPI',
                  'dem_tpi_1000_50m@g_Elevation_Fenoscandia_TPI',
                  'dem_tpi_2500_50m@g_Elevation_Fenoscandia_TPI',
                  'dem_tpi_5000_50m@g_Elevation_Fenoscandia_TPI',
                  'dem_tpi_10000_50m@g_Elevation_Fenoscandia_TPI',
                  'dem_10m_nosefi_tri@g_Elevation_Fenoscandia_TRI',
                  'solar_radiation_10m_april@g_EnergyResources_Fenoscandia',
                  'solar_radiation_10m_autumn@g_EnergyResources_Fenoscandia',
                  'solar_radiation_10m_january@g_EnergyResources_Fenoscandia',
                  'solar_radiation_10m_july@g_EnergyResources_Fenoscandia',
                  'solar_radiation_10m_october@g_EnergyResources_Fenoscandia',
                  'solar_radiation_10m_spring@g_EnergyResources_Fenoscandia',
                  'solar_radiation_10m_summer@g_EnergyResources_Fenoscandia',
                  'solar_radiation_10m_winter@g_EnergyResources_Fenoscandia',
                  'solar_radiation_10m_year@g_EnergyResources_Fenoscandia',
                  'bio01_eurolst_10m@g_Meteorology_Fenoscandia',
                  'bio02_eurolst_10m@g_Meteorology_Fenoscandia',
                  'bio10_eurolst_10m@g_Meteorology_Fenoscandia',
                  'bio11_eurolst_10m@g_Meteorology_Fenoscandia',
                  'bio12_worldclim_10m@g_Meteorology_Fenoscandia',
                  'bio15_worldclim_10m@g_Meteorology_Fenoscandia',
                  'bio18_worldclim_10m@g_Meteorology_Fenoscandia',
                  'bio19_worldclim_10m@g_Meteorology_Fenoscandia',
                  'sea_distance_10m@g_SeaRegions_Fenoscandia',
                  'sea_open_distance_50m@g_SeaRegions_Fenoscandia',
                  'water_distance_50m@g_SeaRegions_Fenoscandia',
                  'latitude_10m@g_GeographicalGridSystems_Fenoscandia',
                  'longitude_10m@g_GeographicalGridSystems_Fenoscandia',
                  'dem_10m_nosefi@g_Elevation_Fenoscandia']
    
    #for predictor in predictors:

    #    r_predictor_samp = 'temp_{}_33samp'.format(predictor.split('@', 1)[0])
    #    grass.run_command('r.resample', input=predictor, 
    #                      output=r_predictor_samp, overwrite=True)

        # create column for predictor in attribute table
        # (! columns are created in lower case)
    #    column = '{}'.format(predictor.split('@', 1)[0])
    #    column = str.lower(column)

    #    grass.run_command('v.db.addcolumn', map=v_sample_grid_clip,
    #                      columns='{} double precision'.format(column))
       
        # populate column with predictor value
    #    grass.run_command('v.what.rast', map=v_sample_grid_clip, 
    #                      raster=r_predictor_samp, column=column)
    
    # create column for coordinates X and Y
    #grass.run_command('v.db.addcolumn', map=v_sample_grid_clip,
    #                  columns='X double precision, Y double precision')

    # populate column with coordinates X and Y
    #grass.run_command('v.to.db', map=v_sample_grid_clip, option='coor', 
    #                  columns='X,Y')

    # create column for response in attribute table
    grass.run_command('v.db.addcolumn', map=v_sample_grid_clip,
                      columns='{} double precision'.format('lc'))
       
    # populate column with predictor value
    grass.run_command('v.what.rast', map=v_sample_grid_clip, 
                      raster=r_landcover_samp, column='lc')


    # export attribute table to csv, zoom region to contain only rows and columns with values
    grass.run_command('g.region', raster=r_landcover_samp, 
                       zoom=r_landcover_samp)
    table_variables = '/data/home/zofie.cimburova/ECOFUNC/DATA/observations_33sample'
    grass.run_command('db.out.ogr', input=v_sample_grid_clip, 
                      output=table_variables, format='CSV', overwrite=True)



if __name__ == '__main__':
    main()
