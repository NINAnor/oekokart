##########################################################################################################################
##########################################################################################################################
##########################################################################################################################
##########################################################################################################################

#Load libraries and data
library("beanplot")
library("lattice")
library("gplots")
library("nlme") # GLS
library("spgwr") # GWR
library("outliers") # For outlier testing - http://cran.r-project.org/web/packages/outliers/index.html
library("car") # Companion to Applied Regression (incl. variance inflation factor (VIF)) - http://cran.r-project.org/web/packages/car/index.html
library("hexbin")

wd <- "/home/stefan/Okokart/fin/"

skgr <- read.csv("/home/stefan/Okokart/skgr.csv", sep=",", header=TRUE)

#Calculate continentality (product of amount of ocean of all scales)
skgr$continentality <- (skgr$amount_ocean_180200m * skgr$amount_ocean_100200m * skgr$amount_ocean_50200m * skgr$amount_ocean_25000m * skgr$amount_ocean_10100m * skgr$amount_ocean_5050m)
skgr$continentality2 <- (skgr$amount_ocean_180200m + skgr$amount_ocean_100200m + skgr$amount_ocean_50200m + skgr$amount_ocean_25000m + skgr$amount_ocean_10100m + skgr$amount_ocean_5050m)

#Calculate sum of forest (sum of z-distance to forest of all scales)
skgr$max_forest_sum_local <- skgr$max_forest_250m+skgr$max_forest_550m+skgr$max_forest_1050m+skgr$max_forest_2550m
skgr$max_forest_sum <- (skgr$max_forest_50200m + skgr$max_forest_25000m + skgr$max_forest_10100m + skgr$max_forest_5050m + skgr$max_forest_2550m)
skgr$max_forest_sum_all <- (skgr$max_forest_50200m + skgr$max_forest_25000m + skgr$max_forest_10100m + skgr$max_forest_5050m + skgr$max_forest_2550m + skgr$max_forest_1050m + skgr$max_forest_550m + skgr$max_forest_250m)

#Set all values of geology < 1 to 1 (to be used as.factor)
skgr$geol_rich[skgr$geol_rich<1] <- 1
skgr$quart_gw[skgr$quart_gw<1] <- 1
skgr$quart_gw[skgr$quart_gw==5] <- 4

#Normalize terrain variation
skgr$TPI_5100m_stddev_n <- (skgr$TPI_5100m_stddev-min(skgr$TPI_5100m_stddev))/(max(skgr$TPI_5100m_stddev)-min(skgr$TPI_5100m_stddev))
skgr$TPI_3100m_stddev_n <- (skgr$TPI_3100m_stddev-min(skgr$TPI_3100m_stddev))/(max(skgr$TPI_3100m_stddev)-min(skgr$TPI_3100m_stddev))
skgr$TPI_1100m_stddev_n <- (skgr$TPI_1100m_stddev-min(skgr$TPI_1100m_stddev))/(max(skgr$TPI_1100m_stddev)-min(skgr$TPI_1100m_stddev))
skgr$tv <- (skgr$TPI_5100m_stddev_n+skgr$TPI_3100m_stddev_n+skgr$TPI_1100m_stddev_n)
skgr$tvn <- (skgr$tv-min(skgr$tv))/(max(skgr$tv)-min(skgr$tv))

#Normalize amount ocean
skgrMergeF1m2$amount_ocean_5050m_n <- (skgrMergeF1m2$amount_ocean_5050m-min(skgr$amount_ocean_5050m))/(max(skgr$amount_ocean_5050m)-min(skgr$amount_ocean_5050m))
skgrMergeF1m2$amount_ocean_10100m_n <- (skgrMergeF1m2$amount_ocean_10100m-min(skgr$amount_ocean_10100m))/(max(skgr$amount_ocean_10100m)-min(skgr$amount_ocean_10100m))
skgrMergeF1m2$amount_ocean_25000m_n <- (skgrMergeF1m2$amount_ocean_25000m-min(skgr$amount_ocean_25000m))/(max(skgr$amount_ocean_25000m)-min(skgr$amount_ocean_25000m))
skgrMergeF1m2$amount_ocean_50200m_n <- (skgrMergeF1m2$amount_ocean_50200m-min(skgr$amount_ocean_50200m))/(max(skgr$amount_ocean_50200m)-min(skgr$amount_ocean_50200m))
skgrMergeF1m2$amount_ocean_100200m_n <- (skgrMergeF1m2$amount_ocean_100200m-min(skgr$amount_ocean_100200m))/(max(skgr$amount_ocean_100200m)-min(skgr$amount_ocean_100200m))
skgrMergeF1m2$amount_ocean_180200m_n <- (skgrMergeF1m2$amount_ocean_180200m-min(skgr$amount_ocean_180200m))/(max(skgr$amount_ocean_180200m)-min(skgr$amount_ocean_180200m))
skgrMergeF1m2$amount_ocean_250200m_n <- (skgrMergeF1m2$amount_ocean_250200m-min(skgr$amount_ocean_250200m))/(max(skgr$amount_ocean_250200m)-min(skgr$amount_ocean_250200m))

skgrMergeF1m2$amount_ocean_avg_n <- sapply(1:length(skgrMergeF1m2$hoh), function(x) mean(skgrMergeF1m2$amount_ocean_250200m_n[x],skgrMergeF1m2$amount_ocean_180200m_n[x],skgrMergeF1m2$amount_ocean_100200m_n[x],skgrMergeF1m2$amount_ocean_50200m_n[x],skgrMergeF1m2$amount_ocean_25000m_n[x],skgrMergeF1m2$amount_ocean_10100m[x],skgrMergeF1m2$amount_ocean_5050m_n[x]))
skgrMergeF1m2$amount_ocean_avg_ln <- sapply(1:length(skgrMergeF1m2$hoh), function(x) mean(skgrMergeF1m2$amount_ocean_250200m_n[x],skgrMergeF1m2$amount_ocean_180200m_n[x],skgrMergeF1m2$amount_ocean_100200m_n[x],skgrMergeF1m2$amount_ocean_50200m_n[x]))

#Adding filter parameter for temperature vs altitude above sea level - Tij = Ti – (Hi-Hj)*0.055 (T is temperature, H is altitude above sea level, i is the pixel in the 1 km grid, and j is the pixel in the 10m grid)
skgr$tetraterm_total_kor_0_6 <- skgr$tetraterm_total - ((skgr$hoh-skgr$dem_1km_avg) * 0.06) #corrected temperature for altitude during the three warmest months of the year
skgr$tetraterm_total_kor <- skgr$tetraterm_total - ((skgr$hoh-skgr$dem_1km_avg) * 0.055) #corrected temperature for altitude during the four warmest months of the year

#Calculate gruped variables by combination of forest patch and open patch
open_patches <- gapply(skgr, c("hoh"), FUN=function(x) max(x), groups=paste(as.factor(skgr$forest_patch),as.factor(skgr$max_alt_open_patch),as.factor(skgr$avg_alt_open_patch), sep="_"))
skgr$GID <- as.character(paste(as.factor(skgr$forest_patch),as.factor(skgr$max_alt_open_patch),as.factor(skgr$avg_alt_open_patch), sep="_"))
skgr <- merge(skgr, data.frame(GID=as.character(names(open_patches)), max_z_dist_open_patch=as.vector(open_patches)), by="GID")

patches_250m_gid <- gapply(skgr, c("max_forest_250m"), FUN=function(x) min(x), groups=as.factor(skgr$GID))
patches_550m_gid <- gapply(skgr, c("max_forest_550m"), FUN=function(x) min(x), groups=as.factor(skgr$GID))
patches_1050m_gid <- gapply(skgr, c("max_forest_1050m"), FUN=function(x) min(x), groups=as.factor(skgr$GID))
patches_2550m_gid <- gapply(skgr, c("max_forest_2550m"), FUN=function(x) min(x), groups=as.factor(skgr$GID))
patches_5050m_gid <- gapply(skgr, c("max_forest_5050m"), FUN=function(x) min(x), groups=as.factor(skgr$GID))
patches_10100m_gid <- gapply(skgr, c("max_forest_10100m"), FUN=function(x) min(x), groups=as.factor(skgr$GID))
patches_25000m_gid <- gapply(skgr, c("max_forest_25000m"), FUN=function(x) min(x), groups=as.factor(skgr$GID))
patches_50200m_gid <- gapply(skgr, c("max_forest_50200m"), FUN=function(x) min(x), groups=as.factor(skgr$GID))

patches_gid <- merge(merge(merge(merge(merge(merge(merge(data.frame(GID=names(patches_250m_gid), max_forest_250m_gid_patch=patches_250m_gid), data.frame(GID=names(patches_550m_gid), max_forest_550m_gid_patch=patches_550m_gid), by="GID"), data.frame(GID=names(patches_1050m_gid), max_forest_1050m_gid_patch=patches_1050m_gid), by="GID"), data.frame(GID=names(patches_2550m_gid), max_forest_2550m_gid_patch=patches_2550m_gid), by="GID"), data.frame(GID=names(patches_5050m_gid), max_forest_5050m_gid_patch=patches_5050m_gid), by="GID"), data.frame(GID=names(patches_10100m_gid), max_forest_10100m_gid_patch=patches_10100m_gid), by="GID"), data.frame(GID=names(patches_25000m_gid), max_forest_25000m_gid_patch=patches_25000m_gid), by="GID"), data.frame(GID=names(patches_50200m_gid), max_forest_50200m_gid_patch=patches_50200m_gid), by="GID")
patches_gid$max_forest_sum_patch_gid <- patches_gid$max_forest_2550m_gid_patch+patches_gid$max_forest_5050m_gid_patch+patches_gid$max_forest_10100m_gid_patch+patches_gid$max_forest_25000m_gid_patch+patches_gid$max_forest_50200m_gid_patch
patches_gid$max_forest_sum_all_patch_gid <- patches_gid$max_forest_250m_gid_patch+patches_gid$max_forest_550m_gid_patch+patches_gid$max_forest_1050m_gid_patch+patches_gid$max_forest_2550m_gid_patch+patches_gid$max_forest_5050m_gid_patch+patches_gid$max_forest_10100m_gid_patch+patches_gid$max_forest_25000m_gid_patch+patches_gid$max_forest_50200m_gid_patch
skgr <- merge(skgr, patches_gid, by=c("GID"))

patches_gid_TPI_5100m_stddev_n <- by(skgr$TPI_5100m_stddev_n,skgr$GID,FUN=mean)
patches_gid_TPI_3100m_stddev_n <- by(skgr$TPI_3100m_stddev_n,skgr$GID,FUN=mean)
patches_gid_TPI_1100m_stddev_n <- by(skgr$TPI_1100m_stddev_n,skgr$GID,FUN=mean)
patches_gid_tvn <- by(skgr$tvn,skgr$GID,FUN=mean)

skgr <- merge(skgr, merge(merge(merge(data.frame(GID=names(patches_gid_TPI_5100m_stddev_n), TPI_5100m_stddev_n_gid_patch=as.vector(patches_gid_TPI_5100m_stddev_n)), data.frame(GID=names(patches_gid_TPI_3100m_stddev_n), TPI_3100m_stddev_n_gid_patch=as.vector(patches_gid_TPI_3100m_stddev_n)), by="GID"), data.frame(GID=names(patches_gid_TPI_1100m_stddev_n), TPI_1100m_stddev_n_gid_patch=as.vector(patches_gid_TPI_1100m_stddev_n)), by="GID"), data.frame(GID=names(patches_gid_tvn), tvn_gid_patch=as.vector(patches_gid_tvn)), by="GID"), by="GID")

#
skgrMergeF1 <- skgr

#####################################################
#Initialise variable to trac number of points during filtering
points_n <- list()
points_n["Total"] <- length(skgrMergeF1$hoh)

#Plot altitude for all points
png('/home/stefan/Okokart/fin/Filtering_reference_altitude_all.png', width = 1000, height = 1000, units = "px", pointsize = 24, bg = "white", res = 96, type = c("cairo"))
zcol <- level.colors(skgrm$hoh, at = c(0, 50, 100, 150, 200, 250, 300, 350, 400, 450, 500, 550, 600, 650, 700, 750, 800, 850, 900, 950, 1000, 1050, 1100, 1150, 1200, 1250, 1300), col.regions=terrain.colors(27), interpolate=c("linear"))
xyplot(Y ~ X | "Altitude of all possible reference points", data=skgrm, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
dev.off()

#Filter NoData values
skgrMergeF1 <- skgrMergeF1[(skgrMergeF1$AGDD_2000>0 & skgrMergeF1$actuality>0 & skgrMergeF1$geol_rich>0 & skgrMergeF1$quart_gw>0),]
#skgrMergeF1 <- read.csv("/home/stefan/Okokart/skgrMergeF1_final_strict.csv", sep=",", header=TRUE)
points_n["Without NoData"] <- length(skgrMergeF1$hoh)

png('/home/stefan/Okokart/fin/Filtering_reference_altitude_F1_S00.png', width = 1000, height = 1000, units = "px", pointsize = 24, bg = "white", res = 96, type = c("cairo"))
zcol <- level.colors(skgrMergeF1$hoh, at = c(0, 50, 100, 150, 200, 250, 300, 350, 400, 450, 500, 550, 600, 650, 700, 750, 800, 850, 900, 950, 1000, 1050, 1100, 1150, 1200, 1250, 1300), col.regions=terrain.colors(27), interpolate=c("linear"))
xyplot(Y ~ X | "Altitude of reference points in filter 0", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
dev.off()

png('/home/stefan/Okokart/fin/Filtering_point_density_F1_S00.png', width = 1000, height = 1000, units = "px", pointsize = 24, bg = "white", res = 96, type = c("cairo"))
hexbinplot(Y ~ X | "Point density after filter 0", skgrMergeF1, aspect = 1, .aspect.ratio = 1, xbins=120, draw=TRUE, colorkey=TRUE)
dev.off()


##############################################################
#Identify suitable filter settings for 250m scale
png('/home/stefan/Okokart/fin/Filtering_max_forest_250m.png', width = 5000, height = 5000, units = "px", pointsize = 10, bg = "white", res = 96, type = c("cairo"))
zcol <- level.colors(skgrMergeF1$max_forest_250m, at = c(0, 5, 7.5, 10, 12.5, 15, 20), col.regions=colorRampPalette(c("yellow", "green", "cyan", "blue", "purple", "magenta", "red")))
xyplot(Y ~ X | "Filtering_max_forest_250m", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
dev.off()

png('/home/stefan/Okokart/fin/Filtering_max_forest_gid_patch_250m.png', width = 5000, height = 5000, units = "px", pointsize = 10, bg = "white", res = 96, type = c("cairo"))
zcol <- level.colors(skgrMergeF1$max_forest_250m_gid_patch, at = c(0, 0.25, 0.5, 0.75, 1, 2, 20), col.regions=colorRampPalette(c("yellow", "green", "cyan", "blue", "purple", "magenta", "red")))
xyplot(Y ~ X | "Filtering_max_forest_gid_patch_250m", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
dev.off()

png('/home/stefan/Okokart/fin/Filtering_max_forest_gid_patch_250m_0p5_0p1_2.png', width = 5000, height = 5000, units = "px", pointsize = 10, bg = "white", res = 96, type = c("cairo"))
zcol <- level.colors(I(skgrMergeF1$max_forest_250m_gid_patch/((ifelse(skgrMergeF1$tvn_gid_patch>0.5,0.5,skgrMergeF1$tvn_gid_patch)*1.9+0.1))), at = c(0, 0.025, 0.05, 0.075, 0.1, 0.2, 0.3, 0.5, 130), col.regions=colorRampPalette(c("yellow", "green", "cyan", "blue", "purple", "magenta", "red")))
xyplot(Y ~ X | "Filtering_max_forest_gid_patch_250m", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
dev.off()

png('/home/stefan/Okokart/fin/Filtering_max_forest_250m_tvn_0p5_0p1_2.png', width = 5000, height = 5000, units = "px", pointsize = 10, bg = "white", res = 96, type = c("cairo"))
zcol <- level.colors(I(skgrMergeF1$max_forest_250m/((ifelse(skgrMergeF1$tvn>0.5,0.5,skgrMergeF1$tvn)*1.9+0.1))), at = c(0, 30, 32.5, 35, 37.5), col.regions=colorRampPalette(c("yellow", "green", "cyan", "blue", "purple", "magenta", "red")))
xyplot(Y ~ X | "Filtering_max_forest_patch_250m_tvn_0p5_0p1_2", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
dev.off()

##############################################################
#Filter 250m
skgrMergeF1 <- skgrm[skgrm$max_forest_250m<=10,]
points_n["max_forest_250m<10"] <- length(skgrMergeF1$hoh)
png('/home/stefan/Okokart/fin/Filtering_reference_altitude_F1_S01a.png', width = 1000, height = 1000, units = "px", pointsize = 24, bg = "white", res = 96, type = c("cairo"))
zcol <- level.colors(skgrMergeF1$hoh, at = c(0, 50, 100, 150, 200, 250, 300, 350, 400, 450, 500, 550, 600, 650, 700, 750, 800, 850, 900, 950, 1000, 1050, 1100, 1150, 1200, 1250, 1300), col.regions=terrain.colors(27), interpolate=c("linear"))
xyplot(Y ~ X | "Altitude of reference points in filter 1a", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
dev.off()

skgrMergeF1 <- skgrMergeF1[skgrMergeF1$max_forest_250m_gid_patch<0.5,]
points_n["max_forest_250m_patch<0.5"] <- length(skgrMergeF1$hoh)
png('/home/stefan/Okokart/fin/Filtering_reference_altitude_F1_S01b.png', width = 1000, height = 1000, units = "px", pointsize = 24, bg = "white", res = 96, type = c("cairo"))
zcol <- level.colors(skgrMergeF1$hoh, at = c(0, 50, 100, 150, 200, 250, 300, 350, 400, 450, 500, 550, 600, 650, 700, 750, 800, 850, 900, 950, 1000, 1050, 1100, 1150, 1200, 1250, 1300), col.regions=terrain.colors(27), interpolate=c("linear"))
xyplot(Y ~ X | "Altitude of reference points in filter 1b", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
dev.off()

skgrMergeF1 <- skgrMergeF1[I(skgrMergeF1$max_forest_250m/((ifelse(skgrMergeF1$tvn>0.5,0.5,skgrMergeF1$tvn)*1.9+0.1)))<30,]
points_n["max_forest_250m_tvn_0p5_0p1_2<30"] <- length(skgrMergeF1$hoh)
png('/home/stefan/Okokart/fin/Filtering_reference_altitude_F1_S01c.png', width = 1000, height = 1000, units = "px", pointsize = 24, bg = "white", res = 96, type = c("cairo"))
zcol <- level.colors(skgrMergeF1$hoh, at = c(0, 50, 100, 150, 200, 250, 300, 350, 400, 450, 500, 550, 600, 650, 700, 750, 800, 850, 900, 950, 1000, 1050, 1100, 1150, 1200, 1250, 1300), col.regions=terrain.colors(27), interpolate=c("linear"))
xyplot(Y ~ X | "Altitude of reference points in filter 1c", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
dev.off()

skgrMergeF1 <- skgrMergeF1[I(skgrMergeF1$max_forest_250m_gid_patch/((ifelse(skgrMergeF1$tvn_gid_patch>0.5,0.5,skgrMergeF1$tvn_gid_patch)*1.9+0.1)))<0.025,]
points_n["max_forest_250m_patch_tvn_0p5_0p1_2<0.025"] <- length(skgrMergeF1$hoh)
png('/home/stefan/Okokart/fin/Filtering_reference_altitude_F1_S01d.png', width = 1000, height = 1000, units = "px", pointsize = 24, bg = "white", res = 96, type = c("cairo"))
zcol <- level.colors(skgrMergeF1$hoh, at = c(0, 50, 100, 150, 200, 250, 300, 350, 400, 450, 500, 550, 600, 650, 700, 750, 800, 850, 900, 950, 1000, 1050, 1100, 1150, 1200, 1250, 1300), col.regions=terrain.colors(27), interpolate=c("linear"))
xyplot(Y ~ X | "Altitude of reference points in filter 1d", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
dev.off()

png('/home/stefan/Okokart/fin/Filtering_point_density_F1_S01.png', width = 1000, height = 1000, units = "px", pointsize = 24, bg = "white", res = 96, type = c("cairo"))
hexbinplot(Y ~ X | "Point density after filter 1", skgrMergeF1, aspect = 1, .aspect.ratio = 1, xbins=120, draw=TRUE, colorkey=TRUE)
dev.off()

##############################################################
#Identify suitable filter settings for 550m scale
png('/home/stefan/Okokart/fin/Filtering_max_forest_550m.png', width = 5000, height = 5000, units = "px", pointsize = 10, bg = "white", res = 96, type = c("cairo"))
zcol <- level.colors(skgrMergeF1$max_forest_550m, at = c(0, 15, 17.5, 20, 22.5, 25, 30), col.regions=colorRampPalette(c("yellow", "green", "cyan", "blue", "purple", "magenta", "red")))
xyplot(Y ~ X | "Filtering_max_forest_550m", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
dev.off()

png('/home/stefan/Okokart/fin/Filtering_max_forest_gid_patch_550m.png', width = 5000, height = 5000, units = "px", pointsize = 10, bg = "white", res = 96, type = c("cairo"))
zcol <- level.colors(skgrMergeF1$max_forest_550m_gid_patch, at = c(0, 0.025, 0.05, 0.075, 0.1, 0.25, 0.5, 30), col.regions=colorRampPalette(c("yellow", "green", "cyan", "blue", "purple", "magenta", "red")))
xyplot(Y ~ X | "Filtering_max_forest_gid_patch_550m", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
dev.off()

png('/home/stefan/Okokart/fin/Filtering_max_forest_gid_patch_550m_0p5_0p1_2.png', width = 5000, height = 5000, units = "px", pointsize = 10, bg = "white", res = 96, type = c("cairo"))
zcol <- level.colors(I(skgrMergeF1$max_forest_550m_gid_patch/((ifelse(skgrMergeF1$tvn_gid_patch>0.5,0.5,skgrMergeF1$tvn_gid_patch)*1.9+0.1))), at = c(0, 0.0025, 0.005, 0.0075, 0.01, 0.015, 0.2, 0.25, 130), col.regions=colorRampPalette(c("yellow", "green", "cyan", "blue", "purple", "magenta", "red")))
xyplot(Y ~ X | "Filtering_max_forest_gid_patch_550m", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
dev.off()

png('/home/stefan/Okokart/fin/Filtering_max_forest_550m_tvn_0p5_0p1_2.png', width = 5000, height = 5000, units = "px", pointsize = 10, bg = "white", res = 96, type = c("cairo"))
zcol <- level.colors(I(skgrMergeF1$max_forest_550m/((ifelse(skgrMergeF1$tvn>0.5,0.5,skgrMergeF1$tvn)*1.9+0.1))), at = c(0, 25, 30, 31, 32, 33, 34, 35, 130), col.regions=colorRampPalette(c("yellow", "green", "cyan", "blue", "purple", "magenta", "red")))
xyplot(Y ~ X | "Filtering_max_forest_patch_550m_tvn_0p5_0p1_2", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
dev.off()

##############################################################
#Filter 550m
skgrMergeF1 <- skgrMergeF1[skgrMergeF1$max_forest_550m<20,]
points_n["max_forest_550m<20"] <- length(skgrMergeF1$hoh)
png('/home/stefan/Okokart/fin/Filtering_reference_altitude_F1_S02a.png', width = 1000, height = 1000, units = "px", pointsize = 24, bg = "white", res = 96, type = c("cairo"))
zcol <- level.colors(skgrMergeF1$hoh, at = c(0, 50, 100, 150, 200, 250, 300, 350, 400, 450, 500, 550, 600, 650, 700, 750, 800, 850, 900, 950, 1000, 1050, 1100, 1150, 1200, 1250, 1300), col.regions=terrain.colors(27), interpolate=c("linear"))
xyplot(Y ~ X | "Altitude of reference points in filter 2a", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
dev.off()

skgrMergeF1 <- skgrMergeF1[skgrMergeF1$max_forest_550m_gid_patch<0.025,]
points_n["max_forest_550m_gid_patch<0.025"] <- length(skgrMergeF1$hoh)
png('/home/stefan/Okokart/fin/Filtering_reference_altitude_F1_S02b.png', width = 1000, height = 1000, units = "px", pointsize = 24, bg = "white", res = 96, type = c("cairo"))
zcol <- level.colors(skgrMergeF1$hoh, at = c(0, 50, 100, 150, 200, 250, 300, 350, 400, 450, 500, 550, 600, 650, 700, 750, 800, 850, 900, 950, 1000, 1050, 1100, 1150, 1200, 1250, 1300), col.regions=terrain.colors(27), interpolate=c("linear"))
xyplot(Y ~ X | "Altitude of reference points in filter 2b", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
dev.off()

#patch/tvn had no effect (all=0)

skgrMergeF1 <- skgrMergeF1[I(skgrMergeF1$max_forest_550m/((ifelse(skgrMergeF1$tvn>0.5,0.5,skgrMergeF1$tvn)*1.9+0.1)))<35,]
points_n["max_forest_550m_tvn_0p5_0p1_2<35"] <- length(skgrMergeF1$hoh)
png('/home/stefan/Okokart/fin/Filtering_reference_altitude_F1_S02c.png', width = 1000, height = 1000, units = "px", pointsize = 24, bg = "white", res = 96, type = c("cairo"))
zcol <- level.colors(skgrMergeF1$hoh, at = c(0, 50, 100, 150, 200, 250, 300, 350, 400, 450, 500, 550, 600, 650, 700, 750, 800, 850, 900, 950, 1000, 1050, 1100, 1150, 1200, 1250, 1300), col.regions=terrain.colors(27), interpolate=c("linear"))
xyplot(Y ~ X | "Altitude of reference points in filter 2c", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
dev.off()

png('/home/stefan/Okokart/fin/Filtering_point_density_F1_S02.png', width = 1000, height = 1000, units = "px", pointsize = 24, bg = "white", res = 96, type = c("cairo"))
hexbinplot(Y ~ X | "Point density after filter 2", skgrMergeF1, aspect = 1, .aspect.ratio = 1, xbins=120, draw=TRUE, colorkey=TRUE)
dev.off()

##############################################################
#Identify suitable filter settings for 1050m scale
png('/home/stefan/Okokart/fin/Filtering_max_forest_1050m.png', width = 5000, height = 5000, units = "px", pointsize = 10, bg = "white", res = 96, type = c("cairo"))
zcol <- level.colors(skgrMergeF1$max_forest_1050m, at = c(0, 35, 37.5, 40, 42.5, 45, 47.5, 650), col.regions=colorRampPalette(c("yellow", "green", "cyan", "blue", "purple", "magenta", "red")))
xyplot(Y ~ X | "Filtering_max_forest_1050m", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
dev.off()

png('/home/stefan/Okokart/fin/Filtering_max_forest_1050m_tvn_0p5_0p1_2.png', width = 5000, height = 5000, units = "px", pointsize = 10, bg = "white", res = 96, type = c("cairo"))
zcol <- level.colors(I(skgrMergeF1$max_forest_1050m/((ifelse(skgrMergeF1$tvn>0.5,0.5,skgrMergeF1$tvn)*1.9+0.1))), at = c(0, 62.5, 65, 67.5, 70, 75, 90, 340), col.regions=colorRampPalette(c("yellow", "green", "cyan", "blue", "purple", "magenta", "red")))
xyplot(Y ~ X | "Filtering_max_forest_gid_patch_1050m_tvn_0p5_0p1_2", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
dev.off()

png('/home/stefan/Okokart/fin/Filtering_max_forest_gid_patch_1050m.png', width = 5000, height = 5000, units = "px", pointsize = 10, bg = "white", res = 96, type = c("cairo"))
zcol <- level.colors(skgrMergeF1$max_forest_1050m_gid_patch, at = c(0, 0.00025, 0.0005, 0.00075, 0.001, 0.0025, 30), col.regions=colorRampPalette(c("yellow", "green", "cyan", "blue", "purple", "magenta", "red")))
xyplot(Y ~ X | "Filtering_max_forest_gid_patch_1050m", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
dev.off()

png('/home/stefan/Okokart/fin/Filtering_max_forest_gid_patch_1050m_0p5_0p1_2.png', width = 5000, height = 5000, units = "px", pointsize = 10, bg = "white", res = 96, type = c("cairo"))
zcol <- level.colors(I(skgrMergeF1$max_forest_1050m_gid_patch/((ifelse(skgrMergeF1$tvn_gid_patch>0.5,0.5,skgrMergeF1$tvn_gid_patch)*1.9+0.1))), at = c(0, 0.000025, 0.00005, 0.000075, 0.0001, 130), col.regions=colorRampPalette(c("yellow", "green", "cyan", "blue", "purple", "magenta", "red")))
xyplot(Y ~ X | "Filtering_max_forest_gid_patch_1050m", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
dev.off()

##############################################################
#Filter 1050m
skgrMergeF1 <- skgrMergeF1[skgrMergeF1$max_forest_1050m<35,]
points_n["max_forest_1050m<35"] <- length(skgrMergeF1$hoh)
png('/home/stefan/Okokart/fin/Filtering_reference_altitude_F1_S03a.png', width = 1000, height = 1000, units = "px", pointsize = 24, bg = "white", res = 96, type = c("cairo"))
zcol <- level.colors(skgrMergeF1$hoh, at = c(0, 50, 100, 150, 200, 250, 300, 350, 400, 450, 500, 550, 600, 650, 700, 750, 800, 850, 900, 950, 1000, 1050, 1100, 1150, 1200, 1250, 1300), col.regions=terrain.colors(27), interpolate=c("linear"))
xyplot(Y ~ X | "Altitude of reference points in filter 3a", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
dev.off()

skgrMergeF1 <- skgrMergeF1[skgrMergeF1$max_forest_1050m_gid_patch<0.00075,]
points_n["max_forest_1050m_patch<0.00075"] <- length(skgrMergeF1$hoh)
png('/home/stefan/Okokart/fin/Filtering_reference_altitude_F1_S03b.png', width = 1000, height = 1000, units = "px", pointsize = 24, bg = "white", res = 96, type = c("cairo"))
zcol <- level.colors(skgrMergeF1$hoh, at = c(0, 50, 100, 150, 200, 250, 300, 350, 400, 450, 500, 550, 600, 650, 700, 750, 800, 850, 900, 950, 1000, 1050, 1100, 1150, 1200, 1250, 1300), col.regions=terrain.colors(27), interpolate=c("linear"))
xyplot(Y ~ X | "Altitude of reference points in filter 3b", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
dev.off()

skgrMergeF1 <- skgrMergeF1[I(skgrMergeF1$max_forest_1050m/((ifelse(skgrMergeF1$tvn>0.5,0.5,skgrMergeF1$tvn)*1.9+0.1)))<65,]
points_n["max_forest_1050m_tvn_0p5_0p1_2<65"] <- length(skgrMergeF1$hoh)
png('/home/stefan/Okokart/fin/Filtering_reference_altitude_F1_S03c.png', width = 1000, height = 1000, units = "px", pointsize = 24, bg = "white", res = 96, type = c("cairo"))
zcol <- level.colors(skgrMergeF1$hoh, at = c(0, 50, 100, 150, 200, 250, 300, 350, 400, 450, 500, 550, 600, 650, 700, 750, 800, 850, 900, 950, 1000, 1050, 1100, 1150, 1200, 1250, 1300), col.regions=terrain.colors(27), interpolate=c("linear"))
xyplot(Y ~ X | "Altitude of reference points in filter 3c", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
dev.off()

skgrMergeF1 <- skgrMergeF1[I(skgrMergeF1$max_forest_1050m_gid_patch/((ifelse(skgrMergeF1$tvn_gid_patch>0.5,0.5,skgrMergeF1$tvn_gid_patch)*1.9+0.1)))<0.0001,]
points_n["max_forest_1050m_patch_tvn_0p5_0p1_2<0.0001"] <- length(skgrMergeF1$hoh)
png('/home/stefan/Okokart/fin/Filtering_reference_altitude_F1_S03d.png', width = 1000, height = 1000, units = "px", pointsize = 24, bg = "white", res = 96, type = c("cairo"))
zcol <- level.colors(skgrMergeF1$hoh, at = c(0, 50, 100, 150, 200, 250, 300, 350, 400, 450, 500, 550, 600, 650, 700, 750, 800, 850, 900, 950, 1000, 1050, 1100, 1150, 1200, 1250, 1300), col.regions=terrain.colors(27), interpolate=c("linear"))
xyplot(Y ~ X | "Altitude of reference points in filter 3d", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
dev.off()

png('/home/stefan/Okokart/fin/Filtering_point_density_F1_S03.png', width = 1000, height = 1000, units = "px", pointsize = 24, bg = "white", res = 96, type = c("cairo"))
hexbinplot(Y ~ X | "Point density after filter 3", skgrMergeF1, aspect = 1, .aspect.ratio = 1, xbins=120, draw=TRUE, colorkey=TRUE)
dev.off()

##############################################################
#Identify suitable filter settings for 2550m scale
png('/home/stefan/Okokart/fin/Filtering_max_forest_2550m.png', width = 5000, height = 5000, units = "px", pointsize = 10, bg = "white", res = 96, type = c("cairo"))
zcol <- level.colors(skgrMergeF1$max_forest_2550m, at = c(0, 75, 80, 85, 90, 100, 125, 150, 200, 300, 650), col.regions=colorRampPalette(c("yellow", "green", "cyan", "blue", "purple", "magenta", "red")))
xyplot(Y ~ X | "Filtering_max_forest_2550m", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
dev.off()

png('/home/stefan/Okokart/fin/Filtering_max_forest_2550m_tvn_0p5_0p1_2.png', width = 5000, height = 5000, units = "px", pointsize = 10, bg = "white", res = 96, type = c("cairo"))
zcol <- level.colors(I(skgrMergeF1$max_forest_2550m/((ifelse(skgrMergeF1$tvn>0.5,0.5,skgrMergeF1$tvn)*1.9+0.1))), at = c(0, 250, 275, 300, 350, 400, 500, 1250), col.regions=colorRampPalette(c("yellow", "green", "cyan", "blue", "purple", "magenta", "red")))
xyplot(Y ~ X | "Filtering_max_forest_patch_2550m_tvn_0p5_0p1_2", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
dev.off()

png('/home/stefan/Okokart/fin/Filtering_max_forest_gid_patch_2550m.png', width = 5000, height = 5000, units = "px", pointsize = 10, bg = "white", res = 96, type = c("cairo"))
zcol <- level.colors(skgrMergeF1$max_forest_2550m_gid_patch, at = c(0, 5, 7.5, 10, 12.5, 15, 20, 500), col.regions=colorRampPalette(c("yellow", "green", "cyan", "blue", "purple", "magenta", "red")))
xyplot(Y ~ X | "Filtering_max_forest_gid_patch_2550m", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
dev.off()

png('/home/stefan/Okokart/fin/Filtering_max_forest_gid_patch_2550m_0p5_0p1_2.png', width = 5000, height = 5000, units = "px", pointsize = 10, bg = "white", res = 96, type = c("cairo"))
zcol <- level.colors(I(skgrMergeF1$max_forest_2550m_gid_patch/((ifelse(skgrMergeF1$tvn_gid_patch>0.5,0.5,skgrMergeF1$tvn_gid_patch)*1.9+0.1))), at = c(0, 2.5, 5, 10, 15, 20, 25, 130), col.regions=colorRampPalette(c("yellow", "green", "cyan", "blue", "purple", "magenta", "red")))
xyplot(Y ~ X | "Filtering_max_forest_gid_patch_2550m", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
dev.off()

##############################################################
#Filter 2550m
skgrMergeF1 <- skgrMergeF1[skgrMergeF1$max_forest_2550m<100,]
points_n["max_forest_2550m<100"] <- length(skgrMergeF1$hoh)
png('/home/stefan/Okokart/fin/Filtering_reference_altitude_F1_S04a.png', width = 1000, height = 1000, units = "px", pointsize = 24, bg = "white", res = 96, type = c("cairo"))
zcol <- level.colors(skgrMergeF1$hoh, at = c(0, 50, 100, 150, 200, 250, 300, 350, 400, 450, 500, 550, 600, 650, 700, 750, 800, 850, 900, 950, 1000, 1050, 1100, 1150, 1200, 1250, 1300), col.regions=terrain.colors(27), interpolate=c("linear"))
xyplot(Y ~ X | "Altitude of reference points in filter 4a", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
dev.off()

skgrMergeF1 <- skgrMergeF1[skgrMergeF1$max_forest_2550m_gid_patch<=10,]
points_n["max_forest_2550m_patch<10"] <- length(skgrMergeF1$hoh)
png('/home/stefan/Okokart/fin/Filtering_reference_altitude_F1_S04b.png', width = 1000, height = 1000, units = "px", pointsize = 24, bg = "white", res = 96, type = c("cairo"))
zcol <- level.colors(skgrMergeF1$hoh, at = c(0, 50, 100, 150, 200, 250, 300, 350, 400, 450, 500, 550, 600, 650, 700, 750, 800, 850, 900, 950, 1000, 1050, 1100, 1150, 1200, 1250, 1300), col.regions=terrain.colors(27), interpolate=c("linear"))
xyplot(Y ~ X | "Altitude of reference points in filter 4b", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
dev.off()

skgrMergeF1 <- skgrMergeF1[I(skgrMergeF1$max_forest_2550m/((ifelse(skgrMergeF1$tvn>0.5,0.5,skgrMergeF1$tvn)*1.9+0.1)))<=250,]
points_n["max_forest_2550m_tvn_0p5_0p1_2<250"] <- length(skgrMergeF1$hoh)
png('/home/stefan/Okokart/fin/Filtering_reference_altitude_F1_S04c.png', width = 1000, height = 1000, units = "px", pointsize = 24, bg = "white", res = 96, type = c("cairo"))
zcol <- level.colors(skgrMergeF1$hoh, at = c(0, 50, 100, 150, 200, 250, 300, 350, 400, 450, 500, 550, 600, 650, 700, 750, 800, 850, 900, 950, 1000, 1050, 1100, 1150, 1200, 1250, 1300), col.regions=terrain.colors(27), interpolate=c("linear"))
xyplot(Y ~ X | "Altitude of reference points in filter 4c", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
dev.off()

skgrMergeF1 <- skgrMergeF1[I(skgrMergeF1$max_forest_2550m_gid_patch/((ifelse(skgrMergeF1$tvn_gid_patch>0.5,0.5,skgrMergeF1$tvn_gid_patch)*1.9+0.1)))<=2.5,]
points_n["max_forest_2550m_patch_tvn_0p5_0p1_2<=2.5"] <- length(skgrMergeF1$hoh)
png('/home/stefan/Okokart/fin/Filtering_reference_altitude_F1_S04d.png', width = 1000, height = 1000, units = "px", pointsize = 24, bg = "white", res = 96, type = c("cairo"))
zcol <- level.colors(skgrMergeF1$hoh, at = c(0, 50, 100, 150, 200, 250, 300, 350, 400, 450, 500, 550, 600, 650, 700, 750, 800, 850, 900, 950, 1000, 1050, 1100, 1150, 1200, 1250, 1300), col.regions=terrain.colors(27), interpolate=c("linear"))
xyplot(Y ~ X | "Altitude of reference points in filter 4d", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
dev.off()

png('/home/stefan/Okokart/fin/Filtering_point_density_F1_S04.png', width = 1000, height = 1000, units = "px", pointsize = 24, bg = "white", res = 96, type = c("cairo"))
hexbinplot(Y ~ X | "Point density after filter 4", skgrMergeF1, aspect = 1, .aspect.ratio = 1, xbins=120, draw=TRUE, colorkey=TRUE)
dev.off()

##############################################################
#Identify suitable filter settings for max_alt_open_patch - max_z_dist_open_patch
png('/home/stefan/Okokart/fin/Filtering_max_z_dist_open_patch_diff.png', width = 5000, height = 5000, units = "px", pointsize = 10, bg = "white", res = 96, type = c("cairo"))
zcol <- level.colors(I(skgrMergeF1$max_alt_open_patch-skgrMergeF1$max_z_dist_open_patch), at = c(90, 95, 97.5, 100, 102.5, 105, 200, 3000), col.regions=colorRampPalette(c("yellow", "green", "cyan", "blue", "purple", "magenta", "red")))
xyplot(Y ~ X | "Filtering_max_z_dist_open_patch", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
dev.off()

png('/home/stefan/Okokart/fin/Filtering_max_z_dist_open_patch.png', width = 5000, height = 5000, units = "px", pointsize = 10, bg = "white", res = 96, type = c("cairo"))
zcol <- level.colors(skgrMergeF1$max_z_dist_open_patch, at = c(0, 100, 125, 150, 200, 250, 300, 2000), col.regions=colorRampPalette(c("yellow", "green", "cyan", "blue", "purple", "magenta", "red")))
xyplot(Y ~ X | "Filtering_max_z_dist_open_patch", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
dev.off()

##############################################################
#Filter max_alt_open_patch - max_z_dist_open_patch
skgrMergeF1 <- skgrMergeF1[I(skgrMergeF1$max_alt_open_patch-skgrMergeF1$max_z_dist_open_patch)>=95,]
points_n["I(skgrMergeF1$max_alt_open_patch-skgrMergeF1$max_z_dist_open_patch)>95"] <- length(skgrMergeF1$hoh)
png('/home/stefan/Okokart/fin/Filtering_reference_altitude_F1_S05.png', width = 1000, height = 1000, units = "px", pointsize = 24, bg = "white", res = 96, type = c("cairo"))
zcol <- level.colors(skgrMergeF1$hoh, at = c(0, 50, 100, 150, 200, 250, 300, 350, 400, 450, 500, 550, 600, 650, 700, 750, 800, 850, 900, 950, 1000, 1050, 1100, 1150, 1200, 1250, 1300), col.regions=terrain.colors(27), interpolate=c("linear"))
xyplot(Y ~ X | "Altitude of reference points in filter 5", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
dev.off()

skgrMergeF1 <- skgrMergeF1[skgrMergeF1$max_z_dist_open_patch>100,]
points_n["skgrMergeF1$max_z_dist_open_patch>100"] <- length(skgrMergeF1$hoh)
png('/home/stefan/Okokart/fin/Filtering_reference_altitude_F1_S05.png', width = 1000, height = 1000, units = "px", pointsize = 24, bg = "white", res = 96, type = c("cairo"))
zcol <- level.colors(skgrMergeF1$hoh, at = c(0, 50, 100, 150, 200, 250, 300, 350, 400, 450, 500, 550, 600, 650, 700, 750, 800, 850, 900, 950, 1000, 1050, 1100, 1150, 1200, 1250, 1300), col.regions=terrain.colors(27), interpolate=c("linear"))
xyplot(Y ~ X | "Altitude of reference points in filter 5", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
dev.off()

png('/home/stefan/Okokart/fin/Filtering_point_density_F1_S05.png', width = 1000, height = 1000, units = "px", pointsize = 24, bg = "white", res = 96, type = c("cairo"))
hexbinplot(Y ~ X | "Point density after filter 5", skgrMergeF1, aspect = 1, .aspect.ratio = 1, xbins=120, draw=TRUE, colorkey=TRUE)
dev.off()

##############################################################
#Identify suitable filter settings for slope_next, slope_3 and slope_5
png('/home/stefan/Okokart/fin/Filtering_slope_next.png', width = 1000, height = 1000, units = "px", pointsize = 10, bg = "white", res = 96, type = c("cairo"))
zcol <- level.colors(skgrMergeF1$slope_next, at = c(-10000, 0, 15, 130), col.regions=colorRampPalette(c("green", "blue", "purple", "red")))
xyplot(Y ~ X | "Filtering_slope_next", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
dev.off()

png('/home/stefan/Okokart/fin/Filtering_slope_3.png', width = 1000, height = 1000, units = "px", pointsize = 10, bg = "white", res = 96, type = c("cairo"))
zcol <- level.colors(skgrMergeF1$slope_3, at = c(-10000, 0, 15, 30, 40, 45, 50, 130), col.regions=colorRampPalette(c("yellow", "green", "cyan", "blue", "purple", "magenta", "red")))
xyplot(Y ~ X | "Filtering_slope_3", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
dev.off()

png('/home/stefan/Okokart/fin/Filtering_slope_5.png', width = 1000, height = 1000, units = "px", pointsize = 10, bg = "white", res = 96, type = c("cairo"))
zcol <- level.colors(skgrMergeF1$slope_5, at = c(-10000, 0, 15, 30, 40, 45, 50, 130), col.regions=colorRampPalette(c("yellow", "green", "cyan", "blue", "purple", "magenta", "red")))
xyplot(Y ~ X | "Filtering_slope_5", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
dev.off()

##############################################################
#Filter slope_next
skgrMergeF1 <- skgrMergeF1[skgrMergeF1$slope_next>0&skgrMergeF1$slope_next<15,]
points_n["skgrMergeF1$slope_next>0&skgrMergeF1$slope_next<15"] <- length(skgrMergeF1$hoh)
png('/home/stefan/Okokart/fin/Filtering_reference_altitude_F1_S06a.png', width = 1000, height = 1000, units = "px", pointsize = 24, bg = "white", res = 96, type = c("cairo"))
zcol <- level.colors(skgrMergeF1$hoh, at = c(0, 50, 100, 150, 200, 250, 300, 350, 400, 450, 500, 550, 600, 650, 700, 750, 800, 850, 900, 950, 1000, 1050, 1100, 1150, 1200, 1250, 1300), col.regions=terrain.colors(27), interpolate=c("linear"))
xyplot(Y ~ X | "Altitude of reference points in filter 6a", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
dev.off()
skgrMergeF1 <- skgrMergeF1[skgrMergeF1$slope_3>0&skgrMergeF1$slope_3<40,]
points_n["skgrMergeF1$slope_3>0&skgrMergeF1$slope_3<40"] <- length(skgrMergeF1$hoh)
png('/home/stefan/Okokart/fin/Filtering_reference_altitude_F1_S06b.png', width = 1000, height = 1000, units = "px", pointsize = 24, bg = "white", res = 96, type = c("cairo"))
zcol <- level.colors(skgrMergeF1$hoh, at = c(0, 50, 100, 150, 200, 250, 300, 350, 400, 450, 500, 550, 600, 650, 700, 750, 800, 850, 900, 950, 1000, 1050, 1100, 1150, 1200, 1250, 1300), col.regions=terrain.colors(27), interpolate=c("linear"))
xyplot(Y ~ X | "Altitude of reference points in filter 6b", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
dev.off()
skgrMergeF1 <- skgrMergeF1[skgrMergeF1$slope_5>0&skgrMergeF1$slope_5<40,]
points_n["skgrMergeF1$slope_5>0&skgrMergeF1$slope_5<40"] <- length(skgrMergeF1$hoh)
png('/home/stefan/Okokart/fin/Filtering_reference_altitude_F1_S06c.png', width = 1000, height = 1000, units = "px", pointsize = 24, bg = "white", res = 96, type = c("cairo"))
zcol <- level.colors(skgrMergeF1$hoh, at = c(0, 50, 100, 150, 200, 250, 300, 350, 400, 450, 500, 550, 600, 650, 700, 750, 800, 850, 900, 950, 1000, 1050, 1100, 1150, 1200, 1250, 1300), col.regions=terrain.colors(27), interpolate=c("linear"))
xyplot(Y ~ X | "Altitude of reference points in filter 6c", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
dev.off()

png('/home/stefan/Okokart/fin/Filtering_point_density_F1_S06.png', width = 1000, height = 1000, units = "px", pointsize = 24, bg = "white", res = 96, type = c("cairo"))
hexbinplot(Y ~ X | "Point density after filter 6", skgrMergeF1, aspect = 1, .aspect.ratio = 1, xbins=120, draw=TRUE, colorkey=TRUE)
dev.off()

##############################################################
#Identify suitable filter settings for tetraterm_total_kor
png('/home/stefan/Okokart/fin/Filtering_tetraterm_total_kor.png', width = 5000, height = 5000, units = "px", pointsize = 10, bg = "white", res = 96, type = c("cairo"))
zcol <- level.colors(skgrMergeF1$tetraterm_total_kor, at = c(-10000, 2770, 2771, 2772, 2773, 2774, 2775, 9999), col.regions=colorRampPalette(c("yellow", "green", "cyan", "blue", "purple", "magenta", "red")))
xyplot(Y ~ X | "Filteringtetraterm_total_kor", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
dev.off()

##############################################################
#Filter tetraterm_total_kor
skgrMergeF1 <- skgrMergeF1[skgrMergeF1$tetraterm_total_kor<=2773,]
points_n["skgrMergeF1$tetraterm_total_kor<2773"] <- length(skgrMergeF1$hoh)
png('/home/stefan/Okokart/fin/Filtering_reference_altitude_F1_S07.png', width = 1000, height = 1000, units = "px", pointsize = 24, bg = "white", res = 96, type = c("cairo"))
zcol <- level.colors(skgrMergeF1$hoh, at = c(0, 50, 100, 150, 200, 250, 300, 350, 400, 450, 500, 550, 600, 650, 700, 750, 800, 850, 900, 950, 1000, 1050, 1100, 1150, 1200, 1250, 1300), col.regions=terrain.colors(27), interpolate=c("linear"))
xyplot(Y ~ X | "Altitude of reference points in filter 7", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
dev.off()

png('/home/stefan/Okokart/fin/Filtering_point_density_F1_S07.png', width = 1000, height = 1000, units = "px", pointsize = 24, bg = "white", res = 96, type = c("cairo"))
hexbinplot(Y ~ X | "Point density after filter 7", skgrMergeF1, aspect = 1, .aspect.ratio = 1, xbins=120, draw=TRUE, colorkey=TRUE)
dev.off()

##############################################################
#Identify suitable filter settings for 50200m scale
png('/home/stefan/Okokart/fin/Filtering_max_forest_50200m.png', width = 5000, height = 5000, units = "px", pointsize = 24, bg = "white", res = 10, type = c("cairo"))
zcol <- level.colors(skgrMergeF1$max_forest_50200m_gid_patch, at = c(0, 250, 275, 300, 325, 350, 375, 500), col.regions=colorRampPalette(c("yellow", "green", "cyan", "blue", "purple", "magenta", "red")))zcol <- level.colors(skgrMergeF1$max_forest_50200m, at = c(0, 300, 350, 400, 475, 850), col.regions=colorRampPalette(c("yellow", "green", "cyan", "blue", "purple", "magenta", "red")))
xyplot(Y ~ X | "Filtering_max_forest_50200m", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
dev.off()

png('/home/stefan/Okokart/fin/Filtering_max_forest_50200m_tvn_0p5_0p1_2.png', width = 5000, height = 5000, units = "px", pointsize = 10, bg = "white", res = 96, type = c("cairo"))
zcol <- level.colors(I(skgrMergeF1$max_forest_50200m/((ifelse(skgrMergeF1$tvn>0.5,0.5,skgrMergeF1$tvn)*1.9+0.1))), at = c(0, 500, 750, 1000, 2000, 3000, 5000), col.regions=colorRampPalette(c("yellow", "green", "cyan", "blue", "purple", "magenta", "red")))
xyplot(Y ~ X | "Filtering_max_forest_patch_50200m_tvn_0p5_0p1_2", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
dev.off()

png('/home/stefan/Okokart/fin/Filtering_max_forest_gid_patch_50200m.png', width = 5000, height = 5000, units = "px", pointsize = 10, bg = "white", res = 96, type = c("cairo"))
zcol <- level.colors(skgrMergeF1$max_forest_50200m_gid_patch, at = c(0, 350, 375, 400, 425, 450, 475, 500), col.regions=colorRampPalette(c("yellow", "green", "cyan", "blue", "purple", "magenta", "red")))
xyplot(Y ~ X | "Filtering_max_forest_gid_patch_50200m", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
dev.off()

png('/home/stefan/Okokart/fin/Filtering_max_forest_gid_patch_50200m_max_0p5_0p1_2.png', width = 5000, height = 5000, units = "px", pointsize = 24, bg = "white", res = 10, type = c("cairo"))
zcol <- level.colors(I(skgrMergeF1$max_forest_50200m_gid_patch/((ifelse(skgrMergeF1$tvn_gid_patch>0.5,0.5,skgrMergeF1$tvn_gid_patch)*1.9+0.1))), at = c(0, 500, 525, 750, 800, 900, 1000, 10000), col.regions=colorRampPalette(c("yellow", "green", "cyan", "blue", "purple", "magenta", "red")))
xyplot(Y ~ X | "Filtering_max_forest_gid_patch_50200m", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
dev.off()

##############################################################
#Filter 50200m  (Start varying filterstrength at this scale)
skgrMergeF1 <- skgrMergeF1[skgrMergeF1$max_forest_50200m<300,]
points_n["max_forest_50200m<300"] <- length(skgrMergeF1$hoh)
png('/home/stefan/Okokart/fin/Filtering_reference_altitude_F1_S08a.png', width = 1000, height = 1000, units = "px", pointsize = 24, bg = "white", res = 96, type = c("cairo"))
zcol <- level.colors(skgrMergeF1$hoh, at = c(0, 50, 100, 150, 200, 250, 300, 350, 400, 450, 500, 550, 600, 650, 700, 750, 800, 850, 900, 950, 1000, 1050, 1100, 1150, 1200, 1250, 1300), col.regions=terrain.colors(27), interpolate=c("linear"))
xyplot(Y ~ X | "Altitude of reference points in filter 8a", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
dev.off()

skgrMergeF1 <- skgrMergeF1[skgrMergeF1$max_forest_50200m_gid_patch<250,]
points_n["max_forest_50200m_gid_patch<250"] <- length(skgrMergeF1$hoh)
png('/home/stefan/Okokart/fin/Filtering_reference_altitude_F1_S08b.png', width = 1000, height = 1000, units = "px", pointsize = 24, bg = "white", res = 96, type = c("cairo"))
zcol <- level.colors(skgrMergeF1$hoh, at = c(0, 50, 100, 150, 200, 250, 300, 350, 400, 450, 500, 550, 600, 650, 700, 750, 800, 850, 900, 950, 1000, 1050, 1100, 1150, 1200, 1250, 1300), col.regions=terrain.colors(27), interpolate=c("linear"))
xyplot(Y ~ X | "Altitude of reference points in filter 8b", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
dev.off()

skgrMergeF1 <- skgrMergeF1[I(skgrMergeF1$max_forest_50200m/((ifelse(skgrMergeF1$tvn>0.5,0.5,skgrMergeF1$tvn)*1.9+0.1)))<=750,]
points_n["max_forest_50200m_tvn_0p5_0p1_2<=750"] <- length(skgrMergeF1$hoh)
png('/home/stefan/Okokart/fin/Filtering_reference_altitude_F1_S08c.png', width = 1000, height = 1000, units = "px", pointsize = 24, bg = "white", res = 96, type = c("cairo"))
zcol <- level.colors(skgrMergeF1$hoh, at = c(0, 50, 100, 150, 200, 250, 300, 350, 400, 450, 500, 550, 600, 650, 700, 750, 800, 850, 900, 950, 1000, 1050, 1100, 1150, 1200, 1250, 1300), col.regions=terrain.colors(27), interpolate=c("linear"))
xyplot(Y ~ X | "Altitude of reference points in filter 8c", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
dev.off()

skgrMergeF1 <- skgrMergeF1[I(skgrMergeF1$max_forest_50200m_gid_patch/((ifelse(skgrMergeF1$tvn_gid_patch>0.5,0.5,skgrMergeF1$tvn_gid_patch)*1.9+0.1)))<400,]
points_n["max_forest_50200m_gid_patch_tvn_max_0p5_0p1_2<=400"] <- length(skgrMergeF1$hoh)
png('/home/stefan/Okokart/fin/Filtering_reference_altitude_F1_S08d.png', width = 1000, height = 1000, units = "px", pointsize = 24, bg = "white", res = 96, type = c("cairo"))
zcol <- level.colors(skgrMergeF1$hoh, at = c(0, 50, 100, 150, 200, 250, 300, 350, 400, 450, 500, 550, 600, 650, 700, 750, 800, 850, 900, 950, 1000, 1050, 1100, 1150, 1200, 1250, 1300), col.regions=terrain.colors(27), interpolate=c("linear"))
xyplot(Y ~ X | "Altitude of reference points in filter 7d", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
dev.off()

png('/home/stefan/Okokart/fin/Filtering_point_density_F1_S08.png', width = 1000, height = 1000, units = "px", pointsize = 24, bg = "white", res = 96, type = c("cairo"))
hexbinplot(Y ~ X | "Point density after filter 8", skgrMergeF1, aspect = 1, .aspect.ratio = 1, xbins=120, draw=TRUE, colorkey=TRUE)
dev.off()

##############################################################
#Identify suitable filter settings for 25000m scale
png('/home/stefan/Okokart/fin/Filtering_max_forest_25000m.png', width = 5000, height = 5000, units = "px", pointsize = 24, bg = "white", res = 10, type = c("cairo"))
zcol <- level.colors(skgrMergeF1$max_forest_25000m, at = c(0, 250, 275, 300, 325, 350, 1000), col.regions=colorRampPalette(c("yellow", "green", "cyan", "blue", "purple", "magenta", "red")))
xyplot(Y ~ X | "Filtering_max_forest_25000m", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
dev.off()

png('/home/stefan/Okokart/fin/Filtering_max_forest_25000m_tvn_0p5_0p1_2.png', width = 5000, height = 5000, units = "px", pointsize = 10, bg = "white", res = 96, type = c("cairo"))
zcol <- level.colors(I(skgrMergeF1$max_forest_25000m/((ifelse(skgrMergeF1$tvn>0.5,0.5,skgrMergeF1$tvn)*1.9+0.1))), at = c(0, 700, 750, 800, 850, 900, 950, 1000, 1400), col.regions=colorRampPalette(c("yellow", "green", "cyan", "blue", "purple", "magenta", "red")))
xyplot(Y ~ X | "Filtering_max_forest_patch_25000m_tvn_0p5_0p1_2", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
dev.off()

png('/home/stefan/Okokart/fin/Filtering_max_forest_gid_patch_25000m.png', width = 5000, height = 5000, units = "px", pointsize = 10, bg = "white", res = 96, type = c("cairo"))
zcol <- level.colors(skgrMergeF1$max_forest_25000m_gid_patch, at = c(0, 200, 225, 250, 275, 300, 500), col.regions=colorRampPalette(c("yellow", "green", "cyan", "blue", "purple", "magenta", "red")))
xyplot(Y ~ X | "Filtering_max_forest_gid_patch_25000m", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
dev.off()

png('/home/stefan/Okokart/fin/Filtering_max_forest_gid_patch_25000m_0p5_0p1_2.png', width = 5000, height = 5000, units = "px", pointsize = 24, bg = "white", res = 96, type = c("cairo"))
zcol <- level.colors(I(skgrMergeF1$max_forest_25000m_gid_patch/((ifelse(skgrMergeF1$tvn_gid_patch>0.5,0.5,skgrMergeF1$tvn_gid_patch)*1.9+0.1))), at = c(0, 300, 325, 350, 375, 400, 550, 600, 900, 1100), col.regions=colorRampPalette(c("yellow", "green", "cyan", "blue", "purple", "magenta", "red")))
xyplot(Y ~ X | "Filtering_max_forest_gid_patch_25000m", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
dev.off()

##############################################################
#Filter 25000m
skgrMergeF1 <- skgrMergeF1[skgrMergeF1$max_forest_25000m<=250,]
points_n["max_forest_25000m<300"] <- length(skgrMergeF1$hoh)
png('/home/stefan/Okokart/fin/Filtering_reference_altitude_F1_S09a.png', width = 1000, height = 1000, units = "px", pointsize = 24, bg = "white", res = 96, type = c("cairo"))
zcol <- level.colors(skgrMergeF1$hoh, at = c(0, 50, 100, 150, 200, 250, 300, 350, 400, 450, 500, 550, 600, 650, 700, 750, 800, 850, 900, 950, 1000, 1050, 1100, 1150, 1200, 1250, 1300), col.regions=terrain.colors(27), interpolate=c("linear"))
xyplot(Y ~ X | "Altitude of reference points in filter 9a", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
dev.off()

skgrMergeF1 <- skgrMergeF1[skgrMergeF1$max_forest_25000m_gid_patch<=200,]
points_n["max_forest_25000m_gid_patch<200"] <- length(skgrMergeF1$hoh)
png('/home/stefan/Okokart/fin/Filtering_reference_altitude_F1_S09b.png', width = 1000, height = 1000, units = "px", pointsize = 24, bg = "white", res = 96, type = c("cairo"))
zcol <- level.colors(skgrMergeF1$hoh, at = c(0, 50, 100, 150, 200, 250, 300, 350, 400, 450, 500, 550, 600, 650, 700, 750, 800, 850, 900, 950, 1000, 1050, 1100, 1150, 1200, 1250, 1300), col.regions=terrain.colors(27), interpolate=c("linear"))
xyplot(Y ~ X | "Altitude of reference points in filter 8b", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
dev.off()

skgrMergeF1 <- skgrMergeF1[I(skgrMergeF1$max_forest_25000m/((ifelse(skgrMergeF1$tvn>0.5,0.5,skgrMergeF1$tvn)*1.9+0.1)))<=700,]
points_n["max_forest_25000m_tvn_0p5_0p1_2<500"] <- length(skgrMergeF1$hoh)
png('/home/stefan/Okokart/fin/Filtering_reference_altitude_F1_S09c.png', width = 1000, height = 1000, units = "px", pointsize = 24, bg = "white", res = 96, type = c("cairo"))
zcol <- level.colors(skgrMergeF1$hoh, at = c(0, 50, 100, 150, 200, 250, 300, 350, 400, 450, 500, 550, 600, 650, 700, 750, 800, 850, 900, 950, 1000, 1050, 1100, 1150, 1200, 1250, 1300), col.regions=terrain.colors(27), interpolate=c("linear"))
xyplot(Y ~ X | "Altitude of reference points in filter 9c", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
dev.off()

skgrMergeF1 <- skgrMergeF1[I(skgrMergeF1$max_forest_25000m_gid_patch/((ifelse(skgrMergeF1$tvn_gid_patch>0.5,0.5,skgrMergeF1$tvn_gid_patch)*1.9+0.1)))<=300,]
points_n["max_forest_25000m_gid_patch_tvn_0p5_0p1_2<=500"] <- length(skgrMergeF1$hoh)
png('/home/stefan/Okokart/fin/Filtering_reference_altitude_F1_S09d.png', width = 1000, height = 1000, units = "px", pointsize = 24, bg = "white", res = 96, type = c("cairo"))
zcol <- level.colors(skgrMergeF1$hoh, at = c(0, 50, 100, 150, 200, 250, 300, 350, 400, 450, 500, 550, 600, 650, 700, 750, 800, 850, 900, 950, 1000, 1050, 1100, 1150, 1200, 1250, 1300), col.regions=terrain.colors(27), interpolate=c("linear"))
xyplot(Y ~ X | "Altitude of reference points in filter 9d", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
dev.off()

png('/home/stefan/Okokart/fin/Filtering_point_density_F1_S09.png', width = 1000, height = 1000, units = "px", pointsize = 24, bg = "white", res = 96, type = c("cairo"))
hexbinplot(Y ~ X | "Point density after filter 9", skgrMergeF1, aspect = 1, .aspect.ratio = 1, xbins=120, draw=TRUE, colorkey=TRUE)
dev.off()

##############################################################
#Identify suitable filter settings for 10100m scale
png('/home/stefan/Okokart/fin/Filtering_max_forest_10100m.png', width = 5000, height = 5000, units = "px", pointsize = 10, bg = "white", res = 96, type = c("cairo"))
zcol <- level.colors(skgrMergeF1$max_forest_10100m, at = c(0, 200, 212.5, 225, 237.5, 250, 267.5, 275, 1000), col.regions=colorRampPalette(c("yellow", "green", "cyan", "blue", "purple", "magenta", "red")))
xyplot(Y ~ X | "Filtering_max_forest_10100m", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
dev.off()

png('/home/stefan/Okokart/fin/Filtering_max_forest_10100m_tvn_0p5_0p1_2.png', width = 5000, height = 5000, units = "px", pointsize = 10, bg = "white", res = 96, type = c("cairo"))
zcol <- level.colors(I(skgrMergeF1$max_forest_10100m/((ifelse(skgrMergeF1$tvn>0.5,0.5,skgrMergeF1$tvn)*1.9+0.1))), at = c(0, 250, 275, 300, 350, 400, 500, 1250), col.regions=colorRampPalette(c("yellow", "green", "cyan", "blue", "purple", "magenta", "red")))
xyplot(Y ~ X | "Filtering_max_forest_patch_10100m_tvn_0p5_0p1_2", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
dev.off()

png('/home/stefan/Okokart/fin/Filtering_max_forest_gid_patch_10100m.png', width = 5000, height = 5000, units = "px", pointsize = 10, bg = "white", res = 96, type = c("cairo"))
zcol <- level.colors(skgrMergeF1$max_forest_10100m_gid_patch, at = c(0, 40, 45, 50, 55, 60, 75, 100, 500), col.regions=colorRampPalette(c("yellow", "green", "cyan", "blue", "purple", "magenta", "red")))
xyplot(Y ~ X | "Filtering_max_forest_gid_patch_10100m", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
dev.off()

png('/home/stefan/Okokart/fin/Filtering_max_forest_gid_patch_10100m_0p5_0p1_2.png', width = 5000, height = 5000, units = "px", pointsize = 24, bg = "white", res = 10, type = c("cairo"))
zcol <- level.colors(I(skgrMergeF1$max_forest_10100m_gid_patch/((ifelse(skgrMergeF1$tvn_gid_patch>0.5,0.5,skgrMergeF1$tvn_gid_patch)*1.9+0.1))), at = c(0, 100, 125, 150, 175, 200, 1100), col.regions=colorRampPalette(c("yellow", "green", "cyan", "blue", "purple", "magenta", "red")))
xyplot(Y ~ X | "Filtering_max_forest_gid_patch_10100m", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
dev.off()

##############################################################
#Filter 10100m
skgrMergeF1 <- skgrMergeF1[skgrMergeF1$max_forest_10100m<175,]
points_n["max_forest_10100m<225"] <- length(skgrMergeF1$hoh)
png('/home/stefan/Okokart/fin/Filtering_reference_altitude_F1_S10a.png', width = 1000, height = 1000, units = "px", pointsize = 24, bg = "white", res = 96, type = c("cairo"))
zcol <- level.colors(skgrMergeF1$hoh, at = c(0, 50, 100, 150, 200, 250, 300, 350, 400, 450, 500, 550, 600, 650, 700, 750, 800, 850, 900, 950, 1000, 1050, 1100, 1150, 1200, 1250, 1300), col.regions=terrain.colors(27), interpolate=c("linear"))
xyplot(Y ~ X | "Altitude of reference points in filter 10a", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
dev.off()

skgrMergeF1 <- skgrMergeF1[skgrMergeF1$max_forest_10100m_gid_patch<=100,]
points_n["max_forest_10100m_patch<100"] <- length(skgrMergeF1$hoh)
png('/home/stefan/Okokart/fin/Filtering_reference_altitude_F1_S10b.png', width = 1000, height = 1000, units = "px", pointsize = 24, bg = "white", res = 96, type = c("cairo"))
zcol <- level.colors(skgrMergeF1$hoh, at = c(0, 50, 100, 150, 200, 250, 300, 350, 400, 450, 500, 550, 600, 650, 700, 750, 800, 850, 900, 950, 1000, 1050, 1100, 1150, 1200, 1250, 1300), col.regions=terrain.colors(27), interpolate=c("linear"))
xyplot(Y ~ X | "Altitude of reference points in filter 10b", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
dev.off()

skgrMergeF1 <- skgrMergeF1[I(skgrMergeF1$max_forest_10100m/((ifelse(skgrMergeF1$tvn>0.5,0.5,skgrMergeF1$tvn)*1.9+0.1)))<=500,]
points_n["max_forest_10100m_tvn_0p5_0p1_2<500"] <- length(skgrMergeF1$hoh)
png('/home/stefan/Okokart/fin/Filtering_reference_altitude_F1_S10c.png', width = 1000, height = 1000, units = "px", pointsize = 24, bg = "white", res = 96, type = c("cairo"))
zcol <- level.colors(skgrMergeF1$hoh, at = c(0, 50, 100, 150, 200, 250, 300, 350, 400, 450, 500, 550, 600, 650, 700, 750, 800, 850, 900, 950, 1000, 1050, 1100, 1150, 1200, 1250, 1300), col.regions=terrain.colors(27), interpolate=c("linear"))
xyplot(Y ~ X | "Altitude of reference points in filter 10c", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
dev.off()

skgrMergeF1 <- skgrMergeF1[I(skgrMergeF1$max_forest_10100m_gid_patch/((ifelse(skgrMergeF1$tvn_gid_patch>0.5,0.5,skgrMergeF1$tvn_gid_patch)*1.9+0.1)))<=100,]
points_n["max_forest_10100m_patch_tvn_0p5_0p1_2<=100"] <- length(skgrMergeF1$hoh)
png('/home/stefan/Okokart/fin/Filtering_reference_altitude_F1_S10d.png', width = 1000, height = 1000, units = "px", pointsize = 24, bg = "white", res = 96, type = c("cairo"))
zcol <- level.colors(skgrMergeF1$hoh, at = c(0, 50, 100, 150, 200, 250, 300, 350, 400, 450, 500, 550, 600, 650, 700, 750, 800, 850, 900, 950, 1000, 1050, 1100, 1150, 1200, 1250, 1300), col.regions=terrain.colors(27), interpolate=c("linear"))
xyplot(Y ~ X | "Altitude of reference points in filter 10d", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
dev.off()

png('/home/stefan/Okokart/fin/Filtering_point_density_F1_S10.png', width = 1000, height = 1000, units = "px", pointsize = 24, bg = "white", res = 96, type = c("cairo"))
hexbinplot(Y ~ X | "Point density after filter 10", skgrMergeF1, aspect = 1, .aspect.ratio = 1, xbins=120, draw=TRUE, colorkey=TRUE)
dev.off()

##############################################################
#Identify suitable filter settings for 5050m scale
png('/home/stefan/Okokart/fin/Filtering_max_forest_5050m.png', width = 5000, height = 5000, units = "px", pointsize = 24, bg = "white", res = 10, type = c("cairo"))
zcol <- level.colors(skgrMergeF1$max_forest_5050m, at = c(0, 150, 162.5, 175, 187.5, 200, 225, 1000), col.regions=colorRampPalette(c("yellow", "green", "cyan", "blue", "purple", "magenta", "red")))
xyplot(Y ~ X | "Filtering_max_forest_5050m", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
dev.off()

png('/home/stefan/Okokart/fin/Filtering_max_forest_5050m_tvn_0p5_0p1_2.png', width = 5000, height = 5000, units = "px", pointsize = 24, bg = "white", res = 10, type = c("cairo"))
zcol <- level.colors(I(skgrMergeF1$max_forest_5050m/((ifelse(skgrMergeF1$tvn>0.5,0.5,skgrMergeF1$tvn)*1.9+0.1))), at = c(0, 250, 275, 300, 350, 400, 500, 1250), col.regions=colorRampPalette(c("yellow", "green", "cyan", "blue", "purple", "magenta", "red")))
xyplot(Y ~ X | "Filtering_max_forest_patch_5050m_tvn_0p5_0p1_2", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
dev.off()

png('/home/stefan/Okokart/fin/Filtering_max_forest_gid_patch_5050m.png', width = 5000, height = 5000, units = "px", pointsize = 24, bg = "white", res = 10, type = c("cairo"))
zcol <- level.colors(skgrMergeF1$max_forest_5050m_gid_patch, at = c(0, 25, 37.5, 50, 62.5, 75, 100, 150, 500), col.regions=colorRampPalette(c("yellow", "green", "cyan", "blue", "purple", "magenta", "red")))
xyplot(Y ~ X | "Filtering_max_forest_gid_patch_5050m", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
dev.off()

png('/home/stefan/Okokart/fin/Filtering_max_forest_gid_patch_5050m_0p5_0p1_2.png', width = 5000, height = 5000, units = "px", pointsize = 24, bg = "white", res = 10, type = c("cairo"))
zcol <- level.colors(I(skgrMergeF1$max_forest_5050m_gid_patch/((ifelse(skgrMergeF1$tvn_gid_patch>0.5,0.5,skgrMergeF1$tvn_gid_patch)*1.9+0.1))), at = c(0, 20, 25, 30, 40, 50, 75, 100, 1100), col.regions=colorRampPalette(c("yellow", "green", "cyan", "blue", "purple", "magenta", "red")))
xyplot(Y ~ X | "Filtering_max_forest_gid_patch_5050m", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
dev.off()

##############################################################
#Filter 5050m
skgrMergeF1 <- skgrMergeF1[skgrMergeF1$max_forest_5050m<150,]
points_n["max_forest_5050m<150"] <- length(skgrMergeF1$hoh)
png('/home/stefan/Okokart/fin/Filtering_reference_altitude_F1_S11a.png', width = 1000, height = 1000, units = "px", pointsize = 24, bg = "white", res = 96, type = c("cairo"))
zcol <- level.colors(skgrMergeF1$hoh, at = c(0, 50, 100, 150, 200, 250, 300, 350, 400, 450, 500, 550, 600, 650, 700, 750, 800, 850, 900, 950, 1000, 1050, 1100, 1150, 1200, 1250, 1300), col.regions=terrain.colors(27), interpolate=c("linear"))
xyplot(Y ~ X | "Altitude of reference points in filter 11a", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
dev.off()

skgrMergeF1 <- skgrMergeF1[skgrMergeF1$max_forest_5050m_gid_patch<=25,]
points_n["max_forest_5050m_gid_patch<25"] <- length(skgrMergeF1$hoh)
png('/home/stefan/Okokart/fin/Filtering_reference_altitude_F1_S11b.png', width = 1000, height = 1000, units = "px", pointsize = 24, bg = "white", res = 96, type = c("cairo"))
zcol <- level.colors(skgrMergeF1$hoh, at = c(0, 50, 100, 150, 200, 250, 300, 350, 400, 450, 500, 550, 600, 650, 700, 750, 800, 850, 900, 950, 1000, 1050, 1100, 1150, 1200, 1250, 1300), col.regions=terrain.colors(27), interpolate=c("linear"))
xyplot(Y ~ X | "Altitude of reference points in filter 11b", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
dev.off()

skgrMergeF1 <- skgrMergeF1[I(skgrMergeF1$max_forest_5050m/((ifelse(skgrMergeF1$tvn>0.5,0.5,skgrMergeF1$tvn)*1.9+0.1)))<=250,]
points_n["max_forest_5050m_tvn_0p5_0p1_2<250"] <- length(skgrMergeF1$hoh)
png('/home/stefan/Okokart/fin/Filtering_reference_altitude_F1_S11c.png', width = 1000, height = 1000, units = "px", pointsize = 24, bg = "white", res = 96, type = c("cairo"))
zcol <- level.colors(skgrMergeF1$hoh, at = c(0, 50, 100, 150, 200, 250, 300, 350, 400, 450, 500, 550, 600, 650, 700, 750, 800, 850, 900, 950, 1000, 1050, 1100, 1150, 1200, 1250, 1300), col.regions=terrain.colors(27), interpolate=c("linear"))
xyplot(Y ~ X | "Altitude of reference points in filter 11c", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
dev.off()

skgrMergeF1 <- skgrMergeF1[I(skgrMergeF1$max_forest_5050m_gid_patch/((ifelse(skgrMergeF1$tvn_gid_patch>0.5,0.5,skgrMergeF1$tvn_gid_patch)*1.9+0.1)))<=20,]
points_n["max_forest_5050m_gid_patch_tvn_0p5_0p1_2<=20"] <- length(skgrMergeF1$hoh)
png('/home/stefan/Okokart/fin/Filtering_reference_altitude_F1_S11d.png', width = 1000, height = 1000, units = "px", pointsize = 24, bg = "white", res = 96, type = c("cairo"))
zcol <- level.colors(skgrMergeF1$hoh, at = c(0, 50, 100, 150, 200, 250, 300, 350, 400, 450, 500, 550, 600, 650, 700, 750, 800, 850, 900, 950, 1000, 1050, 1100, 1150, 1200, 1250, 1300), col.regions=terrain.colors(27), interpolate=c("linear"))
xyplot(Y ~ X | "Altitude of reference points in filter 11d", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
dev.off()

png('/home/stefan/Okokart/fin/Filtering_point_density_F1_S11.png', width = 1000, height = 1000, units = "px", pointsize = 24, bg = "white", res = 96, type = c("cairo"))
hexbinplot(Y ~ X | "Point density after filter 11", skgrMergeF1, aspect = 1, .aspect.ratio = 1, xbins=120, draw=TRUE, colorkey=TRUE)
dev.off()

##############################################################
#Identify suitable filter settings for max_forest_sum (across scales)
png('/home/stefan/Okokart/fin/Filtering_max_forest_sum.png', width = 5000, height = 5000, units = "px", pointsize = 10, bg = "white", res = 96, type = c("cairo"))
zcol <- level.colors(skgrMergeF1$max_forest_sum, at = c(0, 700, 750, 800, 850, 900, 950, 1000), col.regions=colorRampPalette(c("yellow", "green", "cyan", "blue", "purple", "magenta", "red")))
xyplot(Y ~ X | "Filtering_max_forest_sum", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
dev.off()

png('/home/stefan/Okokart/fin/Filtering_max_forest_sum_tvn_0p5_0p1_2.png', width = 5000, height = 5000, units = "px", pointsize = 24, bg = "white", res = 96, type = c("cairo"))
zcol <- level.colors(I(skgrMergeF1$max_forest_sum/((ifelse(skgrMergeF1$tvn>0.5,0.5,skgrMergeF1$tvn)*1.9+0.1))), at = c(0, 1000, 1250, 1500, 1600, 1700, 100000), col.regions=colorRampPalette(c("yellow", "green", "cyan", "blue", "purple", "magenta", "red")))
xyplot(Y ~ X | "Filtering_max_forest_patch_sum_tvn_0p5_0p1_2", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
dev.off()

png('/home/stefan/Okokart/fin/Filtering_max_forest_gid_patch_sum.png', width = 5000, height = 5000, units = "px", pointsize = 24, bg = "white", res = 10, type = c("cairo"))
zcol <- level.colors(skgrMergeF1$max_forest_sum_patch_gid, at = c(0, 300, 350, 400, 450, 500, 550, 615), col.regions=colorRampPalette(c("yellow", "green", "cyan", "blue", "purple", "magenta", "red")))
xyplot(Y ~ X | "Filtering_max_forest_gid_patch_sum", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
dev.off()

png('/home/stefan/Okokart/fin/Filtering_max_forest_gid_patch_sum_0p5_0p1_2.png', width = 5000, height = 5000, units = "px", pointsize = 24, bg = "white", res = 10, type = c("cairo"))
zcol <- level.colors(I(skgrMergeF1$max_forest_sum_patch_gid/((ifelse(skgrMergeF1$tvn_gid_patch>0.5,0.5,skgrMergeF1$tvn_gid_patch)*1.9+0.1))), at = c(0, 400, 500, 600, 700, 800, 900, 1000, 1100), col.regions=colorRampPalette(c("yellow", "green", "cyan", "blue", "purple", "magenta", "red")))
xyplot(Y ~ X | "Filtering_max_forest_gid_patch_sum", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
dev.off()

##############################################################
#Filter max_forest_sum
skgrMergeF1 <- skgrMergeF1[skgrMergeF1$max_forest_sum<750,]
points_n["max_forest_sum<750"] <- length(skgrMergeF1$hoh)
png('/home/stefan/Okokart/fin/Filtering_reference_altitude_F1_S12a.png', width = 1000, height = 1000, units = "px", pointsize = 24, bg = "white", res = 96, type = c("cairo"))
zcol <- level.colors(skgrMergeF1$hoh, at = c(0, 50, 100, 150, 200, 250, 300, 350, 400, 450, 500, 550, 600, 650, 700, 750, 800, 850, 900, 950, 1000, 1050, 1100, 1150, 1200, 1250, 1300), col.regions=terrain.colors(27), interpolate=c("linear"))
xyplot(Y ~ X | "Altitude of reference points in 12a", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
dev.off()

skgrMergeF1 <- skgrMergeF1[I(skgrMergeF1$max_forest_sum/((ifelse(skgrMergeF1$tvn>0.5,0.5,skgrMergeF1$tvn)*1.9+0.1)))<1600,]
points_n["I(skgrMergeF1$max_forest_sum/((ifelse(skgrMergeF1$tvn>0.5,0.5,skgrMergeF1$tvn)*1.9+0.1)))<1600"] <- length(skgrMergeF1$hoh)
png('/home/stefan/Okokart/fin/Filtering_reference_altitude_F1_S12b.png', width = 1000, height = 1000, units = "px", pointsize = 24, bg = "white", res = 96, type = c("cairo"))
zcol <- level.colors(skgrMergeF1$hoh, at = c(0, 50, 100, 150, 200, 250, 300, 350, 400, 450, 500, 550, 600, 650, 700, 750, 800, 850, 900, 950, 1000, 1050, 1100, 1150, 1200, 1250, 1300), col.regions=terrain.colors(27), interpolate=c("linear"))
xyplot(Y ~ X | "Altitude of reference points in filter 12b", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
dev.off()

skgrMergeF1 <- skgrMergeF1[skgrMergeF1$max_forest_sum_patch_gid<350,]
points_n["skgrMergeF1$max_forest_sum_patch_gid<350"] <- length(skgrMergeF1$hoh)
png('/home/stefan/Okokart/fin/Filtering_reference_altitude_F1_S12c.png', width = 1000, height = 1000, units = "px", pointsize = 24, bg = "white", res = 96, type = c("cairo"))
zcol <- level.colors(skgrMergeF1$hoh, at = c(0, 50, 100, 150, 200, 250, 300, 350, 400, 450, 500, 550, 600, 650, 700, 750, 800, 850, 900, 950, 1000, 1050, 1100, 1150, 1200, 1250, 1300), col.regions=terrain.colors(27), interpolate=c("linear"))
xyplot(Y ~ X | "Altitude of reference points in filter 12c", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
dev.off()

skgrMergeF1 <- skgrMergeF1[I(skgrMergeF1$max_forest_sum_patch_gid/((ifelse(skgrMergeF1$tvn_gid_patch>0.5,0.5,skgrMergeF1$tvn_gid_patch)*1.9+0.1)))<700,]
points_n["I(skgrMergeF1$max_forest_sum_patch_gid/((ifelse(skgrMergeF1$tvn_gid_patch>0.5,0.5,skgrMergeF1$tvn_gid_patch)*1.9+0.1)))<700"] <- length(skgrMergeF1$hoh)
png('/home/stefan/Okokart/fin/Filtering_reference_altitude_F1_S12d.png', width = 1000, height = 1000, units = "px", pointsize = 24, bg = "white", res = 96, type = c("cairo"))
zcol <- level.colors(skgrMergeF1$hoh, at = c(0, 50, 100, 150, 200, 250, 300, 350, 400, 450, 500, 550, 600, 650, 700, 750, 800, 850, 900, 950, 1000, 1050, 1100, 1150, 1200, 1250, 1300), col.regions=terrain.colors(27), interpolate=c("linear"))
xyplot(Y ~ X | "Altitude of reference points in filter 12d", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
dev.off()

png('/home/stefan/Okokart/fin/Filtering_point_density_F1_S12.png', width = 1000, height = 1000, units = "px", pointsize = 24, bg = "white", res = 96, type = c("cairo"))
hexbinplot(Y ~ X | "Point density after filter 12", skgrMergeF1, aspect = 1, .aspect.ratio = 1, xbins=120, draw=TRUE, colorkey=TRUE)
dev.off()

# #Continentality
# png('/home/stefan/Okokart/fin/Filtering_continentality.png', width = 1000, height = 1000, units = "px", pointsize = 24, bg = "white", res = 96, type = c("cairo"))
# zcol <- level.colors(skgrMergeF1$continentality, at = c(0, 1.133e+25, 1.332e+30, 2.332e+30, 4.332e+30, 6.332e+30, 1.332e+31, 5.145e+32), col.regions=colorRampPalette(c("yellow", "green", "cyan", "blue", "purple", "magenta", "red")))
# xyplot(Y ~ X | "Filtering_continentality", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
# dev.off()

# #Continentality
# png('/home/stefan/Okokart/fin/Filtering_coast_line_distance.png', width = 1000, height = 1000, units = "px", pointsize = 24, bg = "white", res = 96, type = c("cairo"))
# zcol <- level.colors(skgrMergeF1$coast_line_distance, at = c(0, 100, 250, 500, 750, 1000, 2500, 999999999), col.regions=colorRampPalette(c("red", "magenta", "purple", "blue", "cyan", "green", "yellow")))
# xyplot(Y ~ X | "Filtering_continentality", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
# dev.off()

##############################################################
#Identify suitable filter settings for amount_ocean
png('/home/stefan/Okokart/fin/Filtering_amount_ocean_5050m.png', width = 1000, height = 1000, units = "px", pointsize = 24, bg = "white", res = 96, type = c("cairo"))
zcol <- level.colors(skgrMergeF1$amount_ocean_5050m, at = c(0, 30000, 40000, 55000, 60000, 70000, 75000, 80000, 180000), col.regions=colorRampPalette(c("yellow", "green", "cyan", "blue", "purple", "magenta", "red")))
xyplot(Y ~ X | "Filtering_amount_ocean_5050m", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
dev.off()

png('/home/stefan/Okokart/fin/Filtering_amount_ocean_10100m.png', width = 1000, height = 1000, units = "px", pointsize = 24, bg = "white", res = 96, type = c("cairo"))
zcol <- level.colors(skgrMergeF1$amount_ocean_10100m, at = c(0, 17180, 25000, 50000, 100000, 250000, 500000, 716400), col.regions=colorRampPalette(c("yellow", "green", "cyan", "blue", "purple", "magenta", "red")))
xyplot(Y ~ X | "Filtering_amount_ocean_10100m", data=skgrMergeF1t, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
dev.off()

png('/home/stefan/Okokart/fin/Filtering_amount_ocean_25000m.png', width = 1000, height = 1000, units = "px", pointsize = 24, bg = "white", res = 96, type = c("cairo"))
zcol <- level.colors(skgrMergeF1t$amount_ocean_25000m, at = c(0, 1900000, 2200000, 2500000, 2800000, 3100000, 4369000), col.regions=colorRampPalette(c("yellow", "green", "cyan", "blue", "purple", "magenta", "red")))
xyplot(Y ~ X | "Filtering_amount_ocean_25000m", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
dev.off()

png('/home/stefan/Okokart/fin/Filtering_amount_ocean_50200m.png', width = 1000, height = 1000, units = "px", pointsize = 24, bg = "white", res = 96, type = c("cairo"))
zcol <- level.colors(skgrMergeF1$amount_ocean_50200m, at = c(0, 4000000, 5000000, 6750000, 8000000, 10000000, 13000000, 16980000), col.regions=colorRampPalette(c("yellow", "green", "cyan", "blue", "purple", "magenta", "red")))
xyplot(Y ~ X | "Filtering_amount_ocean_50200m", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
dev.off()

##############################################################
#Filter amount_ocean
skgrMergeF1 <- skgrMergeF1[skgrMergeF1$amount_ocean_5050m<80000,]
points_n["skgrMergeF1$amount_ocean_5050m<80000"] <- length(skgrMergeF1$hoh)
png('/home/stefan/Okokart/fin/Filtering_reference_altitude_F1_S13a.png', width = 1000, height = 1000, units = "px", pointsize = 24, bg = "white", res = 96, type = c("cairo"))
zcol <- level.colors(skgrMergeF1$hoh, at = c(0, 50, 100, 150, 200, 250, 300, 350, 400, 450, 500, 550, 600, 650, 700, 750, 800, 850, 900, 950, 1000, 1050, 1100, 1150, 1200, 1250, 1300), col.regions=terrain.colors(27), interpolate=c("linear"))
xyplot(Y ~ X | "Altitude of reference points in filter 13a", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
dev.off()

skgrMergeF1 <- skgrMergeF1[skgrMergeF1$amount_ocean_10100m<500000,]
points_n["skgrMergeF1$amount_ocean_10100m<500000"] <- length(skgrMergeF1$hoh)
png('/home/stefan/Okokart/fin/Filtering_reference_altitude_F1_S13b.png', width = 1000, height = 1000, units = "px", pointsize = 24, bg = "white", res = 96, type = c("cairo"))
zcol <- level.colors(skgrMergeF1$hoh, at = c(0, 50, 100, 150, 200, 250, 300, 350, 400, 450, 500, 550, 600, 650, 700, 750, 800, 850, 900, 950, 1000, 1050, 1100, 1150, 1200, 1250, 1300), col.regions=terrain.colors(27), interpolate=c("linear"))
xyplot(Y ~ X | "Altitude of reference points in filter 13b", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
dev.off()

skgrMergeF1 <- skgrMergeF1[skgrMergeF1$amount_ocean_25000m<2800000,]
points_n["skgrMergeF1$amount_ocean_25000m<2800000"] <- length(skgrMergeF1$hoh)
png('/home/stefan/Okokart/fin/Filtering_reference_altitude_F1_S13c.png', width = 1000, height = 1000, units = "px", pointsize = 24, bg = "white", res = 96, type = c("cairo"))
zcol <- level.colors(skgrMergeF1$hoh, at = c(0, 50, 100, 150, 200, 250, 300, 350, 400, 450, 500, 550, 600, 650, 700, 750, 800, 850, 900, 950, 1000, 1050, 1100, 1150, 1200, 1250, 1300), col.regions=terrain.colors(27), interpolate=c("linear"))
xyplot(Y ~ X | "Altitude of reference points in filter 13c", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
dev.off()

skgrMergeF1 <- skgrMergeF1[skgrMergeF1$amount_ocean_50200m<13000000,]
points_n["skgrMergeF1$amount_ocean_50200m<13000000"] <- length(skgrMergeF1$hoh)
png('/home/stefan/Okokart/fin/Filtering_reference_altitude_F1_S13d.png', width = 1000, height = 1000, units = "px", pointsize = 24, bg = "white", res = 96, type = c("cairo"))
zcol <- level.colors(skgrMergeF1$hoh, at = c(0, 50, 100, 150, 200, 250, 300, 350, 400, 450, 500, 550, 600, 650, 700, 750, 800, 850, 900, 950, 1000, 1050, 1100, 1150, 1200, 1250, 1300), col.regions=terrain.colors(27), interpolate=c("linear"))
xyplot(Y ~ X | "Altitude of reference points in filter 13d", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
dev.off()

png('/home/stefan/Okokart/fin/Filtering_point_density_F1_S13d.png', width = 1000, height = 1000, units = "px", pointsize = 24, bg = "white", res = 96, type = c("cairo"))
hexbinplot(Y ~ X | "Point density after filter 13", skgrMergeF1, aspect = 1, .aspect.ratio = 1, xbins=120, draw=TRUE, colorkey=TRUE)
dev.off()

# png('/home/stefan/Okokart/fin/Filtering_amount_ocean_100200m.png', width = 1000, height = 1000, units = "px", pointsize = 24, bg = "white", res = 96, type = c("cairo"))
# zcol <- level.colors(skgrMergeF1$amount_ocean_100200m, at = c(0, 14900000, 20000000, 25000000, 30000000, 50000000, 63710000), col.regions=colorRampPalette(c("yellow", "green", "cyan", "blue", "purple", "magenta", "red")))
# xyplot(Y ~ X | "Filtering_amount_ocean_100200m", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
# dev.off()

# png('/home/stefan/Okokart/fin/Filtering_amount_ocean_100200m.png', width = 1000, height = 1000, units = "px", pointsize = 24, bg = "white", res = 96, type = c("cairo"))
# zcol <- level.colors(skgrMergeF1t2$amount_ocean_100200m, at = c(0, 14900000, 20000000, 25000000, 30000000, 50000000, 63710000), col.regions=colorRampPalette(c("yellow", "green", "cyan", "blue", "purple", "magenta", "red")))
# xyplot(Y ~ X | "Filtering_amount_ocean_100200m", data=skgrMergeF1t2, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
# dev.off()

# png('/home/stefan/Okokart/fin/Filtering_continuity_large_scale.png', width = 1000, height = 1000, units = "px", pointsize = 24, bg = "white", res = 96, type = c("cairo"))
# zcol <- level.colors(skgrMergeF1$continuity_large_scale, at = c(0, 2, 5, 10, 15, 25, 1000), col.regions=colorRampPalette(c("yellow", "green", "cyan", "blue", "purple", "magenta", "red")))
# xyplot(Y ~ X | "Filtering_continuity_large_scale", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
# dev.off()

# png('/home/stefan/Okokart/fin/Filtering_continuity_small_scale.png', width = 1000, height = 1000, units = "px", pointsize = 24, bg = "white", res = 96, type = c("cairo"))
# zcol <- level.colors(skgrMergeF1$continuity_small_scale, at = c(0, 2, 5, 10, 15, 25, 1000), col.regions=colorRampPalette(c("yellow", "green", "cyan", "blue", "purple", "magenta", "red")))
# xyplot(Y ~ X | "Filtering_continuity_large_scale", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
# dev.off()

#try non-normal distributions (also for model 1):
#gamma distribution or negative binomial (convert to integer by * 10 (or * 100))
#plot density like in zuur
#estimate form (avg og var)

#offset Y by adding an arbitrary value (e.g. 25)
#remove all points with > 40% deviation from fitted values of model 1

skgrMergeF1_lat <- skgrMergeF1m[skgrMergeF1m$tetraterm_total_kor_0_6<=2720 & skgrMergeF1m$max_forest_50200m<=75 & skgrMergeF1m$max_forest_25000m<=50 & skgrMergeF1m$max_forest_10100m<=25 & skgrMergeF1m$max_forest_5050m<=10,]

for (i in unique(sort(as.integer(round(skgrMergeF1_lat$lat*10))))) {
skgrMergeF1_latF$hoh_lat[as.integer(round(skgrMergeF1_lat$lat*10))==i] <- quantile(skgrMergeF1_lat$hoh[as.integer(round(skgrMergeF1_lat$lat*10))==i],probs=0.75)
}

skgrMergeF1_lat_max <- skgrMergeF1_lat[skgrMergeF1_lat$hoh_lat<=skgrMergeF1_lat$hoh,]

for (i in unique(sort(as.integer(round(skgrMergeF1t3$lat*5))))) {
skgrMergeF1t3$hoh_lat2[as.integer(round(skgrMergeF1t3$lat*5))==i] <- quantile(skgrMergeF1t3$hoh[as.integer(round(skgrMergeF1t3$lat*5))==i],probs=0.75)
}

skgrMergeF1t4 <- skgrMergeF1t3[skgrMergeF1t3$hoh_lat2<=skgrMergeF1t3$hoh,]

m1 <- gls(hoh ~ sqrt(72-lat), cor=corSpatial(form = ~ X + Y, type="gaussian"), data=skgrMergeF1_lat_max)

for (i in unique(sort(as.integer(round(skgrMergeF1t2$lat*10))))) {
skgrMergeF1t2$hoh_lat[as.integer(round(skgrMergeF1t2$lat*10))==i] <- quantile(skgrMergeF1t2$hoh[as.integer(round(skgrMergeF1t2$lat*10))==i],probs=0.75)
}

r.mapcalc expression="m1_lat=(sqrt(3 - tan(latitude@latlon_grids*pi/180)) * 1188.726 - 129.312)"

skgrMergeF1m2$lat_tan <- tan(skgrMergeF1m2$lat*pi/180)
# skgrMergeF1m2$lat_tan_e2 <- tan(skgrMergeF1m2$lat*pi/180)^2
# skgrMergeF1m2$lat_tan_e3 <- tan(skgrMergeF1m2$lat*pi/180)^3
skgrMergeF1m2$lat_tan_e4 <- tan(skgrMergeF1m2$lat*pi/180)^4
# skgrMergeF1m2$lat_tan_e5 <- tan(skgrMergeF1m2$lat*pi/180)^5
# skgrMergeF1m2$lat_tan_e6 <- tan(skgrMergeF1m2$lat*pi/180)^6
skgrMergeF1m2$lat_tan_e7 <- tan(skgrMergeF1m2$lat*pi/180)^7
# skgrMergeF1m2$lat_tan_e8 <- tan(skgrMergeF1m2$lat*pi/180)^8
skgrMergeF1m2$lat_tan_e9 <- tan(skgrMergeF1m2$lat*pi/180)^9
# skgrMergeF1m2$lat_tan_e10 <- tan(skgrMergeF1m2$lat*pi/180)^10
skgrMergeF1m2$lat_tan_e20 <- tan(skgrMergeF1m2$lat*pi/180)^20
# skgrMergeF1m2$lat_tan_e30 <- tan(skgrMergeF1m2$lat*pi/180)^30
skgrMergeF1m2$lat_tan_e50 <- tan(skgrMergeF1m2$lat*pi/180)^50
skgrMergeF1m2$lat_tan_e100 <- tan(skgrMergeF1m2$lat*pi/180)^100

# Backup filter results
write.csv(skgrMergeF1, file = "/home/stefan/Okokart/fin/skgrMergeF1.csv", row.names=FALSE, col.names=TRUE)

# Three models:
f1sm_gls_full <- gls(hoh ~ lat * lon + lat * sqrt(amount_ocean_180200m) + lat * coast_line_distance + lat * solar_radiation + lon * sqrt(amount_ocean_180200m)  + lon * coast_line_distance + sqrt(amount_ocean_180200m) * coast_line_distance + sqrt(amount_ocean_180200m) * solar_radiation + solar_radiation * coast_line_distance + solar_radiation * as.factor(aspect5_cl8), method="REML", data = skgrMergeF1)
f1sm_gls_full_ulon <- gls(hoh ~ lat * sqrt(amount_ocean_180200m) + lat * coast_line_distance + lat * solar_radiation + lat * as.factor(aspect5_cl8) + sqrt(amount_ocean_180200m) * coast_line_distance + sqrt(amount_ocean_180200m) * solar_radiation + solar_radiation * coast_line_distance + solar_radiation * as.factor(aspect5_cl8), method="REML", data = skgrMergeF1)
f1sm_gls_full_ucoast <- gls(hoh ~ lat * lon + lat * sqrt(amount_ocean_180200m) + lat * solar_radiation + lat * as.factor(aspect5_cl8) + lon * sqrt(amount_ocean_180200m) + lon * solar_radiation + sqrt(amount_ocean_180200m) * solar_radiation + solar_radiation * as.factor(aspect5_cl8), method="REML", data = skgrMergeF1)

m_range <- sapply(1:length(skgrMergeF1$hoh), function(x) max(c(f1sm_gls_full$fitted[x],f1sm_gls_full_ulon$fitted[x],f1sm_gls_full_ucoast$fitted[x])-min(c(f1sm_gls_full$fitted[x],f1sm_gls_full_ulon$fitted[x],f1sm_gls_full_ucoast$fitted[x]))))

png('/home/stefan/Okokart/fin/Uncertainty_without_variance_F1.png', width = 1000, height = 1000, units = "px", pointsize = 24, bg = "white", res = 96, type = c("cairo"))
zcol <- level.colors(m_range, at = summary(m_range), col.regions=colorRampPalette(c("yellow", "green", "cyan", "blue", "purple", "magenta", "red")))
xyplot(Y ~ X | "Uncertainty", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
dev.off()

# ucoast
f_gls_ucoast <- formula(hoh ~ lat * lon + lat * sqrt(amount_ocean_avg) + lat * solar_radiation + lat * as.factor(aspect5_cl8) + lon * sqrt(amount_ocean_avg) + lon * solar_radiation + sqrt(amount_ocean_avg) * solar_radiation + solar_radiation * as.factor(aspect5_cl8))
# ulon
f_gls_ulon <- formula(hoh ~ lat * sqrt(amount_ocean_avg) + lat * cost_distance_coast + lat * solar_radiation + lat * as.factor(aspect5_cl8) + sqrt(amount_ocean_avg) * cost_distance_coast + sqrt(amount_ocean_avg) * solar_radiation + solar_radiation * cost_distance_coast + solar_radiation * as.factor(aspect5_cl8))
# all
f_gls_all <- formula(hoh ~ lat * lon + lat * sqrt(amount_ocean_250200m) + lat * cost_distance_coast + lat * solar_radiation + lat * as.factor(aspect5_cl8) + lon * sqrt(amount_ocean_250200m)  + lon * cost_distance_coast +  * solar_radiation + sqrt(amount_ocean_250200m) * cost_distance_coast + sqrt(amount_ocean_250200m) * solar_radiation + cost_distance_coast * solar_radiation + solar_radiation * as.factor(aspect5_cl8))

f1sm_gls_full_o2_poly2b <- gls(hoh ~ poly(lat,3) * poly(X,3) + poly(lat,3) * poly(sqrt(amount_ocean_avg),3) + poly(lat,3) * poly(cost_distance_coast,3) + poly(lat,3) * poly(solar_radiation,3) + poly(lat,3) * as.factor(aspect5_cl8) + poly(X,3) * poly(sqrt(amount_ocean_avg),3)  + poly(X,3) * poly(cost_distance_coast,3) + poly(X,3) * poly(solar_radiation,3)  + poly(sqrt(amount_ocean_avg),3) * poly(cost_distance_coast,3) + poly(sqrt(amount_ocean_avg),3) * poly(solar_radiation,3) + poly(solar_radiation,3) * poly(cost_distance_coast,3) + poly(solar_radiation,3) * as.factor(aspect5_cl8), weights=varComb(varConstPower(form=~slope_5), varPower(form=~tetraterm_total_kor), varConstPower(form=~I(coast_line_distance*cost_distance_coast)), varConstPower(form=~I(cost_distance_coast* amount_ocean_50200m))), data = skgrMergeF1m)
f1sm_gls_full_o2_poly2bl <- gls(hoh ~ poly(lat,3) * poly(X,3) + poly(lat,3) * poly(sqrt(amount_ocean_avg_l),3) + poly(lat,3) * poly(cost_distance_coast,3) + poly(lat,3) * poly(solar_radiation,3) + poly(lat,3) * as.factor(aspect5_cl8) + poly(X,3) * poly(sqrt(amount_ocean_avg_l),3)  + poly(X,3) * poly(cost_distance_coast,3) + poly(X,3) * poly(solar_radiation,3)  + poly(sqrt(amount_ocean_avg_l),3) * poly(cost_distance_coast,3) + poly(sqrt(amount_ocean_avg_l),3) * poly(solar_radiation,3) + poly(solar_radiation,3) * poly(cost_distance_coast,3) + poly(solar_radiation,3) * as.factor(aspect5_cl8), weights=varComb(varConstPower(form=~slope_5), varPower(form=~tetraterm_total_kor), varConstPower(form=~I(coast_line_distance*cost_distance_coast)), varConstPower(form=~I(cost_distance_coast* amount_ocean_50200m))), data = skgrMergeF1m)
f1sm_gls_full_o2 <- gls(hoh ~ poly(lat,2) * X + poly(lat,2) * sqrt(sqrt(amount_ocean_avg)) + poly(lat,2) * sqrt(cost_distance_coast) + poly(lat,2) * sqrt(solar_radiation) + poly(lat,2) * as.factor(aspect5_cl8) + X * sqrt(sqrt(amount_ocean_avg))  + X * sqrt(cost_distance_coast) + X * sqrt(solar_radiation)  + sqrt(sqrt(amount_ocean_avg)) * sqrt(cost_distance_coast) + sqrt(sqrt(amount_ocean_avg)) * sqrt(solar_radiation) + sqrt(solar_radiation) * sqrt(cost_distance_coast) + sqrt(solar_radiation) * as.factor(aspect5_cl8), weights=varComb(varConstPower(form=~slope_5), varPower(form=~tetraterm_total_kor), varConstPower(form=~I(coast_line_distance*cost_distance_coast)), varConstPower(form=~I(cost_distance_coast* amount_ocean_50200m))), data = skgrMergeF1m)
f1sm_gls_full_o2l <- gls(hoh ~ poly(lat,2) * X + poly(lat,2) * sqrt(sqrt(amount_ocean_avg_l)) + poly(lat,2) * sqrt(cost_distance_coast) + poly(lat,2) * sqrt(solar_radiation) + poly(lat,2) * as.factor(aspect5_cl8) + X * sqrt(sqrt(amount_ocean_avg_l))  + X * sqrt(cost_distance_coast) + X * sqrt(solar_radiation)  + sqrt(sqrt(amount_ocean_avg_l)) * sqrt(cost_distance_coast) + sqrt(sqrt(amount_ocean_avg_l)) * sqrt(solar_radiation) + sqrt(solar_radiation) * sqrt(cost_distance_coast) + sqrt(solar_radiation) * as.factor(aspect5_cl8), weights=varComb(varConstPower(form=~slope_5), varPower(form=~tetraterm_total_kor), varConstPower(form=~I(coast_line_distance*cost_distance_coast)), varConstPower(form=~I(cost_distance_coast* amount_ocean_50200m))), data = skgrMergeF1m)

f1sm_gls_full_o2_poly2b <- gls(hoh ~ poly(lat,3, raw=TRUE) * poly(X,3, raw=TRUE) + poly(lat,3, raw=TRUE) * poly(sqrt(amount_ocean_avg),3, raw=TRUE) + poly(lat,3, raw=TRUE) * poly(cost_distance_coast,3, raw=TRUE) + poly(lat,3, raw=TRUE) * poly(solar_radiation,3, raw=TRUE) + poly(lat,3, raw=TRUE) * as.factor(aspect5_cl8) + poly(X,3, raw=TRUE) * poly(sqrt(amount_ocean_avg),3, raw=TRUE)  + poly(X,3, raw=TRUE) * poly(cost_distance_coast,3, raw=TRUE) + poly(X,3, raw=TRUE) * poly(solar_radiation,3, raw=TRUE)  + poly(sqrt(amount_ocean_avg),3, raw=TRUE) * poly(cost_distance_coast,3, raw=TRUE) + poly(sqrt(amount_ocean_avg),3, raw=TRUE) * poly(solar_radiation,3, raw=TRUE) + poly(solar_radiation,3, raw=TRUE) * poly(cost_distance_coast,3, raw=TRUE) + poly(solar_radiation,3, raw=TRUE) * as.factor(aspect5_cl8), weights=varComb(varConstPower(form=~slope_5), varPower(form=~tetraterm_total_kor), varConstPower(form=~I(coast_line_distance*cost_distance_coast)), varConstPower(form=~I(cost_distance_coast* amount_ocean_50200m))), data = skgrMergeF1m)
f1sm_gls_full_o2_poly2bl <- gls(hoh ~ poly(lat,3, raw=TRUE) * poly(X,3, raw=TRUE) + poly(lat,3, raw=TRUE) * poly(sqrt(amount_ocean_avg_l),3, raw=TRUE) + poly(lat,3, raw=TRUE) * poly(cost_distance_coast,3, raw=TRUE) + poly(lat,3, raw=TRUE) * poly(solar_radiation,3, raw=TRUE) + poly(lat,3, raw=TRUE) * as.factor(aspect5_cl8) + poly(X,3, raw=TRUE) * poly(sqrt(amount_ocean_avg_l),3, raw=TRUE)  + poly(X,3, raw=TRUE) * poly(cost_distance_coast,3, raw=TRUE) + poly(X,3, raw=TRUE) * poly(solar_radiation,3, raw=TRUE)  + poly(sqrt(amount_ocean_avg_l),3, raw=TRUE) * poly(cost_distance_coast,3, raw=TRUE) + poly(sqrt(amount_ocean_avg_l),3, raw=TRUE) * poly(solar_radiation,3, raw=TRUE) + poly(solar_radiation,3, raw=TRUE) * poly(cost_distance_coast,3, raw=TRUE) + poly(solar_radiation,3, raw=TRUE) * as.factor(aspect5_cl8), weights=varComb(varConstPower(form=~slope_5), varPower(form=~tetraterm_total_kor), varConstPower(form=~I(coast_line_distance*cost_distance_coast)), varConstPower(form=~I(cost_distance_coast* amount_ocean_50200m))), data = skgrMergeF1m)
f1sm_gls_full_o2 <- gls(hoh ~ poly(lat,2, raw=TRUE) * X + poly(lat,2, raw=TRUE) * sqrt(sqrt(amount_ocean_avg)) + poly(lat,2, raw=TRUE) * sqrt(cost_distance_coast) + poly(lat,2, raw=TRUE) * sqrt(solar_radiation) + poly(lat,2, raw=TRUE) * as.factor(aspect5_cl8) + X * sqrt(sqrt(amount_ocean_avg))  + X * sqrt(cost_distance_coast) + X * sqrt(solar_radiation)  + sqrt(sqrt(amount_ocean_avg)) * sqrt(cost_distance_coast) + sqrt(sqrt(amount_ocean_avg)) * sqrt(solar_radiation) + sqrt(solar_radiation) * sqrt(cost_distance_coast) + sqrt(solar_radiation) * as.factor(aspect5_cl8), weights=varComb(varConstPower(form=~slope_5), varPower(form=~tetraterm_total_kor), varConstPower(form=~I(coast_line_distance*cost_distance_coast)), varConstPower(form=~I(cost_distance_coast* amount_ocean_50200m))), data = skgrMergeF1m)
f1sm_gls_full_o2l <- gls(hoh ~ poly(lat,2, raw=TRUE) * X + poly(lat,2, raw=TRUE) * sqrt(sqrt(amount_ocean_avg_l)) + poly(lat,2, raw=TRUE) * sqrt(cost_distance_coast) + poly(lat,2, raw=TRUE) * sqrt(solar_radiation) + poly(lat,2, raw=TRUE) * as.factor(aspect5_cl8) + X * sqrt(sqrt(amount_ocean_avg_l))  + X * sqrt(cost_distance_coast) + X * sqrt(solar_radiation)  + sqrt(sqrt(amount_ocean_avg_l)) * sqrt(cost_distance_coast) + sqrt(sqrt(amount_ocean_avg_l)) * sqrt(solar_radiation) + sqrt(solar_radiation) * sqrt(cost_distance_coast) + sqrt(solar_radiation) * as.factor(aspect5_cl8), weights=varComb(varConstPower(form=~slope_5), varPower(form=~tetraterm_total_kor), varConstPower(form=~I(coast_line_distance*cost_distance_coast)), varConstPower(form=~I(cost_distance_coast* amount_ocean_50200m))), data = skgrMergeF1m)
AIC(f1sm_gls_full_o2l)
summary(f1sm_gls_full_o2l$resid)
summary(f1sm_gls_full_o2l$fitted)
####
####
#Test continentality og continentality2
####
####

formulas <- list()
formulas[[1]] <- f_gls_full_all
formulas[[2]] <- f_gls_full_ulon
formulas[[3]] <- f_gls_full_ucoast

#reference GLM
f1sm_glm_full <- gls(f, method="REML", data = skgrMergeF1)
#ulon: AIC: 1678704
#ucoast: 1606990
#all: AIC: 1600091

AICs <- list()

for (f in formulas) {
f1sm_glm_full <- gls(f, method="REML", data = skgrMergeF1)

#GLS with variance stucture on lat
f1sm_gls_vf_lat <- gls(f, weights=varFixed(~lat), method="REML", data = skgrMergeF1)
#f1sm_gls_ve_lat <- gls(f, weights=varExp(form=~lat), method="REML", data = skgrMergeF1)
f1sm_gls_vp_lat <- gls(f, weights=varPower(form=~lat), method="REML", data = skgrMergeF1)
f1sm_gls_vcp_lat <- gls(f, weights=varConstPower(form=~lat), method="REML", data = skgrMergeF1)

AICs[[paste("var on lat ", toString(f), sep="")]] <- AIC(f1sm_glm_full,f1sm_gls_vf_lat,f1sm_gls_vp_lat,f1sm_gls_vcp_lat)
}
#Result: No variance with lat
#all: varPower(form=~lat) #AIC (best): 1600051
#ulon: varPower(form=~lat) #AIC (best): 1678705
#ucoast: varPower(form=~lat) #AIC (best): 1606900

for (f in formulas) {
f1sm_glm_full <- gls(f, method="REML", data = skgrMergeF1)
#GLS with variance stucture on lon
f1sm_gls_vf_lon <- gls(f, weights=varFixed(~lon), method="REML", data = skgrMergeF1)
f1sm_gls_ve_lon <- gls(f, weights=varExp(form=~lon), method="REML", data = skgrMergeF1)
f1sm_gls_vp_lon <- gls(f, weights=varPower(form=~lon), method="REML", data = skgrMergeF1)
f1sm_gls_vcp_lon <- gls(f, weights=varConstPower(form=~lon), method="REML", data = skgrMergeF1)

AICs[[paste("var on lon ", toString(f), sep="")]] <- AIC(f1sm_glm_full,f1sm_gls_vf_lon,f1sm_gls_ve_lon,f1sm_gls_vp_lon,f1sm_gls_vcp_lon)
}
#Result:
#all: varExp(form=~lon) #AIC: 1598943
#ulon: varConstPower(form=~lon) #AIC: 1675046
#ucoast: varExp(form=~lon) #AIC: 1605529

for (f in formulas) {
f1sm_glm_full <- gls(f, method="REML", data = skgrMergeF1)
#GLS with variance stucture on X
#f1sm_gls_vf_X <- gls(f_gls, weights=varFixed(~X), method="REML", data = skgrMergeF1)
f1sm_gls_ve_X <- gls(f, weights=varExp(form=~X), method="REML", data = skgrMergeF1)
#f1sm_gls_vp_X <- gls(f_gls, weights=varPower(form=~X), method="REML", data = skgrMergeF1)
#f1sm_gls_vcp_X <- gls(f_gls, weights=varConstPower(form=~X), method="REML", data = skgrMergeF1)

AICs[[paste("var on X ", toString(f), sep="")]] <- AIC(f1sm_glm_full,f1sm_gls_ve_X)
}
#Result:
#ulon: None #AIC: (best) 1710589
#ucoast: None #AIC: (best) 1641911
#all: None #AIC: (best) 1635581

for (f in formulas) {
f1sm_glm_full <- gls(f, method="REML", data = skgrMergeF1)
#GLS with variance stucture on quart_gw
f1sm_gls_vi_quart_gw <- gls(f, weights=varIdent(form=~1|quart_gw), method="REML", data = skgrMergeF1)

AICs[[paste("var on quart_gw ", toString(f), sep="")]] <- AIC(f1sm_glm_full,f1sm_gls_vi_quart_gw)
}

#Result:
#all: varIdent(form=~1|quart_gw) AIC: 1597100
#ulon: varIdent(form=~1|quart_gw) AIC: 1677689
#ucoast: varIdent(form=~1|quart_gw) AIC: 1604100

for (f in formulas) {
f1sm_glm_full <- gls(f, method="REML", data = skgrMergeF1)
#GLS with variance stucture on geol_rich
f1sm_gls_vi_geol_rich <- gls(f, weights=varIdent(form=~1|geol_rich), method="REML", data = skgrMergeF1)

AICs[[paste("var on geol_rich ", toString(f), sep="")]] <- AIC(f1sm_glm_full,f1sm_gls_vi_geol_rich)
}
#Result:
#all: varIdent(form=~1|geol_rich) #AIC: 1599866
#ulon: varIdent(form=~1|geol_rich) #AIC: 1678391
#ucoast: varIdent(form=~1|geol_rich) #AIC: 1606789

for (f in formulas) {
f1sm_glm_full <- gls(f, method="REML", data = skgrMergeF1)
#GLS with variance stucture on slope
f1sm_gls_vf_slope5 <- gls(f, weights=varFixed(~slope_5), method="REML", data = skgrMergeF1)
f1sm_gls_ve_slope5 <- gls(f, weights=varExp(form=~slope_5), method="REML", data = skgrMergeF1)
f1sm_gls_vp_slope5 <- gls(f, weights=varPower(form=~slope_5), method="REML", data = skgrMergeF1)
f1sm_gls_vcp_slope5 <- gls(f, weights=varConstPower(form=~slope_5), method="REML", data = skgrMergeF1)

f1sm_gls_vf_slope3 <- gls(f, weights=varFixed(~slope_3), method="REML", data = skgrMergeF1)
f1sm_gls_ve_slope3 <- gls(f, weights=varExp(form=~slope_3), method="REML", data = skgrMergeF1)
f1sm_gls_vp_slope3 <- gls(f, weights=varPower(form=~slope_3), method="REML", data = skgrMergeF1)
f1sm_gls_vcp_slope3 <- gls(f, weights=varConstPower(form=~slope_3), method="REML", data = skgrMergeF1)

f1sm_gls_vf_slope_next <- gls(f, weights=varFixed(~slope_next), method="REML", data = skgrMergeF1)
f1sm_gls_ve_slope_next <- gls(f, weights=varExp(form=~slope_next), method="REML", data = skgrMergeF1)
f1sm_gls_vp_slope_next <- gls(f, weights=varPower(form=~slope_next), method="REML", data = skgrMergeF1)
f1sm_gls_vcp_slope_next <- gls(f, weights=varConstPower(form=~slope_next), method="REML", data = skgrMergeF1)

AICs[[paste("var on slope ", toString(f), sep="")]] <- AIC(f1sm_glm_full,f1sm_gls_vf_slope3,f1sm_gls_ve_slope3,f1sm_gls_vp_slope3,f1sm_gls_vcp_slope3,f1sm_gls_vf_slope5,f1sm_gls_ve_slope5,f1sm_gls_vp_slope5,f1sm_gls_vcp_slope5,f1sm_gls_vf_slope_next,f1sm_gls_ve_slope_next,f1sm_gls_vp_slope_next,f1sm_gls_vcp_slope_next)
}
#Result:
#all: varConstPower(form=~slope_5) AIC: 1597920
#ulon: varConstPower(form=~slope_5) #AIC: 1677727
#ucoast: varConstPower(form=~slope_5) #AIC: 1604889

#GLS with variance stucture on actuality (actuality > 0)
# Too heavy for processing with varIdent()
# f1sm_gls_vf_actuality <- gls(f, weights=varFixed(~actuality), method="REML", data = skgrMergeF1)
# f1sm_gls_ve_actuality <- gls(f, weights=varExp(form=~actuality), method="REML", data = skgrMergeF1)
# f1sm_gls_vp_actuality <- gls(f, weights=varPower(form=~actuality), method="REML", data = skgrMergeF1)
#f1sm_gls_vi_actuality <- gls(f, weights=varIdent(form=~1|actuality), method="REML", data = skgrMergeF1)

#AIC(f1sm_glm_full,f1sm_gls_vf_actuality,f1sm_gls_ve_actuality,f1sm_gls_vp_actuality,f1sm_gls_vi_actuality)
#AIC(f1sm_glm_full,f1sm_gls_vi_actuality)

for (f in formulas) {
f1sm_glm_full <- gls(f, method="REML", data = skgrMergeF1)
#GLS with variance stucture on TPI_50m
f1sm_gls_vf_TPI_50m <- gls(f, weights=varFixed(~TPI_50m), method="REML", data = skgrMergeF1)
#f1sm_gls_ve_TPI_50m_stddev <- gls(f, weights=varExp(form=~TPI_3100m), method="REML", data = skgrMergeF1)
f1sm_gls_vp_TPI_50m <- gls(f, weights=varPower(form=~TPI_50m), method="REML", data = skgrMergeF1)
f1sm_gls_vcp_TPI_50m <- gls(f, weights=varConstPower(form=~TPI_50m), method="REML", data = skgrMergeF1)

#GLS with variance stucture on TPI_3100m_stddev
f1sm_gls_vf_TPI_3100m_stddev <- gls(f, weights=varFixed(~TPI_3100m_stddev), method="REML", data = skgrMergeF1)
#f1sm_gls_ve_TPI_3100m_stddev <- gls(f, weights=varExp(form=~TPI_3100m_stddev), method="REML", data = skgrMergeF1)
f1sm_gls_vp_TPI_3100m_stddev <- gls(f, weights=varPower(form=~TPI_3100m_stddev), method="REML", data = skgrMergeF1)
f1sm_gls_vcp_TPI_3100m_stddev <- gls(f, weights=varConstPower(form=~TPI_3100m_stddev), method="REML", data = skgrMergeF1)

f1sm_gls_vf_TPI_5100m_stddev <- gls(f, weights=varFixed(~TPI_5100m_stddev), method="REML", data = skgrMergeF1)
#f1sm_gls_ve_TPI_5100m_stddev <- gls(f, weights=varExp(form=~TPI_5100m_stddev), method="REML", data = skgrMergeF1)
f1sm_gls_vp_TPI_5100m_stddev <- gls(f, weights=varPower(form=~TPI_5100m_stddev), method="REML", data = skgrMergeF1)
f1sm_gls_vcp_TPI_5100m_stddev <- gls(f, weights=varConstPower(form=~TPI_5100m_stddev), method="REML", data = skgrMergeF1)

AICs[[paste("var on TPI ", toString(f), sep="")]] <- AIC(f1sm_glm_full,f1sm_gls_vf_TPI_3100m_stddev,f1sm_gls_vp_TPI_3100m_stddev,f1sm_gls_vcp_TPI_3100m_stddev,f1sm_gls_vf_TPI_5100m_stddev,f1sm_gls_vp_TPI_5100m_stddev,f1sm_gls_vcp_TPI_5100m_stddev,f1sm_gls_vf_TPI_50m,f1sm_gls_vp_TPI_50m,f1sm_gls_vcp_TPI_50m)
}
#Result:
#all: varPower(form=~TPI_3100m_stddev) #AIC: 1597159
#ulon: varPower(form=~TPI_3100m_stddev) #AIC: 1678542
#ucoast: varPower(form=~TPI_5100m_stddev) #AIC: 1603921

#GLS with variance stucture on GID
# Too heavy for processing with varIdent()
#f1sm_gls_vi_GID <- gls(f, weights=varIdent(form=~1|GID), method="REML", data = skgrMergeF1)
#AIC(f1sm_glm_full,f1sm_gls_vi_GID)

for (f in formulas) {
f1sm_glm_full <- gls(f, method="REML", data = skgrMergeF1)
#GLS with variance stucture on coast_line_distance (test also the inverse (*-1) effect of coast_line_distance?, as well as coast_distance (or the difference between coast_distance)) 
f1sm_gls_vf_coast_line_distance <- gls(f, weights=varFixed(~coast_line_distance), method="REML", data = skgrMergeF1)
f1sm_gls_ve_coast_line_distance <- gls(f, weights=varExp(form=~coast_line_distance), method="REML", data = skgrMergeF1)
f1sm_gls_vp_coast_line_distance <- gls(f, weights=varPower(form=~coast_line_distance), method="REML", data = skgrMergeF1)

AICs[[paste("var on coast line distance ", toString(f), sep="")]] <- AIC(f1sm_glm_full,f1sm_gls_vf_coast_line_distance,f1sm_gls_ve_coast_line_distance,f1sm_gls_vp_coast_line_distance)
}
#Result:
#all: varExp(form=~coast_line_distance) #AIC: 1596170
#ulon: varExp(form=~coast_line_distance) #AIC: 1675983
#ucoast: varExp(form=~coast_line_distance) #AIC: 1604490

for (f in formulas) {
f1sm_glm_full <- gls(f, method="REML", data = skgrMergeF1)
#GLS with variance stucture on amount_ocean_180200m
f1sm_gls_vf_amount_ocean_180200m <- gls(f, weights=varFixed(~I(1+amount_ocean_180200m)), method="REML", data = skgrMergeF1)
#f1sm_gls_ve_amount_ocean_180200m <- gls(f, weights=varExp(form=~I(1+amount_ocean_180200m)), method="REML", data = skgrMergeF1)
f1sm_gls_vp_amount_ocean_180200m <- gls(f, weights=varPower(form=~I(1+amount_ocean_180200m)), method="REML", data = skgrMergeF1)
f1sm_gls_vcp_amount_ocean_180200m <- gls(f, weights=varConstPower(form=~amount_ocean_180200m), method="REML", data = skgrMergeF1)

AICs[[paste("var on amount_ocean_180200m ", toString(f), sep="")]] <- AIC(f1sm_glm_full,f1sm_gls_vf_amount_ocean_180200m,f1sm_gls_vp_amount_ocean_180200m,f1sm_gls_vcp_amount_ocean_180200m)
}
#Result:
#all: varConstPower(form=~amount_ocean_180200m) #AIC: 1595320
#ulon: varConstPower(form=~I(1+amount_ocean_180200m)) #AIC: 1674283
#ucoast: varConstPower(form=~amount_ocean_180200m) #AIC: 1603794

for (f in formulas) {
f1sm_glm_full <- gls(f, method="REML", data = skgrMergeF1)
#GLS with variance stucture on amount_ocean_50200m
f1sm_gls_vf_amount_ocean_50200m <- gls(f, weights=varFixed(~I(1+amount_ocean_50200m)), method="REML", data = skgrMergeF1)
f1sm_gls_ve_amount_ocean_50200m <- gls(f, weights=varExp(form=~I(1+amount_ocean_50200m)), method="REML", data = skgrMergeF1)
f1sm_gls_vp_amount_ocean_50200m <- gls(f, weights=varPower(form=~amount_ocean_50200m), method="REML", data = skgrMergeF1)
#f1sm_gls_vcp_amount_ocean_50200m <- gls(f, weights=varConstPower(form=~amount_ocean_50200m), method="REML", data = skgrMergeF1)

AICs[[paste("var on amount_ocean_50200m ", toString(f), sep="")]] <- AIC(f1sm_glm_full,f1sm_gls_vf_amount_ocean_50200m,f1sm_gls_ve_amount_ocean_50200m,f1sm_gls_vp_amount_ocean_50200m)
}
#Result:
#ulon: None #AIC: 1710210
#ucoast: None #AIC: 1641040
#all: None #AIC: 1633951

for (f in formulas) {
f1sm_glm_full <- gls(f, method="REML", data = skgrMergeF1)
#GLS with variance stucture on max_forest_dist_sum
f1sm_gls_vf_max_forest_sum_all <- gls(f, weights=varFixed(~I(max_forest_sum_all+1)), method="REML", data = skgrMergeF1)
f1sm_gls_ve_max_forest_sum_all <- gls(f, weights=varExp(form=~max_forest_sum_all), method="REML", data = skgrMergeF1)
f1sm_gls_vp_max_forest_sum_all <- gls(f, weights=varPower(form=~I(max_forest_sum_all+1)), method="REML", data = skgrMergeF1)
#f1sm_gls_vcp_max_forest_sum_all <- gls(f, weights=varConstPower(form=~max_forest_sum_all), method="REML", data = skgrMergeF1)

AICs[[paste("var on max_forest_dist_sum ", toString(f), sep="")]] <- AIC(f1sm_glm_full,f1sm_gls_vf_max_forest_sum_all,f1sm_gls_vp_max_forest_sum_all,f1sm_gls_vcp_max_forest_sum_all)
}
#Result:
#ulon: None #AIC (best): 1710603
#ucoast: None #AIC: 1642515
#all: None #AIC: 1636006

for (f in formulas) {
f1sm_glm_full <- gls(f, method="REML", data = skgrMergeF1)
#GLS with variance stucture on tetraterm_total_kor
#f1sm_gls_vf_tetraterm_total_kor <- gls(f, weights=varFixed(form=~tetraterm_total_kor), method="REML", data = skgrMergeF1)
f1sm_gls_vp_tetraterm_total_kor <- gls(f, weights=varPower(form=~tetraterm_total_kor), method="REML", data = skgrMergeF1)
#f1sm_gls_ve_tetraterm_total_kor <- gls(f, weights=varExp(form=~tetraterm_total_kor), method="REML", data = skgrMergeF1)
f1sm_gls_vcp_tetraterm_total_kor <- gls(f, weights=varConstPower(form=~tetraterm_total_kor), method="REML", data = skgrMergeF1)

AICs[[paste("var on tetraterm_total_kor ", toString(f), sep="")]] <- AIC(f1sm_glm_full,f1sm_gls_vp_tetraterm_total_kor,f1sm_gls_vcp_tetraterm_total_kor,f1sm_gls_ve_tetraterm_total_kor)
}

#GLS with variance stucture on a combination of all relevant variance parameters
#ulon: varConstPower(form=~slope_5),varConstPower(form=~lon),varPower(form=~amount_ocean_180200m) #AIC: 1705757
#all: varConstPower(form=~amount_ocean_180200m),varExp(form=~coast_line_distance),varPower(form=~TPI_3100m_stddev),varConstPower(form=~slope_5),varExp(form=~lon),varIdent(form=~1|quart_gw) AIC: 
#ucoast: weights=varComb(varConstPower(form=~amount_ocean_180200m),varExp(form=~lon),varPower(form=~TPI_3100m_stddev),varConstPower(form=~slope_5),varIdent(form=~1|quart_gw)) #AIC: 1634703
varConstPower(form=~amount_ocean_180200m) #AIC: 1638981
varExp(form=~coast_line_distance) #AIC: 1639672
varPower(form=~TPI_3100m_stddev) #AIC: 1639411
varConstPower(form=~slope_5) #AIC: 1640222
varIdent(form=~1|quart_gw) #AIC: 1639998
varExp(form=~lon) #AIC: 1641303

#ucoast:
f1sm_gls_full_ucoast <- gls(f_gls_full_ucoast, weights=varComb(varConstPower(form=~amount_ocean_180200m),varExp(form=~lon),varPower(form=~TPI_3100m_stddev),varConstPower(form=~slope_5),varIdent(form=~1|quart_gw)), method="REML", data = skgrMergeF1)
#AIC: 1634703
#ulon:
f1sm_gls_full_ulon <- gls(f_gls_full_ulon, weights=varComb(varConstPower(form=~slope_5),varConstPower(form=~lon),varPower(form=~amount_ocean_180200m)), method="REML", data = skgrMergeF1)
#AIC: 1705757

#all:
f1sm_gls_full_all <- gls(f_gls_full_all, weights=varComb(varConstPower(form=~amount_ocean_180200m), varConstPower(form=~slope_5), varExp(form=~lon), varIdent(form=~1|quart_gw)), method="REML", data = skgrMergeF1)
#AIC: 1627361

f1sm_gls_full_all <- gls(hoh ~ lat_tan * sqrt(sqrt(sqrt(lon))) + lat_tan * sqrt(amount_ocean_avg) + lat_tan * sqrt(sqrt(cost_distance_coast)) + lat_tan * solar_radiation + lat_tan * as.factor(aspect5_cl8) + sqrt(sqrt(sqrt(lon))) * sqrt(amount_ocean_avg)  + sqrt(sqrt(sqrt(lon))) * sqrt(sqrt(cost_distance_coast)) + sqrt(amount_ocean_avg) * sqrt(sqrt(cost_distance_coast)) + sqrt(amount_ocean_avg) * solar_radiation + solar_radiation * sqrt(sqrt(cost_distance_coast)) + solar_radiation * as.factor(aspect5_cl8), weights=varComb(varConstPower(form=~slope_5), varPower(form=~tetraterm_total_kor), varConstPower(form=~I(cost_distance_coast* amount_ocean_50200m))), method="REML", data = skgrMergeF1m2)
f1sm_gls_full_ulon <- gls(hoh ~ lat_tan * sqrt(sqrt(sqrt(lon))) + lat_tan * sqrt(amount_ocean_avg) + lat_tan * sqrt(sqrt(cost_distance_coast)) + lat_tan * solar_radiation + lat_tan * as.factor(aspect5_cl8) + sqrt(sqrt(sqrt(lon))) * sqrt(amount_ocean_avg)  + sqrt(sqrt(sqrt(lon))) * sqrt(sqrt(cost_distance_coast)) + sqrt(amount_ocean_avg) * sqrt(sqrt(cost_distance_coast)) + sqrt(amount_ocean_avg) * solar_radiation + solar_radiation * sqrt(sqrt(cost_distance_coast)) + solar_radiation * as.factor(aspect5_cl8), weights=varComb(varConstPower(form=~slope_5), varPower(form=~tetraterm_total_kor), varConstPower(form=~I(cost_distance_coast* amount_ocean_50200m))), method="REML", data = skgrMergeF1m2)
f1sm_gls_full_ucoast <- gls(hoh ~ lat_tan * sqrt(sqrt(sqrt(lon))) + lat_tan * sqrt(amount_ocean_avg) + lat_tan * sqrt(sqrt(cost_distance_coast)) + lat_tan * solar_radiation + lat_tan * as.factor(aspect5_cl8) + sqrt(sqrt(sqrt(lon))) * sqrt(amount_ocean_avg)  + sqrt(sqrt(sqrt(lon))) * sqrt(sqrt(cost_distance_coast)) + sqrt(amount_ocean_avg) * sqrt(sqrt(cost_distance_coast)) + sqrt(amount_ocean_avg) * solar_radiation + solar_radiation * sqrt(sqrt(cost_distance_coast)) + solar_radiation * as.factor(aspect5_cl8), weights=varComb(varConstPower(form=~slope_5), varPower(form=~tetraterm_total_kor), varConstPower(form=~I(cost_distance_coast* amount_ocean_50200m))), method="REML", data = skgrMergeF1m2)

f1sm_gls_full_all <- gls(hoh ~ lat_tan * lon + lat_tan * sqrt(amount_ocean_avg) + lat_tan * sqrt(sqrt(cost_distance_coast)) + lat_tan * sqrt(sqrt(solar_radiation)) + lat_tan * as.factor(aspect5_cl8) + lon * sqrt(amount_ocean_avg)  + lon * sqrt(sqrt(cost_distance_coast)) + sqrt(amount_ocean_avg) * sqrt(sqrt(cost_distance_coast)) + sqrt(amount_ocean_avg) * sqrt(sqrt(solar_radiation)) + sqrt(sqrt(solar_radiation)) * sqrt(sqrt(cost_distance_coast)) + sqrt(sqrt(solar_radiation)) * as.factor(aspect5_cl8), weights=varComb(varConstPower(form=~slope_5), varPower(form=~tetraterm_total_kor), varConstPower(form=~I(cost_distance_coast* amount_ocean_50200m))), method="REML", data = skgrMergeF1m2)
f1sm_gls_full_ulon <- gls(hoh ~ lat_tan * sqrt(amount_ocean_avg) + lat_tan * sqrt(sqrt(cost_distance_coast)) + lat_tan * sqrt(sqrt(solar_radiation)) + lat_tan * as.factor(aspect5_cl8) + sqrt(amount_ocean_avg) * sqrt(sqrt(cost_distance_coast)) + sqrt(amount_ocean_avg) * sqrt(sqrt(solar_radiation)) + sqrt(sqrt(solar_radiation)) * sqrt(sqrt(cost_distance_coast)) + sqrt(sqrt(solar_radiation)) * as.factor(aspect5_cl8), weights=varComb(varConstPower(form=~slope_5), varPower(form=~tetraterm_total_kor), varConstPower(form=~I(cost_distance_coast* amount_ocean_50200m))), method="REML", data = skgrMergeF1m2)
f1sm_gls_full_ucoast <- gls(hoh ~ lat_tan * lon + lat_tan * sqrt(amount_ocean_avg) + lat_tan * sqrt(sqrt(solar_radiation)) + lat_tan * as.factor(aspect5_cl8) + lon * sqrt(amount_ocean_avg) + sqrt(amount_ocean_avg) * sqrt(sqrt(solar_radiation)) + sqrt(sqrt(solar_radiation)) * as.factor(aspect5_cl8), weights=varComb(varConstPower(form=~slope_5), varPower(form=~tetraterm_total_kor), varConstPower(form=~I(cost_distance_coast* amount_ocean_50200m))), method="REML", data = skgrMergeF1m2)

f1sm_gls_full_o2 <- gls(hoh ~ poly(lat,2) * poly(lon,2) + poly(lat,2) * poly(amount_ocean_avg_l,2) + poly(lat,2) * poly(cost_distance_coast,2) + poly(lat,2) * poly(amount_ocean_avg_l,2) * sqrt(sqrt(solar_radiation)) + poly(lat,2) * as.factor(aspect5_cl8) + poly(lon,2) * poly(amount_ocean_avg_l,2)  + poly(lon,2) * poly(cost_distance_coast,2) + poly(amount_ocean_avg_l,2) * poly(cost_distance_coast,2) + poly(amount_ocean_avg_l,2) * sqrt(sqrt(solar_radiation)) + sqrt(sqrt(solar_radiation)) * poly(cost_distance_coast,2) + sqrt(sqrt(solar_radiation)) * as.factor(aspect5_cl8), weights=varComb(varConstPower(form=~slope_5), varPower(form=~tetraterm_total_kor), varConstPower(form=~I(cost_distance_coast* amount_ocean_50200m))), data = skgrMergeF1m2)
f1sm_gls_full_o2_poly <- gls(hoh ~ poly(lat,2) * poly(lon,2) + poly(lat,2) * poly(amount_ocean_avg_l,2) + poly(lat,2) * poly(cost_distance_coast,2) + poly(lat,2) * poly(amount_ocean_avg_l,2) * poly(solar_radiation,2) + poly(lat,2) * as.factor(aspect5_cl8) + poly(lon,2) * poly(amount_ocean_avg_l,2)  + poly(lon,2) * poly(cost_distance_coast,2) + poly(amount_ocean_avg_l,2) * poly(cost_distance_coast,2) + poly(amount_ocean_avg_l,2) * poly(solar_radiation,2) + poly(solar_radiation,2) * poly(cost_distance_coast,2) + poly(solar_radiation,2) * as.factor(aspect5_cl8), weights=varComb(varConstPower(form=~slope_5), varPower(form=~tetraterm_total_kor), varConstPower(form=~I(cost_distance_coast* amount_ocean_50200m))), data = skgrMergeF1m2)
skgrMergeF1s <- skgrMergeF1m2[f1sm_gls_full_o2$resid>=100,]
f1sm_gls_full_o2f <- gls(hoh ~ poly(lat,2) * poly(lon,2) + poly(lat,2) * poly(amount_ocean_avg_l,2) + poly(lat,2) * poly(cost_distance_coast,2) + poly(lat,2) * poly(amount_ocean_avg_l,2) * sqrt(sqrt(solar_radiation)) + poly(lat,2) * as.factor(aspect5_cl8) + poly(lon,2) * poly(amount_ocean_avg_l,2)  + poly(lon,2) * poly(cost_distance_coast,2) + poly(amount_ocean_avg_l,2) * poly(cost_distance_coast,2) + poly(amount_ocean_avg_l,2) * sqrt(sqrt(solar_radiation)) + sqrt(sqrt(solar_radiation)) * poly(cost_distance_coast,2) + sqrt(sqrt(solar_radiation)) * as.factor(aspect5_cl8), weights=varComb(varConstPower(form=~slope_5), varPower(form=~tetraterm_total_kor), varConstPower(form=~I(cost_distance_coast* amount_ocean_50200m))), data = skgrMergeF1s)

#ucoast
f_gls_ucoast <- formula(hoh ~ lat * lon + lat * sqrt(amount_ocean_180200m) + lat * solar_radiation + lat * as.factor(aspect5_cl8) + lon * sqrt(amount_ocean_180200m) + lon * solar_radiation + sqrt(amount_ocean_180200m) * solar_radiation + solar_radiation * as.factor(aspect5_cl8))
#ulon
f_gls_ulon <- formula(hoh ~ lat * sqrt(amount_ocean_180200m) + lat * coast_line_distance + lat * solar_radiation + lat * as.factor(aspect5_cl8) + sqrt(amount_ocean_180200m) * coast_line_distance + sqrt(amount_ocean_180200m) * solar_radiation + solar_radiation * coast_line_distance + solar_radiation * as.factor(aspect5_cl8))
#all
f_gls_all <- formula(hoh ~ lat * lon + lat * sqrt(amount_ocean_180200m) + lat * coast_line_distance + lat * solar_radiation + lon * sqrt(amount_ocean_180200m)  + lon * coast_line_distance + sqrt(amount_ocean_180200m) * coast_line_distance + sqrt(amount_ocean_180200m) * solar_radiation + solar_radiation * coast_line_distance + solar_radiation * as.factor(aspect5_cl8))

f1sm_gls_full_ucoast <- gls(f_gls_ucoast, , weights=varComb(varConstPower(form=~slope_5), varPower(form=~tetraterm_total_kor)), method="REML", data = skgrMergeF1)
f1sm_gls_full_ulon <- gls(f_gls_ulon, , weights=varComb(varConstPower(form=~slope_5), varPower(form=~tetraterm_total_kor)), method="REML", data = skgrMergeF1)
f1sm_gls_full_all <- gls(f_gls_all, , weights=varComb(varConstPower(form=~slope_5), varPower(form=~tetraterm_total_kor)), method="REML", data = skgrMergeF1)


test:
1/y
Y^2
sqrt(y)

AIC(f1sm_gls_all,f1sm_gls_ucoast,f1sm_gls_full_ulon,f1sm_gls_full_all_t,f1sm_gls_full_ucoast_t,f1sm_gls_full_ulon_t)


models <- list()
models[[1]] <- f1sm_gls_full_all_t
models[[2]] <- f1sm_gls_full_ulon_t
models[[3]] <- f1sm_gls_full_ucoast_t

names(models) <- c("f1sm_gls_full_ucoast_t", "f1sm_gls_full_ulon_t", "f1sm_gls_full_all_t")

c <- 1
for (m in models) {
mname <- names(models)[c]

fitted_selected <- m$fitted[grep(TRUE, skgrMergeF1$AGDD_2000>0 & skgrMergeF1$actuality>0 & skgrMergeF1$geol_rich>0 & skgrMergeF1$quart_gw>0)]
resid_selected <- m$residuals[grep(TRUE, skgrMergeF1$AGDD_2000>0 & skgrMergeF1$actuality>0 & skgrMergeF1$geol_rich>0 & skgrMergeF1$quart_gw>0)]
skgr <- skgrMergeF1[(skgrMergeF1$AGDD_2000>0 & skgrMergeF1$actuality>0 & skgrMergeF1$geol_rich>0 & skgrMergeF1$quart_gw>0),]

if (file.exists(paste("/home/stefan/Okokart/fin/",mname, sep=""))){
    setwd(paste("/home/stefan/Okokart/fin/",mname, sep=""))
} else {
    dir.create(paste("/home/stefan/Okokart/fin/",mname, sep=""))
    setwd(paste("/home/stefan/Okokart/fin/",mname, sep=""))
}

#plot residuals against all explanatory variables (used and unused)
for (v in 1:length(names(skgr))) {
if(names(skgr)[v]!="GID"&&names(skgr)[v]!="bgr.x"&&names(skgr)[v]!="bgr.y"){
if(names(skgr)[v]!="geol_rich"&&
names(skgr)[v]!="geol_type"&&
names(skgr)[v]!="quart_infilt"&&
names(skgr)[v]!="quart_gw"&&
names(skgr)[v]!="quart_type"&&
names(skgr)[v]!="aspect3_cl8"&&
names(skgr)[v]!="aspect3_cl16"&&
names(skgr)[v]!="aspect5_cl8"&&
names(skgr)[v]!="aspect5_cl16"){
png(paste("/home/stefan/Okokart/fin/",mname,"/Var", "_", names(skgr)[v], "_Modell_", mname, ".png", sep=""), width = 1000, height = 1000, units = "px", pointsize = 24, bg = "white", res = 96, type = c("cairo"))
plot(resid_selected ~ skgr[,v], xlab=names(skgr)[v], ylab=c("Residualer i modell",mname), pch=20, cex=0.2, lwd=2)
lines(lowess(resid_selected ~ skgr[,v], f=0.2), col="red", lwd=2)
dev.off()
} else {
png(paste("/home/stefan/Okokart/fin/",mname,"/Var", "_", names(skgr)[v], "_Modell_", mname, ".png", sep=""), width = 1000, height = 1000, units = "px", pointsize = 24, bg = "white", res = 96, type = c("cairo"))
boxplot(resid_selected ~ skgr[,v], xlab=names(skgr)[v], ylab=c("Residualer i modell",mname), pch=20, cex=0.2, lwd=2)
dev.off()
}
}
}

#plot residuals against Y
png(paste("/home/stefan/Okokart/fin/",mname,"/Residuals_reference_", mname, ".png", sep=""), width = 1000, height = 1000, units = "px", pointsize = 24, bg = "white", res = 96, type = c("cairo"))
plot(resid_selected ~ skgr$hoh, xlab=c("Høyde av referansepunktene for skoggrensen"), ylab=paste("Residualer i modell",mname), pch=20, cex=0.2, lwd=2)
lines(lowess(resid_selected ~ skgr$hoh, f=0.1), col="red", lwd=2)
dev.off()

#plot histogram
png(paste("/home/stefan/Okokart/fin/",mname,"/Residuals_histogram_", mname, ".png", sep=""), width = 1000, height = 1000, units = "px", pointsize = 24, bg = "white", res = 96, type = c("cairo"))
hist(resid_selected, col="grey", breaks=100, xlab=paste("Residualer i modell",mname), ylab="Antall observasjoner", main=NULL, pch=20, cex=0.2, lwd=2)
abline(v=quantile(resid_selected, c(0.10)), col="red", lty=3, lwd=2)
abline(v=quantile(resid_selected, c(0.90)), col="red", lty=3, lwd=2)
legend("topright", c("10% and 90%", "quantiles"), lty=c(3,0), col="red", cex=0.75)
dev.off()

#plot model
png(paste("/home/stefan/Okokart/fin/",mname,"/Modell_", mname, ".png", sep=""), width = 1000, height = 1000, units = "px", pointsize = 24, bg = "white", res = 96, type = c("cairo"))
#plot(m)
plot(resid_selected ~ fitted_selected, xlab=c("Fitted values"), ylab=c("Residualer i modell",mname), pch=20, cex=0.2, lwd=2)
lines(lowess(resid_selected ~ fitted_selected, f=0.2), col="red", lwd=2)
dev.off()

#plot residual values
png(paste("/home/stefan/Okokart/fin/",mname,"/Residuals_map_total_", mname, ".png", sep=""), width = 1000, height = 1000, units = "px", pointsize = 24, bg = "white", res = 96, type = c("cairo"))
zcol <- level.colors((resid_selected), at=c(min(resid_selected), -100, -50, 0, 50, 100, max(resid_selected)), col.regions=colorRampPalette(c("darkgreen", "green", "lightgreen", "yellow", "orange", "red", "darkred")), interpolate = c("linear"))
xyplot(Y ~ X | paste("Residualer i modell", mname), data=skgr, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.1)
legend("bottomright",bty='n',pch=rep(20,7),col=c("darkgreen", "green", "lightgreen", "yellow", "orange", "red", "darkred"),ncol=1,legend=c("<-250m", "-100m", "-50m", "0m", "50m", "100m", ">250m"))
dev.off()

#Plot residuals for overestimated forest line
png(paste("/home/stefan/Okokart/fin/",mname,"/Residuals_map_overestimated_", mname, ".png", sep=""), width = 1000, height = 1000, units = "px", pointsize = 24, bg = "white", res = 96, type = c("cairo"))
zcol <- level.colors(resid_selected[resid_selected<0], at=c(0, -10, -25, -50), col.regions=colorRampPalette(c("yellow", "lightgreen", "green", "darkgreen")), interpolate = c("linear"))
xyplot(Y ~ X | paste("Negative residualer i modell", mname), data=skgr[resid_selected<0,], col=zcol, main="Overestimert skoggrense", aspect = 1, .aspect.ratio = 1, pch=20, cex=0.1)
dev.off()

#Plot residuals for underestimated forest line
png(paste("/home/stefan/Okokart/fin/",mname,"/Residuals_map_underestimated_", mname, ".png", sep=""), width = 1000, height = 1000, units = "px", pointsize = 24, bg = "white", res = 96, type = c("cairo"))
zcol <- level.colors(resid_selected[resid_selected>0], at=c(0, 50, 100, 250), col.regions=colorRampPalette(c("yellow", "orange", "red", "darkred")), interpolate = c("linear"))
xyplot(Y ~ X | paste("Positive residualer i modell", mname), data=skgr[resid_selected>0,], col=zcol, main="Underestimert skoggrense", aspect=1, .aspect.ratio=1, pch=20, cex=0.1)
dev.off()

#plot QQ for GLM / GLS
png(paste("/home/stefan/Okokart/fin/",mname,"/Residuals_QQ_", mname, ".png", sep=""), width = 1000, height = 1000, units = "px", pointsize = 24, bg = "white", res = 96, type = c("cairo"))
plot(fitted_selected ~ skgr$hoh, xlab=c("Høyde av referansepunktene for skoggrensen"), ylab=paste("\"Fitted values\" i modell",mname))
abline(0,1, col="green")
lines(lowess(fitted_selected ~ skgr$hoh, f=0.1), col="red")
legend("bottomright", c("Fitted values"), lty=c(1), col="red")
dev.off()

c <- c + 1
}

######################################################################################################################
#Export to GRASS
f1sm_gls_full_o2_poly2b
f1sm_gls_full_o2_poly2bl

f1sm_gls_full_o2
f1sm_gls_full_o2l
cat(c("r.mapcalc --o --v expression=f1sm_gls_poly=",paste(names(f1sm_gls_full_o2_poly2b$coefficients), " * ", f1sm_gls_full_o2_poly2b$coefficients," + \\\n",sep="")))
cat(c("r.mapcalc --o --v expression=f1sm_gls_poly_l=",paste(names(f1sm_gls_full_o2_poly2bl$coefficients), " * ", f1sm_gls_full_o2_poly2bl$coefficients," + \\\n",sep="")))
cat(c("r.mapcalc --o --v expression=f1sm_gls=",paste(names(f1sm_gls_full_o2$coefficients), " * ", f1sm_gls_full_o2$coefficients," + \\\n",sep="")))
cat(c("r.mapcalc --o --v expression=f1sm_gls_l=",paste(names(f1sm_gls_full_o2l$coefficients), " * ", f1sm_gls_full_o2l$coefficients," + \\\n",sep="")))

f1sm_gls_full_o2f

#Print model summary
#textplot(summary(m))

#text_output <- paste("Model: ", mname)
#text_output <- append(text_output, paste("Call: ", toString(summary(m)$call)))
#text_output <- append(text_output, paste("F-statistic: ", toString(summary(m)$fstatistic)))
#text_output <- append(text_output, paste("Adj. R squared: ", toString(summary(m)$adj.r.squared)))
#textplot(text_output)
#textplot(summary(m)$coefficients)

# quant_cut <- cut(m$residuals, breaks=quantile(m$residuals,c(0,0.1, 0.25,0.75,0.9,1.0),include.lowest=TRUE,labels=FALSE))
# hoh_cols <- c("darkgreen", "green", "lightgreen", "yellow", "orange", "red", "darkred")
# hoh_col_ramp <- hoh_cols[quant_cut]

# png(paste("/home/stefan/Okokart/fin/",mname,"/Residuals_total_", mname, ".png", sep=""), width = 1000, height = 1000, units = "px", pointsize = 24, bg = "white", res = 96, type = c("cairo"))
# xyplot(Y ~ X | paste("Residualer i modell", mname), data=skgrMergeF1, col=hoh_col_ramp, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.1)
# dev.off()


m <- f1sm_gls_slope5
zcol <- level.colors((m$resid), at=c(min(m$residuals), -100, -50, 0, 50, 100, max(m$residuals)), col.regions=colorRampPalette(c("darkgreen", "green", "lightgreen", "yellow", "orange", "red", "darkred")), interpolate = c("linear"))
xyplot(Y ~ X | paste("Residualer i modell", mname), data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.1)

#Spatial autocorrelation
#GLS with correlation
#grouped by gid
count <- 1
for (g in unique(skgrMergeF1$GID)) {
skgrMergeF1$gid[skgrMergeF1$GID==g] <- count
count <- count + 1
}

balancedcluster(skgrMergeF1,m,cluster,selection=1,comment=TRUE,method=1)
#reduced dataset using random sampling ()
skgrMergeF1[ sample( which(skgrMergeF1$gid), 3 ), ]

mname <- "f1sm_gls_slope5"
ci <- confint(f1sm_gls_slope5)


skgrMergeF1$hoh ~ skgrMergeF1$lat * skgrMergeF1$lon + skgrMergeF1$lat * skgrMergeF1$amount_ocean_180200m + skgrMergeF1$lat * skgrMergeF1$solar_radiation + skgrMergeF1$lon * skgrMergeF1$amount_ocean_180200m + skgrMergeF1$lon * skgrMergeF1$solar_radiation + skgrMergeF1$amount_ocean_180200m * skgrMergeF1$solar_radiation + skgrMergeF1$solar_radiation * as.factor(skgrMergeF1$aspect5_cl8)

abline_test <- try(abline((f1sm_glm_sqrt[2]+f1sm_glm_sqrt$coefficients[1]), f1sm_glm_sqrt$coefficients[2], col="Red", lty=2, family="mono"), silent=TRUE) # 1. quartil
abline_test <- try(abline((test[5]+test_glm$coefficients[1]), test_glm$coefficients[2], col="Red", lty=2, family="mono"), silent=TRUE) # 3. quartil
abline_test <- try(abline(ci[1], ci[2], col="red", lty=3, family="mono"), silent=TRUE) # 2.5% confidence intervall
abline_test <- try(abline(ci[3], ci[4], col="red", lty=3, family="mono"), silent=TRUE) # 97.5% confidence intervall


#Confidence intervalls
#Prediction test intervalls


plot(f1sm7a$residuals ~ skgrMergeF1t$hoh)
plot(f1sm7$residuals ~ skgrMergeF1t$lat)
plot(f1sm7$residuals ~ skgrMergeF1t$lon)
plot(f1sm7$residuals ~ skgrMergeF1t$coast_line_distance)


#Plot residuals for overestimated forest line
png('/home/stefan/Okokart/Modelling_residuals_underestimated_F1_M3.png', width = 5000, height = 5000, units = "px", pointsize = 12, bg = "white", res = 10, type = c("cairo"))
zcol <- level.colors(f1sm3$resid[f1sm3$resid<0], at=c(0, -10, -25, -50, -75, -100, -150, -200, -500), col.regions=colorRampPalette(c("yellow", "green", "cyan", "blue", "purple", "red")), interpolate = c("linear"))
xyplot(Y ~ X | "Negative residuals of model f1sm3", data=skgrMergeF1[f1sm3$resid<0,], col=zcol, aspect = 1, .aspect.ratio = 1)
dev.off()

#Plot residuals for underestimated forest line
png('/home/stefan/Okokart/Modelling_residuals_overestimated_F1_M3.png', width = 5000, height = 5000, units = "px", pointsize = 12, bg = "white", res = 10, type = c("cairo"))
zcol <- level.colors(f1sm3$resid[f1sm3$resid>0], at=c(0, 10, 25, 50, 75, 100, 150, 200, 500), col.regions=colorRampPalette(c("yellow", "green", "cyan", "blue", "purple", "red")), interpolate = c("linear"))
xyplot(Y ~ X | "Negative residuals of model f1sm3", data=skgrMergeF1[f1sm3$resid>0,], col=zcol, aspect = 1, .aspect.ratio = 1)
dev.off()

#Simplify model using forward and backward stepAIC
stepAIC(f1sm7)

#Make model validation plots
plot(f1sm3)
test <- predict(f1sm3, skgrm)
summary(test)
xyplot(test ~ )

#Test confidence intervalls
ci <- confint(f1sm3)


#plot fitted values for model 1
png('/home/stefan/Okokart/Modelling_fitted_values_F1t_M3.png', width = 5000, height = 5000, units = "px", pointsize = 12, bg = "white", res = 10, type = c("cairo"))
zcol <- level.colors(f1sm3$fitted, at = c(-1000, 0, 100, 200, 300, 400, 500, 600, 700, 800, 900, 1000, 1100, 1200), col.regions=terrain.colors(13), interpolate = c("linear"))
xyplot(Y ~ X | "Fitted values of model f1sm3", data=skgrMergeF1, col = zcol, aspect = 1, .aspect.ratio = 1)
dev.off()

#plot residual values for model 1
png('/home/stefan/Okokart/Modelling_residuals_F1t_M1.png', width = 5000, height = 5000, units = "px", pointsize = 12, bg = "white", res = 10, type = c("cairo"))
zcol <- level.colors((f1sm3$resid), at=c(-650, -200, -100, -50, 0, 50, 100, 200, 1080), col.regions=colorRampPalette(c("darkred", "red", "orange", "yellow", "lightgreen", "green", "darkgreen")))
xyplot(Y ~ X | "Residuals of model f1sm3", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1)
dev.off()


png('/home/stefan/Okokart/Modelling_altitude_predict_all.png', width = 5000, height = 5000, units = "px", pointsize = 12, bg = "white", res = 10, type = c("cairo"))
zcol <- level.colors(test, at = c(0, 50, 100, 150, 200, 250, 300, 350, 400, 450, 500, 550, 600, 650, 700, 750, 800, 850, 900, 950, 1000, 1050, 1100, 1150, 1200, 1250, 1300), col.regions=terrain.colors(27), interpolate=c("linear"))
xyplot(Y ~ X | "Altitude of reference points in filter 1 step 7a", data=skgrm, col=zcol, aspect = 1, .aspect.ratio = 1)
dev.off()

png('/home/stefan/Okokart/Modelling_altitude_fjelltest_all.png', width = 5000, height = 5000, units = "px", pointsize = 12, bg = "white", res = 10, type = c("cairo"))
zcol <- level.colors(I(skgrm$hoh-test), at = c(-9999, -1, 0, 9999), col.regions=colorRampPalette(c("yellow", "blue", "red")))
xyplot(Y ~ X | "Altitude of reference points in filter 1 step 7a", data=skgrm, col=zcol, aspect = 1, .aspect.ratio = 1)
dev.off()


#####################################################################################
#Make data exploration plots
cat_val <- c("actuality", "geol_rich", "geol_type", "quart_gw", "quart_infilt", "quart_type", "aspect_cl8", "aspect3_cl8", "aspect5_cl8", "aspect3_cl16", "aspect5_cl16")
folder <- '/home/stefan/Okokart/'
for(evar in names(skgrMergeF1)) {
skgrMergeF1[grep(evar, names(skgrMergeF1))][skgrMergeF1[grep(evar, names(skgrMergeF1))]==-9999] <- NA
}

ps_file <- paste(folder, "Data_exploration_F1.ps", sep="")

postscript(ps_file, horizontal=TRUE, paper="a4", family="mono")
op <- par(mfrow=c(2,2), family="mono")

for(evar in names(skgrMergeF1)) {
if((evar=="bgr.x")==FALSE&(evar=="bgr.y")==FALSE&(evar=="dem_1km_avg.y")==FALSE&(evar=="forest_patch")==FALSE&(evar=="GID")==FALSE) {

if(evar %in% cat_val) {
#Calculate simple linear regression for the single explanatory variable
test_glm <- lm(skgrMergeF1$hoh ~ as.factor(unlist(skgrMergeF1[grep(evar, names(skgrMergeF1))])))
#Plot explainatory variable against response variable along with a regression line 
beanplot_test <- try(beanplot(skgrMergeF1$hoh ~ as.factor(unlist(skgrMergeF1[grep(evar, names(skgrMergeF1))])), horizontal=FALSE, log="", las=1, outline=FALSE, ylab="hoh", xlab=evar, what=c(1,1,1,0), main=c(paste("Beanplot of ", evar), " against hoh")), silent=TRUE)
#if(is.list(beanplot_test)) {
#beanplot(skgrMergeF1$hoh ~ as.factor(unlist(skgrMergeF1[grep(evar, names(skgrMergeF1))])), horizontal=FALSE, log="", las=1, outline=FALSE, ylab="hoh", xlab=evar, what=c(1,1,1,0), main=c(paste("Beanplot of ", evar), " against hoh"))
#}
if(is.list(beanplot_test)==FALSE) {
boxplot(skgrMergeF1$hoh ~ as.factor(unlist(skgrMergeF1[grep(evar, names(skgrMergeF1))])), horizontal=FALSE, log="", las=1, outline=FALSE, ylab="hoh", xlab=evar, main=c(paste("Boxplot of ", evar), " against hoh"))
}
lines(test_glm$coefficients ~ as.factor(test_glm$xlevels[[1]]), col="red", family="mono")
#Plot histogram of explainatory variable
hist(unlist(skgrMergeF1[evar]), xlab=evar, main=c("Histogram of", evar), family="mono")
#Print model summary
text_output <- paste("Explanatory variavble: ", evar)
text_output <- append(text_output, paste("Call: ", toString(summary(test_glm)$call)))
text_output <- append(text_output, paste("F-statistic: ", toString(summary(test_glm)$fstatistic)))
text_output <- append(text_output, paste("Adj. R squared: ", toString(summary(test_glm)$adj.r.squared)))
textplot(text_output)
}

if((evar %in% cat_val)==FALSE) {
#Calculate simple linear regression for the single explanatory variable
test_glm <- lm(skgrMergeF1$hoh ~ unlist(skgrMergeF1[evar]))
#Plot explainatory variable against response variable along with a regression line, confidence intervalls and 1. and 3. quartil
plot(skgrMergeF1$hoh ~ unlist(skgrMergeF1[evar]), family="mono", xlab=evar, ylab="hoh", , main=c(paste("XY-plot of ", evar), " against hoh with linear regression 'test-GLM'"))
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
hist(unlist(skgrMergeF1[evar]), xlab=evar, main=c("Histogram of", evar), family="mono")
#Print model summary
textplot(capture.output(summary(test_glm)), family="mono")
}

#Plot residuals of a linear regression against respons variable
E <- resid(test_glm)#henter ut residualene i modellen din
EAll <- vector(length=length(skgrMergeF1$hoh))#lager en vector som er like lang som vektoren hoh
EAll[] <- NA#fyller inn med NA der det er tomt i E-vektoren
I1 <- !is.na(skgrMergeF1$hoh) #fyller inn med NA der det er tomt i E-vektoren
EAll[I1] <- E#fyller inn med NA der det er tomt i E-vektoren
plot(skgrMergeF1$hoh,EAll, xlab="hoh", ylab="residuals", family="mono", main=paste("XY-plot of test-GLMs residuals against hoh"))

}
} 
par(op)
dev.off()
#####################################################################################



AICs <- list()
summaries <- list()

f1sm7 <- lm(hoh ~ lat + lon + coast_line_distance + solar_radiation, data=skgrMergeF1)
summaries[["lat_lon_cld_sol"]] <- summary(f1sm7$residuals)
AICs[["lat_lon_cld_sol"]] <- AIC(f1sm7)

f1sm7 <- lm(hoh ~ lat + lon + coast_line_distance + solar_radiation + slope_5, data=skgrMergeF1)
summaries[["lat_lon_cld_sol_slope_5"]] <- summary(f1sm7$residuals)
AICs[["lat_lon_cld_sol_slope_5"]] <- AIC(f1sm7)

f1sm7 <- lm(hoh ~ lat + lon + coast_line_distance + solar_radiation + slope_5 + as.factor(aspect5_cl16), data=skgrMergeF1)
summaries[["lat_lon_cld_sol_slope_5_aspect"]] <- summary(f1sm7$residuals)
AICs[["lat_lon_cld_sol_slope_5_aspect"]] <- AIC(f1sm7)

f1sm7 <- lm(hoh ~ lat + lon + coast_line_distance + solar_radiation + slope_5 + amount_ocean_100200m + amount_ocean_50200m + amount_ocean_25000m + amount_ocean_10100m + amount_ocean_5050m + as.factor(aspect5_cl16), data=skgrMergeF1)
summaries[["lat_lon_cld_sol_slope_5_aspect_amount"]] <- summary(f1sm7$residuals)
AICs[["lat_lon_cld_sol_slope_5_aspect_amount"]] <- AIC(f1sm7)

f1sm7 <- lm(hoh ~ lat + lon + coast_line_distance + solar_radiation + slope_5 + amount_ocean_100200m + amount_ocean_50200m + amount_ocean_25000m + amount_ocean_10100m + amount_ocean_5050m + as.factor(aspect5_cl16) + as.factor(geol_rich) + as.factor(quart_gw), data=skgrMergeF1)
summaries[["lat_lon_cld_sol_slope_5_aspect_amount_geol"]] <- summary(f1sm7$residuals)
AICs[["lat_lon_cld_sol_slope_5_aspect_amount_geol"]] <- AIC(f1sm7)

f1sm7 <- lm(hoh ~ lat + lon + coast_line_distance + solar_radiation + slope_3, data=skgrMergeF1)
summaries[["lat_lon_cld_sol_slope_3"]] <- summary(f1sm7$residuals)
AICs[["lat_lon_cld_sol_slope_3"]] <- AIC(f1sm7)

f1sm7 <- lm(hoh ~ lat + lon + coast_line_distance + solar_radiation + slope_3 + as.factor(aspect5_cl16), data=skgrMergeF1)
summaries[["lat_lon_cld_sol_slope_3_aspect"]] <- summary(f1sm7$residuals)
AICs[["lat_lon_cld_sol_slope_3_aspect"]] <- AIC(f1sm7)

f1sm7 <- lm(hoh ~ lat + lon + coast_line_distance + solar_radiation + slope_3 + amount_ocean_100200m + amount_ocean_50200m + amount_ocean_25000m + amount_ocean_10100m + amount_ocean_5050m + as.factor(aspect5_cl16), data=skgrMergeF1)
summaries[["lat_lon_cld_sol_slope_3_aspect_amount"]] <- summary(f1sm7$residuals)
AICs[["lat_lon_cld_sol_slope_3_aspect_amount"]] <- AIC(f1sm7)

f1sm7 <- lm(hoh ~ lat + lon + log(coast_line_distance) + solar_radiation + slope_3 + amount_ocean_100200m + amount_ocean_50200m + amount_ocean_25000m + amount_ocean_10100m + amount_ocean_5050m + as.factor(aspect5_cl16) + as.factor(geol_rich) + as.factor(quart_gw), data=skgrMergeF1)
summaries[["lat_lon_log(cld)_sol_slope_3_aspect_amount_geol"]] <- summary(f1sm7$residuals)
AICs[["lat_lon_log(cld)_sol_slope_3_aspect_amount_geol"]] <- AIC(f1sm7)

f1sm7 <- lm(hoh ~ lat * lon + lat * log(coast_line_distance) + lon * log(coast_line_distance) + lat * sqrt(amount_ocean_100200m) + lon * sqrt(amount_ocean_100200m) + log(coast_line_distance) * sqrt(amount_ocean_100200m) + lat * sqrt(amount_ocean_50200m) + lon * sqrt(amount_ocean_50200m) + log(coast_line_distance) * sqrt(amount_ocean_50200m) + lat * sqrt(amount_ocean_25000m) + lon * sqrt(amount_ocean_25000m) + log(coast_line_distance) * sqrt(amount_ocean_25000m) + lat * sqrt(amount_ocean_10100m) + lon * sqrt(amount_ocean_10100m) + log(coast_line_distance) * sqrt(amount_ocean_10100m) + lat * sqrt(amount_ocean_5050m) + lon * sqrt(amount_ocean_5050m) + log(coast_line_distance) * sqrt(amount_ocean_5050m) + lat * slope_5 + lon * slope_5 + slope_5 * I(solar_radiation^2) + lat * I(solar_radiation^2) + lon * I(solar_radiation^2) + as.factor(aspect5_cl16) * I(solar_radiation^2) + as.factor(aspect5_cl16) * log(coast_line_distance) + as.factor(aspect5_cl16) * slope_5 + lat * as.factor(geol_rich) + lat * as.factor(quart_gw) + lon * as.factor(quart_gw) + lat * TPI_110m + log(coast_line_distance) * TPI_110m + lat * TWI +lon * TWI, data = skgrMergeF1)
summaries[["lat_sqrt_amount_log_dist"]] <- summary(f1sm7$residuals)
AICs[["lat_sqrt_amount_log_dist"]] <- AIC(f1sm7)

f1sm7 <- lm(hoh ~ lat_tan * lon + lat_tan * log(coast_line_distance) + lon * log(coast_line_distance) + lat_tan * sqrt(amount_ocean_100200m) + lon * sqrt(amount_ocean_100200m) + log(coast_line_distance) * sqrt(amount_ocean_100200m) + lat_tan * sqrt(amount_ocean_50200m) + lon * sqrt(amount_ocean_50200m) + log(coast_line_distance) * sqrt(amount_ocean_50200m) + lat_tan * sqrt(amount_ocean_25000m) + lon * sqrt(amount_ocean_25000m) + log(coast_line_distance) * sqrt(amount_ocean_25000m) + lat_tan * sqrt(amount_ocean_10100m) + lon * sqrt(amount_ocean_10100m) + log(coast_line_distance) * sqrt(amount_ocean_10100m) + lat_tan * sqrt(amount_ocean_5050m) + lon * sqrt(amount_ocean_5050m) + log(coast_line_distance) * sqrt(amount_ocean_5050m) + lat_tan * slope_5 + lon * slope_5 + slope_5 * I(solar_radiation^2) + lat_tan * I(solar_radiation^2) + lon * I(solar_radiation^2) + as.factor(aspect5_cl16) * I(solar_radiation^2) + as.factor(aspect5_cl16) * log(coast_line_distance) + as.factor(aspect5_cl16) * slope_5 + lat_tan * as.factor(geol_rich) + lat_tan * as.factor(quart_gw) + lon * as.factor(quart_gw) + lat_tan * TPI_110m + log(coast_line_distance) * TPI_110m + lat_tan * TWI + lon * TWI, data = skgrMergeF1)
summaries[["lat_tan_sqrt_amount_log_dist"]] <- summary(f1sm7$residuals)
AICs[["lat_tan_sqrt_amount_log_dist"]] <- AIC(f1sm7)

f1sm7 <- lm(hoh ~ exp(lat_tan) * lon + exp(lat_tan) * log(coast_line_distance) + lon * log(coast_line_distance) + exp(lat_tan) * sqrt(amount_ocean_100200m) + lon * sqrt(amount_ocean_100200m) + log(coast_line_distance) * sqrt(amount_ocean_100200m) + exp(lat_tan) * sqrt(amount_ocean_50200m) + lon * sqrt(amount_ocean_50200m) + log(coast_line_distance) * sqrt(amount_ocean_50200m) + exp(lat_tan) * sqrt(amount_ocean_25000m) + lon * sqrt(amount_ocean_25000m) + log(coast_line_distance) * sqrt(amount_ocean_25000m) + exp(lat_tan) * sqrt(amount_ocean_10100m) + lon * sqrt(amount_ocean_10100m) + log(coast_line_distance) * sqrt(amount_ocean_10100m) + exp(lat_tan) * sqrt(amount_ocean_5050m) + lon * sqrt(amount_ocean_5050m) + log(coast_line_distance) * sqrt(amount_ocean_5050m) + exp(lat_tan) * slope_5 + lon * slope_5 + slope_5 * I(solar_radiation^2) + exp(lat_tan) * I(solar_radiation^2) + lon * I(solar_radiation^2) + as.factor(aspect5_cl16) * I(solar_radiation^2) + as.factor(aspect5_cl16) * log(coast_line_distance) + as.factor(aspect5_cl16) * slope_5 + exp(lat_tan) * as.factor(geol_rich) + exp(lat_tan) * as.factor(quart_gw) + lon * as.factor(quart_gw) + exp(lat_tan) * TPI_110m + log(coast_line_distance) * TPI_110m + exp(lat_tan) * TWI + lon * TWI, data = skgrMergeF1)
summaries[["exp(lat_tan)_sqrt_amount_log_dist"]] <- summary(f1sm7$residuals)
AICs[["exp(lat_tan)_sqrt_amount_log_dist"]] <- AIC(f1sm7)

f1sm7 <- lm(hoh ~ lat_tan_e2 * lon + lat_tan_e2 * log(coast_line_distance) + lon * log(coast_line_distance) + lat_tan_e2 * sqrt(amount_ocean_100200m) + lon * sqrt(amount_ocean_100200m) + log(coast_line_distance) * sqrt(amount_ocean_100200m) + lat_tan_e2 * sqrt(amount_ocean_50200m) + lon * sqrt(amount_ocean_50200m) + log(coast_line_distance) * sqrt(amount_ocean_50200m) + lat_tan_e2 * sqrt(amount_ocean_25000m) + lon * sqrt(amount_ocean_25000m) + log(coast_line_distance) * sqrt(amount_ocean_25000m) + lat_tan_e2 * sqrt(amount_ocean_10100m) + lon * sqrt(amount_ocean_10100m) + log(coast_line_distance) * sqrt(amount_ocean_10100m) + lat_tan_e2 * sqrt(amount_ocean_5050m) + lon * sqrt(amount_ocean_5050m) + log(coast_line_distance) * sqrt(amount_ocean_5050m) + lat_tan_e2 * slope_5 + lon * slope_5 + slope_5 * I(solar_radiation^2) + lat_tan_e2 * I(solar_radiation^2) + lon * I(solar_radiation^2) + as.factor(aspect5_cl16) * I(solar_radiation^2) + as.factor(aspect5_cl16) * log(coast_line_distance) + as.factor(aspect5_cl16) * slope_5 + lat_tan_e2 * as.factor(geol_rich) + lat_tan_e2 * as.factor(quart_gw) + lon * as.factor(quart_gw) + lat_tan_e2 * TPI_110m + log(coast_line_distance) * TPI_110m + lat_tan_e2 * TWI + lon * TWI, data = skgrMergeF1)
summaries[["lat_tan_e2_sqrt_amount_log_dist"]] <- summary(f1sm7$residuals)
AICs[["lat_tan_e2_sqrt_amount_log_dist"]] <- AIC(f1sm7)

f1sm7 <- lm(hoh ~ lat_tan_e3 * lon + lat_tan_e3 * log(coast_line_distance) + lon * log(coast_line_distance) + lat_tan_e3 * sqrt(amount_ocean_100200m) + lon * sqrt(amount_ocean_100200m) + log(coast_line_distance) * sqrt(amount_ocean_100200m) + lat_tan_e3 * sqrt(amount_ocean_50200m) + lon * sqrt(amount_ocean_50200m) + log(coast_line_distance) * sqrt(amount_ocean_50200m) + lat_tan_e3 * sqrt(amount_ocean_25000m) + lon * sqrt(amount_ocean_25000m) + log(coast_line_distance) * sqrt(amount_ocean_25000m) + lat_tan_e3 * sqrt(amount_ocean_10100m) + lon * sqrt(amount_ocean_10100m) + log(coast_line_distance) * sqrt(amount_ocean_10100m) + lat_tan_e3 * sqrt(amount_ocean_5050m) + lon * sqrt(amount_ocean_5050m) + log(coast_line_distance) * sqrt(amount_ocean_5050m) + lat_tan_e3 * slope_5 + lon * slope_5 + slope_5 * I(solar_radiation^2) + lat_tan_e3 * I(solar_radiation^2) + lon * I(solar_radiation^2) + as.factor(aspect5_cl16) * I(solar_radiation^2) + as.factor(aspect5_cl16) * log(coast_line_distance) + as.factor(aspect5_cl16) * slope_5 + lat_tan_e3 * as.factor(geol_rich) + lat_tan_e3 * as.factor(quart_gw) + lon * as.factor(quart_gw) + lat_tan_e3 * TPI_110m + log(coast_line_distance) * TPI_110m + lat_tan_e3 * TWI + lon * TWI, data = skgrMergeF1)
summaries[["lat_tan_e3_sqrt_amount_log_dist"]] <- summary(f1sm7$residuals)
AICs[["lat_tan_e3_sqrt_amount_log_dist"]] <- AIC(f1sm7)

f1sm7 <- lm(hoh ~ lat_tan_e4 * lon + lat_tan_e4 * log(coast_line_distance) + lon * log(coast_line_distance) + lat_tan_e4 * sqrt(amount_ocean_100200m) + lon * sqrt(amount_ocean_100200m) + log(coast_line_distance) * sqrt(amount_ocean_100200m) + lat_tan_e4 * sqrt(amount_ocean_50200m) + lon * sqrt(amount_ocean_50200m) + log(coast_line_distance) * sqrt(amount_ocean_50200m) + lat_tan_e4 * sqrt(amount_ocean_25000m) + lon * sqrt(amount_ocean_25000m) + log(coast_line_distance) * sqrt(amount_ocean_25000m) + lat_tan_e4 * sqrt(amount_ocean_10100m) + lon * sqrt(amount_ocean_10100m) + log(coast_line_distance) * sqrt(amount_ocean_10100m) + lat_tan_e4 * sqrt(amount_ocean_5050m) + lon * sqrt(amount_ocean_5050m) + log(coast_line_distance) * sqrt(amount_ocean_5050m) + lat_tan_e4 * slope_5 + lon * slope_5 + slope_5 * I(solar_radiation^2) + lat_tan_e4 * I(solar_radiation^2) + lon * I(solar_radiation^2) + as.factor(aspect5_cl16) * I(solar_radiation^2) + as.factor(aspect5_cl16) * log(coast_line_distance) + as.factor(aspect5_cl16) * slope_5 + lat_tan_e4 * as.factor(geol_rich) + lat_tan_e4 * as.factor(quart_gw) + lon * as.factor(quart_gw) + lat_tan_e4 * TPI_110m + log(coast_line_distance) * TPI_110m + lat_tan_e4 * TWI + lon * TWI, data = skgrMergeF1)
summaries[["lat_tan_e4_sqrt_amount_log_dist"]] <- summary(f1sm7$residuals)
AICs[["lat_tan_e4_sqrt_amount_log_dist"]] <- AIC(f1sm7)

f1sm7 <- lm(hoh ~ lat_tan_e5 * lon + lat_tan_e5 * log(coast_line_distance) + lon * log(coast_line_distance) + lat_tan_e5 * sqrt(amount_ocean_100200m) + lon * sqrt(amount_ocean_100200m) + log(coast_line_distance) * sqrt(amount_ocean_100200m) + lat_tan_e5 * sqrt(amount_ocean_50200m) + lon * sqrt(amount_ocean_50200m) + log(coast_line_distance) * sqrt(amount_ocean_50200m) + lat_tan_e5 * sqrt(amount_ocean_25000m) + lon * sqrt(amount_ocean_25000m) + log(coast_line_distance) * sqrt(amount_ocean_25000m) + lat_tan_e5 * sqrt(amount_ocean_10100m) + lon * sqrt(amount_ocean_10100m) + log(coast_line_distance) * sqrt(amount_ocean_10100m) + lat_tan_e5 * sqrt(amount_ocean_5050m) + lon * sqrt(amount_ocean_5050m) + log(coast_line_distance) * sqrt(amount_ocean_5050m) + lat_tan_e5 * slope_5 + lon * slope_5 + slope_5 * I(solar_radiation^2) + lat_tan_e5 * I(solar_radiation^2) + lon * I(solar_radiation^2) + as.factor(aspect5_cl16) * I(solar_radiation^2) + as.factor(aspect5_cl16) * log(coast_line_distance) + as.factor(aspect5_cl16) * slope_5 + lat_tan_e5 * as.factor(geol_rich) + lat_tan_e5 * as.factor(quart_gw) + lon * as.factor(quart_gw) + lat_tan_e5 * TPI_110m + log(coast_line_distance) * TPI_110m + lat_tan_e5 * TWI + lon * TWI, data = skgrMergeF1)
f1sm5 <- lm(hoh ~ lat_tan_e5 * lon + lat_tan_e5 * log(coast_line_distance) + lon * log(coast_line_distance) + lat_tan_e5 * log(amount_ocean_100200m) + lon * log(amount_ocean_100200m) + log(coast_line_distance) * log(amount_ocean_100200m) + lat_tan_e5 * log(amount_ocean_50200m) + lon * log(amount_ocean_50200m) + log(coast_line_distance) * log(amount_ocean_50200m) + lat_tan_e5 * log(amount_ocean_25000m) + lon * log(amount_ocean_25000m) + log(coast_line_distance) * log(amount_ocean_25000m) + lat_tan_e5 * log(amount_ocean_10100m) + lon * log(amount_ocean_10100m) + log(coast_line_distance) * log(amount_ocean_10100m) + lat_tan_e5 * log(amount_ocean_5050m) + lon * log(amount_ocean_5050m) + log(coast_line_distance) * log(amount_ocean_5050m) + lat_tan_e5 * slope_5 + lon * slope_5 + slope_5 * I(solar_radiation^2) + lat_tan_e5 * I(solar_radiation^2) + lon * I(solar_radiation^2) + as.factor(aspect5_cl16) * I(solar_radiation^2) + as.factor(aspect5_cl16) * log(coast_line_distance) + as.factor(aspect5_cl16) * slope_5 + lat_tan_e5 * as.factor(geol_rich) + lat_tan_e5 * as.factor(quart_gw) + lon * as.factor(quart_gw) + lat_tan_e5 * TPI_110m + log(coast_line_distance) * TPI_110m + lat_tan_e5 * TWI + lon * TWI, data = skgrMergeF1)
AIC(f1sm7,f1sm5)
summaries[["lat_tan_e5_sqrt_amount_log_dist"]] <- summary(f1sm7$residuals)
AICs[["lat_tan_e5_sqrt_amount_log_dist"]] <- AIC(f1sm7)

f1sm7 <- lm(hoh ~ lat_tan_e6 * lon + lat_tan_e6 * log(coast_line_distance) + lon * log(coast_line_distance) + lat_tan_e6 * sqrt(amount_ocean_100200m) + lon * sqrt(amount_ocean_100200m) + log(coast_line_distance) * sqrt(amount_ocean_100200m) + lat_tan_e6 * sqrt(amount_ocean_50200m) + lon * sqrt(amount_ocean_50200m) + log(coast_line_distance) * sqrt(amount_ocean_50200m) + lat_tan_e6 * sqrt(amount_ocean_25000m) + lon * sqrt(amount_ocean_25000m) + log(coast_line_distance) * sqrt(amount_ocean_25000m) + lat_tan_e6 * sqrt(amount_ocean_10100m) + lon * sqrt(amount_ocean_10100m) + log(coast_line_distance) * sqrt(amount_ocean_10100m) + lat_tan_e6 * sqrt(amount_ocean_5050m) + lon * sqrt(amount_ocean_5050m) + log(coast_line_distance) * sqrt(amount_ocean_5050m) + lat_tan_e6 * slope_5 + lon * slope_5 + slope_5 * I(solar_radiation^2) + lat_tan_e6 * I(solar_radiation^2) + lon * I(solar_radiation^2) + as.factor(aspect5_cl16) * I(solar_radiation^2) + as.factor(aspect5_cl16) * log(coast_line_distance) + as.factor(aspect5_cl16) * slope_5 + lat_tan_e6 * as.factor(geol_rich) + lat_tan_e6 * as.factor(quart_gw) + lon * as.factor(quart_gw) + lat_tan_e6 * TPI_110m + log(coast_line_distance) * TPI_110m + lat_tan_e6 * TWI + lon * TWI, data = skgrMergeF1)
summaries[["lat_tan_e6_sqrt_amount_log_dist"]] <- summary(f1sm7$residuals)
AICs[["lat_tan_e6_sqrt_amount_log_dist"]] <- AIC(f1sm7)

f1sm7 <- lm(hoh ~ lat_tan_e7 * lon + lat_tan_e7 * log(coast_line_distance) + lon * log(coast_line_distance) + lat_tan_e7 * sqrt(amount_ocean_100200m) + lon * sqrt(amount_ocean_100200m) + log(coast_line_distance) * sqrt(amount_ocean_100200m) + lat_tan_e7 * sqrt(amount_ocean_50200m) + lon * sqrt(amount_ocean_50200m) + log(coast_line_distance) * sqrt(amount_ocean_50200m) + lat_tan_e7 * sqrt(amount_ocean_25000m) + lon * sqrt(amount_ocean_25000m) + log(coast_line_distance) * sqrt(amount_ocean_25000m) + lat_tan_e7 * sqrt(amount_ocean_10100m) + lon * sqrt(amount_ocean_10100m) + log(coast_line_distance) * sqrt(amount_ocean_10100m) + lat_tan_e7 * sqrt(amount_ocean_5050m) + lon * sqrt(amount_ocean_5050m) + log(coast_line_distance) * sqrt(amount_ocean_5050m) + lat_tan_e7 * slope_5 + lon * slope_5 + slope_5 * I(solar_radiation^2) + lat_tan_e7 * I(solar_radiation^2) + lon * I(solar_radiation^2) + as.factor(aspect5_cl16) * I(solar_radiation^2) + as.factor(aspect5_cl16) * log(coast_line_distance) + as.factor(aspect5_cl16) * slope_5 + lat_tan_e7 * as.factor(geol_rich) + lat_tan_e7 * as.factor(quart_gw) + lon * as.factor(quart_gw) + lat_tan_e7 * TPI_110m + log(coast_line_distance) * TPI_110m + lat_tan_e7 * TWI + lon * TWI, data = skgrMergeF1)
summaries[["lat_tan_e7_sqrt_amount_log_dist"]] <- summary(f1sm7$residuals)
AICs[["lat_tan_e7_sqrt_amount_log_dist"]] <- AIC(f1sm7)

f1sm7 <- lm(hoh ~ lat_tan_e8 * lon + lat_tan_e8 * log(coast_line_distance) + lon * log(coast_line_distance) + lat_tan_e8 * sqrt(amount_ocean_100200m) + lon * sqrt(amount_ocean_100200m) + log(coast_line_distance) * sqrt(amount_ocean_100200m) + lat_tan_e8 * sqrt(amount_ocean_50200m) + lon * sqrt(amount_ocean_50200m) + log(coast_line_distance) * sqrt(amount_ocean_50200m) + lat_tan_e8 * sqrt(amount_ocean_25000m) + lon * sqrt(amount_ocean_25000m) + log(coast_line_distance) * sqrt(amount_ocean_25000m) + lat_tan_e8 * sqrt(amount_ocean_10100m) + lon * sqrt(amount_ocean_10100m) + log(coast_line_distance) * sqrt(amount_ocean_10100m) + lat_tan_e8 * sqrt(amount_ocean_5050m) + lon * sqrt(amount_ocean_5050m) + log(coast_line_distance) * sqrt(amount_ocean_5050m) + lat_tan_e8 * slope_5 + lon * slope_5 + slope_5 * I(solar_radiation^2) + lat_tan_e8 * I(solar_radiation^2) + lon * I(solar_radiation^2) + as.factor(aspect5_cl16) * I(solar_radiation^2) + as.factor(aspect5_cl16) * log(coast_line_distance) + as.factor(aspect5_cl16) * slope_5 + lat_tan_e8 * as.factor(geol_rich) + lat_tan_e8 * as.factor(quart_gw) + lon * as.factor(quart_gw) + lat_tan_e8 * TPI_110m + log(coast_line_distance) * TPI_110m + lat_tan_e8 * TWI + lon * TWI, data = skgrMergeF1)
summaries[["lat_tan_e8_sqrt_amount_log_dist"]] <- summary(f1sm7$residuals)
AICs[["lat_tan_e8_sqrt_amount_log_dist"]] <- AIC(f1sm7)

f1sm7 <- lm(hoh ~ lat_tan_e9 * lon + lat_tan_e9 * log(coast_line_distance) + lon * log(coast_line_distance) + lat_tan_e9 * sqrt(amount_ocean_100200m) + lon * sqrt(amount_ocean_100200m) + log(coast_line_distance) * sqrt(amount_ocean_100200m) + lat_tan_e9 * sqrt(amount_ocean_50200m) + lon * sqrt(amount_ocean_50200m) + log(coast_line_distance) * sqrt(amount_ocean_50200m) + lat_tan_e9 * sqrt(amount_ocean_25000m) + lon * sqrt(amount_ocean_25000m) + log(coast_line_distance) * sqrt(amount_ocean_25000m) + lat_tan_e9 * sqrt(amount_ocean_10100m) + lon * sqrt(amount_ocean_10100m) + log(coast_line_distance) * sqrt(amount_ocean_10100m) + lat_tan_e9 * sqrt(amount_ocean_5050m) + lon * sqrt(amount_ocean_5050m) + log(coast_line_distance) * sqrt(amount_ocean_5050m) + lat_tan_e9 * slope_5 + lon * slope_5 + slope_5 * I(solar_radiation^2) + lat_tan_e9 * I(solar_radiation^2) + lon * I(solar_radiation^2) + as.factor(aspect5_cl16) * I(solar_radiation^2) + as.factor(aspect5_cl16) * log(coast_line_distance) + as.factor(aspect5_cl16) * slope_5 + lat_tan_e9 * as.factor(geol_rich) + lat_tan_e9 * as.factor(quart_gw) + lon * as.factor(quart_gw) + lat_tan_e9 * TPI_110m + log(coast_line_distance) * TPI_110m + lat_tan_e9 * TWI + lon * TWI, data = skgrMergeF1)
summaries[["lat_tan_e9_sqrt_amount_log_dist"]] <- summary(f1sm7$residuals)
AICs[["lat_tan_e9_sqrt_amount_log_dist"]] <- AIC(f1sm7)

f1sm7 <- lm(hoh ~ lat_tan_e10 * lon + lat_tan_e10 * log(coast_line_distance) + lon * log(coast_line_distance) + lat_tan_e10 * sqrt(amount_ocean_100200m) + lon * sqrt(amount_ocean_100200m) + log(coast_line_distance) * sqrt(amount_ocean_100200m) + lat_tan_e10 * sqrt(amount_ocean_50200m) + lon * sqrt(amount_ocean_50200m) + log(coast_line_distance) * sqrt(amount_ocean_50200m) + lat_tan_e10 * sqrt(amount_ocean_25000m) + lon * sqrt(amount_ocean_25000m) + log(coast_line_distance) * sqrt(amount_ocean_25000m) + lat_tan_e10 * sqrt(amount_ocean_10100m) + lon * sqrt(amount_ocean_10100m) + log(coast_line_distance) * sqrt(amount_ocean_10100m) + lat_tan_e10 * sqrt(amount_ocean_5050m) + lon * sqrt(amount_ocean_5050m) + log(coast_line_distance) * sqrt(amount_ocean_5050m) + lat_tan_e10 * slope_5 + lon * slope_5 + slope_5 * I(solar_radiation^2) + lat_tan_e10 * I(solar_radiation^2) + lon * I(solar_radiation^2) + as.factor(aspect5_cl16) * I(solar_radiation^2) + as.factor(aspect5_cl16) * log(coast_line_distance) + as.factor(aspect5_cl16) * slope_5 + lat_tan_e10 * as.factor(geol_rich) + lat_tan_e10 * as.factor(quart_gw) + lon * as.factor(quart_gw) + lat_tan_e10 * TPI_110m + log(coast_line_distance) * TPI_110m + lat_tan_e10 * TWI + lon * TWI, data = skgrMergeF1)
summaries[["lat_tan_e10_sqrt_amount_log_dist"]] <- summary(f1sm7$residuals)
AICs[["lat_tan_e10_sqrt_amount_log_dist"]] <- AIC(f1sm7)

f1sm7 <- lm(hoh ~ lat_tan_e20 * lon + lat_tan_e20 * log(coast_line_distance) + lon * log(coast_line_distance) + lat_tan_e20 * sqrt(amount_ocean_100200m) + lon * sqrt(amount_ocean_100200m) + log(coast_line_distance) * sqrt(amount_ocean_100200m) + lat_tan_e20 * sqrt(amount_ocean_50200m) + lon * sqrt(amount_ocean_50200m) + log(coast_line_distance) * sqrt(amount_ocean_50200m) + lat_tan_e20 * sqrt(amount_ocean_25000m) + lon * sqrt(amount_ocean_25000m) + log(coast_line_distance) * sqrt(amount_ocean_25000m) + lat_tan_e20 * sqrt(amount_ocean_10100m) + lon * sqrt(amount_ocean_10100m) + log(coast_line_distance) * sqrt(amount_ocean_10100m) + lat_tan_e20 * sqrt(amount_ocean_5050m) + lon * sqrt(amount_ocean_5050m) + log(coast_line_distance) * sqrt(amount_ocean_5050m) + lat_tan_e20 * slope_5 + lon * slope_5 + slope_5 * I(solar_radiation^2) + lat_tan_e20 * I(solar_radiation^2) + lon * I(solar_radiation^2) + as.factor(aspect5_cl16) * I(solar_radiation^2) + as.factor(aspect5_cl16) * log(coast_line_distance) + as.factor(aspect5_cl16) * slope_5 + lat_tan_e20 * as.factor(geol_rich) + lat_tan_e20 * as.factor(quart_gw) + lon * as.factor(quart_gw) + lat_tan_e20 * TPI_110m + log(coast_line_distance) * TPI_110m + lat_tan_e20 * TWI + lon * TWI, data = skgrMergeF1)
summaries[["lat_tan_e20_sqrt_amount_log_dist"]] <- summary(f1sm7$residuals)
AICs[["lat_tan_e20_sqrt_amount_log_dist"]] <- AIC(f1sm7)

f1sm7 <- lm(hoh ~ lat_tan_e30 * lon + lat_tan_e30 * log(coast_line_distance) + lon * log(coast_line_distance) + lat_tan_e30 * sqrt(amount_ocean_100200m) + lon * sqrt(amount_ocean_100200m) + log(coast_line_distance) * sqrt(amount_ocean_100200m) + lat_tan_e30 * sqrt(amount_ocean_50200m) + lon * sqrt(amount_ocean_50200m) + log(coast_line_distance) * sqrt(amount_ocean_50200m) + lat_tan_e30 * sqrt(amount_ocean_25000m) + lon * sqrt(amount_ocean_25000m) + log(coast_line_distance) * sqrt(amount_ocean_25000m) + lat_tan_e30 * sqrt(amount_ocean_10100m) + lon * sqrt(amount_ocean_10100m) + log(coast_line_distance) * sqrt(amount_ocean_10100m) + lat_tan_e30 * sqrt(amount_ocean_5050m) + lon * sqrt(amount_ocean_5050m) + log(coast_line_distance) * sqrt(amount_ocean_5050m) + lat_tan_e30 * slope_5 + lon * slope_5 + slope_5 * I(solar_radiation^2) + lat_tan_e30 * I(solar_radiation^2) + lon * I(solar_radiation^2) + as.factor(aspect5_cl16) * I(solar_radiation^2) + as.factor(aspect5_cl16) * log(coast_line_distance) + as.factor(aspect5_cl16) * slope_5 + lat_tan_e30 * as.factor(geol_rich) + lat_tan_e30 * as.factor(quart_gw) + lon * as.factor(quart_gw) + lat_tan_e30 * TPI_110m + log(coast_line_distance) * TPI_110m + lat_tan_e30 * TWI + lon * TWI, data = skgrMergeF1)
summaries[["lat_tan_e30_sqrt_amount_log_dist"]] <- summary(f1sm7$residuals)
AICs[["lat_tan_e30_sqrt_amount_log_dist"]] <- AIC(f1sm7)

f1sm7 <- lm(hoh ~ lat_tan_e50 * lon + lat_tan_e50 * log(coast_line_distance) + lon * log(coast_line_distance) + lat_tan_e50 * sqrt(amount_ocean_100200m) + lon * sqrt(amount_ocean_100200m) + log(coast_line_distance) * sqrt(amount_ocean_100200m) + lat_tan_e50 * sqrt(amount_ocean_50200m) + lon * sqrt(amount_ocean_50200m) + log(coast_line_distance) * sqrt(amount_ocean_50200m) + lat_tan_e50 * sqrt(amount_ocean_25000m) + lon * sqrt(amount_ocean_25000m) + log(coast_line_distance) * sqrt(amount_ocean_25000m) + lat_tan_e50 * sqrt(amount_ocean_10100m) + lon * sqrt(amount_ocean_10100m) + log(coast_line_distance) * sqrt(amount_ocean_10100m) + lat_tan_e50 * sqrt(amount_ocean_5050m) + lon * sqrt(amount_ocean_5050m) + log(coast_line_distance) * sqrt(amount_ocean_5050m) + lat_tan_e50 * slope_5 + lon * slope_5 + slope_5 * I(solar_radiation^2) + lat_tan_e50 * I(solar_radiation^2) + lon * I(solar_radiation^2) + as.factor(aspect5_cl16) * I(solar_radiation^2) + as.factor(aspect5_cl16) * log(coast_line_distance) + as.factor(aspect5_cl16) * slope_5 + lat_tan_e50 * as.factor(geol_rich) + lat_tan_e50 * as.factor(quart_gw) + lon * as.factor(quart_gw) + lat_tan_e50 * TPI_110m + log(coast_line_distance) * TPI_110m + lat_tan_e50 * TWI + lon * TWI, data = skgrMergeF1)
summaries[["lat_tan_e50_sqrt_amount_log_dist"]] <- summary(f1sm7$residuals)
AICs[["lat_tan_e50_sqrt_amount_log_dist"]] <- AIC(f1sm7)

f1sm7 <- lm(hoh ~ lat_tan_e100 * lon + lat_tan_e100 * log(coast_line_distance) + lon * log(coast_line_distance) + lat_tan_e100 * sqrt(amount_ocean_100200m) + lon * sqrt(amount_ocean_100200m) + log(coast_line_distance) * sqrt(amount_ocean_100200m) + lat_tan_e100 * sqrt(amount_ocean_50200m) + lon * sqrt(amount_ocean_50200m) + log(coast_line_distance) * sqrt(amount_ocean_50200m) + lat_tan_e100 * sqrt(amount_ocean_25000m) + lon * sqrt(amount_ocean_25000m) + log(coast_line_distance) * sqrt(amount_ocean_25000m) + lat_tan_e100 * sqrt(amount_ocean_10100m) + lon * sqrt(amount_ocean_10100m) + log(coast_line_distance) * sqrt(amount_ocean_10100m) + lat_tan_e100 * sqrt(amount_ocean_5050m) + lon * sqrt(amount_ocean_5050m) + log(coast_line_distance) * sqrt(amount_ocean_5050m) + lat_tan_e100 * slope_5 + lon * slope_5 + slope_5 * I(solar_radiation^2) + lat_tan_e100 * I(solar_radiation^2) + lon * I(solar_radiation^2) + as.factor(aspect5_cl16) * I(solar_radiation^2) + as.factor(aspect5_cl16) * log(coast_line_distance) + as.factor(aspect5_cl16) * slope_5 + lat_tan_e100 * as.factor(geol_rich) + lat_tan_e100 * as.factor(quart_gw) + lon * as.factor(quart_gw) + lat_tan_e100 * TPI_110m + log(coast_line_distance) * TPI_110m + lat_tan_e100 * TWI + lon * TWI, data = skgrMergeF1)
summaries[["lat_tan_e100_sqrt_amount_log_dist"]] <- summary(f1sm7$residuals)
AICs[["lat_tan_e100_sqrt_amount_log_dist"]] <- AIC(f1sm7)

f1sm7 <- lm(hoh ~ lat * lon + lat * log(coast_line_distance) + lon * log(coast_line_distance) + lat * log(amount_ocean_100200m) + lon * log(amount_ocean_100200m) + log(coast_line_distance) * log(amount_ocean_100200m) + lat * log(amount_ocean_50200m) + lon * log(amount_ocean_50200m) + log(coast_line_distance) * log(amount_ocean_50200m) + lat * log(amount_ocean_25000m) + lon * log(amount_ocean_25000m) + log(coast_line_distance) * log(amount_ocean_25000m) + lat * log(amount_ocean_10100m) + lon * log(amount_ocean_10100m) + log(coast_line_distance) * log(amount_ocean_10100m) + lat * log(amount_ocean_5050m) + lon * log(amount_ocean_5050m) + log(coast_line_distance) * log(amount_ocean_5050m) + lat * slope_5 + lon * slope_5 + slope_5 * I(solar_radiation^2) + lat * I(solar_radiation^2) + lon * I(solar_radiation^2) + as.factor(aspect5_cl16) * I(solar_radiation^2) + as.factor(aspect5_cl16) * log(coast_line_distance) + as.factor(aspect5_cl16) * slope_5 + lat * as.factor(geol_rich) + lat * as.factor(quart_gw) + lon * as.factor(quart_gw) + lat * TPI_110m + log(coast_line_distance) * TPI_110m + lat * TWI +lon * TWI, data = skgrMergeF1)
summaries[["lat_log_amount_log_dist"]] <- summary(f1sm7$residuals)
AICs[["lat_log_amount_log_dist"]] <- AIC(f1sm7)

f1sm7 <- lm(hoh ~ lat_tan * lon + lat_tan * log(coast_line_distance) + lon * log(coast_line_distance) + lat_tan * log(amount_ocean_100200m) + lon * log(amount_ocean_100200m) + log(coast_line_distance) * log(amount_ocean_100200m) + lat_tan * log(amount_ocean_50200m) + lon * log(amount_ocean_50200m) + log(coast_line_distance) * log(amount_ocean_50200m) + lat_tan * log(amount_ocean_25000m) + lon * log(amount_ocean_25000m) + log(coast_line_distance) * log(amount_ocean_25000m) + lat_tan * log(amount_ocean_10100m) + lon * log(amount_ocean_10100m) + log(coast_line_distance) * log(amount_ocean_10100m) + lat_tan * log(amount_ocean_5050m) + lon * log(amount_ocean_5050m) + log(coast_line_distance) * log(amount_ocean_5050m) + lat_tan * slope_5 + lon * slope_5 + slope_5 * I(solar_radiation^2) + lat_tan * I(solar_radiation^2) + lon * I(solar_radiation^2) + as.factor(aspect5_cl16) * I(solar_radiation^2) + as.factor(aspect5_cl16) * log(coast_line_distance) + as.factor(aspect5_cl16) * slope_5 + lat_tan * as.factor(geol_rich) + lat_tan * as.factor(quart_gw) + lon * as.factor(quart_gw) + lat_tan * TPI_110m + log(coast_line_distance) * TPI_110m + lat_tan * TWI + lon * TWI, data = skgrMergeF1)
summaries[["lat_tan_log_amount_log_dist"]] <- summary(f1sm7$residuals)
AICs[["lat_tan_log_amount_log_dist"]] <- AIC(f1sm7)

f1sm7 <- lm(hoh ~ exp(lat_tan) * lon + exp(lat_tan) * log(coast_line_distance) + lon * log(coast_line_distance) + exp(lat_tan) * log(amount_ocean_100200m) + lon * log(amount_ocean_100200m) + log(coast_line_distance) * log(amount_ocean_100200m) + exp(lat_tan) * log(amount_ocean_50200m) + lon * log(amount_ocean_50200m) + log(coast_line_distance) * log(amount_ocean_50200m) + exp(lat_tan) * log(amount_ocean_25000m) + lon * log(amount_ocean_25000m) + log(coast_line_distance) * log(amount_ocean_25000m) + exp(lat_tan) * log(amount_ocean_10100m) + lon * log(amount_ocean_10100m) + log(coast_line_distance) * log(amount_ocean_10100m) + exp(lat_tan) * log(amount_ocean_5050m) + lon * log(amount_ocean_5050m) + log(coast_line_distance) * log(amount_ocean_5050m) + exp(lat_tan) * slope_5 + lon * slope_5 + slope_5 * I(solar_radiation^2) + exp(lat_tan) * I(solar_radiation^2) + lon * I(solar_radiation^2) + as.factor(aspect5_cl16) * I(solar_radiation^2) + as.factor(aspect5_cl16) * log(coast_line_distance) + as.factor(aspect5_cl16) * slope_5 + exp(lat_tan) * as.factor(geol_rich) + exp(lat_tan) * as.factor(quart_gw) + lon * as.factor(quart_gw) + exp(lat_tan) * TPI_110m + log(coast_line_distance) * TPI_110m + exp(lat_tan) * TWI + lon * TWI, data = skgrMergeF1)
summaries[["exp(lat_tan)_log_amount_log_dist"]] <- summary(f1sm7$residuals)
AICs[["exp(lat_tan)_log_amount_log_dist"]] <- AIC(f1sm7)

f1sm7 <- lm(hoh ~ lat_tan_e2 * lon + lat_tan_e2 * log(coast_line_distance) + lon * log(coast_line_distance) + lat_tan_e2 * log(amount_ocean_100200m) + lon * log(amount_ocean_100200m) + log(coast_line_distance) * log(amount_ocean_100200m) + lat_tan_e2 * log(amount_ocean_50200m) + lon * log(amount_ocean_50200m) + log(coast_line_distance) * log(amount_ocean_50200m) + lat_tan_e2 * log(amount_ocean_25000m) + lon * log(amount_ocean_25000m) + log(coast_line_distance) * log(amount_ocean_25000m) + lat_tan_e2 * log(amount_ocean_10100m) + lon * log(amount_ocean_10100m) + log(coast_line_distance) * log(amount_ocean_10100m) + lat_tan_e2 * log(amount_ocean_5050m) + lon * log(amount_ocean_5050m) + log(coast_line_distance) * log(amount_ocean_5050m) + lat_tan_e2 * slope_5 + lon * slope_5 + slope_5 * I(solar_radiation^2) + lat_tan_e2 * I(solar_radiation^2) + lon * I(solar_radiation^2) + as.factor(aspect5_cl16) * I(solar_radiation^2) + as.factor(aspect5_cl16) * log(coast_line_distance) + as.factor(aspect5_cl16) * slope_5 + lat_tan_e2 * as.factor(geol_rich) + lat_tan_e2 * as.factor(quart_gw) + lon * as.factor(quart_gw) + lat_tan_e2 * TPI_110m + log(coast_line_distance) * TPI_110m + lat_tan_e2 * TWI + lon * TWI, data = skgrMergeF1)
summaries[["lat_tan_e2_log_amount_log_dist"]] <- summary(f1sm7$residuals)
AICs[["lat_tan_e2_log_amount_log_dist"]] <- AIC(f1sm7)

f1sm7 <- lm(hoh ~ lat_tan_e3 * lon + lat_tan_e3 * log(coast_line_distance) + lon * log(coast_line_distance) + lat_tan_e3 * log(amount_ocean_100200m) + lon * log(amount_ocean_100200m) + log(coast_line_distance) * log(amount_ocean_100200m) + lat_tan_e3 * log(amount_ocean_50200m) + lon * log(amount_ocean_50200m) + log(coast_line_distance) * log(amount_ocean_50200m) + lat_tan_e3 * log(amount_ocean_25000m) + lon * log(amount_ocean_25000m) + log(coast_line_distance) * log(amount_ocean_25000m) + lat_tan_e3 * log(amount_ocean_10100m) + lon * log(amount_ocean_10100m) + log(coast_line_distance) * log(amount_ocean_10100m) + lat_tan_e3 * log(amount_ocean_5050m) + lon * log(amount_ocean_5050m) + log(coast_line_distance) * log(amount_ocean_5050m) + lat_tan_e3 * slope_5 + lon * slope_5 + slope_5 * I(solar_radiation^2) + lat_tan_e3 * I(solar_radiation^2) + lon * I(solar_radiation^2) + as.factor(aspect5_cl16) * I(solar_radiation^2) + as.factor(aspect5_cl16) * log(coast_line_distance) + as.factor(aspect5_cl16) * slope_5 + lat_tan_e3 * as.factor(geol_rich) + lat_tan_e3 * as.factor(quart_gw) + lon * as.factor(quart_gw) + lat_tan_e3 * TPI_110m + log(coast_line_distance) * TPI_110m + lat_tan_e3 * TWI + lon * TWI, data = skgrMergeF1)
summaries[["lat_tan_e3_log_amount_log_dist"]] <- summary(f1sm7$residuals)
AICs[["lat_tan_e3_log_amount_log_dist"]] <- AIC(f1sm7)

f1sm7 <- lm(hoh ~ lat_tan_e4 * lon + lat_tan_e4 * log(coast_line_distance) + lon * log(coast_line_distance) + lat_tan_e4 * log(amount_ocean_100200m) + lon * log(amount_ocean_100200m) + log(coast_line_distance) * log(amount_ocean_100200m) + lat_tan_e4 * log(amount_ocean_50200m) + lon * log(amount_ocean_50200m) + log(coast_line_distance) * log(amount_ocean_50200m) + lat_tan_e4 * log(amount_ocean_25000m) + lon * log(amount_ocean_25000m) + log(coast_line_distance) * log(amount_ocean_25000m) + lat_tan_e4 * log(amount_ocean_10100m) + lon * log(amount_ocean_10100m) + log(coast_line_distance) * log(amount_ocean_10100m) + lat_tan_e4 * log(amount_ocean_5050m) + lon * log(amount_ocean_5050m) + log(coast_line_distance) * log(amount_ocean_5050m) + lat_tan_e4 * slope_5 + lon * slope_5 + slope_5 * I(solar_radiation^2) + lat_tan_e4 * I(solar_radiation^2) + lon * I(solar_radiation^2) + as.factor(aspect5_cl16) * I(solar_radiation^2) + as.factor(aspect5_cl16) * log(coast_line_distance) + as.factor(aspect5_cl16) * slope_5 + lat_tan_e4 * as.factor(geol_rich) + lat_tan_e4 * as.factor(quart_gw) + lon * as.factor(quart_gw) + lat_tan_e4 * TPI_110m + log(coast_line_distance) * TPI_110m + lat_tan_e4 * TWI + lon * TWI, data = skgrMergeF1)
summaries[["lat_tan_e4_log_amount_log_dist"]] <- summary(f1sm7$residuals)
AICs[["lat_tan_e4_log_amount_log_dist"]] <- AIC(f1sm7)

f1sm7 <- lm(hoh ~ lat_tan_e5 * lon + lat_tan_e5 * log(coast_line_distance) + lon * log(coast_line_distance) + lat_tan_e5 * log(amount_ocean_100200m) + lon * log(amount_ocean_100200m) + log(coast_line_distance) * log(amount_ocean_100200m) + lat_tan_e5 * log(amount_ocean_50200m) + lon * log(amount_ocean_50200m) + log(coast_line_distance) * log(amount_ocean_50200m) + lat_tan_e5 * log(amount_ocean_25000m) + lon * log(amount_ocean_25000m) + log(coast_line_distance) * log(amount_ocean_25000m) + lat_tan_e5 * log(amount_ocean_10100m) + lon * log(amount_ocean_10100m) + log(coast_line_distance) * log(amount_ocean_10100m) + lat_tan_e5 * log(amount_ocean_5050m) + lon * log(amount_ocean_5050m) + log(coast_line_distance) * log(amount_ocean_5050m) + lat_tan_e5 * slope_5 + lon * slope_5 + slope_5 * I(solar_radiation^2) + lat_tan_e5 * I(solar_radiation^2) + lon * I(solar_radiation^2) + as.factor(aspect5_cl16) * I(solar_radiation^2) + as.factor(aspect5_cl16) * log(coast_line_distance) + as.factor(aspect5_cl16) * slope_5 + lat_tan_e5 * as.factor(geol_rich) + lat_tan_e5 * as.factor(quart_gw) + lon * as.factor(quart_gw) + lat_tan_e5 * TPI_110m + log(coast_line_distance) * TPI_110m + lat_tan_e5 * TWI + lon * TWI, data = skgrMergeF1)
f1sm5 <- lm(hoh ~ lat_tan_e5 * lon + lat_tan_e5 * log(coast_line_distance) + lon * log(coast_line_distance) + lat_tan_e5 * log(amount_ocean_100200m) + lon * log(amount_ocean_100200m) + log(coast_line_distance) * log(amount_ocean_100200m) + lat_tan_e5 * log(amount_ocean_50200m) + lon * log(amount_ocean_50200m) + log(coast_line_distance) * log(amount_ocean_50200m) + lat_tan_e5 * log(amount_ocean_25000m) + lon * log(amount_ocean_25000m) + log(coast_line_distance) * log(amount_ocean_25000m) + lat_tan_e5 * log(amount_ocean_10100m) + lon * log(amount_ocean_10100m) + log(coast_line_distance) * log(amount_ocean_10100m) + lat_tan_e5 * log(amount_ocean_5050m) + lon * log(amount_ocean_5050m) + log(coast_line_distance) * log(amount_ocean_5050m) + lat_tan_e5 * slope_5 + lon * slope_5 + slope_5 * I(solar_radiation^2) + lat_tan_e5 * I(solar_radiation^2) + lon * I(solar_radiation^2) + as.factor(aspect5_cl16) * I(solar_radiation^2) + as.factor(aspect5_cl16) * log(coast_line_distance) + as.factor(aspect5_cl16) * slope_5 + lat_tan_e5 * as.factor(geol_rich) + lat_tan_e5 * as.factor(quart_gw) + lon * as.factor(quart_gw) + lat_tan_e5 * TPI_110m + log(coast_line_distance) * TPI_110m + lat_tan_e5 * TWI + lon * TWI, data = skgrMergeF1)
AIC(f1sm7,f1sm5)
summaries[["lat_tan_e5_log_amount_log_dist"]] <- summary(f1sm7$residuals)
AICs[["lat_tan_e5_log_amount_log_dist"]] <- AIC(f1sm7)

f1sm7 <- lm(hoh ~ lat_tan_e6 * lon + lat_tan_e6 * log(coast_line_distance) + lon * log(coast_line_distance) + lat_tan_e6 * log(amount_ocean_100200m) + lon * log(amount_ocean_100200m) + log(coast_line_distance) * log(amount_ocean_100200m) + lat_tan_e6 * log(amount_ocean_50200m) + lon * log(amount_ocean_50200m) + log(coast_line_distance) * log(amount_ocean_50200m) + lat_tan_e6 * log(amount_ocean_25000m) + lon * log(amount_ocean_25000m) + log(coast_line_distance) * log(amount_ocean_25000m) + lat_tan_e6 * log(amount_ocean_10100m) + lon * log(amount_ocean_10100m) + log(coast_line_distance) * log(amount_ocean_10100m) + lat_tan_e6 * log(amount_ocean_5050m) + lon * log(amount_ocean_5050m) + log(coast_line_distance) * log(amount_ocean_5050m) + lat_tan_e6 * slope_5 + lon * slope_5 + slope_5 * I(solar_radiation^2) + lat_tan_e6 * I(solar_radiation^2) + lon * I(solar_radiation^2) + as.factor(aspect5_cl16) * I(solar_radiation^2) + as.factor(aspect5_cl16) * log(coast_line_distance) + as.factor(aspect5_cl16) * slope_5 + lat_tan_e6 * as.factor(geol_rich) + lat_tan_e6 * as.factor(quart_gw) + lon * as.factor(quart_gw) + lat_tan_e6 * TPI_110m + log(coast_line_distance) * TPI_110m + lat_tan_e6 * TWI + lon * TWI, data = skgrMergeF1)
summaries[["lat_tan_e6_log_amount_log_dist"]] <- summary(f1sm7$residuals)
AICs[["lat_tan_e6_log_amount_log_dist"]] <- AIC(f1sm7)

f1sm7 <- lm(hoh ~ lat_tan_e7 * lon + lat_tan_e7 * log(coast_line_distance) + lon * log(coast_line_distance) + lat_tan_e7 * log(amount_ocean_100200m) + lon * log(amount_ocean_100200m) + log(coast_line_distance) * log(amount_ocean_100200m) + lat_tan_e7 * log(amount_ocean_50200m) + lon * log(amount_ocean_50200m) + log(coast_line_distance) * log(amount_ocean_50200m) + lat_tan_e7 * log(amount_ocean_25000m) + lon * log(amount_ocean_25000m) + log(coast_line_distance) * log(amount_ocean_25000m) + lat_tan_e7 * log(amount_ocean_10100m) + lon * log(amount_ocean_10100m) + log(coast_line_distance) * log(amount_ocean_10100m) + lat_tan_e7 * log(amount_ocean_5050m) + lon * log(amount_ocean_5050m) + log(coast_line_distance) * log(amount_ocean_5050m) + lat_tan_e7 * slope_5 + lon * slope_5 + slope_5 * I(solar_radiation^2) + lat_tan_e7 * I(solar_radiation^2) + lon * I(solar_radiation^2) + as.factor(aspect5_cl16) * I(solar_radiation^2) + as.factor(aspect5_cl16) * log(coast_line_distance) + as.factor(aspect5_cl16) * slope_5 + lat_tan_e7 * as.factor(geol_rich) + lat_tan_e7 * as.factor(quart_gw) + lon * as.factor(quart_gw) + lat_tan_e7 * TPI_110m + log(coast_line_distance) * TPI_110m + lat_tan_e7 * TWI + lon * TWI, data = skgrMergeF1)
summaries[["lat_tan_e7_log_amount_log_dist"]] <- summary(f1sm7$residuals)
AICs[["lat_tan_e7_log_amount_log_dist"]] <- AIC(f1sm7)

f1sm7 <- lm(hoh ~ lat_tan_e8 * lon + lat_tan_e8 * log(coast_line_distance) + lon * log(coast_line_distance) + lat_tan_e8 * log(amount_ocean_100200m) + lon * log(amount_ocean_100200m) + log(coast_line_distance) * log(amount_ocean_100200m) + lat_tan_e8 * log(amount_ocean_50200m) + lon * log(amount_ocean_50200m) + log(coast_line_distance) * log(amount_ocean_50200m) + lat_tan_e8 * log(amount_ocean_25000m) + lon * log(amount_ocean_25000m) + log(coast_line_distance) * log(amount_ocean_25000m) + lat_tan_e8 * log(amount_ocean_10100m) + lon * log(amount_ocean_10100m) + log(coast_line_distance) * log(amount_ocean_10100m) + lat_tan_e8 * log(amount_ocean_5050m) + lon * log(amount_ocean_5050m) + log(coast_line_distance) * log(amount_ocean_5050m) + lat_tan_e8 * slope_5 + lon * slope_5 + slope_5 * I(solar_radiation^2) + lat_tan_e8 * I(solar_radiation^2) + lon * I(solar_radiation^2) + as.factor(aspect5_cl16) * I(solar_radiation^2) + as.factor(aspect5_cl16) * log(coast_line_distance) + as.factor(aspect5_cl16) * slope_5 + lat_tan_e8 * as.factor(geol_rich) + lat_tan_e8 * as.factor(quart_gw) + lon * as.factor(quart_gw) + lat_tan_e8 * TPI_110m + log(coast_line_distance) * TPI_110m + lat_tan_e8 * TWI + lon * TWI, data = skgrMergeF1)
summaries[["lat_tan_e8_log_amount_log_dist"]] <- summary(f1sm7$residuals)
AICs[["lat_tan_e8_log_amount_log_dist"]] <- AIC(f1sm7)

f1sm7 <- lm(hoh ~ lat_tan_e9 * lon + lat_tan_e9 * log(coast_line_distance) + lon * log(coast_line_distance) + lat_tan_e9 * log(amount_ocean_100200m) + lon * log(amount_ocean_100200m) + log(coast_line_distance) * log(amount_ocean_100200m) + lat_tan_e9 * log(amount_ocean_50200m) + lon * log(amount_ocean_50200m) + log(coast_line_distance) * log(amount_ocean_50200m) + lat_tan_e9 * log(amount_ocean_25000m) + lon * log(amount_ocean_25000m) + log(coast_line_distance) * log(amount_ocean_25000m) + lat_tan_e9 * log(amount_ocean_10100m) + lon * log(amount_ocean_10100m) + log(coast_line_distance) * log(amount_ocean_10100m) + lat_tan_e9 * log(amount_ocean_5050m) + lon * log(amount_ocean_5050m) + log(coast_line_distance) * log(amount_ocean_5050m) + lat_tan_e9 * slope_5 + lon * slope_5 + slope_5 * I(solar_radiation^2) + lat_tan_e9 * I(solar_radiation^2) + lon * I(solar_radiation^2) + as.factor(aspect5_cl16) * I(solar_radiation^2) + as.factor(aspect5_cl16) * log(coast_line_distance) + as.factor(aspect5_cl16) * slope_5 + lat_tan_e9 * as.factor(geol_rich) + lat_tan_e9 * as.factor(quart_gw) + lon * as.factor(quart_gw) + lat_tan_e9 * TPI_110m + log(coast_line_distance) * TPI_110m + lat_tan_e9 * TWI + lon * TWI, data = skgrMergeF1)
summaries[["lat_tan_e9_log_amount_log_dist"]] <- summary(f1sm7$residuals)
AICs[["lat_tan_e9_log_amount_log_dist"]] <- AIC(f1sm7)

f1sm7 <- lm(hoh ~ lat_tan_e10 * lon + lat_tan_e10 * log(coast_line_distance) + lon * log(coast_line_distance) + lat_tan_e10 * log(amount_ocean_100200m) + lon * log(amount_ocean_100200m) + log(coast_line_distance) * log(amount_ocean_100200m) + lat_tan_e10 * log(amount_ocean_50200m) + lon * log(amount_ocean_50200m) + log(coast_line_distance) * log(amount_ocean_50200m) + lat_tan_e10 * log(amount_ocean_25000m) + lon * log(amount_ocean_25000m) + log(coast_line_distance) * log(amount_ocean_25000m) + lat_tan_e10 * log(amount_ocean_10100m) + lon * log(amount_ocean_10100m) + log(coast_line_distance) * log(amount_ocean_10100m) + lat_tan_e10 * log(amount_ocean_5050m) + lon * log(amount_ocean_5050m) + log(coast_line_distance) * log(amount_ocean_5050m) + lat_tan_e10 * slope_5 + lon * slope_5 + slope_5 * I(solar_radiation^2) + lat_tan_e10 * I(solar_radiation^2) + lon * I(solar_radiation^2) + as.factor(aspect5_cl16) * I(solar_radiation^2) + as.factor(aspect5_cl16) * log(coast_line_distance) + as.factor(aspect5_cl16) * slope_5 + lat_tan_e10 * as.factor(geol_rich) + lat_tan_e10 * as.factor(quart_gw) + lon * as.factor(quart_gw) + lat_tan_e10 * TPI_110m + log(coast_line_distance) * TPI_110m + lat_tan_e10 * TWI + lon * TWI, data = skgrMergeF1)
summaries[["lat_tan_e10_log_amount_log_dist"]] <- summary(f1sm7$residuals)
AICs[["lat_tan_e10_log_amount_log_dist"]] <- AIC(f1sm7)

f1sm7 <- lm(hoh ~ lat_tan_e20 * lon + lat_tan_e20 * log(coast_line_distance) + lon * log(coast_line_distance) + lat_tan_e20 * log(amount_ocean_100200m) + lon * log(amount_ocean_100200m) + log(coast_line_distance) * log(amount_ocean_100200m) + lat_tan_e20 * log(amount_ocean_50200m) + lon * log(amount_ocean_50200m) + log(coast_line_distance) * log(amount_ocean_50200m) + lat_tan_e20 * log(amount_ocean_25000m) + lon * log(amount_ocean_25000m) + log(coast_line_distance) * log(amount_ocean_25000m) + lat_tan_e20 * log(amount_ocean_10100m) + lon * log(amount_ocean_10100m) + log(coast_line_distance) * log(amount_ocean_10100m) + lat_tan_e20 * log(amount_ocean_5050m) + lon * log(amount_ocean_5050m) + log(coast_line_distance) * log(amount_ocean_5050m) + lat_tan_e20 * slope_5 + lon * slope_5 + slope_5 * I(solar_radiation^2) + lat_tan_e20 * I(solar_radiation^2) + lon * I(solar_radiation^2) + as.factor(aspect5_cl16) * I(solar_radiation^2) + as.factor(aspect5_cl16) * log(coast_line_distance) + as.factor(aspect5_cl16) * slope_5 + lat_tan_e20 * as.factor(geol_rich) + lat_tan_e20 * as.factor(quart_gw) + lon * as.factor(quart_gw) + lat_tan_e20 * TPI_110m + log(coast_line_distance) * TPI_110m + lat_tan_e20 * TWI + lon * TWI, data = skgrMergeF1)
summaries[["lat_tan_e20_log_amount_log_dist"]] <- summary(f1sm7$residuals)
AICs[["lat_tan_e20_log_amount_log_dist"]] <- AIC(f1sm7)

f1sm7 <- lm(hoh ~ lat_tan_e30 * lon + lat_tan_e30 * log(coast_line_distance) + lon * log(coast_line_distance) + lat_tan_e30 * log(amount_ocean_100200m) + lon * log(amount_ocean_100200m) + log(coast_line_distance) * log(amount_ocean_100200m) + lat_tan_e30 * log(amount_ocean_50200m) + lon * log(amount_ocean_50200m) + log(coast_line_distance) * log(amount_ocean_50200m) + lat_tan_e30 * log(amount_ocean_25000m) + lon * log(amount_ocean_25000m) + log(coast_line_distance) * log(amount_ocean_25000m) + lat_tan_e30 * log(amount_ocean_10100m) + lon * log(amount_ocean_10100m) + log(coast_line_distance) * log(amount_ocean_10100m) + lat_tan_e30 * log(amount_ocean_5050m) + lon * log(amount_ocean_5050m) + log(coast_line_distance) * log(amount_ocean_5050m) + lat_tan_e30 * slope_5 + lon * slope_5 + slope_5 * I(solar_radiation^2) + lat_tan_e30 * I(solar_radiation^2) + lon * I(solar_radiation^2) + as.factor(aspect5_cl16) * I(solar_radiation^2) + as.factor(aspect5_cl16) * log(coast_line_distance) + as.factor(aspect5_cl16) * slope_5 + lat_tan_e30 * as.factor(geol_rich) + lat_tan_e30 * as.factor(quart_gw) + lon * as.factor(quart_gw) + lat_tan_e30 * TPI_110m + log(coast_line_distance) * TPI_110m + lat_tan_e30 * TWI + lon * TWI, data = skgrMergeF1)
summaries[["lat_tan_e30_log_amount_log_dist"]] <- summary(f1sm7$residuals)
AICs[["lat_tan_e30_log_amount_log_dist"]] <- AIC(f1sm7)

f1sm7 <- lm(hoh ~ lat_tan_e50 * lon + lat_tan_e50 * log(coast_line_distance) + lon * log(coast_line_distance) + lat_tan_e50 * log(amount_ocean_100200m) + lon * log(amount_ocean_100200m) + log(coast_line_distance) * log(amount_ocean_100200m) + lat_tan_e50 * log(amount_ocean_50200m) + lon * log(amount_ocean_50200m) + log(coast_line_distance) * log(amount_ocean_50200m) + lat_tan_e50 * log(amount_ocean_25000m) + lon * log(amount_ocean_25000m) + log(coast_line_distance) * log(amount_ocean_25000m) + lat_tan_e50 * log(amount_ocean_10100m) + lon * log(amount_ocean_10100m) + log(coast_line_distance) * log(amount_ocean_10100m) + lat_tan_e50 * log(amount_ocean_5050m) + lon * log(amount_ocean_5050m) + log(coast_line_distance) * log(amount_ocean_5050m) + lat_tan_e50 * slope_5 + lon * slope_5 + slope_5 * I(solar_radiation^2) + lat_tan_e50 * I(solar_radiation^2) + lon * I(solar_radiation^2) + as.factor(aspect5_cl16) * I(solar_radiation^2) + as.factor(aspect5_cl16) * log(coast_line_distance) + as.factor(aspect5_cl16) * slope_5 + lat_tan_e50 * as.factor(geol_rich) + lat_tan_e50 * as.factor(quart_gw) + lon * as.factor(quart_gw) + lat_tan_e50 * TPI_110m + log(coast_line_distance) * TPI_110m + lat_tan_e50 * TWI + lon * TWI, data = skgrMergeF1)
summaries[["lat_tan_e50_log_amount_log_dist"]] <- summary(f1sm7$residuals)
AICs[["lat_tan_e50_log_amount_log_dist"]] <- AIC(f1sm7)

f1sm7 <- lm(hoh ~ lat_tan_e100 * lon + lat_tan_e100 * log(coast_line_distance) + lon * log(coast_line_distance) + lat_tan_e100 * log(amount_ocean_100200m) + lon * log(amount_ocean_100200m) + log(coast_line_distance) * log(amount_ocean_100200m) + lat_tan_e100 * log(amount_ocean_50200m) + lon * log(amount_ocean_50200m) + log(coast_line_distance) * log(amount_ocean_50200m) + lat_tan_e100 * log(amount_ocean_25000m) + lon * log(amount_ocean_25000m) + log(coast_line_distance) * log(amount_ocean_25000m) + lat_tan_e100 * log(amount_ocean_10100m) + lon * log(amount_ocean_10100m) + log(coast_line_distance) * log(amount_ocean_10100m) + lat_tan_e100 * log(amount_ocean_5050m) + lon * log(amount_ocean_5050m) + log(coast_line_distance) * log(amount_ocean_5050m) + lat_tan_e100 * slope_5 + lon * slope_5 + slope_5 * I(solar_radiation^2) + lat_tan_e100 * I(solar_radiation^2) + lon * I(solar_radiation^2) + as.factor(aspect5_cl16) * I(solar_radiation^2) + as.factor(aspect5_cl16) * log(coast_line_distance) + as.factor(aspect5_cl16) * slope_5 + lat_tan_e100 * as.factor(geol_rich) + lat_tan_e100 * as.factor(quart_gw) + lon * as.factor(quart_gw) + lat_tan_e100 * TPI_110m + log(coast_line_distance) * TPI_110m + lat_tan_e100 * TWI + lon * TWI, data = skgrMergeF1)
summaries[["lat_tan_e100_log_amount_log_dist"]] <- summary(f1sm7$residuals)
AICs[["lat_tan_e100_log_amount_log_dist"]] <- AIC(f1sm7)

f1sm7 <- lm(hoh ~ lat * lon + lat * sqrt(coast_line_distance) + lon * sqrt(coast_line_distance) + lat * sqrt(amount_ocean_100200m) + lon * sqrt(amount_ocean_100200m) + sqrt(coast_line_distance) * sqrt(amount_ocean_100200m) + lat * sqrt(amount_ocean_50200m) + lon * sqrt(amount_ocean_50200m) + sqrt(coast_line_distance) * sqrt(amount_ocean_50200m) + lat * sqrt(amount_ocean_25000m) + lon * sqrt(amount_ocean_25000m) + sqrt(coast_line_distance) * sqrt(amount_ocean_25000m) + lat * sqrt(amount_ocean_10100m) + lon * sqrt(amount_ocean_10100m) + sqrt(coast_line_distance) * sqrt(amount_ocean_10100m) + lat * sqrt(amount_ocean_5050m) + lon * sqrt(amount_ocean_5050m) + sqrt(coast_line_distance) * sqrt(amount_ocean_5050m) + lat * slope_5 + lon * slope_5 + slope_5 * I(solar_radiation^2) + lat * I(solar_radiation^2) + lon * I(solar_radiation^2) + as.factor(aspect5_cl16) * I(solar_radiation^2) + as.factor(aspect5_cl16) * sqrt(coast_line_distance) + as.factor(aspect5_cl16) * slope_5 + lat * as.factor(geol_rich) + lat * as.factor(quart_gw) + lon * as.factor(quart_gw) + lat * TPI_110m + sqrt(coast_line_distance) * TPI_110m + lat * TWI +lon * TWI, data = skgrMergeF1)
summaries[["lat_sqrt_amount_sqrt_dist"]] <- summary(f1sm7$residuals)
AICs[["lat_sqrt_amount_sqrt_dist"]] <- AIC(f1sm7)

f1sm7 <- lm(hoh ~ lat_tan * lon + lat_tan * sqrt(coast_line_distance) + lon * sqrt(coast_line_distance) + lat_tan * sqrt(amount_ocean_100200m) + lon * sqrt(amount_ocean_100200m) + sqrt(coast_line_distance) * sqrt(amount_ocean_100200m) + lat_tan * sqrt(amount_ocean_50200m) + lon * sqrt(amount_ocean_50200m) + sqrt(coast_line_distance) * sqrt(amount_ocean_50200m) + lat_tan * sqrt(amount_ocean_25000m) + lon * sqrt(amount_ocean_25000m) + sqrt(coast_line_distance) * sqrt(amount_ocean_25000m) + lat_tan * sqrt(amount_ocean_10100m) + lon * sqrt(amount_ocean_10100m) + sqrt(coast_line_distance) * sqrt(amount_ocean_10100m) + lat_tan * sqrt(amount_ocean_5050m) + lon * sqrt(amount_ocean_5050m) + sqrt(coast_line_distance) * sqrt(amount_ocean_5050m) + lat_tan * slope_5 + lon * slope_5 + slope_5 * I(solar_radiation^2) + lat_tan * I(solar_radiation^2) + lon * I(solar_radiation^2) + as.factor(aspect5_cl16) * I(solar_radiation^2) + as.factor(aspect5_cl16) * sqrt(coast_line_distance) + as.factor(aspect5_cl16) * slope_5 + lat_tan * as.factor(geol_rich) + lat_tan * as.factor(quart_gw) + lon * as.factor(quart_gw) + lat_tan * TPI_110m + sqrt(coast_line_distance) * TPI_110m + lat_tan * TWI + lon * TWI, data = skgrMergeF1)
summaries[["lat_tan_sqrt_amount_sqrt_dist"]] <- summary(f1sm7$residuals)
AICs[["lat_tan_sqrt_amount_sqrt_dist"]] <- AIC(f1sm7)

f1sm7 <- lm(hoh ~ exp(lat_tan) * lon + exp(lat_tan) * sqrt(coast_line_distance) + lon * sqrt(coast_line_distance) + exp(lat_tan) * sqrt(amount_ocean_100200m) + lon * sqrt(amount_ocean_100200m) + sqrt(coast_line_distance) * sqrt(amount_ocean_100200m) + exp(lat_tan) * sqrt(amount_ocean_50200m) + lon * sqrt(amount_ocean_50200m) + sqrt(coast_line_distance) * sqrt(amount_ocean_50200m) + exp(lat_tan) * sqrt(amount_ocean_25000m) + lon * sqrt(amount_ocean_25000m) + sqrt(coast_line_distance) * sqrt(amount_ocean_25000m) + exp(lat_tan) * sqrt(amount_ocean_10100m) + lon * sqrt(amount_ocean_10100m) + sqrt(coast_line_distance) * sqrt(amount_ocean_10100m) + exp(lat_tan) * sqrt(amount_ocean_5050m) + lon * sqrt(amount_ocean_5050m) + sqrt(coast_line_distance) * sqrt(amount_ocean_5050m) + exp(lat_tan) * slope_5 + lon * slope_5 + slope_5 * I(solar_radiation^2) + exp(lat_tan) * I(solar_radiation^2) + lon * I(solar_radiation^2) + as.factor(aspect5_cl16) * I(solar_radiation^2) + as.factor(aspect5_cl16) * sqrt(coast_line_distance) + as.factor(aspect5_cl16) * slope_5 + exp(lat_tan) * as.factor(geol_rich) + exp(lat_tan) * as.factor(quart_gw) + lon * as.factor(quart_gw) + exp(lat_tan) * TPI_110m + sqrt(coast_line_distance) * TPI_110m + exp(lat_tan) * TWI + lon * TWI, data = skgrMergeF1)
summaries[["exp(lat_tan)_sqrt_amount_sqrt_dist"]] <- summary(f1sm7$residuals)
AICs[["exp(lat_tan)_sqrt_amount_sqrt_dist"]] <- AIC(f1sm7)

f1sm7 <- lm(hoh ~ lat_tan_e2 * lon + lat_tan_e2 * sqrt(coast_line_distance) + lon * sqrt(coast_line_distance) + lat_tan_e2 * sqrt(amount_ocean_100200m) + lon * sqrt(amount_ocean_100200m) + sqrt(coast_line_distance) * sqrt(amount_ocean_100200m) + lat_tan_e2 * sqrt(amount_ocean_50200m) + lon * sqrt(amount_ocean_50200m) + sqrt(coast_line_distance) * sqrt(amount_ocean_50200m) + lat_tan_e2 * sqrt(amount_ocean_25000m) + lon * sqrt(amount_ocean_25000m) + sqrt(coast_line_distance) * sqrt(amount_ocean_25000m) + lat_tan_e2 * sqrt(amount_ocean_10100m) + lon * sqrt(amount_ocean_10100m) + sqrt(coast_line_distance) * sqrt(amount_ocean_10100m) + lat_tan_e2 * sqrt(amount_ocean_5050m) + lon * sqrt(amount_ocean_5050m) + sqrt(coast_line_distance) * sqrt(amount_ocean_5050m) + lat_tan_e2 * slope_5 + lon * slope_5 + slope_5 * I(solar_radiation^2) + lat_tan_e2 * I(solar_radiation^2) + lon * I(solar_radiation^2) + as.factor(aspect5_cl16) * I(solar_radiation^2) + as.factor(aspect5_cl16) * sqrt(coast_line_distance) + as.factor(aspect5_cl16) * slope_5 + lat_tan_e2 * as.factor(geol_rich) + lat_tan_e2 * as.factor(quart_gw) + lon * as.factor(quart_gw) + lat_tan_e2 * TPI_110m + sqrt(coast_line_distance) * TPI_110m + lat_tan_e2 * TWI + lon * TWI, data = skgrMergeF1)
summaries[["lat_tan_e2_sqrt_amount_sqrt_dist"]] <- summary(f1sm7$residuals)
AICs[["lat_tan_e2_sqrt_amount_sqrt_dist"]] <- AIC(f1sm7)

f1sm7 <- lm(hoh ~ lat_tan_e3 * lon + lat_tan_e3 * sqrt(coast_line_distance) + lon * sqrt(coast_line_distance) + lat_tan_e3 * sqrt(amount_ocean_100200m) + lon * sqrt(amount_ocean_100200m) + sqrt(coast_line_distance) * sqrt(amount_ocean_100200m) + lat_tan_e3 * sqrt(amount_ocean_50200m) + lon * sqrt(amount_ocean_50200m) + sqrt(coast_line_distance) * sqrt(amount_ocean_50200m) + lat_tan_e3 * sqrt(amount_ocean_25000m) + lon * sqrt(amount_ocean_25000m) + sqrt(coast_line_distance) * sqrt(amount_ocean_25000m) + lat_tan_e3 * sqrt(amount_ocean_10100m) + lon * sqrt(amount_ocean_10100m) + sqrt(coast_line_distance) * sqrt(amount_ocean_10100m) + lat_tan_e3 * sqrt(amount_ocean_5050m) + lon * sqrt(amount_ocean_5050m) + sqrt(coast_line_distance) * sqrt(amount_ocean_5050m) + lat_tan_e3 * slope_5 + lon * slope_5 + slope_5 * I(solar_radiation^2) + lat_tan_e3 * I(solar_radiation^2) + lon * I(solar_radiation^2) + as.factor(aspect5_cl16) * I(solar_radiation^2) + as.factor(aspect5_cl16) * sqrt(coast_line_distance) + as.factor(aspect5_cl16) * slope_5 + lat_tan_e3 * as.factor(geol_rich) + lat_tan_e3 * as.factor(quart_gw) + lon * as.factor(quart_gw) + lat_tan_e3 * TPI_110m + sqrt(coast_line_distance) * TPI_110m + lat_tan_e3 * TWI + lon * TWI, data = skgrMergeF1)
summaries[["lat_tan_e3_sqrt_amount_sqrt_dist"]] <- summary(f1sm7$residuals)
AICs[["lat_tan_e3_sqrt_amount_sqrt_dist"]] <- AIC(f1sm7)

f1sm7 <- lm(hoh ~ lat_tan_e4 * lon + lat_tan_e4 * sqrt(coast_line_distance) + lon * sqrt(coast_line_distance) + lat_tan_e4 * sqrt(amount_ocean_100200m) + lon * sqrt(amount_ocean_100200m) + sqrt(coast_line_distance) * sqrt(amount_ocean_100200m) + lat_tan_e4 * sqrt(amount_ocean_50200m) + lon * sqrt(amount_ocean_50200m) + sqrt(coast_line_distance) * sqrt(amount_ocean_50200m) + lat_tan_e4 * sqrt(amount_ocean_25000m) + lon * sqrt(amount_ocean_25000m) + sqrt(coast_line_distance) * sqrt(amount_ocean_25000m) + lat_tan_e4 * sqrt(amount_ocean_10100m) + lon * sqrt(amount_ocean_10100m) + sqrt(coast_line_distance) * sqrt(amount_ocean_10100m) + lat_tan_e4 * sqrt(amount_ocean_5050m) + lon * sqrt(amount_ocean_5050m) + sqrt(coast_line_distance) * sqrt(amount_ocean_5050m) + lat_tan_e4 * slope_5 + lon * slope_5 + slope_5 * I(solar_radiation^2) + lat_tan_e4 * I(solar_radiation^2) + lon * I(solar_radiation^2) + as.factor(aspect5_cl16) * I(solar_radiation^2) + as.factor(aspect5_cl16) * sqrt(coast_line_distance) + as.factor(aspect5_cl16) * slope_5 + lat_tan_e4 * as.factor(geol_rich) + lat_tan_e4 * as.factor(quart_gw) + lon * as.factor(quart_gw) + lat_tan_e4 * TPI_110m + sqrt(coast_line_distance) * TPI_110m + lat_tan_e4 * TWI + lon * TWI, data = skgrMergeF1)
summaries[["lat_tan_e4_sqrt_amount_sqrt_dist"]] <- summary(f1sm7$residuals)
AICs[["lat_tan_e4_sqrt_amount_sqrt_dist"]] <- AIC(f1sm7)

f1sm7 <- lm(hoh ~ lat_tan_e5 * lon + lat_tan_e5 * sqrt(coast_line_distance) + lon * sqrt(coast_line_distance) + lat_tan_e5 * sqrt(amount_ocean_100200m) + lon * sqrt(amount_ocean_100200m) + sqrt(coast_line_distance) * sqrt(amount_ocean_100200m) + lat_tan_e5 * sqrt(amount_ocean_50200m) + lon * sqrt(amount_ocean_50200m) + sqrt(coast_line_distance) * sqrt(amount_ocean_50200m) + lat_tan_e5 * sqrt(amount_ocean_25000m) + lon * sqrt(amount_ocean_25000m) + sqrt(coast_line_distance) * sqrt(amount_ocean_25000m) + lat_tan_e5 * sqrt(amount_ocean_10100m) + lon * sqrt(amount_ocean_10100m) + sqrt(coast_line_distance) * sqrt(amount_ocean_10100m) + lat_tan_e5 * sqrt(amount_ocean_5050m) + lon * sqrt(amount_ocean_5050m) + sqrt(coast_line_distance) * sqrt(amount_ocean_5050m) + lat_tan_e5 * slope_5 + lon * slope_5 + slope_5 * I(solar_radiation^2) + lat_tan_e5 * I(solar_radiation^2) + lon * I(solar_radiation^2) + as.factor(aspect5_cl16) * I(solar_radiation^2) + as.factor(aspect5_cl16) * sqrt(coast_line_distance) + as.factor(aspect5_cl16) * slope_5 + lat_tan_e5 * as.factor(geol_rich) + lat_tan_e5 * as.factor(quart_gw) + lon * as.factor(quart_gw) + lat_tan_e5 * TPI_110m + sqrt(coast_line_distance) * TPI_110m + lat_tan_e5 * TWI + lon * TWI, data = skgrMergeF1)
f1sm5 <- lm(hoh ~ lat_tan_e5 * lon + lat_tan_e5 * sqrt(coast_line_distance) + lon * sqrt(coast_line_distance) + lat_tan_e5 * log(amount_ocean_100200m) + lon * log(amount_ocean_100200m) + sqrt(coast_line_distance) * log(amount_ocean_100200m) + lat_tan_e5 * log(amount_ocean_50200m) + lon * log(amount_ocean_50200m) + sqrt(coast_line_distance) * log(amount_ocean_50200m) + lat_tan_e5 * log(amount_ocean_25000m) + lon * log(amount_ocean_25000m) + sqrt(coast_line_distance) * log(amount_ocean_25000m) + lat_tan_e5 * log(amount_ocean_10100m) + lon * log(amount_ocean_10100m) + sqrt(coast_line_distance) * log(amount_ocean_10100m) + lat_tan_e5 * log(amount_ocean_5050m) + lon * log(amount_ocean_5050m) + sqrt(coast_line_distance) * log(amount_ocean_5050m) + lat_tan_e5 * slope_5 + lon * slope_5 + slope_5 * I(solar_radiation^2) + lat_tan_e5 * I(solar_radiation^2) + lon * I(solar_radiation^2) + as.factor(aspect5_cl16) * I(solar_radiation^2) + as.factor(aspect5_cl16) * sqrt(coast_line_distance) + as.factor(aspect5_cl16) * slope_5 + lat_tan_e5 * as.factor(geol_rich) + lat_tan_e5 * as.factor(quart_gw) + lon * as.factor(quart_gw) + lat_tan_e5 * TPI_110m + sqrt(coast_line_distance) * TPI_110m + lat_tan_e5 * TWI + lon * TWI, data = skgrMergeF1)
AIC(f1sm7,f1sm5)
summaries[["lat_tan_e5_sqrt_amount_sqrt_dist"]] <- summary(f1sm7$residuals)
AICs[["lat_tan_e5_sqrt_amount_sqrt_dist"]] <- AIC(f1sm7)

f1sm7 <- lm(hoh ~ lat_tan_e6 * lon + lat_tan_e6 * sqrt(coast_line_distance) + lon * sqrt(coast_line_distance) + lat_tan_e6 * sqrt(amount_ocean_100200m) + lon * sqrt(amount_ocean_100200m) + sqrt(coast_line_distance) * sqrt(amount_ocean_100200m) + lat_tan_e6 * sqrt(amount_ocean_50200m) + lon * sqrt(amount_ocean_50200m) + sqrt(coast_line_distance) * sqrt(amount_ocean_50200m) + lat_tan_e6 * sqrt(amount_ocean_25000m) + lon * sqrt(amount_ocean_25000m) + sqrt(coast_line_distance) * sqrt(amount_ocean_25000m) + lat_tan_e6 * sqrt(amount_ocean_10100m) + lon * sqrt(amount_ocean_10100m) + sqrt(coast_line_distance) * sqrt(amount_ocean_10100m) + lat_tan_e6 * sqrt(amount_ocean_5050m) + lon * sqrt(amount_ocean_5050m) + sqrt(coast_line_distance) * sqrt(amount_ocean_5050m) + lat_tan_e6 * slope_5 + lon * slope_5 + slope_5 * I(solar_radiation^2) + lat_tan_e6 * I(solar_radiation^2) + lon * I(solar_radiation^2) + as.factor(aspect5_cl16) * I(solar_radiation^2) + as.factor(aspect5_cl16) * sqrt(coast_line_distance) + as.factor(aspect5_cl16) * slope_5 + lat_tan_e6 * as.factor(geol_rich) + lat_tan_e6 * as.factor(quart_gw) + lon * as.factor(quart_gw) + lat_tan_e6 * TPI_110m + sqrt(coast_line_distance) * TPI_110m + lat_tan_e6 * TWI + lon * TWI, data = skgrMergeF1)
summaries[["lat_tan_e6_sqrt_amount_sqrt_dist"]] <- summary(f1sm7$residuals)
AICs[["lat_tan_e6_sqrt_amount_sqrt_dist"]] <- AIC(f1sm7)

f1sm7 <- lm(hoh ~ lat_tan_e7 * lon + lat_tan_e7 * sqrt(coast_line_distance) + lon * sqrt(coast_line_distance) + lat_tan_e7 * sqrt(amount_ocean_100200m) + lon * sqrt(amount_ocean_100200m) + sqrt(coast_line_distance) * sqrt(amount_ocean_100200m) + lat_tan_e7 * sqrt(amount_ocean_50200m) + lon * sqrt(amount_ocean_50200m) + sqrt(coast_line_distance) * sqrt(amount_ocean_50200m) + lat_tan_e7 * sqrt(amount_ocean_25000m) + lon * sqrt(amount_ocean_25000m) + sqrt(coast_line_distance) * sqrt(amount_ocean_25000m) + lat_tan_e7 * sqrt(amount_ocean_10100m) + lon * sqrt(amount_ocean_10100m) + sqrt(coast_line_distance) * sqrt(amount_ocean_10100m) + lat_tan_e7 * sqrt(amount_ocean_5050m) + lon * sqrt(amount_ocean_5050m) + sqrt(coast_line_distance) * sqrt(amount_ocean_5050m) + lat_tan_e7 * slope_5 + lon * slope_5 + slope_5 * I(solar_radiation^2) + lat_tan_e7 * I(solar_radiation^2) + lon * I(solar_radiation^2) + as.factor(aspect5_cl16) * I(solar_radiation^2) + as.factor(aspect5_cl16) * sqrt(coast_line_distance) + as.factor(aspect5_cl16) * slope_5 + lat_tan_e7 * as.factor(geol_rich) + lat_tan_e7 * as.factor(quart_gw) + lon * as.factor(quart_gw) + lat_tan_e7 * TPI_110m + sqrt(coast_line_distance) * TPI_110m + lat_tan_e7 * TWI + lon * TWI, data = skgrMergeF1)
summaries[["lat_tan_e7_sqrt_amount_sqrt_dist"]] <- summary(f1sm7$residuals)
AICs[["lat_tan_e7_sqrt_amount_sqrt_dist"]] <- AIC(f1sm7)

f1sm7 <- lm(hoh ~ lat_tan_e8 * lon + lat_tan_e8 * sqrt(coast_line_distance) + lon * sqrt(coast_line_distance) + lat_tan_e8 * sqrt(amount_ocean_100200m) + lon * sqrt(amount_ocean_100200m) + sqrt(coast_line_distance) * sqrt(amount_ocean_100200m) + lat_tan_e8 * sqrt(amount_ocean_50200m) + lon * sqrt(amount_ocean_50200m) + sqrt(coast_line_distance) * sqrt(amount_ocean_50200m) + lat_tan_e8 * sqrt(amount_ocean_25000m) + lon * sqrt(amount_ocean_25000m) + sqrt(coast_line_distance) * sqrt(amount_ocean_25000m) + lat_tan_e8 * sqrt(amount_ocean_10100m) + lon * sqrt(amount_ocean_10100m) + sqrt(coast_line_distance) * sqrt(amount_ocean_10100m) + lat_tan_e8 * sqrt(amount_ocean_5050m) + lon * sqrt(amount_ocean_5050m) + sqrt(coast_line_distance) * sqrt(amount_ocean_5050m) + lat_tan_e8 * slope_5 + lon * slope_5 + slope_5 * I(solar_radiation^2) + lat_tan_e8 * I(solar_radiation^2) + lon * I(solar_radiation^2) + as.factor(aspect5_cl16) * I(solar_radiation^2) + as.factor(aspect5_cl16) * sqrt(coast_line_distance) + as.factor(aspect5_cl16) * slope_5 + lat_tan_e8 * as.factor(geol_rich) + lat_tan_e8 * as.factor(quart_gw) + lon * as.factor(quart_gw) + lat_tan_e8 * TPI_110m + sqrt(coast_line_distance) * TPI_110m + lat_tan_e8 * TWI + lon * TWI, data = skgrMergeF1)
summaries[["lat_tan_e8_sqrt_amount_sqrt_dist"]] <- summary(f1sm7$residuals)
AICs[["lat_tan_e8_sqrt_amount_sqrt_dist"]] <- AIC(f1sm7)

f1sm7 <- lm(hoh ~ lat_tan_e9 * lon + lat_tan_e9 * sqrt(coast_line_distance) + lon * sqrt(coast_line_distance) + lat_tan_e9 * sqrt(amount_ocean_100200m) + lon * sqrt(amount_ocean_100200m) + sqrt(coast_line_distance) * sqrt(amount_ocean_100200m) + lat_tan_e9 * sqrt(amount_ocean_50200m) + lon * sqrt(amount_ocean_50200m) + sqrt(coast_line_distance) * sqrt(amount_ocean_50200m) + lat_tan_e9 * sqrt(amount_ocean_25000m) + lon * sqrt(amount_ocean_25000m) + sqrt(coast_line_distance) * sqrt(amount_ocean_25000m) + lat_tan_e9 * sqrt(amount_ocean_10100m) + lon * sqrt(amount_ocean_10100m) + sqrt(coast_line_distance) * sqrt(amount_ocean_10100m) + lat_tan_e9 * sqrt(amount_ocean_5050m) + lon * sqrt(amount_ocean_5050m) + sqrt(coast_line_distance) * sqrt(amount_ocean_5050m) + lat_tan_e9 * slope_5 + lon * slope_5 + slope_5 * I(solar_radiation^2) + lat_tan_e9 * I(solar_radiation^2) + lon * I(solar_radiation^2) + as.factor(aspect5_cl16) * I(solar_radiation^2) + as.factor(aspect5_cl16) * sqrt(coast_line_distance) + as.factor(aspect5_cl16) * slope_5 + lat_tan_e9 * as.factor(geol_rich) + lat_tan_e9 * as.factor(quart_gw) + lon * as.factor(quart_gw) + lat_tan_e9 * TPI_110m + sqrt(coast_line_distance) * TPI_110m + lat_tan_e9 * TWI + lon * TWI, data = skgrMergeF1)
summaries[["lat_tan_e9_sqrt_amount_sqrt_dist"]] <- summary(f1sm7$residuals)
AICs[["lat_tan_e9_sqrt_amount_sqrt_dist"]] <- AIC(f1sm7)

f1sm7 <- lm(hoh ~ lat_tan_e10 * lon + lat_tan_e10 * sqrt(coast_line_distance) + lon * sqrt(coast_line_distance) + lat_tan_e10 * sqrt(amount_ocean_100200m) + lon * sqrt(amount_ocean_100200m) + sqrt(coast_line_distance) * sqrt(amount_ocean_100200m) + lat_tan_e10 * sqrt(amount_ocean_50200m) + lon * sqrt(amount_ocean_50200m) + sqrt(coast_line_distance) * sqrt(amount_ocean_50200m) + lat_tan_e10 * sqrt(amount_ocean_25000m) + lon * sqrt(amount_ocean_25000m) + sqrt(coast_line_distance) * sqrt(amount_ocean_25000m) + lat_tan_e10 * sqrt(amount_ocean_10100m) + lon * sqrt(amount_ocean_10100m) + sqrt(coast_line_distance) * sqrt(amount_ocean_10100m) + lat_tan_e10 * sqrt(amount_ocean_5050m) + lon * sqrt(amount_ocean_5050m) + sqrt(coast_line_distance) * sqrt(amount_ocean_5050m) + lat_tan_e10 * slope_5 + lon * slope_5 + slope_5 * I(solar_radiation^2) + lat_tan_e10 * I(solar_radiation^2) + lon * I(solar_radiation^2) + as.factor(aspect5_cl16) * I(solar_radiation^2) + as.factor(aspect5_cl16) * sqrt(coast_line_distance) + as.factor(aspect5_cl16) * slope_5 + lat_tan_e10 * as.factor(geol_rich) + lat_tan_e10 * as.factor(quart_gw) + lon * as.factor(quart_gw) + lat_tan_e10 * TPI_110m + sqrt(coast_line_distance) * TPI_110m + lat_tan_e10 * TWI + lon * TWI, data = skgrMergeF1)
summaries[["lat_tan_e10_sqrt_amount_sqrt_dist"]] <- summary(f1sm7$residuals)
AICs[["lat_tan_e10_sqrt_amount_sqrt_dist"]] <- AIC(f1sm7)

f1sm7 <- lm(hoh ~ lat_tan_e20 * lon + lat_tan_e20 * sqrt(coast_line_distance) + lon * sqrt(coast_line_distance) + lat_tan_e20 * sqrt(amount_ocean_100200m) + lon * sqrt(amount_ocean_100200m) + sqrt(coast_line_distance) * sqrt(amount_ocean_100200m) + lat_tan_e20 * sqrt(amount_ocean_50200m) + lon * sqrt(amount_ocean_50200m) + sqrt(coast_line_distance) * sqrt(amount_ocean_50200m) + lat_tan_e20 * sqrt(amount_ocean_25000m) + lon * sqrt(amount_ocean_25000m) + sqrt(coast_line_distance) * sqrt(amount_ocean_25000m) + lat_tan_e20 * sqrt(amount_ocean_10100m) + lon * sqrt(amount_ocean_10100m) + sqrt(coast_line_distance) * sqrt(amount_ocean_10100m) + lat_tan_e20 * sqrt(amount_ocean_5050m) + lon * sqrt(amount_ocean_5050m) + sqrt(coast_line_distance) * sqrt(amount_ocean_5050m) + lat_tan_e20 * slope_5 + lon * slope_5 + slope_5 * I(solar_radiation^2) + lat_tan_e20 * I(solar_radiation^2) + lon * I(solar_radiation^2) + as.factor(aspect5_cl16) * I(solar_radiation^2) + as.factor(aspect5_cl16) * sqrt(coast_line_distance) + as.factor(aspect5_cl16) * slope_5 + lat_tan_e20 * as.factor(geol_rich) + lat_tan_e20 * as.factor(quart_gw) + lon * as.factor(quart_gw) + lat_tan_e20 * TPI_110m + sqrt(coast_line_distance) * TPI_110m + lat_tan_e20 * TWI + lon * TWI, data = skgrMergeF1)
summaries[["lat_tan_e20_sqrt_amount_sqrt_dist"]] <- summary(f1sm7$residuals)
AICs[["lat_tan_e20_sqrt_amount_sqrt_dist"]] <- AIC(f1sm7)

f1sm7 <- lm(hoh ~ lat_tan_e30 * lon + lat_tan_e30 * sqrt(coast_line_distance) + lon * sqrt(coast_line_distance) + lat_tan_e30 * sqrt(amount_ocean_100200m) + lon * sqrt(amount_ocean_100200m) + sqrt(coast_line_distance) * sqrt(amount_ocean_100200m) + lat_tan_e30 * sqrt(amount_ocean_50200m) + lon * sqrt(amount_ocean_50200m) + sqrt(coast_line_distance) * sqrt(amount_ocean_50200m) + lat_tan_e30 * sqrt(amount_ocean_25000m) + lon * sqrt(amount_ocean_25000m) + sqrt(coast_line_distance) * sqrt(amount_ocean_25000m) + lat_tan_e30 * sqrt(amount_ocean_10100m) + lon * sqrt(amount_ocean_10100m) + sqrt(coast_line_distance) * sqrt(amount_ocean_10100m) + lat_tan_e30 * sqrt(amount_ocean_5050m) + lon * sqrt(amount_ocean_5050m) + sqrt(coast_line_distance) * sqrt(amount_ocean_5050m) + lat_tan_e30 * slope_5 + lon * slope_5 + slope_5 * I(solar_radiation^2) + lat_tan_e30 * I(solar_radiation^2) + lon * I(solar_radiation^2) + as.factor(aspect5_cl16) * I(solar_radiation^2) + as.factor(aspect5_cl16) * sqrt(coast_line_distance) + as.factor(aspect5_cl16) * slope_5 + lat_tan_e30 * as.factor(geol_rich) + lat_tan_e30 * as.factor(quart_gw) + lon * as.factor(quart_gw) + lat_tan_e30 * TPI_110m + sqrt(coast_line_distance) * TPI_110m + lat_tan_e30 * TWI + lon * TWI, data = skgrMergeF1)
summaries[["lat_tan_e30_sqrt_amount_sqrt_dist"]] <- summary(f1sm7$residuals)
AICs[["lat_tan_e30_sqrt_amount_sqrt_dist"]] <- AIC(f1sm7)

f1sm7 <- lm(hoh ~ lat_tan_e50 * lon + lat_tan_e50 * sqrt(coast_line_distance) + lon * sqrt(coast_line_distance) + lat_tan_e50 * sqrt(amount_ocean_100200m) + lon * sqrt(amount_ocean_100200m) + sqrt(coast_line_distance) * sqrt(amount_ocean_100200m) + lat_tan_e50 * sqrt(amount_ocean_50200m) + lon * sqrt(amount_ocean_50200m) + sqrt(coast_line_distance) * sqrt(amount_ocean_50200m) + lat_tan_e50 * sqrt(amount_ocean_25000m) + lon * sqrt(amount_ocean_25000m) + sqrt(coast_line_distance) * sqrt(amount_ocean_25000m) + lat_tan_e50 * sqrt(amount_ocean_10100m) + lon * sqrt(amount_ocean_10100m) + sqrt(coast_line_distance) * sqrt(amount_ocean_10100m) + lat_tan_e50 * sqrt(amount_ocean_5050m) + lon * sqrt(amount_ocean_5050m) + sqrt(coast_line_distance) * sqrt(amount_ocean_5050m) + lat_tan_e50 * slope_5 + lon * slope_5 + slope_5 * I(solar_radiation^2) + lat_tan_e50 * I(solar_radiation^2) + lon * I(solar_radiation^2) + as.factor(aspect5_cl16) * I(solar_radiation^2) + as.factor(aspect5_cl16) * sqrt(coast_line_distance) + as.factor(aspect5_cl16) * slope_5 + lat_tan_e50 * as.factor(geol_rich) + lat_tan_e50 * as.factor(quart_gw) + lon * as.factor(quart_gw) + lat_tan_e50 * TPI_110m + sqrt(coast_line_distance) * TPI_110m + lat_tan_e50 * TWI + lon * TWI, data = skgrMergeF1)
summaries[["lat_tan_e50_sqrt_amount_sqrt_dist"]] <- summary(f1sm7$residuals)
AICs[["lat_tan_e50_sqrt_amount_sqrt_dist"]] <- AIC(f1sm7)

f1sm7 <- lm(hoh ~ lat_tan_e100 * lon + lat_tan_e100 * sqrt(coast_line_distance) + lon * sqrt(coast_line_distance) + lat_tan_e100 * sqrt(amount_ocean_100200m) + lon * sqrt(amount_ocean_100200m) + sqrt(coast_line_distance) * sqrt(amount_ocean_100200m) + lat_tan_e100 * sqrt(amount_ocean_50200m) + lon * sqrt(amount_ocean_50200m) + sqrt(coast_line_distance) * sqrt(amount_ocean_50200m) + lat_tan_e100 * sqrt(amount_ocean_25000m) + lon * sqrt(amount_ocean_25000m) + sqrt(coast_line_distance) * sqrt(amount_ocean_25000m) + lat_tan_e100 * sqrt(amount_ocean_10100m) + lon * sqrt(amount_ocean_10100m) + sqrt(coast_line_distance) * sqrt(amount_ocean_10100m) + lat_tan_e100 * sqrt(amount_ocean_5050m) + lon * sqrt(amount_ocean_5050m) + sqrt(coast_line_distance) * sqrt(amount_ocean_5050m) + lat_tan_e100 * slope_5 + lon * slope_5 + slope_5 * I(solar_radiation^2) + lat_tan_e100 * I(solar_radiation^2) + lon * I(solar_radiation^2) + as.factor(aspect5_cl16) * I(solar_radiation^2) + as.factor(aspect5_cl16) * sqrt(coast_line_distance) + as.factor(aspect5_cl16) * slope_5 + lat_tan_e100 * as.factor(geol_rich) + lat_tan_e100 * as.factor(quart_gw) + lon * as.factor(quart_gw) + lat_tan_e100 * TPI_110m + sqrt(coast_line_distance) * TPI_110m + lat_tan_e100 * TWI + lon * TWI, data = skgrMergeF1)
summaries[["lat_tan_e100_sqrt_amount_sqrt_dist"]] <- summary(f1sm7$residuals)
AICs[["lat_tan_e100_sqrt_amount_sqrt_dist"]] <- AIC(f1sm7)

f1sm7 <- lm(hoh ~ lat * lon + lat * sqrt(coast_line_distance) + lon * sqrt(coast_line_distance) + lat * log(amount_ocean_100200m) + lon * log(amount_ocean_100200m) + sqrt(coast_line_distance) * log(amount_ocean_100200m) + lat * log(amount_ocean_50200m) + lon * log(amount_ocean_50200m) + sqrt(coast_line_distance) * log(amount_ocean_50200m) + lat * log(amount_ocean_25000m) + lon * log(amount_ocean_25000m) + sqrt(coast_line_distance) * log(amount_ocean_25000m) + lat * log(amount_ocean_10100m) + lon * log(amount_ocean_10100m) + sqrt(coast_line_distance) * log(amount_ocean_10100m) + lat * log(amount_ocean_5050m) + lon * log(amount_ocean_5050m) + sqrt(coast_line_distance) * log(amount_ocean_5050m) + lat * slope_5 + lon * slope_5 + slope_5 * I(solar_radiation^2) + lat * I(solar_radiation^2) + lon * I(solar_radiation^2) + as.factor(aspect5_cl16) * I(solar_radiation^2) + as.factor(aspect5_cl16) * sqrt(coast_line_distance) + as.factor(aspect5_cl16) * slope_5 + lat * as.factor(geol_rich) + lat * as.factor(quart_gw) + lon * as.factor(quart_gw) + lat * TPI_110m + sqrt(coast_line_distance) * TPI_110m + lat * TWI +lon * TWI, data = skgrMergeF1)
summaries[["lat_log_amount_sqrt_dist"]] <- summary(f1sm7$residuals)
AICs[["lat_log_amount_sqrt_dist"]] <- AIC(f1sm7)

f1sm7 <- lm(hoh ~ lat_tan * lon + lat_tan * sqrt(coast_line_distance) + lon * sqrt(coast_line_distance) + lat_tan * log(amount_ocean_100200m) + lon * log(amount_ocean_100200m) + sqrt(coast_line_distance) * log(amount_ocean_100200m) + lat_tan * log(amount_ocean_50200m) + lon * log(amount_ocean_50200m) + sqrt(coast_line_distance) * log(amount_ocean_50200m) + lat_tan * log(amount_ocean_25000m) + lon * log(amount_ocean_25000m) + sqrt(coast_line_distance) * log(amount_ocean_25000m) + lat_tan * log(amount_ocean_10100m) + lon * log(amount_ocean_10100m) + sqrt(coast_line_distance) * log(amount_ocean_10100m) + lat_tan * log(amount_ocean_5050m) + lon * log(amount_ocean_5050m) + sqrt(coast_line_distance) * log(amount_ocean_5050m) + lat_tan * slope_5 + lon * slope_5 + slope_5 * I(solar_radiation^2) + lat_tan * I(solar_radiation^2) + lon * I(solar_radiation^2) + as.factor(aspect5_cl16) * I(solar_radiation^2) + as.factor(aspect5_cl16) * sqrt(coast_line_distance) + as.factor(aspect5_cl16) * slope_5 + lat_tan * as.factor(geol_rich) + lat_tan * as.factor(quart_gw) + lon * as.factor(quart_gw) + lat_tan * TPI_110m + sqrt(coast_line_distance) * TPI_110m + lat_tan * TWI + lon * TWI, data = skgrMergeF1)
summaries[["lat_tan_log_amount_sqrt_dist"]] <- summary(f1sm7$residuals)
AICs[["lat_tan_log_amount_sqrt_dist"]] <- AIC(f1sm7)

f1sm7 <- lm(hoh ~ exp(lat_tan) * lon + exp(lat_tan) * sqrt(coast_line_distance) + lon * sqrt(coast_line_distance) + exp(lat_tan) * log(amount_ocean_100200m) + lon * log(amount_ocean_100200m) + sqrt(coast_line_distance) * log(amount_ocean_100200m) + exp(lat_tan) * log(amount_ocean_50200m) + lon * log(amount_ocean_50200m) + sqrt(coast_line_distance) * log(amount_ocean_50200m) + exp(lat_tan) * log(amount_ocean_25000m) + lon * log(amount_ocean_25000m) + sqrt(coast_line_distance) * log(amount_ocean_25000m) + exp(lat_tan) * log(amount_ocean_10100m) + lon * log(amount_ocean_10100m) + sqrt(coast_line_distance) * log(amount_ocean_10100m) + exp(lat_tan) * log(amount_ocean_5050m) + lon * log(amount_ocean_5050m) + sqrt(coast_line_distance) * log(amount_ocean_5050m) + exp(lat_tan) * slope_5 + lon * slope_5 + slope_5 * I(solar_radiation^2) + exp(lat_tan) * I(solar_radiation^2) + lon * I(solar_radiation^2) + as.factor(aspect5_cl16) * I(solar_radiation^2) + as.factor(aspect5_cl16) * sqrt(coast_line_distance) + as.factor(aspect5_cl16) * slope_5 + exp(lat_tan) * as.factor(geol_rich) + exp(lat_tan) * as.factor(quart_gw) + lon * as.factor(quart_gw) + exp(lat_tan) * TPI_110m + sqrt(coast_line_distance) * TPI_110m + exp(lat_tan) * TWI + lon * TWI, data = skgrMergeF1)
summaries[["exp(lat_tan)_log_amount_sqrt_dist"]] <- summary(f1sm7$residuals)
AICs[["exp(lat_tan)_log_amount_sqrt_dist"]] <- AIC(f1sm7)

f1sm7 <- lm(hoh ~ lat_tan_e2 * lon + lat_tan_e2 * sqrt(coast_line_distance) + lon * sqrt(coast_line_distance) + lat_tan_e2 * log(amount_ocean_100200m) + lon * log(amount_ocean_100200m) + sqrt(coast_line_distance) * log(amount_ocean_100200m) + lat_tan_e2 * log(amount_ocean_50200m) + lon * log(amount_ocean_50200m) + sqrt(coast_line_distance) * log(amount_ocean_50200m) + lat_tan_e2 * log(amount_ocean_25000m) + lon * log(amount_ocean_25000m) + sqrt(coast_line_distance) * log(amount_ocean_25000m) + lat_tan_e2 * log(amount_ocean_10100m) + lon * log(amount_ocean_10100m) + sqrt(coast_line_distance) * log(amount_ocean_10100m) + lat_tan_e2 * log(amount_ocean_5050m) + lon * log(amount_ocean_5050m) + sqrt(coast_line_distance) * log(amount_ocean_5050m) + lat_tan_e2 * slope_5 + lon * slope_5 + slope_5 * I(solar_radiation^2) + lat_tan_e2 * I(solar_radiation^2) + lon * I(solar_radiation^2) + as.factor(aspect5_cl16) * I(solar_radiation^2) + as.factor(aspect5_cl16) * sqrt(coast_line_distance) + as.factor(aspect5_cl16) * slope_5 + lat_tan_e2 * as.factor(geol_rich) + lat_tan_e2 * as.factor(quart_gw) + lon * as.factor(quart_gw) + lat_tan_e2 * TPI_110m + sqrt(coast_line_distance) * TPI_110m + lat_tan_e2 * TWI + lon * TWI, data = skgrMergeF1)
summaries[["lat_tan_e2_log_amount_sqrt_dist"]] <- summary(f1sm7$residuals)
AICs[["lat_tan_e2_log_amount_sqrt_dist"]] <- AIC(f1sm7)

f1sm7 <- lm(hoh ~ lat_tan_e3 * lon + lat_tan_e3 * sqrt(coast_line_distance) + lon * sqrt(coast_line_distance) + lat_tan_e3 * log(amount_ocean_100200m) + lon * log(amount_ocean_100200m) + sqrt(coast_line_distance) * log(amount_ocean_100200m) + lat_tan_e3 * log(amount_ocean_50200m) + lon * log(amount_ocean_50200m) + sqrt(coast_line_distance) * log(amount_ocean_50200m) + lat_tan_e3 * log(amount_ocean_25000m) + lon * log(amount_ocean_25000m) + sqrt(coast_line_distance) * log(amount_ocean_25000m) + lat_tan_e3 * log(amount_ocean_10100m) + lon * log(amount_ocean_10100m) + sqrt(coast_line_distance) * log(amount_ocean_10100m) + lat_tan_e3 * log(amount_ocean_5050m) + lon * log(amount_ocean_5050m) + sqrt(coast_line_distance) * log(amount_ocean_5050m) + lat_tan_e3 * slope_5 + lon * slope_5 + slope_5 * I(solar_radiation^2) + lat_tan_e3 * I(solar_radiation^2) + lon * I(solar_radiation^2) + as.factor(aspect5_cl16) * I(solar_radiation^2) + as.factor(aspect5_cl16) * sqrt(coast_line_distance) + as.factor(aspect5_cl16) * slope_5 + lat_tan_e3 * as.factor(geol_rich) + lat_tan_e3 * as.factor(quart_gw) + lon * as.factor(quart_gw) + lat_tan_e3 * TPI_110m + sqrt(coast_line_distance) * TPI_110m + lat_tan_e3 * TWI + lon * TWI, data = skgrMergeF1)
summaries[["lat_tan_e3_log_amount_sqrt_dist"]] <- summary(f1sm7$residuals)
AICs[["lat_tan_e3_log_amount_sqrt_dist"]] <- AIC(f1sm7)

f1sm7 <- lm(hoh ~ lat_tan_e4 * lon + lat_tan_e4 * sqrt(coast_line_distance) + lon * sqrt(coast_line_distance) + lat_tan_e4 * log(amount_ocean_100200m) + lon * log(amount_ocean_100200m) + sqrt(coast_line_distance) * log(amount_ocean_100200m) + lat_tan_e4 * log(amount_ocean_50200m) + lon * log(amount_ocean_50200m) + sqrt(coast_line_distance) * log(amount_ocean_50200m) + lat_tan_e4 * log(amount_ocean_25000m) + lon * log(amount_ocean_25000m) + sqrt(coast_line_distance) * log(amount_ocean_25000m) + lat_tan_e4 * log(amount_ocean_10100m) + lon * log(amount_ocean_10100m) + sqrt(coast_line_distance) * log(amount_ocean_10100m) + lat_tan_e4 * log(amount_ocean_5050m) + lon * log(amount_ocean_5050m) + sqrt(coast_line_distance) * log(amount_ocean_5050m) + lat_tan_e4 * slope_5 + lon * slope_5 + slope_5 * I(solar_radiation^2) + lat_tan_e4 * I(solar_radiation^2) + lon * I(solar_radiation^2) + as.factor(aspect5_cl16) * I(solar_radiation^2) + as.factor(aspect5_cl16) * sqrt(coast_line_distance) + as.factor(aspect5_cl16) * slope_5 + lat_tan_e4 * as.factor(geol_rich) + lat_tan_e4 * as.factor(quart_gw) + lon * as.factor(quart_gw) + lat_tan_e4 * TPI_110m + sqrt(coast_line_distance) * TPI_110m + lat_tan_e4 * TWI + lon * TWI, data = skgrMergeF1)
summaries[["lat_tan_e4_log_amount_sqrt_dist"]] <- summary(f1sm7$residuals)
AICs[["lat_tan_e4_log_amount_sqrt_dist"]] <- AIC(f1sm7)

f1sm7 <- lm(hoh ~ lat_tan_e5 * lon + lat_tan_e5 * sqrt(coast_line_distance) + lon * sqrt(coast_line_distance) + lat_tan_e5 * log(amount_ocean_100200m) + lon * log(amount_ocean_100200m) + sqrt(coast_line_distance) * log(amount_ocean_100200m) + lat_tan_e5 * log(amount_ocean_50200m) + lon * log(amount_ocean_50200m) + sqrt(coast_line_distance) * log(amount_ocean_50200m) + lat_tan_e5 * log(amount_ocean_25000m) + lon * log(amount_ocean_25000m) + sqrt(coast_line_distance) * log(amount_ocean_25000m) + lat_tan_e5 * log(amount_ocean_10100m) + lon * log(amount_ocean_10100m) + sqrt(coast_line_distance) * log(amount_ocean_10100m) + lat_tan_e5 * log(amount_ocean_5050m) + lon * log(amount_ocean_5050m) + sqrt(coast_line_distance) * log(amount_ocean_5050m) + lat_tan_e5 * slope_5 + lon * slope_5 + slope_5 * I(solar_radiation^2) + lat_tan_e5 * I(solar_radiation^2) + lon * I(solar_radiation^2) + as.factor(aspect5_cl16) * I(solar_radiation^2) + as.factor(aspect5_cl16) * sqrt(coast_line_distance) + as.factor(aspect5_cl16) * slope_5 + lat_tan_e5 * as.factor(geol_rich) + lat_tan_e5 * as.factor(quart_gw) + lon * as.factor(quart_gw) + lat_tan_e5 * TPI_110m + sqrt(coast_line_distance) * TPI_110m + lat_tan_e5 * TWI + lon * TWI, data = skgrMergeF1)
f1sm5 <- lm(hoh ~ lat_tan_e5 * lon + lat_tan_e5 * sqrt(coast_line_distance) + lon * sqrt(coast_line_distance) + lat_tan_e5 * log(amount_ocean_100200m) + lon * log(amount_ocean_100200m) + sqrt(coast_line_distance) * log(amount_ocean_100200m) + lat_tan_e5 * log(amount_ocean_50200m) + lon * log(amount_ocean_50200m) + sqrt(coast_line_distance) * log(amount_ocean_50200m) + lat_tan_e5 * log(amount_ocean_25000m) + lon * log(amount_ocean_25000m) + sqrt(coast_line_distance) * log(amount_ocean_25000m) + lat_tan_e5 * log(amount_ocean_10100m) + lon * log(amount_ocean_10100m) + sqrt(coast_line_distance) * log(amount_ocean_10100m) + lat_tan_e5 * log(amount_ocean_5050m) + lon * log(amount_ocean_5050m) + sqrt(coast_line_distance) * log(amount_ocean_5050m) + lat_tan_e5 * slope_5 + lon * slope_5 + slope_5 * I(solar_radiation^2) + lat_tan_e5 * I(solar_radiation^2) + lon * I(solar_radiation^2) + as.factor(aspect5_cl16) * I(solar_radiation^2) + as.factor(aspect5_cl16) * sqrt(coast_line_distance) + as.factor(aspect5_cl16) * slope_5 + lat_tan_e5 * as.factor(geol_rich) + lat_tan_e5 * as.factor(quart_gw) + lon * as.factor(quart_gw) + lat_tan_e5 * TPI_110m + sqrt(coast_line_distance) * TPI_110m + lat_tan_e5 * TWI + lon * TWI, data = skgrMergeF1)
AIC(f1sm7,f1sm5)
summaries[["lat_tan_e5_log_amount_sqrt_dist"]] <- summary(f1sm7$residuals)
AICs[["lat_tan_e5_log_amount_sqrt_dist"]] <- AIC(f1sm7)

f1sm7 <- lm(hoh ~ lat_tan_e6 * lon + lat_tan_e6 * sqrt(coast_line_distance) + lon * sqrt(coast_line_distance) + lat_tan_e6 * log(amount_ocean_100200m) + lon * log(amount_ocean_100200m) + sqrt(coast_line_distance) * log(amount_ocean_100200m) + lat_tan_e6 * log(amount_ocean_50200m) + lon * log(amount_ocean_50200m) + sqrt(coast_line_distance) * log(amount_ocean_50200m) + lat_tan_e6 * log(amount_ocean_25000m) + lon * log(amount_ocean_25000m) + sqrt(coast_line_distance) * log(amount_ocean_25000m) + lat_tan_e6 * log(amount_ocean_10100m) + lon * log(amount_ocean_10100m) + sqrt(coast_line_distance) * log(amount_ocean_10100m) + lat_tan_e6 * log(amount_ocean_5050m) + lon * log(amount_ocean_5050m) + sqrt(coast_line_distance) * log(amount_ocean_5050m) + lat_tan_e6 * slope_5 + lon * slope_5 + slope_5 * I(solar_radiation^2) + lat_tan_e6 * I(solar_radiation^2) + lon * I(solar_radiation^2) + as.factor(aspect5_cl16) * I(solar_radiation^2) + as.factor(aspect5_cl16) * sqrt(coast_line_distance) + as.factor(aspect5_cl16) * slope_5 + lat_tan_e6 * as.factor(geol_rich) + lat_tan_e6 * as.factor(quart_gw) + lon * as.factor(quart_gw) + lat_tan_e6 * TPI_110m + sqrt(coast_line_distance) * TPI_110m + lat_tan_e6 * TWI + lon * TWI, data = skgrMergeF1)
summaries[["lat_tan_e6_log_amount_sqrt_dist"]] <- summary(f1sm7$residuals)
AICs[["lat_tan_e6_log_amount_sqrt_dist"]] <- AIC(f1sm7)

f1sm7 <- lm(hoh ~ lat_tan_e7 * lon + lat_tan_e7 * sqrt(coast_line_distance) + lon * sqrt(coast_line_distance) + lat_tan_e7 * log(amount_ocean_100200m) + lon * log(amount_ocean_100200m) + sqrt(coast_line_distance) * log(amount_ocean_100200m) + lat_tan_e7 * log(amount_ocean_50200m) + lon * log(amount_ocean_50200m) + sqrt(coast_line_distance) * log(amount_ocean_50200m) + lat_tan_e7 * log(amount_ocean_25000m) + lon * log(amount_ocean_25000m) + sqrt(coast_line_distance) * log(amount_ocean_25000m) + lat_tan_e7 * log(amount_ocean_10100m) + lon * log(amount_ocean_10100m) + sqrt(coast_line_distance) * log(amount_ocean_10100m) + lat_tan_e7 * log(amount_ocean_5050m) + lon * log(amount_ocean_5050m) + sqrt(coast_line_distance) * log(amount_ocean_5050m) + lat_tan_e7 * slope_5 + lon * slope_5 + slope_5 * I(solar_radiation^2) + lat_tan_e7 * I(solar_radiation^2) + lon * I(solar_radiation^2) + as.factor(aspect5_cl16) * I(solar_radiation^2) + as.factor(aspect5_cl16) * sqrt(coast_line_distance) + as.factor(aspect5_cl16) * slope_5 + lat_tan_e7 * as.factor(geol_rich) + lat_tan_e7 * as.factor(quart_gw) + lon * as.factor(quart_gw) + lat_tan_e7 * TPI_110m + sqrt(coast_line_distance) * TPI_110m + lat_tan_e7 * TWI + lon * TWI, data = skgrMergeF1)
summaries[["lat_tan_e7_log_amount_sqrt_dist"]] <- summary(f1sm7$residuals)
AICs[["lat_tan_e7_log_amount_sqrt_dist"]] <- AIC(f1sm7)

f1sm7 <- lm(hoh ~ lat_tan_e8 * lon + lat_tan_e8 * sqrt(coast_line_distance) + lon * sqrt(coast_line_distance) + lat_tan_e8 * log(amount_ocean_100200m) + lon * log(amount_ocean_100200m) + sqrt(coast_line_distance) * log(amount_ocean_100200m) + lat_tan_e8 * log(amount_ocean_50200m) + lon * log(amount_ocean_50200m) + sqrt(coast_line_distance) * log(amount_ocean_50200m) + lat_tan_e8 * log(amount_ocean_25000m) + lon * log(amount_ocean_25000m) + sqrt(coast_line_distance) * log(amount_ocean_25000m) + lat_tan_e8 * log(amount_ocean_10100m) + lon * log(amount_ocean_10100m) + sqrt(coast_line_distance) * log(amount_ocean_10100m) + lat_tan_e8 * log(amount_ocean_5050m) + lon * log(amount_ocean_5050m) + sqrt(coast_line_distance) * log(amount_ocean_5050m) + lat_tan_e8 * slope_5 + lon * slope_5 + slope_5 * I(solar_radiation^2) + lat_tan_e8 * I(solar_radiation^2) + lon * I(solar_radiation^2) + as.factor(aspect5_cl16) * I(solar_radiation^2) + as.factor(aspect5_cl16) * sqrt(coast_line_distance) + as.factor(aspect5_cl16) * slope_5 + lat_tan_e8 * as.factor(geol_rich) + lat_tan_e8 * as.factor(quart_gw) + lon * as.factor(quart_gw) + lat_tan_e8 * TPI_110m + sqrt(coast_line_distance) * TPI_110m + lat_tan_e8 * TWI + lon * TWI, data = skgrMergeF1)
summaries[["lat_tan_e8_log_amount_sqrt_dist"]] <- summary(f1sm7$residuals)
AICs[["lat_tan_e8_log_amount_sqrt_dist"]] <- AIC(f1sm7)

f1sm7 <- lm(hoh ~ lat_tan_e9 * lon + lat_tan_e9 * sqrt(coast_line_distance) + lon * sqrt(coast_line_distance) + lat_tan_e9 * log(amount_ocean_100200m) + lon * log(amount_ocean_100200m) + sqrt(coast_line_distance) * log(amount_ocean_100200m) + lat_tan_e9 * log(amount_ocean_50200m) + lon * log(amount_ocean_50200m) + sqrt(coast_line_distance) * log(amount_ocean_50200m) + lat_tan_e9 * log(amount_ocean_25000m) + lon * log(amount_ocean_25000m) + sqrt(coast_line_distance) * log(amount_ocean_25000m) + lat_tan_e9 * log(amount_ocean_10100m) + lon * log(amount_ocean_10100m) + sqrt(coast_line_distance) * log(amount_ocean_10100m) + lat_tan_e9 * log(amount_ocean_5050m) + lon * log(amount_ocean_5050m) + sqrt(coast_line_distance) * log(amount_ocean_5050m) + lat_tan_e9 * slope_5 + lon * slope_5 + slope_5 * I(solar_radiation^2) + lat_tan_e9 * I(solar_radiation^2) + lon * I(solar_radiation^2) + as.factor(aspect5_cl16) * I(solar_radiation^2) + as.factor(aspect5_cl16) * sqrt(coast_line_distance) + as.factor(aspect5_cl16) * slope_5 + lat_tan_e9 * as.factor(geol_rich) + lat_tan_e9 * as.factor(quart_gw) + lon * as.factor(quart_gw) + lat_tan_e9 * TPI_110m + sqrt(coast_line_distance) * TPI_110m + lat_tan_e9 * TWI + lon * TWI, data = skgrMergeF1)
summaries[["lat_tan_e9_log_amount_sqrt_dist"]] <- summary(f1sm7$residuals)
AICs[["lat_tan_e9_log_amount_sqrt_dist"]] <- AIC(f1sm7)

f1sm7 <- lm(hoh ~ lat_tan_e10 * lon + lat_tan_e10 * sqrt(coast_line_distance) + lon * sqrt(coast_line_distance) + lat_tan_e10 * log(amount_ocean_100200m) + lon * log(amount_ocean_100200m) + sqrt(coast_line_distance) * log(amount_ocean_100200m) + lat_tan_e10 * log(amount_ocean_50200m) + lon * log(amount_ocean_50200m) + sqrt(coast_line_distance) * log(amount_ocean_50200m) + lat_tan_e10 * log(amount_ocean_25000m) + lon * log(amount_ocean_25000m) + sqrt(coast_line_distance) * log(amount_ocean_25000m) + lat_tan_e10 * log(amount_ocean_10100m) + lon * log(amount_ocean_10100m) + sqrt(coast_line_distance) * log(amount_ocean_10100m) + lat_tan_e10 * log(amount_ocean_5050m) + lon * log(amount_ocean_5050m) + sqrt(coast_line_distance) * log(amount_ocean_5050m) + lat_tan_e10 * slope_5 + lon * slope_5 + slope_5 * I(solar_radiation^2) + lat_tan_e10 * I(solar_radiation^2) + lon * I(solar_radiation^2) + as.factor(aspect5_cl16) * I(solar_radiation^2) + as.factor(aspect5_cl16) * sqrt(coast_line_distance) + as.factor(aspect5_cl16) * slope_5 + lat_tan_e10 * as.factor(geol_rich) + lat_tan_e10 * as.factor(quart_gw) + lon * as.factor(quart_gw) + lat_tan_e10 * TPI_110m + sqrt(coast_line_distance) * TPI_110m + lat_tan_e10 * TWI + lon * TWI, data = skgrMergeF1)
summaries[["lat_tan_e10_log_amount_sqrt_dist"]] <- summary(f1sm7$residuals)
AICs[["lat_tan_e10_log_amount_sqrt_dist"]] <- AIC(f1sm7)

f1sm7 <- lm(hoh ~ lat_tan_e20 * lon + lat_tan_e20 * sqrt(coast_line_distance) + lon * sqrt(coast_line_distance) + lat_tan_e20 * log(amount_ocean_100200m) + lon * log(amount_ocean_100200m) + sqrt(coast_line_distance) * log(amount_ocean_100200m) + lat_tan_e20 * log(amount_ocean_50200m) + lon * log(amount_ocean_50200m) + sqrt(coast_line_distance) * log(amount_ocean_50200m) + lat_tan_e20 * log(amount_ocean_25000m) + lon * log(amount_ocean_25000m) + sqrt(coast_line_distance) * log(amount_ocean_25000m) + lat_tan_e20 * log(amount_ocean_10100m) + lon * log(amount_ocean_10100m) + sqrt(coast_line_distance) * log(amount_ocean_10100m) + lat_tan_e20 * log(amount_ocean_5050m) + lon * log(amount_ocean_5050m) + sqrt(coast_line_distance) * log(amount_ocean_5050m) + lat_tan_e20 * slope_5 + lon * slope_5 + slope_5 * I(solar_radiation^2) + lat_tan_e20 * I(solar_radiation^2) + lon * I(solar_radiation^2) + as.factor(aspect5_cl16) * I(solar_radiation^2) + as.factor(aspect5_cl16) * sqrt(coast_line_distance) + as.factor(aspect5_cl16) * slope_5 + lat_tan_e20 * as.factor(geol_rich) + lat_tan_e20 * as.factor(quart_gw) + lon * as.factor(quart_gw) + lat_tan_e20 * TPI_110m + sqrt(coast_line_distance) * TPI_110m + lat_tan_e20 * TWI + lon * TWI, data = skgrMergeF1)
summaries[["lat_tan_e20_log_amount_sqrt_dist"]] <- summary(f1sm7$residuals)
AICs[["lat_tan_e20_log_amount_sqrt_dist"]] <- AIC(f1sm7)

f1sm7 <- lm(hoh ~ lat_tan_e30 * lon + lat_tan_e30 * sqrt(coast_line_distance) + lon * sqrt(coast_line_distance) + lat_tan_e30 * log(amount_ocean_100200m) + lon * log(amount_ocean_100200m) + sqrt(coast_line_distance) * log(amount_ocean_100200m) + lat_tan_e30 * log(amount_ocean_50200m) + lon * log(amount_ocean_50200m) + sqrt(coast_line_distance) * log(amount_ocean_50200m) + lat_tan_e30 * log(amount_ocean_25000m) + lon * log(amount_ocean_25000m) + sqrt(coast_line_distance) * log(amount_ocean_25000m) + lat_tan_e30 * log(amount_ocean_10100m) + lon * log(amount_ocean_10100m) + sqrt(coast_line_distance) * log(amount_ocean_10100m) + lat_tan_e30 * log(amount_ocean_5050m) + lon * log(amount_ocean_5050m) + sqrt(coast_line_distance) * log(amount_ocean_5050m) + lat_tan_e30 * slope_5 + lon * slope_5 + slope_5 * I(solar_radiation^2) + lat_tan_e30 * I(solar_radiation^2) + lon * I(solar_radiation^2) + as.factor(aspect5_cl16) * I(solar_radiation^2) + as.factor(aspect5_cl16) * sqrt(coast_line_distance) + as.factor(aspect5_cl16) * slope_5 + lat_tan_e30 * as.factor(geol_rich) + lat_tan_e30 * as.factor(quart_gw) + lon * as.factor(quart_gw) + lat_tan_e30 * TPI_110m + sqrt(coast_line_distance) * TPI_110m + lat_tan_e30 * TWI + lon * TWI, data = skgrMergeF1)
summaries[["lat_tan_e30_log_amount_sqrt_dist"]] <- summary(f1sm7$residuals)
AICs[["lat_tan_e30_log_amount_sqrt_dist"]] <- AIC(f1sm7)

f1sm7 <- lm(hoh ~ lat_tan_e50 * lon + lat_tan_e50 * sqrt(coast_line_distance) + lon * sqrt(coast_line_distance) + lat_tan_e50 * log(amount_ocean_100200m) + lon * log(amount_ocean_100200m) + sqrt(coast_line_distance) * log(amount_ocean_100200m) + lat_tan_e50 * log(amount_ocean_50200m) + lon * log(amount_ocean_50200m) + sqrt(coast_line_distance) * log(amount_ocean_50200m) + lat_tan_e50 * log(amount_ocean_25000m) + lon * log(amount_ocean_25000m) + sqrt(coast_line_distance) * log(amount_ocean_25000m) + lat_tan_e50 * log(amount_ocean_10100m) + lon * log(amount_ocean_10100m) + sqrt(coast_line_distance) * log(amount_ocean_10100m) + lat_tan_e50 * log(amount_ocean_5050m) + lon * log(amount_ocean_5050m) + sqrt(coast_line_distance) * log(amount_ocean_5050m) + lat_tan_e50 * slope_5 + lon * slope_5 + slope_5 * I(solar_radiation^2) + lat_tan_e50 * I(solar_radiation^2) + lon * I(solar_radiation^2) + as.factor(aspect5_cl16) * I(solar_radiation^2) + as.factor(aspect5_cl16) * sqrt(coast_line_distance) + as.factor(aspect5_cl16) * slope_5 + lat_tan_e50 * as.factor(geol_rich) + lat_tan_e50 * as.factor(quart_gw) + lon * as.factor(quart_gw) + lat_tan_e50 * TPI_110m + sqrt(coast_line_distance) * TPI_110m + lat_tan_e50 * TWI + lon * TWI, data = skgrMergeF1)
summaries[["lat_tan_e50_log_amount_sqrt_dist"]] <- summary(f1sm7$residuals)
AICs[["lat_tan_e50_log_amount_sqrt_dist"]] <- AIC(f1sm7)

f1sm7 <- lm(hoh ~ lat_tan_e100 * lon + lat_tan_e100 * sqrt(coast_line_distance) + lon * sqrt(coast_line_distance) + lat_tan_e100 * log(amount_ocean_100200m) + lon * log(amount_ocean_100200m) + sqrt(coast_line_distance) * log(amount_ocean_100200m) + lat_tan_e100 * log(amount_ocean_50200m) + lon * log(amount_ocean_50200m) + sqrt(coast_line_distance) * log(amount_ocean_50200m) + lat_tan_e100 * log(amount_ocean_25000m) + lon * log(amount_ocean_25000m) + sqrt(coast_line_distance) * log(amount_ocean_25000m) + lat_tan_e100 * log(amount_ocean_10100m) + lon * log(amount_ocean_10100m) + sqrt(coast_line_distance) * log(amount_ocean_10100m) + lat_tan_e100 * log(amount_ocean_5050m) + lon * log(amount_ocean_5050m) + sqrt(coast_line_distance) * log(amount_ocean_5050m) + lat_tan_e100 * slope_5 + lon * slope_5 + slope_5 * I(solar_radiation^2) + lat_tan_e100 * I(solar_radiation^2) + lon * I(solar_radiation^2) + as.factor(aspect5_cl16) * I(solar_radiation^2) + as.factor(aspect5_cl16) * sqrt(coast_line_distance) + as.factor(aspect5_cl16) * slope_5 + lat_tan_e100 * as.factor(geol_rich) + lat_tan_e100 * as.factor(quart_gw) + lon * as.factor(quart_gw) + lat_tan_e100 * TPI_110m + sqrt(coast_line_distance) * TPI_110m + lat_tan_e100 * TWI + lon * TWI, data = skgrMergeF1)
summaries[["lat_tan_e100_log_amount_sqrt_dist"]] <- summary(f1sm7$residuals)
AICs[["lat_tan_e100_log_amount_sqrt_dist"]] <- AIC(f1sm7)




##############################################################################
#Measure distance from coast line to land
g.region -p rast=DEM_10m align=DEM_10m
r.grow.distance --overwrite input=N50_2013_hav_inv distance=N50_2013_kystlinje_dist metric=euclidean

g.region -p rast=DEM_10m res=50 n=n+20
r.neighbors --o -c --verbose input=N50_2013_skog_DEM_max_5050m output=N50_2013_skog_DEM_max_5050m_stddev method=stddev size=101
g.region -p rast=DEM_10m res=100 n=n+20
r.neighbors --o -c --verbose input=N50_2013_skog_DEM_max_10100m output=N50_2013_skog_DEM_max_10100m_stdev method=stddev size=101
g.region -p rast=DEM_10m res=200 n=n+120
r.neighbors --o -c --verbose input=N50_2013_skog_DEM_max_25000m output=N50_2013_skog_DEM_max_25000m_stddev method=stddev size=125
r.neighbors --o -c --verbose input=N50_2013_skog_DEM_max_50200m output=N50_2013_skog_DEM_max_50200m_stddev method=stddev size=251

g.region -p rast=DEM_10m align=DEM_10m
r.out.maxent_swd bgr_mask=N50_2013_skog_aapent_filter_50m alias_input=/home/stefan/Okokart/alias3.csv bgr_output=/home/stefan/Okokart/skgr3_tmp.csv -z --v
cat /home/stefan/Okokart/skgr3_tmp.csv | cut -f2-4 -d',' > /home/stefan/Okokart/skgr3.csv

skgrMergeF5s2<- skgrm[skgrm$max_forest_sum_all/(skgrm$TPI_5100m_stddev_n+0.1)<=1500,]
length(skgrMergeF5s2$hoh)
skgrMergeF5s2<- skgrMergeF5s2[skgrMergeF5s2$max_forest_sum_all/(skgrMergeF5s2$tvn+0.1)<=1500,]
length(skgrMergeF5s2$hoh)
skgrMergeF5s2<- skgrMergeF5s2[skgrMergeF5s2$max_forest_sum/(skgrMergeF5s2$tvn+0.25)<=800,]
length(skgrMergeF5s2$hoh)

#####################################################
#####################################################
#Plot altitude of reference points
png('/home/stefan/Okokart/Filtering_reference_altitude_all.png', width = 5000, height = 5000, units = "px", pointsize = 4, bg = "white", res = 10, type = c("cairo"))
zcol <- level.colors(skgrm$hoh, at = c(0, 50, 100, 150, 200, 250, 300, 350, 400, 450, 500, 550, 600, 650, 700, 750, 800, 850, 900, 950, 1000, 1050, 1100, 1150, 1200, 1250, 1300), col.regions=terrain.colors(27), interpolate=c("linear"))
xyplot(Y ~ X | "Altitude of all possible reference points", data=skgrm, col=zcol, aspect = 1, .aspect.ratio = 1)
dev.off()
skgr2 <- read.csv('/home/stefan/Okokart/skgr3.csv', sep=",", header=TRUE)
skgrm <- merge(skgrm, skgr2, by=c("X","Y"))


#####################################################
#####################################################
###Global filters:
#Confirmed:
#max_forest_250m
#max_forest_550m
#slope_next (min=0)
#max_forest_2550m_patch
#max_forest_5050m_patch
#max_forest_1050m
##max_forest_5050m_patch
##max_forest_10100m_patch
##max_forest_25000m_patch
##max_forest_50200m_patch
##max_forest_sum_all_patch
##max_forest_sum_patch
##avg_alt_forest_patch

#Check:
#DISCONTINUITIES

#slope_next (max = 15)
#actuality
#continentality
#max_patch_filter
#tetraterm_kor (nodata and 2773)
#coast_distance

#Make a variant of max_patch_filter
#skgrm$max_patch_filter <- ifelse(skgrm$max_alt_open_patch > (skgrm$max_alt_forest_patch + 100), 1, 0) #Following Moen (1998)

#Variable filters
#Use max_forest_X_patch and allow for more variation in rugged terrain (two versions (little variation and large variation))
#Leave 50200m out and allow for more variation in rugged terrain (two versions (little variation and large variation))
#Leave 25000m out and allow for more variation in rugged terrain (two versions (little variation and large variation))

#Run full modell (including also quart_gw and all reasonable interaction)
#try gls with max_forest_sum as variance structure
#try gls with max_forest_sum as variance structure

#Try transforming amount of ocean (0-1) -1*
#Try leaving out coast_distance
#Simplify modell 

#####################################################
skgrm$max_forest_sum_local <- skgrm$max_forest_250m+skgrm$max_forest_550m+skgrm$max_forest_1050m+skgrm$max_forest_2550m
skgrm$max_forest_sum_all <- skgrm$max_forest_50200m+skgrm$max_forest_25000m+skgrm$max_forest_10100m+skgrm$max_forest_5050m+skgrm$max_forest_2550m+skgrm$max_forest_1050m+skgrm$max_forest_550m+skgrm$max_forest_250m

skgrm$continuity_large_scale <- unlist(lapply(1:length(skgrm$max_forest_50200m), function(x) max(c(skgrm$max_forest_50200m[x]/(skgrm$max_forest_25000m[x]+1),skgrm$max_forest_25000m[x]/(skgrm$max_forest_10100m[x]+1),skgrm$max_forest_10100m[x]/(skgrm$max_forest_5050m[x]+1),skgrm$max_forest_5050m[x]/(skgrm$max_forest_2550m[x]+1)))))
skgrm$continuity_small_scale <- unlist(lapply(1:length(skgrm$max_forest_2550m), function(x) max(c(skgrm$max_forest_2550m[x]/(skgrm$max_forest_1050m[x]+1),skgrm$max_forest_1050m[x]/(skgrm$max_forest_550m[x]+1),skgrm$max_forest_550m[x]/(skgrm$max_forest_250m[x]+1)))))


# patches_250m <- gapply(skgrm, c("max_forest_250m"), FUN=function(x) min(x), groups=as.factor(skgrm$forest_patch))
# patches_550m <- gapply(skgrm, c("max_forest_550m"), FUN=function(x) min(x), groups=as.factor(skgrm$forest_patch))
# patches_1050m <- gapply(skgrm, c("max_forest_1050m"), FUN=function(x) min(x), groups=as.factor(skgrm$forest_patch))
# patches_2550m <- gapply(skgrm, c("max_forest_2550m"), FUN=function(x) min(x), groups=as.factor(skgrm$forest_patch))
# patches_5050m <- gapply(skgrm, c("max_forest_5050m"), FUN=function(x) min(x), groups=as.factor(skgrm$forest_patch))
# patches_10100m <- gapply(skgrm, c("max_forest_10100m"), FUN=function(x) min(x), groups=as.factor(skgrm$forest_patch))
# patches_25000m <- gapply(skgrm, c("max_forest_25000m"), FUN=function(x) min(x), groups=as.factor(skgrm$forest_patch))
# patches_50200m <- gapply(skgrm, c("max_forest_50200m"), FUN=function(x) min(x), groups=as.factor(skgrm$forest_patch))

# patches <- merge(merge(merge(merge(merge(merge(merge(data.frame(forest_patch=as.integer(names(patches_250m)), max_forest_250m_patch=patches_250m), data.frame(forest_patch=as.integer(names(patches_550m)), max_forest_550m_patch=patches_550m), by="forest_patch"), data.frame(forest_patch=as.integer(names(patches_1050m)), max_forest_1050m_patch=patches_1050m), by="forest_patch"), data.frame(forest_patch=as.integer(names(patches_2550m)), max_forest_2550m_patch=patches_2550m), by="forest_patch"), data.frame(forest_patch=as.integer(names(patches_5050m)), max_forest_5050m_patch=patches_5050m), by="forest_patch"), data.frame(forest_patch=as.integer(names(patches_10100m)), max_forest_10100m_patch=patches_10100m), by="forest_patch"), data.frame(forest_patch=as.integer(names(patches_25000m)), max_forest_25000m_patch=patches_25000m), by="forest_patch"), data.frame(forest_patch=as.integer(names(patches_50200m)), max_forest_50200m_patch=patches_50200m), by="forest_patch")
# patches$max_forest_sum_patch <- patches$max_forest_2550m_patch+patches$max_forest_5050m_patch+patches$max_forest_10100m_patch+patches$max_forest_25000m_patch+patches$max_forest_50200m_patch
# patches$max_forest_sum_all_patch <- patches$max_forest_250m_patch+patches$max_forest_550m_patch+patches$max_forest_1050m_patch+patches$max_forest_2550m_patch+patches$max_forest_5050m_patch+patches$max_forest_10100m_patch+patches$max_forest_25000m_patch+patches$max_forest_50200m_patch
# skgrm <- merge(skgrm, patches, by=c("forest_patch"))

# open_patches <- gapply(skgrm, c("hoh"), FUN=function(x) max(x), groups=paste(as.factor(skgrm$forest_patch),as.factor(skgrm$max_alt_open_patch),as.factor(skgrm$avg_alt_open_patch), sep="_"))
# open_patches <- gapply(skgrm, c("hoh"), FUN=function(x) max(x), groups=paste(as.factor(skgrm$forest_patch),as.factor(skgrm$max_alt_open_patch),as.factor(skgrm$avg_alt_open_patch), sep="_"))

# skgrm$TPI_5100m_stddev_n <- (skgrm$TPI_5100m_stddev-min(skgrm$TPI_5100m_stddev))/(max(skgrm$TPI_5100m_stddev)-min(skgrm$TPI_5100m_stddev))
# skgrm$TPI_3100m_stddev_n <- (skgrm$TPI_3100m_stddev-min(skgrm$TPI_3100m_stddev))/(max(skgrm$TPI_3100m_stddev)-min(skgrm$TPI_3100m_stddev))
# skgrm$TPI_1100m_stddev_n <- (skgrm$TPI_1100m_stddev-min(skgrm$TPI_1100m_stddev))/(max(skgrm$TPI_1100m_stddev)-min(skgrm$TPI_1100m_stddev))
# skgrm$tv <- (skgrm$TPI_5100m_stddev_n+skgrm$TPI_3100m_stddev_n+skgrm$TPI_1100m_stddev_n)
# skgrm$tvn <- (skgrm$tv-min(skgrm$tv))/(max(skgrm$tv)-min(skgrm$tv))

# patches_TPI_5100m_stddev_n <- by(skgrm$TPI_5100m_stddev_n,skgrm$forest_patch,FUN=mean)
# patches_TPI_3100m_stddev_n <- by(skgrm$TPI_3100m_stddev_n,skgrm$forest_patch,FUN=mean)
# patches_TPI_1100m_stddev_n <- by(skgrm$TPI_1100m_stddev_n,skgrm$forest_patch,FUN=mean)
# patches_tvn <- by(skgrm$tvn,skgrm$forest_patch,FUN=mean)

# skgrm <- merge(skgrm, merge(merge(merge(data.frame(forest_patch=as.integer(names(patches_TPI_5100m_stddev_n)), TPI_5100m_stddev_n_patch=as.vector(patches_TPI_5100m_stddev_n)), data.frame(forest_patch=as.integer(names(patches_TPI_3100m_stddev_n)), TPI_3100m_stddev_n_patch=as.vector(patches_TPI_3100m_stddev_n)), by="forest_patch"), data.frame(forest_patch=as.integer(names(patches_TPI_1100m_stddev_n)), TPI_1100m_stddev_n_patch=as.vector(patches_TPI_1100m_stddev_n)), by="forest_patch"), data.frame(forest_patch=as.integer(names(patches_tvn)), tvn_patch=as.vector(patches_tvn)), by="forest_patch"), by="forest_patch")

# patches_gid_TPI_5100m_stddev_n <- by(skgrm$TPI_5100m_stddev_n,skgrm$GID,FUN=mean)
# patches_gid_TPI_3100m_stddev_n <- by(skgrm$TPI_3100m_stddev_n,skgrm$GID,FUN=mean)
# patches_gid_TPI_1100m_stddev_n <- by(skgrm$TPI_1100m_stddev_n,skgrm$GID,FUN=mean)
# patches_gid_tvn <- by(skgrm$tvn,skgrm$GID,FUN=mean)

# skgrm <- merge(skgrm, merge(merge(merge(data.frame(GID=names(patches_gid_TPI_5100m_stddev_n), TPI_5100m_stddev_n_gid_patch=as.vector(patches_gid_TPI_5100m_stddev_n)), data.frame(GID=names(patches_gid_TPI_3100m_stddev_n), TPI_3100m_stddev_n_gid_patch=as.vector(patches_gid_TPI_3100m_stddev_n)), by="GID"), data.frame(GID=names(patches_gid_TPI_1100m_stddev_n), TPI_1100m_stddev_n_gid_patch=as.vector(patches_gid_TPI_1100m_stddev_n)), by="GID"), data.frame(GID=names(patches_gid_tvn), tvn_gid_patch=as.vector(patches_gid_tvn)), by="GID"), by="GID")

# patches_gid_max_TPI_5100m_stddev_n <- by(skgrm$TPI_5100m_stddev_n,skgrm$gid_max,FUN=max)
# patches_gid_max_TPI_3100m_stddev_n <- by(skgrm$TPI_3100m_stddev_n,skgrm$gid_max,FUN=max)
# patches_gid_max_TPI_1100m_stddev_n <- by(skgrm$TPI_1100m_stddev_n,skgrm$gid_max,FUN=max)
# patches_gid_max_tvn <- by(skgrm$tvn,skgrm$gid_max,FUN=max)

# skgrm <- merge(skgrm, merge(merge(merge(data.frame(GID=names(patches_gid_max_TPI_5100m_stddev_n), TPI_5100m_stddev_n_gid_max_patch=as.vector(patches_gid_max_TPI_5100m_stddev_n)), data.frame(GID=names(patches_gid_max_TPI_3100m_stddev_n), TPI_3100m_stddev_n_gid_max_patch=as.vector(patches_gid_max_TPI_3100m_stddev_n)), by="GID"), data.frame(GID=names(patches_gid_max_TPI_1100m_stddev_n), TPI_1100m_stddev_n_gid_max_patch=as.vector(patches_gid_max_TPI_1100m_stddev_n)), by="GID"), data.frame(GID=names(patches_gid_max_tvn), tvn_gid_max_patch=as.vector(patches_gid_max_tvn)), by="GID"), by="GID")

plot(skgrMergeF1t$hoh ~ I(-0,000000040743734456046900000000*I(skgrMergeF1t$coast_line_distance^2) + 0,010701636392595100000000000000skgrMergeF1t$coast_line_distance + 324,560362605996000000000000000000))

skgrm$lat_tan <- tan(skgrm$lat*pi/180)
skgrm$lat_tan_e2 <- tan(skgrm$lat*pi/180)^2
skgrm$lat_tan_e3 <- tan(skgrm$lat*pi/180)^3
skgrm$lat_tan_e4 <- tan(skgrm$lat*pi/180)^4
skgrm$lat_tan_e5 <- tan(skgrm$lat*pi/180)^5
skgrm$lat_tan_e6 <- tan(skgrm$lat*pi/180)^6
skgrm$lat_tan_e7 <- tan(skgrm$lat*pi/180)^7
skgrm$lat_tan_e8 <- tan(skgrm$lat*pi/180)^8
skgrm$lat_tan_e9 <- tan(skgrm$lat*pi/180)^9
skgrm$lat_tan_e10 <- tan(skgrm$lat*pi/180)^10
skgrm$lat_tan_e20 <- tan(skgrm$lat*pi/180)^20
skgrm$lat_tan_e30 <- tan(skgrm$lat*pi/180)^30
skgrm$lat_tan_e50 <- tan(skgrm$lat*pi/180)^50
skgrm$lat_tan_e100 <- tan(skgrm$lat*pi/180)^100

skgrm$amount_ocean_100200m_n <- 1-(skgrm$amount_ocean_100200m-min(skgrm$amount_ocean_100200m))/(max(skgrm$amount_ocean_100200m)-min(skgrm$amount_ocean_100200m))
skgrm$amount_ocean_50200m_n <- 1-(skgrm$amount_ocean_50200m-min(skgrm$amount_ocean_50200m))/(max(skgrm$amount_ocean_50200m)-min(skgrm$amount_ocean_50200m))
skgrm$amount_ocean_25000m_n <- 1-(skgrm$amount_ocean_25000m-min(skgrm$amount_ocean_25000m))/(max(skgrm$amount_ocean_25000m)-min(skgrm$amount_ocean_25000m))
skgrm$amount_ocean_10100m_n <- 1-(skgrm$amount_ocean_10100m-min(skgrm$amount_ocean_10100m))/(max(skgrm$amount_ocean_10100m)-min(skgrm$amount_ocean_10100m))
skgrm$amount_ocean_5050m_n <- 1-(skgrm$amount_ocean_5050m-min(skgrm$amount_ocean_5050m))/(max(skgrm$amount_ocean_5050m)-min(skgrm$amount_ocean_5050m))


# patches_250m_gid <- gapply(skgrm, c("max_forest_250m"), FUN=function(x) min(x), groups=as.factor(skgrm$GID))
# patches_550m_gid <- gapply(skgrm, c("max_forest_550m"), FUN=function(x) min(x), groups=as.factor(skgrm$GID))
# patches_1050m_gid <- gapply(skgrm, c("max_forest_1050m"), FUN=function(x) min(x), groups=as.factor(skgrm$GID))
# patches_2550m_gid <- gapply(skgrm, c("max_forest_2550m"), FUN=function(x) min(x), groups=as.factor(skgrm$GID))
# patches_5050m_gid <- gapply(skgrm, c("max_forest_5050m"), FUN=function(x) min(x), groups=as.factor(skgrm$GID))
# patches_10100m_gid <- gapply(skgrm, c("max_forest_10100m"), FUN=function(x) min(x), groups=as.factor(skgrm$GID))
# patches_25000m_gid <- gapply(skgrm, c("max_forest_25000m"), FUN=function(x) min(x), groups=as.factor(skgrm$GID))
# patches_50200m_gid <- gapply(skgrm, c("max_forest_50200m"), FUN=function(x) min(x), groups=as.factor(skgrm$GID))

# patches_gid <- merge(merge(merge(merge(merge(merge(merge(data.frame(GID=names(patches_250m_gid), max_forest_250m_gid_patch=patches_250m_gid), data.frame(GID=names(patches_550m_gid), max_forest_550m_gid_patch=patches_550m_gid), by="GID"), data.frame(GID=names(patches_1050m_gid), max_forest_1050m_gid_patch=patches_1050m_gid), by="GID"), data.frame(GID=names(patches_2550m_gid), max_forest_2550m_gid_patch=patches_2550m_gid), by="GID"), data.frame(GID=names(patches_5050m_gid), max_forest_5050m_gid_patch=patches_5050m_gid), by="GID"), data.frame(GID=names(patches_10100m_gid), max_forest_10100m_gid_patch=patches_10100m_gid), by="GID"), data.frame(GID=names(patches_25000m_gid), max_forest_25000m_gid_patch=patches_25000m_gid), by="GID"), data.frame(GID=names(patches_50200m_gid), max_forest_50200m_gid_patch=patches_50200m_gid), by="GID")
# patches_gid$max_forest_sum_patch_gid <- patches_gid$max_forest_2550m_gid_patch+patches_gid$max_forest_5050m_gid_patch+patches_gid$max_forest_10100m_gid_patch+patches_gid$max_forest_25000m_gid_patch+patches_gid$max_forest_50200m_gid_patch
# patches_gid$max_forest_sum_all_patch_gid <- patches_gid$max_forest_250m_gid_patch+patches_gid$max_forest_550m_gid_patch+patches_gid$max_forest_1050m_gid_patch+patches_gid$max_forest_2550m_gid_patch+patches_gid$max_forest_5050m_gid_patch+patches_gid$max_forest_10100m_gid_patch+patches_gid$max_forest_25000m_gid_patch+patches_gid$max_forest_50200m_gid_patch
# skgrm <- merge(skgrm, patches_gid, by=c("GID"))

# png('/home/stefan/Okokart/fin/Filtering_tetraterm_total_0_6a.png', width = 5000, height = 5000, units = "px", pointsize = 10, bg = "white", res = 96, type = c("cairo"))
# zcol <- level.colors(skgrMergeF1$tetraterm_total_kor_0_6, at = c(-10000, 2750, 2751, 2752, 2753, 2754, 2755, 2760), col.regions=colorRampPalette(c("yellow", "green", "cyan", "blue", "purple", "magenta", "red")))
# xyplot(Y ~ X | "Filteringtetraterm_total", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
# dev.off()
# png('/home/stefan/Okokart/fin/Filtering_tetraterm_total_0_6.png', width = 5000, height = 5000, units = "px", pointsize = 10, bg = "white", res = 96, type = c("cairo"))
# zcol <- level.colors(skgrMergeF1$tetraterm_total_kor_0_6, at = c(-10000, 2760, 2761, 2762, 2763, 2764, 2765, 2767.5, 9999), col.regions=colorRampPalette(c("yellow", "green", "cyan", "blue", "purple", "magenta", "red")))
# xyplot(Y ~ X | "Filteringtetraterm_total_0_6", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.2)
# dev.off()

plot(f1sm6$fitted ~ skgrMergeF1t$coast_line_distance)
lines(lowess(f1sm6$fitted ~ I(skgrMergeF1$coast_line_distance), f=0.1), col="red")
lines(lowess(hoh ~ I(coast_line_distance), data=skgrMergeF1, f=0.1), col="green")

plot(hoh ~ sqrt(lon), data=skgrMergeF1)
#lines(lowess(f1sm6$fitted ~ I(skgrMergeF1t$lon), f=0.1), col="red")
lines(lowess(hoh ~ sqrt(lon), data=skgrMergeF1, f=0.1), col="green")

max_forest_50200m_stddev
f1sm7 <- lm(hoh ~ poly(coast_line_distance,2) * sqrt(amount_ocean_100200m) * poly(TPI_5100m_stddev,3) * I(solar_radiation^4) * lon * lat * max_forest_50200m_stddev + lon * I(solar_radiation^4) * I(slope_5) * as.factor(aspect5_cl8), data=skgrMergeF1)
f1sm7 <- lm(hoh ~ I(coast_line_distance) * sqrt(amount_ocean_100200m) * poly(TPI_5100m_stddev,3) * sqrt(solar_radiation) * lon * lat_tan + lon * I(solar_radiation) * I(slope_5) * as.factor(aspect5_cl8), data=skgrMergeF1t)
f1sm7 <- lm(hoh ~ log(coast_line_distance) * sqrt(amount_ocean_100200m) * poly(TPI_5100m_stddev,3) * sqrt(solar_radiation) * lon * lat + lon * I(solar_radiation) * I(slope_5) * as.factor(aspect5_cl8), data=skgrMergeF1t)

par(mfrow=c(2,2))

plot(hoh ~ I(coast_line_distance), data=skgrMergeF1[skgrMergeF1$lat<62&skgrMergeF1$lat>58,], xlim=c(0,max(skgrMergeF1$coast_line_distance)))
lines(lowess(hoh ~ I(coast_line_distance), data=skgrMergeF1[skgrMergeF1$lat>58&skgrMergeF1$lat<62,], f=0.5), col="red")
lines(lowess(hoh ~ I(coast_line_distance), data=skgrMergeF1[skgrMergeF1$lat>58&skgrMergeF1$lat<62,], f=0.1), col="green")
abline(test_glm, col="blue")
abline(v=5000, col="yellow")
abline(v=10000, col="yellow")
abline(v=65000, col="yellow")
abline(v=90000, col="yellow")
plot(hoh ~ I(coast_line_distance), data=skgrMergeF1[skgrMergeF1$lat<65&skgrMergeF1$lat>62,], xlim=c(0,max(skgrMergeF1$coast_line_distance)))
lines(lowess(hoh ~ I(coast_line_distance), data=skgrMergeF1[skgrMergeF1$lat>62&skgrMergeF1$lat<65,], f=0.5), col="red")
lines(lowess(hoh ~ I(coast_line_distance), data=skgrMergeF1[skgrMergeF1$lat>62&skgrMergeF1$lat<65,], f=0.1), col="green")
test_glm <- glm(hoh ~ I(coast_line_distance), data=skgrMergeF1[skgrMergeF1$lat>62&skgrMergeF1$lat<65,])
abline(test_glm, col="blue")
abline(v=5000, col="yellow")
abline(v=10000, col="yellow")
abline(v=65000, col="yellow")
abline(v=90000, col="yellow")

plot(hoh ~ I(coast_line_distance), data=skgrMergeF1[skgrMergeF1$lat<68&skgrMergeF1$lat>65,], xlim=c(0,max(skgrMergeF1$coast_line_distance)))
lines(lowess(hoh ~ I(coast_line_distance), data=skgrMergeF1[skgrMergeF1$lat>65&skgrMergeF1$lat<68,], f=0.5), col="red")
lines(lowess(hoh ~ I(coast_line_distance), data=skgrMergeF1[skgrMergeF1$lat>65&skgrMergeF1$lat<68,], f=0.1), col="green")
test_glm <- glm(hoh ~ I(coast_line_distance), data=skgrMergeF1[skgrMergeF1$lat>65&skgrMergeF1$lat<68,])
abline(test_glm, col="blue")
abline(v=5000, col="yellow")
abline(v=10000, col="yellow")
abline(v=65000, col="yellow")
abline(v=90000, col="yellow")

plot(hoh ~ I(coast_line_distance), data=skgrMergeF1[skgrMergeF1$lat<71&skgrMergeF1$lat>68,], xlim=c(0,max(skgrMergeF1$coast_line_distance)))
lines(lowess(hoh ~ I(coast_line_distance), data=skgrMergeF1[skgrMergeF1$lat>68&skgrMergeF1$lat<71,], f=0.5), col="red")
lines(lowess(hoh ~ I(coast_line_distance), data=skgrMergeF1[skgrMergeF1$lat>68&skgrMergeF1$lat<71,], f=0.1), col="green")
test_glm <- glm(hoh ~ I(coast_line_distance), data=skgrMergeF1[skgrMergeF1$lat>68&skgrMergeF1$lat<71,])
abline(test_glm, col="blue")
abline(v=5000, col="yellow")
abline(v=10000, col="yellow")
abline(v=65000, col="yellow")
abline(v=90000, col="yellow")

plot(hoh ~ I(amount_ocean_100200m), data=skgrMergeF1[skgrMergeF1$lat<62&skgrMergeF1$lat>58,], xlim=c(0,max(skgrMergeF1$amount_ocean_100200m)))
lines(lowess(hoh ~ I(amount_ocean_100200m), data=skgrMergeF1[skgrMergeF1$lat>58&skgrMergeF1$lat<62,], f=0.5), col="red")
lines(lowess(hoh ~ I(amount_ocean_100200m), data=skgrMergeF1[skgrMergeF1$lat>58&skgrMergeF1$lat<62,], f=0.1), col="green")
abline(test_glm, col="blue")
abline(v=2400000, col="yellow")
abline(v=4250000, col="yellow")
abline(v=7500000, col="yellow")
abline(v=13000000, col="green")
abline(v=18500000, col="green")
abline(v=23500000, col="green")
abline(v=32500000, col="green")


plot(hoh ~ I(amount_ocean_180200m), data=skgrMergeF1[skgrMergeF1$lat<65&skgrMergeF1$lat>62,], xlim=c(0,max(skgrMergeF1$amount_ocean_180200m)))
lines(lowess(hoh ~ I(amount_ocean_180200m), data=skgrMergeF1[skgrMergeF1$lat>62&skgrMergeF1$lat<65,], f=0.5), col="red")
lines(lowess(hoh ~ I(amount_ocean_180200m), data=skgrMergeF1[skgrMergeF1$lat>62&skgrMergeF1$lat<65,], f=0.1), col="green")
test_glm <- glm(hoh ~ I(amount_ocean_180200m), data=skgrMergeF1[skgrMergeF1$lat>62&skgrMergeF1$lat<65,])
abline(test_glm, col="blue")
abline(v=2400000, col="yellow")
abline(v=4250000, col="yellow")
abline(v=7500000, col="yellow")
abline(v=13000000, col="green")
abline(v=18500000, col="green")
abline(v=23500000, col="green")
abline(v=32500000, col="green")

plot(hoh ~ I(amount_ocean_100200m), data=skgrMergeF1[skgrMergeF1$lat<68&skgrMergeF1$lat>65,], xlim=c(0,max(skgrMergeF1$amount_ocean_100200m)))
lines(lowess(hoh ~ I(amount_ocean_100200m), data=skgrMergeF1[skgrMergeF1$lat>65&skgrMergeF1$lat<68,], f=0.5), col="red")
lines(lowess(hoh ~ I(amount_ocean_100200m), data=skgrMergeF1[skgrMergeF1$lat>65&skgrMergeF1$lat<68,], f=0.1), col="green")
test_glm <- glm(hoh ~ I(amount_ocean_100200m), data=skgrMergeF1[skgrMergeF1$lat>65&skgrMergeF1$lat<68,])
abline(test_glm, col="blue")
abline(v=2400000, col="yellow")
abline(v=4250000, col="yellow")
abline(v=7500000, col="yellow")
abline(v=13000000, col="green")
abline(v=18500000, col="green")
abline(v=23500000, col="green")
abline(v=32500000, col="green")

plot(hoh ~ I(amount_ocean_100200m), data=skgrMergeF1[skgrMergeF1$lat<71&skgrMergeF1$lat>68,], xlim=c(0,max(skgrMergeF1$amount_ocean_100200m)))
lines(lowess(hoh ~ I(amount_ocean_100200m), data=skgrMergeF1[skgrMergeF1$lat>68&skgrMergeF1$lat<71,], f=0.5), col="red")
lines(lowess(hoh ~ I(amount_ocean_100200m), data=skgrMergeF1[skgrMergeF1$lat>68&skgrMergeF1$lat<71,], f=0.1), col="green")
test_glm <- glm(hoh ~ I(amount_ocean_100200m), data=skgrMergeF1[skgrMergeF1$lat>68&skgrMergeF1$lat<71,])
abline(test_glm, col="blue")
abline(v=2400000, col="yellow")
abline(v=4250000, col="yellow")
abline(v=7500000, col="yellow")
abline(v=13000000, col="green")
abline(v=18500000, col="green")
abline(v=23500000, col="green")
abline(v=32500000, col="green")

plot(hoh ~ I(amount_ocean_100200m), data=skgrMergeF1[skgrMergeF1$lat>59&skgrMergeF1$lat<=61,])
test_glm <- glm(skgrMergeF1$hoh[skgrMergeF1$lat>59&skgrMergeF1$lat<=61] ~ I(skgrMergeF1$amount_ocean_100200m[skgrMergeF1$lat>59&skgrMergeF1$lat<=61]))
lines(lowess(skgrMergeF1$hoh[skgrMergeF1$lat>59&skgrMergeF1$lat<=61] ~ I(skgrMergeF1$amount_ocean_100200m[skgrMergeF1$lat>59&skgrMergeF1$lat<=61]), f=0.5), col="red")
abline(test_glm, col="blue")
plot(hoh ~ I(amount_ocean_100200m), data=skgrMergeF1[skgrMergeF1$lat>59&skgrMergeF1$lat<=61,])
test_glm <- glm(skgrMergeF1$hoh[skgrMergeF1$lat>59&skgrMergeF1$lat<=61] ~ I(skgrMergeF1$amount_ocean_100200m[skgrMergeF1$lat>59&skgrMergeF1$lat<=61]))
lines(lowess(skgrMergeF1$hoh[skgrMergeF1$lat>59&skgrMergeF1$lat<=61] ~ I(skgrMergeF1$amount_ocean_100200m[skgrMergeF1$lat>59&skgrMergeF1$lat<=61]), f=0.5), col="red")
abline(test_glm, col="blue")
plot(hoh ~ I(amount_ocean_100200m), data=skgrMergeF1[skgrMergeF1$lat>61&skgrMergeF1$lat<=63,])
test_glm <- glm(skgrMergeF1$hoh[skgrMergeF1$lat>61&skgrMergeF1$lat<=63] ~ I(skgrMergeF1$amount_ocean_100200m[skgrMergeF1$lat>61&skgrMergeF1$lat<=63]))
lines(lowess(skgrMergeF1$hoh[skgrMergeF1$lat>61&skgrMergeF1$lat<=63] ~ I(skgrMergeF1$amount_ocean_100200m[skgrMergeF1$lat>61&skgrMergeF1$lat<=63]), f=0.5), col="red")
abline(test_glm, col="blue")


plot(hoh ~ I(coast_line_distance), data=skgrMergeF1)
test_glm <- glm(skgrMergeF1$hoh ~ I(skgrMergeF1$coast_line_distance))
lines(lowess(skgrMergeF1$hoh ~ I(skgrMergeF1$coast_line_distance), f=0.1), col="red")
abline(test_glm, col="blue")
abline(v=90000, col="green")

plot(hoh ~ I(amount_ocean_180200m), data=skgrMergeF1t)
test_glm <- glm(skgrMergeF1t$hoh ~ I(skgrMergeF1t$amount_ocean_180200m))
lines(lowess(skgrMergeF1t$hoh ~ I(skgrMergeF1t$amount_ocean_180200m), f=0.1), col="red")
abline(test_glm, col="blue")
abline(v=100000, col="green")
abline(v=1000000, col="green")
abline(v=5000000, col="green")
abline(v=10000000, col="green")
abline(v=20000000, col="green")

abline(v=4000000, col="green")

coplot(skgrMergeF1t$hoh ~ skgrMergeF1t$amount_ocean_180200m | skgrMergeF1t$lat, panel=panel.smooth)

skgrMergeF1$continentality <- (skgrMergeF1$amount_ocean_180200m * skgrMergeF1$amount_ocean_100200m * skgrMergeF1$amount_ocean_50200m * skgrMergeF1$amount_ocean_25000m * skgrMergeF1$amount_ocean_10100m * skgrMergeF1$amount_ocean_5050m)

f1sm7 <- lm(hoh ~ I(lat) * I(lon) * I(amount_ocean_100200m) * I(solar_radiation^4) * I(slope_5) * as.factor(aspect5_cl8), data=skgrMergeF1)

f1sm7 <- lm(hoh ~ sqrt(amount_ocean_180200m) * I(lat) * poly(lon,2) * log(coast_line_distance) * as.factor(ifelse(coast_line_distance<=90000,0,1)) * I(solar_radiation^4) *  slope_5 * TPI_5100m_stddev + I(solar_radiation^4) *  slope_5 * as.factor(aspect5_cl8), data=skgrMergeF1)
f1sm7 <- lm(hoh ~ I(amount_ocean_180200m) * I(lat) * I(lon) * I(solar_radiation) + I(amount_ocean_180200m) * I(solar_radiation) * as.factor(aspect5_cl8), data=skgrMergeF1t)

#Two-way interaction
f1sm1 <- lm(hoh ~ lat * lon + lat * sqrt(amount_ocean_180200m) + lat * I(solar_radiation^4) + lon * sqrt(amount_ocean_180200m) + lon * I(solar_radiation^4) + sqrt(amount_ocean_180200m) * I(solar_radiation^4) + I(solar_radiation^4) * as.factor(aspect5_cl8) + lat * as.factor(aspect5_cl8), data = skgrMergeF1tc)
f1sm1g <- lm(hoh ~ lat * lon + lat * sqrt(amount_ocean_180200m) + lat * I(solar_radiation^4) + lon * sqrt(amount_ocean_180200m) + lon * I(solar_radiation^4) + sqrt(amount_ocean_180200m) * I(solar_radiation^4) + I(solar_radiation^4) * as.factor(aspect5_cl8) + lat * as.factor(aspect5_cl8)+ lat * as.factor(quart_gw) + lat * as.factor(geol_rich), data = skgrMergeF1tc)

f1sm2 <- lm(hoh ~ lat * lon + lat * poly(amount_ocean_180200m,2, raw=TRUE) + lat * I(solar_radiation^4) + lon * poly(amount_ocean_180200m,2, raw=TRUE) + lon * I(solar_radiation^4) + poly(amount_ocean_180200m,2, raw=TRUE) * I(solar_radiation^4) + I(solar_radiation^4) * as.factor(aspect5_cl8) + lat * as.factor(aspect5_cl8), data = skgrMergeF1tc)
f1sm2g <- lm(hoh ~ lat * lon + lat * poly(amount_ocean_180200m,2, raw=TRUE) + lat * I(solar_radiation^4) + lon * poly(amount_ocean_180200m,2, raw=TRUE) + lon * I(solar_radiation^4) + poly(amount_ocean_180200m,2, raw=TRUE) * I(solar_radiation^4) + I(solar_radiation^4) * as.factor(aspect5_cl8) + lat * as.factor(aspect5_cl8) + lat * as.factor(aspect5_cl8)+ lat * as.factor(quart_gw) + lat * as.factor(geol_rich), data = skgrMergeF1tc)

f1sm3 <- lm(hoh ~ lat * lon + lat * I(amount_ocean_180200m) + lat * I(solar_radiation^4) + lon * I(amount_ocean_180200m) + lon * I(solar_radiation^4) + I(amount_ocean_180200m) * I(solar_radiation^4) + I(solar_radiation^4) * as.factor(aspect5_cl8) + lat * as.factor(aspect5_cl8), data = skgrMergeF1tc)
f1sm3g <- lm(hoh ~ lat * lon + lat * I(amount_ocean_180200m) + lat * I(solar_radiation^4) + lon * I(amount_ocean_180200m) + lon * I(solar_radiation^4) + I(amount_ocean_180200m) * I(solar_radiation^4) + I(solar_radiation^4) * as.factor(aspect5_cl8) + lat * as.factor(aspect5_cl8)+ lat * as.factor(quart_gw) + lat * as.factor(geol_rich), data = skgrMergeF1tc)
f1sm3ga <- lm(hoh ~ lat * lon + lat * I(amount_ocean_180200m) + lat * I(amount_ocean_50200m) + lat * I(solar_radiation) + lon * I(amount_ocean_180200m) + lon * I(amount_ocean_50200m) + lon * I(solar_radiation) + I(amount_ocean_180200m) * I(solar_radiation) + I(amount_ocean_50200m) * I(solar_radiation) + I(solar_radiation) * as.factor(aspect5_cl8) + lat * as.factor(aspect5_cl8) + I(amount_ocean_180200m) * as.factor(aspect5_cl8) + I(amount_ocean_50200m) * as.factor(aspect5_cl8) + I(amount_ocean_180200m) * as.factor(quart_gw) + lat * as.factor(quart_gw) + I(amount_ocean_180200m) * as.factor(geol_rich) + lat * as.factor(geol_rich), data = skgrMergeF1tc)

#full interaction
f1sm4 <- lm(hoh ~ lat * lon * I(amount_ocean_180200m) * I(solar_radiation^4)  * as.factor(aspect5_cl8) + lat * as.factor(aspect5_cl8), data = skgrMergeF1tc)
f1sm4g <- lm(hoh ~ lat * lon * I(amount_ocean_180200m) * I(solar_radiation^4)  * as.factor(aspect5_cl8) + lat * as.factor(aspect5_cl8)+ lat * as.factor(quart_gw) + lat * as.factor(geol_rich), data = skgrMergeF1tc)

#Polynom transformed
f1sm5 <- lm( hoh ~ poly(amount_ocean_180200m, 2, raw=TRUE) * lat * poly(lon, 6, raw=TRUE) * I(solar_radiation^4) * coast_line_distance + poly(amount_ocean_180200m,2, raw=TRUE) * I(solar_radiation^4) * as.factor(aspect5_cl8), data = skgrMergeF1tc)
f1sm5g <- lm( hoh ~ poly(amount_ocean_180200m, 2, raw=TRUE) * lat * poly(lon, 6, raw=TRUE) * I(solar_radiation^4) * coast_line_distance + poly(amount_ocean_180200m,2, raw=TRUE) * I(solar_radiation^4) * as.factor(aspect5_cl8) + lat * as.factor(quart_gw) + lat * as.factor(geol_rich), data = skgrMergeF1tc)

#full interaction polynom transformed
f1sm6 <- lm( hoh ~ poly(amount_ocean_180200m, 2, raw=TRUE) * lat * poly(lon, 6, raw=TRUE) * poly(coast_line_distance, 2, raw=TRUE) + poly(amount_ocean_180200m,2, raw=TRUE) * I(solar_radiation^4) * as.factor(aspect5_cl8), data = skgrMergeF1tc)
f1sm6g <- lm( hoh ~ poly(amount_ocean_180200m, 2, raw=TRUE) * lat * poly(lon, 6, raw=TRUE) * poly(coast_line_distance, 2, raw=TRUE) + poly(amount_ocean_180200m,2, raw=TRUE) * I(solar_radiation^4) * as.factor(aspect5_cl8) + lat * as.factor(quart_gw) + lat * as.factor(geol_rich), data = skgrMergeF1tc)


f1sm6g_ci <- confint(f1sm6g)

data.frame(names=names(f1sm2$coefficients),coef=f1sm2$coefficients)
as.data.frame(f1sm5_ci)[1]
as.data.frame(f1sm5_ci)[2]

models <- paste("r.mapcalc \"expression=", paste(paste(names(f1sm1$coefficients),f1sm1$coefficients, sep='*'),sep='+'), "\"",sep='')

ps_file <- paste("/home/stefan/Okokart/Modell_F3g.ps", sep="")

postscript(ps_file, horizontal=TRUE, paper="a4", family="mono")

plot(f1sm3g)
plot(f1sm3g$residuals ~ I(skgrMergeF1tc$lat))
plot(f1sm3g$residuals ~ I(skgrMergeF1tc$lon))
plot(f1sm3g$residuals ~ I(skgrMergeF1tc$coast_line_distance))
plot(f1sm3g$residuals ~ I(skgrMergeF1tc$amount_ocean_180200m))
plot(f1sm3g$residuals ~ I(skgrMergeF1tc$max_forest_100200m))
plot(f1sm3g$residuals ~ I(skgrMergeF1tc$max_forest_50200m))
plot(f1sm3g$residuals ~ I(skgrMergeF1tc$max_forest_25000m))
plot(f1sm3g$residuals ~ I(skgrMergeF1tc$max_forest_10100m))
plot(f1sm3g$residuals ~ I(skgrMergeF1tc$slope_3))

plot(skgrMergeF1tc$hoh ~ skgrMergeF1tc$lat, xlab="Latitude", ylab="Reference altitude")
lines(lowess(skgrMergeF1tc$hoh ~ I(skgrMergeF1tc$lat), f=0.1), col="green")
lines(lowess(f1sm3g$fitted ~ I(skgrMergeF1tc$lat), f=0.1), col="red")
plot(f1sm3g$fitted ~ skgrMergeF1tc$lat, xlab="Latitude", ylab="Fitted values")
lines(lowess(skgrMergeF1tc$hoh ~ I(skgrMergeF1tc$lat), f=0.1), col="green")
lines(lowess(f1sm3g$fitted ~ I(skgrMergeF1tc$lat), f=0.1), col="red")

plot(skgrMergeF1tc$hoh ~ skgrMergeF1tc$lon, xlab="Longitude", ylab="Reference altitude")
lines(lowess(skgrMergeF1tc$hoh ~ I(skgrMergeF1tc$lon), f=0.1), col="green")
lines(lowess(f1sm3g$fitted ~ skgrMergeF1tc$lon), f=0.1), col="red")

plot(skgrMergeF1tc$hoh ~ I(skgrMergeF1tc$coast_line_distance))
lines(lowess(skgrMergeF1tc$hoh ~ I(skgrMergeF1tc$coast_line_distance), f=0.1), col="green")
lines(lowess(f1sm3g$fitted ~ I(skgrMergeF1tc$coast_line_distance), f=0.1), col="red")
plot(f1sm3g$fitted ~ I(skgrMergeF1tc$coast_line_distance))
lines(lowess(skgrMergeF1tc$hoh ~ I(skgrMergeF1tc$coast_line_distance), f=0.1), col="green")
lines(lowess(f1sm3g$fitted ~ I(skgrMergeF1tc$coast_line_distance), f=0.1), col="red")

plot(skgrMergeF1tc$hoh ~ I(skgrMergeF1tc$amount_ocean_180200m))
points(I(skgrMergeF1tc$amount_ocean_180200m), f1sm3g$fitted, col="blue")
lines(lowess(skgrMergeF1tc$hoh ~ I(skgrMergeF1tc$amount_ocean_180200m), f=0.1), col="green")
lines(lowess(f1sm3g$fitted ~ I(skgrMergeF1tc$amount_ocean_180200m), f=0.1), col="red")

dev.off()

#plot fitted values for model 1
png('/home/stefan/Okokart/Modelling_fitted_values_F1t_M1.png', width = 5000, height = 5000, units = "px", pointsize = 12, bg = "white", res = 10, type = c("cairo"))
zcol <- level.colors(f1sm8$fitted, at = c(-1000, 0, 100, 200, 300, 400, 500, 600, 700, 800, 900, 1000, 1100, 1200), col.regions=terrain.colors(13), interpolate = c("linear"))
xyplot(Y ~ X | "Fitted values of model F1tsm6", data=skgrMergeF1t, col = zcol, aspect = 1, .aspect.ratio = 1)
dev.off()

#plot residual values for model 1
png('/home/stefan/Okokart/Modelling_residuals_F1_M1.png', width = 5000, height = 5000, units = "px", pointsize = 12, bg = "white", res = 10, type = c("cairo"))
zcol <- level.colors((f1sm8$resid), at=c(-650, -200, -100, -50, 0, 50, 100, 200, 1080), col.regions=colorRampPalette(c("darkred", "red", "orange", "yellow", "lightgreen", "green", "darkgreen")))
xyplot(Y ~ X | "Residuals of model F1sm6", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1)
dev.off()

#plot residual values for model 2
png('/home/stefan/Okokart/Modelling_residuals_F1t_M1.png', width = 5000, height = 5000, units = "px", pointsize = 12, bg = "white", res = 10, type = c("cairo"))
zcol <- level.colors((f1sm8$resid), at=c(-650, -200, -100, -50, 0, 50, 100, 200, 1080), col.regions=colorRampPalette(c("darkred", "red", "orange", "yellow", "lightgreen", "green", "darkgreen")))
xyplot(Y ~ X | "Residuals of model F1tsm6", data=skgrMergeF1t, col=zcol, aspect = 1, .aspect.ratio = 1)
dev.off()

#plot residual values for model 2
png('/home/stefan/Okokart/Modelling_residuals_F1c_M1.png', width = 5000, height = 5000, units = "px", pointsize = 12, bg = "white", res = 10, type = c("cairo"))
zcol <- level.colors((f1sm8$resid), at=c(-650, -200, -100, -50, 0, 50, 100, 200, 1080), col.regions=colorRampPalette(c("darkred", "red", "orange", "yellow", "lightgreen", "green", "darkgreen")))
xyplot(Y ~ X | "Residuals of model F1tsm6", data=skgrMergeF1c, col=zcol, aspect = 1, .aspect.ratio = 1)
dev.off()

#plot residual values for model 4
png('/home/stefan/Okokart/Modelling_residuals_F1t_M4.png', width = 5000, height = 5000, units = "px", pointsize = 12, bg = "white", res = 10, type = c("cairo"))
zcol <- level.colors((f1sm4$resid), at=c(-650, -200, -100, -50, 0, 50, 100, 200, 1080), col.regions=colorRampPalette(c("darkred", "red", "orange", "yellow", "lightgreen", "green", "darkgreen")))
xyplot(Y ~ X | "Residuals of model F1tsm6", data=skgrMergeF1t, col=zcol, aspect = 1, .aspect.ratio = 1)
dev.off()
#plot residual values for model 4
png('/home/stefan/Okokart/Modelling_residuals_F1c_M4.png', width = 5000, height = 5000, units = "px", pointsize = 12, bg = "white", res = 10, type = c("cairo"))
zcol <- level.colors((f1sm8$resid), at=c(-650, -200, -100, -50, 0, 50, 100, 200, 1080), col.regions=colorRampPalette(c("darkred", "red", "orange", "yellow", "lightgreen", "green", "darkgreen")))
xyplot(Y ~ X | "Residuals of model F1tsm6", data=skgrMergeF1c, col=zcol, aspect = 1, .aspect.ratio = 1)
dev.off()

#Plot reative residuals for overestimated forest line
png('/home/stefan/Okokart/Modelling_residuals_overestimated_F1_M1.png', width = 5000, height = 5000, units = "px", pointsize = 12, bg = "white", res = 10, type = c("cairo"))
zcol <- level.colors(f1sm7$resid[f1sm7$resid>=0], at=c(0, 10, 25, 50, 75, 100, 150, 200, 500), col.regions=colorRampPalette(c("yellow", "green", "cyan", "blue", "purple", "red")), interpolate = c("linear"))
xyplot(Y ~ X | "Positive residuals of model f1sm7", data=skgrMergeF1t[f1sm7$resid>=0,], col=zcol, aspect = 1, .aspect.ratio = 1)
dev.off()

#Plot reative residuals for underestimated forest line
png('/home/stefan/Okokart/Modelling_residuals_underestimated_F1_M1.png', width = 5000, height = 5000, units = "px", pointsize = 12, bg = "white", res = 10, type = c("cairo"))
zcol <- level.colors(f1sm7$resid[f1sm7$resid<0], at=c(0, -10, -25, -50, -75, -100, -150, -200, -500), col.regions=colorRampPalette(c("yellow", "green", "cyan", "blue", "purple", "red")), interpolate = c("linear"))
xyplot(Y ~ X | "Negative residuals of model f1sm7", data=skgrMergeF1t[f1sm7$resid<0,], col=zcol, aspect = 1, .aspect.ratio = 1)
dev.off()

f1sm8 <- lm(hoh ~ lat * lon + lat * sqrt(amount_ocean_180200m) + lat * sqrt(amount_ocean_100200m) + lat * sqrt(amount_ocean_50200m) + lat * sqrt(amount_ocean_25000m) + lat * sqrt(amount_ocean_10100m) + lat * sqrt(amount_ocean_5050m) + lat * log(coast_line_distance) + lat * lon + lat * I(solar_radiation^4) + lon * sqrt(amount_ocean_180200m) + lon * sqrt(amount_ocean_100200m) + lon * sqrt(amount_ocean_50200m) + lon * sqrt(amount_ocean_25000m) + lon * sqrt(amount_ocean_10100m) + lon * sqrt(amount_ocean_5050m) + lon * log(coast_line_distance) + lon * I(solar_radiation^4), data = skgrMergeF1c)
f1sm8 <- lm(hoh ~ lat * lon + lat * I(amount_ocean_180200m) + lat * I(amount_ocean_100200m) + lat * I(amount_ocean_50200m) + lat * I(amount_ocean_25000m) + lat * I(amount_ocean_10100m) + lat * I(amount_ocean_5050m) + lat * log(coast_line_distance) + lat * lon + lat * I(solar_radiation^4) + lon * I(amount_ocean_180200m) + lon * I(amount_ocean_100200m) + lon * I(amount_ocean_50200m) + lon * I(amount_ocean_25000m) + lon * I(amount_ocean_10100m) + lon * I(amount_ocean_5050m) + lon * log(coast_line_distance) + lon * I(solar_radiation^4), data = skgrMergeF1c)

par(mfrow=c(1,2))

plot(skgrMergeF1t$hoh ~ I(skgrMergeF1t$lat))
points(I(skgrMergeF1t$lat), f1sm9$fitted, col="blue")
lines(lowess(skgrMergeF1t$hoh ~ I(skgrMergeF1t$lat), f=0.1), col="green")
lines(lowess(f1sm9$fitted ~ I(skgrMergeF1t$lat), f=0.1), col="red")


plot(f1sm8$fitted ~ I(skgrMergeF1$lon))
lines(lowess(skgrMergeF1c$hoh ~ I(skgrMergeF1c$lon), f=0.1), col="green")
lines(lowess(f1sm8$fitted ~ I(skgrMergeF1c$lon), f=0.1), col="red")
plot(skgrMergeF1$hoh ~ I(skgrMergeF1$lat))
lines(lowess(skgrMergeF1$hoh ~ I(skgrMergeF1$lat), f=0.1), col="green")
lines(lowess(f1sm7$fitted ~ I(skgrMergeF1$lat), f=0.1), col="red")
plot(skgrMergeF1$hoh ~ I(skgrMergeF1$lon))
lines(lowess(skgrMergeF1$hoh ~ I(skgrMergeF1$lon), f=0.1), col="green")
lines(lowess(f1sm7$fitted ~ I(skgrMergeF1$lon), f=0.1), col="red")

plot(f1sm4$fitted ~ I(skgrMergeF1t$coast_line_distance))
lines(lowess(skgrMergeF1t$hoh ~ I(skgrMergeF1t$coast_line_distance), f=0.1), col="green")
lines(lowess(f1sm4$fitted ~ I(skgrMergeF1t$coast_line_distance), f=0.1), col="red")

plot(f1sm7$fitted ~ I(skgrMergeF1$lat))
lines(lowess(skgrMergeF1$hoh ~ I(skgrMergeF1$lat), f=0.1), col="green")
lines(lowess(f1sm7$fitted ~ I(skgrMergeF1$lat), f=0.1), col="red")

plot(f1sm7$fitted ~ I(skgrMergeF1$lon))
lines(lowess(skgrMergeF1$hoh ~ I(skgrMergeF1$lon), f=0.1), col="green")
lines(lowess(f1sm7$fitted ~ I(skgrMergeF1$lon), f=0.1), col="red")

plot(f1sm7$fitted ~ I(skgrMergeF1$amount_ocean_100200m))
lines(lowess(skgrMergeF1$hoh ~ I(skgrMergeF1$amount_ocean_100200m), f=0.1), col="green")
lines(lowess(f1sm7$fitted ~ I(skgrMergeF1$amount_ocean_100200m), f=0.1), col="red")

plot(f1sm7$fitted ~ I(skgrMergeF1$coast_line_distance))
lines(lowess(skgrMergeF1$hoh ~ I(skgrMergeF1$coast_line_distance), f=0.1), col="green")
lines(lowess(f1sm7$fitted ~ I(skgrMergeF1$coast_line_distance), f=0.1), col="red")

plot(skgrMergeF1$hoh ~ I(skgrMergeF1$lat))
lines(lowess(skgrMergeF1$hoh ~ I(skgrMergeF1$lat), f=0.1), col="green")
lines(lowess(f1sm6$fitted ~ I(skgrMergeF1$lat), f=0.1), col="red")

plot(skgrMergeF1$hoh ~ I(skgrMergeF1$lon))
lines(lowess(skgrMergeF1$hoh ~ I(skgrMergeF1$lon), f=0.1), col="green")
lines(lowess(f1sm6$fitted ~ I(skgrMergeF1$lon), f=0.1), col="red")

plot(skgrMergeF1$hoh ~ I(skgrMergeF1$amount_ocean_100200m))
lines(lowess(skgrMergeF1$hoh ~ I(skgrMergeF1$amount_ocean_100200m), f=0.1), col="green")
lines(lowess(f1sm6$fitted ~ I(skgrMergeF1$amount_ocean_100200m), f=0.1), col="red")

plot(skgrMergeF1$hoh ~ I(skgrMergeF1$lat))
lines(lowess(skgrMergeF1$hoh ~ I(skgrMergeF1$slope_5), f=0.1), col="green")

#abline(v=1300000, col="yellow")
#abline(v=3250000, col="yellow")
#abline(v=8000000, col="yellow")

abline(v=2400000, col="yellow")
abline(v=4250000, col="yellow")
abline(v=7500000, col="yellow")
abline(v=13000000, col="green")
abline(v=18500000, col="green")
abline(v=23500000, col="green")
abline(v=32500000, col="green")

abline(v=1250000, col="yellow")
abline(v=3000000, col="yellow")
abline(v=6000000, col="yellow")
#abline(v=9000000, col="yellow")
abline(v=10000000, col="yellow")
abline(v=18500000, col="yellow")
abline(v=27500000, col="yellow")
abline(v=37000000, col="yellow")

f1sm6 <- lm(hoh ~ lat_tan + lon * I(solar_radiation^5) + I(amount_ocean_100200m) * sqrt(coast_line_distance) + lat_tan * as.factor(aspect5_cl16) + lon * sqrt(coast_line_distance) + lat_tan * sqrt(coast_line_distance) + lat_tan * I(amount_ocean_100200m) + lon * I(amount_ocean_100200m) +I(solar_radiation^5) * lat_tan + I(solar_radiation^5) * as.factor(aspect5_cl16) + lon * I(amount_ocean_10100m)+ lat_tan * I(amount_ocean_10100m)+ I(amount_ocean_10100m) * sqrt(coast_line_distance)+ lon * I(amount_ocean_50200m)+ lat_tan * I(amount_ocean_50200m)+ I(amount_ocean_50200m) * sqrt(coast_line_distance)+ lon * I(amount_ocean_25000m)+ lat_tan * I(amount_ocean_25000m)+ I(amount_ocean_25000m) * sqrt(coast_line_distance)+ lon * I(amount_ocean_5050m)+ lat_tan * I(amount_ocean_5050m)+ I(amount_ocean_5050m) * sqrt(coast_line_distance), data=skgrMergeF1t)


#Create two alternative filter (more variation on large scale allowed)???
#Make data exploration plots for all three filters
# skgrMergeF1t$amo_fact1 <- 0
# skgrMergeF1t$amo_fact1[skgrMergeF1t$amount_ocean_100200m<1250000] <- 2
# #skgrMergeF1t$amo_fact1[skgrMergeF1t$amount_ocean_100200m<=1] <- 1
# skgrMergeF1t$amo_fact1[skgrMergeF1t$coast_line_distance<=55000] <- 1#60000
# skgrMergeF1t$amo_fact1[skgrMergeF1t$coast_line_distance>55000&skgrMergeF1t$coast_line_distance<=70000] <- 0#60000
# skgrMergeF1t$amo_fact1[skgrMergeF1t$coast_line_distance>70000&skgrMergeF1t$coast_line_distance<=95000] <- -1#60000
# skgrMergeF1t$amo_fact1[skgrMergeF1t$coast_line_distance>1200000] <- -2#60000
# skgrMergeF1t$amo_fact1[skgrMergeF1t$amount_ocean_100200m>=1250000] <- 3
# skgrMergeF1t$amo_fact1[skgrMergeF1t$amount_ocean_100200m>=3000000] <- 4
# skgrMergeF1t$amo_fact1[skgrMergeF1t$amount_ocean_100200m>=6000000] <- 5
# skgrMergeF1t$amo_fact1[skgrMergeF1t$amount_ocean_100200m>=10000000] <- 6
# skgrMergeF1t$amo_fact1[skgrMergeF1t$amount_ocean_100200m>=18500000] <- 7
# skgrMergeF1t$amo_fact1[skgrMergeF1t$amount_ocean_100200m>=27500000] <- 8
# skgrMergeF1t$amo_fact1[skgrMergeF1t$amount_ocean_100200m>=37000000] <- 9

# skgrMergeF1t$amo_fact <- 0
# skgrMergeF1t$amo_fact[skgrMergeF1t$amount_ocean_100200m<1250000] <- 2
# skgrMergeF1t$amo_fact[skgrMergeF1t$amount_ocean_100200m<=1] <- 1
# skgrMergeF1t$amo_fact[skgrMergeF1t$amount_ocean_100200m>=1250000] <- 3
# skgrMergeF1t$amo_fact[skgrMergeF1t$amount_ocean_100200m>=3000000] <- 4
# skgrMergeF1t$amo_fact[skgrMergeF1t$amount_ocean_100200m>=6000000] <- 5
# skgrMergeF1t$amo_fact[skgrMergeF1t$amount_ocean_100200m>=10000000] <- 6
# skgrMergeF1t$amo_fact[skgrMergeF1t$amount_ocean_100200m>=18500000] <- 7

skgrMergeF1t$lat_tan <- tan(skgrMergeF1t$lat*pi/180)
skgrMergeF1t$lat_tan_e2 <- tan(skgrMergeF1t$lat*pi/180)^2
skgrMergeF1t$lat_tan_e3 <- tan(skgrMergeF1t$lat*pi/180)^3
skgrMergeF1t$lat_tan_e4 <- tan(skgrMergeF1t$lat*pi/180)^4
skgrMergeF1t$lat_tan_e5 <- tan(skgrMergeF1t$lat*pi/180)^5
skgrMergeF1t$lat_tan_e6 <- tan(skgrMergeF1t$lat*pi/180)^6
skgrMergeF1t$lat_tan_e7 <- tan(skgrMergeF1t$lat*pi/180)^7
skgrMergeF1t$lat_tan_e8 <- tan(skgrMergeF1t$lat*pi/180)^8
skgrMergeF1t$lat_tan_e9 <- tan(skgrMergeF1t$lat*pi/180)^9
skgrMergeF1t$lat_tan_e10 <- tan(skgrMergeF1t$lat*pi/180)^10
skgrMergeF1t$lat_tan_e20 <- tan(skgrMergeF1t$lat*pi/180)^20
skgrMergeF1t$lat_tan_e30 <- tan(skgrMergeF1t$lat*pi/180)^30
skgrMergeF1t$lat_tan_e50 <- tan(skgrMergeF1t$lat*pi/180)^50
skgrMergeF1t$lat_tan_e100 <- tan(skgrMergeF1t$lat*pi/180)^100


skgrMergeF1$amo_fact1 <- 0
skgrMergeF1$amo_fact1[skgrMergeF1$amount_ocean_100200m<1250000] <- 2
skgrMergeF1$amo_fact1[skgrMergeF1$amount_ocean_100200m<=1] <- 1
skgrMergeF1$amo_fact1[skgrMergeF1$coast_line_distance>70000&skgrMergeF1$coast_line_distance<=90000] <- 0
skgrMergeF1$amo_fact1[skgrMergeF1$coast_line_distance>90000] <- -1
skgrMergeF1$amo_fact1[skgrMergeF1$amount_ocean_100200m>=1250000] <- 3
skgrMergeF1$amo_fact1[skgrMergeF1$amount_ocean_100200m>=3000000] <- 4
skgrMergeF1$amo_fact1[skgrMergeF1$amount_ocean_100200m>=6000000] <- 5
skgrMergeF1$amo_fact1[skgrMergeF1$amount_ocean_100200m>=10000000] <- 6
skgrMergeF1$amo_fact1[skgrMergeF1$amount_ocean_100200m>=18500000] <- 7
# #skgrMergeF1t$amo_fact1[skgrMergeF1t$amount_ocean_100200m>=27500000] <- 8
# #skgrMergeF1t$amo_fact1[skgrMergeF1t$amount_ocean_100200m>=37000000] <- 9

skgrMergeF1t$amo_fact1 <- 0
skgrMergeF1t$amo_fact1[skgrMergeF1t$amount_ocean_100200m<1250000] <- 2
skgrMergeF1t$amo_fact1[skgrMergeF1t$amount_ocean_100200m<=1] <- 1
skgrMergeF1t$amo_fact1[skgrMergeF1t$coast_line_distance>70000] <- 0
skgrMergeF1t$amo_fact1[skgrMergeF1t$amount_ocean_100200m>=1250000] <- 3
skgrMergeF1t$amo_fact1[skgrMergeF1t$amount_ocean_100200m>=3000000] <- 4
skgrMergeF1t$amo_fact1[skgrMergeF1t$amount_ocean_100200m>=10000000] <- 5
skgrMergeF1t$amo_fact1[skgrMergeF1t$amount_ocean_100200m>=18500000] <- 6

skgrm$amo_fact1 <- 0
skgrm$amo_fact1[skgrm$amount_ocean_100200m<1250000] <- 2
skgrm$amo_fact1[skgrm$amount_ocean_100200m<=1] <- 1
skgrm$amo_fact1[skgrm$coast_line_distance>70000] <- 0
skgrm$amo_fact1[skgrm$amount_ocean_100200m>=1250000] <- 3
skgrm$amo_fact1[skgrm$amount_ocean_100200m>=3000000] <- 4
skgrm$amo_fact1[skgrm$amount_ocean_100200m>=10000000] <- 5
skgrm$amo_fact1[skgrm$amount_ocean_100200m>=18500000] <- 6

f1sm6 <- lm(hoh ~ I(solar_radiation^4) * as.factor(amo_fact1) + lat * amount_ocean_100200m * as.factor(amo_fact1) + lon * amount_ocean_100200m * as.factor(amo_fact1) + lat * coast_line_distance * as.factor(amo_fact1) + lon * coast_line_distance * as.factor(amo_fact1) + lat * lon  * as.factor(amo_fact1) + TPI_5100m_stddev * lat * as.factor(amo_fact1), data=skgrMergeF1)

f1sm6 <- lm(hoh ~ slope_5 * I(solar_radiation^4) * as.factor(aspect5_cl8) + lat * amount_ocean_100200m * as.factor(amo_fact1) + lon * amount_ocean_100200m * as.factor(amo_fact1) + lat * lon  * as.factor(amo_fact1), data=skgrMergeF1)
f1sm6 <- lm(hoh ~ slope_5 * I(solar_radiation^4) * as.factor(aspect5_cl8) + lat * as.factor(amo_fact1) + I(amount_ocean_100200m^10) * as.factor(amo_fact1) + lon * as.factor(amo_fact1) + lat * lon + TPI_5100m, data=skgrMergeF1)

 f1sm6 <- lm(hoh ~ I(slope_5) * I(solar_radiation^4) * as.factor(aspect5_cl8) + lat * I(amount_ocean_100200m)  * as.factor(amo_fact1) + lon * I(amount_ocean_100200m) * as.factor(amo_fact1) + lat * I(coast_line_distance) * as.factor(amo_fact1) + lat * lon  * as.factor(amo_fact1) + lon * I(coast_line_distance) * as.factor(amo_fact1), data=skgrMergeF1t)


f1sm6 <- lm(hoh ~ I(slope_5) * I(solar_radiation^4) * as.factor(aspect5_cl8) + lat * I(amount_ocean_100200m)  * as.factor(amo_fact1) + lon * I(amount_ocean_100200m) * as.factor(amo_fact1) + lat * I(coast_line_distance) * as.factor(amo_fact1) + lon * I(coast_line_distance) * as.factor(amo_fact1) + lat * lon  * as.factor(amo_fact1), data=skgrMergeF1t)

skgrMergeF1$cld_fact1 <- 0
skgrMergeF1$cld_fact1[skgrMergeF1$coast_line_distance<2500] <- 1
skgrMergeF1$cld_fact1[skgrMergeF1$coast_line_distance>=2500] <- 2
skgrMergeF1$cld_fact1[skgrMergeF1$coast_line_distance>=20000] <- 3
skgrMergeF1$cld_fact1[skgrMergeF1$coast_line_distance>=65000] <- 4
skgrMergeF1$cld_fact1[skgrMergeF1$coast_line_distance>=90000] <- 5

f1sm6 <- lm(hoh ~ I(slope_5) * I(solar_radiation) + I(solar_radiation) * as.factor(aspect5_cl8)  + lat * I(coast_line_distance) * lon * I(amount_ocean_100200m) * as.factor(amo_fact), data=skgrMergeF1)

f1sm6 <- lm(hoh ~ I(slope_5) * I(solar_radiation^4) * as.factor(aspect5_cl8)  + I(solar_radiation^4) * I(amount_ocean_100200m) + lat * I(amount_ocean_100200m)  * as.factor(amo_fact) + lon * I(amount_ocean_100200m) * as.factor(amo_fact) + lat * I(coast_line_distance) + lat * lon  * as.factor(amo_fact) + lon * I(coast_line_distance), data=skgrMergeF1)



skgrm$amo_fact <- 0
skgrm$amo_fact[skgrm$amount_ocean_100200m<2400000] <- 2
skgrm$amo_fact[skgrm$amount_ocean_100200m<=1] <- 1
skgrm$amo_fact[skgrm$coast_line_distance>70000&skgrm$coast_line_distance<=90000] <- 0#60000
skgrm$amo_fact[skgrm$coast_line_distance>90000] <- -1#60000
skgrm$amo_fact[skgrm$amount_ocean_100200m>=2400000] <- 3
skgrm$amo_fact[skgrm$amount_ocean_100200m>=4250000] <- 4
skgrm$amo_fact[skgrm$amount_ocean_100200m>=7500000] <- 5
skgrm$amo_fact[skgrm$amount_ocean_100200m>=13000000] <- 6
skgrm$amo_fact[skgrm$amount_ocean_100200m>=18500000] <- 7
skgrm$amo_fact[skgrm$amount_ocean_100200m>=23500000] <- 8



#Identify necessary transformations using exploration plots and a series of models
f1sm7 <- lm(hoh ~ lat_tan * sqrt(coast_line_distance) + lon * I(solar_radiation^10) + lon * sqrt(amount_ocean_100200m) + lat * sqrt(amount_ocean_50200m) + lat * sqrt(amount_ocean_25000m) + lat * sqrt(amount_ocean_10100m) + lat * sqrt(amount_ocean_5050m) + lat * as.factor(aspect5_cl8) + I(solar_radiation^10) * as.factor(aspect5_cl8), data=skgrMergeF1)

f1sm6 <- lm(hoh ~ lat_tan_e8 + lon + I(solar_radiation^10) + sqrt(amount_ocean_100200m) + sqrt(coast_line_distance) + as.factor(aspect5_cl8) + lat_tan_e8 + lon + sqrt(amount_ocean_100200m) * sqrt(coast_line_distance) + lon * sqrt(coast_line_distance) + lat_tan_e8 * sqrt(coast_line_distance) + lat_tan_e8 * sqrt(amount_ocean_100200m), data=skgrMergeF1t)
f1sm6 <- lm(hoh ~ lat_tan_e8 + lon + I(solar_radiation^10) + sqrt(amount_ocean_100200m) + sqrt(coast_line_distance) + as.factor(aspect5_cl8) + lat_tan_e8 + lon + sqrt(amount_ocean_100200m) * sqrt(coast_line_distance) + lon * sqrt(coast_line_distance) + lat_tan_e8 * sqrt(coast_line_distance) + lat_tan_e8 * sqrt(amount_ocean_100200m), data=skgrMergeF1)

f1sm7 <- lm(hoh ~ lat_tan + lon + solar_radiation + sqrt(amount_ocean_100200m) * sqrt(coast_line_distance) + as.factor(aspect5_cl8) + lat_tan + lon + sqrt(amount_ocean_100200m) * sqrt(coast_line_distance) + lon * sqrt(coast_line_distance) + lat_tan * sqrt(coast_line_distance) + lat_tan * sqrt(amount_ocean_100200m), data=skgrMergeF1t)
f1sm7 <- lm(hoh ~ lat_tan_e8 + lon + I(solar_radiation^10) + sqrt(amount_ocean_100200m) + sqrt(coast_line_distance) + as.factor(aspect5_cl8) + lat_tan_e8 + lon + sqrt(amount_ocean_100200m) * sqrt(coast_line_distance) + lon * sqrt(coast_line_distance) + lat_tan_e8 * sqrt(coast_line_distance) + lat_tan_e8 * sqrt(amount_ocean_100200m), data=skgrMergeF1)

skgrMergeF1tm <- skgrMergeF1t[(f1sm7$residuals>-250),]

skgrMergeF1t[names(f1sm7$residuals)==as.character(2530752),]
f1sm7 <- lm(hoh ~ lat_tan + lon + I(solar_radiation^10) + sqrt(amount_ocean_100200m) * sqrt(coast_line_distance) + as.factor(aspect5_cl8) + lat_tan + lon + sqrt(amount_ocean_100200m) * sqrt(coast_line_distance) + lon * sqrt(coast_line_distance) + lat_tan * sqrt(coast_line_distance) + lat_tan * sqrt(amount_ocean_100200m), data=skgrMergeF1t)
f1sm7 <- lm(hoh ~ lat_tan_e2 + lon + I(solar_radiation^10) + sqrt(amount_ocean_100200m) * sqrt(coast_line_distance) + as.factor(aspect5_cl8) + lat_tan_e2 + lon + sqrt(amount_ocean_100200m) * sqrt(coast_line_distance) + lon * sqrt(coast_line_distance) + lat_tan_e2 * sqrt(coast_line_distance) + lat_tan_e2 * sqrt(amount_ocean_100200m), data=skgrMergeF1t)


f1sm7 <- lm(hoh ~ solar_radiation * lon + solar_radiation * lon + solar_radiation * as.factor(aspect5_cl8) + solar_radiation * coast_line_distance + solar_radiation * amount_ocean_100200m, data=skgrMergeF1t)
AIC(f1sm7)
summary(f1sm7$fitted)
summary(f1sm7$residuals)
f1sm7 <- lm(hoh ~ I(solar_radiation^2) * lon + I(solar_radiation^2) * lon + I(solar_radiation^2) * as.factor(aspect5_cl8) + I(solar_radiation^2) * coast_line_distance + I(solar_radiation^2) * amount_ocean_100200m, data=skgrMergeF1t)
AIC(f1sm7)
summary(f1sm7$fitted)
summary(f1sm7$residuals)
f1sm7 <- lm(hoh ~ I(solar_radiation^5) * lon + I(solar_radiation^5) * lon + I(solar_radiation^5) * as.factor(aspect5_cl8) + I(solar_radiation^5) * coast_line_distance + I(solar_radiation^5) * amount_ocean_100200m, data=skgrMergeF1t)
AIC(f1sm7)
summary(f1sm7$fitted)
summary(f1sm7$residuals)
f1sm7 <- lm(hoh ~ I(solar_radiation^10) * lon + I(solar_radiation^10) * lon + I(solar_radiation^10) * as.factor(aspect5_cl8) + I(solar_radiation^10) * coast_line_distance + I(solar_radiation^10) * amount_ocean_100200m, data=skgrMergeF1t)
AIC(f1sm7)
summary(f1sm7$fitted)
summary(f1sm7$residuals)

skgrMergeF1tm <- skgrMergeF1tc[(f1sm3$residuals>-250),]

#1Modell with more emphasis on solar radiation
#1Modell with coordinates in addition
#1Modell with coordinates and exponential influence of lat
#1GLS with three variance structures

f1sm3a <- lm(hoh ~ lat * lon + lat * I(amount_ocean_180200m) + lat * I(solar_radiation) + lon * I(amount_ocean_180200m) + lon * I(solar_radiation) + I(amount_ocean_180200m) * I(solar_radiation) + I(solar_radiation) * as.factor(aspect5_cl8), data = skgrMergeF1)
f1sm3als <- gls(hoh ~ lat * lon + lat * I(amount_ocean_180200m) + lat * I(solar_radiation) + lon * I(amount_ocean_180200m) + lon * I(solar_radiation) + I(amount_ocean_180200m) * I(solar_radiation) + I(solar_radiation) * as.factor(aspect5_cl8), data = skgrMergeF1)
f1sm3als_slope <- gls(hoh ~ lat * lon + lat * I(amount_ocean_180200m) + lat * I(solar_radiation) + lon * I(amount_ocean_180200m) + lon * I(solar_radiation) + I(amount_ocean_180200m) * I(solar_radiation) + I(solar_radiation) * as.factor(aspect5_cl8), weights=varPower(form=~slope_5), data = skgrMergeF1)
f1sm3als_TPI_5100 <- gls(hoh ~ lat * lon + lat * I(amount_ocean_180200m) + lat * I(solar_radiation) + lon * I(amount_ocean_180200m) + lon * I(solar_radiation) + I(amount_ocean_180200m) * I(solar_radiation) + I(solar_radiation) * as.factor(aspect5_cl8), weights=varPower(form=~TPI_5100m), data = skgrMergeF1)
f1sm3als_TPI_5100_stddev <- gls(hoh ~ lat * lon + lat * I(amount_ocean_180200m) + lat * I(solar_radiation) + lon * I(amount_ocean_180200m) + lon * I(solar_radiation) + I(amount_ocean_180200m) * I(solar_radiation) + I(solar_radiation) * as.factor(aspect5_cl8), weights=varPower(form=~TPI_5100m_stddev), data = skgrMergeF1)
f1sm3als_max_forest_25000m_gid_patch <- gls(hoh ~ lat * lon + lat * I(amount_ocean_180200m) + lat * I(solar_radiation) + lon * I(amount_ocean_180200m) + lon * I(solar_radiation) + I(amount_ocean_180200m) * I(solar_radiation) + I(solar_radiation) * as.factor(aspect5_cl8), weights=varPower(form=~max_forest_25000m_gid_patch), data = skgrMergeF1)
f1sm3als_max_forest_sum <- gls(hoh ~ lat * lon + lat * I(amount_ocean_180200m) + lat * I(solar_radiation) + lon * I(amount_ocean_180200m) + lon * I(solar_radiation) + I(amount_ocean_180200m) * I(solar_radiation) + I(solar_radiation) * as.factor(aspect5_cl8), weights=varPower(form=~max_forest_sum), data = skgrMergeF1)
f1sm3als_comb <- gls(hoh ~ lat * lon + lat * I(amount_ocean_180200m) + lat * I(solar_radiation) + lon * I(amount_ocean_180200m) + lon * I(solar_radiation) + I(amount_ocean_180200m) * I(solar_radiation) + I(solar_radiation) * as.factor(aspect5_cl8), weights=varComb(varPower(form=~slope_5),varPower(form=~TPI_5100m_stddev),varPower(form=~TPI_3100m_stddev)), data = skgrMergeF1)

AIC(f1sm3als,f1sm3als_slope,f1sm3als_TPI_5100,f1sm3als_TPI_5100_stddev,f1sm3als_max_forest_25000m_gid_patch,f1sm3als_max_forest_sum)
, weights=varComb(varPower(form=~Y),varPower(form=~X),varPower(form=~coast_distance))



# f1sm_glm <- glm(hoh ~ lat * lon + lat * amount_ocean_180200m + lat * solar_radiation + lon * amount_ocean_180200m + lon * solar_radiation + amount_ocean_180200m * solar_radiation + solar_radiation * as.factor(aspect5_cl8), data = skgrMergeF1)
# f1sm_glm_sqrt <- glm(hoh ~ lat * lon + lat * sqrt(amount_ocean_180200m) + lat * solar_radiation + lon * sqrt(amount_ocean_180200m) + lon * solar_radiation + sqrt(amount_ocean_180200m) * solar_radiation + solar_radiation * as.factor(aspect5_cl8), data = skgrMergeF1)
# f1sm_gls_slope5 <- gls(hoh ~ lat * lon + lat * amount_ocean_180200m + lat * solar_radiation + lon * amount_ocean_180200m + lon * solar_radiation + amount_ocean_180200m * solar_radiation + solar_radiation * as.factor(aspect5_cl8), weights=varPower(form=~slope_5), method="REML", data = skgrMergeF1)
# f1sm_gls_slope5_sqrt <- gls(hoh ~ lat * lon + lat * sqrt(amount_ocean_180200m) + lat * solar_radiation + lon * sqrt(amount_ocean_180200m) + lon * solar_radiation + sqrt(amount_ocean_180200m) * solar_radiation + solar_radiation * as.factor(aspect5_cl8), weights=varPower(form=~slope_5), method="REML", data = skgrMergeF1)
# f1sm_gls_ocean_slope5_sqrt <- gls(hoh ~ lat * lon + lat * sqrt(amount_ocean_180200m) + lat * sqrt(amount_ocean_100200m) + lat * sqrt(amount_ocean_50200m) + lat * solar_radiation + lon * sqrt(amount_ocean_180200m) + lon * solar_radiation + sqrt(amount_ocean_180200m) * solar_radiation + solar_radiation * as.factor(aspect5_cl8), weights=varPower(form=~slope_5), method="REML", data = skgrMergeF1)

#Test correlation
, correlation=corCompSymm(form=~1|as.factor(GID))

zcol <- level.colors((f1sm_gls_ve_lat$resid), at=c(min(f1sm_gls_ve_lat$residuals), -100, -50, 0, 50, 100, max(f1sm_gls_ve_lat$residuals)), col.regions=colorRampPalette(c("darkgreen", "green", "lightgreen", "yellow", "orange", "red", "darkred")), interpolate = c("linear"))
xyplot(Y ~ X | "Residualer i modellf1sm_gls_ve_lat", data=skgrMergeF1, col=zcol, aspect = 1, .aspect.ratio = 1, pch=20, cex=0.1)

f1sm_glm_full_sqrt_X <- gls(hoh ~ lat * X + lat * sqrt(amount_ocean_180200m) + lat * coast_line_distance + lat * solar_radiation + X * sqrt(amount_ocean_180200m)  + X * coast_line_distance + sqrt(amount_ocean_180200m) * coast_line_distance + sqrt(amount_ocean_180200m) * solar_radiation + solar_radiation * coast_line_distance + solar_radiation * as.factor(aspect5_cl8), method="ML", data = skgrMergeF1)

AIC(f1sm_glm_full_sqrt_lon,f1sm_glm_full_sqrt_X)

#f_ucoast <- formula(hoh ~ lat * lon + lat * sqrt(amount_ocean_180200m) + lat * solar_radiation + lat * as.factor(aspect5_cl8) + lon * sqrt(amount_ocean_180200m) + lon * solar_radiation + sqrt(amount_ocean_180200m) * solar_radiation + solar_radiation * as.factor(aspect5_cl8))
#f1sm_glm_full <- gls(f_ucoast, method="REML", data = skgrMergeF1)
#f1sm_gls_ve_lat <- gls(f_ucoast, weights=varExp(form=~coast_line_distance), method="REML", data = skgrMergeF1)
#f1sm_gls_vp_lat <- gls(f_ucoast, weights=varPower(form=~coast_line_distance), method="REML", data = skgrMergeF1)
hoh ~ lat * lon + lat * sqrt(amount_ocean_180200m) + lat * coast_line_distance + lat * solar_radiation + lon * sqrt(amount_ocean_180200m)  + lon * coast_line_distance + sqrt(amount_ocean_180200m) * coast_line_distance + sqrt(amount_ocean_180200m) * solar_radiation + solar_radiation * coast_line_distance + solar_radiation * as.factor(aspect5_cl8)
hoh ~ lat * sqrt(amount_ocean_180200m) + lat * coast_line_distance + lat * solar_radiation + lat * as.factor(aspect5_cl8) + sqrt(amount_ocean_180200m) * coast_line_distance + sqrt(amount_ocean_180200m) * solar_radiation + solar_radiation * coast_line_distance + solar_radiation * as.factor(aspect5_cl8)
hoh ~ lat * lon + lat * sqrt(amount_ocean_180200m) + lat * solar_radiation + lat * as.factor(aspect5_cl8) + lon * sqrt(amount_ocean_180200m) + lon * solar_radiation + sqrt(amount_ocean_180200m) * solar_radiation + solar_radiation * as.factor(aspect5_cl8)

f1sm_gls_full <- gls(hoh ~ lat * lon + lat * sqrt(amount_ocean_180200m) + lat * solar_radiation + lon * sqrt(amount_ocean_180200m) + lon * solar_radiation + sqrt(amount_ocean_180200m) * solar_radiation + solar_radiation * as.factor(aspect5_cl8) + lat * as.factor(aspect5_cl8) + sqrt(amount_ocean_180200m) * as.factor(aspect5_cl8) + sqrt(amount_ocean_180200m) * coast_line_distance + lat * coast_line_distance + lon * coast_line_distance, weights=varComb(varPower(form=~amount_ocean_50200m), varPower(form=~actuality), varPower(form=~TPI_3100m_stddev), varPower(form=~coast_line_distance), varPower(form=~slope_5), varIdent(form=~1|GID)), method="REML", data = skgrMergeF1)
# no lon
# id as randomfactor (as.integer(row.names(skgrMergeF1))

AIC(f1sm_glm,f1sm_glm,f1sm_gls_slope5,f1sm_gls_slope5,f1sm_gls_ocean_slope5)

f1sm_glm_full <- gls(f_gls, weights=varComb(varPower(form=~slope_5), varPower(form=~amount_ocean_180200m), varExp(form=~coast_line_distance), varPower(form=~TPI_3100m_stddev), varExp(form=~max_forest_50200m)), method="REML", data = skgrMergeF1)



f1sm_glm <- confint(f1sm_glm, c(0.1,0.9))
f1sm_glm_sqrt <- confint(f1sm_glm_sqrt, c(0.1,0.9))
f1sm_gls_slope5 <- confint(f1sm_gls_slope5, c(0.1,0.9))
f1sm_gls_slope5_sqrt <- confint(f1sm_gls_slope5_sqrt, c(0.1,0.9))
f1sm_gls_ocean_slope5_sqrt <- confint(f1sm_gls_ocean_slope5_sqrt, c(0.1,0.9))


