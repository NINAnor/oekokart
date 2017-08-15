#!/usr/bin/env python

import grass.script as grass
import os
import sys
#from os import listdir

# EXTRACT FOREST LINE

def main():

    r_height = 'dem_10m_nosefi_float@g_Elevation_Fenoscandia'

    # go through rasterized tiles
    directory = '/home/zofie.cimburova/ECOFUNC/RASTERIZE_OVERLAP'

    #for tile in os.listdir(directory):

        #r_forest_open = os.path.splitext(tile)[0]

        # link tile
        #grass.run_command('r.external', input=os.path.join(directory,tile), output=r_forest_open, overwrite=True)

        # set computational region to tile
        #grass.run_command('g.region', raster=r_forest_open)

        # prefix for output tiles
        #prefix = r_forest_open[2:]
    
    #LC_tiles = grass.parse_command('g.list', type='raster', 
    #                               pattern='LC_tile_*',
    #                               mapset='g_LandCover_Fenoscandia')
    LC_tiles = ['LC_tile_12189']
    for r_forest_open in LC_tiles:
        prefix = r_forest_open[7:]
        
        # set computational region to tile
        grass.run_command('g.region', raster=r_forest_open)

        # ------------------------------------------------------------ #
        # 1. Exclude "outlying" forest and open land pixels
        # ------------------------------------------------------------ #
        # 1.1. Minimum area of open land / forest patch

        # group connected pixels
        r_clump = 'temp_clump' + prefix
        grass.run_command('r.clump', overwrite=True, input=r_forest_open, output=r_clump)
        
        # calculate area of connected pixels and stdev of height
        r_clump_area = 'temp_clump_area' + prefix
        r_clump_stdev = 'temp_clump_stdev' + prefix

        grass.run_command('r.stats.zonal', overwrite=True, base=r_clump, cover=r_clump, method='count', output=r_clump_area)
        grass.run_command('r.stats.zonal', overwrite=True, base=r_clump, cover=r_height, method='stddev', output=r_clump_stdev)

        # set limit for area and stdev
        limit_area = 1000 # pixels
        limit_stdev = 10

        r_forest_open_threshold = 'temp_lc_cleaned' + prefix
        grass.run_command('r.mapcalc', overwrite=True, expression=r_forest_open_threshold + '=\
                          if('+r_clump_area+'>'+str(limit_area)+',if('+r_clump_stdev+'>'+str(limit_stdev)+','+r_forest_open+',null()),null())')
        
        # ------------------------------------------------------------ #
        # 2. Extract forest line as border between forest and open land
        # ------------------------------------------------------------ #
        #r_forest_line = 'forest_line_10m' + prefix
        #grass.run_command('r.mapcalc', overwrite=True, expression=r_forest_line+'=('+r_forest_open_threshold+'== 1) * (  \
        #                  (('+r_forest_open_threshold+'[-1,-1] == 0)*('+r_height+'[-1,-1] >= '+r_height+'[0,0])) + \
        #                  (('+r_forest_open_threshold+'[-1,0]  == 0)*('+r_height+'[-1,0]  >= '+r_height+'[0,0])) + \
        #                  (('+r_forest_open_threshold+'[-1,1]  == 0)*('+r_height+'[-1,1]  >= '+r_height+'[0,0])) + \
        #                  (('+r_forest_open_threshold+'[0,-1]  == 0)*('+r_height+'[0,-1]  >= '+r_height+'[0,0])) + \
        #                  (('+r_forest_open_threshold+'[0,1]   == 0)*('+r_height+'[0,1]   >= '+r_height+'[0,0])) + \
        #                  (('+r_forest_open_threshold+'[1,-1]  == 0)*('+r_height+'[1,-1]  >= '+r_height+'[0,0])) + \
        #                  (('+r_forest_open_threshold+'[1,0]   == 0)*('+r_height+'[1,0]   >= '+r_height+'[0,0])) + \
        #                  (('+r_forest_open_threshold+'[1,1]   == 0)*('+r_height+'[1,1]   >= '+r_height+'[0,0])))' \
        #                  )
        
        # reclass to null - 1
        #grass.run_command('r.mapcalc', overwrite=True, expression=r_forest_line+'=\
        #                  if('+r_forest_line+'>0,1,null())')

        # ------------------------------------------------------------ #
        # 3. Delete temporary files
        # ------------------------------------------------------------ #
        #grass.run_command('g.remove', flags='f', type='raster', name=r_clump)
        #grass.run_command('g.remove', flags='f', type='raster', name=r_clump_area)
        #grass.run_command('g.remove', flags='f', type='raster', name=r_clump_stdev)
        #grass.run_command('g.remove', flags='f', type='raster', name=r_forest_open_threshold)

    # ------------------------------------------------------------ #
    # 5. Filter forest line
    # ------------------------------------------------------------ #
    #forest_line_tiles = grass.parse_command('g.list', type='raster', pattern='forest_line_10m_tile_*',
    #                                   mapset='g_LandCover_Fenoscandia', separator='newline')
    #for tile in forest_line_tiles:
        # 5.1. Forest line should consist of minimum number of neighbouring pixels
        #grass.run_command('g.region', raster=tile)

        # group connected pixels
        #grass.run_command('r.clump', overwrite=True, input=tile, output=tile)
    
        # compute number of pixels
        #grass.run_command('r.stats.zonal', overwrite=True, base=tile, 
        #                  cover=tile, method='count', output=tile)

        # delete sections smaller than limit
        #limit_length = 100
        #grass.run_command('r.mapcalc', overwrite=True, expression=tile+'=\
        #                  if('+tile+'>'+str(limit_length/10)+',1,null())')


    # ------------------------------------------------------------ #
    # 4. Merge forest line tiles in one raster
    # ------------------------------------------------------------ #
    # set computational region to full extent
    #grass.run_command('g.region', raster=r_height)
    #grass.run_command('g.region', n=6998298, s=6977298, e=252432, w=231432, res=10) # TEST
    
    # merge tiles
    # needs to be performed by sections, because maximum length of list is too long

    #forest_line_tiles = grass.parse_command('g.list', type='raster', pattern='forest_line_10m_tile_*',
    #                                   mapset='g_LandCover_Fenoscandia', separator='newline')
    tiles_list = []
    j = 1
    #for tile in forest_line_tiles:
        
        # only patch tiles that contain some forest line pixels (i.e. contain null and 1 values)
        #grass.run_command('g.region', raster=tile)
        #stats = grass.parse_command('r.stats', flags='c', input=tile)

        # if tile contains forest line (4324 tiles)
        #if len(stats.keys()) > 1:
        
            # append this tile to patching list
            #tiles_list.append(tile)

            # merge at maximum 500 tiles together
            #if (len(tiles_list)==500):

                #grass.run_command('g.region', raster=r_height)
                #r_forest_line_temp_patch = 'temp_forest_line_patch_'+str(j)
                #grass.run_command('r.patch', input=tiles_list, output=r_forest_line_temp_patch, overwrite=True)
                
                #tiles_list=[]
                #j = j+1

    # patch rest of tiles in tiles_list
    #grass.run_command('g.region', raster=r_height)
    #r_forest_line_temp_patch = 'temp_forest_line_patch_'+str(j)
    #grass.run_command('r.patch', input=tiles_list, output=r_forest_line_temp_patch, overwrite=True)

    # patch sections together
    #rass.run_command('g.region', raster=r_height)
    r_forest_line = 'forest_line_fenoscandia_10m'
    #forest_line_tiles_2 = grass.parse_command('g.list', type='raster', pattern='temp_forest_line_patch_*',
    #                                   mapset='g_LandCover_Fenoscandia')
    #grass.run_command('r.patch', input=forest_line_tiles_2, output=r_forest_line, overwrite=True)

    # ------------------------------------------------------------ #
    # 6. Forest line not more than X-m below median forest in N-km neighbourhood
    # 6.1 Smaller neighbourhoods - filtering the whole raster
    # ------------------------------------------------------------ #
    #grass.run_command('g.region', raster=r_height)

    # height of forest line pixel
    #grass.run_command('r.mask', raster=r_forest_line, overwrite=True)
    
    # go through various neighbourhood sizes
    #for i in [51,101,201,501]:
    #    distance = (i-1)*10/2
        
        # median height of forest line in neighbourhood
    #    r_med_height = 'temp_med_height_' + str(distance)
    #    grass.run_command('r.neighbors', flags='c', overwrite=True, 
    #                      input=r_height, selection=r_forest_line, 
    #                      output=r_med_height, method='median', size=i)
    
        # difference
    #    r_med_height_diff = 'median_height_'+ str(distance) +'_diff_10m'
    #    grass.run_command('r.mapcalc', overwrite = True, expression=r_med_height_diff+'= \
    #                      ('+r_med_height+'-'+r_height+')')
    
        # remove median height raster
    #    grass.run_command('g.remove', flags='f', type='raster', name=r_med_height)

        # create table of univariate statistics
    #    t_med_height_diff_stat = 'ECOFUNC/DATA/median_height_'+ str(distance) +'_diff_stats'
    #    stats = grass.parse_command('r.univar', overwrite=True, flags='ge', map=r_med_height_diff)
    #    Q1 = float(stats.first_quartile)
    #    Q3 = float(stats.third_quartile)
    #    min = float(stats.min)
    #    max = float(stats.max)
    #    mild_limit_min = Q1 - 1.5*(Q3-Q1)
    #    mild_limit_max = Q3 + 1.5*(Q3-Q1)
    #    extr_limit_min = Q1 - 3*(Q3-Q1)
    #    extr_limit_max = Q3 + 3*(Q3-Q1)

    #    with open(t_med_height_diff_stat, "w") as text_file:
    #        text_file.write("Min:     {}\n".format(min))
    #        text_file.write("Q1:      {}\n".format(Q1))
    #        text_file.write("Q3:      {}\n".format(Q3))
    #        text_file.write("Max:     {}\n".format(max))
    #        text_file.write("Mild:    {}\t{}\n".format(mild_limit_min, mild_limit_max))
    #        text_file.write("Extreme: {}\t{}\n".format(extr_limit_min, extr_limit_max))

    #grass.run_command('r.mask', flags='r')

    # ------------------------------------------------------------ #
    # 6. Forest line not more than X-m below median forest in N-km neighbourhood
    # 6.2 Larger neighbourhoods - filtering by tiles (i.e. comp. regions)
    # ------------------------------------------------------------ #
    #grass.run_command('g.region', raster=r_height)

    # height of forest line pixel
    #grass.run_command('r.mask', raster=r_forest_line, overwrite=True)

    # DEM used for computing median height of forest line
    #r_height_50 = 'dem_50m_nosefi@g_Elevation_Fenoscandia'

    # extent of tiling
    #tiles_dim = grass.parse_command('r.info', flags = 'g', map=r_height)
    #xmin = int(tiles_dim.west) #-77335
    #xmax = int(tiles_dim.east) #1335785
    #ymin = int(tiles_dim.south)#6132475
    #ymax = int(tiles_dim.north)#7939995
       
    # size of tiles
    #tile: 50 km x 50 km
    #tile_size = 50000
    #resamp_res = 50

    # go through various neighbourhood sizes
    #for distance in [10000,25000,50000]:
    #    neighbourhood_pix = (2*distance)/resamp_res + 1
    #    print '    neighbourhood in pixels: {}'.format(neighbourhood_pix)
    #    print '    neighbourhood in m: {}'.format(distance)

        # set comp. region with buffer equal to half of neighbourhood
    #    buffer_size_m = distance
    #    print '    buffer size in m: {}'.format(buffer_size_m)

        # tile name for difference from median height
    #    name_base = 'median_height_'+ str(distance) +'_diff_10m'
    #    print '    name base: {}'.format(name_base)
        
    #    i = 0
    #    valid_tiles = 0
    #    for x in range(xmin, xmax, tile_size):
    #        i = i+1
    #        j = 0
    #        for y in range(ymin, ymax, tile_size):
    #            j = j+1
    #            tile_xmin = x - buffer_size_m
    #            tile_xmax = x + tile_size + buffer_size_m
    #            tile_ymin = y - buffer_size_m
    #            tile_ymax = y + tile_size + buffer_size_m

                # set comp. region to tile
    #            grass.run_command('g.region', n=y+tile_size, s=y, 
    #                              e=x+tile_size, w=x, res=10)
                
                # check if tile contains anything
    #            stats = grass.parse_command('r.univar', flags='g', map=r_forest_line)

    #            if len(stats) > 0:
    #                valid_tiles = valid_tiles + 1

                    # increase computational region, set resolution to 50 m
    #                grass.run_command('g.region', n=tile_ymax, s=tile_ymin, 
    #                                  e=tile_xmax, w=tile_xmin, res=resamp_res,
    #                                  align=r_height_50)
                    
                    # resample forest line to 50 m
    #                r_forest_line_50 = 'temp_fl_50m'
    #                grass.run_command('r.resamp.stats', overwrite=True,
    #                                  input=r_forest_line, output=r_forest_line_50,
    #                                  method='maximum')
                    # change mask
    #                grass.run_command('r.mask', overwrite=True, raster=r_forest_line_50)

                    # median height of forest line in neighbourhood
    #                r_med_height = 'temp_med_height_' + str(distance)
    #                grass.run_command('r.neighbors', flags='c', overwrite=True, 
    #                                  input=r_height_50, selection=r_forest_line_50, 
    #                                  output=r_med_height, method='median', 
    #                                  size=neighbourhood_pix)
                    
                    # remove buffer from computationl region
    #                grass.run_command('g.region', n=y+tile_size, s=y, 
    #                                  e=x+tile_size, w=x, res=10)
    #                grass.run_command('r.mask', overwrite=True, raster=r_forest_line)

                    # difference of median height and actual height
    #                r_med_height_diff_t = name_base+'_'+str(i)+'_'+str(j)
    #                grass.run_command('r.mapcalc', overwrite = True, 
    #                                  expression=r_med_height_diff_t+'= \
    #                                  ('+r_med_height+'-'+r_height_50+')')
                    
                    # remove median height raster and resampled forest line
    #                grass.run_command('g.remove', flags='f', type='raster', name=r_med_height)
    #                grass.run_command('g.remove', flags='f', type='raster', name=r_forest_line_50)
        
    #    print "number of valid tiles for neighbourhood " + str(distance) + ' is ' + str(valid_tiles)
        
        # patch
    #    grass.run_command('g.region', raster=r_height)

    #    r_med_height_diff = name_base
    #    tiles_med_height_diff = grass.parse_command('g.list', type='raster', 
    #                                                pattern=name_base+'_*',
    #                                                mapset='g_LandCover_Fenoscandia', 
    #                                                separator='newline')
    #    grass.run_command('r.patch', input=tiles_med_height_diff, 
    #                      output=r_med_height_diff, overwrite=True)

        # remove tiles
        #grass.run_command('g.remove', flags='f', type='raster', name=tiles_med_height_diff)

        # create table of univariate statistics
    #    t_med_height_diff_stat = 'ECOFUNC/DATA/'+name_base+'_stats'
    #    stats = grass.parse_command('r.univar', overwrite=True, flags='ge', map=r_med_height_diff)
    #    Q1 = float(stats.first_quartile)
    #    Q3 = float(stats.third_quartile)
    #    min = float(stats.min)
    #    max = float(stats.max)
    #    mild_limit_min = Q1 - 1.5*(Q3-Q1)
    #    mild_limit_max = Q3 + 1.5*(Q3-Q1)
    #    extr_limit_min = Q1 - 3*(Q3-Q1)
    #    extr_limit_max = Q3 + 3*(Q3-Q1)

    #    with open(t_med_height_diff_stat, "w") as text_file:
    #        text_file.write("Min:     {}\n".format(min))
    #        text_file.write("Q1:      {}\n".format(Q1))
    #        text_file.write("Q3:      {}\n".format(Q3))
    #        text_file.write("Max:     {}\n".format(max))
    #        text_file.write("Mild:    {}\t{}\n".format(mild_limit_min, mild_limit_max))
    #        text_file.write("Extreme: {}\t{}\n".format(extr_limit_min, extr_limit_max))

    #grass.run_command('r.mask', flags='r')


if __name__ == '__main__':
    main()
