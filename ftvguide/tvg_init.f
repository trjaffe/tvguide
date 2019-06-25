*+TVG_INIT
        subroutine TVG_INIT( )

        implicit none

        integer cycle

*       Description
*         This routine initializes common block variables; it also takes
*         a series of perigee times in string form (yyyy-MMM-ddThh:mm),
*         and calculates the ecliptic longitude of the anti-sun direction
*         for the mid-point of each sector. The revised version does not
*         take an argument, and (for now) initializes for Cycles 1 & 2
*
*       Arguments:
*         cycle     (i) : cycle number 1/2
*         c_elon    (o) : Ecliptic longitude of the sectors
*
*       Dependencies:
*         DCD_DTHM, a special-purpose version to decode the date string
*         JULIAN and SUN_ELONG, practical astronomy routines
*
*       Origin:
*         Conceived by KM for user interface of TVGuide
*
*       Author:
*         Koji Mukai, 2018 Jul 5, original version
*         Koji Mukai, 2018 Nov 26, revised version
*-TVG_INIT

*       There are 13 sectors per cycle
        integer n_cycle, m_sect, n_camera
        double precision oneeighty, sixty, twentyfour, two, half, zero
	parameter( n_cycle = 2 )
        parameter( m_sect = 13 )
	parameter( n_camera = 4 )
        parameter( oneeighty = 1.80d+02 )
        parameter( sixty = 6.0d+01 )
        parameter( twentyfour = 2.4d+01 )
        parameter( two = 2.0d+00 )
        parameter( half = 5.0d-01 )
        parameter( zero = 0.0d-00 )

	character*17 pg_strng( n_cycle, 0: m_sect )
        integer year, month, day, hh, mm, status, j, n_c
        double precision pg_jd( 0: m_sect )
	double precision mid_jd, jd_date, dphh, sun_elon
	double precision al, del, pal, pdel, beta
	integer JULIAN
	double precision SUN_ELONG

	integer n_sects( n_cycle )
	character*26 sd_strng( n_cycle, m_sect )
	double precision c_elon( n_cycle, m_sect )
	double precision d_beta( n_camera )
	double precision f_beta( n_cycle, m_sect )
	double precision d2c4( n_cycle, m_sect )
	double precision jd2000, jds( n_cycle )
	double precision c1limit, c1gap, c2limit, c2gap
	double precision edge, corner, gapx, gapy
	double precision orgnorth( 3 )
	double precision pi, deg2rad, rad2deg
        common / TVG_SS / n_sects, sd_strng
	common / TVG_BL / c_elon, d_beta, f_beta, d2c4, jd2000, jds
	common / TVG_GM / c1limit, c1gap, c2limit, c2gap,
     &                                edge, corner, gapx, gapy, orgnorth
        common / TVG_CS / pi, deg2rad, rad2deg

	include 'tvguide.inc'

        pi = 3.14159265358979323846264338328d+00
        deg2rad = 1.74532925199432954737168d-02
	rad2deg = 1.0d+00 / deg2rad
        jd2000 = dble( JULIAN( 2000, 1, 1 ) ) - 0.5D+00
	orgnorth( 1 ) = 0.0d+00
	orgnorth( 2 ) = 0.0d+00
	orgnorth( 3 ) = 1.0d+00

        do cycle = 1, n_cycle
          do j = 0, n_sects( cycle )
            call DCD_DTHM( pg_strng( cycle, j ),
     &                                year, month, day, hh, mm, status )
            if( status .ne. 0 ) then
              print *, 'Error decoding perigee date/time'
              stop
            end if
            jd_date = dble( JULIAN( year, month, day ) ) - half
            dphh = dble( hh ) + dble( mm ) / sixty
            pg_jd( j ) = jd_date + dphh / twentyfour
	  end do

          do j = 1, n_sects( cycle )
            mid_jd = ( pg_jd( j - 1 ) + pg_jd( j ) ) * half
*           For now, apply the 5-hr offset to all sectors in Cycle 1
c	    mid_jd = mid_jd - 5.0d+00 / twentyfour
c	    mid_jd = mid_jd - 6.4d+00 / twentyfour
            sun_elon = SUN_ELONG( mid_jd )
	    call FM_ECLIP( sun_elon, zero, jd2000, al, del )
	    call ARK_PREC( al, del, 2.019d+03, jd2000, pal, pdel )
	    call TO_ECLIP( pal, pdel, jd2000, sun_elon, beta )
            if( sun_elon .gt. oneeighty ) then
              c_elon( cycle, j ) = sun_elon - oneeighty
            else
              c_elon( cycle, j ) = sun_elon + oneeighty
            end if
c            call FM_ECLIP( c_elon( cycle, j ), zero, mid_jd, ra, dec )
          end do

          do j = 1, n_sects( cycle )
            sd_strng( cycle, j ) = pg_strng( cycle, j - 1 )( :11 )
     &                          // ' to ' // pg_strng( cycle, j )( :11 )
          end do
          jds( cycle ) = ( pg_jd( 0 ) + pg_jd( n_sects( cycle ) ) )
     &                                                            * half

	end do

        end
