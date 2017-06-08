setwd("\\\\storage01/zofie.cimburova/My Documents/ecofunc/DATA")


# ------------------------------------ #
# ---------- 1. import data ---------- #
# ------------------------------------ #

### observation points
forest_line <- read.csv("explanatory_variables.csv")

# limit to pixels situated within limit
forest_line <- forest_line[forest_line$lim<=15,]

# exclude minimum height
forest_line <- forest_line[forest_line$height > min(forest_line$height),]
min(forest_line$height)

# half to predict, half to validate
even_indexes<-seq(2,nrow(forest_line),2)
odd_indexes<-seq(1,nrow(forest_line),2)

fl_predict <- forest_line[even_indexes,]
fl_test    <- forest_line[odd_indexes,]


### rasters of explanatory variables
library(rgdal)   
r.dem <- readGDAL("DEM.tif")
names(r.dem@data) <- "height"
r.bio11 <- readGDAL("BIO11.tif")
names(r.bio11@data) <- "BIO11"
r.tpi1010 <- readGDAL("TPI1010.tif")
names(r.tpi1010@data) <- "TPI1010"

r.explanatory <- r.bio11
r.explanatory$TPI1010 <- r.tpi1010$TPI1010 

projection(r.explanatory) <- "+proj=utm +zone=33"


### set extent for predicted data
extent <- expand.grid(x = seq(forest_line@bbox[1,1], forest_line@bbox[1,2], 50), 
                     y = seq(forest_line@bbox[2,1], forest_line@bbox[2,2], 50))
coordinates(extent) <- ~ x + y 

# --------------------------------------------- #
# ---------- 1. preliminary analysis ---------- #
# --------------------------------------------- #

# 1. colinearity between explanatory variables?
# -> Spearman rank correlation coefficient - makes no assumptions about linearity in the relationship between the two variables
cor(forest_line[, 6:16], method = "spearman")
a = pairs(forest_line[, 6:16])

# scatter plots
scatter.smooth(forest_line$BIO18, forest_line$BIO19)
cor(forest_line$BIO18, forest_line$BIO19)


# 2. spatial autocorrelation?
# -> plot
library(ncf)
Correlog <- spline.correlog(x = fl_predict$X[1:500], y = fl_predict$Y[1:500], z = residuals[1:500], xmax = 4700)
plot.spline.correlog(Correlog)

# -------------------------------- #
# ---------- 0. try OLS ---------- #
# -------------------------------- #

# try predict height with lm
model1 <- lm(formula = height~BIO11 + BIO10 + BIO01 + BIO18 +
               BIO12 + srad + lat +lon + slope, data = fl_predict)
summary(model1)

# residuals
fl_predict$residuals <- residuals(model1)


# plot
library(latticeExtra)

grps <- 10
brks <- quantile(fl_predict$residuals, 0:(grps-1)/(grps-1), na.rm=TRUE)
pts <- cbind(fl_predict$X, fl_predict$Y)
spplot(SpatialPointsDataFrame(pts, fl_predict), "residuals", at=brks, col.regions=rev(brewer.pal(grps, "RdBu")), col="black")

# ------------------------------------------------ #
# ---------- 1. try regression krigging ---------- #
# ------------------------------------------------ #

# convert input to SpatialPointsDataFrame
pts <- cbind(fl_predict$X, fl_predict$Y)
fl_predict.spdf <- SpatialPointsDataFrame(pts, fl_predict)

#Estimate the residuals and their autocorrelation structure (variogram):
library(gstat)
null.vgm <- vgm(2000, "Exp", 1000, nugget=0) # initial parameters
vgm_height_r <- fit.variogram(variogram(height~BIO11+TPI1010, fl_predict.spdf), model=null.vgm)

plot(variogram(height~BIO11+TPI1010, fl_predict.spdf), vgm_height_r, main="fitted by gstat")

# run krigging
#coordinates(fl_predict.spdf) <- ~ X + Y
projection(fl_predict.spdf) <- "+proj=utm +zone=33"

height_model2 <- krige(height~BIO11+TPI1010, locations=fl_predict.spdf, newdata=r.explanatory, model=vgm_height_r)

# export
r.height_model2 <- rasterFromXYZ(as.data.frame(height_model2)[c(3,4,1,2)])
projection(r.height_model2) <- "+proj=utm +zone=33"
writeRaster(r.height_model2, filename="temp_height_model2.tif", format="GTiff", overwrite=TRUE)


# -------------------------------------------------------- #
# ---------- 2. try krigging forest line height ---------- #
# -------------------------------------------------------- #
library(sp)
library(gstat)
library(ggplot2)

# 1. Visualize
ggplot(forest_line, aes(x=X, y=Y)) + 
        geom_point(aes(size=height), color="blue", alpha=1/4) +   
        ggtitle("Forest line height (m)") + coord_equal() + theme_bw()

# 2. Convert the dataframe to a spatial points dataframe (SPDF).
coordinates(forest_line) <- ~ X + Y
class(forest_line)

# 3. Fit a variogram model to the data.
# calculates sample variogram values 
fl.vgm <- variogram(log(height)~1, forest_line) 
fl.fit <- fit.variogram(fl.vgm, model=vgm(0.02, "Exp", 900, 1)) # fit model

plot(fl.vgm, fl.fit) # plot the sample values, along with the fit model


# 4. Krige the data according to the variogram.


# krigging
fl.kriged <- krige(log(height) ~ 1, forest_line, extent, model=fl.fit)

# plot results
fl.kriged <- as.data.frame(fl.kriged)
ggplot(fl.kriged, aes(x=x, y=y)) + geom_tile(aes(fill=var1.pred)) + coord_equal() +
  scale_fill_gradient(low = "yellow", high="red") +
  theme_bw()

# export results
library(raster)
fl.kriged_m = fl.kriged
fl.kriged_m$var1.pred = exp(fl.kriged_m$var1.pred)
  
fl.kriged.raster <- rasterFromXYZ(fl.kriged_m)  #Convert first two columns as lon-lat and third as value                
projection(fl.kriged.raster) <- "+proj=utm +zone=33"


writeRaster(fl.kriged.raster, filename="temp_fl_kriged.tif", format="GTiff", overwrite=TRUE)
plot(fl.kriged.raster)


# ------------------------------------------------------- #
# ---------- 3. try SAR for forest line height ---------- #
# ------------------------------------------------------- #
library(spdep)

# create neighbourhood
gridIndex2nb
cell2nb(hh)

nb <- cell2nb(hh)

# spatial weights for neighbours lists
lw <- nb2listw()


# SAR
fl.SAR.e <- errorsarlm(formula=height~BIO11+BIO10+BIO01+BIO18+BIO19+BIO12+srad+lat+lon+slope+aspect, 
                       data=fl_predict)















# ------------------------------------------------------- #
# ---------- 4. try GWR for forest line height ---------- #
# ------------------------------------------------------- #
# gwr
library(maptools)
library(spdep)
owd <- getwd()
setwd(system.file("etc/shapes", package = "spdep"))
NY8 <- readShapeSpatial("NY8_utm18")
setwd(owd)

library(spgwr)

# cross validation of bandwidth
bwG <- gwr.sel(height ~ BIO11 + BIO10 + BIO01 + BIO18 + BIO12 + srad + lat + lon + slope, data = fl_predict, coords = cbind(fl_predict$X, fl_predict$Y), gweight = gwr.Gauss, verbose = FALSE)

# gwr
gwrG <- gwr(height ~ BIO11 + BIO10 + BIO01 + BIO18 + BIO12 + srad + lat + lon + slope, data = fl_predict, coords = cbind(fl_predict$X, fl_predict$Y), bandwidth = bwG,
            gweight = gwr.Gauss, hatmatrix = TRUE)
gwrG





# ---------------------------- #
# ---------- 4. PCA ---------- #
# ---------------------------- #
library(pls)

attributes <- cbind(forest_line$BIO11, forest_line$BIO10, forest_line$BIO01, forest_line$BIO18, forest_line$BIO19, forest_line$BIO12, forest_line$srad, forest_line$lat, forest_line$lon, forest_line$slope, forest_line$aspect)

# scale data
attributes.scaled = scale(attributes)

# pca
attributes.pca <- prcomp(attributes.scaled, center = FALSE, scale = FALSE)

# results
loadingVector = attributes.pca 
pcaSummary = summary(attributes.pca)  # stdev, proportion of variance, cumulative proportion
print(pcaSummary)

plot(attributes.pca, type = "l")   
plot(pcaSummary$importance[1,], type = "l") # plot standard deviation
plot(pcaSummary$importance[2,], type = "l") # plot proportion of variance explained
plot(pcaSummary$importance[3,], type = "l") # plot cumulative proportion of variance explained
