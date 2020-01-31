# TVGuide



### Summary

This is the Transiting Exoplanet Survey Satellite (TESS) Viewing
Guide, a downloadable version of the
[Web TESS Viewing Tool](https://heasarc.gsfc.nasa.gov/cgi-bin/tess/webtess/wtv.py).
It includes a command line executable that wraps the functions and
prints a summary of the results as well as a package that allows you to call the
viewing functions within your own python scripts.  It takes the same
inputs as the web tool, i.e., several options for a single source or
a list of decimal RA,DEC pairs.


### Prerequisites

Python 2.7+, astropy, astroquery, numpy, and a Fortran compiler such
as GNU Fortran.  This works best if all are consistently built into an Anaconda
installation.  Tested under Linux and OSX for Python 2.7 or 3.6.  


### Installing


This can be installed with pip:

```
pip install tvguide
```

Alternatively, download or clone this repo, and from within the top level directory:
```
python setup.py install
```

will install an executable wrapper called 'tvguide' as well as the tvguide package.

### Usage

Ask for a source by name:
```
import tvguide
import astropy.coordinates as coord
pos=coord.SkyCoord.from_name("eta car")
results=tvguide.view( pos.ra.deg, pos.dec.deg )
print( [ 'Eta car viewed by camera {} during Sector {}'.format( camera, sectorM1+1 ) for sectorM1,camera in enumerate(results) if camera > 0 ] )
```

Give a source list with decimal ra,dec pairs:
```
cameras=tvguide.view_list( ras, decs )
```
and then do something with the list of camera information,  a list of
lists where for each source is returned ra, dec, and the camera
numbers for each of the sectors.

Or print out a summary of a list on disk:
```
tvguide.process_infile('data/test.lis')
```

Alternatively, there is a command-line executable:

```
> tvguide
 USAGE:  tvguide [--source=] [--infile=]

where the source string can be
  - a name (e.g., 'Cyg X-1'),
  - a pair of (RA,DEC) coordinates in decimal, (e.g., '101.295, -16.699'),
  - a pair of (RA,DEC) coordinates in sexagesimal (e.g., '6 45 10.8, -16 41 58'),
  - or a TIC ID (e.g., '268644785').

or an input file consisting of a CSV file with RA,DEC pairs.
```


## Authors

* **T.R. Jaffe** - Python code
* **K. Mukai** - Fortran library

## License

This project is licensed under the MIT License - see the [LICENSE.txt](LICENSE.txt) file for details

## Acknowledgments

With thanks to Tom Barclay for a prototype Python wrapper.


## Notes


Note:  this includes compiled Fortran code.  On OSX, before installing compiled software, be sure you have
command line tools and the associated libraries.  If you get a compilation error regarding
something like a missing limits.h, then you need to install these with

```
xcode-select --install
```
and
```
open /Library/Developer/CommandLineTools/Packages/macOS_SDK_headers_for_macOS_10.14. pkg
```

