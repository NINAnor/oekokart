library(geoR)
data(gambia)

coords <- as.matrix(gambia[,1:2])/1000
Y <- gambia$pos

ggplot() +
  geom_point(aes(x=coords[,1],y=coords[,2],colour=Y), size=2,
             alpha=1) +
  scale_colour_gradientn(colours=tim.colors(100)) 

# assign index to each village


# 1. the mesh
bnd <- inla.nonconvex.hull(coords,convex=-0.1)
gambia.mesh <- inla.mesh.2d(boundary = bnd, offset=c(30, 60), max.edge=c(20,40))

plot(gambia.mesh, main="") 
points(coords, pch=21, bg=1, col="white", cex=1.8)

# 2. spde object, A matrixm indexes for spatial effect
gambia.spde <- inla.spde2.matern(mesh=gambia.mesh, alpha=2)
A.est <- inla.spde.make.A(mesh=gambia.mesh, loc=coords)
s.index <- inla.spde.make.index(name="spatial.field", n.spde=gambia.spde$n.spde)

# 3. stack
gambia.stack.est <- inla.stack(data=list(y=gambia$pos), 
                               A=list(A.est, 1, 1, 1, 1, 1, 1), 
                               effects=list(c(s.index, list(Intercept=1)), 
                                            list(age=gambia$age/365), 
                                            list(treated=gambia$treated),
                                            list(netuse=gambia$netuse), 
                                            list(green=gambia$green),
                                            list(phc=gambia$phc),
                                            list(village.index=gambia$x)),
                               tag="est")

# 4. result
formula <- y ~ -1 + Intercept + treated + netuse + age + green + phc + 
  f(spatial.field, model=gambia.spde) + f(village.index, model="iid")

gambia.output <- inla(formula, data=inla.stack.data(gambia.stack.est, spde=gambia.spde), 
                      family="binomial",Ntrials=1, 
                      control.predictor=list(A=inla.stack.A(gambia.stack.est), compute=TRUE), 
                      control.compute=list(dic=TRUE))





