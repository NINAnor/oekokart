export GRASS_BATCH_JOB="$HOME/CODES/compress_null.sh"

# define mapset
ms=/data/grassdata/ETRS_33N/u_zofie.cimburova
echo $ms
grass72 -text $ms

unset GRASS_BATCH_JOB
