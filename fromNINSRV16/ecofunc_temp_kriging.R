setwd("\\\\storage01/zofie.cimburova/My Documents/ecofunc/DATA")


# ------------------------------------ #
# ---------- 1. import data ---------- #
# ------------------------------------ #

library(rgdal)  

# 250 m temperature and 250 m DEM
r.bio11 <- readGDAL("BIO11_250.tif")
r.dem <- readGDAL("DEM_250.tif")

names(r.bio11@data) <- "BIO11"
names(r.dem@data) <- "height"

# set NaN to 0
r.dem$height[is.na(r.dem$height)] = 0

# merge input data
r.measurements <- r.bio11
r.measurements$height <- r.dem$height 
projection(r.measurements) <- "+proj=utm +zone=33"

# new data - 10 m DEM
r.dem_new <- readGDAL("DEM.tif")
projection(r.dem_new) <- "+proj=utm +zone=33"
names(r.dem_new@data) <- "height"
r.dem_new$height[is.na(r.dem_new$height)] = 0



# ------------------------------------------------ #
# ---------- 2. regression krigging ---------- #
# ------------------------------------------------ #

library(gstat)
library(automap)

#Estimate the residuals and their autocorrelation structure (variogram):
width = 100000
vario.emp <- variogram(BIO11~height,r.measurements, cutoff= width, width=width/200)

vgm.fit <- autofitVariogram(BIO11~height,
                             r.measurements,
                             model = c("Gau"),
                             kappa = c(0.05, seq(0.2, 2, 0.1), 5, 10),
                             fix.values = c(NA, 8000, NA),
                             start_vals = c(NA,NA,NA),
                             verbose = T)

plot(vario.emp, vgm.fit$var_model, main = "Fitted variogram")

# Krigging
int.temperature <- krige(BIO11~height, locations=r.measurements, newdata=r.dem_new, model=vgm.fit$var_model)

# Export to tif
r.temperature <- rasterFromXYZ(as.data.frame(int.temperature)[c(3,4,1,2)])
projection(r.temperature) <- "+proj=utm +zone=33"
writeRaster(r.temperature, filename="temperature_kriged_10m.tif", format="GTiff", overwrite=TRUE)


