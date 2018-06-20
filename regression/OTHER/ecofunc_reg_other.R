#NAME:    Exploring other regression models
#
#AUTHOR(S): Zofie Cimburova < zofie.cimburova AT nina.no>
#
#PURPOSE:   Exploring other regression models.
#           OLS, GLS, rgression kriging, collocated cokriging, SAR, GWR, PCA.
#

#
#To Dos: 
#

setwd("\\\\storage01/zofie.cimburova/My Documents/ecofunc/DATA/sample")

# ================================= #
# ========== import data ========== #
# ================================= #

### observation points
forest_line <- read.csv("explanatory_variables.csv")

# limit to pixels situated within limit
forest_line <- forest_line[forest_line$lim<=15,]

# exclude minimum height
forest_line <- forest_line[forest_line$height > min(forest_line$height),]
min(forest_line$height)

# half to predict, half to validate
fl_predict <- forest_line[seq(2,nrow(forest_line),2),]
fl_test    <- forest_line[seq(1,nrow(forest_line),2),]


### rasters of explanatory variables
library(rgdal)   
library(raster)

bio11 <- raster("BIO11.tif", band=1)
projection(bio11) <- "+proj=utm +zone=33 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs"

r.explanatory <- brick(bio11,
                       raster("BIO12.tif", band=1),
                       raster("TPI1010.tif", band=1),
                       raster("slope.tif", band=1),
                       raster("srad10.tif", band=1),
                       raster("lat.tif", band=1))
names(r.explanatory) <- c('BIO11','BIO12','TPI1010', 'slope', 'srad', 'lat')


# ================================= #
# ============= 1. OLS ============ #
# ================================= #
library(ape)
library(ncf)

## fit lm
model.ols <- lm(formula = height~BIO11 + BIO12 + TPI1010 + slope + srad + lat, data = fl_predict)

## check s-a in residuals using Moran's I and correlogram
fl_predict$residuals <- residuals(model.ols)

# Moran's I
fl_predict.dists.inv <- as.matrix(dist(cbind(fl_predict$X, fl_predict$Y)))
fl_predict.dists.inv <- 1/fl_predict.dists.inv
diag(fl_predict.dists.inv) <- 0
Moran.I(fl_predict$residuals, fl_predict.dists.inv)

# Correlogram
Correlog <- spline.correlog(x = fl_predict$X[1:500], y = fl_predict$Y[1:500], z = fl_predict$residuals[1:500], xmax = 4700)
plot.spline.correlog(Correlog)


## evaluate models using test data
# sum of squared differences
SSD.lm <- sum((predict.lm(object = model.ols, fl_test) - fl_test$height)^2)

# mean absolute differences
MAD.lm <- sum(abs(predict.lm(object = model.ols, fl_test) - fl_test$height))/nrow(fl_test)

## predict the whole area
newdata <- as.data.frame(rasterToPoints(r.explanatory))
newdata$predicted_height <-predict.lm(object = model.ols, newdata)

# export
r.height_model.ols <- rasterFromXYZ(newdata[,c("x","y","predicted_height")])
projection(r.height_model.ols) <- "+proj=utm +zone=33"
writeRaster(r.height_model.ols, filename="temp_height_OLS.tif", format="GTiff", overwrite=TRUE)


# ================================= #
# ============ 2. GLS ============= #
# ================================= #
library (nlme)

## fit gls without any correlation structure
# result is identical to the one of OLS
model.gls_0 <- gls(height~BIO11 + BIO12 + TPI1010 + slope + srad + lat, data = fl_predict)

## check s-a in residuals
# semi-variance is clearly increasing with distance. We have a confirmation that spatial autocorrelation is present in our residuals.
variogram.gls <- Variogram(model.gls_0, form = ~X + Y, resType = "pearson")
plot(variogram.gls, smooth = TRUE, ylim = c(0, 1.2))

# Fit model with a spatial correlation structure using the correlation argument in gls function
# Fit model using different correlation structures
# Use AIC to choose the best model
# The nugget argument allows us to choose wether we want a nugget effect (intercept) or not.
# !!! formula must be explicit, otherwise prediction does not work
model.gls_1 <- gls(height~BIO11 + BIO12 + TPI1010 + slope + srad + lat, correlation = corExp(form = ~X + Y, nugget = TRUE), data = fl_predict)
# model.gls_1 did not convergate
model.gls_2 <- gls(height~BIO11 + TPI1010 + lat, correlation = corGaus(form = ~X + Y, nugget = TRUE), data = fl_predict)
model.gls_3 <- gls(height~BIO11 + BIO12 + TPI1010 + slope + srad + lat, correlation = corSpher(form = ~X + Y, nugget = TRUE), data = fl_predict)
model.gls_4 <- gls(height~BIO11 + BIO12 + TPI1010 + slope + srad + lat, correlation = corLin(form = ~X + Y, nugget = TRUE), data = fl_predict)
model.gls_5 <- gls(height~BIO11 + BIO12 + TPI1010 + slope + srad + lat, correlation = corRatio(form = ~X + Y, nugget = TRUE), data = fl_predict)


## check s-a in residuals using Moran's I and correlogram
fl_predict$residuals.gls3 <- residuals(model.gls_3)

# Moran's I
Moran.I(fl_predict$residuals.gls3, fl_predict.dists.inv)

# Correlogram
Correlog <- spline.correlog(x = fl_predict$X[1:500], y = fl_predict$Y[1:500], z = fl_predict$residuals.gls3[1:500], xmax = 4700)
plot.spline.correlog(Correlog)



## evaluate models using test data
# sum of squared differences
SSD.gls_0 <- sum((predict(model.gls_0, fl_test) - fl_test$height)^2)
SSD.gls_2 <- sum((predict(model.gls_2, fl_test) - fl_test$height)^2)
SSD.gls_3 <- sum((predict(model.gls_3, fl_test) - fl_test$height)^2)
SSD.gls_4 <- sum((predict(model.gls_4, fl_test) - fl_test$height)^2)
SSD.gls_5 <- sum((predict(model.gls_5, fl_test) - fl_test$height)^2)

# mean absolute differences
MAD.gls_0 <- sum(abs(predict(model.gls_0, fl_test) - fl_test$height))/nrow(fl_test)
MAD.gls_2 <- sum(abs(predict(model.gls_2, fl_test) - fl_test$height))/nrow(fl_test)
MAD.gls_3 <- sum(abs(predict(model.gls_3, fl_test) - fl_test$height))/nrow(fl_test)
MAD.gls_4 <- sum(abs(predict(model.gls_4, fl_test) - fl_test$height))/nrow(fl_test)
MAD.gls_5 <- sum(abs(predict(model.gls_5, fl_test) - fl_test$height))/nrow(fl_test)

# AIC
AIC(model.gls_0, model.gls_2, model.gls_3, model.gls_4, model.gls_5)

## predict the whole area
newdata <- as.data.frame(rasterToPoints(r.explanatory))
newdata$predicted_height.gls_2 <-predict(model.gls_2, newdata, na.action = na.pass)
newdata$predicted_height.gls_3 <-predict(model.gls_3, newdata, na.action = na.pass)
newdata$predicted_height.gls_4 <-predict(model.gls_4, newdata, na.action = na.pass)
newdata$predicted_height.gls_5 <-predict(model.gls_5, newdata, na.action = na.pass)


# export
r.height_model.gls_2 <- rasterFromXYZ(newdata[,c("x","y","predicted_height.gls_2")])
r.height_model.gls_3 <- rasterFromXYZ(newdata[,c("x","y","predicted_height.gls_3")])
r.height_model.gls_4 <- rasterFromXYZ(newdata[,c("x","y","predicted_height.gls_4")])
r.height_model.gls_5 <- rasterFromXYZ(newdata[,c("x","y","predicted_height.gls_5")])

projection(r.height_model.gls_2) <- "+proj=utm +zone=33"
projection(r.height_model.gls_3) <- "+proj=utm +zone=33"
projection(r.height_model.gls_4) <- "+proj=utm +zone=33"
projection(r.height_model.gls_5) <- "+proj=utm +zone=33"

writeRaster(r.height_model.gls_2, filename="temp_height_GLS2.tif", format="GTiff", overwrite=TRUE)
writeRaster(r.height_model.gls_3, filename="temp_height_GLS3.tif", format="GTiff", overwrite=TRUE)
writeRaster(r.height_model.gls_4, filename="temp_height_GLS4.tif", format="GTiff", overwrite=TRUE)
writeRaster(r.height_model.gls_5, filename="temp_height_GLS5.tif", format="GTiff", overwrite=TRUE)


# ================================= #
# ==== 3. regression krigging ===== #
# ================================= #
library(gstat)

# convert input to SpatialPointsDataFrame
coordinates(fl_predict) <- ~ X + Y
projection(fl_predict) <- "+proj=utm +zone=33"

#Estimate the residuals and their autocorrelation structure (variogram):
psill <- 2000
range <- 2000
vgm.theor <- vgm(psill, "Exp", range, nugget=0)
vgm.empir <- variogram(height~BIO11+TPI1010, fl_predict)
vgm.fit <- fit.variogram(vgm.empir, model=vgm.theor)

plot(vgm.empir, vgm.fit, main="fitted by gstat")

# run krigging
height_model2 <- krige(height~BIO11+TPI1010, locations=fl_predict, newdata=r.explanatory, model=vgm.fit)

# export
r.height_model2 <- rasterFromXYZ(as.data.frame(height_model2)[c(3,4,1,2)])
projection(r.height_model2) <- "+proj=utm +zone=33"
writeRaster(r.height_model2, filename="temp_height_model2.tif", format="GTiff", overwrite=TRUE)



# ================================= #
# === 4. collocated cokrigging ==== #
# ================================= #

g.cc <- gstat(NULL, "blabla", height~BIO11+TPI1010, data=fl_predict, model = vgm.fit)

# kriging
x <- predict(g.cc, fl_predict)


# ================================= #
# ============ 5. SAR ============= #
# ================================= #
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


# ================================= #
# =========== 6. GWR ============== #
# ================================= #
# gwr
library(maptools)
library(spdep)
library(spgwr)

owd <- getwd()
setwd(system.file("etc/shapes", package = "spdep"))
NY8 <- readShapeSpatial("NY8_utm18")
setwd(owd)

# cross validation of bandwidth
bwG <- gwr.sel(height ~ BIO11 + BIO10 + BIO01 + BIO18 + BIO12 + srad + lat + lon + slope, data = fl_predict, coords = cbind(fl_predict$X, fl_predict$Y), gweight = gwr.Gauss, verbose = FALSE)

# gwr
gwrG <- gwr(height ~ BIO11 + BIO10 + BIO01 + BIO18 + BIO12 + srad + lat + lon + slope, data = fl_predict, coords = cbind(fl_predict$X, fl_predict$Y), bandwidth = bwG,
            gweight = gwr.Gauss, hatmatrix = TRUE)


# ================================= #
# ============ 7. PCA ============= #
# ================================= #
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
