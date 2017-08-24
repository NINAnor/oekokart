#!/usr/bin/env python

import grass.script as grass

# IMPORT RESULTS FROM R

def main():

    file_name = '/data/home/zofie.cimburova/ECOFUNC/DATA/temp_height_GLS2.tif'
    r_forest_height = 'r_forest_height_GLS5'
    #grass.run_command('r.import', input=file_name, output=r_forest_height, overwrite=True)
   


    # extract forest - lower than forest height
    #         open land - higher than forest height
    #         forest line - equal to forest height
    r_forest_predicted = 'forest_predict_GLS5'
    #grass.run_command('r.mapcalc', overwrite=True, expression=r_forest_predicted+'=\
    #                 if('+r_height+'-'+r_forest_height+'.1>1, 1, if('+r_height+'-'+r_forest_height+'.1<-1,2,3))')

    #grass.run_command('r.mapcalc', overwrite=True, expression=r_forest_predicted+'='+r_height+'-'+r_forest_height)



if __name__ == '__main__':
    main()
