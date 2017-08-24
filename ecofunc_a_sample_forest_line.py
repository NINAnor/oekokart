#!/usr/bin/env python

import grass.script as grass

# CREATE SAMPLES OF FOREST LINE
# MEADIN VALUE
# NOT USED

def main():
    r_height = 'dem_10m_nosefi_float@g_Elevation_Fenoscandia'
    
    # forest line 0-1
    r_forest_line = 'forest_line_fenoscandia_10m'

    # set computational region
    grass.run_command('g.region', raster = r_forest_line)
    
    # set mask
    grass.run_command('r.mask', raster = r_forest_line, overwrite=True)

    # compute median value of forest line in neighbourhood
    r_forest_line_median = 'temp_forest_line_height_median'
    size = 51
    grass.run_command('r.neighbors', overwrite=True, input=r_height,
                      selection=r_forest_line, output=r_forest_line_median,
                      method='median', size=size)
 
    # sampling: leave only medians of neighbourhood
    r_forest_line_sampled = 'temp_forest_line_sampled'
    grass.run_command('r.mapcalc', overwrite=True, expression='{}= \
                      if(abs({}-{})<=0.05,{},null())'.format(\
                      r_forest_line_sampled,r_height,r_forest_line_median,\
                      r_height))

    # remove mask
    grass.run_command('r.mask', flags='r')

    # remove temporary files
    grass.run_command('g.remove', type='raster', flags='f', 
                      name=r_forest_line_median)

if __name__ == '__main__':
    main()
