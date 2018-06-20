###########################
### Map Sheet Grid Finland ###
###########################

### Link for manual selection of tiles
# https://tiedostopalvelu.maanmittauslaitos.fi/tp/kartta?lang=en

cd /data/raw_data/Grid_Finland

#Download data

for url in "https://tiedostopalvelu.maanmittauslaitos.fi/tp/tilaus/gp1de10cai2i0in7qu5k94nev9?lang=en"
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

