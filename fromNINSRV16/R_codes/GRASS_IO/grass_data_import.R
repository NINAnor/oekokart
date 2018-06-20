# Load GRASS library
library("rgrass7")

# Define GRASS working environment
user <- Sys.info()['user']
gisDbase <- '/data/grassdata'
location <- 'ETRS_33N'
mapset <- paste('u_', user, sep='')

# Full path to mapset
wd <- paste(gisDbase, location, mapset, sep='/')

# Initialize GRASS session
initGRASS(gisBase ='/usr/local/grass-7.2.1svn/', location = location, mapset = mapset, gisDbase = gisDbase, override = TRUE)

# Define some arbitraty points
points <- data.frame(x=c(257263.541385361,239694.999387084,258125.316157533), y=c(6785434.5842491,6637098.90944021,6784733.65002265), id=c(1,2,3))

# Get bounding box of all points
max_x <- max(points$x)
max_y <- max(points$y) 
min_x <- min(points$x)
min_y <- min(points$y)

# set the computational region first to the raster map and extent of your points:
execGRASS("g.region", align="dem_10m_nosefi@g_Elevation_Fenoscandia", n=as.character(max_y), s=as.character(min_y), e=as.character(max_x), w=as.character(min_x), flags = "p")

# query raster maps at vector points, transfer result into R
goutput <- execGRASS("r.what", flags="n", map="dem_10m_nosefi@g_Elevation_Fenoscandia,NORUT_veg@p_Naturindeks_oerrfugl", Sys_input=paste(points$x, points$y, points$id, sep=' '), separator=",", intern=TRUE)
str(goutput)

# Parse results
con <- textConnection(goutput)
go1 <- read.csv(con, header=TRUE)
str(go1)


