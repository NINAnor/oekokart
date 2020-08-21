
# https://stackoverflow.com/questions/13575090/construct-pandas-dataframe-from-items-in-nested-dictionary

data_dict = {
    "predictor": {
		"temperature_general": {
			"v_bio10_wc": {"mapname": "WorldClim_current_bio10_1975_10m_hightdiff", "mapset": "g_Meteorology_Fenoscandia", "description": "Summer temperature (WorldClim)"},
			"v_bio10": {"mapname": "bio10_eurolst_10m", "mapset": "g_Meteorology_Fenoscandia", "description": "Summer temperature (EuroLST)"},
			"v_bio11_wc": {"mapname": "bio11_worldclim_10m", "mapset": "g_Meteorology_Fenoscandia", "description": "Winter temperature (WorldClim)"},
			"v_bio11": {"mapname": "bio11_eurolst_10m", "mapset": "g_Meteorology_Fenoscandia", "description": "Winter temperature (EuroLST)"},
			"v_bio01_wc": {"mapname": "bio01_worldclim_10m", "mapset": "g_Meteorology_Fenoscandia", "description": "Average temperature (WorldClim)"},
			"v_bio01": {"mapname": "bio01_eurolst_10m", "mapset": "g_Meteorology_Fenoscandia", "description": "Average temperature (EuroLST)"},
		},
		"local_temperature": {
			"v_srad_y": {"mapname": "solar_radiation_10m_year", "mapset": "g_EnergyResources_Fenoscandia", "description": "Yearly solar radiation"},
			#"v_srad_wi": {"mapname": "solar_radiation_10m_winter", "mapset": "g_EnergyResources_Fenoscandia", "description": "Winter solar radiation"},
			"v_srad_sp": {"mapname": "solar_radiation_10m_spring", "mapset": "g_EnergyResources_Fenoscandia", "description": "Spring solar radiation"},
			"v_srad_su": {"mapname": "solar_radiation_10m_summer", "mapset": "g_EnergyResources_Fenoscandia", "description": "Summer solar radiation"},
			"v_srad_au": {"mapname": "solar_radiation_10m_autumn", "mapset": "g_EnergyResources_Fenoscandia", "description": "Autumn solar radiation"},
			#"v_srad_1": {"mapname": "solar_radiation_10m_january", "mapset": "g_EnergyResources_Fenoscandia", "description": "January solar radiation"},
			#"v_srad_4": {"mapname": "solar_radiation_10m_april", "mapset": "g_EnergyResources_Fenoscandia", "description": "April solar radiation"},
			#"v_srad_7": {"mapname": "solar_radiation_10m_july", "mapset": "g_EnergyResources_Fenoscandia", "description": "July solar radiation"},
			#"v_srad_10": {"mapname": "solar_radiation_10m_october", "mapset": "g_EnergyResources_Fenoscandia", "description": "October solar radiation"}
		},
		"continentality": {
			"v_bio02_wc": {"mapname": "bio02_worldclim_10m", "mapset": "g_Meteorology_Fenoscandia", "description": "Approximation of continentality (WorldClim)"},
			"v_bio02": {"mapname": "bio02_eurolst_10m", "mapset": "g_Meteorology_Fenoscandia", "description": "Approximation of continentality (EuroLST)"},
			"v_sea": {"mapname": "sea_distance_10m", "mapset": "g_SeaRegions_Fenoscandia", "description": ""},
			"v_sea_open": {"mapname": "sea_open_distance_50m", "mapset": "g_SeaRegions_Fenoscandia", "description": ""},
			#"v_sea_amount_X": {"mapname": "", "mapset": "g_SeaRegions_Fenoscandia", "description": ""},
		},
		"wind_exposure": {
			"v_wind_speed_at_10m": {"mapname": "GlobalWindAtlas_150m_wind_speed_at_10m", "mapset": "g_Meteorology_Fenoscandia_Wind_GlobalWindAtlas", "description": "Modeled wind speed at 10m above ground from GlobalWindAtlas.info"},
			"v_wind_speed_at_100m": {"mapname": "GlobalWindAtlas_150m_wind_speed_at_100m", "mapset": "g_Meteorology_Fenoscandia_Wind_GlobalWindAtlas", "description": "Modeled wind speed at 100m above ground from GlobalWindAtlas.info"},
       },
		"local_wind_exposure": {
			"v_aspect_sin": {"mapname": "dem_10m_nosefi_float_aspect_sin", "mapset": "g_Elevation_Fenoscandia", "description": "Sinus function of aspect (originally in 360 deg)"},
			"v_aspect_cos": {"mapname": "dem_10m_nosefi_float_aspect_cos", "mapset": "g_Elevation_Fenoscandia", "description": "Cosinus function of aspect (originally in 360 deg)"},
			#"v_profc": {"mapname": "dem_10m_nosefi_float_profc", "mapset": "g_Elevation_Fenoscandia", "description": "Profile curvature of the terrain"},
			"v_topex_e": {"mapname": "dem_10m_topex_E", "mapset": "g_Elevation_Fenoscandia_TOPEX", "description": ""},
			#"v_topex_se": {"mapname": "dem_10m_topex_SE", "mapset": "g_Elevation_Fenoscandia_TOPEX", "description": ""},
			#"v_topex_ne": {"mapname": "dem_10m_topex_NE", "mapset": "g_Elevation_Fenoscandia_TOPEX", "description": ""},
			"v_topex_w": {"mapname": "dem_10m_topex_W", "mapset": "g_Elevation_Fenoscandia_TOPEX", "description": ""},
			#"v_topex_sw": {"mapname": "dem_10m_topex_SW", "mapset": "g_Elevation_Fenoscandia_TOPEX", "description": ""},
			#"v_topex_nw": {"mapname": "dem_10m_topex_NW", "mapset": "g_Elevation_Fenoscandia_TOPEX", "description": ""},
			"v_topex": {"mapname": "dem_10m_topex_exposure", "mapset": "g_Elevation_Fenoscandia_TOPEX", "description": ""},
			"v_tpi250": {"mapname": "dem_tpi_250_50m", "mapset": "g_Elevation_Fenoscandia_TPI", "description": ""},
			#"v_tpi500": {"mapname": "dem_tpi_500_50m", "mapset": "g_Elevation_Fenoscandia_TPI", "description": ""},
			"v_tpi1000": {"mapname": "dem_tpi_1000_50m", "mapset": "g_Elevation_Fenoscandia_TPI", "description": ""},
			#"v_tpi2500": {"mapname": "dem_tpi_2500_50m", "mapset": "g_Elevation_Fenoscandia_TPI", "description": ""},
			#"v_tpi5000": {"mapname": "dem_tpi_5000_50m", "mapset": "g_Elevation_Fenoscandia_TPI", "description": ""},
			#"v_tpi10000": {"mapname": "dem_tpi_10000_50m", "mapset": "g_Elevation_Fenoscandia_TPI", "description": ""},
		},
		"precipitation": {
				"v_bio12_wc": {"mapname": "bio12_worldclim_10m", "mapset": "g_Meteorology_Fenoscandia", "description": "Annual precipitation (WorldClim)"},
				"v_bio15_wc": {"mapname": "bio15_worldclim_10m", "mapset": "g_Meteorology_Fenoscandia", "description": "Precipitation seasonality (WorldClim)"},
				"v_bio18_wc": {"mapname": "bio18_worldclim_10m", "mapset": "g_Meteorology_Fenoscandia", "description": "Summer precipitation (WorldClim)"},
				"v_bio19_wc": {"mapname": "bio19_worldclim_10m", "mapset": "g_Meteorology_Fenoscandia", "description": "Winter precipitation (WorldClim)"},
		},
		"snow_cover": {
				"v_snowmelt_doy": {"mapname": "GLS_Snow_Cover_average_melt_DOY", "mapset": "gt_Meteorology_Fenoscandia_SnowCoverExtent_GLS_derived", "description": "Average over last day of the year before 1.September with snow cover for at least 5 days in a row"},
				#"v_snowstart_doy": {"mapname": "GLS_Snow_Cover_average_start_doy", "mapset": "gt_Meteorology_Fenoscandia_SnowCoverExtent_GLS_derived", "description": "Average over first day of the year after 1.September with snow cover for at least 5 days in a row"},
				#"v_snow_stability": {"mapname": "GLS_Snow_Cover_average_stability", "mapset": "gt_Meteorology_Fenoscandia_SnowCoverExtent_GLS_derived", "description": "Average over first day of the year after 1.September with snow cover for at least 5 days in a row"},
				#"v_snow_duration": {"mapname": "GLS_Snow_Cover_average_duration", "mapset": "gt_Meteorology_Fenoscandia_SnowCoverExtent_GLS_derived", "description": "Average over first day of the year after 1.September with snow cover for at least 5 days in a row"},
				"v_snow_cover_average": {"mapname": "GLS_Snow_Cover_average_total", "mapset": "gt_Meteorology_Fenoscandia_SnowCoverExtent_GLS_derived", "description": "Total average of snow cover from GLS"},
				#"v_snow_seasons_n": {"mapname": "GLS_Snow_Cover_seasons", "mapset": "gt_Meteorology_Fenoscandia_SnowCoverExtent_GLS_derived", "description": ""},
		},
	},
	"filter": {
		"physical_limitations": {
				"v_slope": {"mapname": "dem_10m_nosefi_float_slope", "mapset": "g_Elevation_Fenoscandia", "description": ""},
		},
		"human_influence": {
				"v_grazing": {"mapname": "x000_25833_beitebruk_89eae6_SHAPE", "mapset": "u_zofie.cimburova", "description": ""},
				"v_summer_farming": {"mapname": "", "mapset": "", "description": ""},
		},
	},
	"correlation_pattern": {
		"spatial_effects": {
				"v_x": {"mapname": "", "mapset": "", "description": ""},
				"v_y": {"mapname": "", "mapset": "", "description": ""},
		}
	}
}
        
############################
# For future scenarios
# {
# "v_bio01_wc_ghg26_2050": {"mapname": "future_ghg26_2050_bio01_worldclim_10m", "description": "2050 scenario of BIO01"},
# "v_bio02_wc_ghg26_2050": {"mapname": "future_ghg26_2050_bio02_worldclim_10m", "description": "2050 scenario of BIO02"},
# "v_bio10_wc_ghg26_2050": {"mapname": "future_ghg26_2050_bio10_worldclim_10m", "description": "2050 scenario of BIO10"},
# "v_bio11_wc_ghg26_2050": {"mapname": "future_ghg26_2050_bio11_worldclim_10m", "description": "2050 scenario of BIO11"},
# }
