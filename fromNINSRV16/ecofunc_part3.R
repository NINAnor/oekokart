setwd("\\\\storage01/zofie.cimburova/My Documents/ecofunc/DATA")


# ------------------------------------ #
# ---------- 0. import data ---------- #
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



# ------------------------------------------------------- #
# ---------- 2. try SAR for forest line height ---------- #
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
# ---------- 3. try GWR for forest line height ---------- #
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
