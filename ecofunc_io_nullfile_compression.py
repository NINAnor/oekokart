#!/usr/bin/env python

import grass.script as grass
import os.path

# compress null files

def main():

    # choose mapset
    mapset='g_Elevation_Fenoscandia_TOPEX'

    grass.run_command('g.mapset', mapset=mapset)
    maps = grass.parse_command('g.list', type='raster', mapset=mapset)

    # go through maps in mapset
    for map in maps:
        nullfile = '/data/grassdata/ETRS_33N/'+mapset+'/cell_misc/'+map+'/null'
        
        # check if map contains uncompressed nullfile
        if(os.path.isfile(nullfile)): 
            grass.run_command('r.null', flags='z', map=map) 
        else:
            print 'nullfile of {} compressed'.format(map)





if __name__ == '__main__':
    main()
