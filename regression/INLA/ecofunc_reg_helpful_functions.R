# significance test
cor.mtest <- function(mat, conf.level = 0.95){
  mat <- as.matrix(mat)
  n <- ncol(mat)
  p.mat <- lowCI.mat <- uppCI.mat <- matrix(NA, n, n)
  diag(p.mat) <- 0
  diag(lowCI.mat) <- diag(uppCI.mat) <- 1
  for(i in 1:(n-1)){
    for(j in (i+1):n){
      tmp <- cor.test(mat[,i], mat[,j], conf.level = conf.level)
      p.mat[i,j] <- p.mat[j,i] <- tmp$p.value
      lowCI.mat[i,j] <- lowCI.mat[j,i] <- tmp$conf.int[1]
      uppCI.mat[i,j] <- uppCI.mat[j,i] <- tmp$conf.int[2]
    }
  }
  return(list(p.mat, lowCI.mat, uppCI.mat))
}

getSpatialAutocorr<-function(df,Var,Increment=10){
  require(ncf) 
  df<-subset(df,!is.na(df[,Var]))
  index = sample(1:length(df$x),1000,replace = F)
  co = correlog(df$x[index],df$y[index],df[,Var][index],increment = Increment,resamp = 0, 
                latlon = F,na.rm=T)
  co_df<-data.frame(Distance=co[["mean.of.class"]],Corr=co[["correlation"]],Type=Var)
  return(co_df)
}

# Multiple plot function
#
# ggplot objects can be passed in ..., or to plotlist (as a list of ggplot objects)
# - cols:   Number of columns in layout
# - layout: A matrix specifying the layout. If present, 'cols' is ignored.
#
# If the layout is something like matrix(c(1,2,3,3), nrow=2, byrow=TRUE),
# then plot 1 will go in the upper left, 2 will go in the upper right, and
# 3 will go all the way across the bottom.
#
multiplot <- function(..., plotlist=NULL, file, cols=1, layout=NULL) {
  library(grid)
  
  # Make a list from the ... arguments and plotlist
  plots <- c(list(...), plotlist)
  
  numPlots = length(plots)
  
  # If layout is NULL, then use 'cols' to determine layout
  if (is.null(layout)) {
    # Make the panel
    # ncol: Number of columns of plots
    # nrow: Number of rows needed, calculated from # of cols
    layout <- matrix(seq(1, cols * ceiling(numPlots/cols)),
                     ncol = cols, nrow = ceiling(numPlots/cols))
  }
  
  if (numPlots==1) {
    print(plots[[1]])
    
  } else {
    # Set up the page
    grid.newpage()
    pushViewport(viewport(layout = grid.layout(nrow(layout), ncol(layout))))
    
    # Make each plot, in the correct location
    for (i in 1:numPlots) {
      # Get the i,j matrix positions of the regions that contain this subplot
      matchidx <- as.data.frame(which(layout == i, arr.ind = TRUE))
      
      print(plots[[i]], vp = viewport(layout.pos.row = matchidx$row,
                                      layout.pos.col = matchidx$col))
    }
  }
}

# Matern covariance function used in INLA
# d   distance 
# v   nu, smoothness (1,2,3)
# r   range
maternINLA <- function(d,v,r){
  kappa <-  2*sqrt(2*v)/r # scale
  C <- data.frame(d=d,
                  matern = 1/(2^(v-1)*gamma(v)) * (kappa*d)^v * besselK(kappa*d,v))
  return(C)
}


# Moran's I correlogram
# x             vector of coordinates x of observation points
# y             vector of coordinates y of observation points
# lc_proportion vector of observations at observation points
# lim.dist      limit distance to compute correlation [no.cells] (half)
# width         width of bin [no.cells]

moransICorrelogram <- function(x,y,lc_proportion,lim.dist,width){
    
  # prepare input raster                           
  library(raster)                           
  raster <- rasterFromXYZ(cbind(x,y,lc_proportion))
  
  # prepare distance matrix
  distances <- vector()

  for (row in -lim.dist:lim.dist){
    for (col in -lim.dist:lim.dist){
      distances <- c(distances,sqrt(row*row + col*col))
    }
  }

  distance.matrix <- matrix(data = distances, nrow = 2*lim.dist+1, ncol = 2*lim.dist+1) 
  centre <- lim.dist+1
  
  # compute Moran's I in bins
  M.lags <- data.frame("x"=double(), "moran"=double())
  i = 1
  for (bin in seq(1,lim.dist,width)){
    # limit distances for bins
    lim.lower <- bin
    lim.upper <- bin + width
    
    # compute weight matrix
    weight.matrix <- (distance.matrix >= lim.lower & distance.matrix < lim.upper)*1
    
    # shrink weight matrix
    border.lower <- max(0,centre-lim.upper+1)
    border.upper <- min(centre+lim.upper-1,nrow(distance.matrix))
    
    weight.matrix <- weight.matrix[border.lower:border.upper,border.lower:border.upper]
    
    # compute Moran's I
    M.lags[i,]$x <- (lim.lower+lim.upper)/2
    M.lags[i,]$moran <- Moran(raster, w=weight.matrix) 
    i <- i+1
    
  }
  return(M.lags)
}

# Logit function
logit <- function(x){
  return(log(x/(1-x)))
}

# Inverse logit function
logit.inv <- function(x){
  return(exp(x)/(1+exp(x)))
}


# Append spatial random effect to input data frame
# input.data    data frame of input data
# random.effect data frame of random effect, containing ID
# column.name   name of column to be appended to
append.random <- function(input.data, random.effect, column.name) {

  random.effect <- random.effect[,c("ID","mean")]
  colnames(random.effect)[2] <- column.name
  
  output.data <- merge(x = input.data, y = random.effect, by = "ID", all.x = TRUE)
  output.data[,column.name] <- logit.inv(output.data[,column.name])
  return(output.data)
}

# Append fitted values to input data frame
# input.data    data frame of input data
# fitted.values data frame of fitted values
# column.name   name of column to be appended to
append.fitted <- function(input.data, fitted.values, column.name) {
  
  output.data <- input.data
  output.data[,column.name] <- fitted.values$mean
  return(output.data)
}


# Moran's I
morans.I.spdep <- function(input.data.frame, dist.neighbours, col.name){
  library(spdep)
  
  # convert spatial points back to data frame
  if (class(input.data.frame) == "SpatialPointsDataFrame") {
    input.data.frame <- as.data.frame(input.data.frame)
  }
  
  # convert input data frame to spatial points
  coordinates(input.data.frame)=~x+y
 
  # take nearest n neighbours
  nearest.neighbours <- dnearneigh(input.data.frame, d1=0, d2=dist.neighbours)
  
  # compute spatial weights (equal)
  spatial.weights <- nb2listw(nearest.neighbours)
  
  # convert spatial points back to data frame
  if (class(input.data.frame) == "SpatialPointsDataFrame") {
    input.data.frame <- as.data.frame(input.data.frame)
  }
  
  # perform moran's I test
  test <- moran.test(input.data.frame[,col.name],spatial.weights)
  
  # H0: zero spatial autocorrelation
  # small p0 => reject H0
  if (test$p.value < 0.05) {
    if (test$estimate[1] > 0) {
      return(paste("positive spatial autocorrelation ", test$estimate[1]))
    }
    else {
      return(paste("negative spatial autocorrelation", test$estimate[1]))
    }
  }
  else {
    return(paste("no spatial autocorrelation", test$estimate[1]))
  }
  
}

morans.I.ape <- function(input.data.frame, distance.limit, col.name) {
  library(ape)
  
  #input.data.frame <- sample.moran.I
  #distance.limit <- 1
  #col.name <- "diff.res2"
  
  # distance matrix for each pair
  distances <- as.matrix(dist(cbind(input.data.frame$x, input.data.frame$y)))
  
  # inverse distance matrix = weights
  #distances.inv <- 1/distances
  #diag(distances.inv) <- 0
  #distances.inv <- distances.inv/rowSums(distances.inv)
  
  distances.inv <- distances
  distances.inv[distances.inv <= distance.limit] = 1
  distances.inv[distances.inv > distance.limit] = 0
  diag(distances.inv) <- 0
  
  # Moran's I
  test <- Moran.I(input.data.frame[,col.name], distances.inv) 
  
  if (test$p.value < 0.05) {
    if (test$observed > 0) {
      return(paste("positive spatial autocorrelation ", test$observed))
    }
    else {
      return(paste("negative spatial autocorrelation", test$observed))
    }
  }
  else {
    return(paste("no spatial autocorrelation", test$observed))
  }
}



