data(SPDEtoy)

SPDEtoy_geog <- SPDEtoy
coordinates(SPDEtoy_geog) <- ~s1+s2
bubble(SPDEtoy_geog,zcol='y',main="SPDEtoy example")

# 1. construct mesh
coords <- as.matrix(SPDEtoy[,1:2]) 
mesh0 <- inla.mesh.2d(loc=coords, max.edge=0.1) 
mesh1 <- inla.mesh.2d(loc=coords, max.edge=c(0.1, 0.1)) 
mesh2 <- inla.mesh.2d(loc=coords, max.edge=c(0.1, 0.2))
mesh3 <- inla.mesh.2d(loc=coords, max.edge=c(0.1, 0.2), offset=c(0.4,0.1))
mesh4 <- inla.mesh.2d(loc=coords, max.edge=c(0.1, 0.2), offset=c(0.1,0.4))
domain <- matrix(cbind(c(0,1,1,0.7,0), c(0,0,0.7,1,1)),ncol=2)
mesh5 <- inla.mesh.2d(loc.domain=domain, max.edge=c(0.04, 0.2), cutoff=0.015, offset = c(0.1, 0.4))
mesh6 <- inla.mesh.2d(loc.domain=domain, max.edge=c(0.04, 0.2), cutoff=0.05, offset = c(0.1, 0.4))
bnd <- inla.nonconvex.hull(as.matrix(coords),convex=0.07)
mesh7 <- inla.mesh.2d(loc=coords, boundary=bnd, max.edge=c(0.04, 0.2), cutoff=0.05, offset = c(0.1, 0.4))

plot(mesh7, main="") 
#Include data locations: 
points(coords, pch=21, bg=1, col="white", cex=1.8)

# 2. the observation matrix
A.est1 <- inla.spde.make.A(mesh=mesh1, loc=coords)
A.est6 <- inla.spde.make.A(mesh=mesh6, loc=coords)

# 3. model fitting
spde <- inla.spde2.matern(mesh=mesh6, alpha=2)
formula <- y ~ -1 + intercept + f(spatial.field, model=spde)
output6 <- inla(formula, 
                data = list(y=SPDEtoy$y, intercept=rep(1,spde$n.spde), 
                            spatial.field=1:spde$n.spde), 
                control.predictor=list(A=A.est6,compute=TRUE))
# 4. prediction
grid.x <- 50
grid.y <- 50
pred.grid <- expand.grid(x = seq(0, 1, length.out = grid.x), 
                         y = seq(0, 1, length.out = grid.y))

A.pred6 <- inla.spde.make.A(mesh=mesh6, loc=as.matrix(pred.grid))
stack.pred.latent <- inla.stack(data=list(xi=NA), A=list(A.pred6), 
                                effects=list(s.index), tag="pred.latent")
stack.pred.response <- inla.stack(data=list(y=NA), A=list(A.pred6), 
                                  effects=list(c(s.index, list(intercept=1))), tag="pred.response")
join.stack <- inla.stack(stack.est, stack.pred.latent, stack.pred.response)
join.output <- inla(formula, data=inla.stack.data(join.stack), 
                    control.predictor=list(A=inla.stack.A(join.stack), compute=TRUE))





