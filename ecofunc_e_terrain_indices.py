#!/usr/bin/env python

import grass.script as grass

# TERRAIN INDICES

def main():

    # neighbourhood size
    size = 101

    # prepare filtered DEM
    r_height_avg = 'dem_avg' + str(size) + '0_10m'
    #grass.run_command('r.neighbors', overwrite=True, input=r_height, output=r_height_avg, size=size, flags='c')
    
    r_height_min = 'dem_min' + str(size) + '0_10m'
    #grass.run_command('r.neighbors', overwrite=True, input=r_height, output=r_height_min, size=size, method='minimum', flags='c')

    r_height_max = 'dem_max' + str(size) + '0_10m'
    #grass.run_command('r.neighbors', overwrite=True, input=r_height, output=r_height_max, size=size, method='maximum', flags='c')
 
    r_height_range = 'dem_range' + str(size) + '0_10m'
    #grass.run_command('r.neighbors', overwrite=True, input=r_height, output=r_height_range, size=size, method='range', flags='c')
    

    # TRI
    r_tri = 'dem_10m_nosefi_float_tri@g_Elevation_Fenoscandia'
    #grass.run_command('r.tri', overwrite=True, wsize=1, dem=r_height, tri=r_tri)
    
    # TPI
    r_tpi = 'dem_10m_nosefi_float_tpi_' + str(size) + '0'
    #grass.run_command('r.mapcalc', expression=r_tpi+'='+r_height_avg+'-'+r_height)

    # RTP
    r_rtp = 'dem_10m_nosefi_float_rtp_' + str(size) + '0'
    #grass.run_command('r.mapcalc', expression=r_rtp+'=('+r_height+'-'+r_height_min+')/('+r_height_max+'-'+r_height_min+')')
    
    # SDE
    r_sde = 'dem_10m_nosefi_float_sde_' + str(size) + '0'
    #grass.run_command('r.mapcalc', overwrite=True, expression=r_sde+'=('+r_height_avg+'-'+r_height+')/('+r_height_range+')')
    
    # Slope terrain variation
    r_stv = 'dem_10m_nosefi_float_slope_std'
    r_slope = 'dem_10m_nosefi_float_slope@PERMANENT'
    #grass.run_command('r.neighbors', overwrite=True, input=r_slope, output=r_stv, method='stddev', flags='c')




if __name__ == '__main__':
    main()
