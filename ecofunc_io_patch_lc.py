#!/usr/bin/env python

import grass.script as grass

# PREPARE FOREST AND OPEN LAND FOR SAMPLING

def main():

    # 1. PATCH FILTERED TILES TOGETHER
    #r_height = 'dem_10m_nosefi_float@g_Elevation_Fenoscandia'
    #first_tiles = 'temp_lc_cleaned_49,temp_lc_cleaned_50'
    #grass.run_command('g.region', raster=first_tiles)
    
    # patch first tile
    r_land_cover = 'landcover_forest_open_fenoscandia_10m'
    #grass.run_command('r.patch', input=first_tiles, 
    #                  output=r_land_cover, overwrite=True)

    #tiles=grass.parse_command('g.list', type='raster', 
    #                          pattern='temp_lc_cleaned_*',
    #                          mapset='u_zofie.cimburova')
    #tile_list=[r_land_cover]

    # go through tiles
    #index_list = list(range(25702))
    #for index in index_list:
    #    index=index+1
    #    tile = 'temp_lc_cleaned_{}'.format(str(index))
    #    grass.run_command('g.region', raster=tile)

        # find if tile contains any information
    #    stats = grass.parse_command('r.stats', flags='c', input=tile)

        # if tile contains any information
    #    if len(stats.keys()) > 1:
    #        print 'tile {} added as {}-th item. {} tiles left to process'.format(tile, len(tile_list), 25702-index)
    #        tile_list.append(tile)

            # when there is enough tiles in list, patch them
    #        if len(tile_list)==500:
    #            grass.run_command('g.region', raster=tile_list)
    #            grass.run_command('r.patch', input=tile_list, 
    #                              output=r_land_cover,overwrite=True)
    #            tile_list=[r_land_cover]
    #    else:
    #        print 'tile {} skipped'.format(tile)

    # patch rest of tiles
    #grass.run_command('g.region', raster=r_height)
    #grass.run_command('r.patch', input=tile_list, output=r_land_cover,overwrite=True)


    # 2. EXTRACT MOUNTANEOUS AREAS WITH 100 km BUFFER
    r_land_cover_reclassed = 'temp_open'
    
    # extract only open land
    #grass.run_command('r.reclass', overwrite=True, input=r_land_cover, 
    #                  output=r_land_cover_reclassed,
    #                  rules='/data/home/zofie.cimburova/ECOFUNC/CODES/reclass.txt')
    
    # tile to 100 km + 120 km + 100 km (max = 32000 pix)
    #grass.run_command('r.tile', input=r_land_cover_reclassed, 
    #                  output=r_land_cover_reclassed, width=12000,
    #                  height=12000, overlap=10000)

    # buffer for each tile
    #tile_list = grass.parse_command('g.list', type='raster', 
    #                              pattern='temp_open-*') 
    #for tile in tile_list:
        # set comp. region to tile
    #    grass.run_command('g.region', raster=tile)
        
        # check if tile contains anything
    #    stats = grass.parse_command('r.stats', flags='c', input=tile)
        
        # if tile contains any information
    #    tile_buffer = 'tile_open_buffer{}'.format(tile[9:])
    #    tile_buffer = tile_buffer.replace('-','_')
    #    print tile_buffer
    #    if len(stats.keys()) > 1:
    #        print 'tile {} contains open land, file {} created'.format(tile, tile_buffer)
    #        grass.run_command('r.grow', overwrite=True, input=tile,
    #                          output=tile_buffer, radius=10000,
    #                          old=1, new=1)
    #    else: 
    #        print 'tile {} contains nothing'.format(tile)


    # patch first raster
    r_mountain_areas = 'mountain_areas_10m'
    #grass.run_command('g.region', raster=r_land_cover_reclassed)
    #tile_list = []

    #for i in range(14):
    #    for j in range(14):
    #        tile = 'tile_open_buffer_{}_{}'.format(str(i).zfill(3),str(j).zfill(3))

    #        # check if tile exists
    #        exists = grass.find_file(tile, element = 'cell', mapset='g_LandCover_Fenoscandia')

    #        if exists['fullname']:
    #            print '{} exists. Patching.'.format(tile)
    #            tile_list.append(tile)
    #        else:
    #            print '{} does not exist. Skipping.'.format(tile)
    # patch
    #grass.run_command('r.patch', input=tile_list, 
    #                  output=r_mountain_areas, overwrite=True)

    # remove tiles of buffer
    #grass.run_command('g.remove', flags='f', type='raster',
    #                  pattern='tile_open_buffer_*')

    # remove tiles of open land
    #grass.run_command('g.remove', flags='f', type='raster',
    #                  pattern='temp_open-*')

    # remove open land raster
    #grass.run_command('g.remove', flags='f', type='raster',
    #                  name=r_land_cover_reclassed)

    # 3. CREATE SAMPLES IN MOUNTAIN AREAS
    # create mask
    grass.run_command('r.mask', raster=r_mountain_areas)

    # create samples




if __name__ == '__main__':
    main()
