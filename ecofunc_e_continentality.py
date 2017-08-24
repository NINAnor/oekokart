#!/usr/bin/env python

import grass.script as grass
from osgeo import gdal, ogr, osr
from gdalconst import *
import sys

# CONTINENTALITY INDICES
# SEA PROXIMITY

def main():
    
    # Rasterization in gdal

    # Link to GRASS
    input_raster = 'ECOFUNC/DATA/SEA/sea.tif'
    r_sea_binary = 'sea_binary_10m'
    grass.run_command('r.external', overwrite=True, 
                      input='/data/home/zofie.cimburova/'+input_raster, 
                      output=r_sea_binary)
    
    # region
    grass.run_command('g.region', raster=r_sea_binary)

    # reclass to 1-null()
    r_sea = 'sea_10m'
    
    grass.run_command('r.mapcalc', overwrite=True, expression=r_sea+'=\
                     if('+r_sea_binary+'==1,1,null())')
    grass.run_command('g.remove', flags='f', type='raster', name=r_sea_binary)

    #---------------------------------------------------#
    #---------------- DISTANCE FROM SEA ----------------#
    #---------------------------------------------------#
    grass.run_command('g.region', raster=r_sea)

    # measure distance from inland pixels to sea coast
    r_sea_distance = 'sea_distance_10m'
    grass.run_command('r.grow.distance', overwrite=True, input=r_sea, 
                      distance=r_sea_distance)

    #--------------------------------------------------------#
    #---------------- DISTANCE FROM OPEN SEA ----------------#
    #--------------------------------------------------------#
    # tile sea
    r_sea_tile = 'sea_10m_tile_'
    limit = 5000
    grass.run_command('r.tile', input=r_sea, output=r_sea_tile, 
                      width=10000, height=10000, overlap=limit/10)
    
    # iterate through tiles (380)
    tile_list = grass.parse_command('g.list', type='raster', 
                                    pattern='{}*'.format(r_sea_tile))
    i=0

    for tile in tile_list:
        # replace "-" with "_"
        tile.replace('-','_')

        # set computational region to tile
        grass.run_command('g.region', raster=tile)
        
        # set name for open sea tile
        r_sea_open_tile = 'sea_open{}'.format(tile[3:])
        r_sea_open_tile = r_sea_open_tile.replace('-','_')

        # 3 possibilities - only nulls, only ones, mix
        stats = grass.parse_command('r.univar', flags='g', map=tile)
        
        # only nulls
        if len(stats) == 0:
            print '{} only nulls'.format(r_sea_open_tile)
            grass.run_command('r.mapcalc', overwrite=True, expression=
                              '{}=1'.format(r_sea_open_tile))

        # only ones
        elif int(stats.null_cells) == 0:
            print '{} only ones, skipped'.format(r_sea_open_tile)
            continue
        
        # coast
        else:
            print '{} coast'.format(r_sea_open_tile)
            grass.run_command('r.grow', flags='m', overwrite=True, 
                              input=tile, output=r_sea_open_tile, 
                              radius=-limit, old=1, new=1)
            grass.run_command('r.mapcalc', overwrite=True, expression=
                              '{}=if(isnull({}), 1, null())'.format(\
                              r_sea_open_tile,r_sea_open_tile))
   
    # patch
    grass.run_command('g.region', raster=r_sea)
    r_sea_open = 'sea_open_10m'
    tiles_sea_open = grass.parse_command('g.list', type='raster', 
                                        pattern='sea_open_10m_tile__*',
                                        mapset='g_SeaRegions_Fenoscandia')
    grass.run_command('r.patch', input=tiles_sea_open, 
                      output=r_sea_open, overwrite=True)

    # remove tiles
    grass.run_command('g.remove', flags='f', type='raster', 
                      name=tiles_sea_open)
    grass.run_command('g.remove', flags='f', type='raster', 
                      pattern='sea_10m_tile_*')

    
    # measure distance from inland pixels to open sea
    # shrink and change resolution of computational region 
    # (with 10m, memory problem occure with r.grow.distance)
    rast_param = grass.parse_command('r.info', flags = 'g', map=r_sea_open)
    xmin = int(rast_param.west)+5000
    xmax = int(rast_param.east)-5000
    ymin = int(rast_param.south)+5000
    ymax = int(rast_param.north)-5000
    
    grass.run_command('g.region', n=ymax, s=ymin, e=xmax, w=xmin, 
                      res=50, flags='a')

    r_sea_open_distance = 'sea_open_distance_50m'
    grass.run_command('r.grow.distance', overwrite=True, input=r_sea_open, 
                      distance=r_sea_open_distance, flags='n')

if __name__ == '__main__':
    main()
