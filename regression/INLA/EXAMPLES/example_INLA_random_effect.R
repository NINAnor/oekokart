# subset
toy_data <- input_data_na_rm.scaled[input_data_na_rm.scaled$x <   295000 & 
                                      input_data_na_rm.scaled$x >=  290000 & 
                                      input_data_na_rm.scaled$y <  6905000 & 
                                      input_data_na_rm.scaled$y >= 6900000,]
nrows.toy=ncols.toy=5

toy_data$row <- toy_data$row - min(toy_data$row) + 1
toy_data$col <- toy_data$col - min(toy_data$col) + 1
toy_data$ID <- inla.lattice2node(toy_data$row, toy_data$col, nrows.toy, ncols.toy)

#toy_data <- toy_data[sample(1:nrow(toy_data)), ]
toy_data <- toy_data[order(toy_data$ID),]

toy_data$lc_proportion <- c(NA,1,NA,1,NA,
                            1,NA,1,NA,1,
                            NA,1,NA,1,NA,
                            1,NA,1,NA,1,
                            NA,1,NA,1,NA)

ggplot() + geom_tile(data=toy_data, aes(x=x, y=y, fill=lc_proportion)) + coord_equal()

require(INLA)

range1=1
precision1=100000
nu1=1

formula.matern.toy <- lc_proportion ~ 1 + 
  f(ID, model='matern2d',
    nrow=ncols.toy, ncol=ncols.toy, nu=nu1)#, 
    #hyper=list(range=list(initial=log(range1), fixed=TRUE), 
    #           prec=list(initial=log(precision1), fixed=TRUE))) 

matern.toy <- inla(formula=formula.matern.toy,
                        data=toy_data,
                        family='binomial',
                        Ntrials=1,
                        verbose=F,
                        control.inla=list(tolerance=1e-6),
                        control.compute=list(dic=TRUE, waic=TRUE), # compute DIC, WIFC (smaller better)
                        control.fixed=list(prec.intercept=0.001), # can be omitted
                        control.predictor=list(link=1)) 

# fitted values (DO NOT SHUFFLE INPUT DATA FRAME!!!)
toy_data <- append.fitted(toy_data, matern.toy$summary.fitted.values, "fitted_values1")

# random effects
toy_data <- append.random(toy_data, matern.toy$summary.random$ID, "random.mean1")

# residuals
toy_data$residual1 <- toy_data$lc_proportion - toy_data$fitted_values1

toy_data$predicted.values1 <- logit.inv(matern.toy$summary.fixed$mean[1])

toy_data$predicted.values.rand1 <- logit.inv(logit(toy_data$predicted.values1) + logit(toy_data$random.mean1))



ggplot() + geom_tile(data=toy_data, aes(x=x, y=y, fill=lc_proportion)) + coord_equal() + ggtitle("original data") +  scale_fill_gradient(limits=c(0,1), low = "bisque3", high = "darkgreen")

ggplot() + geom_tile(data=toy_data, aes(x=x, y=y, fill=random.mean1)) + 
  coord_equal() + 
  ggtitle("random effect 1") +  
  scale_fill_gradient2(limits=c(min(toy_data$random.mean1),max(toy_data$random.mean1)), low = "blue", mid="bisque3",high = "red",midpoint = median(toy_data$random.mean1))

ggplot() + geom_tile(data=toy_data, aes(x=x, y=y, fill=fitted_values1)) + coord_equal() + ggtitle("fitted values 1") +  scale_fill_gradient(limits=c(0,1), low = "bisque3", high = "darkgreen")

ggplot() + geom_tile(data=toy_data, aes(x=x, y=y, fill=residual1)) + coord_equal() + ggtitle("residuals 1") + scale_fill_gradient2(limits=c(-1,1), low = "dodgerblue2", mid = "cornsilk1", high = "red2", midpoint = 0)


# matern field
size = 1

# prepare distance matrix
distances <- vector()

for (row in -size:size){
  for (col in -size:size){
    distances <- c(distances,sqrt(row*row + col*col))
  }
}

distance.matrix <- matrix(data = distances, nrow = 2*size+1, ncol = 2*size+1) 
centre <- size+1

matern.matrix <- maternINLA(distance.matrix,1,1)[,6:10]

print(distance.matrix)
print(matern.matrix)

ind <- which( ! is.na(matern.matrix) , arr.ind = TRUE ) 

#  cbind indices to values
matern.df <- cbind( matern.matrix[ ! is.na( matern.matrix ) ] , ind )
matern.df <- as.data.frame( matern.df )

ggplot() + geom_tile(data=matern.df, aes(x=col, y=row, fill=V1)) + coord_equal()

