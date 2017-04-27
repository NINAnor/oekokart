#Read data into R
skgr <- read.csv('/home/stefan/Okokart/skgr.csv', sep=",", header=TRUE)

#Load libraries
library("beanplot")
library("lattice")
library("gplots")
library("nlme") # GLS
library("spgwr") # GWR



skgr$aspect_cl8 <- round(skgr$aspect_3/45)

skgr$amount_ocean_100200m[skgr$amount_ocean_100200m<=0] <- 1 
skgr$amount_ocean_50200m[skgr$amount_ocean_50200m<=0] <- 1 
skgr$amount_ocean_25000m[skgr$amount_ocean_25000m<=0] <- 1 
skgr$amount_ocean_10100m[skgr$amount_ocean_10100m<=0] <- 1 
skgr$amount_ocean_5050m[skgr$amount_ocean_5050m<=0] <- 1
skgr$continentality <- (skgr$amount_ocean_100200m * skgr$amount_ocean_50200m * skgr$amount_ocean_25000m * skgr$amount_ocean_10100m * skgr$amount_ocean_5050m)
skgr$max_forest_sum <- (skgr$max_forest_50200m + skgr$max_forest_25000m + skgr$max_forest_10100m + skgr$max_forest_5050m + skgr$max_forest_2550m)
skgr$geol_rich[skgr$geol_rich<1] <- 1
skgr$quart_gw[skgr$quart_gw<1] <- 1
#skgr$triterm_total_cor <- skgr$triterm_total+((skgr$dem_1km_avg-skgr$hoh)*0.55)
#skgr$tetraterm_total_cor <- skgr$tetraterm_total+((skgr$dem_1km_avg-skgr$hoh)*0.55)

###
#Choose filter-criteria for relation to max forest height based on samples from map explorations (i enkelt tilfeller kan forskjellen mellom nord- og sør-li i en øst-vest-dal være opp til 200m)
#Filter based on adjusted temperature
#Removes islands based on continentality (if they are not removed by temperature filtering)
#Remove negative model outliers (heavily negative residuals; defined by percentage (% of fitted/predicted values)

#Filter n in skgr = 2894673
#Filter 1
skgr_filter1 <- skgr[skgr$filter_max_100m==-9999,] #n = 1516366
length(skgr_filter1$hoh)
skgr_filter1 <- skgr_filter1[skgr_filter1$max_forest_50200m<=125.0,] #n = 159940
length(skgr_filter1$hoh)
skgr_filter1 <- skgr_filter1[skgr_filter1$max_forest_25000m<=100.0,] #n = 147999
length(skgr_filter1$hoh)
skgr_filter1 <- skgr_filter1[skgr_filter1$max_forest_10100m<=75.0,] #n = 119923
length(skgr_filter1$hoh)
skgr_filter1 <- skgr_filter1[skgr_filter1$max_forest_5050m<=50.0,] #n = 103259
length(skgr_filter1$hoh)
skgr_filter1 <- skgr_filter1[skgr_filter1$max_forest_2550m<=30.0,] #n = 62869
length(skgr_filter1$hoh)
skgr_filter1 <- skgr_filter1[skgr_filter1$actuality>1988,] #n = 56698
length(skgr_filter1$hoh)
skgr_filter1 <- skgr_filter1[skgr_filter1$slope_3<50,] #n = 56353
length(skgr_filter1$hoh)
skgr_filter1 <- skgr_filter1[skgr_filter1$hoh>40,] #n = 56229
length(skgr_filter1$hoh)

###
#test_lm1 <- lm(hoh ~ Y * log(coast_distance) + X + continentality + solar_radiation + TPI_5100m_stddev + as.factor(geol_rich) + as.factor(quart_gw) * TWI, data=skgr_filter1)
#    Min      1Q  Median      3Q     Max 
#-497.68  -28.02    3.88   31.45  477.40 
#Residual standard error: 66.43 on 60550 degrees of freedom
#Multiple R-squared:  0.9452,    Adjusted R-squared:  0.9452 
#F-statistic: 5.805e+04 on 18 and 60550 DF,  p-value: < 2.2e-16
###All terms significant

#Filter 2
skgr_filter2 <- skgr[skgr$filter_max_100m==-9999,] #n = 1516366
length(skgr_filter2$hoh)
skgr_filter2 <- skgr_filter2[skgr_filter2$max_forest_50200m<=150.0,] #n = 229819
length(skgr_filter2$hoh)
skgr_filter2 <- skgr_filter2[skgr_filter2$max_forest_25000m<=110.0,] #n = 171840
length(skgr_filter2$hoh)
skgr_filter2 <- skgr_filter2[skgr_filter2$max_forest_10100m<=80.0,] #n = 144635
length(skgr_filter2$hoh)
skgr_filter2 <- skgr_filter2[skgr_filter2$max_forest_5050m<=50.0,] #n = 109224
length(skgr_filter2$hoh)
skgr_filter2 <- skgr_filter2[skgr_filter2$max_forest_2550m<=30.0,] #n = 79825
length(skgr_filter2$hoh)
skgr_filter2 <- skgr_filter2[skgr_filter2$actuality>1988,] #n = 71350
#length(skgr_filter2$hoh)
#skgr_filter2 <- skgr_filter2[skgr_filter2$slope_3<50,] #n = 68247 #Slope as variance structure???
#length(skgr_filter2$hoh)
#skgr_filter2 <- skgr_filter2[skgr_filter2$hoh>40,] #n = 68115

#skgr_filter2 <- skgr_filter2[skgr_filter2$continentality<mean(skgr_filter2$continentality),] #Removes islands
#
 

#Filter 3
skgr_filter3 <- skgr[skgr$filter_max_100m==-9999,] #n = 1516366
length(skgr_filter3$hoh)
skgr_filter3 <- skgr_filter3[skgr_filter3$max_forest_50200m<=225.0,] #n = 563748
#skgr_filter3 <- skgr_filter3[skgr_filter3$max_forest_sum<=500.0,] #n = ???
length(skgr_filter3$hoh)
skgr_filter3 <- skgr_filter3[skgr_filter3$actuality>1988,] #n = 480764
length(skgr_filter3$hoh)
skgr_filter3 <- skgr_filter3[skgr_filter3$slope_next>0,]
skgr_filter3 <- skgr_filter3[skgr_filter3$slope_next<15,] #n = 429656 #Slope as variance structure???
skgr_filter3 <- skgr_filter3[skgr_filter3$(max_alt_open_patch-skgr_filter3$max_alt_forest_patch)>100,]
summary(skgr_filter3$max_alt_open_patch-skgr_filter3$hoh)
#length(skgr_filter3$hoh)

test_glm3_f6 <- glm(hoh ~ Y * log(coast_distance) + Y * solar_radiation + X * Y * log(continentality) * log(coast_distance), data=skgr_filter3)
#test_glm3_f6 <- glm(hoh ~ solar_radiation + X * Y * log(continentality) * log(coast_distance), data=skgr_filter3)

#Plot distance to max forest
png('/home/stefan/Okokart/Filter_step_1_z_distance_max_forest.png', width = 3480, height = 3480, units = "px", pointsize = 4, bg = "white", res = NA, type = c("cairo"))
zcol <- level.colors(skgr_filter3$max_forest_50200m, at = c(0, 25, 50, 75, 100, 125, 150, 175, 200, 225, 250), col.regions=rainbow(11))
xyplot(Y ~ X | "Z-distance to higest forest within 25100m", data=skgr_filter3, col=zcol, aspect = 1, .aspect.ratio = 1)
dev.off()

#Plot distance to max forest
png('/home/stefan/Okokart/Filter_step_1_z_distance_max_forest_less_than_200.png', width = 3480, height = 3480, units = "px", pointsize = 4, bg = "white", res = NA, type = c("cairo"))
zcol <- level.colors(skgr_filter3$max_forest_50200m[skgr_filter3$max_forest_50200m<100], at = c(0,25,50,75,100), col.regions=rainbow(5))
xyplot(Y ~ X | "Z-distance to higest forest within 25100m", data=skgr_filter3[skgr_filter3$max_forest_50200m<100,], col=zcol, aspect = 1, .aspect.ratio = 1)
dev.off()

#Plot residuals for forest line
png('/home/stefan/Okokart/Filter_step_1_residuals.png', width = 3480, height = 3480, units = "px", pointsize = 4, bg = "white", res = NA, type = c("cairo"))
zcol <- level.colors((test_glm3_f6$residuals), at=c(-500, -400, -300, -200, -100, 0, 100, 200, 300, 400, 500), col.regions=colorRampPalette(c("red", "yellow", "green")))
xyplot(Y ~ X | "Residuals in m", data=skgr_filter3, col=zcol, aspect = 1, .aspect.ratio = 1)
dev.off()

#Plot reative residuals for overestimated forest line
png('/home/stefan/Okokart/Filter_step_1_residuals_overestimated.png', width = 3480, height = 3480, units = "px", pointsize = 4, bg = "white", res = NA, type = c("cairo"))
zcol <- level.colors((skgr_filter3$hoh/test_glm3_f6$fitted)[(skgr_filter3$hoh/test_glm3_f6$fitted)<1], at=c(0, 0.05, 0.1, 0.25, 0.50, 0.75, 1), col.regions=colorRampPalette(c("red", "yellow")))
xyplot(Y ~ X | "Residuals in % of fitted altitude (<1)", data=skgr_filter3[(skgr_filter3$hoh/test_glm3_f6$fitted)<1,], col=zcol, aspect = 1, .aspect.ratio = 1)
dev.off()

#Plot reative residuals for overestimated forest line
png('/home/stefan/Okokart/Filter_step_1_residuals_underestimated.png', width = 3480, height = 3480, units = "px", pointsize = 4, bg = "white", res = NA, type = c("cairo"))
zcol <- level.colors((skgr_filter3$hoh/test_glm3_f6$fitted)[(skgr_filter3$hoh/test_glm3_f6$fitted)>=1], at = c(1, 1.05, 1.1, 1.25, 1.50, 1.75, 2), col.regions=colorRampPalette(c("yellow", "green")))
xyplot(Y ~ X | "Residuals in % of fitted altitude (>=1)", data=skgr_filter3[(skgr_filter3$hoh/test_glm3_f6$fitted)>=1,], col=zcol, aspect = 1, .aspect.ratio = 1)
dev.off()

#Plot fitted values
png('/home/stefan/Okokart/Filter_step_1_fitted_values.png', width = 3480, height = 3480, units = "px", pointsize = 4, bg = "white", res = NA, type = c("cairo"))
zcol <- level.colors(test_glm3_f6$fitted, at = c(100, 200, 300, 400, 500, 600, 700, 800, 900, 1000,1100), col.regions=terrain.colors(11))
xyplot(Y ~ X | "Fitted values", data=skgr_filter3, col=zcol, aspect = 1, .aspect.ratio = 1)
dev.off()

#Plot altitude of reference points
png('/home/stefan/Okokart/Filter_step_1_reference_altitude.png', width = 3480, height = 3480, units = "px", pointsize = 4, bg = "white", res = NA, type = c("cairo"))
zcol <- level.colors(skgr_filter3$hoh, at = c(100, 200, 300, 400, 500, 600, 700, 800, 900, 1000,1100), col.regions=terrain.colors(11))
xyplot(Y ~ X | "Altitude of reference points", data=skgr_filter3, col=zcol, aspect = 1, .aspect.ratio = 1)
dev.off()

#Plot point density with different filters
library("hexbin")
folder <- '/home/stefan/Okokart/'
ps_file <- paste(folder, "Point_densities.ps", sep="")
postscript(ps_file, horizontal=TRUE, paper="a4", family="mono")
hexbinplot(Y ~ X | "Point density of skgr", skgr, aspect = 1, .aspect.ratio = 1, xbins=120, draw=TRUE, colorkey=TRUE)
#hexbinplot(Y ~ X | "Point density skgr_filter", skgr_filter, aspect = 1, .aspect.ratio = 1, xbins=120, draw=TRUE, colorkey=TRUE)
#hexbinplot(Y ~ X | "Point density skgr_filter2", skgr_filter2, aspect = 1, .aspect.ratio = 1, xbins=120, draw=TRUE, colorkey=TRUE)
hexbinplot(Y ~ X | "Point density of skgr_filter3", skgr_filter3, aspect = 1, .aspect.ratio = 1, xbins=120, draw=TRUE, colorkey=TRUE)
dev.off()

###Make boxplot of filter criteria vs residuals/relative residuals
resid_rel_class <- test_glm3_f6$residuals/skgr_filter3$hoh
resid_rel_class[test_glm3_f6$residuals/test_glm3_f6$fitted<=0] <- 0
resid_rel_class[test_glm3_f6$residuals/test_glm3_f6$fitted<=-0.05] <- 0.05
resid_rel_class[test_glm3_f6$residuals/test_glm3_f6$fitted<=-0.1] <- -0.1
resid_rel_class[test_glm3_f6$residuals/test_glm3_f6$fitted<=-0.05] <- -0.05
resid_rel_class[test_glm3_f6$residuals/test_glm3_f6$fitted<=-0.1] <- -0.1
resid_rel_class[test_glm3_f6$residuals/test_glm3_f6$fitted<=-0.25] <- -0.25
resid_rel_class[test_glm3_f6$residuals/test_glm3_f6$fitted<=-0.5] <- -0.5
resid_rel_class[test_glm3_f6$residuals/test_glm3_f6$fitted<=-0.75] <- -0.75
resid_rel_class[test_glm3_f6$residuals/test_glm3_f6$fitted>=0] <- 0
resid_rel_class[test_glm3_f6$residuals/test_glm3_f6$fitted>=0.05] <- 0.05
resid_rel_class[test_glm3_f6$residuals/test_glm3_f6$fitted>=0.1] <- 0.1
resid_rel_class[test_glm3_f6$residuals/test_glm3_f6$fitted>=0.25] <- 0.25
resid_rel_class[test_glm3_f6$residuals/test_glm3_f6$fitted>=0.5] <- 0.5
resid_rel_class[test_glm3_f6$residuals/test_glm3_f6$fitted>=0.75] <- 0.75

skgr_filter3$max_forest_sum <- skgr_filter3$max_forest_50200m + skgr_filter3$max_forest_25000m + skgr_filter3$max_forest_10100m + skgr_filter3$max_forest_5050m + skgr_filter3$max_forest_2550m

resid_class <- round(test_glm3_f6$residuals/100)
ps_file <- paste(folder, "Filter_criteria_over_residuals.ps", sep="")
postscript(ps_file, horizontal=TRUE, paper="a4", family="mono")
boxplot(skgr_filter3$max_forest_50200m ~ as.factor(resid_rel_class), main="z-distance to max forest in 50200m (relative)")
boxplot(skgr_filter3$max_forest_50200m ~ as.factor(resid_class), main="z-distance to max forest in 50200m")
boxplot(skgr_filter3$max_forest_25000m ~ as.factor(resid_rel_class), main="z-distance to max forest in 25000m (relative)")
boxplot(skgr_filter3$max_forest_25000m ~ as.factor(resid_class), main="z-distance to max forest in 25000m")
boxplot(skgr_filter3$max_forest_10100m ~ as.factor(resid_rel_class), main="z-distance to max forest in 10100m (relative)")
boxplot(skgr_filter3$max_forest_10100m ~ as.factor(resid_class), main="z-distance to max forest in 10100m")
boxplot(skgr_filter3$max_forest_5050m ~ as.factor(resid_rel_class), main="z-distance to max forest in 5050m (relative)")
boxplot(skgr_filter3$max_forest_5050m ~ as.factor(resid_class), main="z-distance to max forest in 5050m")
boxplot(skgr_filter3$max_forest_2550m ~ as.factor(resid_rel_class), main="z-distance to max forest in 2550m (relative)")
boxplot(skgr_filter3$max_forest_2550m ~ as.factor(resid_class), main="z-distance to max forest in 2550m")
boxplot(skgr_filter3$max_forest_sum ~ as.factor(resid_rel_class), main="z-distance to max forest across scales (relative)")
boxplot(skgr_filter3$max_forest_sum ~ as.factor(resid_class), main="z-distance to max forest across scales")
dev.off()



#Filter referance points based on model
skgr_filter3 <- skgr_filter3[(skgr_filter3$hoh/test_glm3_f6$fitted)>=0.75,]
skgr_filter3 <- skgr_filter3[test_glm3_f6$residuals>-225.0,]


#Make data exploration plots
cat_val <- c("actuality", "geol_rich", "geol_type", "quart_gw", "quart_infilt", "quart_type")
folder <- '/home/stefan/Okokart/'
for(evar in names(skgr_filter)) {
skgr_filter[grep(evar, names(skgr_filter))][skgr_filter[grep(evar, names(skgr_filter))]==-9999] <- NA
}

#ps_file <- paste(folder, "data_exploration_filter_abs_5050m.ps", sep="")
ps_file <- paste(folder, "data_exploration_filter_sum.ps", sep="")

postscript(ps_file, horizontal=TRUE, paper="a4", family="mono")
op <- par(mfrow=c(2,2), family="mono")

for(evar in names(skgr_filter)) {
if((evar=="bgr")==FALSE) {

if(evar %in% cat_val) {
#Calculate simple linear regression for the single explanatory variable
test_glm <- lm(skgr_filter$hoh ~ as.factor(unlist(skgr_filter[grep(evar, names(skgr_filter))])))
#Plot explainatory variable against response variable along with a regression line 
beanplot_test <- try(beanplot(skgr_filter$hoh ~ as.factor(unlist(skgr_filter[grep(evar, names(skgr_filter))])), horizontal=FALSE, log="", las=1, outline=FALSE, ylab="hoh", xlab=evar, what=c(1,1,1,0), main=c(paste("Beanplot of ", evar), " against hoh")), silent=TRUE)
#if(is.list(beanplot_test)) {
#beanplot(skgr_filter$hoh ~ as.factor(unlist(skgr_filter[grep(evar, names(skgr_filter))])), horizontal=FALSE, log="", las=1, outline=FALSE, ylab="hoh", xlab=evar, what=c(1,1,1,0), main=c(paste("Beanplot of ", evar), " against hoh"))
#}
if(is.list(beanplot_test)==FALSE) {
boxplot(skgr_filter$hoh ~ as.factor(unlist(skgr_filter[grep(evar, names(skgr_filter))])), horizontal=FALSE, log="", las=1, outline=FALSE, ylab="hoh", xlab=evar, main=c(paste("Boxplot of ", evar), " against hoh"))
}
lines(test_glm$coefficients ~ as.factor(test_glm$xlevels[[1]]), col="red", family="mono")
#Plot histogram of explainatory variable
hist(unlist(skgr_filter[evar]), xlab=evar, main=c("Histogram of", evar), family="mono")
#Print model summary
text_output <- paste("Explanatory variavble: ", evar)
text_output <- append(text_output, paste("Call: ", toString(summary(test_glm)$call)))
text_output <- append(text_output, paste("F-statistic: ", toString(summary(test_glm)$fstatistic)))
text_output <- append(text_output, paste("Adj. R squared: ", toString(summary(test_glm)$adj.r.squared)))
textplot(text_output)
}

if((evar %in% cat_val)==FALSE) {
#Calculate simple linear regression for the single explanatory variable
test_glm <- lm(skgr_filter$hoh ~ unlist(skgr_filter[evar]))
#Plot explainatory variable against response variable along with a regression line, confidence intervalls and 1. and 3. quartil
plot(skgr_filter$hoh ~ unlist(skgr_filter[evar]), family="mono", xlab=evar, ylab="hoh", , main=c(paste("XY-plot of ", evar), " against hoh with linear regression 'test-GLM'"))
abline_test <- try(abline(test_glm, col="red", family="mono"), silent=TRUE)

test <- summary(test_glm$residuals)
ci <- confint(test_glm)

abline_test <- try(abline((test[2]+test_glm$coefficients[1]), test_glm$coefficients[2], col="Red", lty=2, family="mono"), silent=TRUE) # 1. quartil
abline_test <- try(abline((test[5]+test_glm$coefficients[1]), test_glm$coefficients[2], col="Red", lty=2, family="mono"), silent=TRUE) # 3. quartil
abline_test <- try(abline(ci[1], ci[2], col="red", lty=3, family="mono"), silent=TRUE) # 2.5% confidence intervall
abline_test <- try(abline(ci[3], ci[4], col="red", lty=3, family="mono"), silent=TRUE) # 97.5% confidence intervall

if(is.list(abline_test)) {
abline(test_glm, col="red", family="mono")
}
#Plot histogram of explainatory variable
hist(unlist(skgr_filter[evar]), xlab=evar, main=c("Histogram of", evar), family="mono")
#Print model summary
textplot(capture.output(summary(test_glm)), family="mono")
}

#Plot residuals of a linear regression against respons variable
E <- resid(test_glm)#henter ut residualene i modellen din
EAll <- vector(length=length(skgr_filter$hoh))#lager en vector som er like lang som vektoren hoh
EAll[] <- NA#fyller inn med NA der det er tomt i E-vektoren
I1 <- !is.na(skgr_filter$hoh) #fyller inn med NA der det er tomt i E-vektoren
EAll[I1] <- E#fyller inn med NA der det er tomt i E-vektoren
plot(skgr_filter$hoh,EAll, xlab="hoh", ylab="residuals", family="mono", main=paste("XY-plot of test-GLMs residuals against hoh"))

}
} 
par(op)
dev.off()


ps_file <- paste(folder, "data_exploration_filter_coplot.ps", sep="")
postscript(ps_file, horizontal=TRUE, paper="a4", family="mono")
for(evar in names(skgr_filter)) {
if((evar=="bgr")==FALSE) {
if((evar=="Y")==FALSE) {
coplot(skgr_filter$hoh ~ unlist(skgr_filter[evar]) | skgr_filter$Y, family="mono", ylab="hoh", xlab=evar)
}
}
} 
dev.off()

ps_file <- paste(folder, "data_exploration_filter_coplot_Y_", evar, ".ps", sep="")
postscript(ps_file, horizontal=TRUE, paper="a4", family="mono")
for(evar in names(skgr_filter)) {
if((evar=="bgr")==FALSE) {
if((evar=="Y")==FALSE) {
coplot(skgr_filter$hoh ~ unlist(skgr_filter[evar]) | skgr_filter$AGDD_total, family="mono")
}
}
} 
dev.off()
#?gls

#GWR
#library("spgwr")
#sel_w <- gwr.sel(hoh ~ solar_radiation + Y + X + coast_distance_p2 + slope_5 + solar_radiation : Y + solar_radiation : X + solar_radiation :coast_distance_p2 + solar_radiation : slope_5 + Y : X + Y : coast_distance + Y : slope_5 + X : coast_distance + X : slope_5 + coast_distance : slope_5, data=skgr_filter, coords=cbind(skgr_filter$X, skgr_filter$Y))
#test_gwr1_full <- gwr(hoh ~ solar_radiation + Y + X + coast_distance + slope_5 + solar_radiation : Y + solar_radiation : X + solar_radiation : coast_distance + solar_radiation : slope_5 + Y : X + Y : coast_distance + Y : slope_5 + X : coast_distance + X : slope_5 + coast_distance : slope_5, data=skgr_filter, bandwidth=sel_w, coords=cbind(skgr_filter$X,skgr_filter$Y))
#GLS
library("nlme")
f1 <- formula(hoh ~ X * Y)
skgr.gls <-  gls(f1, data=skgr_filter3)
vario.skgr.gls <- Variogram(skgr.gls, form=~X+Y, robust=TRUE, maxDist=1000, resType="pearson")
plot(vario.skgr.gls, smooth=TRUE)

skgr.gls.spher <- gls(f1, correlation=corSpher(form=~X+Y, nugget=TRUE), data=skgr_filter3)
skgr.gls.lin <- gls(f1, correlation=corLin(form=~X+Y, nugget=TRUE), data=skgr_filter3)
skgr.gls.ratio <- gls(f1, correlation=corRatio(form=~X+Y, nugget=TRUE), data=skgr_filter3)
skgr.gls.gaus <- gls(f1, correlation=corGaus(form=~X+Y, nugget=TRUE), data=skgr_filter3)
skgr.gls.exp <- gls(f1, correlation=corExp(form=~X+Y, nugget=TRUE), data=skgr_filter3)

#test_gls1_full <- gls(hoh ~ solar_radiation + Y + X + coast_distance + slope_5 + solar_radiation : Y + solar_radiation : X + solar_radiation : coast_distance + solar_radiation : slope_5 + Y : X + Y : coast_distance + Y : slope_5 + X : coast_distance + X : slope_5 + coast_distance : slope_5, data=skgr_filter, weights=varComb(varPower(form=~Y),varPower(form=~X),varPower(form=~coast_distance)))
#test_glm1_full <- glm(hoh ~ solar_radiation + Y + X + coast_distance + slope_5 + solar_radiation : Y + solar_radiation : X + solar_radiation : coast_distance + solar_radiation : slope_5 + Y : X + Y : coast_distance + Y : slope_5 + X : coast_distance + X : slope_5 + coast_distance : slope_5, data=skgr_filter)
#test_gam1_full <- gam(hoh ~ lo(solar_radiation) + lo(Y) + lo(X) + +lo(coast_distance) + lo(slope_5) + lo(solar_radiation, Y) + lo(solar_radiation, X) + lo(solar_radiation, coast_distance) + lo(solar_radiation, slope_5) + lo(Y, X) + lo(Y, coast_distance) + lo(Y, slope_5) + lo(X, coast_distance) + lo(X, slope_5) + lo(coast_distance, slope_5), data=skgr_filter)

#xyplot(skgr_filter$hoh~skgr_filter$Y, panel=function(x,y) {panel.xyplot(x,y, col="Black");panel.loess(x,y,span=2, degree=1, col="Blue")})

###Zuur et al. protokol:
#- create gls with all possible terms and interactions and no variance structure
#- 

#dotchart(unlist(skgr_filter[evar]), family="mono", xlab=evar, par(yaxt="n"))
#coplot(skgr_filter$hoh ~ unlist(skgr_filter[evar]) | skgr_filter$Y, family="mono")
#results <- boot(data=skgr_filter_5050m_na, statistic=rsq, R=1000, formula=hoh~Y+solar_radiation)

###Model validation
###
E <- rstandard(test_glm3_f6)
plot(E ~ test_glm3_f6$fitted, ylab="Standardised residuals", xlab="Fitted values for altitude")
#Do the line above for each explanatory variable
hist(E)
qqnorm(E)

