#!/usr/bin/env python

import grass.script as grass
from osgeo import gdal, ogr, osr
from gdalconst import *

# CONTINENTALITY INDICES

def main():
    
    #---------------------------------------------------------#
    #----------------------- RASTERIZE -----------------------#
    #---------------------------------------------------------#
    
    # 1. open DB connection
    conn = ogr.Open('PG:dbname=gisdata')

    for layer in conn:
        # find layer to rasterize
        # TODO - how to open directly this layer?
        if layer.GetName() == 'zofie_cimburova.sea_nosefi_singlepart':
            source_layer = layer
    
    #---------------------------------------------------------#
    # 2. get raster parametres
    rast_param = grass.parse_command('r.info', flags = 'g', map='dem_10m_nosefi_float@g_Elevation_Fenoscandia')
    rows = rast_param.rows
    cols = rast_param.cols
    xmin = rast_param.west
    xmax = rast_param.east+500
    ymin = rast_param.south
    ymax = rast_param.north
    xres = rast_param.nsres
    yres = rast_param.ewres
    

    #---------------------------------------------------------#
    # 3. create an empty raster
    # Filename of the raster Tiff that will be created
    output_raster = 'ECOFUNC/DATA/SEA/sea.tif' 

    # Create dataset: Create(name, resolution x, resolution y, bands, data type
    driver = gdal.GetDriverByName('GTiff')
    target_ds = driver.Create(output_raster, int(cols), int(rows), 1, gdal.GDT_Int16)

    # Projection
    proj = osr.SpatialReference()
    proj.SetUTM(33,1)
    proj.SetWellKnownGeogCS("EPSG:25833")
    target_ds.SetProjection(proj.ExportToWkt())

    # Transformation (top left x, w-e pixel resolution, rotation, top-left y, rotation, n-s pixel resolution)
    target_ds.SetGeoTransform((int(xmin), int(xres), 0, int(ymax), 0, -int(yres)))

    # No data value
    band = target_ds.GetRasterBand(1)
    band.SetNoDataValue(-999)

    #---------------------------------------------------------#
    # 4. Rasterize
    # open dataset (GA_ReadOnly / GA_Update)
    #target_ds = gdal.Open( output_raster, GA_Update )

    gdal.RasterizeLayer(target_ds, [1], source_layer)

    #target_ds = None

    #---------------------------------------------------------#
    # 5. Link to GRASS
    r_land_cover = 'temp_norway@u_zofie.cimburova'
    grass.run_command('r.external', overwrite=True, input='/data/home/zofie.cimburova/'+output_raster, output='sea_10m')



    #--------------------------------------------------------#
    #---------------- DISTANCE FROM OPEN SEA ----------------#
    #--------------------------------------------------------#
    r_sea = 'sea_10m'
    r_land = 'dem_10m_nosefi_land@PERMANENT'

    # 1. extract only sea (1-null)
    #TODO - what code is sea?
    #grass.run_command('r.mapcalc', overwrite = True, expression=r_sea+'= \
    #                  if(isnull('+r_land+'),1,null())')

    # 2. measure distance from inland pixels to sea coast
    r_sea_distance = 'sea_distance_10m'
    #grass.run_command('r.grow.distance', overwrite=True, input=r_sea, distance=r_sea_distance)

    # 3. extract open sea (further than 1 km from coast)
    r_sea_open = 'sea_open_10m'
    limit = 1000
    #grass.run_command('r.grow.distance', overwrite=True, input=r_sea, distance=r_sea_open, flags = 'n')
    #grass.run_command('r.mapcalc', overwrite = True, expression=r_sea_open+'= \
    #                  if('+r_sea_open+'>='+str(limit)+',1,null())')

    # 4. measure distance from inland pixels to open sea
    r_sea_open_distance = 'sea_open_distance_10m'
    #grass.run_command('r.grow.distance', overwrite=True, input=r_sea_open, distance=r_sea_open_distance)

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
