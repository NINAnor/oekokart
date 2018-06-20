export GRASS_COMPRESS_NULLS=1

# for each map in mapset
for m in $(g.list type=raster mapset=u_zofie.cimburova)
do
echo $m
r.null -z $m
done
