#!/usr/bin/env python

import grass.script as grass

# TERRAIN INDICES

def main():


    # TRI
    #r_tri = 'dem_10m_nosefi_float_tri@g_Elevation_Fenoscandia'
    #grass.run_command('r.tri', overwrite=True, wsize=1, dem=r_height, tri=r_tri)

   
    # TPI
    # --------------------------------------------------- #
    # 1. resample terrain to coarser resolution (50x50)
    # --------------------------------------------------- #
    resolution = 50
    
    r_height_10 = "dem_10m_nosefi_float@g_Elevation_Fenoscandia"
    r_height = 'dem_50m_nosefi@g_Elevation_Fenoscandia'
    #grass.run_command('g.mapset', mapset='g_Elevation_Fenoscandia')
    #grass.run_command('g.region', n=7939995, s=6132445, e=1335785, w=-77365, res=resolution)
    #grass.run_command('r.resamp.stats', input=r_height_10, output=r_height, overwrite=True)
    grass.run_command('g.mapset', mapset='g_Elevation_Fenoscandia_TPI')
    grass.run_command('g.region', raster=r_height)

    # --------------------------------------------------- #
    # 2. go through neighbourhoods
    # --------------------------------------------------- #
    
    neighbourhoods_m = [250,500,1000,2500,5000]
    neighbourhoods = [2*x/resolution+1 for x in neighbourhoods_m]

    for size in neighbourhoods:
        distance = resolution*(size-1)/2
        
    # --------------------------------------------------- #
    # 3. create tiles with buffer of neighbourhood size
    # --------------------------------------------------- #
        if size > 101:
            grass.run_command('r.tile', input=r_height, output='dem_50m_neigh_'+str(size)+'_tile', 
                              width=100000/resolution, height=100000/resolution, overlap=size)
        
    # --------------------------------------------------- #
    # 4. go through tiles
    # --------------------------------------------------- #
        maps = grass.parse_command('g.list', type='raster', pattern='dem_50m_neigh_'+str(size)+'_tile*', mapset='g_Elevation_Fenoscandia_TPI')
        
        if size > 41:
            for dem_tile in maps:

                # set computational region to tile
                grass.run_command('g.region', raster=dem_tile)

        # --------------------------------------------------- #
        # 5. average height in neighbourhood
        # --------------------------------------------------- #
                r_height_avg = 'dem_avg_' + str(distance) + '_50m'
                grass.run_command('r.neighbors', overwrite=True, input=dem_tile, output=r_height_avg, size=size, flags='c')
                
                #r_height_min = 'dem_min_' + str(distance) + '_10m'
                #grass.run_command('r.neighbors', overwrite=True, input=r_height, output=r_height_min, size=size, method='minimum', flags='c')

                #r_height_max = 'dem_max_' + str(distance) + '_10m'
                #grass.run_command('r.neighbors', overwrite=True, input=r_height, output=r_height_max, size=size, method='maximum', flags='c')
             
                #r_height_range = 'dem_range_' + str(distance) + '_10m'
                #grass.run_command('r.neighbors', overwrite=True, input=r_height, output=r_height_range, size=size, method='range', flags='c')
                
        # --------------------------------------------------- #
        # 6. TPI
        # --------------------------------------------------- #
                r_tpi = 'dem_tpi_50m' + dem_tile[7:]

                # expression does not like '-'
                r_tpi = r_tpi.replace('-','_')

                # shrink computational region
                rast_param = grass.parse_command('r.info', flags = 'g', map=r_height_avg)

                xmin = int(rast_param.west) + distance
                xmax = int(rast_param.east) - distance
                ymin = int(rast_param.south) + distance
                ymax = int(rast_param.north) - distance
                xres = int(rast_param.nsres)
            
                grass.run_command('g.region', n=ymax, s=ymin, e=xmax, w=xmin, res=xres)
                
                grass.run_command('r.mapcalc', overwrite=True, expression=r_tpi+'='+r_height_avg+'-'+r_height)
                
                # delete temporar DEM tile
                grass.run_command('g.remove', flags='f', type='raster', name=dem_tile)

                # delete temporar average DEM tile
                grass.run_command('g.remove', flags='f', type='raster', name=r_height_avg)
    # --------------------------------------------------- #
    # 7. merge tiles
    # --------------------------------------------------- #
        # set computational region to the whole region
        grass.run_command('g.region', raster=r_height)

        # list all TPI tiles
        maps_tpi = grass.parse_command('g.list', type='raster', pattern='dem_tpi_50m_neigh_'+str(size)+'*', mapset='g_Elevation_Fenoscandia_TPI')

        # patch
        if size > 41:
            r_tpi_final = 'dem_tpi_' + str(distance) + '_50m'
            grass.run_command('r.patch', overwrite=True, input=maps_tpi, output=r_tpi_final)
        
            
            # remove TPI tiles
            grass.run_command('g.remove', flags='f', type='raster', name=maps_tpi)



            # RTP
            #r_rtp = 'dem_rtp_' + str(distance) + '_10m'
            #grass.run_command('r.mapcalc', overwrite=True, expression=r_rtp+'=('+r_height+'-'+r_height_min+')/('+r_height_max+'-'+r_height_min+')')
            
            # SDE
            #r_sde = 'dem_sde_' + str(distance) + '_10m'
            #grass.run_command('r.mapcalc', overwrite=True, expression=r_sde+'=('+r_height_avg+'-'+r_height+')/('+r_height_range+')')
            
            # Slope terrain variation
            #r_stv = 'dem_10m_nosefi_float_slope_std'
            #r_slope = 'dem_10m_nosefi_float_slope@PERMANENT'
            #grass.run_command('r.neighbors', overwrite=True, input=r_slope, output=r_stv, method='stddev', flags='c')




if __name__ == '__main__':
    main()
