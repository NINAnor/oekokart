setwd("/data/home/zofie.cimburova/ECOFUNC/DATA/")

# load data
data <- read.csv("var_sample.csv",header=FALSE)

# set header
colnames(data) <- c("x","y","1","height","bio01","bio02","bio10","bio11","bio12",
                    "bio15","bio18","bio19","sr_wi","sr_sp","sr_su","sr_au","sr_ja",
                    "lat","lon","lat2","lon2","sea_dist","aspect","slope","tpi_250","tpi_500",
                    "tpi_1000","tpi_2500","tpi_5000","topex_N","topex_E","topex_S","topex_W")

Y          <- data$height
coords     <- as.matrix(data[,1:2])
predictors <- data[,5:dim(data)[2]]


par(mfrow=c(2,ceiling(dim(predictors)[2]/2)))
for (colname in colnames(predictors)) {
  corcoef = round(cor(Y, predictors[,colname], use="complete.obs"),2) # correlation coefficient
  cat(paste(colname, corcoef, "\n", sep="\t")) 
  plot(predictors[,colname], Y, 
       cex=.5, xlab=paste(colname, toString(corcoef)))
}

OLS <- lm(Y~data$bio02)
summary(OLS)

hist(data$bio01)