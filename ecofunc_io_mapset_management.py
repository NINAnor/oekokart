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



    # copy data from original mapset (u_zofie.cimburova) to new mapset
    #grass.run_command('g.copy', rast='latitude_10m@u_zofie.cimburova,latitude_10m')
    #grass.run_command('g.copy', rast='longitude_10m@u_zofie.cimburova,longitude_10m')
    #grass.run_command('g.copy', rast='temp_dem_250m@u_zofie.cimburova,dem_250m_nosefi')
    #grass.run_command('g.copy', rast='dem_10m_topex_E@u_zofie.cimburova,dem_10m_topex_E')
    #grass.run_command('g.copy', rast='dem_10m_topex_W@u_zofie.cimburova,dem_10m_topex_W')
    #grass.run_command('g.copy', rast='dem_10m_nosefi_float_tri@g_Elevation_Fenoscandia,dem_10m_nosefi_tri')
    #grass.run_command('g.copy', rast='dem_10m_nosefi_float@PERMANENT,dem_10m_nosefi_float')
    grass.run_command('g.copy', rast='dem_10m_nosefi_float_aspect@PERMANENT,dem_10m_nosefi_float_aspect')
    grass.run_command('g.copy', rast='dem_10m_nosefi_float_slope@PERMANENT,dem_10m_nosefi_float_slope')
    grass.run_command('g.copy', rast='dem_10m_nosefi_float_profc@PERMANENT,dem_10m_nosefi_float_profc')






if __name__ == '__main__':
    main()
