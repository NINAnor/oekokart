# needed libraries
library(gridExtra)
library(ggplot2)
library(lattice)
library(INLA)
library(splancs)
library(fields)

# ---------------------------- #
# ---- EXAMINING THE DATA ---- #
# ---------------------------- #

# load data and border of region
data(PRprec) # data frame - 616 obs., 368 var.
data(PRborder) # matrix - points defining border

# extract only total precipitation in January (616)
Y <- rowMeans(PRprec[,3+1:31])

# find observations with non-missing values
ind <- !is.na(Y)

# observations with non-missing values (604)
Y <- Y[ind]

# locations with non-missing values (604)
coords <- as.matrix(PRprec[ind,1:2])

# altitude at locations with non-missing values (604) 
alt <- PRprec$Altitude[ind]

# plot precipitation at locations
ggplot() +
  geom_point(aes(x=coords[,1],y=coords[,2],colour=Y), size=2,
             alpha=1) +
  scale_colour_gradientn(colours=tim.colors(100)) +
  geom_path(aes(x=PRborder[,1],y=PRborder[,2])) +
  geom_path(aes(x=PRborder[1034:1078,1],
                y=PRborder[1034:1078,2]), colour="red")

# calculate distance to coastline for each point 
# (this will be one of covariates)
seaDist <- apply(spDists(coords, PRborder[1034:1078,],
                         longlat=TRUE), 1, min)

# correlation coefficients
r_lon = cor(Y,coords[,1],use="complete.obs")
r_lat = cor(Y,coords[,2],use="complete.obs")
r_seaDist = cor(Y,seaDist,use="complete.obs")
r_alt = cor(Y,alt,use="complete.obs")


# Plot precipitation as a function of the possible covariates
# longitude
# latitude
# distance to sea
# altitude - discarded from analysis, because it's available 
#            only at measured locations, but not around

par(mfrow=c(2,2))
plot(coords[,1], Y, cex=.5, xlab=paste("Longitude", toString(r_lon)))
plot(coords[,2], Y, cex=.5, xlab=paste("Latitude", toString(r_lat)))
plot(seaDist, Y, cex=.5, xlab=paste("Distance to sea", toString(r_seaDist)))
plot(alt, Y, cex=.5, xlab=paste("Altitude", toString(r_alt)))

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
m1 <- inla.mesh.2d(coords, max.edge=c(.45,1), cutoff=0.2)
plot(m1, asp=1, main="")
lines(PRborder, col=3)
points(coords[,1], coords[,2], pch=19, cex=.5, col="red")

# mesh based on non-convex hull
# => smaller comp. time
prdomain <- inla.nonconvex.hull(coords, -0.03, -0.05,
                                resolution=c(100,100))
prmesh <- inla.mesh.2d(boundary=prdomain, max.edge=c(.45,1),
                       cutoff=0.2)
plot(prmesh, asp=1, main="")
lines(PRborder, col=3)
points(coords[,1], coords[,2], pch=19, cex=.5, col="red")

# 2. the observation matrix A
# connects the mesh to the observation locations
# weights
A <- inla.spde.make.A(prmesh, loc=coords)

# spde model
# choose 
spde <- inla.spde2.matern(prmesh, alpha=2)

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
                                        seaDist=inla.group(seaDist))))
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
f.s <- y ~ -1 + Intercept + f(seaDist, model="rw1") +
  f(field, model=spde)

r.s <- inla(f.s, family="Gamma",
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

# create grid 150 x 100 locations
nxy <- c(150,100)
projgrid <- inla.mesh.projector(prmesh,
                                xlim=range(PRborder[,1]),
                                ylim=range(PRborder[,2]),
                                dims=nxy)
# find cells outside of area of interest
xy.in <- inout(projgrid$lattice$loc,
               cbind(PRborder[,1], PRborder[,2]))

# locations of prediction
coord.prd <- projgrid$lattice$loc[xy.in,]
plot(coord.prd, type="p", cex=.1)
lines(PRborder)
points(coords[,1], coords[,2], pch=19, cex=.5, col="red")

# calculate the prediction jointly with the
# estimation, which unfortunately is quite 
# computationally expensive if we do prediction
# on a fine grid.

# link the prediction coordinates to the mesh nodes 
# through an A matrix
A.prd <- projgrid$proj$A[xy.in, ]

# calculate distance to sea for prediction locations
seaDist.prd <- apply(spDists(coord.prd, PRborder[1034:1078,],
                             longlat=TRUE), 1, min)

# stack for the prediction locations
ef.prd = list(c(mesh.index,list(Intercept=1)),
              list(long=inla.group(coord.prd[,1]),
                   lat=inla.group(coord.prd[,2]),
                   seaDist=inla.group(seaDist.prd)))

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
r2.s <- inla(f.s, family="Gamma",
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

