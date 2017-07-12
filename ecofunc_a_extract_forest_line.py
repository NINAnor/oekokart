#!/usr/bin/env python

import grass.script as grass

# EXTRACT FOREST LINE

def main():

    # computational region for test cases
    grass.run_command('g.region', n=7045175, s=7038355, e=207745, w=202175, res=10)
    

    r_height = 'dem_10m_nosefi_float@g_Elevation_Fenoscandia'
    r_forest_open = 'forest_open_10m'
    r_land_cover = 'temp_norway@u_zofie.cimburova'

    # ------------------------------------------------------------ #
    # 1. Exclude land cover pixels other than forest and open land
    # ------------------------------------------------------------ #
    #grass.run_command('r.mapcalc', overwrite=True, expression=r_forest_open + '= \
    #                 if('+r_land_cover+'==800,8,if('+r_land_cover+'==700,7,null()))')

    
    # ------------------------------------------------------------ #
    # 2. Exclude "outlying" forest and open land pixels
    # ------------------------------------------------------------ #
    # 2.1. Minimum area of open land / forest patch

    # group connected pixels
    r_clump = 'temp_clump'
    #grass.run_command('r.clump', overwrite=True, input=r_forest_open, output=r_clump)
    
    # calculate area of connected pixels and stdev of height
    r_clump_area = 'temp_clump_area'
    r_clump_stdev = 'temp_clump_stdev'

    #grass.run_command('r.stats.zonal', overwrite=True, base=r_clump, cover=r_clump, method='count', output=r_clump_area)
    #grass.run_command('r.stats.zonal', overwrite=True, base=r_clump, cover=r_height, method='stddev', output=r_clump_stdev)

    # set limit for area and stdev
    limit_area = 1000 # pixels
    limit_stdev = 10
  
    #grass.run_command('r.mapcalc', overwrite=True, expression=r_forest_open + '=\
    #                  if('+r_clump_area+'>'+str(limit_area)+',if('+r_clump_stdev+'>'+str(limit_stdev)+','+r_forest_open+',null()),null())')
    
    # ------------------------------------------------------------ #
    # 3. Extract forest line as border between forest and open land
    # ------------------------------------------------------------ #
    r_forest_line = 'forest_line_10m'
    #grass.run_command('r.mapcalc', overwrite=True, expression=r_forest_line+'=('+r_forest_open+'== 7) * (  \
    #                  (('+r_forest_open+'[-1,-1] == 8)*('+r_height+'[-1,-1] >= '+r_height+'[0,0])) + \
    #                  (('+r_forest_open+'[-1,0]  == 8)*('+r_height+'[-1,0]  >= '+r_height+'[0,0])) + \
    #                  (('+r_forest_open+'[-1,1]  == 8)*('+r_height+'[-1,1]  >= '+r_height+'[0,0])) + \
    #                  (('+r_forest_open+'[0,-1]  == 8)*('+r_height+'[0,-1]  >= '+r_height+'[0,0])) + \
    #                  (('+r_forest_open+'[0,1]   == 8)*('+r_height+'[0,1]   >= '+r_height+'[0,0])) + \
    #                  (('+r_forest_open+'[1,-1]  == 8)*('+r_height+'[1,-1]  >= '+r_height+'[0,0])) + \
    #                  (('+r_forest_open+'[1,0]   == 8)*('+r_height+'[1,0]   >= '+r_height+'[0,0])) + \
    #                  (('+r_forest_open+'[1,1]   == 8)*('+r_height+'[1,1]   >= '+r_height+'[0,0])))' \
    #                  )
    
    # reclass to null - 1
    #grass.run_command('r.mapcalc', overwrite=True, expression=r_forest_line+'=\
    #                  if('+r_forest_line+'>0,1,null())')


    # ------------------------------------------------------------ #
    # 4. Filter forest line
    # ------------------------------------------------------------ #
    # 4.1. Forest line should consist of minimum number of neighbouring pixels

    # group connected pixels
    #grass.run_command('r.clump', overwrite=True, input=r_forest_line, output=r_forest_line)
    
    # compute number of pixels
    #grass.run_command('r.stats.zonal', overwrite=True, base=r_forest_line, 
    #                  cover=r_forest_line, method='count', output=r_forest_line)

    # delete sections smaller than limit
    limit_length = 100
    #grass.run_command('r.mapcalc', overwrite=True, expression=r_forest_line+'=\
    #                  if('+r_forest_line+'>'+str(limit_length/10)+',1,null())')

    # 4.2. Forest line not more than X-m below median forest in N-km neighbourhood
    
    # height of forest line pixel
    r_fl_height = 'temp_forest_line_height'
    grass.run_command('r.mapcalc', overwrite = True, expression=r_fl_height+'= \
                     if('+r_forest_line+'==1,'+r_height+',null())')

    for i in [51,101,201,501,1001,2001,5001,10001]:
        # median height of forest line in neighbourhood
        print i
        r_med_height = 'temp_med_height_' + str(i)
        grass.run_command('r.neighbors', flags='c', overwrite=True, 
                          input=r_fl_height, selection=r_fl_height, 
                          output=r_med_height, method='median', size=i)
    
        # difference (used in R table, not in analysis)
        r_med_height_diff = 'temp_med_height_'+ str(i) +'_diff'
        grass.run_command('r.mapcalc', overwrite = True, expression=r_med_height_diff+'= \
                          ('+r_med_height+'-'+r_height+')')


if __name__ == '__main__':
    main()
