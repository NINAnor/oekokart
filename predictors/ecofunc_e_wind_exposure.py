#!/usr/bin/env python

"""
NAME:    Compute wind exposure

AUTHOR(S): Zofie Cimburova < zofie.cimburova AT nina.no>

PURPOSE:   Compute wind exposure.
           TOPEX in 8 directions.
"""

"""
To Dos:
"""

import grass.script as grass
import math
import sys

# WIND EXPOSURE

def main():

    r_height = 'dem_10m_nosefi_float@g_Elevation_Fenoscandia'

    # TOPEX
    # http://jamiepopkin.blogspot.no/2011/01/calculating-togographic-exposure-with.html
    # 100 m to 2000 m in 100m intervals
    # TODO: use DEM with 0 instead of null
    grass.run_command('g.region', raster=r_height)

    r_topex_N = 'dem_10m_topex_N'
    r_topex_S = 'dem_10m_topex_S'
    r_topex_E = 'dem_10m_topex_E'
    r_topex_W = 'dem_10m_topex_W'

    r_topex_NE = 'dem_10m_topex_NE'
    r_topex_SE = 'dem_10m_topex_SE'
    r_topex_SW = 'dem_10m_topex_SW'
    r_topex_NW = 'dem_10m_topex_NW'

    r_topex = 'dem_10m_topex'

    lower_limit = 100
    upper_limit = 2000
    step = 100
    bins = list(range(lower_limit, upper_limit+1, step))

    # N S E W
    expression_N = '${out} = max('
    expression_S = '${out} = max('
    expression_E = '${out} = max('
    expression_W = '${out} = max('

    for bin in bins:
        N = bin/10 # index

        expression_N = expression_N + 'if(isnull(${dem}[-'+str(N)+',0]),\
                       atan(-${dem}/'+str(bin)+'),atan((${dem}[-'+str(N)+',0]\
                       -${dem})/'+str(bin)+'))'
        expression_S = expression_S + 'if(isnull(${dem}['+str(N)+',0]),\
                       atan(-${dem}/'+str(bin)+'),atan((${dem}['+str(N)+',0]\
                       -${dem})/'+str(bin)+'))'
        expression_E = expression_E + 'if(isnull(${dem}[0,'+str(N)+']),\
                       atan(-${dem}/'+str(bin)+'),atan((${dem}[0,'+str(N)+']\
                       -${dem})/'+str(bin)+'))'
        expression_W = expression_W + 'if(isnull(${dem}[0,-'+str(N)+']),\
                       atan(-${dem}/'+str(bin)+'),atan((${dem}[0,-'+str(N)+']\
                       -${dem})/'+str(bin)+'))'
        
        if bin == bins[-1]:
            expression_N = expression_N + ')'
            expression_S = expression_S + ')'
            expression_E = expression_E + ')'
            expression_W = expression_W + ')'
        else:
            expression_N = expression_N + ','
            expression_S = expression_S + ','
            expression_E = expression_E + ','
            expression_W = expression_W + ','

    grass.mapcalc(expression_N, overwrite=True, out = r_topex_N, dem=r_height)
    grass.mapcalc(expression_S, overwrite=True, out = r_topex_S, dem=r_height)
    grass.mapcalc(expression_E, overwrite=True, out = r_topex_E, dem=r_height)
    grass.mapcalc(expression_W, overwrite=True, out = r_topex_W, dem=r_height)

    # NE SE SW NW
    expression_NE = '${out} = max('
    expression_SE = '${out} = max('
    expression_SW = '${out} = max('
    expression_NW = '${out} = max('

    for bin in bins:
        N = int(round(math.sqrt(2)/2*(bin/10))) # index

        expression_NE = expression_NE + 'if(isnull(${dem}[-'+str(N)+','\
                       +str(N)+']),atan(-${dem}/'+str(bin)+'),atan((${dem}[-'\
                       +str(N)+','+str(N)+']-${dem})/'+str(bin)+'))'
        expression_SE = expression_SE + 'if(isnull(${dem}['+str(N)+','\
                       +str(N)+']),atan(-${dem}/'+str(bin)+'),atan((${dem}['\
                       +str(N)+','+str(N)+']-${dem})/'+str(bin)+'))'
        expression_SW = expression_SW + 'if(isnull(${dem}['+str(N)+',-'\
                       +str(N)+']),atan(-${dem}/'+str(bin)+'),atan((${dem}['\
                       +str(N)+',-'+str(N)+']-${dem})/'+str(bin)+'))'
        expression_NW = expression_NW + 'if(isnull(${dem}[-'+str(N)+',-'\
                       +str(N)+']),atan(-${dem}/'+str(bin)+'),atan((${dem}[-'\
                       +str(N)+',-'+str(N)+']-${dem})/'+str(bin)+'))'
        
        if bin == bins[-1]:
            expression_NE = expression_NE + ')'
            expression_SE = expression_SE + ')'
            expression_SW = expression_SW + ')'
            expression_NW = expression_NW + ')'
        else:
            expression_NE = expression_NE + ','
            expression_SE = expression_SE + ','
            expression_SW = expression_SW + ','
            expression_NW = expression_NW + ','
        
    grass.mapcalc(expression_NE, overwrite=True,out = r_topex_NE,dem=r_height)
    grass.mapcalc(expression_SE, overwrite=True,out = r_topex_SE,dem=r_height)
    grass.mapcalc(expression_SW, overwrite=True,out = r_topex_SW,dem=r_height)
    grass.mapcalc(expression_NW, overwrite=True,out = r_topex_NW,dem=r_height)

if __name__ == '__main__':
    main()
