####################
# 1. Load the data #
####################

datacaribou <- read.table("/data/home/zofie.cimburova/ECOFUNC/R_codes/EXAMPLES/Appendices_data_Beguin_etal_MEE2012/data_caribou.txt", sep='', header=TRUE)
str(datacaribou)

nrow = 51
ncol = 44

##################################################
# 2. Non-spatial logistic model fitted with INLA #
##################################################
require(INLA)
formula_logistic <- y ~ wildfire + logging + lichwood + openlich + deciduous + water + wetland + meanelev
model_logistic <- inla(formula = formula_logistic, 
                       data = datacaribou, 
                       family = 'binomial', 
                       Ntrials = Ntrials,
                       control.compute = list(dic=TRUE),
                       control.fixed = list(prec.intercept=0.001),
                       verbose=F)
summary(model_logistic)

#############################################
# 4. Bayesian Matern model fitted with INLA #
#############################################
require(INLA)
nrow.larger = 51
ncol.larger = 44
log.range = list(initial = log(5), fixed=TRUE)
hyperpar_matern = list(initial=-3, param=c(23.36,0.001))
formula_matern = y~wildfire + logging + lichwood + openlich + deciduous + water + wetland + meanelev + 
                   f(node_matern, model="matern2d",nrow=nrow.larger,
                     ncol=ncol.larger, hyper=list(range=log.range, prec=hyperpar_matern))
model_matern = inla(formula=formula_matern,
                    data=datacaribou,
                    family="binomial",
                    Ntrials=Ntrials,
                    control.compute=list(dic=TRUE),
                    control.fixed = list(prec.intercept=0.001),
                    verbose=F)
summary(model_matern)



# visualize
vis.data <- expand.grid(seq(1:nrow.larger),seq(1:ncol.larger))
names(vis.data) <- c("x","y")

vis.data.raster <- rasterFromXYZ(vis.data)        
vis.data$node_matern <- cellFromXY(vis.data.raster,cbind(vis.data$x, vis.data$y))
vis.data <- merge(vis.data, datacaribou, by="node_matern",all=TRUE )

ggplot() + geom_tile(data=vis.data, aes(x=x, y=y.x, fill=wildfire)) + scale_y_reverse() 



