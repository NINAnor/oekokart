#!/bin/bash

########################################################################
# Parameters that need adjustment if executed other places
dir=/mnt/ecofunc-data/source_data/GLS_SCE500
grassdb=/mnt/ecofunc-data/grass
location=ETRS_33N
mapset="g_Meteorology_Fenoscandia_SnowCoverExtent_GLS"
memory=3000
cores=3

# Add credentials for ftp.globalland.cls.fr to ~/.netrc if both variables are set
# Single quotes needed to mask special characters
login=''
password=''

if [ "$login" -a "$password" ] ; then
    echo "machine ftp.globalland.cls.fr
login $login
password $password" >> ~/.netrc
fi

########################################################################
# Paramters that can be adjusted if prefered
strds_name="GLS_Snow_Cover_Extent"
strds_description="The 500m Snow Cover Extent (SCE) version 1 products, covering the Pan-European area and inherited from the EU FP7 project CryoLand project. Downloaded from https://land.copernicus.eu/global/products/sce"
strds_title="Snow Cover Extent from the Copernicus Global Land Service"
band_ref="pct"

########################################################################
# Set to recreate=1 for updating instead of recreating
recreate=0

########################################################################
# From here, adjustment should not be necessary

# Define temporary files
reg_file=treg.txt
import_script=${dir}/gimport.sh

runtime=$(date "+%Y%m%d_%H%M%S")

if [ ! -d "$dir" ] ; then
    mkdir "$dir"
fi

if [ ! -d "${dir}/logs" ] ; then
    mkdir "${dir}/logs"
fi

cd "$dir"

time wget -m ftp://ftp.globalland.cls.fr/Core/CRYOSPHERE/dataset-fmi-sce-paneu-500m/ -o downloaded.txt

if [ ! -d "${grassdb}/${location}/${mapset}" ] ; then
    grass -c -e "${grassdb}/${location}/${mapset}"
fi

# Create import script
echo "#\!/bin/bash
if [ $recreate -ne 1 ] ; then
    files=\$(cat downloaded.txt | grep saved | awk -F \"‘\" '{print \"./\"\$2}' | awk -F \"’\" '{print \$1}' | grep \".nc\$\" | sort)
else
    files=\$(find ./ -iname *.nc | sort)
fi

if [ -f \"$reg_file\" ] ; then
    rm \"$reg_file\"
fi

eval \`g.region -g raster=dem_10m_nosefi@g_Elevation_Fenoscandia res=150 n=n+140 e=e+130\`

g.region -up

echo \$files
# Import to GRASS
for file in \$files
do

# Reproject relevant area with over-resampling
echo \"Reprojecting $file\"
echo gdalwarp -ot Byte -t_srs EPSG:25833 -te \$w \$s \$e \$n -tr 150 150 -wm $memory -multi -co COMPRESS=LZW -overwrite -wo NUM_THREADS=$cores \$file ./tmp.tif
gdalwarp -ot Byte -t_srs EPSG:25833 -te \$w \$s \$e \$n -tr 150 150 -wm $memory -multi -co COMPRESS=LZW -overwrite -wo NUM_THREADS=$cores \$file ./tmp.tif

# Get relevant metainformation
file_name=\$(basename -s .nc \"\$file\")
date=\$(echo \"\$file\" | cut -f4 -d'_' | cut -c1-8)
year=\$(echo \"\$date\" | cut -c1-4)
month=\$(echo \"\$date\" | cut -c5-6)
day=\$(echo \"\$date\" | cut -c7-8)
name=\$(echo \"\$file_name\" | sed 's/^c_//' | sed 's/\.nc//' | tr '.' '_')
start_day=\$(date '+%Y-%m-%d' -d \"\${year}-\${month}-\${day}\")
end_day=\$(date '+%Y-%m-%d' -d \"\${year}-\${month}-\${day} +1 days\")

# Link reprojected temporary file
r.external input=tmp.tif output=tmp --o --v

echo Applying Nodata, Offset and smoothing
# Apply NoData and Offset
r.mapcalc expression=\"\$name=if(tmp<100||tmp>200,null(), \
int(round((((tmp[1,1]+tmp[-1,1]+tmp[-1,-1]+tmp[1,-1])/4.0)*(1/sqrt(\${nsres}*\${ewres}))+ \
((tmp[0,1]+tmp[0,-1])/2.0)*1.0/\${ewres}+ \
((tmp[-1,0]+tmp[1,0])/2.0)*1.0/\${ewres}+ \
tmp)/((1.0/sqrt(\${nsres}*\${ewres}))+(1.0/\${ewres})+(1.0/\${ewres})+1.0))-100))\" --o

echo \"\${name}|\${start_day} 00:00:00|\${end_day} 00:00:00|${band_ref}\" >> \"$reg_file\"

rm -f ./tmp.tif
g.remove type=raster name=tmp -f
done

# Connect to temporal database if connection is not set
t.connect -c

if [ $recreate -eq 1 ] ; then
t.remove -f $strds_name
fi

# Create STRDS if it does not exist
if [ \$(t.list where=\"name='${strds_name}'\" columns=name  | wc -l) -lt 1 -o $recreate -eq 1 ] ; then
    t.create --overwrite --verbose output=\"$strds_name\" semantictype=mean title=\"$strds_title\" description=\"$strds_description\"
fi



# Register imported maps in STRDS
tmpfile=\$(g.tempfile -d pid=\$\$)
sort $reg_file > \$tmpfile
mv \$tmpfile $reg_file
t.register input=$strds_name file=$reg_file
" > "$import_script"

# Set and run GRASS batch job
chmod u+x "$import_script"
export GRASS_BATCH_JOB="$import_script"

time grass -f "${grassdb}/${location}/${mapset}" &> "${dir}/logs/run_${runtime}.log"

# Unset batch jobs
unset GRASS_BATCH_JOB

# Remove import script
rm -f "$import_script"
rm -f "$reg_file"
