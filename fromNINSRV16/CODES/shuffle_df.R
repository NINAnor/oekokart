# import data
setwd("/home/zofie.cimburova/ECOFUNC/DATA/OBSERVATIONS")
#test_data <- read.csv("test_data.csv")

#ggplot() + geom_tile(data=test_data, aes(x=col, y=10-row+1, fill=nsuccess/ntrials)) + coord_equal()

# shuffle rows in data frame
#test_data <- test_data[sample(1:nrow(test_data)), ]

# INLA
require(INLA)

## parameters of matern field - range, precision






