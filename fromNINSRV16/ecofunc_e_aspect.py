#!/usr/bin/env python

import grass.script as grass
import math

def main():
    r_aspect = 'dem_10m_nosefi_float_aspect'
    r_aspect_sin = 'dem_10m_nosefi_float_aspect_sin'
    r_aspect_cos = 'dem_10m_nosefi_float_aspect_cos'

    grass.run_command('g.region', raster=r_aspect)

    grass.run_command('r.mapcalc', expression='{}=sin({})'.format(\
                      r_aspect_sin,r_aspect),overwrite=True)

    grass.run_command('r.mapcalc', expression='{}=cos({})'.format(\
                      r_aspect_cos,r_aspect),overwrite=True)



if __name__ == '__main__':
    main()
