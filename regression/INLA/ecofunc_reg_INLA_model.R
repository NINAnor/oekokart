#NAME:    Exploring the functionality of R-INLA
#
#AUTHOR(S): Zofie Cimburova < zofie.cimburova AT nina.no>
#
#PURPOSE:   Exploring the functionality of R-INLA.
#           To predict probability of forest occurrence.
#

#
#To Dos: Not finished, version for exploring the functionality
#

setwd("/data/home/zofie.cimburova/ECOFUNC/DATA/SAMPLE")

library(gridExtra)
library(lattice)
library(fields)
library(geostatsp) # to convert raster to image
library(raster)
library(ggplot2)
library(INLA)

####################
# 1. load the data #
####################
lc <- raster("binom_lc.tif", band=1)
projection(lc) <- "+proj=utm +zone=33 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs"

bio01 <- raster("binom_bio01.tif", band=1)
projection(bio01) <- "+proj=utm +zone=33 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs"

tpi <- raster("binom_tpi.tif", band=1)
projection(tpi) <- "+proj=utm +zone=33 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs"

input_rasters <- brick(lc, bio01, tpi)
names(input_rasters) <- c('lc','tpi','bio01')

# convert to data frame
input_data <- as.data.frame(input_rasters, xy=TRUE) 

# add column with id - cell number in raster
input_data$node <- cellFromXY(input_rasters,cbind(input_data$x, input_data$y))

# add column with samples
input_data$lc_sample <- NA

# replace NaN with NA
input_data[is.na(input_data)] <- NA

ggplot() + geom_tile(data=input_data, aes(x=x, y=y, fill=bio01))
ggplot() + geom_tile(data=input_data, aes(x=x, y=y, fill=lc))
ggplot() + geom_tile(data=input_data, aes(x=x, y=y, fill=tpi))


#####################
# 2. random samples #
#####################
# todo - only 200 samples
n <- dim(input_data)[1]
sample <- sample(rep(0:1, each=n/2))

observations <- sampleRandom(input_rasters, 200, na.rm=TRUE, xy=TRUE)
observations <- as.data.frame(observations)
observations$node <- 1:dim(observations)[1] 

# replace 0 with NA
sample[sample == 0] <- NA

# add column with sample
input_data$sample <- sample


######################
# 3. lattice samples #
######################
# take one sample each x-th meters
distance <- 1000 # m

# assign lc_sample - keep value in sample locations, assign NA in other locations
# fill sample_data at the same time
i=1
sample_data <- input_data[0,]

# go through cells centers (=> xmin +5)
# rows Y
for(row in seq(input_rasters@extent@ymin+5, input_rasters@extent@ymax-5, by = distance)){
  # columns X
  for(col in seq(input_rasters@extent@xmin+5, input_rasters@extent@xmax-5, by = distance)) {

    
    input_data[input_data$x == col & input_data$y == row, ]$lc_sample = input_data[input_data$x == col & input_data$y == row, ]$lc
    sample_data[i,]=input_data[input_data$x == col & input_data$y == row, ]
   i=i+1
  }
}

rows_sample <- seq(input_rasters@extent@ymin+5, input_rasters@extent@ymax-5, by = distance)
cols_sample <- seq(input_rasters@extent@xmin+5, input_rasters@extent@xmax-5, by = distance)
input_data[input_data$x %in% cols_sample & input_data$y %in% rows_sample, ]$lc_sample = input_data[input_data$x == cols_sample & input_data$y == rows_sample, ]$lc
sample_data <- input_data[input_data$x %in% cols_sample & input_data$y %in% rows_sample, ]

sample_data$node <- seq.int(nrow(sample_data))
sample_data$node <- cellFromXY(input_rasters,cbind(input_data$x, input_data$y))

ggplot() + geom_tile(data=input_data, aes(x=x, y=y, fill=lc_sample)) + coord_equal()


#################################################
# 4. nonspatial logistic model fitted with INLA #
#################################################
# formula
formula <- lc ~ tpi + bio01

# GLM
mod.glm <- glm(formula, 
              data=input_data, 
              family=binomial(link='logit'))
summary(mod.glm)

# INLA
mod.inla <- inla(formula=formula,
                 data=sample_data,
                 family="binomial",
                 Ntrials=1,
                 control.compute=list(dic=TRUE),
                 control.fixed=list(prec.intercept=0.001),
                 verbose=FALSE)
summary(mod.inla)

# Predict the whole area
newdata <- rasterToPoints(input_rasters)
newdata <- as.data.frame(newdata)

newdata$predict <- predict(mod.glm, newdata=newdata,type='response')
newdata$predict <- ifelse(!is.na(newdata$lc),newdata$predict,NA)
newdata$predict10 <- ifelse(newdata$predict > 0.5,1,0)

predict.raster <- rasterFromXYZ(newdata)

ggplot()+
  geom_tile(data=newdata[newdata$predict10==1,],aes(x=x, y=y), alpha=0.4, fill="blue")+
  geom_tile(data=newdata[newdata$lc==1,],aes(x=x, y=y), fill="red", alpha=0.4)+
  coord_equal()
  

#############################################
# 5. Bayesian Matérn model fitted with INLA #
#############################################
# dimensions of raster
nrow.larger <- 1100 # no of rows in input data (sample data) raster
ncol.larger <- 1100 # no of columns in input data (sample data) raster

# parameters of matern field - range, precision (shape, scale)
log.range <- list(initial=log(5), fixed=TRUE) # log of range of gamma function (because we use log-gamma function)
hyperpar_matern <- list(initial=-3,param=c(23.36,0.001)) # ??? initial
                                                         # 23.36 shape, 0.001 scale

# formula with fixed effects and spatial effect
formula_matern <- lc_sample ~ tpi + bio01 +
                              f(node, model='matern2d', 
                                nrow=nrow.larger, 
                                ncol=ncol.larger, 
                                nu=1, # 1, 2 or 3
                                hyper=list(range=log.range, 
                                           prec=hyperpar_matern))

# formula spatial effect only
# TODO plot random effect of model fitted with this formula in raster
formula_matern_spatial <- lc_sample ~ 1 +
                                      f(node, model='matern2d',
                                        nrow=nrow.larger, 
                                        ncol=ncol.larger, 
                                        nu=1, # 1, 2 or 3
                                        hyper=list(range=log.range, 
                                                   prec=hyperpar_matern)) 

# fit model
model_matern <- inla(formula=formula_matern,
                     data=input_data,
                     family='binomial',
                     Ntrials=1,
                     control.compute=list(dic=TRUE),
                     control.fixed=list(prec.intercept=0.001),
                     verbose=F,
                     control.predictor=list(link=1))

# model summary
summary(model_matern)

# prediction of fitted values
model_matern$summary.fitted.values

# random effects for each model
model_matern$summary.random

# fixed effects
model_matern$summary.fixed


# ??? how do I predict
# prediction ??? why does it predict only (always) 10 000 points?
input_data$lc_predict <- NA
input_data$lc_predict <- model_matern$summary.random$node$mean
ggplot() + geom_tile(data=data, aes(x=x, y=y, fill=lc_predict))


