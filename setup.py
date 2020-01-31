#!/usr/bin/env python

from numpy.distutils.core import setup, Extension


# Define the Fortran extension.
viewf = Extension(name="viewf",
                    sources=["ftvguide/cartesian.f",
                             "ftvguide/dcd_arg.f",
                             "ftvguide/dcd_dthm.f",
                             "ftvguide/eclip.f",
                             "ftvguide/getlun.f",
                             "ftvguide/julian.f",
                             "ftvguide/lentrim.f",
                             "ftvguide/nutate.f",
                             "ftvguide/perigee.inc",
                             "ftvguide/prec.f",
                             "ftvguide/rd_astro.f",
                             "ftvguide/rd_real.f",
                             "ftvguide/sunpos.f",
                             "ftvguide/sys.f",
                             "ftvguide/tvg_calc.f",
                             "ftvguide/tvg_init.f",
                             #"ftvguide/tvgtgt.f", # Don't want this one I think?
                             "ftvguide/upcase.f",
                             "ftvguide/wt_astro.f",
                             "ftvguide/tvguide.inc",
                             "ftvguide/tvg_secdate.f",
                             "ftvguide/view.f",
                             "ftvguide/viewf.pyf"  # The extension module created myself with "f2py -m viewf -h viewf.pyf view.f"  
                    ])


# Tell it to use all the files found in the directory
files=['*']

if __name__ == "__main__":
    setup(name = 'tvguide',
          version="0.9.1",
          download_url = "https://github.com/trjaffe/tvguide/archive/v_091.tar.gz",
          description       = "TESS Viewing Guide",
          author            = "T. R. Jaffe",
          author_email      = "trjaffe@gmail.com",
          entry_points      ={'console_scripts':['tvguide=tvguide.command_line:main']},
          packages          =["tvguide"],
          ext_modules       =[viewf],
          data_files        =[('data',['data/tvgprecalc.dat'])]
    )

