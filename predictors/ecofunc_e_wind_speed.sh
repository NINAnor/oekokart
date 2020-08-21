#!/bin/bash

########################################################################
# Parameters that need adjustment if executed other places
dir=/mnt/ecofunc-data/source_data/GLS_SCE500
grassdb=/mnt/ecofunc-data/grass
location=ETRS_33N
topic=Meteorology
extent=Fenoscandia
dataset=Wind_GlobalWindAtlas
mapset="g_${topic}_${extent}_${dataset}"
memory=3000
cores=3
target_resolution=150
########################################################################
# Paramters that can be adjusted if prefered
output_prefix="GlobalWindAtlas_"
output_suffix="${target_resolution}m_wind_speed_at_"

########################################################################
# Set to recreate=1 for updating instead of recreating
recreate=0

########################################################################
# From here, adjustment should not be necessary

runtime=$(date "+%Y%m%d_%H%M%S")

if [ ! -d "$dir" ] ; then
    mkdir "$dir"
fi

if [ ! -d "${dir}/logs" ] ; then
    mkdir "${dir}/logs"
fi

cd "$dir"

if [ ! -d "${grassdb}/${location}/${mapset}" ] ; then
    grass -c -e "${grassdb}/${location}/${mapset}"
fi


for height in 10 50 100 150 200
do
    for cnt in NOR SWE FIN
    do
        redirect=$(curl https://globalwindatlas.info/api/gis/country/${cnt}/wind-speed/${height} | sed 's/Found. Redirecting to //g')
        curl -O "$redirect"
    done


    gdalbuildvrt wind-speed_${height}m.vrt ./*${height}m.tif

    grass "${grassdb}/${location}/${mapset}" --exec g.region -g raster=dem_10m_nosefi@g_Elevation_Fenoscandia res=150 n=n+140 e=e+130
    grass "${grassdb}/${location}/${mapset}" --exec r.import --o --v resample=lanczos_f input="${dir}/wind-speed_${height}m.vrt" output="${output_prefix}${output_suffix}${height}m" extent=region memory=$memory
done

#wget -m https://cidportal.jrc.ec.europa.eu/ftp/jrc-opendata/MAPPE/MAPPE_Europe/LATEST/Atmosphere/D_11_wind_speed/D_11_wind_speed.zip
#unzip D_11_wind_speed.zip


