/*NAME:    Queries for preparation of predictir maps

AUTHOR(S): Zofie Cimburova < zofie.cimburova AT nina.no>

PURPOSE:   Queries for preparation of predictir maps - sea distance.

*/

/*
To Dos:
*/

-----------------------------------------------------------
-- Queries used for preparation of explanatory variables --
-----------------------------------------------------------

-- SEA DISTANCE --
-- create bounding box    
CREATE TABLE zofie_cimburova.temp_box AS
SELECT ST_MakeEnvelope(st_xmin(ST_Extent(geom)), st_ymin(ST_Extent(geom)), st_xmax(ST_Extent(geom))+5*1e5, st_ymax(ST_Extent(geom)), 25833) AS geom
FROM (SELECT ST_Union(geom) AS geom
  	  FROM "AdministrativeUnits"."Fenoscandia_Country_polygon") AS scandinavia;
      
-- set srid 25833 to bounding box 
SELECT UpdateGeometrySRID('zofie_cimburova', 'temp_box', 'geom', 25833);
    
-- transform bounding box to 3035
ALTER TABLE zofie_cimburova.temp_box
 ALTER COLUMN geom TYPE geometry(Polygon,3035) 
  USING ST_Transform(ST_SetSRID(geom,25833), 3035);    
    
-- delete land from bounding box
CREATE TABLE zofie_cimburova.sea_nosefi AS
    SELECT ST_Difference(box.geom, ST_Union(ST_Buffer(land.geom, 0.0))) AS geom
    FROM zofie_cimburova.temp_box AS box,
    	 (SELECT * 
          FROM "Hydrography"."Europe_ECRINS_AggregationCatchments_NUTSX_LAEA" 
          WHERE "COUNTRY" = 'NO' OR "COUNTRY" = 'SE' OR "COUNTRY" = 'FI' OR "COUNTRY" = 'RU')AS land
    GROUP BY box.geom;

-- transform land to 25833
ALTER TABLE zofie_cimburova.sea_nosefi
 ALTER COLUMN geom TYPE geometry(MultiPolygon,25833) 
  USING ST_Transform(ST_SetSRID(geom,3035), 25833); 
  
-- split multipolygon to polygons
CREATE TABLE zofie_cimburova.sea_nosefi_singlepart AS
    SELECT (ST_Dump(geom)).geom AS geom
    FROM zofie_cimburova.sea_nosefi;

-- add column with area
ALTER TABLE zofie_cimburova.sea_nosefi_singlepart  
    ADD COLUMN area double precision;
    
UPDATE  zofie_cimburova.sea_nosefi_singlepart 
    SET area = ST_Area(geom);
    
-- only the largest polygon is sea, rest is trash
DELETE FROM zofie_cimburova.sea_nosefi_singlepart 
    WHERE area < (SELECT max(area) FROM zofie_cimburova.sea_nosefi_singlepart)

ALTER TABLE zofie_cimburova.sea_nosefi_singlepart
	ADD COLUMN gid SERIAL PRIMARY KEY;     
	
-- remove bounding box
DROP TABLE zofie_cimburova.temp_box;
 
    

    
    