ALTER TABLE s ALTER COLUMN geom TYPE Geometry(Multipolygon, 4326) USING ST_Transform(geom, 4326);
ALTER TABLE s ADD COLUMN density_per_hect REAL;
UPDATE s SET density_per_hect = ROUND(popcount / hect, 1);
ALTER TABLE s DROP COLUMN gid, DROP COLUMN objectid, DROP COLUMN code, DROP COLUMN hhcount, DROP COLUMN popcount, DROP COLUMN council, DROP COLUMN sqkm, DROP COLUMN hect, DROP COLUMN masterpc, DROP COLUMN easting, DROP COLUMN northing, DROP COLUMN shape_1_le, DROP COLUMN shape_1_ar, DROP COLUMN datazone;
