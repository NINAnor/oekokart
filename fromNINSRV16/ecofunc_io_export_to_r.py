#!/usr/bin/env python

import grass.script as grass

# SAMPLE EXPLANATORY VARIABLES AND 
# EXPORT TO CSV FILE TO USE IN R

def main():
    r_landcover = 'forest_open_fenoscandia_10m@g_LandCover_Fenoscandia'

    # ######################### #
    # 1. Ectract mountain areas #
    # ######################### #
    # 50 km buffer from open land

    #grass.run_command('g.region', raster=r_land_cover, res=50, flags='a')
    
    #r_land_cover_50m = 'temp_landcover_forest_open_fenoscandia_50m'
    #grass.run_command('r.resamp.stats', input=r_land_cover,\
    #                  output=r_land_cover_50m, method='minimum')

    #limit_km = 50
    #limit_pix = limit_km*1000/50
    
    # extract only open land
    #r_land_cover_reclassed = 'temp_open'
    #grass.run_command('r.mapcalc', overwrite=True, 
    #                  expression='{}=if({}==0,1,null())'.format(\
    #                  r_land_cover_reclassed,r_land_cover_50m))
    
    # tile to limit km + 120 km + limit km (max = 32000 pix)
    #tile_limit_km = 120
    #tile_limit_pix = tile_limit_km*1000/50
    #grass.run_command('r.tile', input=r_land_cover_reclassed, 
    #                  output=r_land_cover_reclassed, width=tile_limit_pix,
    #                  height=tile_limit_pix, overlap=limit_pix)

    # buffer for each tile
    #tile_list = grass.parse_command('g.list', type='raster', 
    #                                pattern='temp_open-*',
    #                                mapset='g_LandCover_Fenoscandia') 
    #for tile in tile_list:
        # set comp. region to tile
    #    grass.run_command('g.region', raster=tile)
        
        # check if tile contains anything
    #    stats = grass.parse_command('r.stats', flags='c', input=tile)
        
        # if tile contains any information
    #    tile_buffer = 'tile_open_buffer{}'.format(tile[9:])
    #    tile_buffer = tile_buffer.replace('-','_')
    #    print tile_buffer
    #    if len(stats.keys()) > 1:
    #        print 'tile {} contains open land, file {} created'.format(tile, tile_buffer)
    #        grass.run_command('r.grow', overwrite=True, input=tile,
    #                          output=tile_buffer, radius=limit_pix,
    #                          old=1, new=1)
    #    else: 
    #        print 'tile {} contains nothing'.format(tile)

    # patch first raster
    r_mountain_areas = 'mountain_areas_50m@g_LandCover_Fenoscandia'
    #grass.run_command('g.region', raster=r_land_cover_reclassed)
    #tile_list = []

    #for i in range(14):
    #    for j in range(14):
    #        tile = 'tile_open_buffer_{}_{}'.format(str(i).zfill(3),str(j).zfill(3))

            # check if tile exists
    #        exists = grass.find_file(tile, element = 'cell', mapset='g_LandCover_Fenoscandia')

    #        if exists['fullname']:
    #            print '{} exists. Patching.'.format(tile)
    #            tile_list.append(tile)
    #        else:
    #            print '{} does not exist. Skipping.'.format(tile)
    
    # patch
    #grass.run_command('r.patch', input=tile_list, 
    #                  output=r_mountain_areas, overwrite=True)

    # remove 50 m landcover
    #grass.run_command('g.remove', flags='f', type='raster',
    #                  name=r_land_cover_50m)

    # remove tiles of buffer
    #grass.run_command('g.remove', flags='f', type='raster',
    #                  pattern='tile_open_buffer_*')

    # remove tiles of open land
    #grass.run_command('g.remove', flags='f', type='raster',
    #                  pattern='temp_open-*')

    # remove open land raster
    #grass.run_command('g.remove', flags='f', type='raster',
    #                  name=r_land_cover_reclassed)



    # ############## #
    # 2. Create mask #
    # ############## #
    # based on mountain areas and land cover coverage
    # mask covers non-mountain areas and areas with less than 
    # half of area covered by forst/open land
    grass.run_command('g.region', flags='a', res=1000, raster=r_landcover)

    # mask non-mountain areas
    grass.run_command('r.mask', raster=r_mountain_areas, overwrite=True)

    # compute how big portion of cell is covered by forest and open land 
    r_landcover_count = 'temp_landcover_count_1000m'
    #grass.run_command('r.resamp.stats', input=r_landcover, method='count',
    #                  output=r_landcover_count, overwrite=True)

    # mask areas with coverage less than 50 % = 5000 cells
    r_sample_mask = 'temp_mask_landcover_count'
    #grass.run_command('r.mapcalc', overwrite = True, 
    #                  expression='{}=if({}>=5000,1,null())'.format(\
    #                  r_sample_mask,r_landcover_count))
    grass.run_command('r.mask', raster=r_sample_mask, overwrite=True)

    # vectorize mask
    #v_sample_mask = 'temp_mask_landcover_count'
    #grass.run_command('r.to.vect', flags='t', input=r_sample_mask,
    #                  output=v_sample_mask, type='area')

    # create 1x1 km vector sampling grid
    # this makes 2 554 704 sampling points, but not all of them will be used,
    # some will be masked out
    #v_sample_grid_01 = 'sample_grid_01_1000m'
    #grass.run_command('v.mkgrid', map=v_sample_grid_01, box='1000,1000',
    #                  type='point', overwrite='TRUE')

    # clip vector sampling grid with mask
    v_sample_grid_clip = 'sample_grid_1000m_clip'
    #grass.run_command('v.clip', input=v_sample_grid_01, 
    #                  clip=v_sample_mask, output=v_sample_grid_clip)
    

    # ################################## #
    # 3. Sample response and predictores #
    # ################################## #
    
    # ############### #
    # 1. 0-1 approach # NOT USED
    # ############### #
    '''
    # ------------------------------------------------- #
    # ----- 1.1. create 1x1 km 0-1 landcover grid ----- #
    # ------------------------------------------------- #
    r_landcover_01 = 'landcover_forest_open_fenoscandia_01_1000m'
    
    grass.run_command('r.mask', raster=r_mountain_areas)
    grass.run_command('r.resamp.interp', input=r_landcover, 
                      output=r_landcover_01, method='nearest')
    
    # ---------------------------------------------- #
    # ----- 1.2. create 1x1 km grids of height ----- #
    # ---------- used for filtering ---------------- #
    # ---------------------------------------------- #
    r_height = 'dem_10m_nosefi_float@g_Elevation_Fenoscandia'
    r_height_1000m = 'dem_1000m_nosefi'

    grass.run_command('r.resamp.interp', input=r_height, 
                      output=r_height_1000m, method='nearest')
    
    # --------------------------------------------- #
    # ----- 1.3. filter response using height ----- #
    # --------------------------------------------- #
    # filter separately forest and open land

    for type in [0,1]:
        
        # create mask
        r_temp_mask = 'temp_mask_{}'.format(type)
        grass.run_command('r.mapcalc', overwrite='TRUE',
                          expression='{}=if({}=={},1,null())'.format(\
                          r_temp_mask,r_landcover_01,type))
        grass.run_command('r.mask', overwrite=True, raster=r_temp_mask)

        # go through various neighbourhood sizes [km]
        for distance in [20]:

            neighbourhood = distance*2+1

            # calculate median height in neighbourhood
            r_height_median = 'temp_med_height_{}_{}m'.format(type,distance*1000)
            
            grass.run_command('r.neighbors', flags='c', overwrite=True, 
                              input=r_height_1000m, output=r_height_median,
                              method='median', size=neighbourhood)
        
            # calculate difference of actual height and median height
            r_height_diff = 'temp_med_height_{}_{}m_diff'.format(type,distance*1000)
            grass.run_command('r.mapcalc', overwrite = True, 
                              expression='{}={}-{}'.format(r_height_diff,\
                              r_height_1000m,r_height_median))
        
            # delete temporary maps
            grass.run_command('g.remove', flags='f', type='raster', 
                              name=r_height_median)
         
            # create table of univariate statistics
            t_med_height_diff_stat = 'ECOFUNC/DATA/median_height_{}_{}m_diff_stats'\
                                     .format(type,distance*1000)
            stats = grass.parse_command('r.univar', overwrite=True, flags='ge', 
                    map=r_height_diff)        
            Q1 = float(stats.first_quartile)
            Q3 = float(stats.third_quartile)
            min = float(stats.min)
            max = float(stats.max)
            mild_limit_min = Q1 - 1.5*(Q3-Q1)
            mild_limit_max = Q3 + 1.5*(Q3-Q1)
            extr_limit_min = Q1 - 3*(Q3-Q1)
            extr_limit_max = Q3 + 3*(Q3-Q1)

            with open(t_med_height_diff_stat, "w") as text_file:
                text_file.write("Min:     {}\n".format(min))
                text_file.write("Q1:      {}\n".format(Q1))
                text_file.write("Q3:      {}\n".format(Q3))
                text_file.write("Max:     {}\n".format(max))
                text_file.write("Mild:    {}\t{}\n".format(mild_limit_min, mild_limit_max))
                text_file.write("Extreme: {}\t{}\n".format(extr_limit_min, extr_limit_max))
    
        grass.run_command('r.mask', flags='r')
        grass.run_command('g.remove', flags='f', type='raster', 
                          name=r_temp_mask)
    '''


    # ################# #
    # 2. ratio approach #
    # ################# #

    # create 1x1 km grid of predictors
    predictors = ['dem_10m_nosefi_float_profc@g_Elevation_Fenoscandia',
                  'dem_10m_nosefi_float_slope@g_Elevation_Fenoscandia',
                  'dem_10m_topex_E@g_Elevation_Fenoscandia_TOPEX',
                  'dem_10m_topex_N@g_Elevation_Fenoscandia_TOPEX',
                  'dem_10m_topex_NE@g_Elevation_Fenoscandia_TOPEX',
                  'dem_10m_topex_NW@g_Elevation_Fenoscandia_TOPEX',
                  'dem_10m_topex_S@g_Elevation_Fenoscandia_TOPEX',
                  'dem_10m_topex_SE@g_Elevation_Fenoscandia_TOPEX',
                  'dem_10m_topex_SW@g_Elevation_Fenoscandia_TOPEX',
                  'dem_10m_topex_W@g_Elevation_Fenoscandia_TOPEX',
                  'dem_tpi_250_50m@g_Elevation_Fenoscandia_TPI',
                  'dem_tpi_500_50m@g_Elevation_Fenoscandia_TPI',
                  'dem_tpi_1000_50m@g_Elevation_Fenoscandia_TPI',
                  'dem_tpi_2500_50m@g_Elevation_Fenoscandia_TPI',
                  'dem_tpi_5000_50m@g_Elevation_Fenoscandia_TPI',
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
                  'dem_10m_nosefi_float_aspect_sin@g_Elevation_Fenoscandia',
                  'dem_10m_nosefi_float_aspect_cos@g_Elevation_Fenoscandia',
                  'dem_tpi_10000_50m@g_Elevation_Fenoscandia_TPI',
                  'dem_10m_topex_exposure@g_Elevation_Fenoscandia_TOPEX',
                  'latitude_10m@g_GeographicalGridSystems_Fenoscandia',
                  'longitude_10m@g_GeographicalGridSystems_Fenoscandia']

    # predictors - median value
    #for predictor in predictors:

        # compute median of predictor in 1 km cell
        #r_predictor_med = 'temp_{}_med'.format(predictor.split('@', 1)[0])
        #grass.run_command('r.resamp.stats', input=predictor,
        #                  output=r_predictor_med, method='median',
        #                  overwrite=True)

        # create column for predictor in attribute table
        # (! columns are created in lower case)
        #column_med = '{}'.format(predictor.split('@', 1)[0])
        #column_med = str.lower(column_med)

        #grass.run_command('v.db.addcolumn', map=v_sample_grid_clip,
        #              columns='{} double precision'.format(column_med))
       
        # populate column with predictor value
        #grass.run_command('v.what.rast', map=v_sample_grid_clip, 
        #                  raster=r_predictor_med, column=column_med)
    
    predictors = ['dem_10m_topex_exposure@g_Elevation_Fenoscandia_TOPEX']
    # predictors - average value
    #for predictor in predictors:
    # compute average of predictor in 1 km cell
    #    r_predictor_avg = 'temp_{}_avg'.format(predictor.split('@', 1)[0])
    #    grass.run_command('r.resamp.stats', input=predictor,
    #                      output=r_predictor_avg, method='average',
    #                      overwrite=True)

        # create column for predictor in attribute table
        # (! columns are created in lower case)
    #    column_avg = '{}'.format(predictor.split('@', 1)[0])
    #    column_avg = str.lower(column_avg)

    #    grass.run_command('v.db.addcolumn', map=v_sample_grid_clip,
    #                  columns='{} double precision'.format(column_avg))
       
        # populate column with predictor value
    #    grass.run_command('v.what.rast', map=v_sample_grid_clip, 
    #                      raster=r_predictor_avg, column=column_avg)

    # create column for coordinates X and Y
    #grass.run_command('v.db.addcolumn', map=v_sample_grid_clip,
    #                  columns='X double precision, Y double precision')

    # populate column with coordinates X and Y
    #grass.run_command('v.to.db', map=v_sample_grid_clip, option='coor', columns='X,Y')

    # create column for average height
    #grass.run_command('v.db.addcolumn', map=v_sample_grid_clip,
    #                  columns='height double precision')

    # populate column with height
    r_height_1000 = 'dem_1000m_nosefi_avg@g_Elevation_Fenoscandia'
    #grass.run_command('v.what.rast', map=v_sample_grid_clip, 
    #                  raster=r_height_1000, column='height')

    # response - Ntrials and Nsuccess
    # number of successes
    r_landcover_nsuccess = 'landcover_nsuccess_1000m'
    #grass.run_command('r.resamp.stats', input=r_landcover, method='sum',
    #                  output=r_landcover_nsuccess, overwrite=True)
    
    # number of trials
    r_landcover_ntrials = 'landcover_ntrials_1000m'
    #grass.run_command('r.resamp.stats', input=r_landcover, method='count',
    #                  output=r_landcover_ntrials, overwrite=True)

    # create columns - Ntrials and Nsuccess
    #rass.run_command('v.db.addcolumn', map=v_sample_grid_clip,
    #                  columns='ntrials int')
    #grass.run_command('v.db.addcolumn', map=v_sample_grid_clip,
    #                  columns='nsuccess int')

    # populate columns - Ntrials and Nsuccess
    #grass.run_command('v.what.rast', map=v_sample_grid_clip, 
    #                  raster=r_landcover_ntrials, column='ntrials')
    #grass.run_command('v.what.rast', map=v_sample_grid_clip, 
    #                  raster=r_landcover_nsuccess, column='nsuccess')

    # export attribute table to csv
    table_variables = '/data/home/zofie.cimburova/ECOFUNC/DATA/observations_fenoscandia'
    grass.run_command('db.out.ogr', input=v_sample_grid_clip, 
                      output=table_variables, format='CSV', overwrite=True)


if __name__ == '__main__':
    main()
