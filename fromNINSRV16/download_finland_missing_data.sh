###########################
### Map Sheet Grid Finland ###
###########################

### Link for manual selection of tiles
# https://tiedostopalvelu.maanmittauslaitos.fi/tp/kartta?lang=en

# Run this script with:"bash download_finland_missing_data.sh"

#mkdir /data/raw_data/Missing_LC_Finland
cd /data/raw_data/Missing_LC_Finland

#Download data

for url in "https://tiedostopalvelu.maanmittauslaitos.fi/tp/tilaus/cuo3od7nha9f5894mnm4cjle5g?lang=en" "https://tiedostopalvelu.maanmittauslaitos.fi/tp/tilaus/f4vgov17tfua45f18j8lme2nb4?lang=en"
do
# Extract downloadlinks from URL
for z in $(lynx -accept_all_cookies -dump -force_html -nonumbers $url | grep zip | grep http)
do
# Extract filename
filename=$(echo $z | cut -f1 -d'?' | grep -o '.\{13\}.$')
echo $filename

# Download data
curl $z -o $filename
done
done

# unzip data
#find ./ -name "*.zip" -exec unzip -ojU -d ./ {} \;
#find ./ -name "FONT*.zip" -exec unzip -ojU -d ./ {} \;

