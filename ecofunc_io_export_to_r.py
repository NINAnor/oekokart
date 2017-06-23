#!/usr/bin/env python

import grass.script as grass

# EXPORT TO CSV FILE TO USE IN R


def main():

    table_variables = '/home/zofie.cimburova/ECOFUNC/DATA/variables.csv'
    
    # coordinates of forest line
    # dependent variable
    # limitation of forest line
    # temperature BIO11
    # precipitation BIO18
    # precipitation BIO19
    # precipitation BIO12
    # solar radiation
    # latitude
    # longitude
    # aspect
    # slope
    input_variables = r_forest_line+','+\
                      r_height+','+\
                      r_height_250_forest_diff+','+\
                      'temperature_kriged_10m.1@u_zofie.cimburova'+','+\
                      'WorldClim_current_bio18_1975@g_Meteorology_Fenoscandia_WorldClim_current'+','+\
                      'WorldClim_current_bio19_1975@g_Meteorology_Fenoscandia_WorldClim_current'+','+\
                      'WorldClim_current_bio12_1975@g_Meteorology_Fenoscandia_WorldClim_current'+','+\
                      'GlobalRadiation_10m_doy_090@g_EnergyResources_SolarRadiation'+','+\
                      'latitude_10m@u_zofie.cimburova'+','+\
                      'longitude_10m@u_zofie.cimburova'+','+\
                      'DEM_10m_Norge_aspect@PERMANENT'+','+\
                      'DEM_10m_Norge_slope@PERMANENT'+','+\
                      'dem_10m_nosefi_float_tpi_1010@u_zofie.cimburova'

    #grass.run_command('r.out.xyz', overwrite=True, input=input_variables,\
    #                  output=table_variables, separator='comma')


if __name__ == '__main__':
    main()
