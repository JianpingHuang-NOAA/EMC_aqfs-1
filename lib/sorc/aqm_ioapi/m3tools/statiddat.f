
        SUBROUTINE  STATIDDAT ( NROWS, NLAYS, NVARS,
     &                         JDATE, JTIME, NTHRES, THRES,
     &                         INNAME, VNAMES, VTYPES, LOGDEV )

C***********************************************************************
C Version "@(#)$Header$"
C EDSS/Models-3 M3TOOLS.
C Copyright (C) 1992-2002 MCNC and Carlie J. Coats, Jr., and
C (C) 2003-2010 Baron Advanced Meteorological Systems, LLC
C Distributed under the GNU GENERAL PUBLIC LICENSE version 2
C See file "GPL.txt" for conditions of use.
C.........................................................................
C  subroutine body starts at line  102
C
C  FUNCTION:
C       Statistics report to LOGDEV on variables VNAMES  from file
C       INNAME.
C       and on the results of using GRIDOPS to apply the operations
C       OPNAME( * ) to them.
C
C  PRECONDITIONS REQUIRED:
C       Valid dates and times JDATE:JTIME
C       Stack-allocation operating environment (such as CRAY)
C
C  SUBROUTINES AND FUNCTIONS CALLED:
C       Models-3 I/O:  M3ERR(), READ3(), WRITE3()
C
C  REVISION  HISTORY:
C       Prototype 3/93 by CJC
C       Modified  9/99 by CJC for enhanced portability
C
C       Version 02/2010 by CJC for I/O API v3.1:  Fortran-90 only;
C       USE M3UTILIO, and related changes.
C***********************************************************************

      USE M3UTILIO
      IMPLICIT NONE


C...........   ARGUMENTS and their descriptions:

        INTEGER         NROWS   ! grid dimensions, from INNAME header
        INTEGER         NLAYS   ! grid dimensions, from INNAME header
        INTEGER         NVARS   !  number of vbles to be totaled
        INTEGER         JDATE   ! current model date
        INTEGER         JTIME   ! current model time
        INTEGER         NTHRES( NVARS )         ! number of tests per vble
        REAL            THRES ( 10,NVARS )      ! thresholds for counting
        CHARACTER*16    INNAME                  !  input file logical name
        CHARACTER*16    VNAMES( NVARS )         !  list of vble names
        INTEGER         VTYPES( NVARS )		! number of tests per vble
        INTEGER         LOGDEV  ! unit number for output


C...........   LOCAL VARIABLES and their descriptions:

        INTEGER          N
        INTEGER          ID( NROWS )
        REAL             VV( NROWS, NLAYS, NVARS )
        REAL             GG( NROWS, NLAYS )
        INTEGER          V, W, SIZE, GSIZ
        CHARACTER*120    MESG


C***********************************************************************
C   begin body of subroutine  STATIDDAT

        GSIZ = NROWS * NVARS * NLAYS
        SIZE = 1 + 2 * ( NROWS + GSIZ )

        IF ( JDATE .NE. 0 .OR. JTIME .NE. 0 ) THEN	
            WRITE( LOGDEV,92010 )
     &          INNAME, JDATE, JTIME, DT2STR( JDATE, JTIME )
        ELSE
            WRITE( LOGDEV,92010 ) INNAME
        END IF

        IF ( READ3( INNAME, ALLVAR3, ALLAYS3,
     &                 JDATE, JTIME, N ) ) THEN
           
            W = 1

            DO  111  V = 1, NVARS

                IF ( VTYPES( V ) .EQ. M3REAL ) THEN

                    CALL STATI( NROWS, NLAYS, N, ID, VV( 1,1,W ),
     &                          NTHRES( V ), THRES( 1,V ),
     &                          VNAMES( V ), LOGDEV )
                    W = W + GSIZ

                ELSE IF ( VTYPES( V ) .EQ. M3INT ) THEN

                    CALL INTG2REAL( GSIZ, VV( 1,1,W ), GG )
                    CALL STATI( NROWS, NLAYS, N, ID, GG,
     &                          NTHRES( V ), THRES( 1,V ),
     &                          VNAMES( V ), LOGDEV )
                    W = W + GSIZ

                ELSE IF ( VTYPES( V ) .EQ. M3DBLE ) THEN

                    CALL DBLE2REAL( GSIZ, VV( 1,1,W ), GG )
                    CALL STATI( NROWS, NLAYS, N, ID, GG,
     &                          NTHRES( V ), THRES( 1,V ),
     &                          VNAMES( V ), LOGDEV )
                    W = W + 2 * GSIZ

                ELSE

                    MESG = 'Bad type for variable ' // VNAMES( V )
                    CALL M3EXIT( 'STATIDDAT', JDATE, JTIME, MESG, 2 )

                END IF

111         CONTINUE        !  end loop on variables
           
        ELSE                !  read3() failed:
           
            MESG = 'Read failure:  file ' // INNAME
            CALL M3EXIT( 'STATIDDAT', JDATE, JTIME, MESG, 2 )

        END IF              !  if read3() worked, or not


        RETURN

C******************  FORMAT  STATEMENTS   ******************************

C...........   Informational (LOG) message formats... 92xxx

92010   FORMAT ( //5X, 'File:  ', A, :,
     &            /5X, 'Date and time:', I7.7, ':', I6.6, 2X, A )

        END SUBROUTINE  STATIDDAT

