#!/bin/bash

########################################################################
# Parameters that need adjustment if executed other places
dir=/mnt/ecofunc-data/source_data/GLS_SCE500_derived
grassdb=/mnt/ecofunc-data/grass
location=ETRS_33N
mapset="gt_Meteorology_Fenoscandia_SnowMelt_GLS"
memory=3000
cores=3

########################################################################
# Paramters that can be adjusted if prefered
mapset_in="g_Meteorology_Fenoscandia_SnowCoverExtent_GLS"
strds_in="GLS_Snow_Cover_Extent"
band_ref="pct"


strds_gapfilled_name="GLS_Snow_Cover_Extent_lwr"
strds_gapfilled_description="The 500m Snow Cover Extent (SCE) version 1 products, gapfilled using r.series.lwr, covering the Pan-European area and inherited from the EU FP7 project CryoLand project. Downloaded from https://land.copernicus.eu/global/products/sce"
strds_gapfilled_title="Snow Cover Extent from the Copernicus Global Land Service gapfilled using r.series.lwr"

strds_meltDOY_name="GLS_Snow_Cover_doy"
strds_gapfilled_description="DOY where snow cover > 50% also the 4 previous days in GLS Snow Cover Extent data"
strds_gapfilled_title="DOY with continuous snow cover > 50%, derived from the GLS Snow Cover Extent"

strds_name="GLS_Snow_Melt"
strds_description="Estimated date of Snow melt (last day with snow cover before 01.Sept.) from the GLS Snow Cover Extent from https://land.copernicus.eu/global/products/sce"
strds_title="Snow Melt, derived from the GLS Snow Cover Extent"

output="GLS_Snow_Cover_average_melt_doy"

seasons="GLS_Snow_Cover_seasons"


########################################################################
# Set to recreate=1 for updating instead of recreating
recreate=0
aggregate_script=${dir}/gtaggregate.sh
reg_file=${dir}/treg.txt

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

# Create import script
echo "#\!/bin/bash

if [ -f \"$reg_file\" ] ; then
    rm \"$reg_file\"
fi

g.region -g raster=dem_10m_nosefi@g_Elevation_Fenoscandia res=150 n=n+140 e=e+130

# Connect to temporal database if connection is not set
t.connect -c

if [ $recreate -eq 1 ] ; then
t.remove -f $strds_name
fi

g.mapsets operation=add mapset=$mapset_in

t.rast.list -u input=${strds_in}@${mapset_in} columns=name --v --o > \"$reg_file\"
/usr/local/grass79/bin/r.series.lwr --verbose file=\"$reg_file\" order=0 range=0,100 maxgap=7
t.rast.list -u input=${strds_in}@${mapset_in} columns=name,start_time,end_time,band_reference --v --o | sed 's/V1_0_1/V1_0_1_lwr/g' | sed 's/None/cover_pct/g' > \"$reg_file\"
t.create --overwrite --verbose output=\"$strds_gapfilled_name\" semantictype=mean title=\"$strds_gapfilled_title\" description=\"$strds_gapfilled_description\"
t.register input=$strds_gapfilled_name file=\"$reg_file\"

t.rast.algebra expression=\"${strds_meltDOY_name}=if(start_month(${strds_gapfilled_name})<9, if(${strds_gapfilled_name}[-4] > 50 && ${strds_gapfilled_name}[-3] > 50 && ${strds_gapfilled_name}[-2] > 50 && ${strds_gapfilled_name}[-1] > 10 && ${strds_gapfilled_name} > 50, start_doy(${strds_gapfilled_name}, 0), 0))\" basename=${strds_gapfilled_name} suffix=gran nprocs=$cores

t.rast.aggregate input=${strds_meltDOY_name} output=${strds_name} basename=${strds_name} granularity=\"1 year\" method=maximum nprocs=$cores

t.rast.series --o --v input=$strds_name output=$output

t.rast.list -u input=${strds_in}@${mapset_in} columns=name  where=\"start_time>='2018-01-01' AND start_time<'2020-01-01'\" --v --o > \"$reg_file\"
/usr/local/grass79/bin/r.seasons --overwrite --verbose file=\"$reg_file\" prefix=${seasons} n=5 nout=${seasons}_seasons_n max_length_core=${seasons}_core_season max_length_full=${seasons}_max_full_season_length threshold_value=50 min_length=5 max_gap=10

" > "$aggregate_script"

# Set and run GRASS batch job
chmod u+x "$aggregate_script"
export GRASS_BATCH_JOB="$aggregate_script"

time /mnt/ecofunc-data/code/grass_ninsbl/bin.x86_64-pc-linux-gnu/grass79 -f "${grassdb}/${location}/${mapset}" &> "${dir}/logs/run_${runtime}.log"

# Unset batch jobs
unset GRASS_BATCH_JOB

# Remove import script
rm -f "$aggregate_script"
rm -f "$reg_file"
