#!/usr/bin/env python

"""
NAME:    Compute proximity to water bodies

AUTHOR(S): Zofie Cimburova < zofie.cimburova AT nina.no>

PURPOSE:   Compute proximity to water bodies.
           Euclidean distance.
"""

"""
To Dos:
"""

import grass.script as grass

def main():

    # Rasterization in gdal

    # link to GRASS
    input_raster = 'ECOFUNC/DATA/WATER_AREAS/water.tif'
    r_water_binary = 'water_binary_10m'
    grass.run_command('r.external', overwrite=True, 
                      input='/data/home/zofie.cimburova/'+input_raster, 
                      output=r_water_binary)
    
    # region
    grass.run_command('g.region', raster=r_water_binary)

    # reclass 1-0 to 1-null()
    r_water = 'water_10m'
    
    grass.run_command('r.mapcalc', overwrite=True, expression='{}=\
                     if({}==1,1,null())'.format(r_water,r_water_binary))

    # remove binary leyer
    grass.run_command('g.remove', flags='f', type='raster', 
                      name=r_water_binary)

    # region
    grass.run_command('g.region', flags='a', raster=r_water, res=50)

    # distance to water
    r_water_distance = 'water_distance_50m'
    grass.run_command('r.grow.distance', overwrite=True,
                      input=r_water, distance=r_water_distance)

if __name__ == '__main__':
    main()
