# create data frame
data.df <- data.frame(x = c(1,2,3,4,
                            1,2,3,4,
                            1,2,3,4,
                            1,2,3,4,
                            1,2,3,4))
data.df$y <- c(1,1,1,1,
               2,2,2,2,
               3,3,3,3,
               4,4,4,4,
               5,5,5,5)
data.df$val <- c(1/2,2/3,3/4,4/5,
                 1/4,1/3,1/2,2/3,
                 1/5,1/3,1/2,2/3,
                 0,1/4,1/3,1/3,
                 1/5,1/6,0,0)
data.df$pred <- c(0,1,2,3,-2,-1,0,1,-3,-1,0,1,-4,-5,-1,-1,-5,-4,-2,-3)

# data frame to raster
#library(raster)
#data.raster <- rasterFromXYZ(data.df)        
#plot(data.raster)

# get cell number
require(INLA)
nrows=5
ncols=4
data.df$ID <- NA
for (i in seq(1,nrows,1)){
  for (j in seq(1,ncols,1)){
    data.df[data.df$x==j & data.df$y==nrows+1-i,]$ID = inla.lattice2node(i, j, nrows, ncols)
  }
}


# order by ID
data.df <- data.df[order(data.df$ID),]

#ggplot() + geom_tile(data=data.df, aes(x=x, y=y, fill=val)) + coord_equal()
#ggplot() + geom_tile(data=data.df, aes(x=x, y=y, fill=pred)) + coord_equal()
#ggplot() + geom_tile(data=data.df, aes(x=x, y=y, fill=ID)) + coord_equal()

# inla

# formula
formula_matern_spatial <- val ~ pred + f(ID, model='matern2d',
                                      nrow=nrows, 
                                      ncol=ncols, 
                                      nu=1, # 1, 2 or 3
                                      hyper=list(range=list(initial=1, fixed=TRUE),
                                                 prec=list(initial=1, fixed=TRUE)))
                                      #hyper=list(range=list(prior="loggamma", # log of range
                                      #                      param=c(1,1), # params of prior distribution - shape, scale
                                      #                      initial=1), # may be fixed=TRUE in case we know range of autocorrelation
                                      #           prec=list(prior="loggamma", # log of precision
                                      #                     param=c(1,1), # params of prior distribution - shape, scale
                                      #                     initial=1)))

# fit model
model_matern <- inla(formula=formula_matern_spatial,
                     data=data.df,
                     family='binomial',
                     Ntrials=1,
                     control.compute=list(dic=TRUE),
                     control.fixed=list(prec.intercept=0.001),
                     verbose=F,
                     control.predictor=list(link=1))
# model summary
summary(model_matern)

# prediction of fitted values
#model_matern$summary.fitted.values

# random effects for each data point
#model_matern$summary.random 

# fixed effects
#model_matern$summary.fixed

data.df$fitted <- model_matern$summary.fitted.values$mean
data.df$random <- model_matern$summary.random$ID$mean
data.df$residuals <- data.df$val - data.df$fitted


require(gridExtra)

plot0 <- ggplot() + geom_tile(data=data.df, aes(x=x, y=y, fill=val)) + coord_equal() + labs(title="Observed values")
plot1 <- ggplot() + geom_tile(data=data.df, aes(x=x, y=y, fill=fitted)) + coord_equal()+ labs(title="Fitted values")
plot2 <- ggplot() + geom_tile(data=data.df, aes(x=x, y=y, fill=random)) + coord_equal()+ labs(title="Random effects")
plot3 <- ggplot() + geom_tile(data=data.df, aes(x=x, y=y, fill=fitted-val)) + coord_equal()+ labs(title="Residuals")
grid.arrange(plot0, plot1, plot2, plot3, ncol=2)



