ALTER TABLE ni_output_areas ALTER COLUMN geom TYPE Geometry(Multipolygon, 4326) USING ST_Transform(geom, 4326);
ALTER TABLE ni_output_areas DROP COLUMN gid, DROP COLUMN sa2011, DROP COLUMN x_coord, DROP COLUMN y_coord;
DROP TABLE IF EXISTS ni;
CREATE TABLE ni AS (SELECT * FROM ni_output_areas LEFT JOIN ni_population USING (soa2011));
ALTER TABLE ni ADD COLUMN density_per_hect REAL;
-- why explicit casting is necessary below???
UPDATE ni SET density_per_hect = ROUND(CAST(population / hectares AS NUMERIC), 1);
ALTER TABLE ni DROP COLUMN soa2011, DROP COLUMN hectares, DROP COLUMN population;
DROP TABLE IF EXISTS ni_output_areas;
DROP TABLE IF EXISTS ni_population;
