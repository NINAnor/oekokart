setwd("/data/home/zofie.cimburova/ECOFUNC/DATA/SAMPLE")

library(gridExtra)
library(ggplot2)
library(lattice)
library(INLA)
library(fields)
library(raster)
library(geostatsp) # to convert raster to image

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

# add column with id
input_data$node <- seq.int(nrow(input_data))

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

# TODO replace NaN with NA ???
input_data$lc_sample <- NA

# assign lc_sample - keep value in sample locations, assign NA in other locations
# go through cells centers (=> xmin +5)
# rows Y
for(row in seq(input_rasters@extent@ymin+5, input_rasters@extent@ymax-5, by = distance)){
  # columns X
  for(col in seq(input_rasters@extent@xmin+5, input_rasters@extent@xmax-5, by = distance)) {
    input_data[input_data$x == col & input_data$y == row, ]$lc_sample = input_data[input_data$x == col & input_data$y == row, ]$lc
  }
}

sample_data <- input_data[!is.na(input_data$lc_sample),]
sample_data$node <- seq.int(nrow(sample_data))

ggplot() + geom_tile(data=input_data, aes(x=x, y=y, fill=lc_sample))

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
#newdata <- rasterToPoints(input_rasters)
#newdata <- as.data.frame(newdata)

#newdata$predict <- predict(mod.glm, newdata=newdata,type='response')
#newdata$predict <- ifelse(!is.na(newdata$lc),newdata$predict,NA)
#newdata$predict10 <- ifelse(newdata$predict > 0.5,1,0)

#predict.raster <- rasterFromXYZ(newdata)

#plot(predict.raster$predict)
#plot(predict.raster$predict10)
#plot(predict.raster$predict10+predict.raster$lc)

#ggplot()+
#  geom_tile(data=newdata[newdata$predict10==1,],aes(x=x, y=y), alpha=0.4, fill="blue")+
#  geom_tile(data=newdata[newdata$lc==1,],aes(x=x, y=y), fill="red", alpha=0.4)+
#  coord_equal()
  
##########################################
# 5. Bayesian CAR model fitted with INLA #
##########################################
# makes sense only for data in a grid/direct neighbourhood

#############################################
# 6. Bayesian Matérn model fitted with INLA #
#############################################
# dimensions of field
nrow.larger <- 100 # ???
ncol.larger <- 100 # ???
log.range <- list(initial=log(5), fixed=TRUE) # range of spatial autocorrelation

# shape=23.36, scale=0.001
hyperpar_matern <- list(initial=-3,param=c(23.36,0.001)) # ??? initial
                                                         # 23.36 shape, 0.001 scale
formula_matern <- lc_sample ~ tpi + bio01 +
                       f(node, model='matern2d', #??? node=ID???
                         nrow=nrow.larger, 
                         ncol=ncol.larger, 
                         nu=1, # 1, 2 or 3
                         hyper=list(range=log.range, 
                                    prec=hyperpar_matern))


model_matern <- inla(formula=formula_matern,
                     data=input_data,
                     family='binomial',
                     Ntrials=1,
                     control.compute=list(dic=TRUE),
                     control.fixed=list(prec.intercept=0.001),
                     verbose=F)
# model summary
summary(model_matern)

# prediction of fitted values
model_matern$summary.fitted.values



# ??? how do I predict
# prediction ??? why does it predict only (always) 10 000 points?
input_data$lc_predict <- NA
input_data$lc_predict <- model_matern$summary.random$node$mean
ggplot() + geom_tile(data=data, aes(x=x, y=y, fill=lc_predict))























###########################################
# 7. Bayesian SPDE model fitted with INLA #
###########################################
# ---------------------------- #
# ---- EXAMINING THE DATA ---- #
# ---------------------------- #
# extract response variable
Y <- observations$lc

# locations with non-missing values, sampled
coords <- as.matrix(observations[,1:2])

# predictors at locations
predictors <- observations[,c('tpi','bio01')]

# plot locations
ggplot() +
  geom_point(aes(x=coords[,1],y=coords[,2],colour=Y), size=2,
             alpha=1) +
  scale_colour_gradientn(colours=tim.colors(100)) #+

# Plot height as a function of the possible covariates

par(mfrow=c(2,ceiling(dim(predictors)[2]/2)))
for (colname in colnames(predictors)) {
  corcoef = round(cor(Y, predictors[,colname], use="complete.obs"),2)
  cat(paste(colname, corcoef, "\n", sep="\t"))
  plot(predictors[,colname], Y, 
       cex=.5, xlab=paste(colname, toString(corcoef)))
}


# --------------------------------- #
# ---- CREATING THE SPDE MODEL ---- #
# --------------------------------- #

# 1. the mesh
# use triangulation with "regular triangles"
# mesh based on covex hull
# extend mesh outside the region to reduce edge effects
# parametres: offset - extending region
#             cutoff - increase / decrease density of mesh
#             max.edge - increase / decrease density of mesh
m1 <- inla.mesh.2d(loc = coords, # triangulation nodes
                   offset = 1000, # extension distance
                   max.edge=1000, # largest allowed triange edge length
                   cutoff=100) # minimum allowed distance between points
plot(m1, asp=1, main="")
points(coords[,1], coords[,2], pch=19, cex=.5, col="red")

# mesh based on non-convex hull
# => smaller comp. time
prdomain <- inla.nonconvex.hull(points = coords,
                                convex = -0.03, # minimal convex curvature radius (fraction)
                                concave = -0.05, # minimal concave curvature radius
                                resolution=c(100,100)) # internal computation resolution
prmesh <- inla.mesh.2d(boundary = prdomain,
                       offset = 10000,
                       max.edge = 1000,
                       cutoff= 100)
plot(prmesh, asp=1, main="")
points(coords[,1], coords[,2], pch=19, cex=.5, col="red")

# 2. the observation matrix A
# connects the mesh to the observation locations
# weights
A <- inla.spde.make.A(mesh = m1, # inla mesh
                      loc=coords) # observation/prediction coordinates

# spde model object for a Matern model
spde <- inla.spde2.matern(mesh = m1, # The mesh to build the model on
                          alpha=2) # Fractional operator order, 0<α≤q 2 supported

# 3. the inla.stack
# Since the covariates already are evaluated at the 
# observation locations, we only want to apply the 
# A matrix to the spatial effect and not the fixed 
# effects. It is difficult to do this manually, but 
# we can use the inla.stack function
mesh.index <- inla.spde.make.index(name="field",
                                   n.spde=spde$n.spde)

stk.dat <- inla.stack(data=list(y=Y), A=list(A,1), tag="est",
                      effects=list(c(mesh.index,list(Intercept=1)),
                                   list(long=inla.group(coords[,1]),
                                        lat=inla.group(coords[,2]),
                                        bio01=inla.group(predictors$bio01),
                                        tpi=inla.group(predictors$tpi))))
# Here the observation matrix A is applied to 
# the spatial effect and the intercept while 
# an identity observation matrix, denoted by “1”, 
# is applied to the covariates. This means the 
# covariates are unaffected by the observation matrix.

# ----------------------- #
# ---- MODEL FITTING ---- #
# ----------------------- #
# fit model using distance to the sea as a covariate
# through a random walk 1 model
# -1 is added to remove R's implicit intercept,
# which is replaced by the explicit +Intercept from
# when we created the stack
formula.inla <- y ~ -1 + Intercept + f(bio01, model="rw1") + 
  f(tpi, model="rw1") + f(field, model=spde)

mod.inla.sp <- inla(formula.inla, family="binomial",control.family = list(link = "logit"),
            data=inla.stack.data(stk.dat), verbose=TRUE,
            control.predictor=list(A=inla.stack.A(stk.dat),
                                   compute=TRUE))
summary(mod.inla.sp)

# ----------------------------------------- #
# ---- Calculating kriging predictions ---- #
# ----------------------------------------- #
# prediction of expected precipitation

# aggregate to coarser resolution
bio01.aggregate <- aggregate(bio01, fact=5)
tpi.aggregate <- aggregate(tpi, fact=5)

# locations of prediction
coord.prd.x <- xFromCol(bio01.aggregate, c(1:bio01.aggregate@ncols))
coord.prd.y <- yFromRow(bio01.aggregate, c(1:bio01.aggregate@nrows))
coord.prd <- expand.grid(coord.prd.x,
                         coord.prd.y)

# create grid of size of prediction grid
nxy <- c(bio01.aggregate@nrows, bio01.aggregate@ncols)

# Calculate a lattice projection to/from an inla.mesh
projgrid <- inla.mesh.projector(mesh = m1,
                                xlim=range(coord.prd[,1]), # X-axis limits for a lattice
                                ylim=range(coord.prd[,2]), # Y-axis limits for a lattice.
                                dims=nxy)

plot(projgrid$lattice$loc, type="p", cex=.1, asp=1)
points(coords[,1], coords[,2], pch=19, cex=.5, col="red")


# calculate the prediction jointly with the
# estimation, which unfortunately is quite 
# computationally expensive if we do prediction
# on a fine grid.

# link the prediction coordinates to the mesh nodes 
# through an A matrix
A.prd <- projgrid$proj$A

# stack for the prediction locations
ef.prd <- list(c(mesh.index,list(Intercept=1)),
              list(long=inla.group(coord.prd[,1]),
                   lat=inla.group(coord.prd[,2]),
                   bio01=inla.group(bio01.aggregate@data@values),
                   tpi=inla.group(tpi.aggregate@data@values)))


# no data at prediction locations => y=NA
stk.prd <- inla.stack(data=list(y=NA), A=list(A.prd,1),
                      tag="prd", effects=ef.prd)

stk.all <- inla.stack(stk.dat, stk.prd)

# turn of the computation of certain things 
# that we are not interested in, such as the marginals
# for the random effect. 
# We also use a simplified integration strategy 
# through the command 
# control.inla = list(int.strategy = "eb"), 
# i.e. empirical Bayes.
r2.s <- inla(formula.inla, family="binomial",
             data=inla.stack.data(stk.all),
             control.predictor=list(A=inla.stack.A(stk.all),
                                    compute=TRUE,link = 1),
             quantiles=NULL,
             control.results=list(return.marginals.random=F,
                                  return.marginals.predictor=F),
             verbose=TRUE,
             control.inla = list(int.strategy = "eb"))

# extract the indices to the prediction nodes and 
# then extract the mean and the standard deviation 
# of the response 
id.prd <- inla.stack.index(stk.all, "prd")$data
sd.prd <- m.prd <- matrix(NA, nxy[1], nxy[2])

xy.in <- c(0<1:dim(coord.prd)[1])


m.prd[xy.in] <- r2.s$summary.fitted.values$mean[id.prd]
sd.prd[xy.in] <- r2.s$summary.fitted.values$sd[id.prd]

# plot the results
grid.arrange(levelplot(m.prd, col.regions=tim.colors(99),
                       xlab="", ylab="", main="mean",
                       scales=list(draw=FALSE)),
             levelplot(sd.prd, col.regions=topo.colors(99),
                       xlab="", ylab="",
                       scales=list(draw=FALSE),
                       main="standard deviation"))

# to data frame
m.prd <- as.data.frame(as.vector(m.prd))
m.prd$x <- coord.prd$Var1
m.prd$y <- coord.prd$Var2
m.prd$predict10 <- ifelse(m.prd[1] > 0.5,1,0)

# plot
ggplot()+
  geom_tile(data=m.prd,aes(x=x, y=y, fill=m.prd[1]))+
  geom_tile(data=m.prd[m.prd$predict10==1,],aes(x=x, y=y), alpha=0.4, fill="blue")+
  geom_tile(data=newdata[newdata$lc==1,],aes(x=x, y=y), fill="red", alpha=0.4)+
  coord_equal()


