#!/usr/bin/env python

import grass.script as grass

# SOLAR RADIATION

def main():
    
    # yearly layer
    r_sorad_year = "solar_radiation_10m_year"
    layers_sorad_year = grass.parse_command('g.list', type='raster', separator='newline', pattern='GlobalRadiation_10m_doy_*', mapset='g_EnergyResources_SolarRadiation')
    
    expression_year = ''
    for layer in layers_sorad_year:
        expression_year = expression_year + '+' + layer + '@g_EnergyResources_SolarRadiation'
    
    grass.run_command('r.mapcalc', overwrite=True, expression=r_sorad_year+'='+expression_year[1:])
    
    # seasonal layers
    r_sorad_spring = "solar_radiation_10m_spring"
    r_sorad_summer = "solar_radiation_10m_summer"
    r_sorad_autumn = "solar_radiation_10m_autumn"
    r_sorad_winter = "solar_radiation_10m_winter"

    layers_sorad_spring = grass.parse_command('g.list', type='raster', separator='newline', pattern='GlobalRadiation_10m_doy_(0[8-9][0-9]|1[0-6][0-9]|170)', mapset='g_EnergyResources_SolarRadiation', flags='e')
    layers_sorad_summer = grass.parse_command('g.list', type='raster', separator='newline', pattern='GlobalRadiation_10m_doy_(175|1[8-9][0-9]|2[0-6][0-9])', mapset='g_EnergyResources_SolarRadiation', flags='e')
    layers_sorad_autumn = grass.parse_command('g.list', type='raster', separator='newline', pattern='GlobalRadiation_10m_doy_(2[7-9][0-9]|3[0-4][0-9]|350)', mapset='g_EnergyResources_SolarRadiation', flags='e')
    layers_sorad_winter = grass.parse_command('g.list', type='raster', separator='newline', pattern='GlobalRadiation_10m_doy_(355|36[0-9]|0[0-7][0-9])', mapset='g_EnergyResources_SolarRadiation', flags='e')

    expression_spring = ''
    expression_summer = ''
    expression_autumn = ''
    expression_winter = ''

    for layer in layers_sorad_spring:
        expression_spring = expression_spring + '+' + layer + '@g_EnergyResources_SolarRadiation'
    for layer in layers_sorad_summer:
        expression_summer = expression_summer + '+' + layer + '@g_EnergyResources_SolarRadiation'
    for layer in layers_sorad_autumn:
        expression_autumn = expression_autumn + '+' + layer + '@g_EnergyResources_SolarRadiation'
    for layer in layers_sorad_winter:
        expression_winter = expression_winter + '+' + layer + '@g_EnergyResources_SolarRadiation'

    grass.run_command('r.mapcalc', overwrite=True, expression=r_sorad_spring+'='+expression_spring[1:])
    grass.run_command('r.mapcalc', overwrite=True, expression=r_sorad_summer+'='+expression_summer[1:])
    grass.run_command('r.mapcalc', overwrite=True, expression=r_sorad_autumn+'='+expression_autumn[1:])
    grass.run_command('r.mapcalc', overwrite=True, expression=r_sorad_winter+'='+expression_winter[1:])


if __name__ == '__main__':
    main()
