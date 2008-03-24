
C***********************************************************************
C   Portions of Models-3/CMAQ software were developed or based on      *
C   information from various groups: Federal Government employees,     *
C   contractors working on a United States Government contract, and    *
C   non-Federal sources (including research institutions).  These      *
C   research institutions have given the Government permission to      *
C   use, prepare derivative works, and distribute copies of their      *
C   work in Models-3/CMAQ to the public and to permit others to do     *
C   so.  EPA therefore grants similar permissions for use of the       *
C   Models-3/CMAQ software, but users are requested to provide copies  *
C   of derivative works to the Government without restrictions as to   *
C   use by others.  Users are responsible for acquiring their own      *
C   copies of commercial software associated with Models-3/CMAQ and    *
C   for complying with vendor requirements.  Software copyrights by    *
C   the MCNC Environmental Modeling Center are used with their         *
C   permissions subject to the above restrictions.                     *
C***********************************************************************

C RCS file, release, date & time of last delta, author, state, [and locker]
C $Header: /project/work/rep/CCTM/src/vdiff/acm2/eddyx.F,v 1.5 2006/09/22 18:16:37 sjr Exp $

C what(1) key, module and SID; SCCS file; date and time of last delta:
C %W% %P% %G% %U%

C:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
      SUBROUTINE EDDYX ( JDATE, JTIME, TSTEP,
     &                   EDDYV, HOL, XPBL, LPBL, CONVCT )

C--------------------------------------------------------------------------
C---- Eddy diffusivity (Kz) computed according to 2 different models:
C----   1- Boundary Layer scaling based on Hostlag and Boville (1993)
C----      Kz = k ust z(1-z/h)2 / phih
C       2- Local scaling based on local Richardson # and vertical shear
C          similar to Liu and Carroll (1996)
C
C  REVISION HISTORY:
C  JEP        4/00 - CCTM implimentation from MM5
C  JEP        4/06 - Updated for ACM2
C  YOJ        9/07 - SETUP_LOGDEV instead of INIT3
C  08 Nov 07 J.Young: add Richardson No. based PBL option
C--------------------------------------------------------------------------

      USE GRID_CONF             ! horizontal domain specifications
      USE SE_MODULES         ! stenex

      IMPLICIT NONE

C Includes:

      INCLUDE "/meso/save/wx20jy/cctm/BLD_u5a/CONST.EXT"       ! constants
      INCLUDE "/meso/save/wx20dw/tools/ioapi_3/ioapi/fixed_src/PARMS3.EXT"     ! I/O parameters definitions
      INCLUDE "/meso/save/wx20dw/tools/ioapi_3/ioapi/fixed_src/FDESC3.EXT"     ! file header data structure
      INCLUDE "/meso/save/wx20dw/tools/ioapi_3/ioapi/fixed_src/IODECL3.EXT"      ! I/O definitions and declarations
      INCLUDE "/meso/save/wx20jy/cctm/BLD_u5a/FILES_CTM.EXT"    ! file name parameters
      INCLUDE "/meso/save/wx20jy/cctm/BLD_u5a/PE_COMM.EXT"     ! PE communication displacement and direction

C Arguments:

      INTEGER, INTENT( IN )  :: JDATE     ! current model date, coded YYYYDDD
      INTEGER, INTENT( IN )  :: JTIME     ! current model time, coded HHMMSS
      INTEGER, INTENT( IN )  :: TSTEP     ! sciproc sync. step (chem)
      REAL,    INTENT( OUT ) :: EDDYV ( :,:,: ) ! eddy diffusivity (m**2/s)
      REAL,    INTENT( OUT ) :: HOL   ( :,: ) ! PBL over Obukhov length
      REAL,    INTENT( OUT ) :: XPBL  ( :,: ) ! PBL sigma height
      INTEGER, INTENT( OUT ) :: LPBL  ( :,: ) ! PBL layer
      LOGICAL, INTENT( OUT ) :: CONVCT( :,: ) ! no convection flag

C Parameters:

      REAL, PARAMETER :: RLAM   = 80.0 ! asymptotic mixing length (m)
      REAL, PARAMETER :: KZ0UT  = 1.0  ! minimum eddy diffusivity (m**2/sec) KZ0
!     REAL, PARAMETER :: KZL    = 0.5  ! lowest KZ
      REAL, PARAMETER :: KZL    = 0.1  ! lowest KZ
      REAL, PARAMETER :: KZU    = 2.0  ! highest KZ
      REAL, PARAMETER :: RIC    = 0.25 ! critical Richardson #
!     REAL, PARAMETER :: PRAN   = 0.95 ! HOGSTROM(1988)
      REAL, PARAMETER :: GAMH   = 15.0 ! Holtslag and Boville (1993)
      REAL, PARAMETER :: BETAH  = 5.0  ! Holtslag and Boville (1993)
      REAL, PARAMETER :: CGAM   = 0.0  ! Holtslag and Boville (1993)
      REAL, PARAMETER :: KARMAN = 0.4

C small number for temperature difference

      REAL, PARAMETER :: EPS = 1.0E-08

C External Functions not previously declared in IODECL3.EXT:

      INTEGER, EXTERNAL :: SEC2TIME, TIME2SEC, INDEX1, SETUP_LOGDEV
      LOGICAL, EXTERNAL :: ENVYN

C                                123456789012345678901234567890
      CHARACTER( 30 ) :: MSG1 = ' Error interpolating variable '

C File Variables:

      REAL          PBL  ( NCOLS,NROWS )           ! pbl height (m)
      REAL          USTAR( NCOLS,NROWS )           ! friction velocity
      REAL          WSTAR( NCOLS,NROWS )           ! friction velocity
      REAL          MOLI ( NCOLS,NROWS )           ! inverse Monin-Obukhov Len
      REAL          ZH   ( NCOLS,NROWS,NLAYS )     ! mid-layer elevation
      REAL          ZF   ( NCOLS,NROWS,0:NLAYS )   ! full layer elevation
      REAL          TA   ( NCOLS,NROWS,NLAYS )     ! temperature (K)
      REAL          QV   ( NCOLS,NROWS,NLAYS )     ! water vapor mixing ratio
      REAL          QC   ( NCOLS,NROWS,NLAYS )     ! cloud water mixing ratio
      REAL          PRES ( NCOLS,NROWS,NLAYS )     ! pressure

      REAL, ALLOCATABLE, SAVE :: MSFX2 ( :,: )     ! Squared map scale factors

      LOGICAL, SAVE :: RIPBL                       ! .true. - use Richardson No. PBL
      LOGICAL, SAVE :: MINKZ
!     REAL          PURB( NCOLS,NROWS )            ! percent urban
      REAL, ALLOCATABLE, SAVE ::PURB( :,: )        ! percent urban
      REAL          UFRAC
      REAL, ALLOCATABLE, SAVE :: KZMIN( :,:,: )    ! minimum Kz (m**2/s)
      REAL          KZM                            ! local KZMIN
      LOGICAL, ALLOCATABLE, SAVE :: KZLAY( :,:,: ) ! minimum Kz applied
      REAL, PARAMETER :: KZMAXL = 500.0            ! upper limit for min Kz (m)

      REAL          UWIND( NCOLS+1,NROWS+1,NLAYS ) ! x-direction winds
      REAL          VWIND( NCOLS+1,NROWS+1,NLAYS ) ! y-direction winds
      REAL, ALLOCATABLE, SAVE :: UVBUF( :,:,: )    ! U, V read buffer
      INTEGER, SAVE :: MCOLS, MROWS                ! for allocating

C Local variables:

      LOGICAL,SAVE :: FIRSTIME = .TRUE.

      CHARACTER( 16 ) :: PNAME = 'EDDYX'
      CHARACTER( 16 ) :: VNAME
      CHARACTER( 16 ) :: UNITSCK
      CHARACTER( 120 ) :: XMSG = ' '

      REAL, SAVE :: P0          ! 1000 mb reference pressure
      REAL, SAVE :: CONVPA      ! Pressure conversion factor file units to Pa

      INTEGER      ASTAT
      INTEGER      MDATE, MTIME, STEP
      INTEGER      C, R, L, V

      REAL         TV                      ! virtual temperature (K)
      REAL         DZL                     ! Z(L+1)-Z(L)
      REAL         WW2                     ! (wind speed)**2
      REAL         WS2                     ! (wind shear)**2
      REAL         RIB                     ! Bulk Richardson Number
      REAL         RL, RU, ZL, ZU
      REAL         HEAD, ARG1, BETA
      REAL         THETAV( NCOLS,NROWS,NLAYS )    ! potential temp
      REAL         ZOL
      REAL         ZFUNC, HPBL 
      REAL         EDDV                    ! local EDDYV

      INTEGER      GXOFF, GYOFF            ! global origin offset from file
C for INTERPX
      INTEGER       :: STRTCOLGC2, ENDCOLGC2, STRTROWGC2, ENDROWGC2
      INTEGER, SAVE :: STRTCOLMC2, ENDCOLMC2, STRTROWMC2, ENDROWMC2
      INTEGER, SAVE :: STRTCOLMC3, ENDCOLMC3, STRTROWMC3, ENDROWMC3
      INTEGER, SAVE :: STRTCOLMD3, ENDCOLMD3, STRTROWMD3, ENDROWMD3

      INTEGER      MCOL                   ! these don't need to be initialized
      INTEGER      MROW
      INTEGER      MLVL
      REAL         MTH1                   ! pot. temp. in layer L
      REAL         MTH2                   ! pot. temp. in layer L+1
      REAL         MRIB                   ! bulk Richardson Number
      REAL         MWS                    ! wind shear (/sec)
      REAL         MEDDYV                 ! eddy diffusivity (m**2/sec)

      INTEGER, SAVE :: LOGDEV

      REAL QMEAN, TMEAN
      REAL XLV, ALPH, CHI
      REAL CPAIR, ZK, SQL, PHIH
      REAL PHIM
      REAL WT, WM, PR, ZSOL
      REAL EDYZ, FINT
      REAL ZFL                            ! local ZF
      INTEGER LP

C-----------------------------------------------------------------------

      IF ( FIRSTIME )  THEN
         FIRSTIME  =  .FALSE.
!        LOGDEV = INIT3()
         LOGDEV = SETUP_LOGDEV()

C Open the met files

         IF ( .NOT. OPEN3( MET_CRO_3D, FSREAD3, PNAME ) ) THEN
            XMSG = 'Could not open '// MET_CRO_3D // ' file'
            CALL M3EXIT( PNAME, JDATE, JTIME, XMSG, XSTAT1 )
         END IF

         IF ( .NOT. DESC3( MET_CRO_3D ) ) THEN
            XMSG = 'Could not get ' // MET_CRO_3D // ' file description'
            CALL M3EXIT( PNAME, JDATE, JTIME, XMSG, XSTAT2 )
         END IF         !  error abort if if desc3() failed

         V = INDEX1( 'PRES', NVARS3D, VNAME3D )
         IF ( V .NE. 0 ) THEN
            UNITSCK = UNITS3D( V )
         ELSE
            XMSG = 'Could not get variable PRES from ' // MET_CRO_3D
            CALL M3EXIT( PNAME, JDATE, JTIME, XMSG, XSTAT2 )
         END IF

         IF ( UNITSCK .EQ. 'PASCAL' .OR. UNITSCK .EQ. 'pascal' .OR.
     &        UNITSCK .EQ. 'Pascal' .OR. UNITSCK .EQ. 'PA'     .OR.
     &        UNITSCK .EQ. 'pa'     .OR. UNITSCK .EQ. 'Pa' ) THEN
            CONVPA = 1.0
            P0 = 100000.0
         ELSE IF ( UNITSCK .EQ. 'MILLIBAR' .OR. UNITSCK .EQ. 'millibar' .OR.
     &             UNITSCK .EQ. 'Millibar' .OR. UNITSCK .EQ. 'MB'       .OR.
     &             UNITSCK .EQ. 'mb'       .OR. UNITSCK .EQ. 'Mb' ) THEN
            CONVPA = 1.0E-02
            P0 = 1000.0
         ELSE IF ( UNITSCK .EQ. 'CENTIBAR' .OR. UNITSCK .EQ. 'centibar' .OR.
     &             UNITSCK .EQ. 'Centibar' .OR. UNITSCK .EQ. 'CB'       .OR.
     &             UNITSCK .EQ. 'cb'       .OR. UNITSCK .EQ. 'Cb' ) THEN
            CONVPA = 1.0E-03
            P0 = 100.0
         ELSE
            XMSG = 'Units incorrect on ' // MET_CRO_3D
            CALL M3EXIT( PNAME, JDATE, JTIME, XMSG, XSTAT2 )
         END IF

!        IF ( .NOT. OPEN3( MET_DOT_3D, FSREAD3, PNAME ) ) THEN
!           XMSG = 'Could not open '// MET_DOT_3D // ' file'
!           CALL M3EXIT( PNAME, JDATE, JTIME, XMSG, XSTAT1 )
!        END IF

!        IF ( .NOT. OPEN3( GRID_CRO_2D, FSREAD3, PNAME ) ) THEN
!           XMSG = 'Could not open '// GRID_CRO_2D // ' file'
!           CALL M3EXIT( PNAME, JDATE, JTIME, XMSG, XSTAT1 )
!        END IF

         ALLOCATE ( MSFX2( NCOLS,NROWS ), STAT = ASTAT )
         IF ( ASTAT .NE. 0 ) THEN
            XMSG = 'Failure allocating MSFX2'
            CALL M3EXIT( PNAME, JDATE, JTIME, XMSG, XSTAT1 )
         END IF

         CALL SUBHFILE ( GRID_CRO_2D, GXOFF, GYOFF,
     &                   STRTCOLGC2, ENDCOLGC2, STRTROWGC2, ENDROWGC2 )

         VNAME = 'MSFX2'
         IF ( .NOT. INTERPX( GRID_CRO_2D, VNAME, PNAME,
!    &                       1,NCOLS, 1,NROWS, 1,1,
     &                       STRTCOLGC2,ENDCOLGC2, STRTROWGC2,ENDROWGC2, 1,1,
     &                       JDATE, JTIME, MSFX2 ) ) THEN
            XMSG = MSG1 // VNAME // ' from ' // GRID_CRO_2D
            CALL M3EXIT( PNAME, JDATE, JTIME, XMSG, XSTAT1 )
         END IF

         RIPBL = .TRUE.   ! default
         RIPBL = ENVYN( 'PBL_RICH', 'Richardson No. PBL flag', RIPBL, ASTAT )
         IF ( ASTAT .NE. 0 ) WRITE( LOGDEV,'(5X, A)' ) 'Richardson No. PBL flag'
         IF ( ASTAT .EQ. 1 ) THEN
            XMSG = 'Environment variable improperly formatted'
            CALL M3EXIT( PNAME, JDATE, JTIME, XMSG, XSTAT2 )
         ELSE IF ( ASTAT .EQ. -1 ) THEN
            XMSG = 'Environment variable set, but empty ... Using default:'
            WRITE( LOGDEV,'(5X, A)' ) XMSG
         ELSE IF ( ASTAT .EQ. -2 ) THEN
            XMSG = 'Environment variable not set ... Using default:'
            WRITE( LOGDEV,'(5X, A)' ) XMSG
         END IF

         IF ( .NOT. RIPBL ) THEN
            XMSG = 'This run does *NOT* use Richardson No. PBL in subroutine EDDYX.'
            WRITE( LOGDEV,'(/5X, A, /)' ) XMSG
         END IF

         MINKZ = .TRUE.   ! default
         MINKZ = ENVYN( 'KZMIN', 'Kz min on flag', MINKZ, ASTAT )
         IF ( ASTAT .NE. 0 ) WRITE( LOGDEV,'(5X, A)' ) 'Kz min on flag'
         IF ( ASTAT .EQ. 1 ) THEN
            XMSG = 'Environment variable improperly formatted'
            CALL M3EXIT( PNAME, JDATE, JTIME, XMSG, XSTAT2 )
         ELSE IF ( ASTAT .EQ. -1 ) THEN
            XMSG = 'Environment variable set, but empty ... Using default:'
            WRITE( LOGDEV,'(5X, A)' ) XMSG
         ELSE IF ( ASTAT .EQ. -2 ) THEN
            XMSG = 'Environment variable not set ... Using default:'
            WRITE( LOGDEV,'(5X, A)' ) XMSG
         END IF

         IF ( MINKZ ) THEN

            ALLOCATE ( PURB( NCOLS,NROWS ), STAT = ASTAT )
            IF ( ASTAT .NE. 0 ) THEN
               XMSG = 'Failure allocating PURB'
               CALL M3EXIT( PNAME, JDATE, JTIME, XMSG, XSTAT1 )
            END IF

            VNAME = 'PURB'
            IF ( .NOT. INTERPX( GRID_CRO_2D, VNAME, PNAME,
     &                          STRTCOLGC2,ENDCOLGC2, STRTROWGC2,ENDROWGC2, 1,1,
     &                          JDATE, JTIME, PURB ) ) THEN
               XMSG = 'Either make the data available from MCIP'
               WRITE( LOGDEV,'(/5X, A)' ) XMSG
               XMSG = 'or set the env var KZMIN to F or N,'
               WRITE( LOGDEV,'( 5X, A)' ) XMSG
               XMSG = 'in which case you will revert back to the'
               WRITE( LOGDEV,'( 5X, A)' ) XMSG
               XMSG = 'previous version of subroutine edyintb using Kz0UT'
               WRITE( LOGDEV,'( 5X, A, /)' ) XMSG
               XMSG = ' '
               CALL M3EXIT( PNAME, JDATE, JTIME, XMSG, XSTAT1 )
            END IF

            ALLOCATE ( KZLAY( NCOLS,NROWS,NLAYS ), STAT = ASTAT )
            IF ( ASTAT .NE. 0 ) THEN
               XMSG = 'Failure allocating KZLAY'
               CALL M3EXIT( PNAME, JDATE, JTIME, XMSG, XSTAT1 )
            END IF

         ELSE IF ( .NOT. MINKZ ) THEN
            XMSG = 'This run uses Kz0UT, *NOT* KZMIN in subroutine edyintb.'
            WRITE( LOGDEV,'(/5X, A, /)' ) XMSG
         END IF   ! MINKZ

         ALLOCATE ( KZMIN( NCOLS,NROWS,NLAYS ), STAT = ASTAT )
         IF ( ASTAT .NE. 0 ) THEN
            XMSG = 'Failure allocating KZMIN'
            CALL M3EXIT( PNAME, JDATE, JTIME, XMSG, XSTAT1 )
         END IF

         CALL SUBHFILE ( MET_CRO_2D, GXOFF, GYOFF,
     &                   STRTCOLMC2, ENDCOLMC2, STRTROWMC2, ENDROWMC2 )
         CALL SUBHFILE ( MET_CRO_3D, GXOFF, GYOFF,
     &                   STRTCOLMC3, ENDCOLMC3, STRTROWMC3, ENDROWMC3 )
         CALL SUBHFILE ( MET_DOT_3D, GXOFF, GYOFF,
     &                   STRTCOLMD3, ENDCOLMD3, STRTROWMD3, ENDROWMD3 )

         MCOLS = ENDCOLMD3 - STRTCOLMD3 + 1
         MROWS = ENDROWMD3 - STRTROWMD3 + 1

         ALLOCATE ( UVBUF( MCOLS,MROWS,NLAYS ), STAT = ASTAT )
         IF ( ASTAT .NE. 0 ) THEN
            XMSG = 'Failure allocating UVBUF'
            CALL M3EXIT( PNAME, JDATE, JTIME, XMSG, XSTAT1 )
         END IF

      END IF          !  if firstime

C Interpolate time dependent one-layer and layered input variables

      MDATE  = JDATE
      MTIME  = JTIME
      STEP   = TIME2SEC( TSTEP )
      CALL NEXTIME( MDATE, MTIME, SEC2TIME( STEP / 2 ) )


      VNAME = 'UWIND'
      IF ( .NOT. INTERPX( MET_DOT_3D, VNAME, PNAME,
!    &                    1,NCOLS+1, 1,NROWS+1, 1,NLAYS,
     &                    STRTCOLMD3,ENDCOLMD3, STRTROWMD3,ENDROWMD3, 1,NLAYS,
     &                    MDATE, MTIME, UVBUF ) ) THEN
         XMSG = MSG1 // VNAME // ' from ' // MET_DOT_3D
         CALL M3EXIT( PNAME, JDATE, JTIME, XMSG, XSTAT1 )
      END IF

      UWIND = 0.0
      DO L = 1, NLAYS
         DO R = 1, MROWS
            DO C = 1, MCOLS
               UWIND( C,R,L ) = UVBUF( C,R,L )
            END DO
         END DO
      END DO

      VNAME = 'VWIND'
      IF ( .NOT. INTERPX( MET_DOT_3D, VNAME, PNAME,
!    &                    1,NCOLS+1, 1,NROWS+1, 1,NLAYS,
     &                    STRTCOLMD3,ENDCOLMD3, STRTROWMD3,ENDROWMD3, 1,NLAYS,
     &                    MDATE, MTIME, UVBUF ) ) THEN
         XMSG = MSG1 // VNAME // ' from ' // MET_DOT_3D
         CALL M3EXIT( PNAME, JDATE, JTIME, XMSG, XSTAT1 )
      END IF

      VWIND = 0.0
      DO L = 1, NLAYS
         DO R = 1, MROWS
            DO C = 1, MCOLS
               VWIND( C,R,L ) = UVBUF( C,R,L )
            END DO
         END DO
      END DO

      IF ( RIPBL ) THEN
         VNAME = 'PBL2'
      ELSE
         VNAME = 'PBL'
      END IF
      IF ( .NOT. INTERPX( MET_CRO_2D, VNAME, PNAME,
     &                    STRTCOLMC2,ENDCOLMC2, STRTROWMC2,ENDROWMC2, 1,1,
     &                    MDATE, MTIME, PBL ) ) THEN
         XMSG = MSG1 // VNAME // ' from ' // MET_CRO_2D
         CALL M3EXIT( PNAME, JDATE, JTIME, XMSG, XSTAT1 )
      END IF

      VNAME = 'USTAR'
      IF ( .NOT. INTERPX( MET_CRO_2D, VNAME, PNAME,
     &                    STRTCOLMC2,ENDCOLMC2, STRTROWMC2,ENDROWMC2, 1,1,
     &                    MDATE, MTIME, USTAR ) ) THEN
         XMSG = MSG1 // VNAME // ' from ' // MET_CRO_2D
         CALL M3EXIT( PNAME, JDATE, JTIME, XMSG, XSTAT1 )
      END IF

      VNAME = 'WSTAR'
      IF ( .NOT. INTERPX( MET_CRO_2D, VNAME, PNAME,
     &                    STRTCOLMC2,ENDCOLMC2, STRTROWMC2,ENDROWMC2, 1,1,
     &                    MDATE, MTIME, WSTAR ) ) THEN
         XMSG = MSG1 // VNAME // ' from ' // MET_CRO_2D
         CALL M3EXIT( PNAME, JDATE, JTIME, XMSG, XSTAT1 )
      END IF

      VNAME = 'MOLI'
      IF ( .NOT. INTERPX( MET_CRO_2D, VNAME, PNAME,
     &                    STRTCOLMC2,ENDCOLMC2, STRTROWMC2,ENDROWMC2, 1,1,
     &                    MDATE, MTIME, MOLI ) ) THEN
         XMSG = MSG1 // VNAME // ' from ' // MET_CRO_2D
         CALL M3EXIT( PNAME, JDATE, JTIME, XMSG, XSTAT1 )
      END IF

      VNAME = 'TA'
      IF ( .NOT. INTERPX( MET_CRO_3D, VNAME, PNAME,
!    &                    1,NCOLS, 1,NROWS, 1,NLAYS,
     &                    STRTCOLMC3,ENDCOLMC3, STRTROWMC3,ENDROWMC3, 1,NLAYS,
     &                    MDATE, MTIME, TA ) ) THEN
         XMSG = MSG1 // VNAME // ' from ' // MET_CRO_3D
         CALL M3EXIT( PNAME, JDATE, JTIME, XMSG, XSTAT1 )
      END IF

      VNAME = 'QV'
      IF ( .NOT. INTERPX( MET_CRO_3D, VNAME, PNAME,
!    &                    1,NCOLS, 1,NROWS, 1,NLAYS,
     &                    STRTCOLMC3,ENDCOLMC3, STRTROWMC3,ENDROWMC3, 1,NLAYS,
     &                    MDATE, MTIME, QV ) ) THEN
         XMSG = MSG1 // VNAME // ' from ' // MET_CRO_3D
         CALL M3EXIT( PNAME, JDATE, JTIME, XMSG, XSTAT1 )
      END IF

      VNAME = 'QC'
      IF ( .NOT. INTERPX( MET_CRO_3D, VNAME, PNAME,
!    &                    1,NCOLS, 1,NROWS, 1,NLAYS,
     &                    STRTCOLMC3,ENDCOLMC3, STRTROWMC3,ENDROWMC3, 1,NLAYS,
     &                    MDATE, MTIME, QC ) ) THEN
         XMSG = MSG1 // VNAME // ' from ' // MET_CRO_3D
         CALL M3EXIT( PNAME, JDATE, JTIME, XMSG, XSTAT1 )
      END IF

      VNAME = 'PRES'
      IF ( .NOT. INTERPX( MET_CRO_3D, VNAME, PNAME,
!    &                    1,NCOLS, 1,NROWS, 1,NLAYS,
     &                    STRTCOLMC3,ENDCOLMC3, STRTROWMC3,ENDROWMC3, 1,NLAYS,
     &                    MDATE, MTIME, PRES ) ) THEN
         XMSG = MSG1 // VNAME // ' from ' // MET_CRO_3D
         CALL M3EXIT( PNAME, JDATE, JTIME, XMSG, XSTAT1 )
      END IF

      VNAME = 'ZF'
      IF ( .NOT. INTERPX( MET_CRO_3D, VNAME, PNAME,
!    &                    1,NCOLS, 1,NROWS, 1,NLAYS,
     &                    STRTCOLMC3,ENDCOLMC3, STRTROWMC3,ENDROWMC3, 1,NLAYS,
     &                    MDATE, MTIME, ZF ) ) THEN
         XMSG = MSG1 // VNAME // ' from ' // MET_CRO_3D
         CALL M3EXIT( PNAME, JDATE, JTIME, XMSG, XSTAT1 )
      END IF

C Move 3rd dimension slabbed data from INTERP3 into proper order
C ( Using ZF both as a read buffer and an argument variable.)

      IF ( MINKZ ) THEN
         KZLAY = .FALSE.
         DO L = NLAYS, 1, -1
            DO R = 1, MY_NROWS
               DO C = 1, MY_NCOLS
                  ZF( C,R,L ) = ZF( C,R,L-1 )
                  IF ( ZF( C,R,L ) .LE. KZMAXL ) KZLAY( C,R,L ) = .TRUE.
               END DO
            END DO
         END DO
      ELSE
         DO L = NLAYS, 1, -1
            DO R = 1, MY_NROWS
               DO C = 1, MY_NCOLS
                  ZF( C,R,L ) = ZF( C,R,L-1 )
               END DO
            END DO
         END DO
      END IF

      DO R = 1, MY_NROWS
         DO C = 1, MY_NCOLS
            ZF( C,R,0 ) = 0.0
         END DO
      END DO

      IF ( MINKZ ) THEN
         KZMIN = KZL
         DO L = 1, NLAYS
            DO R = 1, MY_NROWS
               DO C = 1, MY_NCOLS
                  IF ( KZLAY( C,R,L ) ) THEN
                     UFRAC = 0.01 * PURB( C,R )
                     KZMIN( C,R,L ) = KZL + ( KZU - KZL ) * UFRAC
                  END IF
               END DO
            END DO
         END DO
      ELSE
         KZMIN = KZ0UT
      END IF

      VNAME = 'ZH'
      IF ( .NOT. INTERPX( MET_CRO_3D, VNAME, PNAME,
     &                    STRTCOLMC3,ENDCOLMC3, STRTROWMC3,ENDROWMC3, 1,NLAYS,
     &                    MDATE, MTIME, ZH ) ) THEN
         XMSG = MSG1 // VNAME // ' from ' // MET_CRO_3D
         CALL M3EXIT( PNAME, JDATE, JTIME, XMSG, XSTAT1 )
      END IF

      DO L = 1, NLAYS
         DO R = 1, MY_NROWS
            DO C = 1, MY_NCOLS
               TV = TA( C,R,L ) * ( 1.0 + 0.608 * QV( C,R,L ) )
               THETAV( C,R,L ) = TV * ( P0 / PRES( C,R,L ) ) ** 0.286
            END DO
         END DO
      END DO

      CONVCT = .FALSE.
      DO R = 1, MY_NROWS
         DO C = 1, MY_NCOLS

            DO L = 1, NLAYS
               IF ( PBL( C,R ) .LT. ZF( C,R,L ) ) THEN
                  LP = L
                  GO TO 14
               END IF
            END DO

14          CONTINUE

            LPBL( C,R ) = LP
            FINT = ( PBL( C,R ) - ZF( C,R,LP-1 ) )
     &           / ( ZF( C,R,LP ) - ZF( C,R,LP-1 ) )
            XPBL( C,R ) = FINT * ( X3FACE_GD( LP ) - X3FACE_GD( LP-1 ) )
     &                  + X3FACE_GD( LP-1 )
            HOL( C,R ) = PBL( C,R ) * MOLI( C,R )

            IF ( ( ( THETAV( C,R,1 ) - THETAV( C,R,2 ) ) .GT. EPS ) .AND.
     &           ( HOL( C,R ) .LT. -0.1 ) .AND.
     &           ( LPBL( C,R ) .GT. 3 ) ) CONVCT( C,R ) = .TRUE.

!            IF ( ( R .EQ. MY_NROWS / 2 ) .AND. ( C .EQ. MY_NCOLS / 2 ) )
!     &         WRITE( LOGDEV,1011 ) CONVCT( C,R ), HOL( C,R ), XPBL( C,R ),
!     &                              LPBL( C,R )
!1011           FORMAT( ' CONVCT, HOL, XPBL, LPBL: ', L3, 1X, 1PE13.5, F8.5, I4 )
         END DO
      END DO

      MEDDYV = 0.0

C get ghost values for wind fields in case of free trop.

      CALL SE_COMM ( UWIND, DSPL_N0_E1_S0_W0, DRCN_E )
      CALL SE_COMM ( VWIND, DSPL_N1_E0_S0_W0, DRCN_N )

      DO 233 L = 1, NLAYS-1
      DO 222 R = 1, MY_NROWS
      DO 211 C = 1, MY_NCOLS
!        GAMOCF( C,R,L ) = 0.0
         HPBL = MAX( PBL( C,R ), 20.0 )
         ZFL = ZF( C,R,L )
         KZM = KZMIN( C,R,L )

         IF ( ZFL .LT. HPBL ) THEN
            ZOL = ZFL * MOLI( C,R )
            IF ( ZOL .LT. 0.0 ) THEN
               IF ( ZFL .LT. 0.1 * HPBL ) THEN
                  PHIH = 1.0 / SQRT( 1.0 - GAMH * ZOL )
!                 PHIM = 1.0 / (1.0 - GAMH * ZOL ) ** 0.3333333
!                 WM = USTAR( C,R ) / PHIM
!                 PR = PHIH / PHIM
!                    + ZF( C,R,L ) / HPBL * CGAM * KARMAN * WSTAR( C,R ) / WM
!                 WT =  USTAR( C,R ) / PHIH
               ELSE
                  ZSOL = 0.1 * HOL( C,R )
                  PHIH = 1.0 / SQRT( 1.0 - GAMH * ZSOL )
!                 PHIM = 1.0 / ( 1.0 - GAMH * ZSOL ) ** 0.3333333
!                 WM = USTAR( C,R ) / PHIM
!                 PR = PHIH / PHIM + 0.1 * CGAM * KARMAN * WSTAR( C,R ) / WM
!                 WT =  USTAR( C,R ) / PHIH
               END IF
!              GAMOCF( C,R,L ) = CGAM * WSTAR( C,R ) / ( WM * WM * HPBL )
            ELSE IF ( ZOL .LT. 1.0 ) THEN
               PHIH = 1.0 + BETAH * ZOL
!              WT = USTAR( C,R ) / PHIH
            ELSE
               PHIH = BETAH + ZOL
!              WT = USTAR( C,R ) / PHIH
            END IF
            WT = USTAR( C,R ) / PHIH
            ZFUNC = ZFL * ( 1.0 - ZFL / HPBL ) ** 2
            EDYZ = KARMAN * WT * ZFUNC
            EDYZ = MAX( EDYZ, KZM )
         ELSE
            EDYZ = 0.0
         END IF

         DZL = ZH( C,R,L+1 ) - ZH( C,R,L )
!        RIC = 0.257 * DZL ** 0.175
         WW2 = 0.25 * MSFX2( C,R )      ! component-wise wind shear
     &           * ( ( UWIND( C+1,R,  L+1 ) - UWIND( C+1,R  ,L  )
     &               + UWIND( C,  R,  L+1 ) - UWIND( C,  R  ,L  ) ) ** 2
     &           +   ( VWIND( C,  R+1,L+1 ) - VWIND( C,  R+1,L )
     &               + VWIND( C,  R,  L+1 ) - VWIND( C,  R,  L  ) ) ** 2 )
         WS2 = WW2 / ( DZL * DZL ) + 1.0E-9

         RIB = 2.0 * GRAV * ( THETAV( C,R,L+1 ) - THETAV( C,R,L ) )
     &       / ( DZL * WS2 * ( THETAV( C,R,L+1 ) + THETAV( C,R,L ) ) )

C-- Adjustment to vert diff in Moist air from HIRPBL

         IF ( ( QC( C,R,L ) .GT. 0.01E-3 ) .AND.
     &        ( QC( C,R,L+1 ) .GT. 0.01E-3 ) ) THEN
            QMEAN = 0.5 * ( QV( C,R,L ) + QV( C,R,L+1 ) )
            TMEAN = 0.5 * ( TA( C,R,L ) + TA( C,R,L+1 ) )
            XLV = ( 2.501 - 0.00237 * ( TMEAN - 273.15 ) ) * 1.0E6
            ALPH = XLV * QMEAN / RDGAS / TMEAN
            CPAIR = 1004.67 * ( 1.0 + 0.84 * QV( C,R,L ) )   ! J/(K KG)
            CHI = XLV * XLV * QMEAN / ( CPAIR * RWVAP * TMEAN * TMEAN )
            RIB = ( 1.0 + ALPH )
     &          * ( RIB - GRAV * GRAV / ( WS2 * TMEAN * CPAIR )
     &          * ( ( CHI - ALPH ) / ( 1.0 + CHI ) ) )
         END IF

C-----------------

         ZK = 0.4 * ZFL
!        SQL = ( ZK * RLAM / ( RLAM + ZK ) ) ** 2
         SQL = ZK * RLAM / ( RLAM + ZK )
         SQL = SQL * SQL

         IF ( RIB .GE. RIC ) THEN
            EDDV = KZM
         ELSE IF ( RIB .GE. 0.0 ) THEN
            EDDV = KZM + SQRT( WS2 ) * ( 1.0 - RIB / RIC ) ** 2 * SQL
         ELSE
            EDDV = KZM + SQRT( WS2 * ( 1.0 - 25.0 * RIB ) ) * SQL
         END IF

         IF ( ZFL .LT. HPBL ) THEN
            IF ( EDYZ .GT. EDDV ) THEN
               EDDV = EDYZ
            ELSE
               IF ( ZOL .GT. 0.0 ) EDDV = EDYZ
            END IF
         END IF

         EDDV = MIN( 1000.0, EDDV )

         IF ( EDDV .GT. MEDDYV ) THEN
C Capture the col, row, lvl, and EDDYV for the global min DT
            MCOL = C
            MROW = R
            MLVL = L
            MEDDYV = EDDV
            MTH1 = THETAV( C,R,L )
            MTH2 = THETAV( C,R,L+1 )
            MRIB = RIB
            MWS  = SQRT ( WS2 )
         END IF

         EDDYV( C,R,L ) = EDDV

211   CONTINUE       !  end loop on columns
222   CONTINUE       !  end loop on rows
233   CONTINUE       !  end loop on levels

      WRITE( LOGDEV,* ) '    '
      WRITE( LOGDEV,1001 ) MEDDYV, MCOL, MROW, MLVL
1001  FORMAT(/ 5X, 'Maximum eddy diffusivity of:', 1PG13.5,
     &         1X, '(m**2/sec)'
     &       / 5X, 'at col, row, layer:', I4, 2(', ', I3))
      WRITE( LOGDEV,1003 ) MWS, MRIB, MTH1, MTH2
1003  FORMAT(  5X, 'corresponding to a free tropospheric wind shear of:',
     &         1PG13.5,  1X, '(/sec),'
     &        /28X, 'a bulk Richardson Number of:', 1PG13.5, ','
     &        / 5X, 'and pot. temps. in layer and layer+1:', 2(1PG13.5))
      WRITE( LOGDEV,* ) '    '

      DO R = 1, MY_NROWS
         DO C = 1, MY_NCOLS
            EDDYV( C,R,NLAYS ) = 0.0
         END DO
      END DO

      RETURN
      END