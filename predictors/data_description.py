
# https://stackoverflow.com/questions/13575090/construct-pandas-dataframe-from-items-in-nested-dictionary

data_dict = {
"temperature_general": {
    "v_bio11_wc": {"mapname": "bio11_worldclim_10m", "mapset": "g_Meteorology_Fenoscandia", "description": "Winter temperature (WorldClim)"},
    "v_bio11": {"mapname": "bio11_eurolst_10m", "mapset": "g_Meteorology_Fenoscandia", "description": "Winter temperature (EuroLST)"},
    "v_bio10_wc": {"mapname": "bio10_worldclim_10m", "mapset": "g_Meteorology_Fenoscandia", "description": "Summer temperature (WorldClim)"},
    "v_bio10": {"mapname": "bio10_eurolst_10m", "mapset": "g_Meteorology_Fenoscandia", "description": "Summer temperature (EuroLST)"},
    "v_bio01_wc": {"mapname": "bio01_worldclim_10m", "mapset": "g_Meteorology_Fenoscandia", "description": "Average temperature (WorldClim)"},
    "v_bio01": {"mapname": "bio01_eurolst_10m", "mapset": "g_Meteorology_Fenoscandia", "description": "Average temperature (EuroLST)"},
},
"local_temperature": {
    "v_srad_y": {"mapname": "solar_radiation_10m_year", "mapset": "g_EnergyResources_Fenoscandia", "description": "Yearly solar radiation"},
    "v_srad_wi": {"mapname": "solar_radiation_10m_winter", "mapset": "g_EnergyResources_Fenoscandia", "description": "Winter solar radiation"},
    "v_srad_sp": {"mapname": "solar_radiation_10m_spring", "mapset": "g_EnergyResources_Fenoscandia", "description": "Spring solar radiation"},
    "v_srad_su": {"mapname": "solar_radiation_10m_summer", "mapset": "g_EnergyResources_Fenoscandia", "description": "Summer solar radiation"},
    "v_srad_au": {"mapname": "solar_radiation_10m_autumn", "mapset": "g_EnergyResources_Fenoscandia", "description": "Autumn solar radiation"},
    "v_srad_1": {"mapname": "solar_radiation_10m_january", "mapset": "g_EnergyResources_Fenoscandia", "description": "January solar radiation"},
    "v_srad_4": {"mapname": "solar_radiation_10m_april", "mapset": "g_EnergyResources_Fenoscandia", "description": "April solar radiation"},
    "v_srad_7": {"mapname": "solar_radiation_10m_july", "mapset": "g_EnergyResources_Fenoscandia", "description": "July solar radiation"},
    "v_srad_10": {"mapname": "solar_radiation_10m_october", "mapset": "g_EnergyResources_Fenoscandia", "description": "October solar radiation"}
},
"continentality": {
    "v_bio02_wc": {"mapname": "bio02_worldclim_10m", "mapset": "g_Meteorology_Fenoscandia", "description": "Approximation of continentality (WorldClim)"},
    "v_bio02": {"mapname": "bio02_eurolst_10m", "mapset": "g_Meteorology_Fenoscandia", "description": "Approximation of continentality (EuroLST)"},
    "v_sea": {"mapname": "", "mapset": "", "description": ""},
    "v_sea_open": {"mapname": "", "mapset": "", "description": ""},
    "v_sea_amount_X": {"mapname": "", "mapset": "", "description": ""},
},
"wind_exposure": {
    "v_aspect_sin": {"mapname": "", "mapset": "", "description": "Sinus function of aspect (originally in 360 deg)"}
    "v_aspect_cos": {"mapname": "", "mapset": "", "description": "Coinus function of aspect (originally in 360 deg)"}
    "v_profc": {"mapname": "", "mapset": "", "description": "Profil curvature of the terrain"}
    "v_topex_e": {"mapname": "", "mapset": "", "description": ""},
    "v_topex_se": {"mapname": "", "mapset": "", "description": ""},
    "v_topex_ne": {"mapname": "", "mapset": "", "description": ""},
    "v_topex_w": {"mapname": "", "mapset": "", "description": ""},
    "v_topex_sw": {"mapname": "", "mapset": "", "description": ""},
    "v_topex_nw": {"mapname": "", "mapset": "", "description": ""},
    "v_topex": {"mapname": "", "mapset": "", "description": ""},
    "v_tpi250": {"mapname": "", "mapset": "", "description": ""},
    "v_tpi500": {"mapname": "", "mapset": "", "description": ""},
    "v_tpi1000": {"mapname": "", "mapset": "", "description": ""},
    "v_tpi2500": {"mapname": "", "mapset": "", "description": ""},
    "v_tpi5000": {"mapname": "", "mapset": "", "description": ""},
    "v_tpi10000": {"mapname": "", "mapset": "", "description": ""},
},
"precipitation": {
        "v_bio12_wc": {"mapname": "bio12_worldclim_10m", "mapset": "g_Meteorology_Fenoscandia", "description": "Annual precipitation (WorldClim)"},
        "v_bio15_wc": {"mapname": "bio15_worldclim_10m", "mapset": "g_Meteorology_Fenoscandia", "description": "Precipitation seasonality (WorldClim)"},
        "v_bio18_wc": {"mapname": "bio18_worldclim_10m", "mapset": "g_Meteorology_Fenoscandia", "description": "Summer precipitation (WorldClim)"},
        "v_bio19_wc": {"mapname": "bio19_worldclim_10m", "mapset": "g_Meteorology_Fenoscandia", "description": "Winter precipitation (WorldClim)"},
},
"snow_cover": {
        "v_snowmelt_doy": {"mapname": "GLS_Snow_Cover_average_melt_doy", "mapset": "g_Meteorology_Fenoscandia_SnowMelt_GLS", "description": "Average over last day of the year before 1.September with snow cover for at least 5 days in a row"},
        "v_snowstart_doy": {"mapname": "GLS_Snow_Cover_average_start_doy", "mapset": "g_Meteorology_Fenoscandia_SnowMelt_GLS", "description": "Average over first day of the year after 1.September with snow cover for at least 5 days in a row"},
        "v_snow_stability": {"mapname": "GLS_Snow_Cover_stability", "mapset": "g_Meteorology_Fenoscandia_SnowMelt_GLS", "description": "Average over first day of the year after 1.September with snow cover for at least 5 days in a row"},
        "v_snow_duration": {"mapname": "GLS_Snow_Cover_average_duration", "mapset": "g_Meteorology_Fenoscandia_SnowMelt_GLS", "description": "Average over first day of the year after 1.September with snow cover for at least 5 days in a row"},
        "v_snow_seasons_n": {"mapname": "GLS_Snow_Cover_seasons", "mapset": "g_Meteorology_Fenoscandia_SnowMelt_GLS", "description": ""},
},
"physical_limitations": {
        "v_slope": {"mapname": "", "mapset": "", "description": ""},
},
"human_influence": {
        "v_grazing": {"mapname": "", "mapset": "", "description": ""},
        "v_summer_farming": {"mapname": "", "mapset": "", "description": ""},
},
"spatial_effects":
        "v_x": {"mapname": "", "mapset": "", "description": ""},
        "v_y": {"mapname": "", "mapset": "", "description": ""},
}


############################
# For future scenarios
# {
# "v_bio01_wc_ghg26_2050": {"mapname": "future_ghg26_2050_bio01_worldclim_10m", "description": "2050 scenario of BIO01"},
# "v_bio02_wc_ghg26_2050": {"mapname": "future_ghg26_2050_bio02_worldclim_10m", "description": "2050 scenario of BIO02"},
# "v_bio10_wc_ghg26_2050": {"mapname": "future_ghg26_2050_bio10_worldclim_10m", "description": "2050 scenario of BIO10"},
# "v_bio11_wc_ghg26_2050": {"mapname": "future_ghg26_2050_bio11_worldclim_10m", "description": "2050 scenario of BIO11"},
# }

