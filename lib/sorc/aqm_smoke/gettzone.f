
        INTEGER FUNCTION GETTZONE( FIP )

C***********************************************************************
C  function body starts at line 76
C
C  DESCRIPTION: 
C     Returns the time zone of a FIPs code based on the input tables
C
C  PRECONDITIONS REQUIRED:
C     FIP set to state and county FIPS code of interest
C     Memory allocated for arrays in argument list and arrays populated
C
C  SUBROUTINES AND FUNCTIONS CALLED:
C     Subroutines: I/O API subroutines
C     Functions: I/O API functions
C
C  REVISION  HISTORY:
C     Created 10/98 by M. Houyoux
C
C***********************************************************************
C
C Project Title: Sparse Matrix Operator Kernel Emissions (SMOKE) Modeling
C                System
C File: @(#)$Id: gettzone.f,v 1.7 2004/06/21 17:28:23 cseppan Exp $
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
C Pathname: $Source: /afs/isis/depts/cep/emc/apps/archive/smoke/smoke/src/lib/gettzone.f,v $
C Last updated: $Date: 2004/06/21 17:28:23 $ 
C
C****************************************************************************

C.........  MODULES for public variables
C.........  This module contains the arrays for state and county summaries
        USE MODSTCY, ONLY: NCOUNTY, CNTYCOD, CNTYTZON

        IMPLICIT NONE

C...........   EXTERNAL FUNCTIONS and their descriptions:

        INTEGER      ENVINT
        INTEGER      FIND1   !  returns -1 for failure
        EXTERNAL     ENVINT, FIND1

C...........   ARGUMENTS and their descriptions:

        INTEGER, INTENT (IN) :: FIP !  input FIPS code to assign zone

C...........   LOCAL VARIABLES their descriptions:

        INTEGER          K            ! indice
        INTEGER          IOS          ! i/o status
        INTEGER, SAVE :: TZONE0       ! default time zone

        LOGICAL, SAVE :: FIRSTIME = .TRUE.

        CHARACTER        BUFFER       ! ASCII LINE from X-ref file
        CHARACTER(300)   MESG         ! Message buffer

        CHARACTER(16) :: PROGNAME = 'GETTZONE' ! Program name

C***********************************************************************
C   begin body of subroutine GETTZONE

C.........  For the first time the routine is called, retrieve the default
C           time zone from the environment (or use the ultimate default of 5)
        IF( FIRSTIME ) THEN

            MESG = 'Default time zone for sources'
            TZONE0 = ENVINT( 'SMK_DEFAULT_TZONE', MESG, 5, IOS )
            FIRSTIME = .FALSE.

        END IF

C.........  Search for FIPS code in county-specific table
        K = FIND1( FIP, NCOUNTY, CNTYCOD )

        IF ( K .GT. 0 ) THEN
            GETTZONE = CNTYTZON( K )

C.........  Apply default
        ELSE
            GETTZONE = TZONE0

            WRITE( MESG,94040 ) 
     &                'WARNING: Applying default time zone of', TZONE0,
     &                'to country, state, and county code', FIP
            CALL M3MESG( MESG )

        END IF

        RETURN

C******************  FORMAT  STATEMENTS   ******************************C...........   Internal buffering formats.............94xxx
 
C...........   Internal buffering formats............ 94xxx

94040   FORMAT( A, 1X, I2.2, 1X, A, 1X, I6.6 )

        END