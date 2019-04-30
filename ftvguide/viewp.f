C FILE: VIEW.F
      PROGRAM VIEWF
C
C     Trivial wrapper to Koji's functions:  
C
      LOGICAL TERMOUT
      DOUBLE PRECISION ALPHA, DELTA, DEQUINOX, MID_JD
      INTEGER TOTINT, INTVLS( 13 )
C
      write( *, 110 ) ALPHA, DELTA 
 110  format( 'alpha, delta= ', f10.3 , ', ', f10.3)  
      print *, 'Calling TVG_INIT' 
      call TVG_INIT( 1, MID_JD )
      print *, 'Got past TVG_INIT;  calling TVG_CALC' 
C
C      call TVG_CALC( 1, .false., ALPHA, DELTA, INTVLS, TOTINT )
      call TVG_CALC( 1, .false., 101.2950, -16.6990, INTVLS, TOTINT )
C
      write( *, 310 ) TOTINT
 310  format( 'totint: ', i4 )

C
      END
C END FILE VIEW.F
