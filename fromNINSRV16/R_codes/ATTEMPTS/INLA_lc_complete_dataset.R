setwd("/home/zofie.cimburova/ECOFUNC/DATA/OBSERVATIONS")
source("/home/zofie.cimburova/git/oekokart/ecofunc_helpful_functions.R")

####################
# 1. load the data #
####################
input_data <- read.csv("variables_avg_med_std.csv")

# skip average values (median used instead)
input_data <- input_data[ , -which(names(input_data) %in% names(input_data)[c(4:29,32:41,45)])]

names(input_data)[names(input_data)=="dem_10m_nosefi_float_aspect_std"] <- "aspect_std"
names(input_data)[names(input_data)=="dem_10m_nosefi_float_aspect_med"] <- "aspect_med"
names(input_data)[names(input_data)=="dem_10m_nosefi_float_slope_std"] <- "slope_std"
names(input_data)[names(input_data)=="dem_10m_nosefi_float_slope_med"] <- "slope_med"
names(input_data)[names(input_data)=="dem_10m_nosefi_float_profc_std"] <- "curv_std"
names(input_data)[names(input_data)=="dem_10m_nosefi_float_profc_med"] <- "curv_med"
names(input_data)[names(input_data)=="dem_10m_topex_e_std"] <- "topex_e_std"
names(input_data)[names(input_data)=="dem_10m_topex_e_med"] <- "topex_e_med"
names(input_data)[names(input_data)=="dem_10m_topex_n_std"] <- "topex_n_std"
names(input_data)[names(input_data)=="dem_10m_topex_n_med"] <- "topex_n_med"
names(input_data)[names(input_data)=="dem_10m_topex_ne_std"] <- "topex_ne_std"
names(input_data)[names(input_data)=="dem_10m_topex_ne_med"] <- "topex_ne_med"
names(input_data)[names(input_data)=="dem_10m_topex_nw_std"] <- "topex_nw_std"
names(input_data)[names(input_data)=="dem_10m_topex_nw_med"] <- "topex_nw_med"
names(input_data)[names(input_data)=="dem_10m_topex_s_std"] <- "topex_s_std"
names(input_data)[names(input_data)=="dem_10m_topex_s_med"] <- "topex_s_med"
names(input_data)[names(input_data)=="dem_10m_topex_se_std"] <- "topex_se_std"
names(input_data)[names(input_data)=="dem_10m_topex_se_med"] <- "topex_se_med"
names(input_data)[names(input_data)=="dem_10m_topex_sw_std"] <- "topex_sw_std"
names(input_data)[names(input_data)=="dem_10m_topex_sw_med"] <- "topex_sw_med"
names(input_data)[names(input_data)=="dem_10m_topex_w_std"] <- "topex_w_std"
names(input_data)[names(input_data)=="dem_10m_topex_w_med"] <- "topex_w_med"
names(input_data)[names(input_data)=="dem_tpi_250_50m_std"] <- "tpi_250_std"
names(input_data)[names(input_data)=="dem_tpi_250_50m_med"] <- "tpi_250_med"
names(input_data)[names(input_data)=="dem_tpi_500_50m_std"] <- "tpi_500_std"
names(input_data)[names(input_data)=="dem_tpi_500_50m_med"] <- "tpi_500_med"
names(input_data)[names(input_data)=="dem_tpi_1000_50m_std"] <- "tpi_1000_std"
names(input_data)[names(input_data)=="dem_tpi_1000_50m_med"] <- "tpi_1000_med"
names(input_data)[names(input_data)=="dem_tpi_2500_50m_std"] <- "tpi_2500_std"
names(input_data)[names(input_data)=="dem_tpi_2500_50m_med"] <- "tpi_2500_med"
names(input_data)[names(input_data)=="dem_tpi_5000_50m_std"] <- "tpi_5000_std"
names(input_data)[names(input_data)=="dem_tpi_5000_50m_med"] <- "tpi_5000_med"
names(input_data)[names(input_data)=="dem_10m_nosefi_tri_std"] <- "tri_std"
names(input_data)[names(input_data)=="dem_10m_nosefi_tri_med"] <- "tri_med"
names(input_data)[names(input_data)=="solar_radiation_10m_april_std"] <- "solrad_apr_std"
names(input_data)[names(input_data)=="solar_radiation_10m_april_med"] <- "solrad_apr_med"
names(input_data)[names(input_data)=="solar_radiation_10m_autumn_std"] <- "solrad_autumn_std"
names(input_data)[names(input_data)=="solar_radiation_10m_autumn_med"] <- "solrad_autumn_med"
names(input_data)[names(input_data)=="solar_radiation_10m_january_std"] <- "solrad_jan_std"
names(input_data)[names(input_data)=="solar_radiation_10m_january_med"] <- "solrad_jan_med"
names(input_data)[names(input_data)=="solar_radiation_10m_july_std"] <- "solrad_jul_std"
names(input_data)[names(input_data)=="solar_radiation_10m_july_med"] <- "solrad_jul_med"
names(input_data)[names(input_data)=="solar_radiation_10m_october_std"] <- "solrad_oct_std"
names(input_data)[names(input_data)=="solar_radiation_10m_october_med"] <- "solrad_oct_med"
names(input_data)[names(input_data)=="solar_radiation_10m_spring_std"] <- "solrad_spring_std"
names(input_data)[names(input_data)=="solar_radiation_10m_spring_med"] <- "solrad_spring_med"
names(input_data)[names(input_data)=="solar_radiation_10m_summer_std"] <- "solrad_summer_std"
names(input_data)[names(input_data)=="solar_radiation_10m_summer_med"] <- "solrad_summer_med"
names(input_data)[names(input_data)=="solar_radiation_10m_winter_std"] <- "solrad_winter_std"
names(input_data)[names(input_data)=="solar_radiation_10m_winter_med"] <- "solrad_winter_med"
names(input_data)[names(input_data)=="solar_radiation_10m_year_std"] <- "solrad_year_std"
names(input_data)[names(input_data)=="solar_radiation_10m_year_med"] <- "solrad_year_med"
names(input_data)[names(input_data)=="latitude_10m"] <- "lat"
names(input_data)[names(input_data)=="longitude_10m"] <- "lon"
names(input_data)[names(input_data)=="bio01_eurolst_10m_std"] <- "bio01_std"
names(input_data)[names(input_data)=="bio01_eurolst_10m_med"] <- "bio01_med"
names(input_data)[names(input_data)=="bio02_eurolst_10m_std"] <- "bio02_std"
names(input_data)[names(input_data)=="bio02_eurolst_10m_med"] <- "bio02_med"
names(input_data)[names(input_data)=="bio10_eurolst_10m_std"] <- "bio10_std"
names(input_data)[names(input_data)=="bio10_eurolst_10m_med"] <- "bio10_med"
names(input_data)[names(input_data)=="bio11_eurolst_10m_std"] <- "bio11_std"
names(input_data)[names(input_data)=="bio11_eurolst_10m_med"] <- "bio11_med"
names(input_data)[names(input_data)=="bio12_eurolst_10m_std"] <- "bio12_std"
names(input_data)[names(input_data)=="bio12_eurolst_10m_med"] <- "bio12_med"
names(input_data)[names(input_data)=="bio15_eurolst_10m_std"] <- "bio15_std"
names(input_data)[names(input_data)=="bio15_eurolst_10m_med"] <- "bio15_med"
names(input_data)[names(input_data)=="bio18_eurolst_10m_std"] <- "bio18_std"
names(input_data)[names(input_data)=="bio18_eurolst_10m_med"] <- "bio18_med"
names(input_data)[names(input_data)=="bio02_eurolst_10m_std"] <- "bio02_std"
names(input_data)[names(input_data)=="bio02_eurolst_10m_med"] <- "bio02_med"
names(input_data)[names(input_data)=="bio19_eurolst_10m_std"] <- "bio19_std"
names(input_data)[names(input_data)=="bio19_eurolst_10m_med"] <- "bio19_med"
names(input_data)[names(input_data)=="sea_distance_10m_std"] <- "sea_std"
names(input_data)[names(input_data)=="sea_distance_10m_med"] <- "sea_med"
names(input_data)[names(input_data)=="sea_open_distance_50m_std"] <- "sea_open_std"
names(input_data)[names(input_data)=="sea_open_distance_50m_med"] <- "sea_open_med"
names(input_data)[names(input_data)=="water_distance_50m_std"] <- "water_std"
names(input_data)[names(input_data)=="water_distance_50m_med"] <- "water_med"

observations.names <- names(input_data)[c(9:83)]
observations.names.mod <- c(observations.names[grep("_med", observations.names)],"height")

#####################
# 2. some filtering #
#####################
# remove all incomplete observations
input_data_na_rm <- input_data[complete.cases(input_data),]


ggplot() + geom_tile(data=input_data, aes(x=x, y=y, fill=height)) + coord_equal()


##############################
# 3. assign node ID for INLA #
##############################
require(INLA)

nrows=1808
ncols=1414

input_data_na_rm$ID <- NA
input_data_na_rm$ID = inla.lattice2node(input_data_na_rm$row, input_data_na_rm$col, nrows, ncols)

ggplot() + geom_tile(data=input_data_na_rm, aes(x=x, y=y, fill=ID)) + coord_equal()


############################################
# 4. standardize data - mean 0, stddev = 1 #
###########################################
library(robustHD)
input_data_na_rm.scaled <- input_data_na_rm
input_data_na_rm.scaled[,observations.names] <- standardize(input_data_na_rm[,observations.names])

input_data_na_rm.means <- colMeans(input_data_na_rm[,observations.names])
input_data_na_rm.stddev <- apply(input_data_na_rm[,observations.names], 2, sd)

colMeans(input_data_na_rm.scaled[,observations.names])
apply(input_data_na_rm.scaled[,observations.names], 2, sd)


################################
# 5. exploratory data analysis #
################################
hist(input_data_na_rm$lc)

# --------------------------------------------- #
# correlation coefficient of response~predictor #
# --------------------------------------------- #

data.cor.coef <- data.frame(cor.coef=double())
i = 1
for (predictor in observations.names) {
  print(predictor)
  data.cor.coef[i,] <- cor(input_data_na_rm.scaled$lc, input_data_na_rm.scaled[,predictor])
  row.names(data.cor.coef)[i]<- predictor
  i = i+1
  # scatter plot
  #smoothScatter(input_data_na_rm.scaled[,predictor], input_data_na_rm.scaled$lc, main=predictor, xlab=predictor, ylab="lc")
  #abline(lm(input_data_na_rm.scaled$lc~input_data_na_rm.scaled[,predictor]), col="red")
  
  # histogram
  #ggplot(data=input_data_na_rm.scaled, aes(input_data_na_rm.scaled[,predictor])) + geom_histogram()
}
data.cor.coef$predictor <- rownames(data.cor.coef)
data.cor.coef <- data.cor.coef[order(data.cor.coef$cor.coef),] 
data.cor.coef$predictor <- factor(data.cor.coef$predictor, levels = data.cor.coef$predictor[order(data.cor.coef$cor.coef)])
ggplot(data.cor.coef, aes(predictor, cor.coef)) + geom_col() + coord_flip()


# ------------------------------- #
# correlations between predictors #
# ------------------------------- #
library(corrplot)

# 1. full data - medians and standard deviations
# observe
M.full <- cor(input_data_na_rm.scaled[,observations.names])
M.full.lim <- M.full*(abs(M.full)>=0.7)

corrplot(M.full.lim, method="circle",type="lower")

# exclude correlated predictors
observation.names.exclude <- observations.names[!observations.names %in% 
                                                  c("slope_std","topex_e_std","tpi_250_std",
                                                    "tri_med","tri_std","solrad_apr_std",
                                                    "solrad_jul_std","solrad_spring_std",
                                                    "solrad_summer_std","solrad_year_std",
                                                    "topex_ne_med","topex_ne_std","topex_n_std",
                                                    "topex_s_std","topex_se_std","topex_sw_std",
                                                    "topex_w_std","tpi_500_std","topex_nw_std",
                                                    "topex_se_med","topex_sw_med","tpi_250_med",
                                                    "tpi_2500_med","tpi_500_med","tpi_2500_std",
                                                    "tpi_5000_std","solrad_jul_med","solrad_spring_med",
                                                    "solrad_summer_med","solrad_jan_med","solrad_apr_med",
                                                    "solrad_year_med","solrad_winter_med","solrad_autumn_med",
                                                    "solrad_jan_std","solrad_autumn_std",
                                                    "solrad_winter_std","bio10_std","bio11_std","bio18_std",
                                                    "bio12_med","bio01_std","tpi_1000_std","sea_open_med",
                                                    "bio18_med","bio12_std","bio01_med","bio02_med"
                                                    )]

M.full.2 <- cor(input_data_na_rm.scaled[,observation.names.exclude])
M.full.2.lim <- M.full.2*(abs(M.full.2)>=0.7)

corrplot(M.full.2.lim, method="circle",type="lower",order ="FPC")


# 2. median data
# observe
M.med <- cor(input_data_na_rm.scaled[,observations.names.mod])
M.med.lim <- M.med*(abs(M.med)>=0.7)

corrplot(M.med, method="circle",type="lower",order ="FPC")

# exclude correlated predictors
observation.names.mod.exclude <- observations.names.mod[!observations.names.mod %in% 
                                                  c("solrad_jul_med","solrad_spring_med","solrad_summer_med",
                                                    "solrad_year_med","solrad_apr_med","solrad_jan_med",
                                                    "tpi_2500_med","solrad_winter_med","solrad_autumn_med",
                                                    "bio12_med","topex_ne_med","topex_sw_med",
                                                    "topex_se_med","tri_med","bio01_med","tpi_250_med",
                                                    "tpi_500_med","bio02_med","sea_open_med","bio18_med"
                                                  )]

M.med.2 <- cor(input_data_na_rm.scaled[,observation.names.mod.exclude])
M.med.2.lim <- M.med.2*(abs(M.med.2)>=0.7)

corrplot(M.med.2, method="circle",type="lower",order ="FPC")



##################################################
# 6. VIF larger than 4 implies multicollinearity #
##################################################
library(car)

formula.full <- lc ~ water_med + sea_med + 
                     aspect_med + curv_med +
                     topex_e_med + topex_n_med + topex_s_med + topex_w_med +
                     tpi_1000_med + tpi_5000_med + 
                     bio10_med + bio15_med + bio19_med +
                     water_std + sea_std + sea_open_std +
                     aspect_std + curv_std + 
                     bio02_std + bio19_std + bio15_std +
                     height

formula.med <- lc ~ water_med + sea_med + 
  aspect_med + curv_med + 
  topex_e_med + topex_n_med+ topex_s_med + topex_w_med +
  tpi_1000_med + tpi_5000_med + 
  bio10_med + bio11_med + bio15_med + bio19_med + height

# GLM
mod.glm.full <- glm(formula.full, 
              data=input_data_na_rm.scaled, 
              family=binomial(link='logit'))
summary(mod.glm.full)

mod.glm.med <- glm(formula.med, 
                    data=input_data_na_rm.scaled, 
                    family=binomial(link='logit'))
summary(mod.glm.med)

# VIF larger than 4
# FULL: solrad_oct_med, slope_med, topex_nw_med, solrad_oct_std, bio11_med          
vif(mod.glm.full)

# MED: solrad_oct_med, topex_nw_med, slope_med             
vif(mod.glm.med)


#############################################################
# 7. PCA to detect multicollinearity in remaining variables #
#############################################################
fit <- princomp(input_data_na_rm.scaled[,c("water_med","sea_med","aspect_med","curv_med",
                                           "topex_e_med","topex_n_med","topex_s_med","topex_w_med",
                                           "tpi_5000_med","bio10_med",
                                           "bio15_med","bio19_med")], cor=TRUE) 
summary(fit) # variance accounted for, pulls out the variables on the first 2 axes
loadings(fit) # pc loadings

biplot(fit)#this pulls out the variables on the first 2 axes
plot(fit,type="lines") # scree plot 

# excluded: bio11_med, tpi_100_med


###############################
# 8. Moran's I - correlograms #
###############################
library(raster)

raster <- rasterFromXYZ(cbind(input_data_na_rm.scaled$x, input_data_na_rm.scaled$y, input_data_na_rm.scaled$lc))

# set bins width and range of correlogram
lim.dist <- 100 # range, no.cells (half)
width <- 10 # width, no.cells

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

ggplot(M.lags,aes(x=x, y=moran)) + geom_line() + xlab("Distance [km]") + ylab("Moran's I") + 
  ggtitle("Correlogram")


#############################################################
# 9. Variogram #
#############################################################
library(gstat)
coordinates(input_data_na_rm.scaled)=~x+y

myvariogram <- variogram(lc~x+y, data=input_data_na_rm.scaled, cutoff=250000, width=10000)  

ggplot(myvariogram,aes(x=dist/1000, y=gamma)) + geom_line() + xlab("Distance [km]") + ylab("Variance") + 
  ggtitle("Variogram")

# back to data frame
if (class(input_data_na_rm.scaled) == "SpatialPointsDataFrame") {
  input_data_na_rm.scaled <- as.data.frame(input_data_na_rm.scaled)
}


##############################################
# 10. Bayesian Matérn model fitted with INLA #
##############################################
require(INLA)

# change proportion to no.successes in 100*100 pix cell
input_data_na_rm.scaled$y_lc <- input_data_na_rm.scaled$lc*10000

# subset 200*200
test_data <- input_data_na_rm.scaled[input_data_na_rm.scaled$x < 232000 & 
                                     input_data_na_rm.scaled$x >= 182000 & 
                                     input_data_na_rm.scaled$y < 7020000 & 
                                     input_data_na_rm.scaled$y >= 6970000,]
nrows.test=ncols.test=50

test_data$row <- test_data$row - min(test_data$row) + 1
test_data$col <- test_data$col - min(test_data$col) + 1
test_data$ID <- inla.lattice2node(test_data$row, test_data$col, nrows.test, ncols.test)

ggplot() + geom_tile(data=test_data, aes(x=x, y=y, fill=lc)) + coord_equal()


# parameters of matern field - range, precision (shape, scale)
# range
range=100
log.range <- list(initial=log(range), fixed=TRUE) # log of range of gamma function (because we use log-gamma function)

# precision
shape = 23.36
scale = 0.001

# formula with fixed effects and spatial effect
formula_matern <- lc ~ water_med + sea_med + 
                       aspect_med + curv_med + 
                       topex_e_med + topex_n_med+ topex_s_med + topex_w_med +
                       tpi_1000_med + tpi_5000_med + 
                       bio10_med + bio11_med + bio15_med + bio19_med + 
                      f(ID, 
                        model='matern2d', 
                        nrow=nrows.test, 
                        ncol=ncols.test, 
                        nu=1, # 1, 2 or 3
                        hyper=list(range=log.range, 
                                   prec=list(initial=-3,
                                             param=c(shape,scale))))



# formula spatial effect only
# TODO plot random effect of model fitted with this formula in raster
formula_matern_spatial <- lc_sample ~ 1 +
  f(node, model='matern2d',
    nrow=nrow.larger, 
    ncol=ncol.larger, 
    nu=1, # 1, 2 or 3
    hyper=list(range=log.range, 
               prec=hyperpar_matern)) 

# fit model
model_matern <- inla(formula=formula_matern,
                     data=test_data,
                     family='binomial',
                     Ntrials=1,
                     control.compute=list(dic=TRUE, waic=TRUE), # compute DIC, WIFC (smaller better)
                     control.fixed=list(prec.intercept=0.001), # can be omitted
                     verbose=F,
                     control.predictor=list(link=1)) # logit link

# model summary
summary(model_matern)

# prediction of fitted values
model_matern$summary.fitted.values

# random effects for each model
model_matern$summary.random

# fixed effects
model_matern$summary.fixed


######################################
# 11. prediction using fixed effects #
######################################
output_data <- cbind(rownames(model_matern$summary.fixed), 
                     model_matern$summary.fixed$mean,
                     input_data_na_rm.means[rownames(model_matern$summary.fixed)],
                     input_data_na_rm.stddev[rownames(model_matern$summary.fixed)])

write.table(output_data,
            file="fixed_effects_coefficients.csv",sep=',',quote=FALSE)

# prediction
test_data$predict_logit <- model_matern$summary.fixed$mean[1] + 
                    model_matern$summary.fixed$mean[2]*test_data$water_med +
                    model_matern$summary.fixed$mean[3]*test_data$sea_med +
                    model_matern$summary.fixed$mean[4]*test_data$aspect_med +
                    model_matern$summary.fixed$mean[5]*test_data$curv_med +
                    model_matern$summary.fixed$mean[6]*test_data$topex_e_med +
                    model_matern$summary.fixed$mean[7]*test_data$topex_n_med +
                    model_matern$summary.fixed$mean[8]*test_data$topex_s_med +
                    model_matern$summary.fixed$mean[9]*test_data$topex_w_med +
                    model_matern$summary.fixed$mean[10]*test_data$tpi_1000_med +
                    model_matern$summary.fixed$mean[11]*test_data$tpi_5000_med +
                    model_matern$summary.fixed$mean[12]*test_data$bio10_med +
                    model_matern$summary.fixed$mean[13]*test_data$bio11_med +
                    model_matern$summary.fixed$mean[14]*test_data$bio15_med +
                    model_matern$summary.fixed$mean[15]*test_data$bio19_med
test_data$predict <- exp(test_data$predict_logit)/(1+exp(test_data$predict_logit))
  
ggplot() + geom_tile(data=test_data, aes(x=x, y=y, fill=predict)) + coord_equal()







