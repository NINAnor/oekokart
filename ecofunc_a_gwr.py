#!/usr/bin/env python

import grass.script as grass

# GWR IN GRASS

def main():

    # observation points - take height within limit
    r_observations = 'observation_points_10m'
    #grass.run_command('r.mapcalc', overwrite=True, expression=r_observations+'=('\
    #                  +r_forest_line+'*'+r_height+')')

    #grass.run_command('r.mapcalc', overwrite=True, expression=r_observations+'=\
    #                  if('+r_height_250_forest_diff+'<=15,'+r_observations+',null())')
    
    # GRW
    r_grw = 'gwr_estimates'
    #grass.run_command('r.gwr', overwrite=True, mapx='temperature_kriged_10m.1@u_zofie.cimburova,dem_10m_nosefi_float_tpi_1010@u_zofie.cimburova', \
    #                  mapy=r_observations,\
    #                  residuals='gwr_residuals',\
    #                  estimates='gwr_estimates',\
    #                  coefficients='gwr_ output=/data/home/zofie.cimburova/ECOFUNC/DATA/gwr_coefficients',\
    #                  bandwidth=1000)

    # difference
    #grass.run_command('r.mapcalc', overwrite=True, expression='temp_pred_height_difference_GWR='+r_height+'-'+r_grw)




if __name__ == '__main__':
    main()
