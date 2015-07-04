consolidated-uk-geography
=========================

##Introduction
The UK last census in 2011 was administered by three statistics authorities: one for England and Wales, the [Office for National Statistics](http://www.ons.gov.uk/), one for Scotland, the [National Records for Scotland](http://www.nrscotland.gov.uk/), and one for Northern Ireland, the [Northern Ireland Statistics & Research Agency](http://www.nisra.gov.uk). To help data scientists charge higher fees to their clients, the three bodies published the data that was collected through the census using three different websites, different aggregation models, different formats, different units and even different spatial reference systems (I still can't believe it) so that a substantial volume of work is necessary to draw a comprehensive picture of the United Kingdom as a whole.

<blockquote class="twitter-tweet" lang="en"><p lang="en" dir="ltr">I started hating devolution the first time I had to reconcile <a href="https://twitter.com/hashtag/opendata?src=hash">#opendata</a> from the three UK 2011 censuses: England+Wales, Scotland and NI 😡</p>&mdash; Gianfranco Cecconi (@giacecco) <a href="https://twitter.com/giacecco/status/612226696037683200">June 20, 2015</a></blockquote>
<script async src="//platform.twitter.com/widgets.js" charset="utf-8"></script>

The scripts in this repository start addressing the issue by importing selected data from the three sources - **for the time being: geometry, population (as of the 2011 Census) and area of all local administrative authorities** - into one homogeneous, cross-countries dataset. The ambition is to have a dataset that describes the latest geographies vs the latest coherent demographics (as I write, the 2011 Census' population numbers).

Hope you will appreciate the effort and continue it together with me. Please check [the open issues](https://github.com/Digital-Contraptions-Imaginarium/consolidated-uk-geography/issues) before asking for support or deciding what to contribute. Thanks!

##Usage
Define the name of the target database by changing the _DATABASE_NAME_ variable in the _process.sh_ script and run it by using _bash_ in a terminal. After lots of verbose output and at least 16 minutes (depending on your machine's performance and PostgreSQL optimisation) you will have a _uk_ table in your PostGIS and a ~54Mb _uk.json_ file with the consolidated data.
```
$ bash process.sh
```

##Prerequisites
You need a working, local [PostGIS database](http://postgis.net/), the [GDAL](http://www.gdal.org/) command line utilities and an [R](http://www.r-project.org/) environment with the _gdata_ package installed. The PostGIS commands assume that the current user has administrative rights and no password set. Of course this is bad practice if you use that PostGIS for anything but development.

The scripts have been tested on MacOS and should work on Linux with little adaptation.

##Licence
For the time being, no data is distributed or re-distributed in this repository, as I could not assess in detail the licensing of all the sources. While I am quite comfortable for England and Wales' data to be available under the UK [Open Government Licence](http://www.nationalarchives.gov.uk/doc/open-government-licence) (OGL), I can't say the same for Scotland and Northern Ireland. The documentation in the [data](data) folder describes everything you need and where to find it.

All code is copyright (c) 2015 Digital Contraptions Imaginarium Ltd. and licensed under the terms of the [MIT licence](LICENCE.md).
