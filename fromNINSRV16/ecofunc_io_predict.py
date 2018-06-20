#!/usr/bin/env python

import grass.script as grass
import numpy as np

# IMPORT COEFFICIENTS OF PREDICTORS COMPUTED IN R


def main():
    r_mask = 'temp_mask_landcover_count'
    r_landcover = 'forest_open_fenoscandia_10m@g_LandCover_Fenoscandia'
    
    # mask
    grass.run_command('r.mask', raster=r_mask, overwrite=True)

    # sample region
    #grass.run_command('g.region', n=7020000, s=6970000, e=232000, w=182000, 
    #                  res=10)
    
    # region
    grass.run_command('g.region', raster=r_landcover)
    
    # load coefficients from table
    table = '/home/zofie.cimburova/ECOFUNC/DATA/OBSERVATIONS/fixed_effects_coefficients.csv'
    coefficients = np.genfromtxt(table, skip_header=1, delimiter=',', 
                                 dtype=None)

    r_height = 'dem_10m_nosefi_float@g_Elevation_Fenoscandia'
    r_sqrt_height = 'temp_sqrt_height'
    grass.run_command('r.mapcalc',
                      expression='{}=if({}<0,-1,1)*sqrt(abs({}))'.format(r_sqrt_height,r_height,r_height),
                      overwrite=True)

    predictors = ['pow(water_distance_50m@g_SeaRegions_Fenoscandia,1/3)',
                  'dem_10m_nosefi_float_profc@g_Elevation_Fenoscandia',
                  'log(dem_10m_nosefi_float_slope@g_Elevation_Fenoscandia+1)',
                  'bio10_eurolst_10m@g_Meteorology_Fenoscandia',
                  'bio15_worldclim_10m@g_Meteorology_Fenoscandia',
                  'bio19_worldclim_10m@g_Meteorology_Fenoscandia',
                  'dem_tpi_10000_50m@g_Elevation_Fenoscandia_TPI',
                  'log(dem_10m_topex_exposure@g_Elevation_Fenoscandia_TOPEX+1)',
                  'bio02_eurolst_10m@g_Meteorology_Fenoscandia',
                  r_sqrt_height]

    r_prediction = 'forest_open_predict2_10m'
    expression = '{}=({})+'.format(r_prediction,coefficients[0][1]) 

    # create a mapcalc expression
    # intercept + sum (beta*(X-mu)/sigma) 
    i = 1
    for predictor in predictors:
        expression = expression + '({})*({}-({}))/({})+'.format(\
                     coefficients[i][1],predictor,coefficients[i][2],\
                     coefficients[i][3])
        i = i+1
    expression = expression[:-1]

    # compute probability of forest
    grass.run_command('r.mapcalc',expression=expression, overwrite=True)
    #grass.run_command('r.mapcalc',expression='{}=exp({})/(1+exp({}))'.format(\
    #                   r_prediction,r_prediction,r_prediction),overwrite=True)

    # compute residuals
    #r_residuals = 'forest_open_residuals_10m'
    #grass.run_command('r.mapcalc', expression= "{}={}-{}".format(\
    #                  r_residuals,r_prediction,r_landcover),overwrite=True)


if __name__ == '__main__':
    main()
