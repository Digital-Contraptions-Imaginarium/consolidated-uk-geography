consolidated-uk-geography
=========================

##Introduction
The UK last census in 2011 was administered by three statistics authorities: one for England and Wales, the [Office for National Statistics](http://www.ons.gov.uk/), one for Scotland, the [National Records for Scotland](http://www.nrscotland.gov.uk/), and one for Northern Ireland, the [Northern Ireland Statistics & Research Agency](http://www.nisra.gov.uk). To help data scientists charge higher fees to their clients, the three bodies published the data that was collected through the census using three different websites, different aggregation models, different formats, different units etc. so that a substantial volume of work is necessary to draw a comprehensive picture of the United Kingdom as a whole.

<blockquote class="twitter-tweet" lang="en"><p lang="en" dir="ltr">I started hating devolution the first time I had to reconcile <a href="https://twitter.com/hashtag/opendata?src=hash">#opendata</a> from the three UK 2011 censuses: England+Wales, Scotland and NI 😡</p>&mdash; Gianfranco Cecconi (@giacecco) <a href="https://twitter.com/giacecco/status/612226696037683200">June 20, 2015</a></blockquote>
<script async src="//platform.twitter.com/widgets.js" charset="utf-8"></script>

The scripts in this repository try to start addressing the issue by importing selected data from the three sources into homogeneous, cross-country datasets. Hope you will appreciate the effort and continue it together with me.

##Usage
Run the process script using _bash_ in a console. After lots of verbose output and at least 16 minutes (depending on your machine's performance and PostgreSQL optimisation) you will have a _uk_ table and a ~54Mb _uk.json_ file with the consolidated data.
```
$ bash process.sh
```

##Prerequisites
A working, local [PostGIS database](http://postgis.net/), the [GDAL](http://www.gdal.org/) command line utilities and an [R](http://www.r-project.org/) environment with the following packages installed: gdata. The scripts have been tested on MacOS and should work on Linux with little adaptation. The PostGIS commands assume that the current user has administrative rights and no password set. Of course this is bad practice if you use that PostGIS for anything but development.

##Licence
For the time being, no data is distributed or re-distributed in this repository, as I could not assess in detail the licensing of all the sources. While I am quite comfortable for England and Wales' data to be available under OGL, I can't say the same for Scotland and Northern Ireland. The documentation in the [data](data) folder describes everything you need and where to find it.

All code is copyright (c) 2015 Digital Contraptions Imaginarium Ltd. and licensed under the terms of the [MIT licence](LICENCE.md).
