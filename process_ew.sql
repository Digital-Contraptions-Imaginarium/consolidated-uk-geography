ALTER TABLE ew_output_areas ALTER COLUMN geom TYPE Geometry(Multipolygon, 4326) USING ST_Transform(geom, 4326);
DROP TABLE IF EXISTS ew;
CREATE TABLE ew as (SELECT geom, density_per_hect FROM ew_output_areas LEFT JOIN ew_population USING (oa11cd));
DROP TABLE IF EXISTS ew_output_areas;
DROP TABLE IF EXISTS ew_population;
