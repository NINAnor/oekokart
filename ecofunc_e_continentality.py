#!/usr/bin/env python

import grass.script as grass
from osgeo import gdal, ogr, osr
from gdalconst import *

# CONTINENTALITY INDICES

def main():
    
    # computational region for test cases
    #grass.run_command('g.region', n=7055175, s=7038355, e=207745, w=192175, res=10)

    # Rasterization in gdal

    # Link to GRASS
    input_raster = 'ECOFUNC/DATA/SEA/sea.tif'
    r_sea_binary = 'sea_binary_10m'
    #grass.run_command('r.external', overwrite=True, input='/data/home/zofie.cimburova/'+input_raster, output=r_sea_binary)
    
    # region
    #grass.run_command('g.region', raster=r_sea_binary)

    # reclass to 1-null()
    r_sea = 'sea_10m'
    #grass.run_command('r.mapcalc', overwrite=True, expression=r_sea+'=\
    #                 if('+r_sea_binary+'==1,1,null())')

    #--------------------------------------------------------#
    #---------------- DISTANCE FROM OPEN SEA ----------------#
    #--------------------------------------------------------#
    
    # 1. measure distance from inland pixels to sea coast
    r_sea_distance = 'sea_distance_10m'
    #grass.run_command('r.grow.distance', overwrite=True, input=r_sea, distance=r_sea_distance)

    # 2. extract open sea (further than x km from coast)
    limit = 5000

    # adjust computational region
    rast_param = grass.parse_command('r.info', flags = 'g', map=r_sea)
    north = int(rast_param.north)
    south = int(rast_param.south)
    east = int(rast_param.east)
    west = int(rast_param.west)

    grass.run_command('g.region', n=str(north), 
                      s=str(south), 
                      e=str(east), 
                      w=str(west), res=10)

    r_sea_open = 'sea_open_10m'

    grass.run_command('r.grow', flags='m', overwrite=True, input=r_sea, output=r_sea_open, radius=-limit, old=1, new=1)

    # 4. measure distance from inland pixels to open sea
    r_sea_open_distance = 'sea_open_distance_10m'
    grass.run_command('r.grow.distance', overwrite=True, input=r_sea_open, distance=r_sea_open_distance)

    # 5. compute number of sea pixels in various neighbourhoods
    # TODO what size
    size = 101
    r_sea_count = 'sea_count_' + str(size) + '_10m'
    #grass.run_command('r.neighbors', overwrite = True, input=r_sea, output=r_sea_count, method='sum', size=size, flags = 'c')
    #grass.run_command('r.mapcalc', overwrite = True, expression=r_sea_count+'=\
    #                  if(isnull('+r_sea_count+'),0,'+r_sea_count+')')
    #grass.run_command('r.mapcalc', overwrite = True, expression=r_sea_count+'=\
    #                  if(isnull('+r_sea+'),'+r_sea_count+',null())')

if __name__ == '__main__':
    main()
