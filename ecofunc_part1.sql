-- intersection when problems like "non-noded intersection" (in clip_sweden)
-- https://gis.stackexchange.com/questions/50399/how-best-to-fix-a-non-noded-intersection-problem-in-postgis
CREATE OR REPLACE FUNCTION "zofie_cimburova".safe_isect(geom_a geometry, geom_b geometry)
RETURNS geometry AS
$$
BEGIN
    RETURN ST_Intersection(geom_a, geom_b);
    EXCEPTION
        WHEN OTHERS THEN
            BEGIN
                RETURN ST_Intersection(ST_Buffer(geom_a, 0.0000001), ST_Buffer(geom_b, 0.0000001));
                EXCEPTION
                    WHEN OTHERS THEN
                        RETURN ST_GeomFromText('POLYGON EMPTY');
    END;
END
$$
LANGUAGE 'plpgsql' STABLE STRICT;

-- difference when problems like "non-noded intersection" (in clip_sweden)
CREATE OR REPLACE FUNCTION "zofie_cimburova".safe_diff(geom_a geometry, geom_b geometry)
RETURNS geometry AS
$$
BEGIN
    RETURN ST_Difference(geom_a, geom_b);
    EXCEPTION
        WHEN OTHERS THEN
            BEGIN
                RETURN ST_Difference(ST_Buffer(geom_a, 0.0000001), ST_Buffer(geom_b, 0.0000001));
                EXCEPTION
                    WHEN OTHERS THEN
                        RETURN ST_GeomFromText('POLYGON EMPTY');
    END;
END
$$
LANGUAGE 'plpgsql' STABLE STRICT;



------------------------------------------------------------
-- 1. add comlumns for standard land cover classes to Norway, Sweden, Finland datasets
------------------------------------------------------------

-- Finland
ALTER TABLE "Topography"."Finland_NLS_TopographicDatabase_Terrain_1_polygons" 
	ADD COLUMN "ID_l1" smallint,
	ADD COLUMN "ID_l2" smallint,
	ADD COLUMN "ID_l3" smallint;
	
ALTER TABLE "Topography"."Finland_NLS_TopographicDatabase_Terrain_2_polygons" 
	ADD COLUMN "ID_l1" smallint,
	ADD COLUMN "ID_l2" smallint,
	ADD COLUMN "ID_l3" smallint;

ALTER TABLE "Topography"."Finland_NLS_TopographicDatabase_DenselyBuiltAreas_polygons" 
	ADD COLUMN "ID_l1" smallint,
	ADD COLUMN "ID_l2" smallint,
	ADD COLUMN "ID_l3" smallint;

ALTER TABLE "Topography"."Finland_NLS_TopographicDatabase_Consctructions_polygons" 
	ADD COLUMN "ID_l1" smallint,
	ADD COLUMN "ID_l2" smallint,
	ADD COLUMN "ID_l3" smallint;	

-- Norway	
ALTER TABLE "Topography"."Norway_N50_ArealdekkeFlate" 
	ADD COLUMN "ID_l1" smallint,
	ADD COLUMN "ID_l2" smallint,
	ADD COLUMN "ID_l3" smallint;

-- Sweden
ALTER TABLE "Topography"."Sweden_Vagkartan_LandTypes_all_polygons" 
	ADD COLUMN "ID_l1" smallint,
	ADD COLUMN "ID_l2" smallint,
	ADD COLUMN "ID_l3" smallint;

------------------------------------------------------------
-- 2. import mapping tables
------------------------------------------------------------

-- importing csv with GUI
CREATE TABLE zofie_cimburova.map_sweden_vag
(
    "KKOD" smallint NOT NULL,
    "KATEGORI" text NOT NULL,
    "Translation" text,
    "ID_l1" smallint NOT NULL,
    "ID_l2" smallint,
    "ID_l3" smallint,
    PRIMARY KEY ("KKOD")
)
WITH (
    OIDS = FALSE
);

CREATE TABLE zofie_cimburova.map_norway
(
    "OBJTYPE" varchar NOT NULL,
    "ID_l1" smallint NOT NULL,
    "ID_l2" smallint,
    "ID_l3" smallint,
    PRIMARY KEY ("OBJTYPE")
)
WITH (
    OIDS = FALSE
);

CREATE TABLE zofie_cimburova.map_finland
(
    "objecttype" text NOT NULL,
	"LUOKKA" integer NOT NULL,
    "ID_l1" smallint NOT NULL,
    "ID_l2" smallint,
    "ID_l3" smallint,
    PRIMARY KEY ("LUOKKA")
)
WITH (
    OIDS = FALSE
);

	
	
------------------------------------------------------------
-- 3. update values of standard LC based on mapping tables
------------------------------------------------------------
-- Norway
UPDATE "Topography"."Norway_N50_ArealdekkeFlate"
SET "ID_l1" = "zofie_cimburova"."map_norway"."ID_l1",
  	"ID_l2" = "zofie_cimburova"."map_norway"."ID_l2",
  	"ID_l3" = "zofie_cimburova"."map_norway"."ID_l3"
FROM "zofie_cimburova"."map_norway"
WHERE "Topography"."Norway_N50_ArealdekkeFlate"."OBJTYPE" = "zofie_cimburova"."map_norway"."OBJTYPE";

--Sweden vagkartan
UPDATE "Topography"."Sweden_Vagkartan_LandTypes_all_polygons"
SET "ID_l1" = "zofie_cimburova"."map_sweden_vag"."ID_l1",
  	"ID_l2" = "zofie_cimburova"."map_sweden_vag"."ID_l2",
  	"ID_l3" = "zofie_cimburova"."map_sweden_vag"."ID_l3"
FROM "zofie_cimburova"."map_sweden_vag"
WHERE "Topography"."Sweden_Fastighetskartan_LandTypes_all_polygons"."KKOD" = "zofie_cimburova"."map_sweden_vag"."KKOD";

-- Finland
UPDATE "Topography"."Finland_NLS_TopographicDatabase_Terrain_1_polygons"
SET "ID_l1" = "zofie_cimburova"."map_finland"."ID_l1",
  	"ID_l2" = "zofie_cimburova"."map_finland"."ID_l2",
  	"ID_l3" = "zofie_cimburova"."map_finland"."ID_l3"
FROM "zofie_cimburova"."map_finland"
WHERE "Topography"."Finland_NLS_TopographicDatabase_Terrain_1_polygons"."LUOKKA" = "zofie_cimburova"."map_finland"."LUOKKA";

UPDATE "Topography"."Finland_NLS_TopographicDatabase_Terrain_2_polygons"
SET "ID_l1" = "zofie_cimburova"."map_finland"."ID_l1",
  	"ID_l2" = "zofie_cimburova"."map_finland"."ID_l2",
  	"ID_l3" = "zofie_cimburova"."map_finland"."ID_l3"
FROM "zofie_cimburova"."map_finland"
WHERE "Topography"."Finland_NLS_TopographicDatabase_Terrain_2_polygons"."LUOKKA" = "zofie_cimburova"."map_finland"."LUOKKA";

UPDATE "Topography"."Finland_NLS_TopographicDatabase_DenselyBuiltAreas_polygons"
SET "ID_l1" = "zofie_cimburova"."map_finland"."ID_l1",
  	"ID_l2" = "zofie_cimburova"."map_finland"."ID_l2",
  	"ID_l3" = "zofie_cimburova"."map_finland"."ID_l3"
FROM "zofie_cimburova"."map_finland"
WHERE "Topography"."Finland_NLS_TopographicDatabase_DenselyBuiltAreas_polygons"."LUOKKA" = "zofie_cimburova"."map_finland"."LUOKKA";

UPDATE "Topography"."Finland_NLS_TopographicDatabase_Consctructions_polygons"
SET "ID_l1" = "zofie_cimburova"."map_finland"."ID_l1",
  	"ID_l2" = "zofie_cimburova"."map_finland"."ID_l2",
  	"ID_l3" = "zofie_cimburova"."map_finland"."ID_l3"
FROM "zofie_cimburova"."map_finland"
WHERE "Topography"."Finland_NLS_TopographicDatabase_Consctructions_polygons"."LUOKKA" = "zofie_cimburova"."map_finland"."LUOKKA";


------------------------------------------------------------
-- 4. check geometries
------------------------------------------------------------

-- Sweden: check validity of polygon geometries (ring self-intersections) 
SELECT gid, ST_isvalid(geom) AS val 
	FROM "Topography"."Sweden_Vagkartan_LandTypes_all_polygons"
    WHERE ST_isvalid(geom) = false
    
-- Sweden: repair geometry
CREATE TABLE "zofie_cimburova"."valid_sweden" AS
SELECT ST_Buffer(geom,0.0) AS geom, gid, "ID_l1", "ID_l2", "ID_l3"  
	FROM "Topography"."Sweden_Vagkartan_LandTypes_all_polygons";

-- Norway: check validity of polygon geometries (ring self-intersections)
SELECT gid, ST_isvalid(geom) AS val 
	FROM "Topography"."Norway_N50_ArealdekkeFlate"
    WHERE ST_isvalid(geom) = false
    
-- Norway: repair geometry
CREATE TABLE "zofie_cimburova"."valid_norway" AS
SELECT ST_Buffer(geom,0.0) AS geom, gid, "ID_l1", "ID_l2", "ID_l3"  
	FROM "Topography"."Norway_N50_ArealdekkeFlate";

-- Finland: check validity of polygon geometries (self-intersections)
SELECT gid, ST_isvalid(geom) AS val 
	FROM "Topography"."Finland_NLS_TopographicDatabase_Terrain_1_polygons"
    WHERE ST_isvalid(geom) = false

SELECT gid, ST_isvalid(geom) AS val 
	FROM "Topography"."Finland_NLS_TopographicDatabase_Terrain_2_polygons"
    WHERE ST_isvalid(geom) = false

SELECT gid, ST_isvalid(geom) AS val 
	FROM "Topography"."Finland_NLS_TopographicDatabase_DenselyBuiltAreas_polygons"
    WHERE ST_isvalid(geom) = false
	
SELECT gid, ST_isvalid(geom) AS val 
	FROM "Topography"." Finland_NLS_TopographicDatabase_Consctructions_polygons"
    WHERE ST_isvalid(geom) = false
	
-- Finland: repair geometry
CREATE TABLE "zofie_cimburova"."valid_finland_terr1" AS
SELECT ST_MakeValid(geom) AS geom, gid, "ID_l1", "ID_l2", "ID_l3"  
	FROM "Topography"."Finland_NLS_TopographicDatabase_Terrain_1_polygons";

CREATE TABLE "zofie_cimburova"."valid_finland_terr2" AS
SELECT ST_MakeValid(geom) AS geom, gid, "ID_l1", "ID_l2", "ID_l3"  
	FROM "Topography"."Finland_NLS_TopographicDatabase_Terrain_2_polygons";
	
CREATE TABLE "zofie_cimburova"."valid_finland_dense" AS
SELECT ST_MakeValid(geom) AS geom, gid, "ID_l1", "ID_l2", "ID_l3"  
	FROM "Topography"."Finland_NLS_TopographicDatabase_DenselyBuiltAreas_polygons";
	
CREATE TABLE "zofie_cimburova"."valid_finland_buildings" AS
SELECT ST_MakeValid(geom) AS geom, gid, "ID_l1", "ID_l2", "ID_l3"  
	FROM "Topography"."Finland_NLS_TopographicDatabase_Consctructions_polygons";
	
------------------------------------------------------------
-- 5. create indices
------------------------------------------------------------
-- Norway
CREATE INDEX valid_norway_gix ON "zofie_cimburova"."valid_norway" USING GIST (geom);
VACUUM ANALYZE "zofie_cimburova"."valid_norway";	

-- Sweden
CREATE INDEX valid_sweden_gix ON "zofie_cimburova"."valid_sweden" USING GIST (geom);
VACUUM ANALYZE "zofie_cimburova"."valid_sweden";

-- Finland
CREATE INDEX valid_finland_buildings_gix ON "zofie_cimburova"."valid_finland_buildings" USING GIST (geom);
CREATE INDEX valid_finland_dense_gix ON "zofie_cimburova"."valid_finland_dense" USING GIST (geom);
CREATE INDEX valid_finland_terr1_gix ON "zofie_cimburova"."valid_finland_terr1" USING GIST (geom);
CREATE INDEX valid_finland_terr2_gix ON "zofie_cimburova"."valid_finland_terr2" USING GIST (geom);

VACUUM ANALYZE "zofie_cimburova"."valid_finland_buildings";	
VACUUM ANALYZE "zofie_cimburova"."valid_finland_dense";	
VACUUM ANALYZE "zofie_cimburova"."valid_finland_terr1";	
VACUUM ANALYZE "zofie_cimburova"."valid_finland_terr2";	
	
------------------------------------------------------------
-- 6. create forest in Finland
------------------------------------------------------------
-- created table of grid UTM 25LR
CREATE INDEX finland_grid_UTM_25LR_poly_gix ON "zofie_cimburova"."finland_grid_UTM_25LR_polygon" USING GIST (geom);
VACUUM ANALYZE "zofie_cimburova"."finland_grid_UTM_25LR_polygon";	

-- subtract densely built areas - 16 sec
CREATE TABLE "zofie_cimburova"."finland_diff_dense" AS (    
SELECT  tile.lehtitunnu,     
        COALESCE(
            ST_Difference(tile.geom, ST_Union(LC.geom)), 
            tile.geom
        ) AS geom 
FROM "zofie_cimburova"."finland_grid_UTM_25LR_polygon" AS tile 
LEFT JOIN "zofie_cimburova"."valid_finland_dense" AS LC 
	ON tile.geom && LC.geom
GROUP BY tile.lehtitunnu, tile.geom);

-- subtract terrain 2 - 4 min
CREATE TABLE "zofie_cimburova"."finland_diff_terr2" AS (    
SELECT  tile.lehtitunnu,     
        COALESCE(
            ST_Difference(tile.geom, ST_Union(LC.geom)), 
            tile.geom
        ) AS geom 
FROM "zofie_cimburova"."finland_diff_dense" AS tile 
LEFT JOIN "zofie_cimburova"."valid_finland_terr2" AS LC 
	ON tile.geom && LC.geom
GROUP BY tile.lehtitunnu, tile.geom);

-- subtract terrain 1 - more than 8 hours
CREATE TABLE "zofie_cimburova"."finland_diff_terr1" AS (    
SELECT  tile.lehtitunnu,     
        COALESCE(
            ST_Difference(tile.geom, ST_Union(LC.geom)), 
            tile.geom
        ) AS geom 
FROM "zofie_cimburova"."finland_diff_terr2" AS tile 
LEFT JOIN "zofie_cimburova"."valid_finland_terr1" AS LC 
	ON tile.geom && LC.geom
GROUP BY tile.lehtitunnu, tile.geom);

-- exclude polygons with zero area
CREATE TABLE "zofie_cimburova"."finland_diff_terr1_repaired" AS (
SELECT *
	FROM "zofie_cimburova"."finland_diff_terr1"
	WHERE ST_Area(geom) > 0)
	
-- subtract buildings - more than 24 hours
CREATE TABLE "zofie_cimburova"."valid_finland" AS (    
SELECT  tile.lehtitunnu,     
        COALESCE(
            ST_Difference(tile.geom, ST_Union(LC.geom)), 
            tile.geom
        ) AS geom 
FROM "zofie_cimburova"."finland_diff_terr1_repaired" AS tile 
LEFT JOIN "zofie_cimburova"."valid_finland_buildings" AS LC 
	ON tile.geom && LC.geom
GROUP BY tile.lehtitunnu, tile.geom);


------------------------------------------------------------
-- 7. add missing tiles
------------------------------------------------------------
-- add comlumns for standard land cover classes
ALTER TABLE "zofie_cimburova"."missing_fi_build_M3443L" 
	ADD COLUMN "ID_l1" smallint,
	ADD COLUMN "ID_l2" smallint,
	ADD COLUMN "ID_l3" smallint;
	
ALTER TABLE "zofie_cimburova"."missing_fi_build_X5213L" 
	ADD COLUMN "ID_l1" smallint,
	ADD COLUMN "ID_l2" smallint,
	ADD COLUMN "ID_l3" smallint;
	
ALTER TABLE "zofie_cimburova"."missing_fi_build_X5213R" 
	ADD COLUMN "ID_l1" smallint,
	ADD COLUMN "ID_l2" smallint,
	ADD COLUMN "ID_l3" smallint;	
	
ALTER TABLE "zofie_cimburova"."missing_fi_dense_M3443L" 
	ADD COLUMN "ID_l1" smallint,
	ADD COLUMN "ID_l2" smallint,
	ADD COLUMN "ID_l3" smallint;	
	
ALTER TABLE "zofie_cimburova"."missing_fi_terr1_M3443L" 
	ADD COLUMN "ID_l1" smallint,
	ADD COLUMN "ID_l2" smallint,
	ADD COLUMN "ID_l3" smallint;
	
ALTER TABLE "zofie_cimburova"."missing_fi_terr1_X5213L" 
	ADD COLUMN "ID_l1" smallint,
	ADD COLUMN "ID_l2" smallint,
	ADD COLUMN "ID_l3" smallint;
	
ALTER TABLE "zofie_cimburova"."missing_fi_terr1_X5213R" 
	ADD COLUMN "ID_l1" smallint,
	ADD COLUMN "ID_l2" smallint,
	ADD COLUMN "ID_l3" smallint;
	
ALTER TABLE "zofie_cimburova"."missing_fi_terr2_M3443L" 
	ADD COLUMN "ID_l1" smallint,
	ADD COLUMN "ID_l2" smallint,
	ADD COLUMN "ID_l3" smallint;
	
ALTER TABLE "zofie_cimburova"."missing_fi_terr2_X5213L" 
	ADD COLUMN "ID_l1" smallint,
	ADD COLUMN "ID_l2" smallint,
	ADD COLUMN "ID_l3" smallint;
	
ALTER TABLE "zofie_cimburova"."missing_fi_terr2_X5213R" 
	ADD COLUMN "ID_l1" smallint,
	ADD COLUMN "ID_l2" smallint,
	ADD COLUMN "ID_l3" smallint;
	
-- merge with original datasets
-- check geometry - everything ok
SELECT gid, ST_isvalid(geom) AS val 
	FROM "zofie_cimburova"."missing_fi_build_M3443L"
    WHERE ST_isvalid(geom) = false;

SELECT gid, ST_isvalid(geom) AS val 
	FROM "zofie_cimburova"."missing_fi_build_X5213L"
    WHERE ST_isvalid(geom) = false;
	
SELECT gid, ST_isvalid(geom) AS val 
	FROM "zofie_cimburova"."missing_fi_build_X5213R"
    WHERE ST_isvalid(geom) = false;
	
SELECT gid, ST_isvalid(geom) AS val 
	FROM "zofie_cimburova"."missing_fi_dense_M3443L"
    WHERE ST_isvalid(geom) = false;
	
SELECT gid, ST_isvalid(geom) AS val 
	FROM "zofie_cimburova"."missing_fi_terr1_M3443L"
    WHERE ST_isvalid(geom) = false;
	
SELECT gid, ST_isvalid(geom) AS val 
	FROM "zofie_cimburova"."missing_fi_terr1_X5213L"
    WHERE ST_isvalid(geom) = false;
	
SELECT gid, ST_isvalid(geom) AS val 
	FROM "zofie_cimburova"."missing_fi_terr1_X5213R"
    WHERE ST_isvalid(geom) = false;
	
SELECT gid, ST_isvalid(geom) AS val 
	FROM "zofie_cimburova"."missing_fi_terr2_M3443L"
    WHERE ST_isvalid(geom) = false;
	
SELECT gid, ST_isvalid(geom) AS val 
	FROM "zofie_cimburova"."missing_fi_terr2_X5213L"
    WHERE ST_isvalid(geom) = false;
	
SELECT gid, ST_isvalid(geom) AS val 
	FROM "zofie_cimburova"."missing_fi_terr2_X5213R"
    WHERE ST_isvalid(geom) = false;

-- update gid's so that they are different from gid's in table
CREATE SEQUENCE "serial_fi_build";
SELECT nextval('serial_fi_build');
SELECT setval('serial_fi_build', (SELECT MAX(gid) + 1 FROM "zofie_cimburova"."valid_finland_buildings"));

UPDATE "zofie_cimburova"."missing_fi_build_M3443L"
	SET gid = nextval('serial_fi_build');
UPDATE "zofie_cimburova"."missing_fi_build_X5213L"
	SET gid = nextval('serial_fi_build');
UPDATE "zofie_cimburova"."missing_fi_build_X5213R"
	SET gid = nextval('serial_fi_build');
	
CREATE SEQUENCE "serial_fi_terr1";
SELECT setval('serial_fi_terr1', (SELECT MAX(gid) + 1 FROM "zofie_cimburova"."valid_finland_terr1"));

UPDATE "zofie_cimburova"."missing_fi_terr1_M3443L"
	SET gid = nextval('serial_fi_terr1');
UPDATE "zofie_cimburova"."missing_fi_terr1_X5213L"
	SET gid = nextval('serial_fi_terr1');
UPDATE "zofie_cimburova"."missing_fi_terr1_X5213R"
	SET gid = nextval('serial_fi_terr1');
	
CREATE SEQUENCE "serial_fi_terr2";
SELECT setval('serial_fi_terr2', (SELECT MAX(gid) + 1 FROM "zofie_cimburova"."valid_finland_terr2"));

UPDATE "zofie_cimburova"."missing_fi_terr2_M3443L"
	SET gid = nextval('serial_fi_terr2');
UPDATE "zofie_cimburova"."missing_fi_terr2_X5213L"
	SET gid = nextval('serial_fi_terr2');
UPDATE "zofie_cimburova"."missing_fi_terr2_X5213R"
	SET gid = nextval('serial_fi_terr2');
	
CREATE SEQUENCE "serial_fi_dense";
SELECT setval('serial_fi_dense', (SELECT MAX(gid) + 1 FROM "zofie_cimburova"."valid_finland_dense"));

UPDATE "zofie_cimburova"."missing_fi_dense_M3443L"
	SET gid = nextval('serial_fi_dense');

-- insert new entries to tables
INSERT INTO "zofie_cimburova"."valid_finland_dense"
	SELECT geom, gid, "ID_l1", "ID_l2", "ID_l3" 
    FROM "zofie_cimburova"."missing_fi_dense_M3443L";
	
INSERT INTO "zofie_cimburova"."valid_finland_buildings"
	SELECT geom, gid, "ID_l1", "ID_l2", "ID_l3" 
    FROM "zofie_cimburova"."missing_fi_build_M3443L";
    
INSERT INTO "zofie_cimburova"."valid_finland_buildings"
	SELECT geom, gid, "ID_l1", "ID_l2", "ID_l3" 
    FROM "zofie_cimburova"."missing_fi_build_X5213L";
    
INSERT INTO "zofie_cimburova"."valid_finland_buildings"
	SELECT geom, gid, "ID_l1", "ID_l2", "ID_l3" 
    FROM "zofie_cimburova"."missing_fi_build_X5213R";
	
INSERT INTO "zofie_cimburova"."valid_finland_terr1"
	SELECT geom, gid, "ID_l1", "ID_l2", "ID_l3" 
    FROM "zofie_cimburova"."missing_fi_terr1_M3443L";
    
INSERT INTO "zofie_cimburova"."valid_finland_terr1"
	SELECT geom, gid, "ID_l1", "ID_l2", "ID_l3" 
    FROM "zofie_cimburova"."missing_fi_terr1_X5213L";
    
INSERT INTO "zofie_cimburova"."valid_finland_terr1"
	SELECT geom, gid, "ID_l1", "ID_l2", "ID_l3" 
    FROM "zofie_cimburova"."missing_fi_terr1_X5213R";
	
INSERT INTO "zofie_cimburova"."valid_finland_terr2"
	SELECT geom, gid, "ID_l1", "ID_l2", "ID_l3" 
    FROM "zofie_cimburova"."missing_fi_terr2_M3443L";
    
INSERT INTO "zofie_cimburova"."valid_finland_terr2"
	SELECT geom, gid, "ID_l1", "ID_l2", "ID_l3" 
    FROM "zofie_cimburova"."missing_fi_terr2_X5213L";
    
INSERT INTO "zofie_cimburova"."valid_finland_terr2"
	SELECT geom, gid, "ID_l1", "ID_l2", "ID_l3" 
    FROM "zofie_cimburova"."missing_fi_terr2_X5213R";

-- extract forest
-- subtract densely built areas
CREATE TABLE "zofie_cimburova"."missing_finland_diff_dense" AS (    
SELECT  tile.lehtitunnu,     
        COALESCE(
            ST_Difference(tile.geom, ST_Union(LC.geom)), 
            tile.geom
        ) AS geom 
FROM "zofie_cimburova"."finland_grid_UTM_25LR_polygon" AS tile 
LEFT JOIN "zofie_cimburova"."valid_finland_dense" AS LC 
	ON tile.geom && LC.geom
WHERE tile.lehtitunnu IN ('M3443L', 'X5213L', 'X5213R')
GROUP BY tile.lehtitunnu, tile.geom);

-- subtract terrain 2
CREATE TABLE "zofie_cimburova"."missing_finland_diff_terr2" AS (    
SELECT  tile.lehtitunnu,     
        COALESCE(
            ST_Difference(tile.geom, ST_Union(LC.geom)), 
            tile.geom
        ) AS geom 
FROM "zofie_cimburova"."finland_grid_UTM_25LR_polygon" AS tile 
LEFT JOIN "zofie_cimburova"."valid_finland_terr2" AS LC 
	ON tile.geom && LC.geom
WHERE tile.lehtitunnu IN ('M3443L', 'X5213L', 'X5213R')
GROUP BY tile.lehtitunnu, tile.geom);

-- subtract terrain 1 - 11 sec
CREATE TABLE "zofie_cimburova"."missing_finland_diff_terr1" AS (    
SELECT  tile.lehtitunnu,     
        COALESCE(
            ST_Difference(tile.geom, ST_Union(LC.geom)), 
            tile.geom
        ) AS geom 
FROM "zofie_cimburova"."missing_finland_diff_terr2" AS tile 
LEFT JOIN "zofie_cimburova"."valid_finland_terr1" AS LC 
	ON tile.geom && LC.geom
WHERE tile.lehtitunnu IN ('M3443L', 'X5213L', 'X5213R')
GROUP BY tile.lehtitunnu, tile.geom);

-- exclude polygons with zero area
CREATE TABLE "zofie_cimburova"."missing_finland_diff_terr1_repaired" AS (
SELECT *
	FROM "zofie_cimburova"."missing_finland_diff_terr1"
	WHERE ST_Area(geom) > 0)
	
-- subtract buildings - 48 sec
CREATE TABLE "zofie_cimburova"."missing_valid_finland" AS (    
SELECT  tile.lehtitunnu,     
        COALESCE(
            ST_Difference(tile.geom, ST_Union(LC.geom)), 
            tile.geom
        ) AS geom 
FROM "zofie_cimburova"."missing_finland_diff_terr1_repaired" AS tile 
LEFT JOIN "zofie_cimburova"."valid_finland_buildings" AS LC 
	ON tile.geom && LC.geom
WHERE tile.lehtitunnu IN ('M3443L', 'X5213L', 'X5213R')
GROUP BY tile.lehtitunnu, tile.geom);

-- add missing tiles to forest dataset
DELETE FROM "zofie_cimburova"."valid_finland" AS forest
    WHERE forest.lehtitunnu IN ('M3443L', 'X5213L', 'X5213R');
	
INSERT INTO "zofie_cimburova"."valid_finland"
	SELECT lehtitunnu, geom
    FROM "zofie_cimburova"."missing_valid_finland";
	
	

------------------------------------------------------------
-- 8. repair border-exceedings - clip
------------------------------------------------------------	
-- Sweden: - 7 min
CREATE TABLE "zofie_cimburova"."clip_sweden" AS (    
	SELECT LC.gid AS orig_gid, "ID_l1", "ID_l2", "ID_l3", ST_Intersection(LC.geom, sweden.geom) AS geom
	FROM "zofie_cimburova"."valid_sweden" AS LC, 
    	(SELECT * 
   		 FROM "AdministrativeUnits"."Fenoscandia_Country_polygon" 
    	 WHERE "countryCode" = 'SE') AS sweden
	WHERE NOT ST_Contains(sweden.geom, LC.geom) AND    	  
    	  ST_Intersects(sweden.geom, LC.geom));
    
-- 5 min
INSERT INTO "zofie_cimburova"."clip_sweden"
	SELECT LC.gid, "ID_l1", "ID_l2", "ID_l3", LC.geom
    FROM "zofie_cimburova"."valid_sweden" AS LC,
    	(SELECT * 
   		 FROM "AdministrativeUnits"."Fenoscandia_Country_polygon" 
    	 WHERE "countryCode" = 'SE') AS sweden
    WHERE ST_Contains(sweden.geom, LC.geom);

ALTER TABLE "zofie_cimburova"."clip_sweden" 
	ADD COLUMN gid SERIAL PRIMARY KEY;
	
CREATE INDEX clip_sweden_gix ON "zofie_cimburova"."clip_sweden" USING GIST (geom);
VACUUM ANALYZE "zofie_cimburova"."clip_sweden";	 
	
UPDATE "zofie_cimburova"."clip_sweden"
SET geom = ST_CollectionExtract(geom, 3)
WHERE ST_GeometryType(geom) = 'ST_GeometryCollection';	
	
-- Norway: - 9 min
CREATE TABLE "zofie_cimburova"."clip_norway" AS (    
	SELECT LC.gid AS orig_gid, "ID_l1", "ID_l2", "ID_l3", ST_Intersection(LC.geom, norway.geom) AS geom
	FROM "zofie_cimburova"."valid_norway" AS LC, 
    	(SELECT * 
   		 FROM "AdministrativeUnits"."Fenoscandia_Country_polygon" 
    	 WHERE "countryCode" = 'NO') AS norway
	WHERE NOT ST_Contains(norway.geom, LC.geom) AND    	  
    	  ST_Intersects(norway.geom, LC.geom));
    
-- 42 min
INSERT INTO "zofie_cimburova"."clip_norway"
	SELECT LC.gid, "ID_l1", "ID_l2", "ID_l3", LC.geom
    FROM "zofie_cimburova"."valid_norway" AS LC,
    	(SELECT * 
   		 FROM "AdministrativeUnits"."Fenoscandia_Country_polygon" 
    	 WHERE "countryCode" = 'NO') AS norway
    WHERE ST_Contains(norway.geom, LC.geom);

ALTER TABLE "zofie_cimburova"."clip_norway" 
	ADD COLUMN gid SERIAL PRIMARY KEY;

CREATE INDEX clip_norway_gix ON "zofie_cimburova"."clip_norway" USING GIST (geom);
VACUUM ANALYZE "zofie_cimburova"."clip_norway";	 

-- convert one feature of type geometry collection to polygon
UPDATE "zofie_cimburova"."clip_norway"
SET geom = ST_CollectionExtract(geom, 3)
WHERE ST_GeometryType(geom) = 'ST_GeometryCollection';

-- Clip Finland Terrain 1 - 25 min
CREATE TABLE "zofie_cimburova"."clip_finland_terr1" AS (    
	SELECT LC.gid AS orig_gid, "ID_l1", "ID_l2", "ID_l3", ST_Intersection(LC.geom, finland.geom) AS geom
	FROM "zofie_cimburova"."valid_finland_terr1" AS LC, 
    	(SELECT * 
   		 FROM "AdministrativeUnits"."Fenoscandia_Country_polygon" 
    	 WHERE "countryCode" = 'FI') AS finland
	WHERE NOT ST_Contains(finland.geom, LC.geom) AND    	  
    	  ST_Intersects(finland.geom, LC.geom));
    

INSERT INTO "zofie_cimburova"."clip_finland_terr1"
	SELECT LC.gid, "ID_l1", "ID_l2", "ID_l3", LC.geom
    FROM "zofie_cimburova"."valid_finland_terr1" AS LC,
    	(SELECT * 
   		 FROM "AdministrativeUnits"."Fenoscandia_Country_polygon" 
    	 WHERE "countryCode" = 'FI') AS finland
    WHERE ST_Contains(finland.geom, LC.geom);

ALTER TABLE "zofie_cimburova"."clip_finland_terr1" 
	ADD COLUMN gid SERIAL PRIMARY KEY;	
	

-- Clip Finland Terrain 2 
CREATE TABLE "zofie_cimburova"."clip_finland_terr2" AS (    
	SELECT LC.gid AS orig_gid, "ID_l1", "ID_l2", "ID_l3", ST_Intersection(LC.geom, finland.geom) AS geom
	FROM "zofie_cimburova"."valid_finland_terr2" AS LC, 
    	(SELECT * 
   		 FROM "AdministrativeUnits"."Fenoscandia_Country_polygon" 
    	 WHERE "countryCode" = 'FI') AS finland
	WHERE NOT ST_Contains(finland.geom, LC.geom) AND    	  
    	  ST_Intersects(finland.geom, LC.geom));
    

INSERT INTO "zofie_cimburova"."clip_finland_terr2"
	SELECT LC.gid, "ID_l1", "ID_l2", "ID_l3", LC.geom
    FROM "zofie_cimburova"."valid_finland_terr2" AS LC,
    	(SELECT * 
   		 FROM "AdministrativeUnits"."Fenoscandia_Country_polygon" 
    	 WHERE "countryCode" = 'FI') AS finland
    WHERE ST_Contains(finland.geom, LC.geom);

ALTER TABLE "zofie_cimburova"."clip_finland_terr2" 
	ADD COLUMN gid SERIAL PRIMARY KEY;	
	
UPDATE "zofie_cimburova"."clip_finland_terr2"
	SET geom = ST_CollectionExtract(geom, 3)
	WHERE ST_GeometryType(geom) = 'ST_GeometryCollection';
	
-- clip Finland buildings
UPDATE "zofie_cimburova"."valid_finland_buildings"
SET geom = ST_CollectionExtract(geom, 3)
WHERE ST_GeometryType(geom) = 'ST_GeometryCollection';

CREATE TABLE "zofie_cimburova"."clip_finland_buildings" AS (    
	SELECT LC.gid AS orig_gid, "ID_l1", "ID_l2", "ID_l3", ST_Intersection(LC.geom, finland.geom) AS geom
	FROM "zofie_cimburova"."valid_finland_buildings" AS LC, 
    	(SELECT * 
   		 FROM "AdministrativeUnits"."Fenoscandia_Country_polygon" 
    	 WHERE "countryCode" = 'FI') AS finland
	WHERE NOT ST_Contains(finland.geom, LC.geom) AND    	  
    	  ST_Intersects(finland.geom, LC.geom));
    
INSERT INTO "zofie_cimburova"."clip_finland_buildings"
	SELECT LC.gid, "ID_l1", "ID_l2", "ID_l3", LC.geom
    FROM "zofie_cimburova"."valid_finland_buildings" AS LC,
    	(SELECT * 
   		 FROM "AdministrativeUnits"."Fenoscandia_Country_polygon" 
    	 WHERE "countryCode" = 'FI') AS finland
    WHERE ST_Contains(finland.geom, LC.geom);
    
ALTER TABLE "zofie_cimburova"."clip_finland_buildings" 
	ADD COLUMN gid SERIAL PRIMARY KEY;	
    
-- clip Finland densely built areas
CREATE TABLE "zofie_cimburova"."clip_finland_dense" AS (    
	SELECT LC.gid AS orig_gid, "ID_l1", "ID_l2", "ID_l3", ST_Intersection(LC.geom, finland.geom) AS geom
	FROM "zofie_cimburova"."valid_finland_dense" AS LC, 
    	(SELECT * 
   		 FROM "AdministrativeUnits"."Fenoscandia_Country_polygon" 
    	 WHERE "countryCode" = 'FI') AS finland
	WHERE NOT ST_Contains(finland.geom, LC.geom) AND    	  
    	  ST_Intersects(finland.geom, LC.geom));
    
INSERT INTO "zofie_cimburova"."clip_finland_dense"
	SELECT LC.gid, "ID_l1", "ID_l2", "ID_l3", LC.geom
    FROM "zofie_cimburova"."valid_finland_dense" AS LC,
    	(SELECT * 
   		 FROM "AdministrativeUnits"."Fenoscandia_Country_polygon" 
    	 WHERE "countryCode" = 'FI') AS finland
    WHERE ST_Contains(finland.geom, LC.geom);
    
ALTER TABLE "zofie_cimburova"."clip_finland_dense" 
	ADD COLUMN gid SERIAL PRIMARY KEY;	
    
-- clip Finland forest
CREATE TABLE "zofie_cimburova"."clip_finland_forest" AS (    
	SELECT LC.gid AS orig_gid, "ID_l1", "ID_l2", "ID_l3", ST_Intersection(LC.geom, finland.geom) AS geom
	FROM "zofie_cimburova"."valid_finland" AS LC, 
    	(SELECT * 
   		 FROM "AdministrativeUnits"."Fenoscandia_Country_polygon" 
    	 WHERE "countryCode" = 'FI') AS finland
	WHERE NOT ST_Contains(finland.geom, LC.geom) AND    	  
    	  ST_Intersects(finland.geom, LC.geom));
    
INSERT INTO "zofie_cimburova"."clip_finland_forest"
	SELECT LC.gid, "ID_l1", "ID_l2", "ID_l3", LC.geom
    FROM "zofie_cimburova"."valid_finland" AS LC,
    	(SELECT * 
   		 FROM "AdministrativeUnits"."Fenoscandia_Country_polygon" 
    	 WHERE "countryCode" = 'FI') AS finland
    WHERE ST_Contains(finland.geom, LC.geom);
    
ALTER TABLE "zofie_cimburova"."clip_finland_forest" 
	ADD COLUMN gid SERIAL PRIMARY KEY;	
	
UPDATE "zofie_cimburova"."clip_finland_forest"
SET geom = ST_CollectionExtract(geom, 3)
WHERE ST_GeometryType(geom) = 'ST_GeometryCollection';
	
	
	
------------------------------------------------------------
-- 9. update values of land covers levels 2 and 3
------------------------------------------------------------	
-- Sweden
UPDATE "zofie_cimburova"."valid_sweden"
SET "ID_l2" = "ID_l1" * 100
WHERE "ID_l2" IS NULL

UPDATE "zofie_cimburova"."valid_sweden"
SET "ID_l3" = "ID_l2" * 10
WHERE "ID_l3" IS NULL;

UPDATE "zofie_cimburova"."clip_sweden"
SET "ID_l2" = "ID_l1" * 100
WHERE "ID_l2" IS NULL

UPDATE "zofie_cimburova"."clip_sweden"
SET "ID_l3" = "ID_l2" * 10
WHERE "ID_l3" IS NULL;


-- Norway 
UPDATE "zofie_cimburova"."clip_norway"
SET "ID_l2" = "ID_l1" * 100
WHERE "ID_l2" IS NULL

UPDATE "zofie_cimburova"."clip_norway"
SET "ID_l3" = "ID_l2" * 10
WHERE "ID_l3" IS NULL;

UPDATE "zofie_cimburova"."valid_norway"
SET "ID_l2" = "ID_l1" * 100
WHERE "ID_l2" IS NULL

UPDATE "zofie_cimburova"."valid_norway"
SET "ID_l3" = "ID_l2" * 10
WHERE "ID_l3" IS NULL;

-- Finland buildings  
UPDATE "zofie_cimburova"."clip_finland_buildings"
SET "ID_l2" = "ID_l1" * 100
WHERE "ID_l2" IS NULL;

UPDATE "zofie_cimburova"."clip_finland_buildings"
SET "ID_l3" = "ID_l2" * 10
WHERE "ID_l3" IS NULL;

UPDATE "zofie_cimburova"."valid_finland_buildings"
SET "ID_l2" = "ID_l1" * 100
WHERE "ID_l2" IS NULL;

UPDATE "zofie_cimburova"."valid_finland_buildings"
SET "ID_l3" = "ID_l2" * 10
WHERE "ID_l3" IS NULL;  

-- Finland dense
UPDATE "zofie_cimburova"."clip_finland_dense"
SET "ID_l2" = "ID_l1" * 100
WHERE "ID_l2" IS NULL;

UPDATE "zofie_cimburova"."clip_finland_dense"
SET "ID_l3" = "ID_l2" * 10
WHERE "ID_l3" IS NULL;

UPDATE "zofie_cimburova"."valid_finland_dense"
SET "ID_l2" = "ID_l1" * 100
WHERE "ID_l2" IS NULL;

UPDATE "zofie_cimburova"."valid_finland_dense"
SET "ID_l3" = "ID_l2" * 10
WHERE "ID_l3" IS NULL;  

-- Finland terr1
UPDATE "zofie_cimburova"."clip_finland_terr1"
SET "ID_l2" = "ID_l1" * 100
WHERE "ID_l2" IS NULL;

UPDATE "zofie_cimburova"."clip_finland_terr1"
SET "ID_l3" = "ID_l2" * 10
WHERE "ID_l3" IS NULL;

UPDATE "zofie_cimburova"."valid_finland_terr1"
SET "ID_l2" = "ID_l1" * 100
WHERE "ID_l2" IS NULL;

UPDATE "zofie_cimburova"."valid_finland_terr1"
SET "ID_l3" = "ID_l2" * 10
WHERE "ID_l3" IS NULL;  

-- Finland terr2
UPDATE "zofie_cimburova"."clip_finland_terr2"
SET "ID_l2" = "ID_l1" * 100
WHERE "ID_l2" IS NULL;

UPDATE "zofie_cimburova"."clip_finland_terr2"
SET "ID_l3" = "ID_l2" * 10
WHERE "ID_l3" IS NULL;

UPDATE "zofie_cimburova"."valid_finland_terr2"
SET "ID_l2" = "ID_l1" * 100
WHERE "ID_l2" IS NULL;

UPDATE "zofie_cimburova"."valid_finland_terr2"
SET "ID_l3" = "ID_l2" * 10
WHERE "ID_l3" IS NULL;  


------------------------------------------------------------
-- 10. repair gaps
------------------------------------------------------------		
	
-- Sweden	
-- create datasets of tiles in Sweden - for faster processing
CREATE TABLE "zofie_cimburova"."clip_sweden_tiles" AS (    
	SELECT tiles.gid AS orig_gid, tiles."RUTA" AS ruta, ST_Intersection(tiles.geom, sweden.geom) AS geom
	FROM "Topography"."Sweden_Vagkartan_rutnat" AS tiles, 
    	(SELECT * 
   		 FROM "AdministrativeUnits"."Fenoscandia_Country_polygon" 
    	 WHERE "countryCode" = 'SE') AS sweden
	WHERE NOT ST_Contains(sweden.geom, tiles.geom) AND    	  
    	  ST_Intersects(sweden.geom, tiles.geom));
          
INSERT INTO "zofie_cimburova"."clip_sweden_tiles"
	SELECT tiles.gid, tiles."RUTA", tiles.geom
    FROM "Topography"."Sweden_Vagkartan_rutnat" AS tiles,
    	(SELECT * 
   		 FROM "AdministrativeUnits"."Fenoscandia_Country_polygon" 
    	 WHERE "countryCode" = 'SE') AS sweden
    WHERE ST_Contains(sweden.geom, tiles.geom);
	
-- subtract all swedish LC polygons
CREATE TABLE "zofie_cimburova"."gap_sweden" AS (
	SELECT  tile.ruta,     
        COALESCE(
            ST_Difference(tile.geom, ST_Union(LC.geom)), 
            tile.geom
        ) AS geom 
	FROM "zofie_cimburova"."clip_sweden_tiles" AS tile 
	LEFT JOIN "zofie_cimburova"."valid_sweden" AS LC 
		ON tile.geom && LC.geom
	GROUP BY tile.ruta, tile.geom);
	
-- merge gaps smaller than 100 m2	
WITH repair AS (
    SELECT DISTINCT ON (gaps.ruta) gaps.ruta, LC.gid, gaps.geom
	FROM "zofie_cimburova"."gap_sweden" AS gaps
		JOIN "zofie_cimburova"."clip_sweden" AS LC
  	   	ON ST_Intersects(gaps.geom, LC.geom)
	WHERE ST_Area(gaps.geom) < 100 AND ST_Area(gaps.geom) > 0
	ORDER BY gaps.ruta, ST_Length(ST_CollectionExtract(ST_Intersection(gaps.geom, LC.geom), 2)) DESC
	)    
UPDATE "zofie_cimburova"."clip_sweden" AS orig 
SET geom = ST_Union(orig.geom, repair.geom)
FROM repair 
WHERE orig.gid = repair.gid

-- add gaps larger than 100 m2
INSERT INTO "zofie_cimburova"."clip_sweden"
	SELECT '0' AS orig_id, 12, 1200, 12000, gaps.geom AS geom
	FROM "zofie_cimburova"."gap_sweden" AS gaps
	WHERE ST_Area(gaps.geom) >= 100

	
-- Norway	
-- subtract all norwegian LC polygons from Municipality map (other small units not found)
CREATE TABLE "zofie_cimburova"."gap_norway" AS (
	SELECT  tile.gid,     
        COALESCE(
            ST_Difference(tile.geom, ST_Union(LC.geom)), 
            tile.geom
        ) AS geom 
	FROM "AdministrativeUnits"."Fenoscandia_Municipality_polygon" AS tile 
	LEFT JOIN "zofie_cimburova"."valid_norway" AS LC 
		ON tile.geom && LC.geom
    WHERE tile."countryCode" = 'NO'
	GROUP BY tile.gid, tile.geom);
    
-- delete polygons with zero area
DELETE FROM "zofie_cimburova"."gap_norway3"
WHERE ST_Area(geom) = 0

-- create single part gaps
CREATE TABLE "zofie_cimburova"."gap_norway_single" AS (
	SELECT gid AS orig_gid, 
          (ST_DUMP(geom)).geom::geometry(Polygon,25833) AS geom 
   	FROM "zofie_cimburova"."gap_norway"
    WHERE ST_GeometryType(geom) = 'ST_Polygon' OR 
          ST_GeometryType(geom) = 'ST_MultiPolygon')
		  
-- add primary key
ALTER TABLE "zofie_cimburova"."gap_norway_single" 
	ADD COLUMN gid SERIAL PRIMARY KEY;
	
-- add columns for land cover types
ALTER TABLE "zofie_cimburova"."gap_norway_single" 
	ADD COLUMN "ID_l1" smallint,
	ADD COLUMN "ID_l2" smallint,
	ADD COLUMN "ID_l3" smallint;
	
-- for each gap find its neighbours using ST_intersects and assign the gap LC of the neighbor
UPDATE "zofie_cimburova"."gap_norway_single" AS b
	SET "ID_l1" = a."ID_l1",
        "ID_l2" = a."ID_l2",
        "ID_l3" = a."ID_l3"
    FROM (
   	 	SELECT DISTINCT ON (gaps.gid) gaps.gid, gaps.geom, neighbours."ID_l1", neighbours."ID_l2", neighbours."ID_l3"
		FROM "zofie_cimburova"."gap_norway_single" AS gaps
			LEFT JOIN "zofie_cimburova"."clip_norway" AS neighbours
  			ON ST_Intersects(gaps.geom, neighbours.geom) 
		ORDER BY gaps.gid, ST_Length(ST_CollectionExtract(ST_Intersection(gaps.geom, neighbours.geom), 2)) DESC) AS a
    WHERE b.gid = a.gid
   
-- 16 gaps were not assigned anything - choose neighbour of buffer
UPDATE "zofie_cimburova"."gap_norway_single" AS b
	SET "ID_l1" = a."ID_l1",
        "ID_l2" = a."ID_l2",
        "ID_l3" = a."ID_l3"
    FROM (
        WITH buffered_gaps AS (
            SELECT ST_Buffer(geom, 0.001) AS geom, "ID_l1", "ID_l2", "ID_l3", gid
            FROM "zofie_cimburova"."gap_norway_single"
            WHERE "ID_l1" IS NULL )
   	 	SELECT DISTINCT ON (gaps.gid) gaps.gid, gaps.geom, neighbours."ID_l1", neighbours."ID_l2", neighbours."ID_l3"
		FROM buffered_gaps AS gaps
			LEFT JOIN "zofie_cimburova"."clip_norway" AS neighbours
  			ON ST_Intersects(gaps.geom, neighbours.geom)
		ORDER BY gaps.gid, ST_Length(ST_CollectionExtract(ST_Intersection(gaps.geom, neighbours.geom), 2)) DESC) AS a
    WHERE b.gid = a.gid

-- merge gaps with original dataset
INSERT INTO "zofie_cimburova"."clip_norway"
	SELECT orig_gid, "ID_l1", "ID_l2", "ID_l3", geom
    FROM "zofie_cimburova"."gap_norway_single"	
	
	
-- Finland should not contain any gaps due to the origin of the data,
-- i.e. subtracting from the country area

------------------------------------------------------------
-- 11. Merge all finnish data
------------------------------------------------------------	
-- add columns to forest data
ALTER TABLE "zofie_cimburova"."valid_finland" 
	ADD COLUMN gid SERIAL PRIMARY KEY,
	ADD COLUMN "ID_l1" smallint,
	ADD COLUMN "ID_l2" smallint,
	ADD COLUMN "ID_l3" smallint;
	
-- fill columns
UPDATE "zofie_cimburova"."clip_finland_forest"
SET "ID_l1" = 7,
  	"ID_l2" = 700,
    "ID_l3" = 7000;
	
UPDATE "zofie_cimburova"."valid_finland_forest"
SET "ID_l1" = 7,
  	"ID_l2" = 700,
    "ID_l3" = 7000;


-- union Buildings, Densely built areas, Terrain 1, Terrain 2 and Forest



------------------------------------------------------------
-- 12. Check self-overlaps
------------------------------------------------------------	
-- Norway
CREATE TABLE "zofie_cimburova"."overlaps_norway" AS
	SELECT aa.gid AS gid_1, bb.gid AS gid_2, ST_Area(ST_Intersection(aa.geom, bb.geom))
	FROM "zofie_cimburova"."clip_norway" AS aa, 
		 "zofie_cimburova"."clip_norway" AS bb
	WHERE aa.gid > bb.gid AND
		  ST_Overlaps(aa.geom, bb.geom)
		  
-- part of larger of concerned polygons kept, part of smaller polygon deleted
WITH update_table AS (
	SELECT gid_1 AS overlap_gid1,
		CASE WHEN ST_Area(poly_a.geom) > ST_Area(poly_b.geom) 
		 	 THEN ST_Difference(poly_b.geom, poly_a.geom)
   	 		 ELSE ST_Difference(poly_a.geom, poly_b.geom)
   		END AS updated_poly_geom,
   	 	CASE WHEN ST_Area(poly_a.geom) > ST_Area(poly_b.geom) 
		 	 THEN poly_b.gid 
   		 	 ELSE poly_a.gid
    	END AS updated_poly_gid
	FROM "zofie_cimburova"."clip_norway" AS poly_a,
		 "zofie_cimburova"."clip_norway" AS poly_b,
     	 "zofie_cimburova"."overlaps_norway" AS overlap
	WHERE poly_a.gid = overlap.gid_1 AND
	  	  poly_b.gid = overlap.gid_2)
UPDATE "zofie_cimburova"."clip_norway"
	SET geom = update_table.updated_poly_geom
    FROM update_table
	WHERE gid = update_table.updated_poly_gid;	  
		 

-- Sweden
CREATE TABLE "zofie_cimburova"."overlaps_sweden" AS
	SELECT aa.gid AS gid_1, bb.gid AS gid_2, ST_Area("zofie_cimburova".safe_isect(aa.geom, bb.geom))
	FROM "zofie_cimburova"."clip_sweden" AS aa, 
		 "zofie_cimburova"."clip_sweden" AS bb
	WHERE aa.gid > bb.gid AND
		  ST_Overlaps(aa.geom, bb.geom)
		  
-- part of larger of concerned polygons kept, part of smaller polygon deleted   
WITH update_table AS (
	SELECT gid_1 AS overlap_gid1,
		CASE WHEN ST_Area(poly_a.geom) > ST_Area(poly_b.geom) 
		 	 THEN "zofie_cimburova".safe_diff(poly_b.geom, poly_a.geom)
   	 		 ELSE "zofie_cimburova".safe_diff(poly_a.geom, poly_b.geom)
   		END AS updated_poly_geom,
   	 	CASE WHEN ST_Area(poly_a.geom) > ST_Area(poly_b.geom) 
		 	 THEN poly_b.gid 
   		 	 ELSE poly_a.gid
    	END AS updated_poly_gid
	FROM "zofie_cimburova"."clip_sweden" AS poly_a,
		 "zofie_cimburova"."clip_sweden" AS poly_b,
     	 "zofie_cimburova"."overlaps_sweden" AS overlap
	WHERE poly_a.gid = overlap.gid_1 AND
	  	  poly_b.gid = overlap.gid_2)
UPDATE "zofie_cimburova"."clip_sweden"
	SET geom = update_table.updated_poly_geom
    FROM update_table
	WHERE gid = update_table.updated_poly_gid;	  
		  
-- Finland buildings
CREATE TABLE "zofie_cimburova"."overlaps_finland_build" AS
	SELECT aa.gid AS gid_1, bb.gid AS gid_2, ST_Area(ST_Intersection(aa.geom, bb.geom))
	FROM "zofie_cimburova"."clip_finland_buildings" AS aa, 
		 "zofie_cimburova"."clip_finland_buildings" AS bb
	WHERE aa.gid > bb.gid AND
		  ST_Overlaps(aa.geom, bb.geom)
		  
-- part of larger of concerned polygons kept, part of smaller polygon deleted
WITH update_table AS (
	SELECT gid_1 AS overlap_gid1,
		CASE WHEN ST_Area(poly_a.geom) > ST_Area(poly_b.geom) 
		 	 THEN ST_Difference(poly_b.geom, poly_a.geom)
   	 		 ELSE ST_Difference(poly_a.geom, poly_b.geom)
   		END AS updated_poly_geom,
   	 	CASE WHEN ST_Area(poly_a.geom) > ST_Area(poly_b.geom) 
		 	 THEN poly_b.gid 
   		 	 ELSE poly_a.gid
    	END AS updated_poly_gid
	FROM "zofie_cimburova"."clip_finland_buildings" AS poly_a,
		 "zofie_cimburova"."clip_finland_buildings" AS poly_b,
     	 "zofie_cimburova"."overlaps_finland_build" AS overlap
	WHERE poly_a.gid = overlap.gid_1 AND
	  	  poly_b.gid = overlap.gid_2)
UPDATE "zofie_cimburova"."clip_finland_buildings"
	SET geom = update_table.updated_poly_geom
    FROM update_table
	WHERE gid = update_table.updated_poly_gid;	
	
	
-- Finland densely built areas
CREATE TABLE "zofie_cimburova"."overlaps_finland_dense" AS
	SELECT aa.gid AS gid_1, bb.gid AS gid_2, ST_Area(ST_Intersection(aa.geom, bb.geom))
	FROM "zofie_cimburova"."clip_finland_dense" AS aa, 
		 "zofie_cimburova"."clip_finland_dense" AS bb
	WHERE aa.gid > bb.gid AND
		  ST_Overlaps(aa.geom, bb.geom)
		  
-- part of larger of concerned polygons kept, part of smaller polygon deleted
WITH update_table AS (
	SELECT gid_1 AS overlap_gid1,
		CASE WHEN ST_Area(poly_a.geom) > ST_Area(poly_b.geom) 
		 	 THEN ST_Difference(poly_b.geom, poly_a.geom)
   	 		 ELSE ST_Difference(poly_a.geom, poly_b.geom)
   		END AS updated_poly_geom,
   	 	CASE WHEN ST_Area(poly_a.geom) > ST_Area(poly_b.geom) 
		 	 THEN poly_b.gid 
   		 	 ELSE poly_a.gid
    	END AS updated_poly_gid
	FROM "zofie_cimburova"."clip_finland_dense" AS poly_a,
		 "zofie_cimburova"."clip_finland_dense" AS poly_b,
     	 "zofie_cimburova"."overlaps_finland_dense" AS overlap
	WHERE poly_a.gid = overlap.gid_1 AND
	  	  poly_b.gid = overlap.gid_2)
UPDATE "zofie_cimburova"."clip_finland_dense"
	SET geom = update_table.updated_poly_geom
    FROM update_table
	WHERE gid = update_table.updated_poly_gid;	

		  
-- Finland terrain 1
-- problems with geometry collection -- change
UPDATE "zofie_cimburova"."clip_finland_terr1"
SET geom = ST_CollectionExtract(geom, 3)
WHERE ST_GeometryType(geom) = 'ST_GeometryCollection';	

CREATE TABLE "zofie_cimburova"."overlaps_finland_terr1" AS
	SELECT aa.gid AS gid_1, bb.gid AS gid_2, ST_Area(ST_Intersection(aa.geom, bb.geom))
	FROM "zofie_cimburova"."clip_finland_terr1" AS aa, 
		 "zofie_cimburova"."clip_finland_terr1" AS bb
	WHERE aa.gid > bb.gid AND
		  ST_Overlaps(aa.geom, bb.geom)

-- part of larger of concerned polygons kept, part of smaller polygon deleted
WITH update_table AS (
	SELECT gid_1 AS overlap_gid1,
		CASE WHEN ST_Area(poly_a.geom) > ST_Area(poly_b.geom) 
		 	 THEN ST_Difference(poly_b.geom, poly_a.geom)
   	 		 ELSE ST_Difference(poly_a.geom, poly_b.geom)
   		END AS updated_poly_geom,
   	 	CASE WHEN ST_Area(poly_a.geom) > ST_Area(poly_b.geom) 
		 	 THEN poly_b.gid 
   		 	 ELSE poly_a.gid
    	END AS updated_poly_gid
	FROM "zofie_cimburova"."clip_finland_terr1" AS poly_a,
		 "zofie_cimburova"."clip_finland_terr1" AS poly_b,
     	 "zofie_cimburova"."overlaps_finland_terr1" AS overlap
	WHERE poly_a.gid = overlap.gid_1 AND
	  	  poly_b.gid = overlap.gid_2)
UPDATE "zofie_cimburova"."clip_finland_terr1"
	SET geom = update_table.updated_poly_geom
    FROM update_table
	WHERE gid = update_table.updated_poly_gid;	

		  
-- Finland terrain 2
CREATE TABLE "zofie_cimburova"."overlaps_finland_terr2" AS
	SELECT aa.gid AS gid_1, bb.gid AS gid_2, ST_Area(ST_Intersection(aa.geom, bb.geom))
	FROM "zofie_cimburova"."clip_finland_terr2" AS aa, 
		 "zofie_cimburova"."clip_finland_terr2" AS bb
	WHERE aa.gid > bb.gid AND
		  ST_Overlaps(aa.geom, bb.geom)

-- part of larger of concerned polygons kept, part of smaller polygon deleted
WITH update_table AS (
	SELECT gid_1 AS overlap_gid1,
		CASE WHEN ST_Area(poly_a.geom) > ST_Area(poly_b.geom) 
		 	 THEN ST_Difference(poly_b.geom, poly_a.geom)
   	 		 ELSE ST_Difference(poly_a.geom, poly_b.geom)
   		END AS updated_poly_geom,
   	 	CASE WHEN ST_Area(poly_a.geom) > ST_Area(poly_b.geom) 
		 	 THEN poly_b.gid 
   		 	 ELSE poly_a.gid
    	END AS updated_poly_gid
	FROM "zofie_cimburova"."clip_finland_terr2" AS poly_a,
		 "zofie_cimburova"."clip_finland_terr2" AS poly_b,
     	 "zofie_cimburova"."overlaps_finland_terr2" AS overlap
	WHERE poly_a.gid = overlap.gid_1 AND
	  	  poly_b.gid = overlap.gid_2)
UPDATE "zofie_cimburova"."clip_finland_terr2"
	SET geom = update_table.updated_poly_geom
    FROM update_table
	WHERE gid = update_table.updated_poly_gid;	
	
-- Finland forest
CREATE TABLE "zofie_cimburova"."overlaps_finland_forest" AS
	SELECT aa.gid AS gid_1, bb.gid AS gid_2, ST_Area(ST_Intersection(aa.geom, bb.geom))
	FROM "zofie_cimburova"."clip_finland_forest" AS aa, 
		 "zofie_cimburova"."clip_finland_forest" AS bb
	WHERE aa.gid > bb.gid AND
		  ST_Overlaps(aa.geom, bb.geom)



	
-- TODO merge finnish datasets

