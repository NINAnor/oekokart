# needed libraries
library(gridExtra)
library(ggplot2)
library(lattice)
library(INLA)
library(splancs)
library(fields)
library(raster)

# ---------------------------- #
# ---- EXAMINING THE DATA ---- #
# ---------------------------- #

# load data
setwd("/data/home/zofie.cimburova/ECOFUNC/DATA/")

data(PRprec) # data frame - 616 obs., 368 var.
data(PRborder) # matrix - points defining border

forest_line <- read.csv("variables.csv")

# extract response variable: height of forest line
Y <- forest_line$height

# find observations with non-missing values
ind <- !is.na(Y)

# observations with non-missing values (6978)
Y <- Y[ind]

# take random subset of observations
sample <- rbinom(length(Y),1,.1)
sample <- sample==1

Y <- Y[sample]

# locations with non-missing values, sampled
coords <- as.matrix(forest_line[ind,1:2])
coords <- as.matrix(forest_line[sample,1:2])

# predictors at locations with non-missing values, sampled
predictors <- forest_line[,c("BIO11","BIO12","aspect","slope","TPI1010")]
predictors <- predictors[ind,]
predictors <- predictors[sample,]

# plot precipitation at locations
ggplot() +
  geom_point(aes(x=coords[,1],y=coords[,2],colour=Y), size=2,
             alpha=1) +
  scale_colour_gradientn(colours=tim.colors(100)) #+
  #geom_path(aes(x=PRborder[,1],y=PRborder[,2])) +
  #geom_path(aes(x=PRborder[1034:1078,1],
  #              y=PRborder[1034:1078,2]), colour="red")

# calculate distance to coastline for each point 
# (this will be one of covariates)
#seaDist <- apply(spDists(coords, PRborder[1034:1078,],
#                         longlat=TRUE), 1, min)

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
# naive approach - triangulate observation points
m.bad <- inla.mesh.create(coords)
plot(m.bad, asp=1, main="")
lines(PRborder, col=3)

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
#lines(PRborder, col=3)
points(coords[,1], coords[,2], pch=19, cex=.5, col="red")

# mesh based on non-convex hull
# => smaller comp. time
prdomain <- inla.nonconvex.hull(points = coords,
                                convex = -0.03, # minimal convex curvature radius (fraction)
                                concave = -0.05, # minimal concave curvature radius
                                resolution=c(100,100)) # internal computation resolution
prmesh <- inla.mesh.2d(boundary = prdomain,
                       max.edge = 1000,
                       cutoff= 100)
plot(prmesh, asp=1, main="")
#lines(PRborder, col=3)
points(coords[,1], coords[,2], pch=19, cex=.5, col="red")

# 2. the observation matrix A
# connects the mesh to the observation locations
# weights
A <- inla.spde.make.A(mesh = prmesh, # inla mesh
                      loc=coords) # observation/prediction coordinates

# spde model object for a Matern model
spde <- inla.spde2.matern(mesh = prmesh, # The mesh to build the model on
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
                                        BIO11=inla.group(predictors$BIO11),
                                        BIO12=inla.group(predictors$BIO12),
                                        aspect=inla.group(predictors$aspect),
                                        slope=inla.group(predictors$slope),
                                        TPI1010=inla.group(predictors$TPI1010))))
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
f.s <- y ~ -1 + Intercept + f(BIO11, model="rw1") + 
  f(BIO12, model="rw1") + f(aspect, model="rw1") +
  f(slope, model="rw1") + f(TPI1010, model="rw1") + 
  f(field, model=spde)

r.s <- inla(f.s, family="gaussian",
            data=inla.stack.data(stk.dat), verbose=TRUE,
            control.predictor=list(A=inla.stack.A(stk.dat),
                                   compute=TRUE))

# ----------------- #
# ---- RESULTS ---- #
# ----------------- #
# summaries of the posterior distributions 
# for the parameters, for example the fixed 
# effects (i.e. the intercept) and the 
# hyper-parameters (i.e. dispersion in the 
# gamma likelihood, the precision of the RW1, 
# and the   parameters of the spatial-field)
r.s$summary.fixed
r.s$summary.hyperpar

#  posterior distributions for the range and 
# variance parameters
r.f <- inla.spde2.result(r.s, "field", spde, do.transf=TRUE)

# posterior mean
inla.emarginal(function(x) x,
               r.f$marginals.variance.nominal[[1]])

# posterior distributions for the hyper-parameters
par(mfrow=c(2,3))
plot(r.s$marginals.fix[[1]], type="l", xlab="Intercept",
     ylab="Density")
plot(r.s$marginals.hy[[1]], type="l", ylab="Density",
     xlab=expression(phi))
plot.default(r.f$marginals.variance.nominal[[1]], type="l",
             xlab=expression(sigma[x]^2), ylab="Density")
plot.default(r.f$marginals.range.nominal[[1]], type="l",
             xlab="Practical range", ylab="Density")

# plot random effect for the distance to the sea covariate
# as well as a pointwise confidence band for it
plot(r.s$summary.random$seaDist[,1:2], type="l",
     xlab="Distance to sea (Km)", ylab="random effect")
abline(h=0, lty=3)
for (i in c(4,6))
  lines(r.s$summary.random$seaDist[,c(1,i)], lty=2)

# posterior precision of the random effect
plot(r.s$marginals.hy[[2]], type="l", ylab="Density",
     xlab=names(r.s$marginals.hy)[2])

# ----------------------------------------- #
# ---- Calculating kriging predictions ---- #
# ----------------------------------------- #
# prediction of expected precipitation

bio11 <- raster("SAMPLE/temp_height_car.tif", band=1)
projection(bio11) <- "+proj=utm +zone=33 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs"

# aggregate to coarser resolution
bio11.aggregate <- aggregate(bio11, fact=5)

# locations of prediction
coord.prd.x <- xFromCol(bio11.aggregate, c(1:bio11.aggregate@ncols))
coord.prd.y <- yFromRow(bio11.aggregate, c(1:bio11.aggregate@nrows))
coord.prd <- expand.grid(coord.prd.x, coord.prd.y)

# create grid of size of prediction grid
nxy <- c(bio11.aggregate@nrows, bio11.aggregate@ncols)

# Calculate a lattice projection to/from an inla.mesh
projgrid <- inla.mesh.projector(mesh = prmesh,
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

# set predictors
seaDist.prd <- bio11.aggregate@data@values

# stack for the prediction locations
ef.prd = list(c(mesh.index,list(Intercept=1)),
              list(long=inla.group(coord.prd[,1]),
                   lat=inla.group(coord.prd[,2]),
                   BIO11=inla.group(seaDist.prd),
                   BIO12=inla.group(seaDist.prd),
                   aspect=inla.group(seaDist.prd),
                   slope=inla.group(seaDist.prd),
                   TPI1010=inla.group(seaDist.prd)))

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
r2.s <- inla(f.s, family="Gaussian",
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

