#!/bin/bash

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
# should I specify the encoding here?
psql --set ON_ERROR_STOP=1 -dpostgres -c"CREATE DATABASE $DATABASE_NAME;"
psql --set ON_ERROR_STOP=1 -d$DATABASE_NAME -c"CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;"

# import output area boundaries for England and Wales
psql --set ON_ERROR_STOP=1 -d$DATABASE_NAME -c"DROP TABLE IF EXISTS ew_output_areas;"
shp2pgsql -I -c -W "latin1" -s EPSG:27700 "source_data/england-and-wales/Output_areas_(E+W)_2011_Boundaries_(Full_Clipped)_V2/OA_2011_EW_BFC_V2.shp" ew_output_areas | psql --set ON_ERROR_STOP=1 -d$DATABASE_NAME

# import population density data for England and Wales
psql --set ON_ERROR_STOP=1 -d$DATABASE_NAME -c"DROP TABLE IF EXISTS ew_population;"
psql --set ON_ERROR_STOP=1 -d$DATABASE_NAME -c"CREATE TABLE ew_population (oa11cd CHAR(9), density_per_hect REAL);"
rm -rf .temp.csv
for file in source_data/england-and-wales/*.csv;
    do
        # beware, the use of _sed_ below presume that all files end with an empty line; this could be probably managed
        # better
        cut -d , -f 2,7 "$(dir_resolve $file)" | tail -n +2 | sed '$d' >> .temp.csv
    done
psql --set ON_ERROR_STOP=1 -d$DATABASE_NAME -c"COPY ew_population (oa11cd, density_per_hect) FROM '$(dir_resolve .temp.csv)' WITH CSV;"
rm -rf .temp.csv

# adjust England and Wales tables' contents and join population and boundaries and drop the rest
psql --set ON_ERROR_STOP=1 -d$DATABASE_NAME -fprocess_ew.sql

# import output area boundaries and population density for Scotland
psql --set ON_ERROR_STOP=1 -d$DATABASE_NAME -c"DROP TABLE IF EXISTS s;"
shp2pgsql -I -c -W "latin1" -s EPSG:27700 "source_data/scotland/output-area-2011-mhw/OutputArea2011_MHW.shp" s | psql --set ON_ERROR_STOP=1 -d$DATABASE_NAME
psql --set ON_ERROR_STOP=1 -d$DATABASE_NAME -fprocess_s.sql

# import output area boundaries for Northern Ireland
psql --set ON_ERROR_STOP=1 -d$DATABASE_NAME -c"DROP TABLE IF EXISTS ni_output_areas;"
shp2pgsql -I -c -W "latin1" -s EPSG:27700 "source_data/ni/SA2011_Esri_Shapefile/SA2011.shp" ni_output_areas | psql --set ON_ERROR_STOP=1 -d$DATABASE_NAME

# import population density for Northern Ireland
psql --set ON_ERROR_STOP=1 -d$DATABASE_NAME -c"DROP TABLE IF EXISTS ni_population;"
psql --set ON_ERROR_STOP=1 -d$DATABASE_NAME -c"CREATE TABLE ni_population (soa2011 CHAR(9), population REAL);"
Rscript --vanilla process_ni.R > .temp.csv
psql --set ON_ERROR_STOP=1 -d$DATABASE_NAME -c"COPY ni_population (soa2011, population) FROM '$(dir_resolve .temp.csv)' WITH CSV;"
rm -rf .temp.csv

# adjust Northern Ireland tables' contents and join population and boundaries and drop the rest
psql --set ON_ERROR_STOP=1 -d$DATABASE_NAME -fprocess_ni.sql

# merge all
psql --set ON_ERROR_STOP=1 -d$DATABASE_NAME -c"DROP TABLE IF EXISTS uk;"
psql --set ON_ERROR_STOP=1 -d$DATABASE_NAME -c"CREATE TABLE uk AS ((SELECT * FROM ew) UNION (SELECT * FROM s) UNION (SELECT * FROM ni));"
psql --set ON_ERROR_STOP=1 -d$DATABASE_NAME -c"CREATE INDEX uk_idx ON uk USING GIST (geom);"
psql --set ON_ERROR_STOP=1 -d$DATABASE_NAME -c"DROP TABLE IF EXISTS ew;"
psql --set ON_ERROR_STOP=1 -d$DATABASE_NAME -c"DROP TABLE IF EXISTS s;"
psql --set ON_ERROR_STOP=1 -d$DATABASE_NAME -c"DROP TABLE IF EXISTS ni;"
