
        SUBROUTINE WPINGSTK( FNAME, SDATE, STIME )

C***********************************************************************
C  subroutine body starts at line 
C
C  DESCRIPTION:
C       Opens the output files for the Elevpoint program
C       
C  PRECONDITIONS REQUIRED:
C
C  SUBROUTINES AND FUNCTIONS CALLED:
C
C  REVISION  HISTORY:
C       Created 8/99 by M Houyoux
C
C************************************************************************
C  
C Project Title: Sparse Matrix Operator Kernel Emissions (SMOKE) Modeling
C                System
C File: @(#)$Id: wpingstk.f,v 1.9 2004/06/21 17:29:49 cseppan Exp $
C  
C COPYRIGHT (C) 2004, Environmental Modeling for Policy Development
C All Rights Reserved
C 
C Carolina Environmental Program
C University of North Carolina at Chapel Hill
C 137 E. Franklin St., CB# 6116
C Chapel Hill, NC 27599-6116
C 
C smoke@unc.edu
C  
C Pathname: $Source: /afs/isis/depts/cep/emc/apps/archive/smoke/smoke/src/point/wpingstk.f,v $
C Last updated: $Date: 2004/06/21 17:29:49 $ 
C  
C***********************************************************************

C...........   MODULES for public variables
C.........  This module contains arrays for plume-in-grid and major sources
        USE MODELEV, ONLY: NGROUP, GRPIDX, GRPGIDA, GRPCNT, GRPCOL,
     &                     GRPROW, GRPDM, GRPFL, GRPHT, GRPLAT, GRPLON,
     &                     GRPTK, GRPVE, GRPXL, GRPYL

        IMPLICIT NONE

C...........   INCLUDES:
        
        INCLUDE 'PARMS3.EXT'    !  I/O API parameters
        INCLUDE 'IODECL3.EXT'   !  I/O API function declarations
        INCLUDE 'FDESC3.EXT'    !  I/O API file description data structures.

C...........   EXTERNAL FUNCTIONS and their descriptions:

        CHARACTER(2)    CRLF
        EXTERNAL        CRLF

C..........    Subroutine arguments and their descriptions
        CHARACTER(*), INTENT (IN) :: FNAME   ! i/o api inventory file
        INTEGER     , INTENT (IN) :: SDATE   ! Julian start date
        INTEGER     , INTENT (IN) :: STIME   ! start time

C...........   LOCAL PARAMETERS
        CHARACTER(50), PARAMETER :: CVSW = '$Name: SMOKE_v2_2_11282005 $' ! CVS release tag

C...........   Local variables allocatable arrays
C...........   These are for sorting groups and outputting in sorted order
        INTEGER, ALLOCATABLE :: LOCGID( : )
        INTEGER, ALLOCATABLE :: LOCCNT( : )
        INTEGER, ALLOCATABLE :: LOCCOL( : )
        INTEGER, ALLOCATABLE :: LOCROW( : )

        REAL   , ALLOCATABLE :: LOCDM ( : )
        REAL   , ALLOCATABLE :: LOCFL ( : )
        REAL   , ALLOCATABLE :: LOCHT ( : )
        REAL   , ALLOCATABLE :: LOCLAT( : )
        REAL   , ALLOCATABLE :: LOCLON( : )
        REAL   , ALLOCATABLE :: LOCTK ( : )
        REAL   , ALLOCATABLE :: LOCVE ( : )
        REAL   , ALLOCATABLE :: LOCXL ( : )
        REAL   , ALLOCATABLE :: LOCYL ( : )

C...........   Other local variables
        INTEGER         I, J, L      ! indices and counters
        INTEGER         IOS          ! i/o status
         
        LOGICAL      :: EFLAG    = .FALSE.  !  true: error found

        CHARACTER(300)  MESG

        CHARACTER(16) :: PROGNAME = 'WPINGSTK'   !  subroutine name

C***********************************************************************
C   begin body of subroutine WPINGSTK

C.........  Allocate memory for local arrays
        ALLOCATE( LOCGID( NGROUP ), STAT=IOS )
        CALL CHECKMEM( IOS, 'LOCGID', PROGNAME )
        ALLOCATE( LOCCNT( NGROUP ), STAT=IOS )
        CALL CHECKMEM( IOS, 'LOCCNT', PROGNAME )
        ALLOCATE( LOCCOL( NGROUP ), STAT=IOS )
        CALL CHECKMEM( IOS, 'LOCCOL', PROGNAME )
        ALLOCATE( LOCROW( NGROUP ), STAT=IOS )
        CALL CHECKMEM( IOS, 'LOCROW', PROGNAME )
        ALLOCATE( LOCDM( NGROUP ), STAT=IOS )
        CALL CHECKMEM( IOS, 'LOCDM', PROGNAME )
        ALLOCATE( LOCFL( NGROUP ), STAT=IOS )
        CALL CHECKMEM( IOS, 'LOCFL', PROGNAME )
        ALLOCATE( LOCHT( NGROUP ), STAT=IOS )
        CALL CHECKMEM( IOS, 'LOCHT', PROGNAME )
        ALLOCATE( LOCLAT( NGROUP ), STAT=IOS )
        CALL CHECKMEM( IOS, 'LOCLAT', PROGNAME )
        ALLOCATE( LOCLON( NGROUP ), STAT=IOS )
        CALL CHECKMEM( IOS, 'LOCLON', PROGNAME )
        ALLOCATE( LOCTK( NGROUP ), STAT=IOS )
        CALL CHECKMEM( IOS, 'LOCTK', PROGNAME )
        ALLOCATE( LOCVE( NGROUP ), STAT=IOS )
        CALL CHECKMEM( IOS, 'LOCVE', PROGNAME )
        ALLOCATE( LOCXL( NGROUP ), STAT=IOS )
        CALL CHECKMEM( IOS, 'LOCXL', PROGNAME )
        ALLOCATE( LOCYL( NGROUP ), STAT=IOS )
        CALL CHECKMEM( IOS, 'LOCYL', PROGNAME )

C.........  Store sorted information
        DO I = 1, NGROUP
            J = GRPIDX( I )

            LOCGID( I ) = GRPGIDA( J )
            LOCCNT( I ) = GRPCNT( J )
            LOCCOL( I ) = GRPCOL( J )
            LOCROW( I ) = GRPROW( J )
            LOCDM ( I ) = GRPDM ( J )
            LOCFL ( I ) = GRPFL ( J )
            LOCHT ( I ) = GRPHT ( J )
            LOCLAT( I ) = GRPLAT( J )
            LOCLON( I ) = GRPLON( J )
            LOCTK ( I ) = GRPTK ( J )
            LOCVE ( I ) = GRPVE ( J )
            LOCXL ( I ) = GRPXL ( J )
            LOCYL ( I ) = GRPYL ( J )
            
        END DO

        MESG = 'Error writing to output file "' // FNAME // '"'

        IF ( .NOT. WRITE3( FNAME, 'ISTACK', SDATE, STIME, LOCGID )) THEN
            CALL M3EXIT( PROGNAME, 0, 0, MESG, 2 )
        END IF

        IF ( .NOT. WRITE3( FNAME,'LATITUDE',SDATE,STIME,LOCLAT )) THEN
            CALL M3EXIT( PROGNAME, 0, 0, MESG, 2 )
        END IF

        IF ( .NOT. WRITE3( FNAME,'LONGITUDE',SDATE,STIME,LOCLON )) THEN
            CALL M3EXIT( PROGNAME, 0, 0, MESG, 2 )
        END IF

        IF ( .NOT. WRITE3( FNAME, 'STKDM', SDATE, STIME, LOCDM ) ) THEN
            CALL M3EXIT( PROGNAME, 0, 0, MESG, 2 )
        END IF

        IF ( .NOT. WRITE3( FNAME, 'STKHT', SDATE, STIME, LOCHT ) ) THEN
            CALL M3EXIT( PROGNAME, 0, 0, MESG, 2 )
        END IF

        IF ( .NOT. WRITE3( FNAME, 'STKTK', SDATE, STIME, LOCTK ) ) THEN
            CALL M3EXIT( PROGNAME, 0, 0, MESG, 2 )
        END IF

        IF ( .NOT. WRITE3( FNAME, 'STKVE', SDATE, STIME, LOCVE ) ) THEN
            CALL M3EXIT( PROGNAME, 0, 0, MESG, 2 )
        END IF

        IF ( .NOT. WRITE3( FNAME, 'STKFLW', SDATE, STIME, LOCFL ) ) THEN
            CALL M3EXIT( PROGNAME, 0, 0, MESG, 2 )
        END IF

        IF ( .NOT. WRITE3( FNAME, 'STKCNT', SDATE, STIME, LOCCNT )) THEN
            CALL M3EXIT( PROGNAME, 0, 0, MESG, 2 )
        END IF

        IF ( .NOT. WRITE3( FNAME, 'ROW', SDATE, STIME, LOCROW ) ) THEN
            CALL M3EXIT( PROGNAME, 0, 0, MESG, 2 )
        END IF

        IF ( .NOT. WRITE3( FNAME, 'COL', SDATE, STIME, LOCCOL ) ) THEN
            CALL M3EXIT( PROGNAME, 0, 0, MESG, 2 )
        END IF

        IF ( .NOT. WRITE3( FNAME, 'XLOCA', SDATE, STIME, LOCXL ) ) THEN
            CALL M3EXIT( PROGNAME, 0, 0, MESG, 2 )
        END IF

        IF ( .NOT. WRITE3( FNAME, 'YLOCA', SDATE, STIME, LOCYL ) ) THEN
            CALL M3EXIT( PROGNAME, 0, 0, MESG, 2 )
        END IF

C.........  Deallocate local memory
        DEALLOCATE( LOCGID, LOCCNT, LOCCOL, LOCROW,
     &              LOCDM, LOCFL, LOCHT, LOCLAT, LOCLON, LOCTK,
     &              LOCVE, LOCXL, LOCYL )

        RETURN

C******************  FORMAT  STATEMENTS   ******************************

C...........   Informational (LOG) message formats... 92xxx

92000   FORMAT( 5X, A )


C...........   Formatted file I/O formats............ 93xxx

93010   FORMAT( 4 I10, F10.2 )


C...........   Internal buffering formats............ 94xxx

94010   FORMAT( 10 ( A, :, I8, :, 2X  ) )

94015   FORMAT( A, 1X, I6, 1X, A, 1X, I5.5, 1X, A, 1X, I8.8, 1X,
     &          A, 1X, I6, 1X, A, 1X, I6,   1X, A )

94020   FORMAT( 5X, 'H[m]:', 1X, F6.2, 1X, 'D[m]:'  , 1X, F4.2, 1X,
     &              'T[K]:', 1X, F7.1, 1X, 'V[m/s]:', 1X, F10.1 )

        END SUBROUTINE WPINGSTK
