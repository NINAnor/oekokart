#!/bin/bash

for f in *.shp
do
    shp2pgsql -I -s 25835 $f `basename $f .shp` > `basename $f .shp`.sql
done

for f in *.sql
do
    psql -d 'gisdata' -f $f
done
