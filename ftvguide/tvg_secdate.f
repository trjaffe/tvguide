*+TVG_SECDATE
        subroutine TVG_SECDATE( cycle, sector, out_strng )

        implicit none

        integer cycle, sector
	character*26 out_strng

*       Description
*         Given the cycle and sector numbers, this routine returns
*         the date range of the sector as a string.
*
*       Arguments:
*         cycle     (i) : cycle number 1/2
*         sector    (i) : cycle number 1-13
*         out_strng (o) : Sector date in the form of a string
*
*       Dependencies:
*         TVG_INIT should have set all the common blocks
*
*       Origin:
*         Conceived by KM for interface with TJ's Python tool
*
*       Author:
*         Koji Mukai, 2018 Aug 7, original version
*-TVG_SECDATE

*       There are 13 sectors per cycle
	integer n_cycle, n_sect
	parameter( n_cycle = 2 )
        parameter( n_sect = 13 )

	character*26 sd_strng( n_cycle, n_sect )
        common / TVG_SS / sd_strng

        out_strng = sd_strng( cycle, sector )

        end
