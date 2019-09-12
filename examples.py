import tvguide
import astropy.coordinates as coord
import numpy as np

## Ask for a source by name:
pos=coord.SkyCoord.from_name("eta car")
results=tvguide.view( pos.ra.deg, pos.dec.deg )
print( [ 'Eta car viewed by camera {} during Sector {}'.format( camera, sectorM1+1 ) for sectorM1,camera in enumerate(results) if camera > 0 ] )


## Give a source list with decimal ra,dec pairs:
ras, decs = np.atleast_2d(np.genfromtxt(
    'data/test.lis',
    usecols=[0, 1],
    delimiter=',',
    comments='#',
    skip_header=0,
    dtype="f8"
)).T
cameras=tvguide.view_list( ras, decs )
## and do something with camera information...


## Or to get it to print a summary of a list on disk:
tvguide.process_infile('data/test.lis')









