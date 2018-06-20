#!/bin/bash

#
# NAME:    Upload downloaded Finnish TopographicMap_100k
#
# AUTHOR(S): Stefan Blumentrath < stefan.blumentrath AT nina.no>
#
# PURPOSE:   Upload downloaded Finnish TopographicMap_100k to PostgreSQL.
#

#
#To Dos:
#

for f in *.shp
do
    shp2pgsql -I -s 25835 $f `basename $f .shp` > `basename $f .shp`.sql
done

for f in *.sql
do
    psql -d 'gisdata' -f $f
done
