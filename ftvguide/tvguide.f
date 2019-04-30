*+TVGIODE
        Program TVGUIDE

        implicit none

*       Provisional name for a provisional program that provides
*       information about TESS visibility of potential targets

*-TVGUIDE

        integer n_sect, n_cycle, n_camera, n_opt
        character*12 v_string
*       There are 13 sectors per cycle
        parameter( n_sect = 13 )
*       There are 2 cycles recognized by this version of TVGUIDE
        parameter( n_cycle = 2 )
*       There are 4 cameras on-board TESS
        parameter( n_camera = 4 )
*       Up to 32 missions allowed
        parameter( n_opt = 3 )
*       Version number string
        parameter( v_string = 'Version 1.2' )

        character*255 cline
        character*10 ra_string
        character*9 dec_string
        character*80 in_buffer
        character*64 star
        logical do_prec, termin, termout
        integer in_unit, out_unit
        integer n_obj, len
	integer status, flag
	integer totint, intvls( 26 ), flags( 26 )
	real equinox
	double precision mid_jd
        double precision in_ra, in_dec, alpha, delta, dequinox
        double precision lambda, beta, lambda_, beta0, lambda0

        integer JULIAN, LENTRIM
        character*3 MN_NAME

	double precision c_elon( n_sect )
	double precision betas( n_cycle, n_camera )
	double precision jd2000, jds( n_cycle )
	double precision c1limit, c1gap, c2limit, c2gap
	double precision edge, corner, gapx, gapy
	double precision locx( 3 ), locy( 3 )
	character*26 sd_strng( n_cycle, n_sect )
	common / TVG_BL / c_elon, betas, jd2000, jds
	common / TVG_GM / c1limit, c1gap, c2limit, c2gap,
     &                           edge, corner, gapx, gapy, locx, locy
        common / TVG_SS / sd_strng

        character*16 names( n_opt )
        integer types( n_opt )
        character*64 prompts( n_opt )
        character*64 values( n_opt )
        character*64 blank

        data names / 'equinox', 'input', 'output' /
        data types / 1, 1, 1 /
        data prompts / ' ', ' ', ' ' /
        data blank / ' ' /

*       Initialize (currently for cycles 1 and 2, no more arguments needed)
	call TVG_INIT( )

*       Get the command line argument
        call ARKGCL( cline )

*       Did it just say "help"?
        if( cline .eq. 'help' .or. cline .eq. '-help'
     &             .or. cline .eq. 'HELP' .or. cline .eq. '-HELP'
     &                                        .or. cline .eq. '?' ) then
          call PWRITE( 'USAGE: TVGide [equinox=year]' //
     &                               ' [input=<file>] [output=<file>]' )
          call PWRITE( ' ' )
          goto 900
        end if

*       If not, sort out what was specified
        call DCD_ARG( cline, names, types, prompts, n_opt,
     &                                                  values, status )

        if( status .lt. 0 ) then
          call PWRITE( 'Error decoding the command line arguments' )
          goto 900
        end if

*       Arg 1 should be the equinox of the coordinates
        if( values( 1 ) .eq. ' ' ) then
*         Use default
          dequinox = 2.00D+03
          do_prec = .false.
        else
          call RD_REAL( values( 1 ), equinox, flag )
          if( flag .lt. 0 ) then
            call PWRITE( 'Error reading equinox' )
            goto 900
          end if
          dequinox = DBLE( equinox )
          if( abs( dequinox - 2.00D+03 ) .gt. 5.0D-01 ) then
            do_prec = .true.
          else
            do_prec = .false.
          end if
        end if

*       Arg 2 is the input file (a list of targets)
        if( values( 2 ) .eq. ' ' ) then
          termin = .true.
        else
          termin = .false.
          call ARKOPN( in_unit, ' ', values( 2 ), 'lst', 'OLD',
     &                  'READONLY', 'FORMATTED', 'SEQUENTIAL', 1, flag )
          if( flag .ne. 0 ) then
            call PWRITE( 'Error: failed to open input file' )
            goto 900
          end if
        end if

*       Arg 3 is the output file name
        if( values( 3 ) .eq. ' ' ) then
	  termout = .true.
          out_unit = 6
        else
	  termout = .false.
          call ARKOPN( out_unit, ' ', values( 3 ), 'lst', 'NEW',
     &                 'OVERWRITE', 'FORMATTED', 'SEQUENTIAL', 1, flag )
          if( flag .ne. 0 ) then
            call PWRITE( 'Error: failed to open output file' )
            goto 900
          end if
        end if

*       Now produce some preliminary output
        if( termout ) then
          write( out_unit, 300 ) v_string
 300      format( ' *** TESS Viewing Guide ', a, 'for Cycles 1/2 ***' )
          if( .not. termin ) then
            len = LENTRIM( values( 2 ) )
            write( out_unit, 304 ) values( 2 )( : len )
 304        format( '     list of targets taken from ', a )
          end if
          write( out_unit, 305 ) dequinox
 305      format( '     input positions are taken to be for equinox ',
     &                                                            f6.1 )
        end if

        n_obj = 0
        do while( .true. )
*         Loop over stars
          if( termin ) then
            star = 'Coordinates input from terminal'
            call WRITEN(
     &            'Enter RA (hh mm [ss.s] or dd.ddd) [<CR> to end] > ' )
            read( *, '(a)', end = 800 ) in_buffer
            if( in_buffer .eq. ' ' ) goto 800
            call RD_ASTRO( in_buffer, 'R', in_ra, flag )
            if( flag .ne. 0 ) then
              call PWRITE( 'Error in RA --- try again' )
              goto 700
            end if
            call WT_ASTRO( in_ra, +7, ra_string, flag )
            call WRITEN( 'Enter Dec ([s]dd mm [ss.s] or [s]dd.ddd) > ' )
            read '(a)', in_buffer
            call RD_ASTRO( in_buffer, 'D', in_dec, flag )
            if( flag .ne. 0 ) then
              call PWRITE( 'Error in Dec --- try again' )
              goto 700
            end if
            call WT_ASTRO( in_dec, -6, dec_string, flag )
            n_obj = n_obj + 1
            write( out_unit,
     &        '('' * Object #'',I5,'' at ('',A,'', '',A,''):'')' )
     &                                    n_obj, ra_string, dec_string
          else
            read( in_unit, '(a)', end = 800 ) star
            read( in_unit, '(a)', end = 800 ) in_buffer
            call RD_ASTRO( in_buffer, 'R', in_ra, flag )
            if( flag .ne. 0 ) then
              call PWRITE( 'Error in RA --- aborting' )
              goto 800
            end if
            call WT_ASTRO( in_ra, +7, ra_string, flag )
            read( in_unit, '(a)', end = 800 ) in_buffer
            call RD_ASTRO( in_buffer, 'D', in_dec, flag )
            if( flag .ne. 0 ) then
              call PWRITE( 'Error in Dec --- aborting' )
              goto 800
            end if
            call WT_ASTRO( in_dec, -6, dec_string, flag )
            len = LENTRIM( star )
          end if

          if( do_prec ) then
*           Display coordinates precessed to J2000 for convenience
            call ARK_PREC( in_ra, in_dec, dequinox,
     &                                            jd2000, alpha, delta )
            call WT_ASTRO( alpha, +7, ra_string, flag )
            call WT_ASTRO( delta, -6, dec_string, flag )
          if( termout ) then
              write( out_unit,
     &             '(''   [J2000 coordinates: ('',a,'','',a,'')]'')' )
     &                                             ra_string, dec_string
          end if
          else
            alpha = in_ra
	    delta = in_dec
          end if

          call TVG_CALC( termout, alpha, delta, intvls, flags, totint )
	  
          if( .not. termout ) then
	     write( out_unit, 600 ) totint, star( : len ), intvls
 600	     format( i2, ' ', a, 26( ' ', i1 ) )
          end if
*         Rejoin here if error found during interactive input
 700      continue
        end do

*       Rejoin here at <CR>/EOF
c       <EOF> or equivalent detected
 800    continue
        if( .not. termin ) then
          close( in_unit )
        end if
        if( out_unit .ne. 6 ) then
          close( out_unit )
        end if

 900    continue

        end
