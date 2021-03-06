# -*- coding: utf-8 -*-
# ^ needed for special degree character parsing
import re,os,io,sys
import numpy as np
from viewf import viewf, viewdate
from .coordconvert import *

debug=False

class Namespace:
    """  Namespace to mimic args passed to Fortran wrapper view()
    """

    def __init__(self,indict=None,**kwargs):
        if indict is not None:  self.__dict__.update(indict)
        else:  self.__dict__.update(kwargs)



def view(ra_deg, dec_deg,quiet=True):
    """ Wrapper for Koji Mukai's Fortran TESS viewing tool taking one ra,dec pair in decimal degrees."""

    ## Use, e.g.,  utils.parse_NameRaDec() to get the inputs from user form.  
    ## Have to convert ra from decimal degrees to decimal *hours*. 
    from astropy.coordinates import SkyCoord
    from astropy import units as u
    coord = SkyCoord(ra=ra_deg * u.degree, dec=dec_deg * u.degree, frame='icrs')
    if debug:  print("<p>You gave (ra,dec)=({}deg,{}deg)=({}h,{}deg).  Calling viewf()</p>".format(coord.ra.degree,coord.dec.degree,coord.ra.hour,coord.dec.degree))
    try:
        full_out=viewf(coord.ra.hour, coord.dec.degree)
    except Exception as e: 
        print("ERROR:  could not call viewf():  {}.  ".format(e))

    num_cycles = int(len(full_out)/13)
    if debug:
        print("<p>DEBUGGING:  got back {} sectors, so assuming {} cycles.</p>".format(len(full_out),num_cycles))

    for ncycle in range(num_cycles):
        cycle=ncycle+1 # arrays counting from zero, Cycles from 1
        out=full_out[ncycle*13:cycle*13]

        if not quiet:
            for i,f in enumerate(out):
                try:
                    datestr=viewdate(cycle, i+1).decode()
                except Exception as e: 
                    print("<p>ERROR:  could not call viewdate():  {}.  ".format(e))

                if f > 0: print("Sector {:2d} ({}, in cycle {}): observed in camera {}.".format(i+1+13*ncycle,datestr, cycle,f))
                else:  print("Sector {:2d} ({}, in cycle {}): not observed.".format(i+1+13*ncycle,datestr, cycle))

    return full_out


def view_list( ras, decs, nsectors=None ):
    """ Wrapper for Koji Mukai's Fortran TESS viewing tool taking a list of RAs and a list of DECs.

    By default, nsectors is 2x13 for the first two cycles.  To be updated as needed.
    """
    try:
        tmp=view(0,0)
        nsectors=len(tmp)
    except Exception as e:
        print("ERROR:  Could not call view() to test number of sectors:  {}".format(e))
        raise

    # Will return a camera number for each of 13 sectors
    cameras=np.zeros((len(ras),nsectors+2))
    for i,ra in np.ndenumerate(ras):
        cameras[i,0]=ra
        cameras[i,1]=decs[i]
        cameras[i,2:]=view(ra,decs[i])

    return cameras


def get_sector_dates(cycle=1):
    # Got to make sure the data are initialized in the common block, which
    #  you can do if you call view() once.
    x=view(0.0,0.0,1)
    dates=[]
    for i in range(13):
        dates.append( viewdate(cycle,i+1).decode() )
    return dates




def summarize_html( observations, sectors, cameras, ncycle=0):
    """Prints summary stats for HTML output"""

    num=len(observations)

    print('<div><table class="table-condensed"><tr><th>Summary</th><th>number</th><th>fraction</th></tr>\n'.format(num))

    print("<td>Number of sources with at least 1 observation:  </td><td> {:d} </td><td> {:.1f}% </td></tr>".format( len([o for o in observations if o > 0]) , 100.*float(len([o for o in observations if o > 0]))/float(num)) )

    print("<td>Number of sources with at least 2 observations:  </td><td> {:d} </td><td> {:.1f}% </td></tr>".format( len([o for o in observations if o > 1]) , 100.*float(len([o for o in observations if o > 1]))/float(num)) )

    print("<td>Number of sources not observed:  </td><td> {:d} </td><td> {:.1f}% </td></tr>".format( len([o for o in observations if o == 0]) , 100.*float(len([o for o in observations if o == 0]))/float(num) ))

    for s in range(1,14):
        print("<td>Number of sources observed in Sector {:d}:  </td><td> {:d} </td><td> {:.1f}% </td></tr>".format(s+ncycle*13, sectors[s-1], 100*sectors[s-1]/float(num)))
    for c in range(1,5):
        print("<td>Number of sources observed in Camera {:d} </td><td>  {:d} </td><td> - </td></tr>".format(c, cameras[c-1] ))

       
    print("</table>")
    print("<p>(Feel free to write to the helpdesk to suggest other useful stats!)</p>\n")
    print("</div>")



def summarize_simple( observations, sectors, cameras, ncycle=0):
    """Prints summary stats for screen output
    """

    num=len(observations)
    print("{:-<70}".format(''))
    print("{: <50} {: >10} {: >10}".format('Summary for Cycle {:1}'.format(ncycle+1),'number','fraction'))
    print("{:-<70}".format(''))

    print("{: <50} {: >10} {: >10.2f}".format("Number of sources with at least 1 observation:", len([o for o in observations if o > 0]) , 100.*float(len([o for o in observations if o > 0]))/float(num)) )
    print("{: <50} {: >10} {: >10.2f}".format("Number of sources with at least 2 observations:",len([o for o in observations if o > 1]) , 100.*float(len([o for o in observations if o > 1]))/float(num)))
    print("{: <50} {: >10} {: >10.2f}".format("Number of sources not observed: ",len([o for o in observations if o == 0]) , 100.*float(len([o for o in observations if o == 0]))/float(num) ))

    for s in range(1,14):
        print("{: <50} {: >10} {: >10.2f}".format("Number of sources observed in Sector {: >2}:".format(s+ncycle*13), sectors[s-1], 100*sectors[s-1]/float(num)))
    for c in range(1,5):
        print("{: <50} {: >10}".format("Number of sources observed in Camera {: >2}:".format(c), cameras[c-1] ))



def summarize_list(stats,ncycle=0):
    """ Compute summary statistics to be printed with either summarize_html() or summarize()
    """

    num=stats.shape[0]
    
    observations=[len([s for s in stats[row,2:15] if s > 0]) for row in range(num)]
    sectors=np.zeros(13,dtype=int)
    cameras=np.zeros(5,dtype=int)
    if debug: print("DEBUGGING:  in summarize_list about to set sector data")
    for s in range(1,14):
        sectors[s-1]=len([c for c in stats[:,s+1] if c > 0])

    if debug: print("DEBUGGING:  in summarize_list about to count cameras")
    ## Count how many sources are observed in each camera.
    for c in range(1,5):
        cameras[c-1]=sum([1 for r in range(0,num) if c in stats[r,2:-1] ])
 
    return observations, sectors, cameras 




def parse_input(fileitem):
    """Managing the input options for a list input, handing contents to parse_lines().

    Converts to floats just to be sure, also replaces \r Windows-style
    newlines which aren't parsed correctly.
    """

    assert fileitem is not None
    if debug:  print("<p>DEBUGGING: got into parse_input() with fileitem is {}</p>".format(fileitem))
    if debug and fileitem.value:  print("<p>DEBUGGING: got into parse_input() with fileitem.value</p>")

    if not hasattr(fileitem,'file') and type(fileitem) is str:
        # Given a file on disk for testing
        if debug:  print("<p>DEBUGGING:  fileitem is str, calling tvguide's parse_file</p>")
        if not os.path.isfile(fileitem):
            print("ERROR:  cannot find fileitem '%s'"%fileitem)
            exit(1)
        try:
            ## Use io.open for encoding compatibility with 2 and 3.
            with io.open(fileitem,'r',encoding='utf_8') as infile:
                #  No decode here because done on open unlike the cgi case below
                lines=[l for l in infile.readlines()]
        except Exception as e:
            print("ERROR:  cannot read file {}: {}".format(fileitem,e))
    else:
        lines=[l.decode() for l in fileitem.file.readlines()]
    # A bit extra to handle Windows-style carriage returns.  genfromtxt used in parse_file doesn't 
    #  seem to handle them correctly
    if len(lines) == 1:
        lines=re.split('\r',lines[0])
    try:
        #inra,indec=parse_file(io.StringIO("\n".join(lines)))
        ra,dec,bad=parse_lines(lines)
    except Exception as e:
        print("<p><font color=red>Problem reading file</font>:  Exception {}</p>".format(e))

    return ra,dec,bad


def parse_lines(inlines):
    """Parses input list of strings into numpy array of ras, decs as floats"""

    ras=[]
    decs=[]
    bad=0
    for line in inlines:  
        if not line.startswith('#'):
            ra,dec = tuple( line.split(',')[0:2] )
            try:
                ras.append(float(ra.strip()))
            except:
                bad+=1
                ras.append(np.nan)
            try:
                decs.append(float(dec.strip()))
            except:
                bad+=1
                decs.append(np.nan)

    return np.array(ras),np.array(decs),bad 


def csv_header():
    try:
        tmp=viewf(0,0)
        num_cycles = int(len(tmp)/13)
    except Exception as e:
        print("ERROR:  Cannot run viewf() to get number of cycles:  {}".format(e))
        raise
    if debug:
        print("<p>DEBUGGING:  num_cycles={}</p>".format(num_cycles))
    cycles=range(num_cycles)
    header=""
    for cycle in cycles:
        header+="\n# For TESS observing Cycle {}\n# ".format(cycle+1)
        dates=get_sector_dates(cycle=cycle+1)
        header+="\n# ".join([ "Sector {:2d} observed {}".format(s+13*cycle,d) for s,d in enumerate(dates,1)])
        if debug:  print("<p>DEBUGGING:  header is {}</p>".format(header))
    header+="\n#\n#RA,DEC,"
    for i in range(13*len(cycles)-1):
        header+="S{},".format(i+1)
    header+="S{}".format(len(cycles)*13)
    return header




def parse_coord(incoord,hours=False):
    # See https://heasarc.gsfc.nasa.gov/Tools/name_or_coordinates_help.html
    #  and
    #  https://stackoverflow.com/questions/385558/extract-float-double-value
    #
    #  So this should work for "-54 4 3.2" or "-54d4m3.2s" or 
    # "-54 4.2" or "+54:4.:3.2" etc., or (I hope) any odd characters
    #  in between.  Only worry is special characters like degrees
    #  that could get pasted into the form and turned into something numeric.  
    #
    #from coordconvert import ra2decimal, dec2decimal

    pattern=r"^[\d\s\+-\.hms]*$"
    if not re.match(pattern ,incoord):
        print("Content-type:text/html\n\n<p><font color=red>Illegal characters found in string. </font></p>")
        exit(-1)


    pattern=re.compile(r"[\+-]?(?:\d+(?:\.\d*)?|\d\d+)")

    wsplit=pattern.findall(incoord)
    if debug:  print("<p>DEBUGGING:  got wsplit={} from incoord='{}'</p>".format(wsplit,incoord))
    #  h m s.s  or h m.m if hours=True
    #  d m s.s  or d m.m if hours=False

    try:
        if len(wsplit) == 1 and not hours:
            if debug:  print("<p>DEBUGGING:  trying decimal={}</p>".format(wsplit[0]))
            return float(wsplit[0])
        elif len(wsplit) == 2 and hours:
            if debug:  print("<p>DEBUGGING:  trying H={} M={} </p>".format(wsplit[0],wsplit[1]))
            return ra2decimal(float(wsplit[0]),float(wsplit[1]),0.0)
        elif len(wsplit)==2 and not hours:
            if debug:  print("<p>DEBUGGING:  trying D={} M={} </p>".format(wsplit[0],wsplit[1]))
            return dec2decimal(float(wsplit[0]),float(wsplit[1]),0.0)
        elif len(wsplit) == 3 and hours:
            if debug:  print("<p>DEBUGGING:  trying H={} M={} S={} </p>".format(wsplit[0],wsplit[1],wsplit[2]))
            return ra2decimal(float(wsplit[0]),float(wsplit[1]),float(wsplit[2]))
        elif len(wsplit) == 3 and not hours:
            if debug:  print("<p>DEBUGGING:  trying D={} M={} S={} </p>".format(wsplit[0],wsplit[1],wsplit[2]))
            return dec2decimal(float(wsplit[0]),float(wsplit[1]),float(wsplit[2]))
        else:
            print("<p>ERROR:  Cannot parse input coordinate</p>")

    except Exception as e:
        print("<p>ERROR:  cannot convert input into decimal coordinate:  '{}'</p>"&(e))
        return None



def parse_NameRaDec(entry):
    if debug:  print("<p>DEBUGGING:  got into parse_NameRaDec({})</p>".format(entry))
    degpat='^\s*[-+]?\d+\.?[dD]'
    decpat='^\s*[+-]?\d+(\.\d*)?$'
    #  Briefly attempted to handle a unicode degree symbol, but couldn't get it to work.
    #deg='º'   #  Simply doesn't match web input
    #deg=u'\xb0'  #  With u causes compile error.  Without, there's simply no match.  
    deg='\u00b0'  # this with (deg.encode('utf-8') in entry) does what I want on the command line but not in the web input
    if debug:
        if deg in entry:  print("<p>DEBUGGING:  Found a degree symbol in entry</p>")
        else: print("<p>DEBUGGING:  Did NOT find a degree symbol in entry</p>")

    comsep=re.split('\s*,\s*',entry)
    if len(comsep) == 1:
        if debug:  print("<p>DEBUGGING:  splits into only one field, '{}'</p>".format(comsep))
        if re.match('^\s*\d+\s*$',comsep[0]):
            if debug:  print("<p>DEBUGGING: this field is all digits;  trying as a TIC ID</p>")
            try:
                return ticid2radec(comsep[0])
            except Exception as e:
                print("<p>ERROR:  Problem calling ticid2radec():  {}</p>".format(e))
                raise
        else:
            if debug:  print("<p>DEBUGGING: this field is NOT all digits, so trying the name resolver</p>")
            try:
                return name_resolver(entry)
            except Exception as e:
                #  Don't do this print here.  It messes up the HTML.  Caller should handle None return. 
                #print("<p>ERROR:  Problem calling name_resolver():  {}</p>".format((e)))
                return entry, None, None
    elif len(comsep) == 2:
        if debug:  print("<p>DEBUGGING:  splits into two fields, '{},{}', so assuming RA, DEC</p>".format(comsep[0],comsep[1]))
        if deg in comsep[0] or re.match(degpat,comsep[0]) or re.match(decpat,comsep[0]):  
        #if re.match(degpat,comsep[0]):  
            if debug:  print("<p>DEBUGGING:  first field has what looks like a degree indicator or is simply a decimal</p>")
            hours=False
        else: 
            if debug:  print("<p>DEBUGGING:  first field has nothing that looks like a degree indicator, so assuming hours</p>")
            hours=True
        RA=parse_coord(comsep[0],hours=hours)
        DEC=parse_coord(comsep[1],hours=False)
    else:
        print("<p>ERROR:  entry splits into {} comma-separated fields.  Expecting one name field or two RA,DEC fields.  If your RA,DEC are in sexadecimal format, use spaces instead of commas, i.e. 'H M S.S' and 'D M S.S'.</p>".format(len(comsep)))

    if debug:  print("<p>DEBUGGING:  returning entry={}, RA={}, and DEC={}<p>".format(entry,RA, DEC))
    return None, RA, DEC



def ticid2radec(entry):
    if debug:  print("<p>DEBUGGING:  trying to call astropy.mast.Catalogs.query_criteria()</p>")
    #from .coordconvert import ra2decimal, dec2decimal
    #from cgi import escape
    import warnings,datetime

    if "GATEWAY_INTERFACE" in os.environ:
        import __main__
        homedir=os.path.abspath(os.path.join(os.path.dirname(__main__.__file__),'../tmp/'))
        ## #  To make astropy work from w/in Apache?  XDG variables don't work.
        os.environ.update({
           'HOME': homedir
        } )
        if not (os.path.isdir(homedir) or os.path.islink(homedir)):  
            if debug:  print("<p>Trying to make homedir {}</p>".format(homedir))
            try:
                os.mkdir(homedir)
            except Exception as e:
                print("<p><font color=red>ERROR:  Failed to make homedir with exception {}</font></e>".format(e))
                return None

    homedir=os.environ["HOME"]

    if debug:  
        print("<p>Homedir is {} with contents:".format(homedir))
        print(os.listdir(homedir))
        if os.path.isdir("{}/.astropy".format(homedir)):
            print(os.listdir("{}/.astropy".format(homedir)))
        print("</p>\n")

 
    if debug:  print("<p>DEBUGGING:  environ is {}</p>".format(os.environ))
    key='HTTP_HOST'
    if key in os.environ:
        if 'heasarcdev' not in os.environ[key]:
            if debug:  print("<p>DEBUGGING:  {} is {};  trying to reset the HTTP proxies to 128.183.17.248:443</p>".format(key,os.environ[key]))
            os.environ.update({"HTTPS_PROXY":"128.183.17.248:443","HTTP_PROXY":"128.183.17.248:443"})
        else:
            if debug:  print("<p>DEBUGGING:  {} is {};  NOT trying to reset the HTTP proxies</p>".format(key,os.environ[key]))
    sys.stdout.flush()

    if debug:  
        print("<p>DEBUG: trying to import astroquery.mast.Catalogs</p>")
        print("<p>{} DEBUG: HOME dir is currently {}</p>".format(datetime.datetime.now(),os.environ['HOME']))
        print("<p>{} DEBUG: HTTP_HOST is currently {}</p>".format(datetime.datetime.now(),os.environ['HTTP_HOST']))
        sys.stdout.flush()
    try:
        from astroquery.mast import Catalogs
    except Exception as e:
        print("<p>{} ERROR:  failed to import astroquery.mast.Catalogs():  {}</p>".format(datetime.datetime.now(),e))
        sys.stdout.flush()
        raise
    if debug:  print("<p>{} DEBUG:  Successfully imported astroquery.mast.Catalogs.</p>".format(datetime.datetime.now()))
    if debug:  
        import inspect,astroquery
        print("<p>DEBUG:  my astroquery is version {} at {}</p>".format(astroquery.__version__,inspect.getfile(astroquery)))
    sys.stdout.flush()

    if debug:  print("<p>DEBUGGING:  Calling query_criteria</p>")
    sys.stdout.flush()

    try:              
        catalogData = Catalogs.query_criteria(catalog="Tic", ID=entry)
    except Exception as e:
        #print("<p>ERROR:  astroquery.mast.Catalogs() error {} for string {}</p>".format(e,escape(entry,quote=True)))
        print("<p>ERROR:  astroquery.mast.Catalogs() error {} for string {}</p>".format(e,entry))
        raise
    if debug:  print("<p>DEBUGGING:  this Tic ID gives ra,dec={},{}</p>".format( catalogData['ra'][0], catalogData['dec'][0] ))
    sys.stdout.flush()

    return entry, catalogData['ra'][0], catalogData['dec'][0]
    

def name_resolver(entry):
    #  Do some security checks:
    #from .coordconvert import ra2decimal, dec2decimal
    #from cgi import escape
    pattern=r"^[\w\d\s\*_\+-]*$"
    if not re.match(pattern ,entry):
        print("Content-type:text/html\n\n<p><font color=red>Illegal characters found in string. </font></p>")
        exit(-1)
        return entry, None,None

    if debug:  print("<p>DEBUGGING:  trying to call try_simbad_ned()</p>")
    result=try_simbad_ned(entry,simbad=True)
    if result is None:
        if debug:  print("<p>DEBUGGING:  Nothing from SIMBAD;  calling NED with warnings disabled.</p>\n")
        result=try_simbad_ned(entry,ned=True)

    if result is None:  
        #if debug:  print("<p>ERROR:  Didn't find a match in SIMBAD or NED with this string:  '{}'</p>\n".format(escape(entry,quote=True)))
        if debug:  print("<p>ERROR:  Didn't find a match in SIMBAD or NED with this string:  '{}'</p>\n".format(entry))
        return entry, None, None
    else:
        if len(result) > 1:  print("Content-type:text/html\n\n<p><font color=red>WARNING:  Multiple matches found.  Using only the first.</font></p>\n")
        if 'RA' in result.colnames:
            [h,m,s]=[float(i) for i in result['RA'][0].split()]
            if debug:  print("<p>DEBUGGING:  Simbad returned (RA,DEC)=('{}','{}')</p>\n".format(result['RA'],result['DEC']))
            RA=ra2decimal(h,m,s)
            [d,m,s]=[float(i) for i in result['DEC'][0].split()]
            DEC=dec2decimal(d,m,s)
        elif 'RA(deg)' in result.colnames:
            RA=float(result['RA(deg)'][0])
            DEC=float(result['DEC(deg)'][0])
            
        return entry,RA,DEC

    return entry,None,None




def try_simbad_ned(entry,simbad=False,ned=False):
    """Wrapper for SIMBAD and NED queries from astroquery.

    The error handling is different for the two in the case that the
    source name isn't found.  Simbad.query_object() issues a warning.
    Ned.query_object() issues an exception.
    """

    import warnings

    if "GATEWAY_INTERFACE" in os.environ:
        import __main__
        homedir=os.path.abspath(os.path.join(os.path.dirname(__main__.__file__),'../tmp/'))
        ## #  To make astropy work from w/in Apache?  XDG variables don't work.
        os.environ.update({
            #  This doesn't seem to work
            'XDG_CONFIG_HOME': os.path.abspath(os.path.join(os.path.dirname(__main__.__file__),'../','install/var/astropyconfig')),
            'XDG_CACHE_HOME': os.path.abspath(os.path.join(os.path.dirname(__main__.__file__),'../','install/var/astropycache')),
            'HOME': homedir
        } )
        if not (os.path.isdir(homedir) or os.path.islink(homedir)):  
            if debug:  print("<p>Trying to make homedir {}</p>".format(homedir))
            try:
                os.mkdir(homedir)
            except Exception as e:
                print("<p><font color=red>ERROR:  Failed to make homedir with exception {}</font></e>".format(e))
                return None

    homedir=os.environ["HOME"]

    if debug:  
        print("<p>Homedir is {} with contents:".format(homedir))
        print(os.listdir(homedir))
        print("</p>\n")

    if debug:  
        print("<p>DEBUG: trying to import astroquery functions</p>")
        print("<p>DEBUG: HOME dir is currently {}</p>".format(os.environ['HOME']))
    try:
        from astroquery.simbad import Simbad
    except Exception as e:
        print("<p><font color=red>ERROR:  Cannot import astroquery.simbad:  {}</font></p>".format(e))
        if debug:  
            print("<p>Homedir is {} with contents:".format(homedir))
            print(os.listdir(homedir))
            print("</p>\n")
        return None
    if debug:  print("<p>DEBUGGING:  successfully imported astroquery.simbad.Simbad</p>")
    try:
        from astroquery.ned import Ned
    except Exception as e:
        print("<p><font color=red>ERROR:  Cannot import astroquery.ned:  {}</font></p>".format(e))
        if debug:  
            print("<p>Homedir is {} with contents:".format(homedir))
            print(os.listdir(homedir))
            print("</p>\n")
        return None


    if simbad:  interpreter="SIMBAD"
    else: interpreter="NED"
    try:
        if debug:  print("<p>DEBUGGING:  Calling {} with warnings disabled.</p>\n".format(interpreter))
        with warnings.catch_warnings():
            warnings.simplefilter("ignore")
            if simbad:  result= Simbad.query_object(entry)
            else:  result= Ned.query_object(entry)
    except Exception as e:
        if debug:  print("<p><font color=red>ERROR: {} gives exception {}, with message:  '{}'</p></font>".format(interpreter,e.__class__.__name__,e))
        if e.__class__.__name__=='RemoteServiceError':
            if debug:  print("<p>DEBUGGING:  got RemoteServiceError that usually means NED didn't find '{}';  returning None.</p>\n".format(entry))
            return None
        raise 

    if debug and "GATEWAY_INTERFACE" in os.environ:  
        print("<p><font color=blue>Homedir is {} with contents:</font><br>".format(homedir))
        #print(os.listdir(homedir))
        for root, subdirs, files in os.walk(homedir,topdown=True):
            for f in files:  
                print("{} :: {} <font color=blue>({} B)</font><br>\n".format( ( time.ctime(os.path.getmtime(os.path.join(root,f))) ,os.path.join(root,f), os.stat(os.path.join(root,f)).st_size ) ))
        print("</p>\n")

    if debug:  
        print("<p>DEBUGGING:  Trying to clean up HOME/.astropy dir with contents: </p>")
        print(os.listdir(homedir))

    try:
        import shutil
        shutil.rmtree(os.path.join(os.environ['HOME'],'.astropy'))
    except Exception as e2:
        print("<p><font color=red>ERROR: got exception {} trying to clean up astroquery cache, with message:  '{}'</font></p>".format(e2.__class__.__name__,e2))
        return None

    return result



def process_infile(infile):
    """Prints out summary information for an input CSV file list of sources"""

    ra,dec,bad=parse_input(infile)
    full_outlst=view_list(ra,dec)
    num_cycles = int(len(full_outlst[:][0])/13)
    # Print summary info per sector
    for ncycle in range(num_cycles-1,-1,-1):
        cycle=ncycle+1 #  ncycle starts from zero for arrays
        radecs=full_outlst[:,0:2]
        sectors=full_outlst[:,2+ncycle*13:2+cycle*13]
        outlst=np.concatenate( (radecs,sectors), axis=1)
        dates=get_sector_dates(cycle=cycle)
        observations, sectors, cameras = summarize_list(outlst,ncycle=ncycle)
        summarize_simple(observations,sectors,cameras,ncycle=ncycle)
    print("\n(Feel free to write to the helpdesk to suggest other useful stats!)\n")
    # Write full results to CSV
#    with open("wtv-{}".format(infile),'w') as outfile:
#        for row in 



def tvguide_main():
    """ Main for command-line version, with argument parsing, then calling root functions"""

    import argparse,sys
    parser = argparse.ArgumentParser()
    parser.add_argument("--source",type=str,default=None,help="Input a single source")
    parser.add_argument("--infile",type=str,default=None,help="Input a csv file of sources")
    parser.add_argument("--outfile",type=str,default=None,help="Output a csv file of sources")

    args = parser.parse_args()

    if args.source is not None:
        inName, inRA, inDEC = parse_NameRaDec(args.source)
        args=Namespace(ra=[float(inRA)],dec=[float(inDEC)])
        try:
            outlst=view(args.ra[0],args.dec[0],quiet=False)
        except Exception as e:
            print("ERROR:  tvguide's view() encountered an error:   '{}'".format(e)) 

    elif args.infile is not None:  
        process_infile(args.infile)

    else:
        print("USAGE:  tvguide [--source=] [--infile=]\n\nwhere the source string can be\n  - a name (e.g., 'Cyg X-1'), \n  - a pair of (RA,DEC) coordinates in decimal, (e.g., '101.295, -16.699'), \n  - a pair of (RA,DEC) coordinates in sexagesimal (e.g., '6 45 10.8, -16 41 58'), \n  - or a TIC ID (e.g., '268644785').\n\nor an input file consisting of a CSV file with RA,DEC pairs.\n")

    return



