*+CEL_CARTS
        subroutine CEL_CARTS( ra, dec, vector )

        implicit none

        double precision ra, dec
        double precision vector( 3 )

*       Description:
*         Given RA and Dec, returns the 3-d vector
*
*       Arguments:
*         ra        (i) : input RA (decimal hours)
*         dec       (i) : input Dec
*         vector    (o) : 3-d vector
*
*       Dependencies:
*         Assumes the presence of trig functions on degrees on the system
*
*       Origin:
*         Conceived as a part of the 3-d vector routines
*
*       Author:
*         Koji Mukai, 1993 Mar 15, Original version
*-CEL_CARTS

        double precision cos_dec, ra_rad, dec_rad

        double precision pi, deg2rad, rad2deg
        common / TVG_CS / pi, deg2rad, rad2deg

	dec_rad = dec * deg2rad
        cos_dec = cos( dec_rad )
        ra_rad = ra * 1.5d+01 * deg2rad
        vector( 1 ) = cos_dec * cos( ra_rad )
        vector( 2 ) = cos_dec * sin( ra_rad )
        vector( 3 ) = sin( dec_rad )

        end

*+CARTS_CEL
        subroutine CARTS_CEL( vector, ra, dec )

        implicit none

        double precision vector( 3 )
        double precision ra, dec
  
*       Description:
*         Given a 3-d vector, returns RA and Dec
*
*       Arguments:
*         vector    (i) : input 3-d vector
*         ra        (o) : output RA (decimal hours)
*         dec       (o) : output Dec
*
*       Origin:
*         Conceived as a part of the 3-d vector routines
*
*       Author:
*         Koji Mukai, 1993 Mar 15, Original version
*-CARTS_CEL

        double precision cos_dec, ra_rad, dec_rad

        double precision pi, deg2rad, rad2deg
        common / TVG_CS / pi, deg2rad, rad2deg

	dec = asin( vector( 3 ) ) * rad2deg
	if( vector( 1 ) .eq. 0.0d+00 ) then
          if( vector( 2 ) .gt. 0.0d+00 ) then
            ra = 6.0d+00
	  else
            ra = 18.0d+00
	  end if
	else if( vector( 1 ) .gt. 0.0 ) then
	  ra = atan( vector( 2 ) / vector( 1 ) ) * rad2deg / 15.0d+00
        else
	  ra = atan( vector( 2 ) / vector( 1 ) ) * rad2deg / 15.0d+00
     &                                                     + 12.0d+00
	end if
	if( ra .lt. 0.0d+00 ) then
	  ra = ra + 24.0d+00
	end if

        end

*+ECL_CARTS
        subroutine ECL_CARTS( lambda, beta, vector )

        implicit none

        double precision lambda, beta
        double precision vector( 3 )

*       Description:
*         Given ecliptic longitude and latitude, returns the 3-d vector
*
*       Arguments:
*         ra        (i) : input RA (decimal hours)
*         dec       (i) : input Dec
*         vector    (o) : 3-d vector
*
*       Dependencies:
*         Assumes the presence of trig functions on degrees on the system
*
*       Origin:
*         Conceived as a part of the 3-d vector routines
*
*       Author:
*         Koji Mukai, 1993 Mar 15, Original version
*-CEL_CARTS

        double precision cos_beta, lambda_rad, beta_rad

        double precision pi, deg2rad, rad2deg
        common / TVG_CS / pi, deg2rad, rad2deg

	beta_rad = beta * deg2rad
        cos_beta = cos( beta_rad )
        lambda_rad = lambda * deg2rad
        vector( 1 ) = cos_beta * cos( lambda_rad )
        vector( 2 ) = cos_beta * sin( lambda_rad )
        vector( 3 ) = sin( beta_rad )

        end

*+VEC_SCALR
        double precision function VEC_SCALR( vector1, vector2 )

        implicit none

        double precision vector1( 3 ), vector2( 3 )

*       Description:
*         Scalar products of two cartesian vectors
*
*       Arguments:
*         vector1, vector2 (i) : two input Cartesian vectors
*         <VEC_SCALR>      (r) : Scalar products
*
*       Dependencies:
*         Assumes the presence of trig functions on degrees on the system
*
*       Origin:
*         Conceived as a part of the 3-d vector routines
*
*       Author:
*         Koji Mukai, 2018 Jun 20, Original version
*-VEC_SCALR

        double precision inner
        integer j

        double precision pi, deg2rad, rad2deg
        common / TVG_CS / pi, deg2rad, rad2deg

        inner = 0.0d+00
        do j = 1, 3
          inner = inner + vector1( j ) * vector2( j )
        end do

	VEC_SCALR = inner

	end
	
*+VEC_ANGLE
        double precision function VEC_ANGLE( vector1, vector2 )

        implicit none

        double precision vector1( 3 ), vector2( 3 )

*       Description:
*         Angle between two cartesian vectors
*
*       Arguments:
*         vector1, vector2 (i) : two input Cartesian vectors
*         <VEC_ANGLE>      (r) : Angle between the two
*
*       Dependencies:
*         Assumes the presence of trig functions on degrees on the system
*
*       Origin:
*         Conceived as a part of the 3-d vector routines
*
*       Author:
*         Koji Mukai, 1993 Mar 15, Original version
*-VEC_ANGLE

        double precision inner, temp, work
        integer j

        double precision pi, deg2rad, rad2deg
        common / TVG_CS / pi, deg2rad, rad2deg

        inner = 0.0d+00
        do j = 1, 3
          inner = inner + vector1( j ) * vector2( j )
        end do

        if( inner .gt. 0.71d+00 ) then
*            Use sine, which is more accurate in this regime
*            Length( vector1 - vector2 ) * 0.5 = sin( angle * 0.5 )
*            (Cosine of small x is ~1.0-x^2/2, whereas sin x ~ x)
          temp = 0.0
          do j = 1, 3
            work = vector1( j ) - vector2( j )
            temp = temp + work * work
          end do
          temp = sqrt( temp ) * 0.5d+00
          VEC_ANGLE = asin( temp ) * 2.0d+00 * rad2deg
        else if( inner .ge. -0.71d+00 ) then
*            Use the more familiar cosine formula
          VEC_ANGLE = acos( inner ) * rad2deg
        else
*            Back to sine, but two vectors are ~180 degrees apart
          temp = 0.0
          do j = 1, 3
            work = vector1( j ) + vector2( j )
            temp = temp + work * work
          end do
          temp = sqrt( temp ) * 0.5d+00
          VEC_ANGLE = 1.8d+02 - asin( temp ) * 2.0d+00 * rad2deg
        end if

        end

*+VEC_PRDCT
        subroutine VEC_PRDCT( vector1, vector2, vector3 )

        implicit none

        double precision vector1( 3 ), vector2( 3 ), vector3( 3 )

*       Description:
*         Calculates product of two vectors
*
*       Arguments:
*         vector1, vector2 (i) : two input Cartesian vectors
*         vector3          (o) : product of the two input vectors
*
*       Dependencies:
*         None
*
*       Origin:
*         Conceived as a part of the 3-d vector routines
*
*       Author:
*         Koji Mukai, 1993 Mar 15, Original version
*-VEC_PRDCT

        integer i, j, k

        do i = 1, 3
          j = i + 1
          if( j .eq. 4 ) j = 1
          k = j + 1
          if( k .eq. 4 ) k = 1
          vector3( i ) = vector1( j ) * vector2( k )
     &                                - vector1( k ) * vector2( j )
        end do

        end

*+VEC_RENRM
        subroutine VEC_RENRM( vector )

        implicit none

        double precision vector( 3 )

*       Description:
*         Renormalizes a Cartesian vector
*
*       Arguments:
*         vector  (i/o) : Cartesian vector to be renormalized
*
*       Dependencies:
*         None
*
*       Origin:
*         Conceived as a part of the 3-d vector routines
*
*       Author:
*         Koji Mukai, 1993 Mar 15, Original version
*-VEC_RENRM

        double precision temp
        integer j

        temp = 0.0d+00
        do j = 1, 3
          temp = temp + vector( j ) * vector( j )
        end do
        temp = 1.0d+00 / sqrt( temp )
        do j = 1, 3
          vector( j ) = vector( j ) * temp
        end do

        end


*+VEC_FNDIR
        subroutine VEC_FNDIR( pos, dir, dir_ )

	implicit none

	double precision pos( 3 ), dir( 3 ), dir_( 3 )
	
*       Description:
*         Given a generic direction dir, find the vector dir_ that is
*         tangential to the unit sphere at position pos
*
*       Arguments:
*         pos   (i) : Cartesian position to be rotated
*         dir   (i) : Cartesian vector - local direction
*         dir_  (o) : Direction vector after twist
*
*       Dependencies:
*         None
*
*       Origin:
*         Conceived as a part of the 3-d vector routines
*
*       Author:
*         Koji Mukai, 2019 June 14, original version
*-VEC_FNDIR

	double precision third( 3 )

	call VEC_PRDCT( pos, dir, third )
	call VEC_RENRM( third )
	call VEC_PRDCT( third, pos, dir_ )
	call VEC_RENRM( dir_ )

	end


*+VEC_TWIST
        subroutine VEC_TWIST( pos, dir, angle, dir_ )

	implicit none

	double precision pos( 3 ), dir( 3 )
	double precision angle
	double precision dir_( 3 )
	
*       Description:
*         Rotates the position vector "pos" in the direction "dir" by
*         angle "angle" to arrive at "pos_"; "dir_" is the direction
*         vector at "
*
*       Arguments:
*         pos   (i) : Cartesian position to be rotated
*         dir   (i) : Cartesian vector - local direction
*         angle (i) : Scaler - angle (deg) to be twisted
*         dir_  (o) : Direction vector after twist
*
*       Dependencies:
*         None
*
*       Origin:
*         Conceived as a part of the 3-d vector routines
*
*       Author:
*         Koji Mukai, 2019 June 14, original version
*-VEC_TWIST

	double precision third( 3 )
	double precision cosan, sinan
	integer k
	
        double precision pi, deg2rad, rad2deg
        common / TVG_CS / pi, deg2rad, rad2deg

	call VEC_PRDCT( pos, dir, third )
	cosan = cos( angle * deg2rad )
	sinan = sin( angle * deg2rad )
	do k = 1, 3
	  dir_( k ) = cosan * dir( k ) + sinan * third( k )
	end do
	call VEC_RENRM( dir_ )

	end

*+VEC_ROTAT
        subroutine VEC_ROTAT( pos, dir, angle, pos_, dir_ )

        implicit none

        double precision pos( 3 ), dir( 3 )
	double precision angle
	double precision pos_( 3 ), dir_( 3 )

*       Description:
*         Rotates the position vector "pos" in the direction "dir" by
*         angle "angle" to arrive at "pos_"; "dir_" is the direction
*         vector at "
*
*       Arguments:
*         pos   (i) : Cartesian position to be rotated
*         dir   (i) : Cartesian vector - the direction of rotation;
*                     assumed to be perpendicular to pos
*         angle (i) : Scaler - angle (deg) to be rotated
*         pos_  (o) : Position vector after rotation
*         dir_  (o) : Direction vector after rotation
*
*       Dependencies:
*         None
*
*       Origin:
*         Conceived as a part of the 3-d vector routines
*
*       Author:
*         Koji Mukai, 2019 June 14, original version
*-VEC_ROTAT

	double precision cosan, sinan
	integer k
	
        double precision pi, deg2rad, rad2deg
        common / TVG_CS / pi, deg2rad, rad2deg

	cosan = cos( angle * deg2rad )
	sinan = sin( angle * deg2rad )
	do k = 1, 3
	  pos_( k ) = cosan * pos( k ) + sinan * dir( k )
	  dir_( k ) = -sinan * pos( k ) + cosan * dir( k )
	end do
	call VEC_RENRM( pos_ )
	call VEC_RENRM( dir_ )

	end
