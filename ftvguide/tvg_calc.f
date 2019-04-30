*+TVG_CALC
        subroutine TVG_CALC
     &                  ( termout, alpha, delta, intvls, flags, totint )

        implicit none
	
        integer n_cycle, n_sect, n_camera
	parameter( n_cycle = 2 )
        parameter( n_sect = 13 )
	parameter( n_camera = 4 )

	logical termout
	double precision alpha, delta
	integer intvls( 26 ), flags( 26 ), totint
	
*       Description
*         This routine does the actual calculations for a single object
*         of which, if any, sector/camera combination will it be in.
*         If termout is .true., it provides screen outputs along the way
*
*       Arguments:
*         termout   (i) : output to terminal (true/false)
*         alpha     (i) : RA in decimal hours
*         delta     (i) : Dec in decimal degree
*         intvls    (o) : If observable in that sector, camera number
*         flags     (o) : Array of flags, such as too close to the edge
*         totint    (o) : Total number of sectors it can be observed
*
*       Dependencies:
*         ECL_CARTS and VEC_RENRM, Cartesian vector routines
*
*       Origin:
*         Conceived by KM for user interface of TVGuide
*
*       Author:
*         Koji Mukai, 2018 Jul 6, original version
*         Koji Mukai, 2018 Nov 27, multi-cycle version
*-TVG_CALC

	logical dothis( n_cycle )
        integer cycle, off_sect
        integer i, j, jj, k
	double precision lambda, beta, lambda0, lambda_
	double precision d2000, alpnow, dltnow
	double precision offset, cosoff, beta0, locxang, locyang
	double precision offsetx, offsety
	double precision targt( 3 ), cc( 3 ), tgt_cc( 3 )
	double precision VEC_ANGLE
	
	double precision c_elon( n_cycle, n_sect )
	double precision betas( n_cycle, n_camera )
	double precision jd2000, jds( n_cycle )
	double precision c1limit, c1gap, c2limit, c2gap
	double precision edge, corner, gapx, gapy
	double precision locx( 3 ), locy( 3 )
	double precision pi, deg2rad, rad2deg
	character*26 sd_strng( n_cycle, n_sect )
	common / TVG_BL / c_elon, betas, jd2000, jds
	common / TVG_GM / c1limit, c1gap, c2limit, c2gap,
     &                           edge, corner, gapx, gapy, locx, locy
        common / TVG_CS / pi, deg2rad, rad2deg
        common / TVG_SS / sd_strng

	d2000 = 2.0d+03
*       Find the ecliptic latitude, draw some conclusions from that
	call TO_ECLIP( alpha, delta, jd2000, lambda, beta )
*       Using J2000 coordinates and jd2000 seems to work
*       Precessing to current date and then converting to ecliptic
*       seems to introduce numerical inaccuracies (check)
c       call ARK_PREC
c     &             ( alpha, delta, d2000, jds( cycle ), alpnow, dltnow )
c       call TO_ECLIP( alpnow, dltnow, jds( cycle ), lambda, beta )
	if( termout ) then
	  write( *, 310 ) lambda, beta
 310	  format( 'Ecliptic longitude: ', f7.2, '; latitude: ', f7.2 )
        end if
	
	if( beta .le. c1limit ) then
*         In the southern ecliptic hemisphere - potential Cycle 1 target
          dothis( 1 ) = .true.
	  dothis( 2 ) = .false.
          if( beta .ge. c1gap ) then
	    if( termout ) then
              write( *,
     &       '(''This target might fall in the gap between sectors'')' )
              end if
          else
	    if( termout ) then
	      write( *,
     &       '(''This target should be observable during Cycle 1'')' )
            end if
          end if
	else if( beta .ge. c2limit ) then
*         In the northeern ecliptic hemisphere - potential Cycle 2 target
          dothis( 1 ) = .false.
	  dothis( 2 ) = .true.
          if( beta .le. c2gap ) then
	    if( termout ) then
              write( *,
     &       '(''This target might fall in the gap between sectors'')' )
                end if
          else
	    if( termout ) then
	      write( *,
     &       '(''This target should be observable during Cycle 2'')' )
            end if
          end if
        else
          dothis( 1 ) = .false.
	  dothis( 2 ) = .false.
	  if( termout ) then
            write( *,
     &     '(''This target cannot be observed during Cycle 1 or 2'')' )
          end if
	end if

        totint = 0
	do cycle = 1, n_cycle
	  off_sect = n_sect * ( cycle - 1 )
          do j = 1, n_sect
	    jj = off_sect + j
	    intvls( jj ) = 0
	    flags( jj ) = 0
	  end do
	  if( dothis( cycle ) ) then
*           Try with 13 sectors starting with ecliptic longitude L0+delta
            do j = 1, n_sect
	      jj = off_sect + j
              lambda0 = c_elon( cycle, j )
              lambda_ = lambda - lambda0
	      call ECL_CARTS( lambda_, beta, targt )
	      do k = 1, n_camera
	        call ECL_CARTS( 0.0d+00, betas( cycle, k ), cc )

	        offset = VEC_ANGLE( targt, cc )
	        cosoff = cos( offset * deg2rad )
	        if( offset .le. corner ) then
	          do i = 1, 3
	            tgt_cc( i ) = targt( i ) / cosoff - cc( i )
	          end do
* 	          Get the angle between cc and targt
*	          but what I really care is the angle between tgt_cc
*	          projected along locx/locy an
                  call VEC_RENRM( tgt_cc )
	          beta0 = betas( cycle, k ) * deg2rad
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
	              write( *, 400 )
     &                     jj, sd_strng( cycle, j ), k, offsetx, offsety
 400	              format( 'in sector ', i2, ' (', a, ') camera ',
     &                    i1, ' at offsets of (', f6.2, ',', f6.2, ')' )
                    end if
                    if( abs( offsetx ) .le. gapx
     &                              .or. abs( offsety ) .le. gapy ) then
                      if( termout ) then
	                write( *, 401 )
 401	                format( 'Except it may be in the chip gap' )
		      end if
		    else
		      intvls( jj ) = k
		      totint = totint + 1
		    end if
		  end if
                end if
              end do
            end do
          end if
	end do
	
        end
	