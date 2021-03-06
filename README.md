consolidated-uk-geography
=========================

##Introduction
The results of the UK last census in 2011 are published by three bodies: the [Office for National Statistics](http://www.ons.gov.uk/) for England and Wales, the [National Records for Scotland](http://www.nrscotland.gov.uk/) for Scotland and the [Northern Ireland Statistics & Research Agency](http://www.nisra.gov.uk) for Northern Ireland.

To help data scientists charge higher fees to their clients, the data is published on three different websites, using different aggregation models, different formats and even different spatial reference systems (I still can't believe it) so that a substantial volume of work is necessary to draw a comprehensive picture of the United Kingdom as a whole.

Moreover, the data is sometimes 'stuck' to the administrative geography that worked at the time of the Census. E.g. the Northern Irish machine-readable data is available aggregated vs the then census geography (small areas, super output areas etc.) but not vs the most relevant and current ones, such as the ["local government districts"](https://en.wikipedia.org/wiki/Local_government_in_Northern_Ireland).

<blockquote class="twitter-tweet" lang="en"><p lang="en" dir="ltr">I started hating devolution the first time I had to reconcile <a href="https://twitter.com/hashtag/opendata?src=hash">#opendata</a> from the three UK 2011 censuses: England+Wales, Scotland and NI 😡</p>&mdash; Gianfranco Cecconi (@giacecco) <a href="https://twitter.com/giacecco/status/612226696037683200">June 20, 2015</a></blockquote>
<script async src="//platform.twitter.com/widgets.js" charset="utf-8"></script>

The scripts in this repository start experimenting / addressing the issue by importing selected data from the three sources - **for the time being: geometry, population (as of the 2011 Census) and area of all current local administrative authorities** - into one homogeneous, cross-countries dataset. The ambition is to create a dataset that describes the latest administrative geographies (the ones most people would know and "connect to") vs the latest coherent demographics (as I write, just the 2011 Census' total population numbers).

What I call the "local administrative authorities" are:
- in England:
  - the "single-tier" authorities
    - the 55 [unitary authorities](https://en.wikipedia.org/wiki/Unitary_authorities_of_England)
    - the ["City of London"](https://en.wikipedia.org/wiki/City_of_London_Corporation) (that is not a London borough)
    - the [Isles of Scilly](https://en.wikipedia.org/wiki/Isles_of_Scilly)
  - the "lower-tier" authorities
    - the 201 [non metropolitan districts](https://en.wikipedia.org/wiki/Non-metropolitan_district) (or "shires")
    - the 36 [metropolitan boroughs](https://en.wikipedia.org/wiki/Metropolitan_borough)
    - the 32 [London boroughs](https://en.wikipedia.org/wiki/London_boroughs)
- in Northern Ireland, the 11 [districts](https://en.wikipedia.org/wiki/Local_government_in_Northern_Ireland)
- in Scotland, the 32 [unitary authorities](https://en.wikipedia.org/wiki/Local_government_in_Scotland) (or "councils")
- in Wales, the 22 [principal areas](https://en.wikipedia.org/wiki/Local_government_in_Wales) (or "counties")

Note that **for the time being, no data is distributed or re-distributed in this repository**, but just the code to produce it yourself, as I did not have the time to assess in detail the licensing of all the sources. While I am quite comfortable for England and Wales' data to be available under the UK [Open Government Licence](http://www.nationalarchives.gov.uk/doc/open-government-licence) (OGL), I can't say the same for Scotland and Northern Ireland. The documentation in the [data](data) folder describes all the source data you need to find and download before you can run the scripts.

Hope you will appreciate the effort and continue it together with me. I am sure lots of testing is needed and there may be mistakes. Please check [the open issues](https://github.com/Digital-Contraptions-Imaginarium/consolidated-uk-geography/issues) before asking for support or deciding how to contribute. Thanks!

##Usage
Define the name of the target database by changing the _DATABASE_NAME_ variable in the _process.sh_ script and run it by using _bash_ in a terminal. After lots of verbose output and at least 16 minutes (depending on your machine's performance and PostgreSQL optimisation) you will have a _uk_ table in your PostGIS, a ~54Mb _uk.json_ GeoJSON and a 14Kb _uk.csv_ file with the consolidated data. The GeoJSON file includes the authorities' geometries.
```
$ bash process.sh
```

##Prerequisites
You need a working, local [PostgreSQL/PostGIS database](http://postgis.net/), the [GDAL](http://www.gdal.org/) command line utilities (we use _shp2pgsql_ and _ogr2ogr_), [csvfix](http://neilb.bitbucket.org/csvfix/) and an [R](http://www.r-project.org/) environment with the _gdata_ package installed (to read directly from MS Excel files).

The PostgreSQL commands assume that the current user has administrative rights and no password set. Of course this is bad practice if you use that PostgreSQL for anything but development. It comes handy [if you've spent some times making your PostgreSQL faster](http://big-elephants.com/2012-12/tuning-postgres-on-macos/).

The scripts have been tested on MacOS and should work on Linux with little adaptation.

##Licence
No data is distributed or re-distributed in this repository. All code is copyright (c) 2015 Digital Contraptions Imaginarium Ltd. and licensed under the terms of the [MIT licence](LICENCE.md).
