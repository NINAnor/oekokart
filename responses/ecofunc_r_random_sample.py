#!/usr/bin/env python

"""
NAME:    Filter forest, sample and extract values

AUTHOR(S): Zofie Cimburova < zofie.cimburova AT nina.no>

PURPOSE:   Filter forest - usign median of forest line height, 
           sample points - random sampling,
           extract values - to attribute table.
"""

"""
To Dos:
"""
import grass.script as grass


def main():
    
    r_height = 'dem_10m_nosefi_float@g_Elevation_Fenoscandia'
    r_forest_open = 'forest_open_fenoscandia_10m@g_LandCover_Fenoscandia'
    r_forest_line = 'forest_line_fenoscandia_10m@g_LandCover_Fenoscandia'
    r_mountains = 'mountain_areas_50km@g_LandCover_Fenoscandia'

    # 1. GET FOREST LINE HEIGHT (22 min)
    print "Getting forest line height..."
    
    grass.run_command('g.region', raster=r_forest_open)
    grass.run_command('r.mask', raster=r_forest_line)

    # compute height of forest line
    r_forest_line_height='temp_1_forest_line_height'
    grass.run_command('r.mapcalc', overwrite=True, expression="{} = {}".format(r_forest_line_height, r_height))

    # remove mask
    grass.run_command('r.mask', flags="r")
    
    print "...done."
    

    # 2. COMPUTE AVERAGE FOREST LINE HEIGHT IN 10 KM NEIGHBOURHOOD (12 min)
    print "Computing average forest line height in neighbourhood..."
    
    grass.run_command('g.region', res="1000")
    
    r_forest_line_height_1km = 'temp_1_forest_line_height_1km'
    grass.run_command('r.resamp.stats', overwrite=True,
                      input=r_forest_line_height, 
                      output=r_forest_line_height_1km)


    r_Q1 = 'temp_1_forest_line_Q1_height'
    r_Q3 = 'temp_1_forest_line_Q3_height'

    grass.run_command('r.neighbors', flags='ca', overwrite=True, input=r_forest_line_height_1km, output=r_Q1, method='quart1', size='301')
    grass.run_command('r.neighbors', flags='ca', overwrite=True, input=r_forest_line_height_1km, output=r_Q3, method='quart3', size='301')

    print "...done."


    # 3. FILTER OPEN AREAS AND FOREST (317 min)
    print "Filtering open areas and forest..."
    
    grass.run_command('g.region', n="6740005", s="6640005", e="280005", w="180005", res="10")
    grass.run_command('g.region', res="10")
    grass.run_command('r.mask', raster=r_forest_open)

    r_forest_open_filter = 'forest_open_filter_10m@u_zofie.cimburova'
    grass.run_command('r.mapcalc', overwrite=True,
                      expression= "{s5} = if({s3}==1 && {s4} >  {s1}+0.5*({s1}-{s2}),null(),\
                                          if({s3}==1 && {s4} <= {s1}+0.5*({s1}-{s2}),1,\
                                          if({s3}==0 && {s4} >  {s2}-0.5*({s1}-{s2}),0,\
                                          if({s3}==0 && {s4} <= {s2}-0.5*({s1}-{s2}),null(),null()))))".format(s1=r_Q3,s2=r_Q1,s3=r_forest_open,s4=r_height,s5=r_forest_open_filter))
    # remove mask
    grass.run_command('r.mask', flags="r")

    print "...done."


    # 4. RANDOMLY SELECT SAMPLE POINTS INSIDE OF FILTERED OPEN AREAS (3) AND FOREST (2)
    #    IN MOUNTAIN AREAS
    print "Selecting random points..."

    grass.run_command('r.mask', raster=r_mountains)

    npoints=2000000
    v_samples = "random_points_v_{}".format(npoints)
    grass.run_command('r.random', overwrite=True, input=r_forest_open_filter, 
                      npoints=npoints, vector=v_samples)

    grass.run_command('r.mask', flags="r")

    print "...done."


    # 5. RECORD VALUES OF EXPLANATORY VARIABLES
    print "Recording values..."

    #              

    predictors = [['dem_10m_nosefi_float@g_Elevation_Fenoscandia', 'v_elevation'],
                  ['dem_10m_nosefi_float_aspect_sin@g_Elevation_Fenoscandia', 'v_aspect_sin'],
                  ['dem_10m_nosefi_float_aspect_cos@g_Elevation_Fenoscandia', 'v_aspect_cos'],
                  ['dem_10m_nosefi_float_profc@g_Elevation_Fenoscandia', 'v_profc'],
                  ['dem_10m_nosefi_float_slope@g_Elevation_Fenoscandia', 'v_slope'],
                  ['bio01_eurolst_10m@g_Meteorology_Fenoscandia', 'v_bio01'],
                  ['bio02_eurolst_10m@g_Meteorology_Fenoscandia', 'v_bio02'],
                  ['bio10_eurolst_10m@g_Meteorology_Fenoscandia', 'v_bio10'],
                  ['bio11_eurolst_10m@g_Meteorology_Fenoscandia', 'v_bio11'],
                  ['bio12_worldclim_10m@g_Meteorology_Fenoscandia', 'v_bio12'],
                  ['bio15_worldclim_10m@g_Meteorology_Fenoscandia', 'v_bio15'],
                  ['bio18_worldclim_10m@g_Meteorology_Fenoscandia', 'v_bio18'],
                  ['bio19_worldclim_10m@g_Meteorology_Fenoscandia', 'v_bio19'],
                  ['solar_radiation_10m_year@g_EnergyResources_Fenoscandia', 'v_srad_y'],
                  ['solar_radiation_10m_winter@g_EnergyResources_Fenoscandia', 'v_srad_wi'],
                  ['solar_radiation_10m_spring@g_EnergyResources_Fenoscandia', 'v_srad_sp'],
                  ['solar_radiation_10m_summer@g_EnergyResources_Fenoscandia', 'v_srad_su'],
                  ['solar_radiation_10m_autumn@g_EnergyResources_Fenoscandia', 'v_srad_au'],
                  ['solar_radiation_10m_january@g_EnergyResources_Fenoscandia', 'v_srad_1'],
                  ['solar_radiation_10m_april@g_EnergyResources_Fenoscandia', 'v_srad_4'],
                  ['solar_radiation_10m_july@g_EnergyResources_Fenoscandia', 'v_srad_7'],
                  ['solar_radiation_10m_october@g_EnergyResources_Fenoscandia', 'v_srad_10'],
                  ['sea_distance_10m@g_SeaRegions_Fenoscandia', 'v_sea'],
                  ['sea_open_distance_50m@g_SeaRegions_Fenoscandia', 'v_sea_open'],
                  ['water_distance_50m@g_SeaRegions_Fenoscandia', 'v_water'],
                  ['dem_tpi_250_50m@g_Elevation_Fenoscandia_TPI', 'v_tpi250'],
                  ['dem_tpi_500_50m@g_Elevation_Fenoscandia_TPI', 'v_tpi500'],
                  ['dem_tpi_1000_50m@g_Elevation_Fenoscandia_TPI', 'v_tpi1000'],
                  ['dem_tpi_2500_50m@g_Elevation_Fenoscandia_TPI', 'v_tpi2500'],
                  ['dem_tpi_5000_50m@g_Elevation_Fenoscandia_TPI', 'v_tpi5000'],
                  ['dem_tpi_10000_50m@g_Elevation_Fenoscandia_TPI', 'v_tpi10000'],
                  ['dem_10m_topex_E@g_Elevation_Fenoscandia_TOPEX', 'v_topex_e'],
                  ['dem_10m_topex_SE@g_Elevation_Fenoscandia_TOPEX', 'v_topex_se'],
                  ['dem_10m_topex_S@g_Elevation_Fenoscandia_TOPEX', 'v_topex_s'],
                  ['dem_10m_topex_SW@g_Elevation_Fenoscandia_TOPEX', 'v_topex_sw'],
                  ['dem_10m_topex_W@g_Elevation_Fenoscandia_TOPEX', 'v_topex_w'],
                  ['dem_10m_topex_NW@g_Elevation_Fenoscandia_TOPEX', 'v_topex_nw'],
                  ['dem_10m_topex_N@g_Elevation_Fenoscandia_TOPEX', 'v_topex_n'],
                  ['dem_10m_topex_NE@g_Elevation_Fenoscandia_TOPEX', 'v_topex_ne'],
                  ['dem_10m_topex_exposure@g_Elevation_Fenoscandia_TOPEX', 'v_topex'],
                  ['latitude_10m@g_GeographicalGridSystems_Fenoscandia', 'v_latitude'],
                  ['longitude_10m@g_GeographicalGridSystems_Fenoscandia', 'v_longitude']]

    for predictor in predictors:
        col = predictor[1]
        var = predictor[0]
        
        print(var)

        grass.run_command('v.db.addcolumn', map=v_samples, 
                          columns='{} double precision'.format(col))
        grass.run_command('v.what.rast', map=v_samples, 
                          raster=var, column=col)   
    
    # record values of coordinates
    grass.run_command('v.db.addcolumn', map=v_samples, 
                      columns='v_x double precision,v_y double precision')
    grass.run_command('v.to.db', map=v_samples, option='coor', 
                      columns='v_x,v_y')
    print "...done."

if __name__ == '__main__':
    main()
