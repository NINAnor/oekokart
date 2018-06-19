############################################################################################################
#ToDo:
#- prepare temperatur data (met.no) (data downloaded, next steps):
#	-- Double check temperature (feb vs. jun)
#	-- calculate remaining climate parameters (droughts, spring variation in temperature (melting/freezing))
#	-- remove datapoints with insufficient coverage (MASK out)
#- Check februar temperature
#
#Group dataset by temp
#
#Model validation
#Homogenity: plot residuals vs. fittet values (plus bartlet test)
#Normality: Histogram of residuals
#Independence: residuals vs. each explanatory variable
#
#cor(explanatory_variables)
#
###Try GLS instead of GLM
##GLS (decresing residuals with increasing distance from coast)
############################################################################################################

############################################################################################################
############################################################################################################
###Prepare input data
############################################################################################################
############################################################################################################


############################################################################################################
###Terrain data
##Get DEM with 10m resolution:
#Create VRT-raster for Terrain WCS from Kartverket
echo "<WCS_GDAL>
 <ServiceURL>http://wcs.geonorge.no/skwms1/wcs.dtm?</ServiceURL>
 <CoverageName>land_utm33_10m</CoverageName>
</WCS_GDAL>" > dem_10m_33n.vrt

#Download DEM from WCS
gdal_translate -co "COMPRESS=LZW" -srcwin 0 0 125041 15504 dem_10m_33n.vrt dem_10m_0.tif
gdal_translate -co "COMPRESS=LZW" -srcwin 0 15504 125041 15504 dem_10m_33n.vrt dem_10m_1.tif
gdal_translate -co "COMPRESS=LZW" -srcwin 0 31008 125041 15504 dem_10m_33n.vrt dem_10m_2.tif
gdal_translate -co "COMPRESS=LZW" -srcwin 0 46512 125041 15504 dem_10m_33n.vrt dem_10m_3.tif
gdal_translate -co "COMPRESS=LZW" -srcwin 0 62016 125041 15504 dem_10m_33n.vrt dem_10m_4.tif
gdal_translate -co "COMPRESS=LZW" -srcwin 0 77520 125041 15504 dem_10m_33n.vrt dem_10m_5.tif
gdal_translate -co "COMPRESS=LZW" -srcwin 0 93024 125041 15504 dem_10m_33n.vrt dem_10m_6.tif
gdal_translate -co "COMPRESS=LZW" -srcwin 0 108528 125041 15504 dem_10m_33n.vrt dem_10m_7.tif
gdal_translate -co "COMPRESS=LZW" -srcwin 0 124032 125041 15504 dem_10m_33n.vrt dem_10m_8.tif
gdal_translate -co "COMPRESS=LZW" -srcwin 0 139536 125041 15505 dem_10m_33n.vrt dem_10m_9.tif

#Mosaic tiles to VRT
gdalbuildvrt dem_10m_2013_kartverket.vrt ./dem_10m_*.tif
r.in.gdal input=dem_10m_2013_kartverket.vrt output=DEM_10m_2013_kartverket -o --v

#Set region according to terrain model
g.region -p rast=DEM_10m align=DEM_10m

#Calculate Terrain Position Index (TPI)
r.neighbors
r.neighbors
r.neighbors
r.neighbors
r.neighbors
r.neighbors

g.region -p rast=DEM_10m res=100 n=n+20
r.resamp.stats --o input=DEM_10m_2013_kartverket output=DEM_2013_kartverket_100m_avg method=average
r.neighbors -c input=DEM_2013_kartverket_100m_avg output=DEM_2013_kartverket_1100m_avg method=average size=11 --o --v
r.mapcalc --o expression="DEM_10m_TPI_1100m=DEM_2013_kartverket_100m_avg-DEM_2013_kartverket_1100m_avg"
r.neighbors -c input=DEM_2013_kartverket_100m_avg output=DEM_2013_kartverket_3100m_avg method=average size=31 --o --v
r.mapcalc --o expression="DEM_10m_TPI_3100m=DEM_2013_kartverket_100m_avg-DEM_2013_kartverket_3100m_avg"
r.neighbors -c input=DEM_2013_kartverket_100m_avg output=DEM_2013_kartverket_5100m_avg method=average size=51 --o --v
r.mapcalc --o expression="DEM_10m_TPI_5100m=DEM_2013_kartverket_100m_avg-DEM_2013_kartverket_5100m_avg"

r.neighbors -c input=DEM_10m_TPI_1100m output=DEM_10m_TPI_1100m_stddev method=stddev size=11 --o --v
r.neighbors -c input=DEM_10m_TPI_3100m output=DEM_10m_TPI_3100m_stddev method=stddev size=31 --o --v
r.neighbors -c input=DEM_10m_TPI_5100m output=DEM_10m_TPI_5100m_stddev method=stddev size=51 --o --v

g.region -p rast=DEM_10m align=DEM_10m
#Create slope and aspect map
r.slope.aspect --o elevation=DEM_10m_2013_kartverket slope=DEM_10m_slope aspect=DEM_10m_aspect precision=CELL
r.param.scale --o input=DEM_10m_2013_kartverket output=DEM_10m_slope_5 size=5 param=slope
r.param.scale --o input=DEM_10m_2013_kartverket output=DEM_10m_aspect_5 size=5 param=aspect
r.mapcalc --o expression="DEM_10m_slope_next_aapent=if(isnull(N50_2013_aapent_omraade)&&N50_2013_skog,nmin(if(N50_2013_aapent_omraade[-1,0],if((DEM_10m_2013_kartverket-DEM_10m_2013_kartverket[-1,0])<0,DEM_10m_2013_kartverket[-1,0]-DEM_10m_2013_kartverket,9999)),if(N50_2013_aapent_omraade[0,1],if((DEM_10m_2013_kartverket-DEM_10m_2013_kartverket[0,1])<0,DEM_10m_2013_kartverket[0,1]-DEM_10m_2013_kartverket,9999)),if(N50_2013_aapent_omraade[1,0],if((DEM_10m_2013_kartverket-DEM_10m_2013_kartverket[1,0])<0,DEM_10m_2013_kartverket[1,0]-DEM_10m_2013_kartverket,9999)),if(N50_2013_aapent_omraade[0,-1],if((DEM_10m_2013_kartverket-DEM_10m_2013_kartverket[0,-1])<0,DEM_10m_2013_kartverket[0,-1]-DEM_10m_2013_kartverket,9999))),null())" --o
r.null map=DEM_10m_slope_next_aapent setnull=9999

g.region -p rast=temperature_mean_1957_2012_tetraterm_total_mean@PERMANENT align=temperature_mean_1957_2012_tetraterm_total_mean@PERMANENT
r.resamp.stats --o input=DEM_10m_2013_kartverket output=DEM_2013_kartverket_1km_avg method=average -w


###temp. here:

g.region -p rast=DEM_10m align=DEM_10m
r.out.maxent_swd bgr_mask=N50_2013_skog_aapent_filter_50m alias_input=/home/stefan/Okokart/alias.csv bgr_output=/home/stefan/Okokart/skgr.csv -z --v

##############################################################
###Get N50 kartdata in SOSI format from Norge digitalt (has to be downloaded manually)
#Load SOSI-files for municipalities into PostGIS database
N50_ogr.sh script here
#Import data from PostGIS to GRASS and build GRASS topology 
v.in.ogr
v.in.ogr

#Import maritim borders
ogr2ogr -t_srs "EPSG:32633" /home/stefan/Okokart/ADM_maritim_versjon_2012-1_linje_utm33n.shp /home/stefan/Avd15GIS_Ressurser/Norge/Maritime_Grenser/ADM_maritim_versjon_2012-1_linje.shp
v.in.ogr dsn=/home/stefan/Okokart/ADM_maritim_versjon_2012-1_linje_utm33n.shp output=grunnlinje_pluss_1nm_2012 where="NAVN='1 nautisk mil'" encoding=latin4 -w --v --o
v.in.ogr dsn=/home/stefan/Okokart/ADM_maritim_versjon_2012-1_linje_utm33n.shp output=ADM_maritim_versjon_2012_1_linje type=boundary encoding=latin4 -w --v --o
v.centroids --overwrite --verbose input=ADM_maritim_versjon_2012_1_linje output=ADM_maritim_versjon_2012_1_flate
v.edit --verbose map=ADM_maritim_versjon_2012_1_flate_yttre_hav tool=snap thresh=-1,50,0 ids=0-99999999999999999 bgmap=N50_2013_hav@Oekokart snap=vertex
v.extract -d -t --overwrite --verbose input=ADM_maritim_versjon_2012_1_flate type=centroid,area cats="124,125,126,128,129,376,423" output=ADM_maritim_versjon_2012_1_flate_yttre_hav new=1

##############################################################
###Get klimate data from met.no
klimagrid.sh here
#Create space-time dataset with daily temperature maps from met.no (Note: Temperature is in 10th degree Kalvin, conversion to celsius would be: y =(x/10.0)-273.15)

#Set region according to climate grids (1km)
####

g.region

####


t.connect -d
g.region -p rast=tm_1957_01_01 align=tm_1957_01_01 save=tm
t.create --o type=strds temporaltype=absolute output=temperature_met_no title="Daily temperature" descr="Daily temperature raw met.no data"
g.list type=rast mapset=. | tr ' ' '\n' | grep tm | sort | awk '{split($0,a,"_");print $0, a[2] "-" a[3] "-" a[4]}' > ./ts_datasets_tm.txt
t.register input=temperature_met_no file=./ts_datasets_tm.txt separator=' '
#Aggregate Daily temperature data to average tri- and tetraterm temperature for each year, 10 years (1960 - 2010), 30 years (1960 - 1990), and total
t.rast.aggregate input=temperature_met_no method=average output=temperature_mean_1957_2012_triterm base=temperature_mean_triterm granularity="1 years" where="strftime('%m', start_time) >= strftime('%m', '2013-06-01') and strftime('%m', start_time) < strftime('%m', '2013-09-01')" --o
t.rast.aggregate input=temperature_met_no method=average output=temperature_mean_1957_2012_tetraterm base=temperature_mean_tetraterm granularity="1 years" where="strftime('%m', start_time) >= strftime('%m', '2013-06-01') and strftime('%m', start_time) < strftime('%m', '2013-10-01')" --o
t.rast.aggregate input=temperature_mean_1957_2012_triterm method=average output=temperature_mean_1957_2012_triterm_10years base=temperature_mean_triterm_10years granularity="10 years" where="start_time >= '1960-01-01'" --o
t.rast.aggregate input=temperature_mean_1957_2012_tetraterm method=average output=temperature_mean_1957_2012_tetraterm_10years base=temperature_mean_tetraterm_10years granularity="10 years" where="start_time >= '1960-01-01'" --o
t.rast.series input=temperature_mean_1957_2012_triterm output=temperature_mean_1960_1990_triterm where="start_time >= '1960-01-01' AND start_time < '1991-01-01'" method="average" --o
t.rast.series input=temperature_mean_1957_2012_tetraterm output=temperature_mean_1960_1990_tetraterm where="start_time >= '1960-01-01' AND start_time < '1991-01-01'" method="average" --o
t.rast.series input=temperature_mean_1957_2012_triterm output=temperature_mean_1957_2012_triterm_total_mean method="average" --o
t.rast.series input=temperature_mean_1957_2012_tetraterm output=temperature_mean_1957_2012_tetraterm_total_mean method="average" --o
#Aggregate Daily temperature data to average february temperature for each year, 10 years and total
t.rast.aggregate input=temperature_met_no method=average output=temperature_mean_1957_2012_februar base=temperature_mean_februar granularity="1 years" where="strftime('%m', start_time) >= strftime('%m', '2013-02-01') and strftime('%m', start_time) < strftime('%m', '2013-03-01')" --o
t.rast.aggregate input=temperature_mean_1957_2012_februar method=average output=temperature_mean_1957_2012_februar_10years base=temperature_mean_februar_10years granularity="10 years" where="start_time >= '1960-01-01'" --o
t.rast.series input=temperature_mean_1957_2012_februar output=temperature_mean_1960_1990_februar where="start_time >= '1960-01-01' AND start_time < '1991-01-01'" method="average" --o
t.rast.series input=temperature_mean_1957_2012_februar output=temperature_mean_1957_2012_februar_total_mean method="average" --o

############################
#Calculate growing degree days at a base of 0 degree
t.rast.mapcalc input=temperature_met_no output=temperature_met_no_GDD_daily base=temperature_met_no_GDD_daily_base_0 method=equal expr="if((temperature_met_no/10.0)<=273.15,0,1)" nprocs=5 --o
t.rast.aggregate input=temperature_met_no_GDD_daily method=sum output=temperature_met_no_AGDD_base_0 base=temperature_met_no_AGDD_base_0 granularity="1 years" --o
t.rast.aggregate input=temperature_met_no_AGDD_base_0 method=average output=temperature_met_no_AGDD_base_0_10years base=temperature_met_no_AGDD_base_0_10years granularity="10 years" where="start_time >= '1960-01-01'" --o
t.rast.series input=temperature_met_no_AGDD_base_0 output=temperature_met_no_1960_1990_AGDD_base_0 where="start_time >= '1960-01-01' AND start_time < '1991-01-01'" method="average" --o
t.rast.series input=temperature_met_no_AGDD_base_0 output=temperature_met_no_AGDD_base_0_total_mean method="average" --o
###########################

####Calculate temperature variation in spring (melt-freez-events)
#t.rast.mapcalc if((this_day10.0>271.15 AND this_day10.0<275.15) OR ((this_day/10.0<273.15 AND next_day/10.0>273.15) OR (this_day/10.0>273.15 AND next_day<273.15)),1,0)
#t.rast.aggregate input=temperature_met_no_GDD_daily method=sum output=temperature_met_no_AGDD_base_0 base=temperature_met_no_AGDD_base_0 granularity="1 years" --o
#t.rast.aggregate input=temperature_met_no_AGDD_base_0 method=average output=temperature_met_no_AGDD_base_0_10years base=temperature_met_no_AGDD_base_0_10years granularity="10 years" where="start_time >= '1960-01-01'" --o
#t.rast.series input=temperature_met_no_AGDD_base_0 output=temperature_met_no_1960_1990_AGDD_base_0 where="start_time >= '1960-01-01' AND start_time < '1991-01-01'" method="average" --o
#t.rast.series input=temperature_met_no_AGDD_base_0 output=temperature_met_no_AGDD_base_0_total_mean method="average" --o

t.remove
g.mremove

#Calculate droughts




###########################
###Probably irrelevant
t.rast.series input=temperature_mean_1957_2012_triterm output=temperature_mean_1957_2012_triterm_total_slope method="slope" --o
t.rast.series input=temperature_mean_1957_2012_tetraterm output=temperature_mean_1957_2012_tetraterm_total_slope method="slope" --o
t.rast.series input=temperature_mean_1957_2012_triterm output=temperature_mean_1957_2012_triterm_total_stddev method="stddev" --o
t.rast.series input=temperature_mean_1957_2012_tetraterm output=temperature_mean_1957_2012_tetraterm_total_stddev method="stddev" --o
###########################


##############################################################
###Get data on geology (NGU)
#Set region according to Terrain model (10m)
g.region -p rast=DEM_10m align=DEM_10m

#Import data on bedrock geology
v.in.ogr
#Add numeric columns for (geological) nutrition richness
echo "ALTER TABLE bergrunnsgeologi_rikhet ADD COLUMN rihet_ID INTEGER;" | db.execute inptu=-
echo "UPDATE bergrunnsgeologi_rikhet set rihet_ID=CASE WHEN RIKHET='Rik' THEN 3 WHEN RIKHET='Middels' THEN 2 ELSE 1 END;" | db.execute inptu=-
#Rasterize bedrock type and nutrition richness
v.to.rast use=attr attrcolumn=rihet_ID input=bergrunnsgeologi_rikhet output=bergrunnsgeologi_rikhet type=area
v.to.rast use=attr attrcolumn=HBERGKODE input=bergrunnsgeologi_rikhet output=bergrunnsgeologi_type type=area
r.grow.distance input=bergrunnsgeologi_rikhet value=bergrunnsgeologi_rikhet_fill
#Import data on quarternary geology
v.in.ogr
#Rasterize quarternary geology type, infiltration potential, and groundwater potential
v.to.rast use=attr attrcolumn=JORDART input=Loesmasse output=loesmasse_jordart type=area
v.to.rast use=attr attrcolumn=INFILT input=Loesmasse output=loesmasse_infilt type=area
v.to.rast use=attr attrcolumn=GRUNNVANN input=Loesmasse output=loesmasse_grunnvann type=area
r.grow.distance input=loesmasse_grunnvann value=loesmasse_grunnvann_fill


###########################
###Probably irrelevant
#Analyse topology of N50 kartdata in order to identify neighboring landcover types (borders between them)
v.category --overwrite --verbose input=N50_2013_arealdekke_pol output=N50_2013_arealdekke_pol_boundary type=boundary layer=2 option=add
v.db.addtable --verbose map=N50_2013_arealdekke_pol_boundary table=N50_2013_arealdekke_pol_boundary_l2 layer=2 columns="cat integer, left integer, right integer, left_type varchar(25), right_type varchar(25)"
v.to.db --verbose map=N50_2013_arealdekke_pol_boundary layer=2 option=sides columns="left,right"
echo 'UPDATE N50_2013_arealdekke_pol_boundary_l2 SET left_type=(SELECT objtype FROM N50_2013_arealdekke_pol_boundary WHERE N50_2013_arealdekke_pol_boundary.cat = N50_2013_arealdekke_pol_boundary_l2.left); \
UPDATE N50_2013_arealdekke_pol_boundary_l2 SET right_type=(SELECT objtype FROM N50_2013_arealdekke_pol_boundary WHERE N50_2013_arealdekke_pol_boundary.cat = N50_2013_arealdekke_pol_boundary_l2.right);' | db.execute input=-
###########################

#Define region for raster analysis with 10m resolution
g.region -p rast=DEM_10m align=DEM_10m
#Rasterize forest with 10m resolution
v.to.rast use=val val=1 input=N50_2013_arealdekke_pol output=N50_2013_skog where="objtype='Skog'" type=area
#Rasterize open areas with 10m resolution
v.to.rast use=val val=1 input=N50_2013_arealdekke_pol output=N50_2013_aapent_omraade where="objtype='ÅpentOmråde'" type=area
#Patch rastermaps with forest and open areas
r.mapcalc expression="N50_2013_skog_og_aapent_omraade=if(isnull(N50_2013_skog),if(isnull(N50_2013_aapent_omraade),0,if(N50_2013_aapent_omraade==1,2,null())),N50_2013_skog)"

#Create raster layer with data-actuality
v.db.addcolumn map=N50_2013_arealdekke_pol column="ajour integer"
echo " UPDATE N50_2013_arealdekke_pol SET ajour=CAST(substr(CAST(oppd_dato AS text),1,4) AS INTEGER);" | db.execute inptu=-
#UPDATE N50_2013_arealdekke_pol SET ajour=CASE WHEN year(oppdaterin)!=0 THEN CAST(year(oppdaterin) AS integer) WHEN year(oppdaterin)=0 THEN CAST(year(datafangst) AS integer) ELSE NULL END;" | db.execute inptu=-
v.to.rast use=attr attrcolumn=ajour input=N50_2013_arealdekke_pol output=N50_2013_arealdekke_pol_ajour type=area

echo "ALTER TABLE N50_2013_arealdekke_lin ADD COLUMN ajour integer;
UPDATE N50_2013_arealdekke_lin SET ajour=CASE WHEN CAST(substr(CAST(oppd_dato AS text),1,4) AS INTEGER) > 1000 THEN CAST(substr(CAST(oppd_dato AS text),1,4) AS INTEGER) ELSE CAST(substr(CAST(dataf_dato AS text),1,4) AS INTEGER) END;" | db.execute inptu=-
v.to.rast use=attr attrcolumn=ajour input=N50_2013_arealdekke_lin output=N50_2013_arealdekke_lin_ajour type=line where="objtype='Arealbrukgrense'"
r.neighbors --verbose input=N50_2013_arealdekke_lin_ajour output=N50_2013_arealdekke_lin_ajour_max_3 method=maximum

#############################################################################################
v.to.rast use=val val=1 input=N50_2013_arealdekke_pol output=N50_2013_land where="objtype!='Havflate'" type=area
v.to.rast use=val val=1 input=N50_2013_arealdekke_pol output=N50_2013_norge type=area
r.stats input=N50_2013_norge -gn separator=" " | m.proj -oed separator=" " | cut -f1-4 -d' ' > /home/stefan/Okokart/latlon.tmp
r.in.xyz input=/home/stefan/Okokart/latlon.tmp output=lat type=DCELL separator=" " x=1 y=2 z=3 method=mean percent=5 -i
r.in.xyz input=/home/stefan/Okokart/latlon.tmp output=lon type=DCELL separator=" " x=1 y=2 z=4 method=mean percent=5 -i

#############################################################################################
###Measure distance from open ocean
##Rasterize ocean with 10m resolution and measure distance from open ocean areas (>1000m from the coast)
#Rasterize ocean with 10m resolution
v.to.rast use=val val=1 input=N50_2013_arealdekke_pol output=N50_2013_hav where="objtype='Havflate'" type=area
#Measure distance from coast line to land
r.grow.distance --overwrite input=N50_2013_hav_inv distance=N50_2013_kystlinje_dist metric=euclidean
#Identify land areas (invert ocean)  
r.mapcalc expression="N50_2013_hav_inv=if(isnull(N50_2013_hav@Oekokart),1,null())"
#Measure distance from coast line to ocean
r.grow.distance --overwrite input=N50_2013_hav_inv distance=N50_2013_hav_inv_dist metric=squared
#Extract open ocean as ocean area with more than 1000m distance from coast line
r.mapcalc expression="N50_2013_hav_inv_rel=if(sqrt(N50_2013_hav_inv_dist)>1000.0,1,null())"
#Measure ditance from open ocean
r.grow.distance --overwrite input=N50_2013_hav_inv_rel distance=N50_2013_hav_dist metric=euclidean
#Measure amount of ocean in a given neighborhood
#Count number of ocean pixels within 50m gridcells
g.region -p rast=DEM_10m res=50 n=n+20
r.resamp.stats --o input=N50_2013_hav output=N50_2013_hav_50m method=sum
#Sum the number of ocean pixels within 5050m neighborhood
r.neighbors -c input=N50_2013_hav_50m output=N50_2013_mengde_hav_5050m method=sum size=101 --o --v
#Count number of ocean pixels within 100m gridcells
g.region -p rast=DEM_10m res=100 n=n+20
r.resamp.stats --o input=N50_2013_hav output=N50_2013_hav_100m method=sum
#Sum the number of ocean pixels within 10100m neighborhood
r.neighbors -c input=N50_2013_hav_100m output=N50_2013_mengde_hav_10100m method=sum size=101 --o --v
#Count number of ocean pixels within 200m gridcells
g.region -p rast=DEM_10m res=200 n=n+120

r.resamp.stats --o input=N50_2013_hav output=N50_2013_hav_200m method=sum
r.mapcalc expression="N50_2013_hav_200m_nabo=if(isnull(N50_2013_land_200m)&&isnull(N50_2013_hav_200m),Hav_naboer_200m,N50_2013_hav_200m)"
#Sum the number of ocean pixels within 25000m neighborhood
r.neighbors --o -c --verbose input=N50_2013_hav_200m_nabo output=N50_2013_mengde_hav_25000m method=sum size=125
#Sum the number of ocean pixels within 50200m neighborhood
r.neighbors --o -c --verbose input=N50_2013_hav_200m_nabo output=N50_2013_mengde_hav_50200m method=sum size=251
#Sum the number of ocean pixels within 100200m neighborhood
r.neighbors --o -c --verbose input=N50_2013_hav_200m_nabo output=N50_2013_mengde_hav_100200m method=sum size=501
#Sum the number of ocean pixels within 180200m neighborhood
r.neighbors --o -c --verbose input=N50_2013_hav_200m_nabo output=N50_2013_mengde_hav_180200m method=sum size=901
#Sum the number of ocean pixels within 180200m neighborhood
r.neighbors --o -c --verbose input=N50_2013_hav_200m_nabo output=N50_2013_mengde_hav_250200m method=sum size=1251

r.null map=N50_2013_mengde_hav_25000m null=1
r.null map=N50_2013_mengde_hav_50200m null=1
r.null map=N50_2013_mengde_hav_100200m null=1
r.null map=N50_2013_mengde_hav_180200m null=1
r.null map=N50_2013_mengde_hav_180200m null=1

r.mapcalc expression="N50_2013_mengde_hav_avg=avg(N50_2013_mengde_hav_250200m,N50_2013_mengde_hav_180200m,N50_2013_mengde_hav_100200m,N50_2013_mengde_hav_50200m,N50_2013_mengde_hav_25000m,N50_2013_mengde_hav_10100m,N50_2013_mengde_hav_5050m)"
#Count number of ocean pixels within 50m gridcells
g.region -p rast=DEM_10m res=50 n=n+20
r.resamp.stats --o input=DEM_10m_2013_kartverket output=DEM_50m_2013_kartverket_avg method=average
r.resamp.stats --o input=N50_2013_hav output=N50_2013_hav_50m method=min
r.mapcalc expression="DEM_50m_2013_kartverket_avg_0=if(DEM_50m_2013_kartverket_avg<=0,null(),DEM_50m_2013_kartverket_avg)" --o --v
r.cost -k --o --v input=DEM_50m_2013_kartverket_avg_0 output=coast_cost_dist_50m start_rast=N50_2013_hav_50m

#Count number of forest pixels within 50m gridcells
g.region -p rast=DEM_10m res=50 n=n+20
r.resamp.stats --o input=N50_2013_skog output=N50_2013_skog_50m method=sum
#Sum the number of forest pixels within 5050m neighborhood
r.neighbors -c input=N50_2013_skog_50m output=N50_2013_mengde_skog_5050m method=sum size=101 --o --v


###########################################
###Not used
##Smooth borders between forest and open areas in order to remove narrow 
#r.neighbors -c input=N50_2013_skog_og_aapent_omraade output=N50_2013_rel_objtyper_mode_5 method=mode size=5 --o
###########################################

#Clump forest and open areas to uniqe units
r.clump --overwrite --verbose input=N50_2013_skog_og_aapent_omraade output=N50_2013_rel_objtyper_clump
#Measure area of the relevant landcover types
r.stats input="N50_2013_rel_objtyper_clump,N50_2013_skog_og_aapent_omraade" -cni --v separator=' ' > /home/stefan/tmp/N50_2013_rel_objtyper.txt

r.mask raster=N50_2013_skog_og_aapent_omraade
r.statistics2 base=N50_2013_rel_objtyper_clump cover=DEM_10m_2013_kartverket output=N50_2013_clump_maks_hoh method=max
r.statistics2 base=N50_2013_rel_objtyper_clump cover=DEM_10m_2013_kartverket output=N50_2013_clump_avg_hoh method=average

g.remove rast=DEM_1km_kartverket_avg -f
r.mask --o raster=N50_2013_aapent_omraade
r.neighbors --o --verbose input=N50_2013_clump_maks_hoh output=N50_2013_clump_maks_hoh_aapent method=maximum size=3
r.neighbors --o --verbose input=N50_2013_clump_avg_hoh output=N50_2013_clump_avg_hoh_aapent method=maximum size=3
r.mask -r
exit

grass64 -text /home/stefan/grassdata/Norge_33N_WGS84/Oekokart
r.out.maxent_swd bgr_mask=N50_2013_skog_aapent_filter_50m@Oekokart alias_input=/home/stefan/Okokart/alias2.csv bgr_output=/home/stefan/Okokart/skgr2.csv -z --v


###########################################
#Could be replaced by original forest map
cat /home/stefan/tmp/N50_2013_rel_objtyper.txt | awk '{if($2==1) print $1 " = " 1}' > /home/stefan/tmp/N50_2013_rel_skog.txt
echo "* = NULL" >> /home/stefan/tmp/N50_2013_rel_skog.txt
#Remove areas with less than 1km2 from forest raster
r.reclass --o --v input=N50_2013_rel_objtyper_clump output=N50_2013_rel_skog rules=/home/stefan/tmp/N50_2013_rel_skog.txt
###########################################

cat /home/stefan/tmp/N50_2013_rel_objtyper.txt | awk '{if($2==2&&$3>10000) print $1 " = " 1}' > /home/stefan/tmp/N50_2013_rel_aapent.txt
echo "* = NULL" >> /home/stefan/tmp/N50_2013_rel_aapent.txt
#Remove areas with less than 1km2 from open areas raster
r.reclass --o --v input=N50_2013_rel_objtyper_clump output=N50_2013_rel_aapent rules=/home/stefan/tmp/N50_2013_rel_aapent.txt

###########################
###Probably irrelevant
cat /home/stefan/tmp/N50_2013_rel_objtyper.txt | awk '{if($2>=1) print $1 " = " $3}' > /home/stefan/tmp/N50_2013_clump_size.txt
echo "* = NULL" >> /home/stefan/tmp/N50_2013_clump_size.txt
r.reclass --o --v input=N50_2013_rel_objtyper_clump output=N50_2013_clump_size rules=/home/stefan/tmp/N50_2013_clump_size.txt
###########################

###########################
###Probably irrelevant
##Rasterize borders between forest and open areas with 10m resolution
#v.extract input=N50_2013_arealdekke_pol_boundary layer=2 output=N50_2013_skog_aapent type=boundary where="(left_type='Skog' AND right_type='ÅpentOmråde') OR (left_type='ÅpentOmråde' AND right_type='Skog')" --v
#v.type --verbose input=N50_2013_skog_aapent layer=2 from_type=boundary to_type=line output=N50_2013_skog_aapent_lin
#v.to.rast use=val val=1 input=N50_2013_skog_aapent_lin layer=2 output=N50_2013_skog_aapent_lin type=line
###########################

#############################################################################################
#Measure altitude of forest
r.mapcalc expression="N50_2013_skog_DEM=if(isnull(N50_2013_skog),if(N50_2013_aapent_omraade==1,0,null()),if(N50_2013_skog==1,DEM_10m_2013_kartverket,null()))" --o

###########################
###Probably irrelevant
##Alternative with smoothed borders
#r.mapcalc expression="N50_2013_skog_DEM_mode_5=if(isnull(N50_2013_skog)&&&isnull(N50_2013_rel_skog),if(N50_2013_rel_objtyper_mode_5==2&&N50_2013_rel_aapent==1,0,null()),if(N50_2013_rel_objtyper_mode_5==1&&N50_2013_rel_skog,DEM_10m_2013_kartverket,null()))" --o
###########################


#Alternative identify border piksels between forest and open areas using r.mapcalc (faster than the approach of using vector and topology)
#r.mapcalc --o expression="N50_2013_skog_aapent=if(isnull(N50_2013_aapent_omraade),if(((N50_2013_skog&&N50_2013_aapent_omraade[-1,0])|||(N50_2013_skog&&N50_2013_aapent_omraade[0,1])|||(N50_2013_skog&&N50_2013_aapent_omraade[1,0])|||(N50_2013_skog&&N50_2013_aapent_omraade[0,-1])),1,null()),null())" --o
r.mapcalc --o expression="N50_2013_skog_aapent_filter=if(isnull(N50_2013_aapent_omraade)&&isnull(N50_2013_rel_aapent)&&&N50_2013_rel_skog,if(((N50_2013_skog&&N50_2013_rel_aapent[-1,0]&&N50_2013_aapent_omraade[-1,0])|||(N50_2013_skog&&N50_2013_rel_aapent[0,1]&&N50_2013_aapent_omraade[0,1])|||(N50_2013_skog&&N50_2013_rel_aapent[1,0]&&N50_2013_aapent_omraade[1,0])|||(N50_2013_skog&&N50_2013_rel_aapent[0,-1]&&N50_2013_aapent_omraade[0,-1])),1,null()),null())" --o
#r.mapcalc --o expression="N50_2013_skog_aapent_all_mask=if(isnull(N50_2013_skog_aapent),N50_2013_skog_aapent_filter,null())"

#############################################################################################
#Aggregate data to 50m resolution
g.region -p rast=DEM_10m res=50 n=n+20
r.resamp.stats --o input=N50_2013_skog_DEM output=N50_2013_skog_DEM_50m method=maximum
r.neighbors --o --verbose input=N50_2013_skog_DEM_50m output=N50_2013_skog_DEM_max_250m method=maximum size=5
r.neighbors --o -c --verbose input=N50_2013_skog_DEM_50m output=N50_2013_skog_DEM_max_550m method=maximum size=11
r.neighbors --o -c --verbose input=N50_2013_skog_DEM_50m output=N50_2013_skog_DEM_max_1050m method=maximum size=21
r.neighbors --o -c --verbose input=N50_2013_skog_DEM_50m output=N50_2013_skog_DEM_max_2550m method=maximum size=51
r.neighbors --o -c --verbose input=N50_2013_skog_DEM_50m output=N50_2013_skog_DEM_max_5050m method=maximum size=101

r.neighbors --o -c --verbose input=N50_2013_skog_DEM_max_5050m output=N50_2013_skog_DEM_max_5050m_stddev method=stddev size=101

#############################################################################################
#Aggregate data to 100m resolution
g.region -p rast=DEM_10m res=100 n=n+20
r.resamp.stats --o input=N50_2013_skog_DEM output=N50_2013_skog_DEM_100m method=maximum
r.neighbors --o -c --verbose input=N50_2013_skog_DEM_100m output=N50_2013_skog_DEM_max_10100m method=maximum size=101

#Aggregate data to 200m resolution
g.region -p rast=DEM_10m res=200 n=n+120
r.resamp.stats --o input=N50_2013_skog_DEM output=N50_2013_skog_DEM_200m method=maximum
r.neighbors --o -c --verbose input=N50_2013_skog_DEM_200m output=N50_2013_skog_DEM_max_25000m method=maximum size=125
r.neighbors --o -c --verbose input=N50_2013_skog_DEM_200m output=N50_2013_skog_DEM_max_50200m method=maximum size=251

#############################################################################################
#Aggregate data to 500m resolution
#g.region -up rast=DEM_10m res=500 n=n+420 e=e+100
#r.resamp.stats --o input=N50_2013_skog_DEM_mode_5 output=N50_2013_skog_DEM_mode_5_500m method=maximum
#r.neighbors --o -c --verbose input=N50_2013_skog_DEM_mode_5_500m output=N50_2013_skog_DEM_mode_5_max_50500m method=maximum size=251

#Relate altitude to maximal altitude of forest in different neighborhoods
g.region -p rast=DEM_10m align=DEM_10m
r.mapcalc --o expression="N50_2013_skog_DEM_ifht_max_skog_250m=N50_2013_skog_DEM_max_250m-DEM_10m_2013_kartverket"
r.mapcalc --o expression="N50_2013_skog_DEM_ifht_max_skog_550m=N50_2013_skog_DEM_max_550m-DEM_10m_2013_kartverket"
r.mapcalc --o expression="N50_2013_skog_DEM_ifht_max_skog_1050m=N50_2013_skog_DEM_max_1050m-DEM_10m_2013_kartverket"
r.mapcalc --o expression="N50_2013_skog_DEM_ifht_max_skog_2550m=N50_2013_skog_DEM_max_2550m-DEM_10m_2013_kartverket"
r.mapcalc --o expression="N50_2013_skog_DEM_ifht_max_skog_5050m=N50_2013_skog_DEM_max_5050m-DEM_10m_2013_kartverket"
r.mapcalc --o expression="N50_2013_skog_DEM_ifht_max_skog_10100m=N50_2013_skog_DEM_max_10100m-DEM_10m_2013_kartverket"
r.mapcalc --o expression="N50_2013_skog_DEM_ifht_max_skog_25000m=N50_2013_skog_DEM_max_25000m-DEM_10m_2013_kartverket"
r.mapcalc --o expression="N50_2013_skog_DEM_ifht_max_skog_50200m=N50_2013_skog_DEM_max_50200m-DEM_10m_2013_kartverket"

###Extract forest transition line
#Extract forest transition line at maximum hight within 50m gridcellls
r.mapcalc --o expression="N50_2013_skog_aapent_filter_50m=if(N50_2013_skog_DEM_50m-DEM_10m_2013_kartverket>0,null(),if(isnull(N50_2013_aapent_omraade)&&isnull(N50_2013_rel_aapent)&&&N50_2013_rel_skog,if(((N50_2013_skog&&N50_2013_rel_aapent[-1,0]&&N50_2013_aapent_omraade[-1,0])|||(N50_2013_skog&&N50_2013_rel_aapent[0,1]&&N50_2013_aapent_omraade[0,1])|||(N50_2013_skog&&N50_2013_rel_aapent[1,0]&&N50_2013_aapent_omraade[1,0])|||(N50_2013_skog&&N50_2013_rel_aapent[0,-1]&&N50_2013_aapent_omraade[0,-1])),1,null()),null())" --o
#Extract forest transition line at maximum hight within 100m gridcellls
r.mapcalc --o expression="N50_2013_skog_aapent_filter_100m=if(N50_2013_skog_DEM_100m-DEM_10m_2013_kartverket>0,null(),if(isnull(N50_2013_aapent_omraade)&&isnull(N50_2013_rel_aapent)&&&N50_2013_rel_skog,if(((N50_2013_skog&&N50_2013_rel_aapent[-1,0]&&N50_2013_aapent_omraade[-1,0])|||(N50_2013_skog&&N50_2013_rel_aapent[0,1]&&N50_2013_aapent_omraade[0,1])|||(N50_2013_skog&&N50_2013_rel_aapent[1,0]&&N50_2013_aapent_omraade[1,0])|||(N50_2013_skog&&N50_2013_rel_aapent[0,-1]&&N50_2013_aapent_omraade[0,-1])),1,null()),null())" --o


#############################################################################################
#Export GIS data layers to csv-tabel for further modelling in R
r.out.maxent_swd bgr_mask=N50_2013_skog_aapent_filter_50m alias_input=/home/stefan/Okokart/alias.csv bgr_output=/home/stefan/Okokart/skgr.csv -z --v


#############################################################################################
#############################################################################################
#Statistical modelling in Cran R
#############################################################################################
#############################################################################################

#############################################################################################
#Data visualisation / exploration
#############################################################################################

#############################################################################################
#Filtering of reference points
#############################################################################################

#############################################################################################
#Modelling
#############################################################################################

#############################################################################################
#Plotting of relevant model results
#############################################################################################


#############################################################################################
#############################################################################################
###Model analysis in GRASS GIS:
#############################################################################################
#############################################################################################

#Import 500m SSB-grid
v.in.ogr dsn="PG:host=ninsrv16 dbname=gisdata" layer="ssb_grid_2013.ssb500m_utm33" output="ssb500m" --o

#Convert SSB-grid to raster
g.region vect=ssb500m res=500 -p
v.to.rast input=ssb500m output=ssb500m tye=area use=cat rows=3000

#Import models to GRASS (including confidence intervalls), relate them to terrain model (DEM) and compute  uncertainty maps

#Adjust maps to R analysis
r.mapcalc --o expression="aspect5_cl8=if(round((DEM_10m_aspect_5@Oekokart-22.5)/45.0)==4,3,if(round((DEM_10m_aspect_5@Oekokart-22.5)/45.0)==-5,-4,round((DEM_10m_aspect_5@Oekokart-22.5)/45.0)))"
r.mapcalc --o expression="aspect3_cl8=if(round((DEM_10m_aspect_3@Oekokart-22.5)/45.0)==4,3,if(round((DEM_10m_aspect_3@Oekokart-22.5)/45.0)==-5,-4,round((DEM_10m_aspect_3@Oekokart-22.5)/45.0)))"
r.mapcalc --o expression="amount_ocean_100200m=if(isnull(N50_2013_mengde_hav_100200m@Oekokart),1,if(N50_2013_mengde_hav_100200m@Oekokart<=0,1,N50_2013_mengde_hav_100200m@Oekokart))"

#Relate altitude of the terrain (DEM) to altitude of forest line from model 1

#Create uncertainty map for model 1 using r.series
r.series --o --v input="modell_1_confint_2p5,modell_1_avg,modell_1_confint_97p5" output="modell_1_range" method="range"

#Import model 2 ("") with confidence intervalls

#Relate altitude of the terrain (DEM) to altitude of forest line from model 2

#Create uncertainty map for model 2 using r.series
r.series --o --v input="modell_2_confint_2p5,modell_2_avg,modell_2_confint_97p5" output="modell_2_range" method="range"

#Import modell 3 ("") with confidence intervalls

#Relate altitude of the terrain (DEM) to altitude of forest line from model 3

#Create uncertainty map for model 3 using r.series
r.series --o --v input="modell_3_confint_2p5,modell_3_avg,modell_3_confint_97p5" output="modell_3_range" method="range"

#Create uncertainty maps across modells 
r.series --o --v input="f1sm_gls_all,f1sm_gls_ulon,f1sm_gls_ucoast" output="f1sm_gls_avg,f1sm_gls_range,f1sm_gls_var,f1sm_gls_min_raster,f1sm_gls_max_raster" method="average,range,variance,min_raster,max_raster"
r.series --o --v input="f1sm_gls_all_fjell,f1sm_gls_ulon_fjell,f1sm_gls_ucoast_fjell" output="f1sm_gls_fjell_count" method="sum"


# r.series --o --v input="modell_1_avg,modell_2_avg,modell_3_avg" output="modell_avg_all_avg,modell_avg_all_range,modell_avg_all_var" method="average,range,variance"
# r.series --o --v input="modell_1_confint_2p5,modell_2_confint_2p5,modell_3_confint_2p5" output="modell_confint_2p5_avg,modell_confint_2p5_range,modell_confint_2p5_var" method="average,range,variance"
# r.series --o --v input="modell_1_confint_97p5,modell_2_confint_97p5,modell_3_confint_97p5" output="modell_confint_97p5_avg,modell_confint_97p5_range,modell_confint_97p5_var" method="average,range,variance"

#Create uncertainty maps across modells regarding relation to terrain modell (DEM)
r.series --o --v input="modell_1_confint_2p5_fjell_bin,modell_2_confint_2p5_fjell_bin,modell_3_confint_2p5_fjell_bin,modell_1_avg_fjell_bin,modell_2_avg_fjell_bin,modell_3_avg_fjell_bin,modell_1_confint_97p5_fjell_bin,modell_2_confint_97p5_fjell_bin,modell_3_confint_97p5_fjell_bin" output=modell_all_fjell method="sum"

#Calculate error type 1:

#Calculate amount of forest over forest line for each model
echo "Model,amount of forest over forest line (m2)" > /home/stefan/Okokart/forest_over_forestline.csv
for m in "f1sm_gls_all@m1" "f1sm_gls_ulon@m2" "f1sm_gls_ucoast@m3"
do
r.stats -a -n --overwrite --verbose input="N50_2013_skog,$m" separator=" " | awk -v M=$m '{print "Modell " M "," $2}' >> /home/stefan/Okokart/forest_over_forestline.csv
done

g.region rast=DEM10m res=2500 -p
eval `g.region -ug` 
r.resamp.stats --verbose input=f1sm_gls_fjell_count output=s

r.mapcalc --o --v expression="grid_seq = col() * $rows + row() + $cols - ($rows + $cols)" 
r.mapcalc --o --v expression="modell_1_avg_fjell_bin_SI=round(if(modell_1_avg_fjell_bin==0,-1*grid_seq,grid_seq))"

#Underestimated forest line: Amount of forest over forest line
#Effect on wrong classified area
if(fjell,skog,null())

#Altitude deviation for underestimates
r.mapcalc expression="modell_3g_underestimates=if(modell_3g_avg_fjell_bin@m3g,(modell_3g_avg@m3g-skog_DEM),null())"

#Amount of mountain area
r.stats -a fjell

#Residuals

r.resamp.stats 



#Nr.	Resultatområde (arealkategori)	N50 objekttype	Arealkategorier som kan leveres
#1	Levende hav og kyst 	Hav	•	Indre havområder (kystvann)
#•	Ytre havområder
#2	Livskraftige elver og innsjøer	Innsjø, ElvBekk, FerskvannTørrfall	•	Ferskvann•	
#3	Frodige våtmarker , 	Myr	•	Våtmark
#4	Mangfoldige skoger	Skog	•	Skog
#5	Storslått fjellandskap 	ÅpentOmråde over modellert skoggrense, SnøIsBre	•	SnøIsBre
#•	Fjell
#6	Verdifulle kulturminner og rikt kulturlandskap 	ÅpentOmråde under modellert skoggrense,  DyrketMark	•	Åpent lavland
#•	Dyrket mark
#7	Godt bymiljø	BymessigBebyggelse, TettBebyggelse, Park	•	Byer og tettsteder
#-	Rest andre kategorier	Alpinbakke, Steintipp, Golfbane, Gravplass, Industriområde. Lufthavn, SportIdrettPlass, Steinbrudd	•	Annet

# Reclassification table for nutrition in bedrock (Join column = HBERGKODE)
# HBERGKODE|HBERGNAVN|rihet_ID|RIKHET
# 0||1|Flate i vann
# 0||1|Sverige
# 0||1|Sverige?
# 1|Løsmasser|2|Middels
# 2|Sandstein|1|Fattig
# 3|Konglomerat, sedimentær breksje|2|Middels
# 4|Breksje|2|Middels
# 5|Mylonitt, fyllonitt|2|Middels
# 7|Sedimentære bergarter (uspesifisert)|1|Fattig
# 7|Sedimentære bergarter (uspsesifisert)|1|Fattig
# 8|Skifer, sandstein, kalkstein|2|Middels
# 9|Sandstein, skifer|2|Middels
# 10|Kalkstein, skifer, mergelstein|3|Rik
# 11|Kalkstein, dolomitt|3|Rik
# 21|Granitt|1|Fattig
# 21|Granitt, granodioritt|1|Fattig
# 22|Dioritt, monzodioritt|1|Fattig
# 23|Syenitt, kvartssyenitt|1|Fattig
# 24|Kvartsmonzonitt|1|Fattig
# 24|Monzonitt, kvartsmonzonitt|1|Fattig
# 25|Mangerittsyenitt|1|Fattig
# 26|Ryolitt, ryodacitt|1|Fattig
# 26|Ryolitt, ryodacitt, dacitt|1|Fattig
# 27|Rombeporfyr|2|Middels
# 28|Metabasalt|2|Middels
# 29|Vulkanske bergarter (uspesifisert)|1|Fattig
# 30|Mangeritt til gabbro, gneis og amfibolitt|2|Middels
# 35|Gabbro, amfibolitt|2|Middels
# 37|Keratofyr|1|Fattig
# 37|Keratoporfyr|1|Fattig
# 38|Kvartsdioritt|1|Fattig
# 38|Kvartsdioritt, tonalitt, trondhjemitt|1|Fattig
# 40|Olivinstein|1|Fattig
# 41|Eklogitt|1|Fattig
# 45|Anortositt|1|Fattig
# 46|Charnockittiske til anortosittiske dypbergarter, stedvis omdannet|1|Fattig
# 46|Charnokittiske til anortosittiske dypberarter, stedvis omdannet|1|Fattig
# 50|Amfibolitt og glimmerskifer|2|Middels
# 55|Grønnstein, amfibolitt|2|Middels
# 60|Meta-arkose, kvartsitt|2|Middels
# 60|Metasandstein, skifer|2|Middels
# 61|Kvartsitt|1|Fattig
# 62|Glimmergneis, glimmerskifer, metasandstein, amfibolitt|2|Middels
# 65|Fylitt, glimmerskifer|3|Rik
# 65|Fyllitt, glimmerskifer|3|Rik
# 66|Kalkglimmerskifer, kalksilikatgneis|3|Rik
# 70|Marmor|3|Rik
# 71|Dolomitt|3|Rik
# 82|Diorittisk til granittisk gneis, migmatitt|1|Fattig
# 82|Gneis, granittisk gneis, migmatitt|1|Fattig
# 82|Granitt, fin- til middelskornet, og partier med porfyrisk ryodacitt|1|Fattig
# 85|Øyegneis, granitt, foliert granitt|1|Fattig
# 87|B?ndgneis (amfibolitt, hornblendegneis, glimmergne|1|Fattig
# 87|Båndgneis|1|Fattig
# 87|Båndgneis (amfibolitt, hornblendegneis, glimmergneis), stedvis migmatittisk|1|Fattig

r.mapcalc expression="N50_2013_skog_over_modell_1=if(modell_1_avg_fjell_bin@m1==1,N50_2013_skog,null())" --o
r.mapcalc expression="N50_2013_skog_over_modell_1g=if(modell_1g_avg_fjell_bin@m1g==1,N50_2013_skog,null())" --o
r.mapcalc expression="N50_2013_skog_over_modell_2=if(modell_2_avg_fjell_bin@m2==1,N50_2013_skog,null())" --o
r.mapcalc expression="N50_2013_skog_over_modell_2g=if(modell_2g_avg_fjell_bin@m2g==1,N50_2013_skog,null())" --o
r.mapcalc expression="N50_2013_skog_over_modell_3=if(modell_3_avg_fjell_bin@m3==1,N50_2013_skog,null())" --o
r.mapcalc expression="N50_2013_skog_over_modell_3g=if(modell_3g_avg_fjell_bin@m3g==1,N50_2013_skog,null())" --o
r.mapcalc expression="N50_2013_skog_over_modell_5g=if(modell_5g_avg_fjell_bin@m5g==1,N50_2013_skog,null())" --o
r.mapcalc expression="N50_2013_skog_over_modell_6g=if(modell_6g_avg_fjell_bin@m6g==1,N50_2013_skog,null())" --o


#Ytre og indre havområder

#Utfigurer fjellpolygoner
#fjell_fjellrev,fjell_interpolert"
r.series --o --v input="modell_1_avg_fjell_bin@m1,modell_1g_avg_fjell_bin@m1g,modell_2_avg_fjell_bin@m2,modell_2g_avg_fjell_bin@m2g,modell_3_avg_fjell_bin@m3,modell_3g_avg_fjell_bin@m3g" output="modell_1_2_3_5_6_fjell_count" method="sum"
r.series --o --v input="modell_1_avg_fjell@m1,modell_1g_avg_fjell@m1g,modell_2_avg_fjell@m2,modell_2g_avg_fjell@m2g,modell_3_avg_fjell@m3,modell_3g_avg_fjell@m3g" output="modell_1_2_3_5_6_fjell_max,modell_1_2_3_5_6_fjell_stddev,modell_1_2_3_5_6_fjell_range" method="maximum,stddev,range"

#Calculate amount of forest over forest line for each model
echo "Model,amount of forest over forest line (m2), Number of pixels (10x10m)" > /home/stefan/Okokart/forest_over_forestline.csv
for m in "1" "1g" "2" "2g" "3" "3g"
do
r.stats -a -n -c --overwrite --verbose input="N50_2013_skog_over_modell_${m}" separator=" " | awk -v M=$m '{print "Modell " M "," $2 "," $3}' >> /home/stefan/Okokart/forest_over_forestline.csv
done

# - Sjekk forskjell interpolert vs. modell
# - Sjekk grensen mot Sverige
# - Sjekk forskjell i mengde fjell

#Med Odd:
# - det er først og fremst oseanitet-kontinentalits-gradienten som ikke fanges godt opp i modellen
#	- Kystlinja: enten fjordene fanges ikke opp eller dem får for  mye effekt i modellen --> derfor droppet jeg avstand til kystlinja (og brukte kun mengde med hav i 90km radius)
#	- Forklaringsevne av "mengde hav innen 90km radius" stopper 90km fra kystlinja
#	- lon er økologisk sett fanskelig å interpretere men gir mindre feil enn avstand til kyst

#Med Marianne:
# - modell - call
#	- ble forklaringsvariablene plukket på en forsvarlig måte
#	- 

###Import filter result to GRASS GIS
#Save filter results to csv
write.csv(skgrMergeF1tc, '/home/stefan/Okokart/skgrMereF1tc.csv')
write.csv(data.frame(X=skgrMergeF1tc$X,Y=skgrMergeF1tc$Y,Z=f1sm3$residuals), '/home/stefan/Okokart/modell_3_residuals.csv')
write.csv(data.frame(X=skgrMergeF1tc$X,Y=skgrMergeF1tc$Y,Z=f1sm3$fitted), '/home/stefan/Okokart/modell_3_fitted.csv')

g.region -p rast=DEM_10m res=200 n=n+120

cat /home/stefan/Okokart/modell_3_residuals.csv | cut -f2-4 -d',' | tail -n +2 | r.in.xyz input=- output=modell_3_residuals_underestimated method=max -i separator=','
cat /home/stefan/Okokart/modell_3_residuals.csv | tr ',' ' ' | awk '{if($3<0) print $0}' | r.in.xyz input=- output=modell_3_residuals_overestimated method=max separator=' '

r.surf.idw input=modell_3_residuals_underestimated output=modell_3_residuals_underestimated_idw

#Import csv to GRASS for overlaying with variable maps
v.in.ascii -z --o --v input=/data/home/stefan/Okokart/skgr_filter3.csv output=skgr_filter_3 separator="," skip=1 columns="id varchar(10), bgr varchar(10),X integer,Y integer,hoh double precision,f_max_100m integer,forest_p integer,forest_p_s integer,lat double precision,lon double precision,dem1km_avg double precision,maxf_250 double precision,maxf_550 double precision,maxf_1050 double precision,maxf_2550 double precision,maxf_5050 double precision,maxf_10100 double precision,maxf_25000 double precision,maxf_50200 double precision,actuality integer,slope_3 integer,slope_5 double precision,slope_next double precision,trit_1960 double precision,trit_1970 double precision,trit_1980 double precision,trit_1990 double precision,trit_2000 double precision,trit_total double precision,tett_1960 double precision,tett_1970 double precision,tett_1980 double precision,tett_1990 double precision,tett_2000 double precision,tett_total double precision,solar_radi double precision,aspect_3 integer,aspect_5 double precision,geol_rich integer,geol_type integer,quart_gw integer,quart_inf integer,quart_type integer,TWI double precision,coast_dist double precision,amo_5050m integer,amo_10100m integer,amo_25000m double precision,amo_50200m integer,amo_100200 integer,TPI_30m double precision,TPI_50m double precision,TPI_70m double precision,TPI_90m double precision,TPI_110m double precision,TPI_1100m double precision,TPI_3100m double precision,TPI_5100m double precision,TPI_1100ms double precision,TPI_3100ms double precision,TPI_5100ms double precision,AGDD_total double precision,AGDD_6090 double precision,AGDD_1960 double precision,AGDD_1970 double precision,AGDD_1980 double precision,AGDD_1990 double precision,AGDD_2000 double precision,t_feb_tot double precision,t_feb_6090 double precision,t_feb_1960 double precision,t_feb_1970 double precision,t_feb_1980 double precision,t_feb_1990 double precision,t_feb_2000 double precision,t_feb_2010 double precision,asp_cl8 integer,continent double precision,max_f_sum double precision x=3 y=4 z=5"

sh /home/stefan/Okokart/m3g.sh
r.neighbors input=modell_3g_avg_fjell_bin output=modell_3g_avg_fjell_bin_mode_3 method=mode
r.mapcalc expression="modell_3g_avg_fjell_bin_mode_3_rst=if(modell_3g_avg_fjell_bin@m3g==0,modell_3g_avg_fjell_bin_mode_3,modell_3g_avg_fjell_bin@m3g)" --o --v

g.region -p rast=DEM_10m res=20
r.resamp.stats --overwrite --verbose input=modell_3g_avg_fjell_bin_mode_3_rst output=modell_3g_avg_fjell_bin_mode_3_rst_20m method=maximum
r.null setnull=0 map=modell_3g_avg_fjell_bin_mode_3_rst_20m
#r.null null=0 map=modell_3g_avg_fjell_bin_mode_3_rst_20m
r.to.vect -s --overwrite --verbose input=modell_3g_avg_fjell_bin_mode_3_rst_20m output=modell_3g_avg_fjell_bin_mode_3_rst type=area
v.clean input=modell_3g_avg_fjell_bin_mode_3_rst output=modell_3g_avg_fjell_bin_mode_3_rst_clean type=boundary,centroid,area tool=rmarea,rmsa,bpol,rmdupl thres=10000.00,10.00,0.00,0.00 --overwrite
#v.generalize input=modell_3g_avg_fjell_bin_mode_3_rst output=modell_3g_avg_fjell_bin_mode_3_rst_red0_30 method=lang threshold=30 look_ahead=2 --o
#v.generalize input=modell_3g_avg_fjell_bin_mode_3_rst output=modell_3g_avg_fjell_bin_mode_3_rst_red0_30 method=douglas_reduction threshold=0 reduction=30

#v.extract --o --verbose input=N50_2013_arealdekke_pol where="objtype=='ÅpentOmråde'" output=N50_2013_aapent_omraade
#v.extract --o --verbose input=N50_2013_arealdekke_pol where="objtype=='Havflate'" output=N50_2013_hav

#v.overlay --overwrite --verbose ainput=N50_2013_aapent_omraade@Oekokart binput=modell_3g_avg_fjell_bin_mode_3_rst_clean@Oekokart operator=or output=N50_2013_fjell_lavland
v.overlay --overwrite --verbose ainput=N50_2013_arealdekke_pol binput=ADM_maritim_versjon_2012_1_flate_yttre_hav operator=or output=N50_2013_arealdekke_pol_hav snap=-1
v.overlay --overwrite --verbose ainput=N50_2013_arealdekke_pol_hav binput=modell_3g_avg_fjell_bin_mode_3_rst_clean@Oekokart operator=or output=N50_2013_arealdekke_pol_fjell_lavland_hav snap=-1

v.db.addcolumn map=N50_2013_arealdekke_pol_fjell_lavland_hav column="resultat_ID integer"
echo "UPDATE N50_2013_arealdekke_pol_fjell_lavland_hav SET resultat_ID = \
CASE WHEN a_a_objtype='Havflate' OR b_cat IS NOT NULL THEN 10 \
WHEN a_a_objtype='Innsjø' OR a_a_objtype='ElvBekk' OR a_a_objtype='FerskvannTørrfall' THEN 20 \
WHEN a_a_objtype='Myr' THEN 30 \
WHEN a_a_objtype='Skog' THEN 40 \
WHEN a_a_objtype='SnøIsbre' OR (a_a_objtype='ÅpentOmråde' AND a_b_value=1) THEN 50 \
WHEN a_a_objtype='DyrketMark' OR (a_a_objtype='ÅpentOmråde' AND a_b_value=0) THEN 60 \
WHEN a_a_objtype='BymessigBebyggelse' OR a_a_objtype='TettBebyggelse' OR a_a_objtype='Park' THEN 70 \
WHEN a_a_cat IS NULL AND b_cat IS NULL THEN NULL \
ELSE 99 \
END;" | db.execute input=-

v.db.addcolumn map=N50_2013_arealdekke_pol_fjell_lavland_hav column="NI_ID integer"
echo "UPDATE N50_2013_arealdekke_pol_fjell_lavland_hav SET NI_ID = \
CASE WHEN a_a_objtype='Havflate' AND b_cat IS NULL THEN 10 \
WHEN b_cat IS NOT NULL THEN 11 \
WHEN a_a_objtype='Innsjø' OR a_a_objtype='ElvBekk' OR a_a_objtype='FerskvannTørrfall' THEN 20 \
WHEN a_a_objtype='Myr' THEN 30 \
WHEN a_a_objtype='Skog' THEN 40 \
WHEN a_a_objtype='SnøIsbre' OR (a_a_objtype='ÅpentOmråde' AND a_b_value=1) OR (a_a_objtype='Alpinbakke' AND a_b_value=1) OR (a_a_objtype='Steintipp' AND a_b_value=1) THEN 50 \
WHEN a_a_objtype='DyrketMark' OR (a_a_objtype='ÅpentOmråde' AND a_b_value=0) OR (a_a_objtype='Alpinbakke' AND a_b_value=0) OR (a_a_objtype='Steintipp' AND a_b_value=0) THEN 60 \
WHEN a_a_cat IS NULL AND b_cat IS NULL THEN NULL \
ELSE 99 \
END;" | db.execute input=-

v.db.addcolumn map=N50_2013_arealdekke_pol_fjell_lavland_hav_pre column="NI text"
echo "UPDATE N50_2013_arealdekke_pol_fjell_lavland_hav_pre SET NI = \
CASE \
WHEN NI_ID==10 THEN 'Indre havområder (kystvann)' \
WHEN NI_ID==11 THEN 'Ytre havområder' \
WHEN NI_ID==20 THEN 'Ferskvann' \
WHEN NI_ID==30 THEN 'Myr og vannkant' \
WHEN NI_ID==40 THEN 'Skog' \
WHEN NI_ID==50 THEN 'Fjell' \
WHEN NI_ID==60 THEN 'Åpent lavland' \
ELSE 'Annet' \
END;" | db.execute input=-

v.db.renamecolumn map=N50_2013_arealdekke_pol_fjell_lavland_hav_pre column=a_b_value,fjell --verbose
v.db.renamecolumn map=N50_2013_arealdekke_pol_fjell_lavland_hav_pre column=a_a_hoeyde,hoeyde --verbose
v.db.renamecolumn map=N50_2013_arealdekke_pol_fjell_lavland_hav_pre column=a_a_objtype,objtype --verbose
v.db.renamecolumn map=N50_2013_arealdekke_pol_fjell_lavland_hav_pre column=a_a_oppd_dato,oppd_dato --verbose
v.db.renamecolumn map=N50_2013_arealdekke_pol_fjell_lavland_hav_pre column=a_a_vannbr,vannbr --verbose
v.db.renamecolumn map=N50_2013_arealdekke_pol_fjell_lavland_hav_pre column=a_a_vatnlnr,vatnlnr --verbose
v.db.renamecolumn map=N50_2013_arealdekke_pol_fjell_lavland_hav_pre column=a_a_kommune,kommune --verbose
v.db.renamecolumn map=N50_2013_arealdekke_pol_fjell_lavland_hav_pre column=a_a_ajour,ajour --verbose
v.db.renamecolumn map=N50_2013_arealdekke_pol_fjell_lavland_hav_pre column=a_b_value,fjell --verbose
v.db.dropcolumn map=N50_2013_arealdekke_pol_fjell_lavland_hav_pre columns=a_cat,a_a_cat,a_b_cat,b_cat

v.extract --o --verbose input=N50_2013_arealdekke_pol_fjell_lavland_hav where="resultat_ID IS NOT NULL" output=N50_2013_arealdekke_pol_fjell_lavland_hav_final

v.dissolve --overwrite --verbose input=N50_2013_arealdekke_pol_fjell_lavland_hav_final column=resultat_ID output=MD_resultatomraader
v.dissolve --overwrite --verbose input=N50_2013_arealdekke_pol_fjell_lavland_hav_final column=NI_ID output=NI_naturtyper

#Add descriptive column to MD_resultatomraader
v.db.addcolumn map=MD_resultatomraader column="areal_ha double precision"
echo "UPDATE MD_resultatomraader SET resultat = \
CASE \
WHEN cat==10 THEN 'Levende hav og kyst' \
WHEN cat==20 THEN 'Livskraftige elver og innsjøer' \
WHEN cat==30 THEN 'Frodige våtmarker' \
WHEN cat==40 THEN 'Mangfoldige skoger' \
WHEN cat==50 THEN 'Storslått fjellandskap' \
WHEN cat==60 THEN 'Verdifulle kulturminner og rikt kulturlandskap' \
WHEN cat==70 THEN 'Godt bymiljø' \
ELSE 'Annet' \
END;" | db.execute input=-

#Add descriptive column to NI_naturtyper
v.db.addtable map=NI_naturtyper columns="NI text"
echo "UPDATE NI_naturtyper SET NI = \
CASE \
WHEN cat==10 THEN 'Indre havområder (kystvann)' \
WHEN cat==11 THEN 'Ytre havområder' \
WHEN cat==20 THEN 'Ferskvann' \
WHEN cat==30 THEN 'Myr og vannkant' \
WHEN cat==40 THEN 'Skog' \
WHEN cat==50 THEN 'Fjell' \
WHEN cat==60 THEN 'Åpent lavland' \
ELSE 'Annet' \
END;" | db.execute input=-


v.db.addcolumn map=NI_naturtyper column="NI text"
echo "UPDATE NI_naturtyper SET NI = \
CASE \
WHEN cat==10 THEN 'Indre havområder (kystvann)' \
WHEN cat==11 THEN 'Ytre havområder' \
WHEN cat==20 THEN 'Ferskvann' \
WHEN cat==30 THEN 'Myr og vannkant' \
WHEN cat==40 THEN 'Skog' \
WHEN cat==50 THEN 'Fjell' \
WHEN cat==60 THEN 'Åpent lavland' \
ELSE 'Annet' \
END;" | db.execute input=-

v.out.ogr -s --verbose input=MD_resultatomraader type=auto dsn=/home/stefan/Okokart/MD_resultatomraader.gdb format=FileGDB
v.out.ogr -s --verbose input=NI_naturtyper type=auto dsn=/home/stefan/Okokart/NI_naturtyper.gdb format=FileGDB

#test
v.db.addtable map=MD_resultatomraader columns="resultat_ID integer, resultat varchar(250)"
echo "UPDATE MD_resultatomraader SET resultat_ID = cat;" | db.execute input=-
echo "UPDATE MD_resultatomraader SET resultat = \
CASE \
WHEN cat==10 THEN 'Levende hav og kyst' \
WHEN cat==20 THEN 'Livskraftige elver og innsjøer' \
WHEN cat==30 THEN 'Frodige våtmarker' \
WHEN cat==40 THEN 'Mangfoldige skoger' \
WHEN cat==50 THEN 'Storslått fjellandskap' \
WHEN cat==60 THEN 'Verdifulle kulturminner og rikt kulturlandskap' \
WHEN cat==70 THEN 'Godt bymiljø' \
ELSE 'Annet' \
END;" | db.execute input=-

v.out.ogr -s --verbose input=MD_resultatomraader@Oekokart type=auto dsn=/home/stefan/Okokart/MD_resultatomraader.gdb format=FileGDB

v.out.ogr -s --verbose input=NI_naturtyper type=auto dsn=/home/stefan/Okokart/NI_naturtyper.gdb format=FileGDB
v.out.ogr -s --verbose input=N50_2013_arealdekke_pol_fjell_lavland_hav_pre@Oekokart type=auto dsn=/home/stefan/Okokart/N50_nyinndeling_naturtyper.gdb format=FileGDB


g.region -p rast=DEM_10m res=20
r.resamp.stats --overwrite --verbose input=modell_3g_avg@m3g output=modell_3g_avg_20m method=average
r.mapcalc expression="modell_3g_avg_20m_int=round(modell_3g_avg_20m*100.0)" --v --o
r.out.gdal -c --verbose input=modell_3g_avg_20m_int type=UInt16 output=/home/stefan/Okokart/skoggrense_20m.tif createopt="PROFILE=BASELINE,COMPRESS=LZW,TFW=YES,PREDICTOR=2,BIGTIFF=YES"
