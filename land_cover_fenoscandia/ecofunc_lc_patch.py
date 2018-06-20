#!/usr/bin/env python

"""
NAME:    Patch tiles of forest and open land cover

AUTHOR(S): Zofie Cimburova < zofie.cimburova AT nina.no>

PURPOSE:   Patch tiles of forest and open land cover.
"""

"""
To Dos:
"""

import grass.script as grass

def main():

    # 1. PATCH FILTERED TILES TOGETHER
    r_height = 'dem_10m_nosefi_float@g_Elevation_Fenoscandia'
    first_tiles = 'temp_lc_cleaned_49,temp_lc_cleaned_50'
    grass.run_command('g.region', raster=first_tiles)
    
    # patch first tile
    r_land_cover = 'landcover_forest_open_fenoscandia_10m'
    grass.run_command('r.patch', input=first_tiles, 
                      output=r_land_cover, overwrite=True)

    tiles=grass.parse_command('g.list', type='raster', 
                              pattern='temp_lc_cleaned_*',
                              mapset='u_zofie.cimburova')
    tile_list=[r_land_cover]

    # go through tiles
    index_list = list(range(25702))
    for index in index_list:
        index=index+1
        tile = 'temp_lc_cleaned_{}'.format(str(index))
        grass.run_command('g.region', raster=tile)

        # find if tile contains any information
        stats = grass.parse_command('r.stats', flags='c', input=tile)

        # if tile contains any information
        if len(stats.keys()) > 1:
            print 'tile {} added as {}-th item. {} tiles left to process'.format(tile, len(tile_list), 25702-index)
            tile_list.append(tile)

            # when there is enough tiles in list, patch them
            if len(tile_list)==500:
                grass.run_command('g.region', raster=tile_list)
                grass.run_command('r.patch', input=tile_list, 
                                 output=r_land_cover,overwrite=True)
                tile_list=[r_land_cover]
        else:
            print 'tile {} skipped'.format(tile)

    # patch rest of tiles
    grass.run_command('g.region', raster=r_height)
    grass.run_command('r.patch', input=tile_list, output=r_land_cover,overwrite=True)


if __name__ == '__main__':
    main()
