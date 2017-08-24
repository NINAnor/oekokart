#!/usr/bin/env python

import grass.script as grass

# SOLAR RADIATION

def main():
    # merge tiles
    
    # yearly layer
    r_sorad_year = "solar_radiation_10m_year"
    layers_sorad_year=grass.parse_command('g.list', type='raster', 
                                          separator='newline',
                                          pattern='GlobalRadiation_10m_doy_*',
                                          mapset='g_EnergyResources_SolarRadiation')
    
    #expression_year = ''
    for layer in layers_sorad_year:
        expression_year = '{}+{}@g_EnergyResources_SolarRadiation'.format(\
                          expression_year,layer)
    
    grass.run_command('r.mapcalc', overwrite=True,
                      expression=r_sorad_year+'='+expression_year[1:])
    
    # seasonal layers
    r_sorad_spring = "solar_radiation_10m_spring"
    r_sorad_summer = "solar_radiation_10m_summer"
    r_sorad_autumn = "solar_radiation_10m_autumn"
    r_sorad_winter = "solar_radiation_10m_winter"
    r_sorad_january = "solar_radiation_10m_january"
    r_sorad_april = "solar_radiation_10m_april"
    r_sorad_july = "solar_radiation_10m_july"
    r_sorad_october = "solar_radiation_10m_october"

    layers_sorad_spring = grass.parse_command('g.list', type='raster',
                                              separator='newline',
                                              pattern='GlobalRadiation_10m_doy_(0[8-9][0-9]|1[0-6][0-9]|170)', 
                                              mapset='g_EnergyResources_SolarRadiation', 
                                              flags='e')
    layers_sorad_summer = grass.parse_command('g.list', type='raster',
                                              separator='newline', 
                                              pattern='GlobalRadiation_10m_doy_(175|1[8-9][0-9]|2[0-6][0-9])', 
                                              mapset='g_EnergyResources_SolarRadiation', 
                                              flags='e')
    layers_sorad_autumn = grass.parse_command('g.list', type='raster',
                                              separator='newline', 
                                              pattern='GlobalRadiation_10m_doy_(2[7-9][0-9]|3[0-4][0-9]|350)', 
                                              mapset='g_EnergyResources_SolarRadiation', 
                                              flags='e')
    layers_sorad_winter = grass.parse_command('g.list', type='raster',
                                              separator='newline', 
                                              pattern='GlobalRadiation_10m_doy_(355|36[0-9]|0[0-7][0-9])', 
                                              mapset='g_EnergyResources_SolarRadiation', 
                                              flags='e')
    layers_sorad_january = grass.parse_command('g.list', type='raster',
                                               separator='newline',
                                               pattern='GlobalRadiation_10m_doy_(005|010|015|020|025|030)', 
                                               mapset='g_EnergyResources_SolarRadiation',
                                               flags='e')
    layers_sorad_april   = grass.parse_command('g.list', type='raster',
                                               separator='newline',
                                               pattern='GlobalRadiation_10m_doy_(095|100|105|110|115|120)', 
                                               mapset='g_EnergyResources_SolarRadiation',
                                               flags='e')
    layers_sorad_july    = grass.parse_command('g.list', type='raster',
                                               separator='newline',
                                               pattern='GlobalRadiation_10m_doy_(185|190|195|200|205|210)', 
                                               mapset='g_EnergyResources_SolarRadiation',
                                               flags='e')
    layers_sorad_october = grass.parse_command('g.list', type='raster',
                                               separator='newline',
                                               pattern='GlobalRadiation_10m_doy_(275|280|285|290|295|300)', 
                                               mapset='g_EnergyResources_SolarRadiation',
                                               flags='e')
    expression_spring = ''
    expression_summer = ''
    expression_autumn = ''
    expression_winter = ''
    expression_january = ''
    expression_april = ''
    expression_july = ''
    expression_october = ''

    for layer in layers_sorad_spring:
        expression_spring = '{}+{}@g_EnergyResources_SolarRadiation'.format(\
                            expression_spring,layer)
    for layer in layers_sorad_summer:
        expression_summer = '{}+{}@g_EnergyResources_SolarRadiation'.format(\
                            expression_summer,layer)
    for layer in layers_sorad_autumn:
        expression_autumn = '{}+{}@g_EnergyResources_SolarRadiation'.format(\
                            expression_autumn,layer)
    for layer in layers_sorad_winter:
        expression_winter = '{}+{}@g_EnergyResources_SolarRadiation'.format(\
                            expression_winter,layer)
    for layer in layers_sorad_january:
        expression_january = '{}+{}@g_EnergyResources_SolarRadiation'.format(\
                             expression_january,layer)
    for layer in layers_sorad_april:
        expression_april = '{}+{}@g_EnergyResources_SolarRadiation'.format(\
                           expression_april,layer)
    for layer in layers_sorad_july:
        expression_july = '{}+{}@g_EnergyResources_SolarRadiation'.format(\
                          expression_july,layer)
    for layer in layers_sorad_october:
        expression_october = '{}+{}@g_EnergyResources_SolarRadiation'.format(\
                             expression_october,layer)
    
    grass.run_command('r.mapcalc', overwrite=True, 
                      expression=r_sorad_spring+'='+expression_spring[1:])
    grass.run_command('r.mapcalc', overwrite=True, 
                      expression=r_sorad_summer+'='+expression_summer[1:])
    grass.run_command('r.mapcalc', overwrite=True, 
                      expression=r_sorad_autumn+'='+expression_autumn[1:])
    grass.run_command('r.mapcalc', overwrite=True, 
                      expression=r_sorad_winter+'='+expression_winter[1:])
    grass.run_command('r.mapcalc', overwrite=True, 
                      expression=r_sorad_january+'='+expression_january[1:])
    grass.run_command('r.mapcalc', overwrite=True, 
                      expression=r_sorad_april+'='+expression_april[1:])
    grass.run_command('r.mapcalc', overwrite=True, 
                      expression=r_sorad_july+'='+expression_july[1:])
    grass.run_command('r.mapcalc', overwrite=True, 
                      expression=r_sorad_october+'='+expression_october[1:])


if __name__ == '__main__':
    main()
