#!/bin/bash

#Run this script with:"bash rasterize.sh"

# rasterize shapefile

# gdal_rasterize -a ATTRIBUTE_NAME -a_nodata NODATA_VALUE -te xmin ymin xmax ymax -tr RESOLUTION_X RESOLUTION_Y -ot DATA_FORMAT -l SHAPEFILE_WITHOUT_SHP SHAPEFILE_WITH_SHP OUT_NAME.tif
gdal_rasterize  -a LC_TYPE -a_nodata -999999 -te 148350 6519850 363720 6795710 -tr 10 10 -ot UInt32 -l fkb_ar5_oslo_kommuner_avgrensing fkb_ar5_oslo_kommuner_avgrensing.shp fkb_ar5.tif

