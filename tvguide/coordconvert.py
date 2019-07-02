################################################################
#
#   S-01: Source Sensitivity Calculation
#		- Coordinate Conversion Script
#		- Functions need to convert coordinates. Used by sensfuncs.py and sensitivity.py
#
#   Version: 1.0
#   Author: J.D. Myers (myersjd@milkyway.gsfc.nasa.gov)
#	History:
#       1.0 - May 10, 2005
#			- Initial Release
#
################################################################

### IMPORT NEEDED MODULES
from math import *

### CONVERT DEGREES TO RADIANS
def deg2rad(deg):
    rad = (deg/180.0)*pi
    return rad

### CONVERT RADIANS TO DEGREES
def rad2deg(rad):
    deg = (rad*180.0)/pi
    return deg

### CONVERT RA (hh:mm:ss) to RA (decimal degrees)
def ra2decimal(h,m,s):
    ra = 15*h + 15.0*m/60 + 15.0*s/3600
    return ra

### CONVERT RA (decimal degrees) to RA (hh:mm:ss)
def decimal2ra(decimal):
    h = int(decimal/15)
    m = int((decimal/15.0 - h)*60)
    s = ((decimal/15.0 - h)*60 - m)*60
    ra = str(h) + ':' + str(m) + ':' + str(s)
    return ra

### CONVERT DEC (dd:mm:ss) to DEC (decimal)
def dec2decimal(d,m,s):
    # take care of negative values
    if d < 0:
        d = d*(-1)
        dec = (d + m/60.0 + s/3600.0)*(-1)
        return dec
    else:
        dec = d + m/60.0 + s/3600.0
        return dec

### CONVERT DEC (decimal) to DEC (dd:mm:ss)
def decimal2dec(decimal):
    # take care of negative values
    n = abs(decimal)
    d = int(n)
    m = int((n - d)*60)
    s = ((n - d)*60 - m)*60
    dec = str(d) + ' deg ' + str(m) + ' arcmin ' + str(s) + ' arcsec'
    if decimal < 0:
        dec = '-' + dec
        return dec
    else:
        return dec

### CONVERT B1950 TO J2000 (ASSUME NO PROPER MOTION)
def b1950_j2000(ra1950,dec1950):
    # convert ra1950 and dec1950 from degrees (decimal) to radians
    ra1950_rad = deg2rad(ra1950)
    dec1950_rad = deg2rad(dec1950)
    # convert ra and dec to rectangular coordinates
    x1950 = cos(ra1950_rad)*cos(dec1950_rad)
    y1950 = sin(ra1950_rad)*cos(dec1950_rad)
    z1950 = sin(dec1950_rad)
    # rotate (precess) the coordinates via the B1950 to J2000 precession matrix
    # |x2000|   |0.999926 -0.011179 -0.004859 |   |x1950|
    # |y2000| = |0.011179  0.999938 -0.000027 | * |x1950|
    # |z2000|   |0.004859 -0.000027  0.999988 |   |x1950|
    prec_matrix = [[0.999926,-0.011179,-0.004859],[0.011179,0.999938,-0.000027],[0.004859,-0.000027,0.999988]]
    x2000 = prec_matrix[0][0]*x1950 + prec_matrix[0][1]*y1950 + prec_matrix[0][2]*z1950
    y2000 = prec_matrix[1][0]*x1950 + prec_matrix[1][1]*y1950 + prec_matrix[1][2]*z1950
    z2000 = prec_matrix[2][0]*x1950 + prec_matrix[2][1]*y1950 + prec_matrix[2][2]*z1950
    # convert to ra and dec
    r = atan(y2000/x2000)
    if x2000 < 0:
        ra2000_rad = r + pi
    elif y2000 < 0 and x2000 > 0:
        ra2000_rad = r + 2*pi
    else:
        ra2000_rad = r
    dec2000_rad = asin(z2000)
    # convert ra2000 and dec2000 from radians to degrees (decimal)
    ra2000 = rad2deg(ra2000_rad)
    dec2000 = rad2deg(dec2000_rad)
    return ra2000, dec2000

### CONVERT J2000 TO B1950 (ASSUME NO PROPER MOTION)
def j2000_b1950(ra2000,dec2000):
    # convert ra2000 and dec2000 from degrees (decimal) to radians
    ra2000_rad = deg2rad(ra2000)
    dec2000_rad = deg2rad(dec2000)
    # convert ra and dec to rectangular coordinates
    x2000 = cos(ra2000_rad)*cos(dec2000_rad)
    y2000 = sin(ra2000_rad)*cos(dec2000_rad)
    z2000 = sin(dec2000_rad)
    # rotate (precess) the coordinates via the inverse B1950 to J2000 precession matrix
    # |x1950|   |0.999926 -0.011179 -0.004859 |   |x2000|
    # |y1950| = |0.011179  0.999938 -0.000027 | * |x2000|
    # |z1950|   |0.004859 -0.000027  0.999988 |   |x2000|
    prec_matrix = [[0.999926,-0.011179,-0.004859],[0.011179,0.999938,-0.000027],[0.004859,-0.000027,0.999988]]
    a, b, c = prec_matrix[0][0], prec_matrix[0][1], prec_matrix[0][2]
    d, e, f = prec_matrix[1][0], prec_matrix[1][1], prec_matrix[1][2]
    g, h, i = prec_matrix[2][0], prec_matrix[2][1], prec_matrix[2][2]
    det = a*(e*i-h*f) - b*(d*i-g*f) + c*(d*h-g*e)
    prec_matrix_inv = [[(e*i-h*f)/det,-(b*i-h*c)/det,(b*f-e*c)/det],[-(d*i-g*f)/det,(a*i-g*c)/det,-(a*f-d*c)/det],[(d*h-g*e)/det,-(a*h-g*b)/det,(a*e-d*b)/det]]
    x1950 = prec_matrix_inv[0][0]*x2000 + prec_matrix_inv[0][1]*y2000 + prec_matrix_inv[0][2]*z2000
    y1950 = prec_matrix_inv[1][0]*x2000 + prec_matrix_inv[1][1]*y2000 + prec_matrix_inv[1][2]*z2000
    z1950 = prec_matrix_inv[2][0]*x2000 + prec_matrix_inv[2][1]*y2000 + prec_matrix_inv[2][2]*z2000
    # convert to ra and dec
    r = atan(y1950/x1950)
    if x1950 < 0:
        ra1950_rad = r + pi
    elif y1950 < 0 and x1950 > 0:
        ra1950_rad = r + 2*pi
    else:
        ra1950_rad = r
    dec1950_rad = asin(z1950)
    # convert ra1950 and dec1950 from radians to degrees (decimal)
    ra1950 = rad2deg(ra1950_rad)
    dec1950 = rad2deg(dec1950_rad)
    return ra1950, dec1950

### CONVERT B1950 TO GALACTIC
def b1950_galactic(ra,dec):
    # constants used in conversions (converted to radians)
    c1, c2 = deg2rad(62.6), deg2rad(282.25)
    # overall formulae (converts from B1950):
    #     cos(b)cos(l-33deg) = cos(dec)cos(ra-282.25deg)
    #     cos(b)sin(l-33deg) = sin(dec)sin(62.6deg) + cos(dec)sin(ra-282.25deg)cos(62.6deg)
    #     sin(b) = sin(dec)cos(62.6deg) - cos(dec)sin(ra-282.25deg)sin(62.6deg)
    # references:
    #     http://scienceworld.wolfram.com/astronomy/GalacticCoordinates.html
    #     Barb Mattson: astro_tools.py script
    # convert ra and dec to radians
    ra, dec = deg2rad(ra), deg2rad(dec)
    # determine galactic latitude
    b = asin(sin(dec)*cos(c1) - cos(dec)*sin(ra - c2)*sin(c1))
    # determine galactic longitude
    # NOTE: things are a bit more complicated here, there is an acos/asin ambiguity (addressed below)
    # and we need to add in the extra 33 degrees
    l1 = acos(cos(dec)*cos(ra - c2)/cos(b))
    l2 = asin((sin(dec)*sin(c1) + cos(dec)*sin(ra - c2)*cos(c1))/cos(b))
    # convert everything back to degrees
    b, l1, l2 = rad2deg(b), rad2deg(l1), rad2deg(l2)
    # resolve acos/asin ambiguity by examining the quadrants that l1 and l2 are in
    if (0 <= l1 <= 90 and 0 <= l2 <= 90) or (90 <= l1 <= 180 and 0 <= l2 <= 90):
        # Quadrant I or II
        l = abs(l1)
    elif 90 <= l1 <= 180 and -90 <= l2 <= 0:
        # Quadrant III
        l = 180 + abs(l2)
    else:
        # Quadrant IV
        l = 360 - abs(l2)
    # add in the extra 33 degrees
    l = l + 33
    # check if l is > 360, if it is then subtract 360
    if l > 360:
        l = l - 360
    return l, b

### CONVERT J2000 TO GALACTIC
def j2000_galactic(ra,dec):
    # convert ra and dec from J2000 to B1950 (formualae use B1950)
    ra, dec = j2000_b1950(ra,dec)
    # constants used in conversions (converted to radians)
    c1, c2 = deg2rad(62.6), deg2rad(282.25)
    # overall formulae (converts from B1950):
    #     cos(b)cos(l-33deg) = cos(dec)cos(ra-282.25deg)
    #     cos(b)sin(l-33deg) = sin(dec)sin(62.6deg) + cos(dec)sin(ra-282.25deg)cos(62.6deg)
    #     sin(b) = sin(dec)cos(62.6deg) - cos(dec)sin(ra-282.25deg)sin(62.6deg)
    # references:
    #     http://scienceworld.wolfram.com/astronomy/GalacticCoordinates.html
    #     Barb Mattson: astro_tools.py script
    # convert ra and dec to radians
    ra, dec = deg2rad(ra), deg2rad(dec)
    # determine galactic latitude
    b = asin(sin(dec)*cos(c1) - cos(dec)*sin(ra - c2)*sin(c1))
    # determine galactic longitude
    # NOTE: things are a bit more complicated here, there is an acos/asin ambiguity (addressed below)
    # and we need to add in the extra 33 degrees
    l1 = acos(cos(dec)*cos(ra - c2)/cos(b))
    l2 = asin((sin(dec)*sin(c1) + cos(dec)*sin(ra - c2)*cos(c1))/cos(b))
    # convert everything back to degrees
    b, l1, l2 = rad2deg(b), rad2deg(l1), rad2deg(l2)
    # resolve acos/asin ambiguity by examining the quadrants that l1 and l2 are in
    if (0 <= l1 <= 90 and 0 <= l2 <= 90) or (90 <= l1 <= 180 and 0 <= l2 <= 90):
        # Quadrant I or II
        l = abs(l1)
    elif 90 <= l1 <= 180 and -90 <= l2 <= 0:
        # Quadrant III
        l = 180 + abs(l2)
    else:
        # Quadrant IV
        l = 360 - abs(l2)
    # add in the extra 33 degrees
    l = l + 33
    # check if l is > 360, if it is then subtract 360
    if l > 360:
        l = l - 360
    return l, b

### CONVERT GALACTIC TO B1950
def galactic_b1950(l,b):
    # constants used in conversions (converted to radians)
    c1, c2 = deg2rad(62.6), deg2rad(33.0)
    # overall formulae (converts to B1950):
    #     cos(dec)cos(ra-282.25deg) = cos(b)cos(l-33deg)
    #     cos(dec)sin(ra-282.25deg) = cos(b)sin(l-33deg)cos(62.6deg) - sin(b)sin(62.6deg)
    #     sin(dec) = cos(b)sin(l-33deg)sin(62.6deg) + sin(b)cos(62.6deg)
    # references:
    #     http://scienceworld.wolfram.com/astronomy/EquatorialCoordinates.html
    #     Barb Mattson: astro_tools.py script
    # conver l and b to radians
    l, b = deg2rad(l), deg2rad(b)
    # determine dec
    dec = asin(cos(b)*sin(l-c2)*sin(c1) + sin(b)*cos(c1))
    # determine ra
    # NOTE: things are a bit more complicated here, there is an acos/asin ambiguity (addressed below)
    # and we need to add in the extra 282.25 degrees
    ra1 = acos(cos(b)*cos(l-c2)/cos(dec))
    ra2 = asin((cos(b)*sin(l-c2)*cos(c1) - sin(b)*sin(c1))/cos(dec))
    # convert everything back to degrees
    dec, ra1, ra2 = rad2deg(dec), rad2deg(ra1), rad2deg(ra2)
    # resolve acos/asin ambiguity by examining the quadrants that ra1 and ra2 are in
    if (0 <= ra1 <= 90 and 0 <= ra2 <= 90) or (90 <= ra1 <= 180 and 0 <= ra2 <= 90):
        # Quadrant I or II
        ra = abs(ra1)
    elif 90 <= ra1 <= 180 and -90 <= ra2 <= 0:
        # Quadrant III
        ra = 180 + abs(ra2)
    else:
        # Quadrant IV
        ra = 360 - abs(ra2)
    # add in the extra 282.25 degrees
    ra = ra + 282.25
    # check if ra is > 360, if it is then subtract 360
    if ra > 360:
        ra = ra - 360
    return ra, dec

### CONVERT GALACTIC TO J2000
def galactic_j2000(l,b):
    # constants used in conversions (converted to radians)
    c1, c2 = deg2rad(62.6), deg2rad(33.0)
    # overall formulae (converts to B1950):
    #     cos(dec)cos(ra-282.25deg) = cos(b)cos(l-33deg)
    #     cos(dec)sin(ra-282.25deg) = cos(b)sin(l-33deg)cos(62.6deg) - sin(b)sin(62.6deg)
    #     sin(dec) = cos(b)sin(l-33deg)sin(62.6deg) + sin(b)cos(62.6deg)
    # references:
    #     http://scienceworld.wolfram.com/astronomy/EquatorialCoordinates.html
    #     Barb Mattson: astro_tools.py script
    # conver l and b to radians
    l, b = deg2rad(l), deg2rad(b)
    # determine dec
    dec = asin(cos(b)*sin(l-c2)*sin(c1) + sin(b)*cos(c1))
    # determine ra
    # NOTE: things are a bit more complicated here, there is an acos/asin ambiguity (addressed below)
    # and we need to add in the extra 282.25 degrees
    ra1 = acos(cos(b)*cos(l-c2)/cos(dec))
    ra2 = asin((cos(b)*sin(l-c2)*cos(c1) - sin(b)*sin(c1))/cos(dec))
    # convert everything back to degrees
    dec, ra1, ra2 = rad2deg(dec), rad2deg(ra1), rad2deg(ra2)
    # resolve acos/asin ambiguity by examining the quadrants that ra1 and ra2 are in
    if (0 <= ra1 <= 90 and 0 <= ra2 <= 90) or (90 <= ra1 <= 180 and 0 <= ra2 <= 90):
        # Quadrant I or II
        ra = abs(ra1)
    elif 90 <= ra1 <= 180 and -90 <= ra2 <= 0:
        # Quadrant III
        ra = 180 + abs(ra2)
    else:
        # Quadrant IV
        ra = 360 - abs(ra2)
    # add in the extra 282.25 degrees
    ra = ra + 282.25
    # check if ra is > 360, if it is then subtract 360
    if ra > 360:
        ra = ra - 360
    # convert from B1950 to J2000
    ra, dec = b1950_j2000(ra,dec)
    return ra, dec
