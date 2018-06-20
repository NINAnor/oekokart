#!/usr/bin/env python

import grass.script as grass


def main():
    # create new mapsets
    #grass.run_command('g.mapset', mapset='g_GeographicalGridSystems_Fenoscandia', location='ETRS_33N', flags='c')
    #grass.run_command('g.mapset', mapset='g_Elevation_Fenoscandia', location='ETRS_33N', flags='c')
    #grass.run_command('g.mapset', mapset='g_Elevation_Fenoscandia_TOPEX', location='ETRS_33N', flags='c')
    #grass.run_command('g.mapset', mapset='g_Elevation_Fenoscandia_TOPEX', location='ETRS_33N', flags='c')
    #grass.run_command('g.mapset', mapset='g_Elevation_Fenoscandia_TRI', location='ETRS_33N', flags='c')
    #grass.run_command('g.mapset', mapset='g_Elevation_Fenoscandia_TPI', location='ETRS_33N', flags='c')
    #grass.run_command('g.mapset', mapset='g_Elevation_Fenoscandia_SDE', location='ETRS_33N', flags='c')
    #grass.run_command('g.mapset', mapset='g_Elevation_Fenoscandia_RTP', location='ETRS_33N', flags='c')
    #grass.run_command('g.mapset', mapset='g_SeaRegions_Fenoscandia', location='ETRS_33N', flags='c')
    #grass.run_command('g.mapset', mapset='g_LandCover_Fenoscandia', location='ETRS_33N', flags='c')
    #grass.run_command('g.mapset', mapset='g_Meteorology_Fenoscandia', location='ETRS_33N', flags='c')
    #grass.run_command('g.mapset', mapset='g_EnergyResouces_Fenoscandia', location='ETRS_33N', flags='c')


    # copy data from original mapset (u_zofie.cimburova) to new mapset
    #grass.run_command('g.copy', rast='latitude_10m@u_zofie.cimburova,latitude_10m')
    #grass.run_command('g.copy', rast='longitude_10m@u_zofie.cimburova,longitude_10m')
    #grass.run_command('g.copy', rast='temp_dem_250m@u_zofie.cimburova,dem_250m_nosefi')
    #grass.run_command('g.copy', rast='dem_10m_topex_E@u_zofie.cimburova,dem_10m_topex_E')
    #grass.run_command('g.copy', rast='dem_10m_topex_W@u_zofie.cimburova,dem_10m_topex_W')
    #grass.run_command('g.copy', rast='dem_10m_nosefi_float_tri@g_Elevation_Fenoscandia,dem_10m_nosefi_tri')
    #grass.run_command('g.copy', rast='dem_10m_nosefi_float@PERMANENT,dem_10m_nosefi_float')
    #grass.run_command('g.copy', rast='dem_10m_nosefi_float_aspect@PERMANENT,dem_10m_nosefi_float_aspect')
    #grass.run_command('g.copy', rast='dem_10m_nosefi_float_slope@PERMANENT,dem_10m_nosefi_float_slope')
    #grass.run_command('g.copy', rast='dem_10m_nosefi_float_profc@PERMANENT,dem_10m_nosefi_float_profc')
    #grass.run_command('g.copy', rast='sea_10m@u_zofie.cimburova,sea_10m')
    #grass.run_command('g.copy', rast='bio11_gwr_estimates@g_LandCover_Fenoscandia,bio11_eurolst_10m')
    #grass.run_command('g.copy', rast='solar_radiation_10m_summer@u_zofie.cimburova,solar_radiation_summer_10m')
    #grass.run_command('g.copy', rast='solar_radiation_10m_spring@u_zofie.cimburova,solar_radiation_spring_10m')
    #grass.run_command('g.copy', rast='solar_radiation_10m_year@u_zofie.cimburova,solar_radiation_year_10m')
    #grass.run_command('g.copy', rast='eurolst_clim.bio12_10m@g_LandCover_Fenoscandia,bio12_eurolst_10m')

    # move land cover tiles in a special mapset
    #grass.run_command('g.mapset', flags='c', location='ETRS_33N',
    #                  mapset='g_LandCover_Fenoscandia_tiles')

    # collect tiles in g_LandCover_Fenoscandia 
    # and move them to g_LandCover_Fenoscandia_tiles
    tiles_forest_line = grass.parse_command('g.list', type='raster', 
                                            pattern='LC_tile_*',
                                            mapset='g_LandCover_Fenoscandia')
    grass.run_command('g.mapset', location='ETRS_33N',
                      mapset='g_LandCover_Fenoscandia')
    
    for tile in tiles_forest_line:
        #grass.run_command('g.copy', overwrite=True,
        #                  rast='{}@g_LandCover_Fenoscandia,{}'.format(tile,tile))
        grass.run_command('g.remove', name=tile, flags='f', 
                          type='raster')


if __name__ == '__main__':
    main()
