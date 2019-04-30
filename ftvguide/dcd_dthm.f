*+DCD_DTHM
        subroutine DCD_DTHM( string, year, month, day, hh, mm, status )

        implicit none

        character*(*) string
        integer year, month, day
        integer hh,mm
        integer status

*       Description
*         This routine decodes a string of the form yyyy-MMM-ddThh:mm
*         and puts the results into integer variables year, month and day,
*         hh, and mm.
*
*       Arguments:
*         string    (i) : Input string
*         year      (o) : Year, full 4 digits
*         month     (o) : Month
*         day       (o) : Day, after some sanity check
*         hh        (o) : hour
*         mm        (o) : minute
*         status    (o) : 0 if no errors were detected
*
*       Dependencies:
*         LOCASE, a XANLIB clone (in upcase.f), for case conversion.
*
*       Origin:
*         Conceived by KM for user interface of TVGuide
*
*       Author:
*         Koji Mukai, 2018 Jun 22, original version
*-DCD_DTHM

        character*32 buffer
        integer length, kstart, k, m, labour
        character one

        integer LENTRIM

        character*9 mnname( 12 )
        integer mnlimt( 12 )
        data mnname / 'january', 'february', 'march', 'april', 'may',
     &                'june', 'july', 'august', 'september',
     &                'october', 'november', 'december' /
        data mnlimt / 31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 /

        status = 0

        length = LENTRIM( string )
        if( length .gt. 32 ) then
          status = -99
*         the string appears to be too long
          goto 900
        else
          buffer = string( : length )
        end if
        call LOCASE( buffer )

        k = 1
        do while( buffer( k: k ) .le. ' ' .and. k .le. length )
          k = k + 1
        end do
        if( k .eq. length ) then
*         string was empty
          status = -1
          goto 900
        end if

        kstart = k
        do while( k .le. length )
          one = buffer( k: k )
          if( one .lt. '0' .or. one .gt. '9' ) goto 110
          k = k + 1
        end do
*       string consisted entirely of digits
        status = -2
        goto 900

 110    continue
*       Found the first non-digit character --- read the first integer
        call DD_PCKUP( buffer, kstart, k, labour, status )
        if( status .lt. 0 ) goto 900
        if( one .ne. '-' ) then
*         Unexpected format
	  status = -99
	  goto 900
	end if
*	Okay, now assume yyyy-MMM-dd format
        if( labour .ge. 1900 ) then
          year = labour
        else
          status = -12
          goto 900
        end if
        kstart = k + 1
        k = kstart
	one = buffer( k: k )
        do while( one .ne. '-' )
          k = k + 1
	  if( k .eq. length ) then
	    status = -99
	    goto 900
          end if
          one = buffer( k: k )
        end do
*       Found the second dash - try to interpret the middle bit as month
        month = 0
        do m = 1, 12
          if( buffer( kstart: k - 1 ) .eq.
     &              mnname( m )( 1: k - kstart ) ) month = m
        end do
        if( month .eq. 0 ) then
          status = -4
          goto 900
        end if
*	Now look for the number that is the day
	kstart = k + 1
	k = kstart
	one = buffer( k: k )
	do while( one .ge. '0' .and. one .le. '9' )
	  k = k + 1
	  if( k .eq. length ) then
            status = -99
	    goto 900
	  end if
	  one = buffer( k: k )
	end do
	if( one .ne. 't' ) then
	  status = -99
	  goto 900
	end if
        call DD_PCKUP( buffer, kstart, k, day, status )
        if( day .lt. 1 .or. day .gt. mnlimt( month ) ) then
          status = -11
	  goto 900
        end if

*	Now try to read HH and MM
	kstart = k + 1
	k = kstart
	one = buffer( k: k )
	do while( one .ge. '0' .and. one .le. '9' )
	  k = k + 1
	  if( k .eq. length ) then
	    status = -99
	    goto 900
	  end if
	  one = buffer( k: k)
	end do
	if( one .ne. ':' ) then
	  status = -99
	  goto 900
	end if
        call DD_PCKUP( buffer, kstart, k, hh, status )
	if( hh .lt. 0 .or. hh .ge. 24 ) then
	  status = -12
	  goto 900
	end if
	kstart = k + 1
	k = kstart
*	should be the last item	
	do while( k .le. length )
	  one = buffer( k: k )
	  if( one .lt. '0' .or. one .gt. '9' ) then
	    status = -99
	    goto 900
	  end if
	  k = k + 1
	end do
        call DD_PCKUP( buffer, kstart, k, mm, status )
	if( mm .lt. 0 .or. mm .ge. 60 ) then
	  status = -12
	  goto 900
	end if

 900    continue

        end


*+DD_PCKUP
        subroutine DD_PCKUP( string, k1, k2, number, status )

        implicit none

        character*( * ) string
        integer k1, k2, number, status

*       Description:
*         Use internal I/O to read 1 or 2 digit numbers from string
*
*       Arguments:
*         string    (i) : Input string
*         k1, k2    (i) : Location of number within string (k1:k2-1)
*         number    (o) : The actual number read
*         status    (o) : 0 if no errors detected
*
*       Dependencies:
*         None
*
*       Origin:
*         Created by KM for internal use by DCD_DATE
*
*       Author
*         Koji Mukai, 1993 Jan 29, original version
*-DD_PCKUP

        integer k3

        k3 = k2 - 1
	
        if( k2 .eq. k1 ) then
          status = -3
        else if( k3 .eq. k1 ) then
          read( string( k1: k3 ), '(i1)' ) number
        else if( k3 .eq. k1 + 1 ) then
          read( string( k1: k3 ), '(i2)' ) number
        else if( k3 .eq. k1 + 2 ) then
          read( string( k1: k3 ), '(i3)' ) number
        else if( k3 .eq. k1 + 3 ) then
          read( string( k1: k3 ), '(i4)' ) number
        else if( k3 .eq. k1 + 4 ) then
          read( string( k1: k3 ), '(i5)' ) number
        else
          status = -3
        end if

        end
