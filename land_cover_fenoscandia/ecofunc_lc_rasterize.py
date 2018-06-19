#!/usr/bin/env python

"""
NAME:    Rasterize vector land cover

AUTHOR(S): Zofie Cimburova < zofie.cimburova AT nina.no>

PURPOSE:   Rasterize vector land cover by tiles and link to GRASS.
"""

"""
To Dos:
"""

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
    conn = ogr.Open('PG:dbname=gisdata')

    for layer in conn:
        # find layer to rasterize
        # TODO - how to open directly this layer?
        if layer.GetName() == 'zofie_cimburova.landcover_nosefi':
            source_layer = layer
    
    #---------------------------------------------------------#
    # 2. get raster parametres
    rast_param = grass.parse_command('r.info', flags = 'g',
                                     map='dem_10m_nosefi_float@g_Elevation_Fenoscandia')
    rows = rast_param.rows
    cols = rast_param.cols
    xmin = rast_param.west
    xmax = rast_param.east
    ymin = rast_param.south
    ymax = rast_param.north
    xres = rast_param.nsres
    yres = rast_param.ewres
   
    #---------------------------------------------------------#
    # 3. create an empty raster
    # Filename of the raster Tiff that will be created
    output_raster = 'ECOFUNC/DATA/LC/landcover_nosefi.tif' 

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

    layerDefinition = source_layer.GetLayerDefn()
    attribute = layerDefinition.GetFieldDefn(3).GetName()
    print attribute

    gdal.RasterizeLayer(target_ds, [1], source_layer,
                        options=["ATTRIBUTE=%s" % (attribute)])

    #target_ds = None

    #---------------------------------------------------------#
    # 5. Link to GRASS
    r_land_cover = 'temp_norway@u_zofie.cimburova'
    grass.run_command('r.external', overwrite=True,
                      input='/data/home/zofie.cimburova/'+output_raster,
                      output='landcover_nosefi_10m')


if __name__ == '__main__':
    main()
