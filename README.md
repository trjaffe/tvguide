# Project Title
TVGuide -- the Transiting Exoplanet Survey Satellite (TESS) Viewing
Guide.

### Summary

This is a downloadable version of the
[Web TESS Viewing Tool](https://heasarc.gsfc.nasa.gov/cgi-bin/tess/webtess/wtv.py).
It includes a command line executable that wraps the functions and
prints the results as well as a package that allows you to call the
viewing functions within your own python scripts.  It takes the same
inputs as the web tool, i.e., several options for a single source, or
a list of decimal ra,dec pairs.


### Prerequisites

Python 2.7+, astropy, astroquery, numpy, and a Fortran compiler such
as GNU Fortran.  This works best if all are in your Anaconda
installation.


### Installing

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



## Authors

* **T.R. Jaffe** - Python code
* **K. Mukai** - Fortran library

## License

This project is licensed under the MIT License - see the [LICENSE.txt](LICENSE.txt) file for details

## Acknowledgments

With thanks to Tom Barclay for a prototype Python wrapper.

