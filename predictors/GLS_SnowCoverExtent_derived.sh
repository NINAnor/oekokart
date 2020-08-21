#!/bin/bash

########################################################################
# Parameters that need adjustment if executed other places
dir=/mnt/ecofunc-data/source_data/GLS_SCE500_derived
grassdb=/mnt/ecofunc-data/grass
location=ETRS_33N
mapset="gt_Meteorology_Fenoscandia_SnowCoverExtent_GLS_derived"
memory=3000
cores=3

first_full_year=2018
current_year=$(date "+%Y")
t_where_full="start_time >= '${first_full_year}-01-01' AND end_time < '${current_year}-01-01 00:00:00'"

########################################################################
# Paramters that can be adjusted if prefered
mapset_in="g_Meteorology_Fenoscandia_SnowCoverExtent_GLS"
strds_in="GLS_Snow_Cover_Extent"
band_ref="pct"


strds_gapfilled_name="GLS_Snow_Cover_Extent_lwr"
strds_gapfilled_description="The 500m Snow Cover Extent (SCE) version 1 products, gapfilled using r.series.lwr, covering the Pan-European area and inherited from the EU FP7 project CryoLand project. Downloaded from https://land.copernicus.eu/global/products/sce"
strds_gapfilled_title="Snow Cover Extent from the Copernicus Global Land Service gapfilled using r.series.lwr"

strds_meltDOY_name="GLS_Snow_Cover_Spring_DOY"
strds_meltDOY_description="DOY before 01.Sept. where snow cover > 50% also the 4 previous days in GLS Snow Cover Extent data"
strds_meltDOY_title="DOY before 01.Sept. with continuous snow cover > 50%, also the 4 previous days, derived from the GLS Snow Cover Extent"

strds_melt_name="GLS_Snow_Melt"
strds_melt_description="Estimated date of Snow melt (last day with snow cover before 01.Sept.) from the GLS Snow Cover Extent from https://land.copernicus.eu/global/products/sce"
strds_melt_title="Snow Melt, derived from the GLS Snow Cover Extent"

strds_startDOY_name="GLS_Snow_Cover_Fall_DOY"
strds_startDOY_description="DOY after 01.Sept. where snow cover > 50% also the 4 following days in GLS Snow Cover Extent data"
strds_startDOY_title="DOY aster 01.Sept. with continuous snow cover > 50%, also the 4 following days, derived from the GLS Snow Cover Extent"

strds_start_name="GLS_Snow_Start"
strds_start_description="Estimated date for start of the snow season (first day with snow cover, also the 4 following days, after 01.Sept.) from the GLS Snow Cover Extent from https://land.copernicus.eu/global/products/sce"
strds_start_title="Snow Season start, derived from the GLS Snow Cover Extent"

strds_stability_day_name="GLS_Snow_Cover_Stability"
strds_stability_day_description="Number of days where snow cover is between 75 and 25% or crosses 25% threshold, derived from the GLS Snow Cover Extent from https://land.copernicus.eu/global/products/sce"
strds_stability_day_title="Snow Cover Stability, derived from the GLS Snow Cover Extent"

strds_average_name="GLS_Snow_Cover_Average"
strds_average_description="Average snow cover by year, derived from the GLS Snow Cover Extent from https://land.copernicus.eu/global/products/sce"
strds_average_title="Snow Cover average, derived from the GLS Snow Cover Extent"

output_end="GLS_Snow_Cover_average_melt_DOY"
output_start="GLS_Snow_Cover_average_start_DOY"
output_duration="GLS_Snow_Cover_average_duration"
output_stability="GLS_Snow_Cover_average_stability"
output_average="GLS_Snow_Cover_average_total"

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
#/usr/local/grass79/bin/r.series.lwr --verbose file=\"$reg_file\" order=0 range=0,100 maxgap=7
t.rast.list -u input=${strds_in}@${mapset_in} columns=name,start_time,end_time,band_reference --v --o | sed 's/V1_0_1/V1_0_1_lwr/g' | sed 's/None/cover_pct/g' > \"$reg_file\"
t.create --overwrite --verbose output=\"$strds_gapfilled_name\" semantictype=mean title=\"$strds_gapfilled_title\" description=\"$strds_gapfilled_description\"
t.register input=$strds_gapfilled_name file=\"$reg_file\"

# Snow Melt
t.rast.algebra expression=\"${strds_meltDOY_name}=if(start_month(${strds_gapfilled_name})<9, if(${strds_gapfilled_name}[-4] > 50 && ${strds_gapfilled_name}[-3] > 50 && ${strds_gapfilled_name}[-2] > 50 && ${strds_gapfilled_name}[-1] > 50 && ${strds_gapfilled_name} > 50, start_doy(${strds_gapfilled_name}, 0), 0))\" basename=${strds_meltDOY_name} suffix=gran nprocs=$cores
t.rast.aggregate input=${strds_meltDOY_name} output=${strds_melt_name} basename=${strds_melt_name} granularity=\"1 year\" method=maximum nprocs=$cores
t.rast.series --o --v input=$strds_melt_name output=$output_end

# Snow fall
t.rast.algebra expression=\"${strds_startDOY_name}=if(start_month(${strds_gapfilled_name})>=9, if(${strds_gapfilled_name}[4] > 50 && ${strds_gapfilled_name}[3] > 50 && ${strds_gapfilled_name}[2] > 50 && ${strds_gapfilled_name}[1] > 50 && ${strds_gapfilled_name} > 50, start_doy(${strds_gapfilled_name}, 0), 999))\" basename=${strds_startDOY_name} suffix=gran nprocs=$cores
t.rast.aggregate input=${strds_startDOY_name} output=${strds_start_name} basename=${strds_start_name} granularity=\"1 year\" method=minimum nprocs=$cores
t.rast.series --o --v input=$strds_start_name output=$output_start

# Snow stability
t.rast.algebra expression=\"${strds_stability_day_name}=if(${strds_gapfilled_name}[-1] > 25 && ${strds_gapfilled_name} < 25 || ${strds_gapfilled_name} > 25 && ${strds_gapfilled_name} < 75, 1, 0)\" basename=${strds_stability_day_name} suffix=gran nprocs=$cores
t.rast.aggregate where=\"${t_where_full}\" input=${strds_stability_day_name} output=${strds_stability_name} basename=${strds_stability_name} granularity=\"1 year\" method=sum nprocs=$cores
t.rast.series --o --v input=$strds_start_stability output=$output_stability

# Snow average
t.rast.aggregate where=\"${t_where_full}\" input=${strds_gapfilled_name} output=${strds_average_name} basename=${strds_average_name} granularity=\"1 year\" method=average nprocs=$cores
t.rast.series --o --v input=$strds_average_name output=$output_average

t.rast.list -u input=${strds_in}@${mapset_in} columns=name  where=\"start_time>=\"${t_where_full}\" --v --o > \"$reg_file\"
/usr/local/grass79/bin/r.seasons -b --overwrite --verbose file=\"$reg_file\" prefix=${seasons} n=1 nout=${seasons}_seasons_n max_length_core=${seasons}_core_season max_length_full=${seasons}_max_full_season_length threshold_value=50 min_length=30 max_gap=5

r.mapcalc --o --v expression=\"${output_duration}=${output_start}-${output_end}\"
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
