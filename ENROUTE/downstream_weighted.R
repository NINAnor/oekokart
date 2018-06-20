# Charge your raster
r1<-raster("/home/zofie.cimburova/ENROUTE/DATA/runoff_oslo_komunne_10m.tif") #include the complete path of your raster file inside the paenthesis
rdir<-raster("/home/zofie.cimburova/ENROUTE/DATA/flowdir_oslo_komunne_10m.tif") # Add flow direction raster
r1.matrix<-as.matrix(r1)
mdir<-as.matrix(rdir)
r2.matrix<-r1.matrix


for (i in 1:ncol(r1.matrix)){
  for (j in 1:nrow(r1.matrix)){
    x<-i
    y<-j
    valor<-0
    while ((x>=1) & (x<=ncol(r1.matrix)) & (y>=1) & (y<=nrow(r1.matrix))){
      if (is.na(mdir[y,x])==TRUE){
        break
      }
      if (mdir[y,x]==1){
        valor<-valor+r1.matrix[y,x]
        x<-x+1
        if ((x>=1) & (x<=ncol(r1.matrix)) & (y>=1) & (y<=nrow(r1.matrix))){
          if (is.na(mdir[y,x])==TRUE){
            break
          }
          if(mdir[y,x]==16){break}
        }
        next
      } 
      if (mdir[y,x]==2){
        valor<-valor+r1.matrix[y,x]
        x<-x+1
        y<-y+1
        if ((x>=1) & (x<=ncol(r1.matrix)) & (y>=1) & (y<=nrow(r1.matrix))){
          if (is.na(mdir[y,x])==TRUE){
            break
          }
          if(mdir[y,x]==32){break}
        }
        next
      } 
      if (mdir[y,x]==4){
        valor<-valor+r1.matrix[y,x]
        y<-y+1
        if ((x>=1) & (x<=ncol(r1.matrix)) & (y>=1) & (y<=nrow(r1.matrix))){
          if (is.na(mdir[y,x])==TRUE){
            break
          }
          if(mdir[y,x]==64){break}
        }
        next
      } 
      if (mdir[y,x]==8){
        valor<-valor+r1.matrix[y,x]
        x<-x-1
        y<-y+1
        if ((x>=1) & (x<=ncol(r1.matrix)) & (y>=1) & (y<=nrow(r1.matrix))){
          if (is.na(mdir[y,x])==TRUE){
            break
          }
          if(mdir[y,x]==128){break}
        }
        next
      } 
      if (mdir[y,x]==16){
        valor<-valor+r1.matrix[y,x]
        x<-x-1
        if ((x>=1) & (x<=ncol(r1.matrix)) & (y>=1) & (y<=nrow(r1.matrix))){
          if (is.na(mdir[y,x])==TRUE){
            break
          }
          if(mdir[y,x]==1){break}
        }
        next
      } 
      if (mdir[y,x]==32){
        valor<-valor+r1.matrix[y,x]
        x<-x-1
        y<-y-1
        if ((x>=1) & (x<=ncol(r1.matrix)) & (y>=1) & (y<=nrow(r1.matrix))){
          if (is.na(mdir[y,x])==TRUE){
            break
          }
          if(mdir[y,x]==2){break}
        }
        next
      } 
      if (mdir[y,x]==64){
        valor<-valor+r1.matrix[y,x]
        y<-y-1
        if ((x>=1) & (x<=ncol(r1.matrix)) & (y>=1) & (y<=nrow(r1.matrix))){
          if (is.na(mdir[y,x])==TRUE){
            break
          }
          if(mdir[y,x]==4){break}
        }
        next
      } 
      if (mdir[y,x]==128){
        valor<-valor+r1.matrix[y,x]
        x<-x+1
        y<-y-1
        if ((x>=1) & (x<=ncol(r1.matrix)) & (y>=1) & (y<=nrow(r1.matrix))){
          if (is.na(mdir[y,x])==TRUE){
            break
          }
          if(mdir[y,x]==8){break}
        }
        next
      }
      
    }
    r2.matrix[j,i]<-valor
  }
}


r2<-r1
r2[]<-r2.matrix
writeRaster(r2, filename="/home/zofie.cimburova/ENROUTE/DATA/flowacc_rev_weight_10m", format="GTiff", overwrite=TRUE) 



