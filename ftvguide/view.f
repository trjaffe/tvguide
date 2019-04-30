C
C  If you edit this file in a way that changes the interface, then run 
C     f2py --overwrite-signature -m viewf -h viewf.pyf view.f
C
C FILE: VIEW.F
      SUBROUTINE VIEWF(INTVLS, ALPHA, DELTA)
C
C     Trivial wrapper to Koji's functions:  
C
      DOUBLE PRECISION ALPHA, DELTA
      INTEGER TOTINT, INTVLS( 26 ), FLAGS( 26 )
Cf2py intent(in) :: ALPHA, DELTA
Cf2py intent(out) :: INTVLS
C
C      write( *, 110 ) ALPHA, DELTA 
C 110  format( 'alpha, delta= ', f10.3 , ', ', f10.3)  
C      print *, 'Calling TVG_INIT' 
      call TVG_INIT( )
C
C      print *, 'Got past TVG_INIT' 
      call TVG_CALC( .false., ALPHA, DELTA, INTVLS, FLAGS, TOTINT )
C
C      write( *, 310 ) TOTINT
C 310  format( 'totint: ', i4 )
C
      END
C
      subroutine VIEWDATE(CYCLE, SECTOR,DATE)
C
C     Trivial wrapper to get the date string for a given sector.
C
      character*26, intent(out) :: DATE
      integer, intent(in) :: CYCLE, SECTOR
!f2py intent(out) DATE
!f2py intent(in) N
      call TVG_SECDATE( CYCLE, SECTOR, DATE) 
      end
C
C END FILE VIEW.F
