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

# import local authority boundaries for England, Scotland and Wales
psql --set ON_ERROR_STOP=1 -d$DATABASE_NAME -c"DROP TABLE IF EXISTS esw_boundaries;"
shp2pgsql -I -c -W "latin1" -s EPSG:27700 "source_data/great_britain/Local_authority_district_(GB)_2011_Boundaries_(Full_Extent)/LAD_DEC_2011_GB_BFE.shp" esw_boundaries | psql --set ON_ERROR_STOP=1 -d$DATABASE_NAME

# import population for England and Wales
psql --set ON_ERROR_STOP=1 -d$DATABASE_NAME -c"DROP TABLE IF EXISTS ews_population;"
psql --set ON_ERROR_STOP=1 -d$DATABASE_NAME -c"CREATE TABLE ews_population (lad11cd CHAR(9), all_usual_residents INTEGER, area REAL, density REAL);"
csvfix exclude -f 1,2,4,5,6,7,8,9 "$(dir_resolve source_data/england_and_wales/ks101ew.csv)" | tail -n +2 | sed '$d' > .temp.csv
psql --set ON_ERROR_STOP=1 -d$DATABASE_NAME -c"COPY ews_population (lad11cd, all_usual_residents, area, density) FROM '$(dir_resolve .temp.csv)' WITH CSV;"
rm -rf .temp.csv

# import population for Scotland
csvfix edit -f 2,3 -e 's/,//g' source_data/scotland/Council\ Area\ blk/QS102SC.csv | tail -n +2 | sed '$d' > .temp.csv
psql --set ON_ERROR_STOP=1 -d$DATABASE_NAME -c"COPY ews_population (lad11cd, all_usual_residents, area, density) FROM '$(dir_resolve .temp.csv)' WITH CSV;"
rm -rf .temp.csv
