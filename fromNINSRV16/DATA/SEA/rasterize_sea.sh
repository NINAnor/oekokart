#Run this script with:"bash rasterize_sea.sh  &> rasterize_sea.log"


# rasterize sea 
gdal_rasterize -burn 1 -l zofie_cimburova.sea_nosefi_singlepart -a_nodata -999999 -te -87345 6122465 1835785 7950005 -tr 10 10 -ot Byte PG:'dbname=gisdata' sea.tif




