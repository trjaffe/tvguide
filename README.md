# Project Title
TVGuide -- the Transiting Exoplanet Survey Satellite (TESS) Viewing Guide

### Prerequisites

Python 2.7+, astropy, astroquery, numpy, and a Fortran compiler such as GNU Fortran.

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


