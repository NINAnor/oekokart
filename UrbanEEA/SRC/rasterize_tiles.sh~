#!/bin/bash

#Run this script with:"bash rasterize_tiles.sh  &> tile_list.txt"

# rasterize land cover tiles (only forest / open land due to speed)

STARTx=148350
ENDx=363720

STARTy=6519850
ENDy=6795710

#STARTx=231932
#ENDx=241932

#STARTy=6977798
#ENDy=6987798

for ((x=STARTx; x<=ENDx; x=x+20000))
do
	for ((y=STARTy; y<=ENDy; y=y+20000))
	do
		let "i=i+1"
		let "xmin=x"
		let "ymin=y"
		let "xmax=x+20000"
		let "ymax=y+20000"
		echo ar5_tile_$i.tif
		echo $xmin
		echo $ymin
		echo $xmax
		echo $ymax

		# rasterize tile
		gdal_rasterize  -a lc1 -sql "SELECT * FROM zofie_cimburova.landcover_nosefi_78 WHERE geom && ST_MakeEnvelope("$xmin", "$ymin", "$xmax", "$ymax", 25833)" -a_nodata -999999 -te $xmin $ymin $xmax $ymax -tr 10 10 -ot UInt8 -q PG:'dbname=gisdata' LC_tile_$i.tif
	done
done

# build mosaic
#gdalbuildvrt -input_file_list tile_list.txt LC_mosaic.vrt

