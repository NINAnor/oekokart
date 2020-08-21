g.region -p raster=sea_10m res=50 n=n+10 e=e+20
r.resamp.stats --overwrite --verbose input=sea_10m output=sea_50m_count method=count
r.null map=sea_50m_count null=0
r.neighbors --overwrite --verbose input=sea_50m_count@g_SeaRegions_Fenoscandia output=sea_50m_amount_2500m method=sum size=51
