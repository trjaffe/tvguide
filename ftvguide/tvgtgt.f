*+TVGIODE
        Program TVGUIDE

        implicit none

*       Provisional name for a provisional program that provides
*       information about TESS visibility of potential targets

*-TVGUIDE

        integer n_sect, n_opt
	double precision deg2rad, rad2deg
        character*12 v_string
*       There are 13 sectors per cycle
        parameter( n_sect = 13 )
*       Up to 32 missions allowed
        parameter( n_opt = 3 )
*       Degree to radian conversion
        parameter( deg2rad = 0.01745329252D+00 )
	parameter( rad2deg = 57.29577951D+00 )
*       Version number string
        parameter( v_string = 'Version 0.8' )

        character*255 cline
        character*10 ra_string
        character*9 dec_string
        character*80 in_buffer
        character*64 star
        character*96 out_msg
	character*17 pg_strng( 2, n_sect + 1 )
	character*26 sd_strng( 2, n_sect )
        logical do_prec, termin, termout
	integer n_c
        integer ir_lo, ir_hi
        integer flag, status, count, i, j, k
        integer lun, in_unit, out_unit
        integer n_obj, len
	integer totint, intvls( 13 )
        real lo_rang, hi_rang, avoid_moon, temp, equinox
	real dstart
	double precision c_elon( n_sect ), mid_jd
	double precision lambda1, dlambda, step
	double precision edge, corner, gapx, gapy
        double precision in_ra, in_dec, alpha, delta, dequinox, jd
	double precision lambda, beta, lambda_, beta0, lambda0
	double precision lambdas( 13 )
	double precision betas( 4 )
	double precision c1limit, c1gap, c2limit
	double precision cc( 3 ), targt( 3 ), locx( 3 ), locy( 3 )
	double precision tgt_cc( 3 ), offset, offsetx, offsety, cosoff
	double precision locxang, locyang

	double precision VEC_ANGLE
        integer JULIAN, LENTRIM
        character*3 MN_NAME

        character*16 names( n_opt )
        integer types( n_opt )
        character*64 prompts( n_opt )
        character*64 values( n_opt )
        character*64 blank

        data names / 'equinox', 'input', 'output' /
        data types / 1, 1, 1 /
        data prompts / ' ', ' ', ' ' /
        data blank / ' ' /

        include 'tvguide.inc'

        call SET_SCTR( pg_strng, n_c, n_sect, c_elon, mid_jd )
        do j = 1, n_sect
          sd_strng( 1, j ) = pg_strng( n_c, j )( :11 ) // ' to '
     &                                  // pg_strng( n_c, j + 1 )( :11 )
        end do
	
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
 300      format( ' *** TESS Viewing Guide ', a, 'for Cycle 1 ***' )
          if( .not. termin ) then
            len = LENTRIM( values( 2 ) )
            write( out_unit, 304 ) values( 2 )( : len )
 304        format( '     list of targets taken from ', a )
          end if
          write( out_unit, 305 ) dequinox
 305      format( '     input positions are taken to be for equinox ',
     &                                                            f6.1 )
        end if

        jd = dble( JULIAN( 2000, 1, 1 ) ) - 0.5D+00
	locx( 1 ) = 0.0d+00
	locx( 2 ) = 1.0d+00
	locx( 3 ) = 0.0d+00
	locy( 2 ) = 0.0d+00

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
            call ARK_PREC( in_ra, in_dec, dequinox, jd, alpha, delta )
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

          totint = 0
	  do j = 1, 13
	    intvls( j ) = 0
	  end do
*         Find the ecliptic latitude, draw some conclusions from that
          call TO_ECLIP( alpha, delta, jd, lambda, beta )
	  if( termout ) then
	    write( out_unit, 310 ) lambda, beta
 310	    format( 'Ecliptic longitude: ', f7.2, '; latitude: ', f7.2 )
          end if
	  if( beta .le. c1limit ) then
*           In the southern ecliptic hemisphere - potential Cycle 1 target
            if( beta .ge. c1gap ) then
	      if( termout ) then
                write( out_unit,
     &       '(''This target might fall in the gap between sectors'')' )
              end if
            else
	      if( termout ) then
	        write( out_unit,
     &       '(''This target should be observable during Cycle 1'')' )
              end if
            end if
*           Try with 13 sectors starting with ecliptic longitude L0+delta
            do j = 1, 13
              lambda0 = c_elon( j )
              lambda_ = lambda - lambda0
	      call ECL_CARTS( lambda_, beta, targt )
	      do k = 1, 4
	        call ECL_CARTS( 0.0d+00, betas( k ), cc )
		offset = VEC_ANGLE( targt, cc )
		cosoff = cos( offset * deg2rad )
		if( offset .le. corner ) then
		  do i = 1, 3
		    tgt_cc( i ) = targt( i ) / cosoff - cc( i )
		  end do
* 		  Get the angle between cc and targt
*		  but what I really care is the angle between tgt_cc
*		  projected along locx/locy an
                  call VEC_RENRM( tgt_cc )
		  beta0 = betas( k ) * deg2rad
		  locy( 1 ) = -sin( beta0 )
		  locy( 3 ) = cos( beta0 )
		  locxang = VEC_ANGLE( tgt_cc, locx ) * deg2rad
		  locyang = VEC_ANGLE( tgt_cc, locy )
                  offsetx = offset * cos( locxang )
		  if( locyang .le. 90.0 ) then
		    offsety = offset * sin( locxang )
		  else
		    offsety = -offset * sin( locxang )
		  end if
		  if( abs( offsetx ) .le. edge
     &                             .and. abs( offsety ) .le. edge ) then
                    if( termout ) then
		      write( out_unit, 400 )
     &                          j, sd_strng( 1, j ), k, offsetx, offsety
 400		      format( 'in sector ', i2, ' (', a, ') camera ',
     &                    i1, ' at offsets of (', f6.2, ',', f6.2, ')' )
                    end if
                    if( abs( offsetx ) .le. gapx
     &                              .or. abs( offsety ) .le. gapy ) then
                      if( termout ) then
		        write( out_unit, 401 )
 401			format( 'Except it may be in the chip gap' )
		      end if
		    else
		      intvls( j ) = k
		      totint = totint + 1
		    end if
		  end if
		end if
              end do
            end do

          else if( beta .gt. c2limit ) then
	    if( termout ) then
              write( out_unit,
     &             '(''This target may be observed during Cycle 2'')' )
            end if
          else
	    if( termout ) then
              write( out_unit,
     &     '(''This target cannot be observed during Cycle 1 or 2'')' )
            end if
          end if

          if( .not. termout ) then
	     write( out_unit, 600 ) totint, star( : len ), intvls
 600	     format( i2, ' ', a, 13( ' ', i1 ) )	     
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
