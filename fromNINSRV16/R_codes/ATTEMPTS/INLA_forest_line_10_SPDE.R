setwd("/data/home/zofie.cimburova/ECOFUNC/DATA/SAMPLE")


# 1. load data
lc <- raster("binom_lc.tif", band=1)
projection(lc) <- "+proj=utm +zone=33 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs"

bio01 <- raster("binom_bio01.tif", band=1)
projection(bio01) <- "+proj=utm +zone=33 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs"

tpi <- raster("binom_tpi.tif", band=1)
projection(tpi) <- "+proj=utm +zone=33 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs"
 
input_rasters <- brick(lc, bio01, tpi)
names(input_rasters) <- c('lc','tpi','bio01')

## random samples
observations <- sampleRandom(input_rasters, 200, na.rm=TRUE, xy=TRUE)
observations <- as.data.frame(observations)

# 2. formula
formula <- lc ~ 1 + tpi + bio01
Y <- observations$lc
predictors <- observations[,c('tpi','bio01')]

# LINEAR MODEL
model.glm <- glm(formula, data=observations, family=binomial(link='logit'))
summary(model.glm)

# INLA
model.inla <- inla(formula, data=observations, family="binomial", control.family = list(link = "logit"))
summary(model.inla)
# plot posterior marginal distributions
beta0_post <- model.inla$marginals.fixed$`(Intercept)`
plot(beta0_post,type='l',main='Intercept',xlab=expression(beta[0]),
     ylab=expression(tilde(p)(paste(beta[0],"|",y))))

beta1_post <- model.inla$marginals.fixed$bio01
plot(beta1_post,type='l',main='bio01',xlab=expression(beta[1]),
    ylab=expression(tilde(p)(paste(beta[1],"|",y))))

beta2_post <- model.inla$marginals.fixed$tpi
plot(beta2_post,type='l',main='tpi',xlab=expression(beta[2]),
     ylab=expression(tilde(p)(paste(beta[2],"|",y))))

# INLA + SPATIAL
# 3. create the mesh 
coords <- as.matrix(observations[,1:2]) # coordinates

mesh0 <- inla.mesh.2d(loc=coords, max.edge=1000) # mesh
mesh1 <- inla.mesh.2d(loc=coords, max.edge=c(1000, 1000)) # mesh + buffer, equal triangles
mesh2 <- inla.mesh.2d(loc=coords, max.edge=c(1000, 2000)) # mesh + buffer, different triangles
mesh3 <- inla.mesh.2d(loc=coords, max.edge=c(1000, 2000), offset=c(4000,1000)) # mesh + offset + buffer
mesh4 <- inla.mesh.2d(loc=coords, max.edge=c(1000, 2000), offset=c(1000,4000)) # mesh + offset + buffer
#domain <- matrix(cbind(c(0,1,1,0.7,0), c(0,0,0.7,1,1)),ncol=2)
#mesh5 <- inla.mesh.2d(loc.domain=domain, max.edge=c(0.04, 0.2), cutoff=0.015, offset = c(0.1, 0.4))
#mesh6 <- inla.mesh.2d(loc.domain=domain, max.edge=c(0.04, 0.2), cutoff=0.05, offset = c(0.1, 0.4))
bnd <- inla.nonconvex.hull(as.matrix(coords),convex=400)
mesh7 <- inla.mesh.2d(loc=coords, boundary=bnd, max.edge=c(300, 1000), cutoff=200, offset = c(1000, 2000))
m1 <- inla.mesh.2d(loc = coords, # triangulation nodes
                   offset = 1000, # extension distance
                   max.edge=1000, # largest allowed triange edge length
                   cutoff=100) # minimum allowed distance between points

plot(mesh7, main="", asp=1) 
points(coords, pch=21, bg=1, col="white", cex=1.8)

# 4. spde object, A matrix, indexes for spatial effect
spde <- inla.spde2.matern(mesh=mesh7, alpha=2) # SPDE object, not much to change
A.est <- inla.spde.make.A(mesh=mesh7, loc=coords) # observation matrix
s.index <- inla.spde.make.index(name="spatial.field", n.spde=spde$n.spde)

formula <- Y ~ -1 + Intercept + bio01 + tpi + f(spatial.field, model=spde)
               # always SPDE
           

# 5. stack
stk.dat <- inla.stack(data=list(y=Y), 
                      A=list(A.est,1), 
                      tag="est",
                      effects=list(c(s.index,list(Intercept=1)),
                                   list(long=inla.group(coords[,1]),
                                   lat=inla.group(coords[,2]),
                                   bio01=inla.group(predictors$bio01),
                                   tpi=inla.group(predictors$tpi))))

# 6. fitting the model
mod.inla.sp <- inla(formula, 
                    data=inla.stack.data(stk.dat,spde=spde),
                    family="binomial",Ntrials=1,
                    control.family = list(link = "logit"),
                    control.predictor=list(A=inla.stack.A(stk.dat),compute=TRUE),
                    control.compute=list(dic=TRUE))
summary(mod.inla.sp)

# 7. prediction

# aggregate to coarser resolution
bio01.aggregate <- aggregate(bio01, fact=5)
tpi.aggregate <- aggregate(tpi, fact=5)

# locations of prediction
grid.x <- xFromCol(bio01.aggregate, c(1:bio01.aggregate@ncols))
grid.y <- yFromRow(bio01.aggregate, c(1:bio01.aggregate@nrows))
pred.grid <- expand.grid(grid.x,
                         grid.y)

A.pred7 <- inla.spde.make.A(mesh=mesh7, loc=as.matrix(pred.grid))

# stack for the prediction locations
ef.prd <- list(c(s.index,list(Intercept=1)),
               list(long=inla.group(pred.grid[,1]),
                    lat=inla.group(pred.grid[,2]),
                    bio01=inla.group(bio01.aggregate@data@values),
                    tpi=inla.group(tpi.aggregate@data@values)))

# no data at prediction locations => y=NA
stk.prd <- inla.stack(data=list(y=NA), A=list(A.pred7,1),
                      tag="prd", effects=ef.prd)

stk.all <- inla.stack(stk.dat, stk.prd)
stack.pred.latent <- inla.stack(data=list(y=NA), 
                                A=list(A.pred7,1),
                                tag="pred.latent", 
                                effects=ef.prd)
stack.pred.response <- inla.stack(data=list(y=NA), 
                                  A=list(A.pred7), 
                                  effects=list(c(s.index, list(Intercept=1))), 
                                  tag="pred.response")

join.stack <- inla.stack(stk.dat, stack.pred.latent, stack.pred.response)

join.output <- inla(formula, 
                    data=inla.stack.data(stk.all),
                    family="binomial",Ntrials=1,
                    control.family = list(link = "logit"),
                    control.predictor=list(A=inla.stack.A(stk.all),compute=TRUE,link = 1),
                    quantiles=NULL,
                    control.results=list(return.marginals.random=F,return.marginals.predictor=F),
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

