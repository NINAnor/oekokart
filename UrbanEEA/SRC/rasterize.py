#!/usr/bin/env python

# RASTERIZE LAND COVER

import grass.script as grass
import math
from grass.script import run_command, message, parser
from osgeo import gdal, ogr, osr
from gdalconst import *
from grass.pygrass.modules.shortcuts import vector as v
from grass.pygrass.modules import Module


def main():

    #---------------------------------------------------------#
    #----------------------- RASTERIZE -----------------------#
    #---------------------------------------------------------#
    
    # 1. open DB connection
    #conn = ogr.Open('PG:dbname=gisdata')

    #for layer in conn:
        # find layer to rasterize
        # TODO - how to open directly this layer?
    #    if layer.GetName() == 'zofie_cimburova.landcover_nosefi':
    #        source_layer = layer
    
    #---------------------------------------------------------#
    # 2. get raster parametres
    #rast_param = grass.parse_command('r.info', flags = 'g',
    #                                 map='dem_10m_nosefi_float@g_Elevation_Fenoscandia')
    #rows = 27586
    #cols = 21537
    #xmin = 148350
    #xmax = 363720
    #ymin = 6519850
    #ymax = 6795710
    #xres = 10
    #yres = 10

    rows = 1000
    cols = 1000
    xmin = 230000
    xmax = 240000
    ymin = 6600000
    ymax = 6610000
    xres = 10
    yres = 10
   
    #---------------------------------------------------------#
    # 3. create an empty raster
    # Filename of the raster Tiff that will be created
    output_raster = 'ESTIMAP/DATA/fkb_ar5_10m.tiff' 

    # Create dataset: Create(name, resolution x, resolution y, bands, data type
    driver = gdal.GetDriverByName('GTiff')
    target_ds=driver.Create(output_raster,int(cols),int(rows),1,gdal.GDT_Int16)

    # Projection
    proj = osr.SpatialReference()
    proj.SetUTM(33,1)
    proj.SetWellKnownGeogCS("EPSG:25833")
    target_ds.SetProjection(proj.ExportToWkt())

    # Transformation (top left x, w-e pixel resolution, rotation, top-left y,
    # rotation, n-s pixel resolution)
    target_ds.SetGeoTransform((int(xmin),int(xres),0,int(ymax),0,-int(yres)))

    # No data value
    band = target_ds.GetRasterBand(1)
    band.SetNoDataValue(-999)

    #---------------------------------------------------------#
    # 4. Rasterize
    # open dataset (GA_ReadOnly / GA_Update)
    #target_ds = gdal.Open( output_raster, GA_Update )
    source_layer = "fkb_ar5_oslo_kommuner_avgrensing@p_ESTIMAP_zofie.cimburova"
    attribute = "LC_TYPE"
    print attribute

    gdal.RasterizeLayer(target_ds, [1], source_layer,
                        options=["ATTRIBUTE=LC_TYPE"])

    #target_ds = None

    #---------------------------------------------------------#
    # 5. Link to GRASS
    #grass.run_command('r.external', flags= 'o',
    #                  input='/data/home/zofie.cimburova/ESTIMAP/DATA/fkb_ar5_10m.tiff',
    #                  output='fkb_ar5_10m', overwrite=True)


if __name__ == '__main__':
    main()
