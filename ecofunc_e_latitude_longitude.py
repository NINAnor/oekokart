#!/usr/bin/env python

import grass.script as grass

# LATITUDE AND LONGITUDE 

def main():
    #--------------------------------------------------------------------#
    #---------------- MERGE LONGITUDE AND LATITUDE TILES ----------------#
    #--------------------------------------------------------------------#
    r_longitude_10 = 'longitude_10m'
    
    # merge in 4 groups - all are too much to load
    layers_long1 = grass.parse_command('g.list', type='raster', separator='comma', pattern='*longitude_tile_0[0,1,2,3]*', mapset='g_EnergyResources_SolarRadiation')
    #grass.run_command('r.patch', overwrite=True, input=layers_long1, output='longitude_10m_1')

    layers_long2 = grass.parse_command('g.list', type='raster', separator='comma', pattern='*longitude_tile_0[4,5,6]*', mapset='g_EnergyResources_SolarRadiation')
    #grass.run_command('r.patch', overwrite=True, input=layers_long2, output='longitude_10m_2')

    layers_long3 = grass.parse_command('g.list', type='raster', separator='comma', pattern='*longitude_tile_0[7,8,9]*', mapset='g_EnergyResources_SolarRadiation')
    #grass.run_command('r.patch', overwrite=True, input=layers_long3, output='longitude_10m_3')

    layers_long4 = grass.parse_command('g.list', type='raster', separator='comma', pattern='*longitude_tile_1*', mapset='g_EnergyResources_SolarRadiation')
    #grass.run_command('r.patch', overwrite=True, input=layers_long4, output='longitude_10m_4')

    # merge groups and delete temporary files
    #grass.run_command('r.patch', overwrite=True, input='longitude_10m_1,longitude_10m_2,longitude_10m_3,longitude_10m_4', output=r_longitude_10)
    #grass.run_command('g.remove', type='raster', name='longitude_10m_1,longitude_10m_2,longitude_10m_3,longitude_10m_4', flags='f')

    r_latitude_10 = 'latitude_10m'

    # merge in 4 groups - all are too much to load
    #layers_lat1 = grass.parse_command('g.list', type='raster', separator='comma', pattern='*latitude_tile_0[0,1,2,3]*', mapset='g_EnergyResources_SolarRadiation')
    #grass.run_command('r.patch', overwrite=True, input=layers_lat1, output='latitude_10m_1')

    #layers_lat2 = grass.parse_command('g.list', type='raster', separator='comma', pattern='*latitude_tile_0[4,5,6]*', mapset='g_EnergyResources_SolarRadiation')
    #grass.run_command('r.patch', overwrite=True, input=layers_lat2, output='latitude_10m_2')

    #layers_lat3 = grass.parse_command('g.list', type='raster', separator='comma', pattern='*latitude_tile_0[7,8,9]*', mapset='g_EnergyResources_SolarRadiation')
    #grass.run_command('r.patch', overwrite=True, input=layers_lat3, output='latitude_10m_3')

    #layers_lat4 = grass.parse_command('g.list', type='raster', separator='comma', pattern='*latitude_tile_1*', mapset='g_EnergyResources_SolarRadiation')
    #grass.run_command('r.patch', overwrite=True, input=layers_lat4, output='latitude_10m_4')
    
    #layers_lat = grass.parse_command('g.list', type='raster', pattern='*latitude*', mapset='g_EnergyResources_SolarRadiation')
    #grass.run_command('r.patch', overwrite=True, input=layers_lat, output=r_latitude_10)

    # merge groups and delete temporary files
    #grass.run_command('r.patch', overwrite=True, input='latitude_10m_1,latitude_10m_2,latitude_10m_3,latitude_10m_4', output=r_latitude_10)
    #grass.run_command('g.remove', type='raster', name='latitude_10m_1,latitude_10m_2,latitude_10m_3,latitude_10m_4', flags='f')


if __name__ == '__main__':
    main()
