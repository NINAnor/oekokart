###########################
### TopographicMap_100k ###
###########################

### Metadata:
# http://www.paikkatietohakemisto.fi/geonetwork/srv/eng/catalog.search#/metadata/5c671d8d-be58-4f5d-8242-a150ecc82f95
# http://www.maanmittauslaitos.fi/en/maps-and-spatial-data/expert-users/product-descriptions/topographic-map-1100-000

### Link for manual selection of tiles
# https://tiedostopalvelu.maanmittauslaitos.fi/tp/kartta?lang=en

# Maximum 100 tiles in one chunk, data has to be ordered in two chunks

cd /data/raw_data/Topography_Finland_100k/

#Download data

for url in "https://tiedostopalvelu.maanmittauslaitos.fi/tp/tilaus/je7oojpehuge16laoeej5pru8i?lang=en" "https://tiedostopalvelu.maanmittauslaitos.fi/tp/tilaus/gduajo56sc3v9vkuabnve3avu?lang=en"
do
# Extract downloadlinks from URL
for z in $(lynx -accept_all_cookies -dump -force_html -nonumbers $url | grep zip | grep http)
do
# Extract filename
filename=$(echo $z | cut -f1 -d'?' | grep -o '.\{7\}$')
# Download data
curl $z -o $filename
done
done
