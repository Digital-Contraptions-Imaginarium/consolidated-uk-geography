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

# import small area boundaries for Northern Ireland
psql --set ON_ERROR_STOP=1 -d$DATABASE_NAME -c"DROP TABLE IF EXISTS ni_boundaries;"
shp2pgsql -I -c -W "latin1" -s EPSG:27700 "data/ni/SA2011_Esri_Shapefile/SA2011.shp" ni_boundaries | psql --set ON_ERROR_STOP=1 -d$DATABASE_NAME
psql --set ON_ERROR_STOP=1 -d$DATABASE_NAME -c"ALTER TABLE ni_boundaries DROP COLUMN gid, DROP COLUMN soa2011, DROP COLUMN x_coord, DROP COLUMN y_coord;"

# select the relevant parts and convert the MS Excel source files to CSV
Rscript --vanilla process_ni.R
