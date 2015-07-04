#!/bin/bash

# Makes a relative path into a full path. I need it because references to files in PostgreSQL want absolute paths.
dir_resolve() {
    # thanks to http://stackoverflow.com/a/20901614/1218376
    local dir=`dirname "$1"`
    local file=`basename "$1"`
    pushd "$dir" &>/dev/null || return $? # On error, return error code
    echo "`pwd -P`/$file" # output full, link-resolved path with filename
    popd &> /dev/null
}

# Read the _README.md_. You need a PostGIS database for this thing to work.
export DATABASE_NAME=consolidated_uk_geography

psql --set ON_ERROR_STOP=1 -dpostgres -c"DROP DATABASE IF EXISTS $DATABASE_NAME;"
psql --set ON_ERROR_STOP=1 -dpostgres -c"CREATE DATABASE $DATABASE_NAME;"
psql --set ON_ERROR_STOP=1 -d$DATABASE_NAME -c"CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;"

# Import local authority boundaries for England, Scotland and Wales
psql --set ON_ERROR_STOP=1 -d$DATABASE_NAME -c"DROP TABLE IF EXISTS gb_boundaries;"
shp2pgsql -I -c -W "latin1" -s EPSG:27700 "data/great_britain/Local_authority_district_(GB)_2011_Boundaries_(Full_Extent)/LAD_DEC_2011_GB_BFE.shp" gb_boundaries | psql --set ON_ERROR_STOP=1 -d$DATABASE_NAME
psql --set ON_ERROR_STOP=1 -d$DATABASE_NAME -c"ALTER TABLE gb_boundaries DROP COLUMN gid, DROP COLUMN lad11cdo, DROP COLUMN lad11nmw;"

# Import population for England and Wales
psql --set ON_ERROR_STOP=1 -d$DATABASE_NAME -c"DROP TABLE IF EXISTS gb_population;"
psql --set ON_ERROR_STOP=1 -d$DATABASE_NAME -c"CREATE TABLE gb_population (lad11cd CHAR(9), population INTEGER, area REAL);"
csvfix exclude -f 1,2,4,6,7,8,9,10,12 "$(dir_resolve data/england_and_wales/ks101ew.csv)" | tail -n +2 | grep -v "^$" > data/england_and_wales/.temp.csv
psql --set ON_ERROR_STOP=1 -d$DATABASE_NAME -c"COPY gb_population (lad11cd, population, area) FROM '$(dir_resolve data/england_and_wales/.temp.csv)' WITH CSV;"
rm -rf data/england_and_wales/.temp.csv

# Import population for Scotland
# Note: the source data has a row for the Scotland total (Scotland's geography code is S92000003), so I need to drop
#       that.
csvfix exclude -f 4 data/scotland/Council\ Area\ blk/QS102SC.csv | csvfix edit -f 2,3 -e 's/,//g' | csvfix remove -f 1 -s 'S92000003' | tail -n +2 | grep -v "^$" > data/scotland/.temp.csv
psql --set ON_ERROR_STOP=1 -d$DATABASE_NAME -c"COPY gb_population (lad11cd, population, area) FROM '$(dir_resolve data/scotland/.temp.csv)' WITH CSV;"
rm -rf data/scotland/.temp.csv

# Join the GB shapefile and population tables into a new _gb_ table
psql --set ON_ERROR_STOP=1 -d$DATABASE_NAME -c"DROP TABLE IF EXISTS gb;"
psql --set ON_ERROR_STOP=1 -d$DATABASE_NAME -c"CREATE TABLE gb AS (SELECT gb_boundaries.*, gb_population.population, gb_population.area FROM gb_boundaries INNER JOIN gb_population ON gb_boundaries.lad11cd = gb_population.lad11cd);"

# Import small area (SA) boundaries for Northern Ireland
psql --set ON_ERROR_STOP=1 -d$DATABASE_NAME -c"DROP TABLE IF EXISTS ni_boundaries;"
shp2pgsql -I -c -W "latin1" -s EPSG:27700 "data/ni/SA2011_Esri_Shapefile/SA2011.shp" ni_boundaries | psql --set ON_ERROR_STOP=1 -d$DATABASE_NAME
psql --set ON_ERROR_STOP=1 -d$DATABASE_NAME -c"ALTER TABLE ni_boundaries DROP COLUMN gid, DROP COLUMN soa2011, DROP COLUMN x_coord, DROP COLUMN y_coord;"

# Select the relevant parts and convert the MS Excel source files to temporary CSV files
Rscript --vanilla process_ni.R

# Import the SA population data
psql --set ON_ERROR_STOP=1 -d$DATABASE_NAME -c"DROP TABLE IF EXISTS ni_population;"
psql --set ON_ERROR_STOP=1 -d$DATABASE_NAME -c"CREATE TABLE ni_population (sa2011 CHAR(9), population INTEGER);"
psql --set ON_ERROR_STOP=1 -d$DATABASE_NAME -c"COPY ni_population FROM '$(dir_resolve data/ni/.temp.SAPE_SA_01_12.csv)' WITH CSV;"

# Import the SA to local authority lookup table
psql --set ON_ERROR_STOP=1 -d$DATABASE_NAME -c"DROP TABLE IF EXISTS ni_sa_la_lookup;"
psql --set ON_ERROR_STOP=1 -d$DATABASE_NAME -c"CREATE TABLE ni_sa_la_lookup (sa2011 CHAR(9), lgd2014 CHAR(9), lgd2014name VARCHAR);"
psql --set ON_ERROR_STOP=1 -d$DATABASE_NAME -c"COPY ni_sa_la_lookup FROM '$(dir_resolve data/ni/.temp.11DC_Lookup.csv)' WITH CSV;"

# Join the shapefile and population tables into a new _ni_temp_1_ table
psql --set ON_ERROR_STOP=1 -d$DATABASE_NAME -c"DROP TABLE IF EXISTS ni_temp_1;"
psql --set ON_ERROR_STOP=1 -d$DATABASE_NAME -c"CREATE TABLE ni_temp_1 AS (SELECT ni_boundaries.*, ni_population.population FROM ni_boundaries INNER JOIN ni_population ON ni_boundaries.sa2011 = ni_population.sa2011);"

# Join the lookup table with _ni_temp_1_ above into _ni_temp_2_
psql --set ON_ERROR_STOP=1 -d$DATABASE_NAME -c"DROP TABLE IF EXISTS ni_temp_2;"
psql --set ON_ERROR_STOP=1 -d$DATABASE_NAME -c"CREATE TABLE ni_temp_2 AS (SELECT ni_temp_1.*, ni_sa_la_lookup.lgd2014, ni_sa_la_lookup.lgd2014name FROM ni_temp_1 INNER JOIN ni_sa_la_lookup ON ni_temp_1.sa2011 = ni_sa_la_lookup.sa2011);"

# Finally, get the final data I need for NI; note that the area is converted to hectares, that appears to be the
# "standard" for UK statistics. This step takes > 16 minutes on a fast mid-2015 MacBook Pro.
psql --set ON_ERROR_STOP=1 -d$DATABASE_NAME -c"DROP TABLE IF EXISTS ni;"
psql --set ON_ERROR_STOP=1 -d$DATABASE_NAME -c"CREATE TABLE ni AS (SELECT lgd2014, lgd2014name, sum(population) AS population, ST_Union(geom) AS geom, CAST(ROUND(CAST(ST_Area(ST_Union(geom)) / 10000 AS NUMERIC), 0) AS INTEGER) AS area FROM ni_temp_2 GROUP BY lgd2014, lgd2014name);"

# Delete Northern Ireland's temporary CSV files and tables
psql --set ON_ERROR_STOP=1 -d$DATABASE_NAME -c"DROP TABLE IF EXISTS ni_boundaries; DROP TABLE IF EXISTS ni_population; DROP TABLE IF EXISTS ni_sa_la_lookup; DROP TABLE IF EXISTS ni_temp_1; DROP TABLE IF EXISTS ni_temp_2;"
rm -rf data/ni/.temp.*.csv

# Finally, create the UK table
psql --set ON_ERROR_STOP=1 -d$DATABASE_NAME -c"DROP TABLE IF EXISTS uk;"
psql --set ON_ERROR_STOP=1 -d$DATABASE_NAME -c"CREATE TABLE uk AS (SELECT lad11cd AS lad_code, lad11nm AS lad_name, geom, population, area FROM gb) UNION (SELECT lgd2014 AS lad_code, lgd2014 AS lad_name, geom, population, area FROM ni);"

# add an overall numeric index, suitable for importing as a QGIS layer
psql --set ON_ERROR_STOP=1 -d$DATABASE_NAME -c"ALTER TABLE uk ADD COLUMN gid SERIAL; UPDATE uk SET gid = DEFAULT; ALTER TABLE uk ADD PRIMARY KEY (gid);"
