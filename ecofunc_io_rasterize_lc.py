#!/usr/bin/env python

# RASTERIZE LAND COVER AND DETECT FOREST LINE

import grass.script as grass
import math
from grass.script import run_command, message, parser
from osgeo import gdal, ogr, osr
from gdalconst import *
from grass.pygrass.modules.shortcuts import vector as v
from grass.pygrass.modules import Module


def main():

    # computational region for test cases
    #grass.run_command('g.region', n=7045175, s=7038355, e=207745, w=202175, res=10)
    
    #---------------------------------------------------------#
    #----------------------- RASTERIZE -----------------------#
    #---------------------------------------------------------#
    
    # 1. open DB connection
    conn = ogr.Open('PG:dbname=gisdata')

    for layer in conn:
        # find layer to rasterize
        # TODO - how to open directly this layer?
        if layer.GetName() == 'zofie_cimburova.temp_finland':
            source_layer = layer
    
    #---------------------------------------------------------#
    # 2. get raster parametres
    #rast_param = grass.parse_command('r.info', flags = 'g', map='dem_10m_nosefi_float@PERMANENT')
    #rows = rast_param.rows
    #cols = rast_param.cols
    #xmin = rast_param.west
    #xmax = rast_param.east
    #ymin = rast_param.south
    #ymax = rast_param.north
    #xres = rast_param.nsres
    #yres = rast_param.ewres
    
    xmin = 750000
    xmax = 800000
    ymin = 6600000
    ymax = 6650000

    xres = 10
    yres = 10

    rows = (ymax-ymin)/xres
    cols = (xmax-xmin)/xres
 

    #---------------------------------------------------------#
    # 3. create an empty raster
    # Filename of the raster Tiff that will be created
    output_raster = 'temp_finland.tif' 

    # Create dataset: Create(name, resolution x, resolution y, bands, data type
    #driver = gdal.GetDriverByName('GTiff')
    #target_ds = driver.Create(output_raster, int(cols), int(rows), 1, gdal.GDT_Int16)

    # Projection
    #proj = osr.SpatialReference()
    #proj.SetUTM(33,1)
    #proj.SetWellKnownGeogCS("EPSG:25833")
    #target_ds.SetProjection(proj.ExportToWkt())

    # Transformation (top left x, w-e pixel resolution, rotation, top-left y, rotation, n-s pixel resolution)
    #target_ds.SetGeoTransform((int(xmin), int(xres), 0, int(ymax), 0, -int(yres)))

    # No data value
    #band = target_ds.GetRasterBand(1)
    #band.SetNoDataValue(-999)

    #---------------------------------------------------------#
    # 4. Rasterize
    # open dataset (GA_ReadOnly / GA_Update)
    #target_ds = gdal.Open( output_raster, GA_Update )

    #layerDefinition = source_layer.GetLayerDefn()
    #attribute = layerDefinition.GetFieldDefn(1).GetName()
    #print attribute

    #gdal.RasterizeLayer(target_ds, [1], source_layer, options=["ATTRIBUTE=%s" % (attribute)])

    #target_ds = None

    #---------------------------------------------------------#
    # 5. Link to GRASS
    r_land_cover = 'temp_norway@u_zofie.cimburova'
    #grass.run_command('r.external', overwrite=True, input='/data/home/zofie.cimburova/'+output_raster, output='temp_finland')
   


    #-------------------------------------------------------------------#
    #----------------------- EXTRACT FOREST LINE -----------------------#
    #-------------------------------------------------------------------#
    r_height = 'dem_10m_nosefi_float@PERMANENT'

    #---------------------------------------------------------#
    # exclude open areas which are below forest altitude
    
    # group conected pixels in open areas and calculate their standard deviation
    r_open_area_stdev = 'LC_open_stdev'
    #grass.run_command('r.clump', overwrite=True, input=r_land_cover, output=r_open_area_stdev)
     
    #grass.run_command('r.mapcalc', overwrite=True,\
    #                  expression=r_open_area_stdev+'=if('+r_land_cover+'==800,'+r_open_area_stdev+',null())')

    #grass.run_command('r.stats.zonal', overwrite=True,\
    #                                   base=r_open_area_stdev,\
    #                                   cover=r_height, method='stddev',
    #                                   output=r_open_area_stdev)
    

    #---------------------------------------------------------#
    # extract forest line based on rules
    r_forest_line = 'forest_line'
    #grass.run_command('r.mapcalc', overwrite=True, expression=r_forest_line+'=('+r_land_cover+'== 700) * (  \
    #                  (('+r_land_cover+'[-1,-1] == 800)*('+r_height+'[-1,-1] >= '+r_height+'[0,0])) + \
    #                  (('+r_land_cover+'[-1,0]  == 800)*('+r_height+'[-1,0]  >= '+r_height+'[0,0])) + \
    #                  (('+r_land_cover+'[-1,1]  == 800)*('+r_height+'[-1,1]  >= '+r_height+'[0,0])) + \
    #                  (('+r_land_cover+'[0,-1]  == 800)*('+r_height+'[0,-1]  >= '+r_height+'[0,0])) + \
    #                  (('+r_land_cover+'[0,1]   == 800)*('+r_height+'[0,1]   >= '+r_height+'[0,0])) + \
    #                  (('+r_land_cover+'[1,-1]  == 800)*('+r_height+'[1,-1]  >= '+r_height+'[0,0])) + \
    #                  (('+r_land_cover+'[1,0]   == 800)*('+r_height+'[1,0]   >= '+r_height+'[0,0])) + \
    #                  (('+r_land_cover+'[1,1]   == 800)*('+r_height+'[1,1]   >= '+r_height+'[0,0])))' \
    #                  )
    
    # reclass to null - 1
    #grass.run_command('r.mapcalc', overwrite=True, expression=r_forest_line+'=\
    #                  if('+r_forest_line+'>0,1,null())')


    #---------------------------------------------------------#
    # filter forest line
    # 1. take only DEM in forest
    r_height_10_forest = 'dem_10m_forest'
    #grass.run_command('r.mapcalc', overwrite = True, expression=r_height_10_forest+'= \
    #                  if('+r_land_cover+'==700,'+r_height+',null())')
    
    # 2. compute maximum (99% quantile) altitude in 25*10 m neighbourhood
    r_height_250_forest_max = 'dem_250m_forest_max'
    #grass.run_command('r.neighbors', overwrite = True, input=r_height_10_forest, \
    #                  selection=r_height_10_forest, output=r_height_250_forest_max, \
    #                  method='quantile', quantile=0.9, size=25)

    # 3. compute difference between pixel and maximum local altitude
    r_height_250_forest_diff = 'dem_250m_forest_diff'
    #grass.run_command('r.mapcalc', overwrite = True, expression=r_height_250_forest_diff+'= \
    #                  '+r_height_250_forest_max+'-'+r_height)





    #------------------------------------------------------#
    #----------------------- USEFUL -----------------------#
    #------------------------------------------------------#

    #--- import layers from PostGIS to GRASS
    #b = grass.parse_command('v.import', input='PG:dbname=gisdata', layer='zofie_cimburova.clip_finland_dense', output='juhuhu2', overwrite = 1)


    #v.import --o input='PG:dbname=gisdata' layer='zofie_cimburova.clip_finland_dense' output='juhuhu2'
    #--- layer info
    
    # get information about layer
    #print source_layer.GetName()


    #print "Name  -  Type  Width  Precision"
    
    #for i in range(layerDefinition.GetFieldCount()):
    #    fieldName =  layerDefinition.GetFieldDefn(i).GetName()
    #    fieldTypeCode = layerDefinition.GetFieldDefn(i).GetType()
    #    fieldType = layerDefinition.GetFieldDefn(i).GetFieldTypeName(fieldTypeCode)
    #    fieldWidth = layerDefinition.GetFieldDefn(i).GetWidth()
    #    GetPrecision = layerDefinition.GetFieldDefn(i).GetPrecision()

    #   print fieldName + " - " + fieldType+ " " + str(fieldWidth) + " " + str(GetPrecision)

    # get attribute ID_l1 of first 10 features
    #for i in range(0,10):
    #    feat = source_layer.GetFeature(i)
    #    print feat.GetFieldAsInteger (1)



  
if __name__ == '__main__':
    main()
