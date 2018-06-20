#Run this script with:"bash rasterize_water.sh  &> rasterize_water.log"


# rasterize water areas 
gdal_rasterize -burn 1 -sql "SELECT * FROM zofie_cimburova.landcover_nosefi WHERE \"ID_l1\"=12" -a_nodata -999999 -te -77335 6132475 1335785 7939995 -tr 10 10 -ot Byte PG:'dbname=gisdata' water.tif
