PCA <- function(attributes, name, compNumber){
  library(pls)
  
  # scale data
  attributes.scaled = scale(attributes)
  
  # pca
  attributes.pca <- prcomp(attributes.scaled, center = FALSE, scale = FALSE)
  
  # results
  loadingVector = attributes.pca 
  pcaSummary = summary(attributes.pca)  # stdev, proportion of variance, cumulative proportion
  print(pcaSummary)
  
  plot(attributes.pca, type = "l")   
  plot(pcaSummary$importance[1,1:30], type = "l") # plot standard deviation
  plot(pcaSummary$importance[2,1:30], type = "l") # plot proportion of variance explained
  plot(pcaSummary$importance[3,1:30], type = "l") # plot cumulative proportion of variance explained
  
  pcaResult = attributes.pca$x[,1:compNumber] # only take n first components into account
  write.table(pcaResult, file = "BL_PCA2.csv", sep = ",") # write result in table
  return(pcaResult)
}