
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
C $Header: /project/work/rep/CCTM/src/vdiff/acm2/vdiffacm2.F,v 1.5 2007/01/08 14:45:05 sjr Exp $

C what(1) key, module and SID; SCCS file; date and time of last delta:
C @(#)vdiffim.F 1.8 /project/mod3/CMAQ/src/vdiff/eddy/SCCS/s.vdiffim.F 25 Jul 1997 12:57:45

C:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
      SUBROUTINE VDIFF ( JDATE, JTIME, TSTEP )

C-----------------------------------------------------------------------
C Asymmetric Convective Model v2 (ACM2) -- Pleim(2006)
C Function:
C   calculates and writes dry deposition.
C   calculates vertical diffusion


C Subroutines and Functions Called:
C   INIT3, SEC2TIME, TIME2SEC, WRITE3, NEXTIME,
C   M3EXIT, EDDYX, TRI, MATRIX, PA_UPDATE_EMIS, PA_UPDATE_DDEP

C Revision History:
C   Analogous to VDIFFIM (Eddy diffusion PBL scheme)

C   31 Jan 05 J.Young: dyn alloc - establish both horizontal & vertical
C                      domain specifications in one module (GRID_CONF)
C    7 Jun 05 P.Bhave: added call to OPSSEMIS if MECHNAME='AE4';
C                      added TSTEP to RDEMIS_AE call vector
C    Aug 05 J. Pleim Update to v4.5
C
C    Jan 06 J. Pleim ACM2 implementation
C-----------------------------------------------------------------------

      USE CGRID_DEFN          ! inherits GRID_CONF and CGRID_SPCS
      USE AERO_EMIS           ! inherits GRID_CONF
      USE DDEP_DEFN           ! inherits HGRD_DEFN

      USE SE_MODULES              ! stenex
!     USE SUBST_GLOBAL_SUM_MODULE    ! stenex

      IMPLICIT NONE

!     INCLUDE SUBST_HGRD_ID   ! horizontal dimensioning parameters
!     INCLUDE SUBST_VGRD_ID   ! vertical dimensioning parameters
      INCLUDE "/meso/save/wx20jy/cctm/BLD_u5a/RXCM.EXT"    ! model mechanism name

      INCLUDE "/meso/save/wx20jy/cctm/BLD_u5a/GC_SPC.EXT"    ! gas chemistry species table
      INCLUDE "/meso/save/wx20jy/cctm/BLD_u5a/GC_EMIS.EXT"   ! gas chem emis surrogate names and map table
!     INCLUDE "/meso/save/wx20jy/cctm/BLD_u5a/GC_DEPV.EXT"   ! gas chem dep vel surrogate names and map table
!     INCLUDE "/meso/save/wx20jy/cctm/BLD_u5a/GC_DDEP.EXT"   ! gas chem dry dep species and map table
      INCLUDE "/meso/save/wx20jy/cctm/BLD_u5a/GC_DIFF.EXT"   ! gas chem diffusion species and map table

      INCLUDE "/meso/save/wx20jy/cctm/BLD_u5a/AE_SPC.EXT"    ! aerosol species table
!     INCLUDE "/meso/save/wx20jy/cctm/BLD_u5a/AE_EMIS.EXT"   ! aerosol emis surrogate names and map table
!     INCLUDE "/meso/save/wx20jy/cctm/BLD_u5a/AE_DEPV.EXT"   ! aerosol dep vel surrogate names and map table
!     INCLUDE "/meso/save/wx20jy/cctm/BLD_u5a/AE_DDEP.EXT"   ! aerosol dry dep species and map table
      INCLUDE "/meso/save/wx20jy/cctm/BLD_u5a/AE_DIFF.EXT"   ! aerosol diffusion species and map table

      INCLUDE "/meso/save/wx20jy/cctm/BLD_u5a/NR_SPC.EXT"    ! non-reactive species table
      INCLUDE "/meso/save/wx20jy/cctm/BLD_u5a/NR_EMIS.EXT"   ! non-react emis surrogate names and map table
!     INCLUDE "/meso/save/wx20jy/cctm/BLD_u5a/NR_DEPV.EXT"   ! non-react dep vel surrogate names and map table
!     INCLUDE "/meso/save/wx20jy/cctm/BLD_u5a/NR_DDEP.EXT"   ! non-react dry dep species and map table
      INCLUDE "/meso/save/wx20jy/cctm/BLD_u5a/NR_DIFF.EXT"   ! non-react diffusion species and map table

      INCLUDE "/meso/save/wx20jy/cctm/BLD_u5a/TR_SPC.EXT"    ! tracer species table
      INCLUDE "/meso/save/wx20jy/cctm/BLD_u5a/TR_EMIS.EXT"   ! tracer emis surrogate names and map table
!     INCLUDE "/meso/save/wx20jy/cctm/BLD_u5a/TR_DEPV.EXT"   ! tracer dep vel surrogate names and map table
!     INCLUDE "/meso/save/wx20jy/cctm/BLD_u5a/TR_DDEP.EXT"   ! tracer dry dep species and map table
      INCLUDE "/meso/save/wx20jy/cctm/BLD_u5a/TR_DIFF.EXT"   ! tracer diffusion species and map table

!     INCLUDE SUBST_EMLYRS_ID ! emissions layers parameter
      INCLUDE "/meso/save/wx20jy/cctm/BLD_u5a/EMISPRM.vdif.EXT"   ! emissions processing in vdif 
      INCLUDE "/meso/save/wx20jy/cctm/BLD_u5a/PA_CTL.EXT"  ! PA control parameters
!     INCLUDE "/meso/save/wx20jy/cctm/BLD_u5a/CONST.EXT"     ! constants
      INCLUDE "/meso/save/wx20jy/cctm/BLD_u5a/FILES_CTM.EXT"  ! file name parameters
      INCLUDE "/meso/save/wx20dw/tools/ioapi_3/ioapi/fixed_src/PARMS3.EXT"   ! I/O parameters definitions

!.........................................................................
! Version "@(#)$Header$"
!    EDSS/Models-3 I/O API.  Copyright (C) 1992-2002 MCNC
!    Distributed under the GNU LESSER GENERAL PUBLIC LICENSE version 2.1
!    See file "LGPL.txt" for conditions of use.
!....................................................................
!  INCLUDE FILE  IODECL3.EXT
!
!
!  DO NOT EDIT !!
!
!       The EDSS/Models-3 I/O API depends in an essential manner
!       upon the contents of this INCLUDE file.  ANY CHANGES are
!       likely to result in very obscure, difficult-to-diagnose
!       bugs caused by an inconsistency between standard "libioapi.a"
!       object-libraries and whatever code is compiled with the
!       resulting modified INCLUDE-file.
!
!       By making any changes to this INCLUDE file, the user
!       explicitly agrees that in the case any assistance is 
!       required of MCNC or of the I/O API author, Carlie J. Coats, Jr.
!       as a result of such changes, THE USER AND/OR HIS PROJECT OR
!       CONTRACT AGREES TO REIMBURSE MCNC AND/OR THE I/O API AUTHOR,
!       CARLIE J. COATS, JR., AT A RATE TRIPLE THE NORMAL CONTRACT
!       RATE FOR THE SERVICES REQUIRED.
!
!  CONTAINS:  declarations and usage comments for the Models-3 (M3)
!             Interprocess Communication Applications Programming
!             Interface (API)
!
!  DEPENDENT UPON:  consistency with the API itself.
!
!  RELATED FILES:  PARM3.EXT, FDESC3.EXT
!
!  REVISION HISTORY:
!       prototype 3/1992 by Carlie J. Coats, Jr., MCNC Environmental
!       Programs
!
!       Modified  2/2002 by CJC:  updated dates, license, compatibility
!       with both free and fixed Fortran 9x source forms
!
!....................................................................

        LOGICAL         CHECK3  !  is JDATE:JTIME available for FNAME?
        LOGICAL         CLOSE3  !  close FNAME
        LOGICAL         DESC3   !  Puts M3 file descriptions into FDESC3.EXT
        LOGICAL         FILCHK3 ! check file type and dimensions
        INTEGER         INIT3   !  Initializes M3 API and returns unit for log
        LOGICAL         SHUT3   !  Shuts down API
        LOGICAL         OPEN3   !  opens an M3 file
        LOGICAL         READ3   !  read M3 file for variable,layer,timestep
        LOGICAL         WRITE3  !  write timestep to M3 file
        LOGICAL         XTRACT3 !  extract window from timestep in a M3 file
        LOGICAL         INTERP3 !  do time interpolation from a M3 file
        LOGICAL         DDTVAR3 !  do time derivative from M3 file

        LOGICAL         INTERPX !  time interpolation from a window
                                !  extraction from an M3 gridded file
!!        LOGICAL      PINTERPB !  1 time interpolation from an
                                !  M3 boundary file

        LOGICAL         INQATT3 !  inquire attributes in M3 file
        LOGICAL         RDATT3  !  read numeric attributes by name from M3 file
        LOGICAL         WRATT3  !  add new numeric attributes "
        LOGICAL         RDATTC  !  read CHAR attributes       "
        LOGICAL         WRATTC  !  add new CHAR attributes    "

        LOGICAL         SYNC3   !  flushes file to disk, etc.

        EXTERNAL        CHECK3 , CLOSE3,  DESC3  , FILCHK3, INIT3  ,
     &                  SHUT3  , OPEN3  , READ3  , WRITE3 , XTRACT3,
     &                  INTERP3, DDTVAR3, INQATT3, RDATT3 , WRATT3 ,
     &                  RDATTC , WRATTC,  SYNC3,   INTERPX ! , PINTERPB

!.......................................................................
!..................  API FUNCTION USAGE AND EXAMPLES  ..................
!.......
!.......   In the examples below, names (FILENAME, PROGNAME, VARNAME)
!.......   should be CHARACTER*16, STATUS and RDFLAG are LOGICAL, dates
!.......   are INTEGER, coding the Julian date as YYYYDDD, times are
!.......   INTEGER, coding the time as HHMMSS, and LOGDEV is the FORTRAN
!.......   INTEGER unit number for the program's log file; and layer,
!.......   row, and column specifications use INTEGER FORTRAN array
!.......   index conventions (in particular, they are based at 1, not
!.......   based at 0, as in C).
!.......   Parameter values for "ALL...", for grid and file type IDs,
!.......   and for API dimensioning values are given in PARMS3.EXT;
!.......   file descriptions are passed via commons BDESC3 and CDESC3
!.......   in file FDESC3.EXT.
!.......
!.......   CHECK3():  check whether timestep JDATE:JTIME is available 
!.......   for variable VNAME in file FILENAME.
!.......   FORTRAN usage is:
!.......
!.......       STATUS = CHECK3 ( FILENAME, VNAME, JDATE, JTIME )
!.......       IF ( .NOT. STATUS ) THEN
!.......           ... (data-record not available in file FNAME)
!.......       END IF
!.......
!.......   CLOSE3():  check whether timestep JDATE:JTIME is available 
!.......   for variable VNAME in file FILENAME.
!.......   FORTRAN usage is:
!.......
!.......       STATUS = CLOSE3 ( FILENAME )
!.......       IF ( .NOT. STATUS ) THEN
!.......           ... could not flush file to disk successfully,
!.......           or else file not currently open.
!.......       END IF
!.......
!.......   DESC3():   return description of file FILENAME to the user
!.......   in commons BDESC3 and CDESC3, file FDESC3.EXT.
!.......   FORTRAN usage is:
!.......
!.......       STATUS = DESC3 ( FILENAME )
!.......       IF ( .NOT. STATUS ) THEN
!.......           ... (file not yet opened)
!.......       END IF
!.......       ...
!.......       (Now common FDESC3 (file FDESC3.EXT) contains the descriptive
!.......       information for this file.)
!.......
!.......   FILCHK3():   check whether file type and dimensions for file 
!.......   FILENAME match the type and dimensions supplied by the user.
!.......   FORTRAN usage is:
!.......
!.......       STATUS = FILCHK3 ( FILENAME, FTYPE, NCOLS, NROWS, NLAYS, NTHIK )
!.......       IF ( .NOT. STATUS ) THEN
!.......           ... (file type and dimensions do not match
!.......                the supplied FTYPE, NCOLS, NROWS, NLAYS, NTHIK)
!.......       END IF
!.......       ...
!.......
!.......   INIT3():  set up the M3 API, open the program's log file, and
!.......   return the unit FORTRAN number for log file.  May be called
!.......   multiple times (in which case, it always returns the log-file's
!.......   unit number).  Note that block data INITBLK3.FOR must also be
!.......   linked in.
!.......   FORTRAN usage is:
!.......
!.......       LOGDEV = INIT3 ( )
!.......       IF ( LOGDEV .LT. 0 ) THEN
!.......           ... (can't proceed:  probably can't open the log.
!.......                Stop the program)
!.......       END IF
!.......
!.......   OPEN3():  open file FILENAME from program PROGNAME, with
!.......   requested read-write/old-new status.  For files opened for WRITE,
!.......   record program-name and other history info in their headers.
!.......   May be called multiple times for the same file (in which case,
!.......   it returns true unless the request is for READ-WRITE status
!.......   for a file already opened READ-ONLY).  Legal statuses are:
!.......   FSREAD3: "old read-only"
!.......   FSRDWR3: "old read-write"
!.......   FSNEW3:  "new (read-write)"
!.......   FSUNKN3: "unknown (read_write)"
!.......   FORTRAN usage is:
!.......
!.......       STATUS = OPEN3 ( FILENAME, FSTATUS, PROGNAME )
!.......       IF ( .NOT. STATUS ) THEN
!.......           ... (process the error)
!.......       END IF
!.......
!.......   READ3():  read data from FILENAME for timestep JDATE:JTIME,
!.......   variable VNAME, layer LAY, into location  ARRAY.
!.......   If VNAME==ALLVARS3=='ALL         ', reads all variables;
!.......   if LAY==ALLAYS3==-1, reads all layers.
!.......   Offers random access to the data by filename, date&time, variable,
!.......   and layer.  For DICTIONARY files, logical name for file being
!.......   requested maps into the VNAME argument.  For time-independent
!.......   files (including DICTIONARY files), JDATE and JTIME are ignored.
!.......   FORTRAN usage is:
!.......
!.......       STATUS = READ3 ( FILENAME, VNAME, LAY, JDATE, JTIME, ARRAY )
!.......       IF ( .NOT. STATUS ) THEN
!.......           ... (read failed -- process this error.)
!.......       END IF
!.......
!.......   SHUT3():  Flushes and closes down all M3 files currently open.
!.......   Must be called before program termination; if it returns FALSE
!.......   the run must be considered suspect.
!.......   FORTRAN usage is:
!.......
!.......       STATUS = SHUT3 ( )
!.......       IF ( .NOT. STATUS ) THEN
!.......           ... (Flush of files to disk probably didn't work;
!.......                look at netCDF error messages)
!.......       END IF
!.......
!.......   WRITE3():  write data from ARRAY to file FILENAME for timestep
!.......   JDATE:JTIME.  For GRIDDED, BUONDARY, and CUSTOM files, VNAME
!.......   must be a variable found in the file, or else ALLVARS3=='ALL'
!.......   to write all variables from ARRAY.  For other file types,
!.......   VNAME _must_ be ALLVARS3.
!.......   FORTRAN usage is:
!.......
!.......       STATUS = WRITE3 ( FILENAME, VNAME, JDATE, JTIME, ARRAY )
!.......       IF ( .NOT. STATUS ) THEN
!.......           ... (write failed -- process this error.)
!.......       END IF
!.......
!.......   XTRACT3():  read/extract gridded data into location  ARRAY
!.......   from FILENAME for time step JDATE:JTIME, variable VNAME
!.......   and the data window defined by
!.......       LOLAY  <=  layer   <=  HILAY,
!.......       LOROW  <=  row     <=  HIROW,
!.......       LOCOL  <=  column  <=  HICOL
!.......   FORTRAN usage is:
!.......
!.......       STATUS = XTRACT3 ( FILENAME, VNAME,
!.......   &                      LOLAY, HILAY,
!.......   &                      LOROW, HIROW,
!.......   &                      LOCOL, HICOL,
!.......   &                      JDATE, JTIME, ARRAY )
!.......       IF ( .NOT. STATUS ) THEN
!.......           ... (extract failed -- process this error.)
!.......       END IF
!.......
!.......   INTERP3():  read/interpolate gridded, boundary, or custom data 
!.......   into location  ARRAY from FILENAME for time JDATE:JTIME, variable 
!.......   VNAME, and all layers.  Note use of ASIZE = transaction size =
!.......   size of ARRAY, for error-checking.
!.......   FORTRAN usage is:
!.......
!.......       STATUS = INTERPX ( FILENAME, VNAME, CALLER, JDATE, JTIME,
!.......   &                      ASIZE, ARRAY )
!.......       IF ( .NOT. STATUS ) THEN
!.......           ... (interpolate failed -- process this error.)
!.......       END IF
!.......
!.......   INTERPX():  read/interpolate/window gridded, boundary, or custom
!.......   data into location  ARRAY from FILENAME for time JDATE:JTIME, 
!.......   variable VNAME, and all layers.
!.......   FORTRAN usage is:
!.......
!.......       STATUS = INTERPX ( FILENAME, VNAME, CALLER, 
!.......   &                      COL0, COL1, ROW0, ROW1, LAY0, LAY1,
!.......   &                      JDATE, JTIME, ARRAY )
!.......       IF ( .NOT. STATUS ) THEN
!.......           ... (windowed interpolate failed -- process this error.)
!.......       END IF
!.......
!.......   DDTVAR3():  read and calculate mean time derivative (per second) 
!.......   for gridded, boundary, or custom data.  Put result into location  
!.......   ARRAY from FILENAME for time JDATE:JTIME, variable VNAME, and all 
!.......   layers.  Note use of ASIZE = transaction size = size of ARRAY, 
!.......   for error-checking.  Note  d/dt( time-independent )==0.0
!.......   FORTRAN usage is:
!.......
!.......       STATUS = DDTVAR3 ( FILENAME, VNAME, JDATE, JTIME,
!.......   &                      ASIZE, ARRAY )
!.......       IF ( .NOT. STATUS ) THEN
!.......           ... (operation failed -- process this error.)
!.......       END IF
!.......
!.......   INQATT():  inquire how many attributes there are for a
!.......   particular file and variable (or for the file globally,
!.......   if the variable-name ALLVAR3 is used)), and what the 
!.......   names, types, and array-dimensions of these attributes are.
!.......   FORTRAN usage is:
!.......
!.......       STATUS = INQATT3( FNAME, VNAME, MXATTS, 
!.......   &                     NATTS, ANAMES, ATYPES, ASIZES )
!.......       IF ( .NOT. STATUS ) THEN
!.......           ... (operation failed -- process this error.)
!.......       END IF
!....... 
!.......   RDATT3():  Reads an INTEGER, REAL, or DOUBLE attribute by name
!.......   for a specified file and variable into a user-specified array.
!.......   If variable name is ALLVAR3, reads the file-global attribute.
!.......   FORTRAN usage is:
!.......
!.......       STATUS = RDATT3( FNAME, VNAME, ANAME, ATYPE, AMAX,
!.......   &                    ASIZE, AVAL )
!.......       IF ( .NOT. STATUS ) THEN
!.......           ... (operation failed -- process this error.)
!.......       END IF
!.......
!.......   WRATT3():  Writes an INTEGER, REAL, or DOUBLE attribute by name
!.......   for a specified file and variable.  If variable name is ALLVAR3, 
!.......   reads the file-global attribute.
!.......
!.......       STATUS =  WRATT3( FNAME, VNAME, 
!.......   &                     ANAME, ATYPE, AMAX, AVAL )
!.......       IF ( .NOT. STATUS ) THEN
!.......           ... (operation failed -- process this error.)
!.......       END IF
!.......   
!.......   RDATTC():  Reads a CHARACTER string attribute by name
!.......   for a specified file and variable into a user-specified array.
!.......   If variable name is ALLVAR3, reads the file-global attribute.
!.......   FORTRAN usage is:
!.......
!.......       STATUS = RDATTC( FNAME, VNAME, ANAME, CVAL )
!.......       IF ( .NOT. STATUS ) THEN
!.......           ... (operation failed -- process this error.)
!.......       END IF
!.......
!.......   WRATT3():  Writes a CHARACTER string attribute by name
!.......   for a specified file and variable.  If variable name is ALLVAR3, 
!.......   reads the file-global attribute.
!.......
!.......       STATUS =  WRATTC( FNAME, VNAME, ANAME, CVAL )
!.......       IF ( .NOT. STATUS ) THEN
!.......           ... (operation failed -- process this error.)
!.......       END IF
!.......
!.......   SYNC3():   Synchronize FILENAME with disk (flush output;
!.......   re-read header and invalidate data-buffers for input.
!.......   FORTRAN usage is:
!.......
!.......       STATUS = SYNC3 ( FILENAME )
!.......       IF ( .NOT. STATUS ) THEN
!.......           ... (file not yet opened, or disk-synch failed)
!.......       END IF
!.......       ...
!.......
!................   end   IODECL3.EXT   ....................................

!     INCLUDE SUBST_COORD_ID  ! coordinate and domain definitions (req IOPARMS)

      CHARACTER( 120 ) :: XMSG = ' '

C Arguments:

      INTEGER      JDATE        ! current model date, coded YYYYDDD
      INTEGER      JTIME        ! current model time, coded HHMMSS
      INTEGER      TSTEP( 2 )   ! time step vector (HHMMSS)
                                ! TSTEP(1) = local output step
                                ! TSTEP(2) = sciproc sync. step (chem)

C Parameters:

C explicit, THETA = 0, implicit, THETA = 1
      REAL, PARAMETER :: THETA = 0.5,  ! For dry deposition term
     &                   THBAR = 1.0 - THETA
      REAL THRAT  ! THBAR/THETA

!     INTEGER, PARAMETER :: N_SPC_DDEP = N_GC_DDEP
!    &                                 + N_AE_DDEP
!    &                                 + N_NR_DDEP
!    &                                 + N_TR_DDEP

C global dep vel species
!     INTEGER, PARAMETER :: N_SPC_DEPV = N_GC_DEPV
!    &                                 + N_AE_DEPV
!    &                                 + N_NR_DEPV
!    &                                 + N_TR_DEPV

C global diffusion species
      INTEGER, PARAMETER :: N_SPC_DIFF = N_GC_DIFF
     &                                 + N_AE_DIFF
     &                                 + N_NR_DIFF
     &                                 + N_TR_DIFF

C global emissions species

      INTEGER, SAVE      :: N_SPC_EMIS
!     INTEGER, PARAMETER :: N_SPC_EMIS = NEMIS
!!   &                                 + N_AE_EMIS
!    &                                 + N_NR_EMIS
!    &                                 + N_TR_EMIS

C ACM parameters

!     REAL, PARAMETER :: M2PHA = 1.0E+04       ! 1 hectare = 1.0e4 m**2
      REAL, PARAMETER :: CMLMR = 1.0E+06       ! ppmV/Molar Mixing Ratio
!     REAL, PARAMETER :: CNVTD = M2PHA / CMLMR / MWAIR ! combined ddep
                                                       ! conversion factor
!     REAL, PARAMETER :: GPKG = 1.0E+03        ! g/Kg
!     REAL, PARAMETER :: MGPG = 1.0E+06        ! micro-g/g

      REAL, PARAMETER :: CRANKP = 0.5
      REAL, PARAMETER :: CRANKQ = 1.0 - CRANKP
      REAL, PARAMETER :: KARMAN = 0.4
      REAL, PARAMETER :: EPS = 1.0E-06

!     INTEGER, PARAMETER :: IFACM2 = 1    ! 1 = acm2, 0 = acm1
      INTEGER, PARAMETER :: IFACM = 1     ! 1 = acm, 0 = no acm

C External Functions not previously declared in IODECL3.EXT:

      INTEGER, EXTERNAL :: SECSDIFF, SEC2TIME, TIME2SEC, SETUP_LOGDEV
      LOGICAL, EXTERNAL :: ENVYN

C File variables:

      REAL         RDEPVHT( NCOLS,NROWS )        ! air dens / dep vel height
      REAL         RJACM  ( NCOLS,NROWS,NLAYS )  ! reciprocal mid-layer Jacobian
      REAL         RVJACMF( NCOLS,NROWS,NLAYS )  ! 1/ mid-full layer vert Jac
      REAL         RRHOJ  ( NCOLS,NROWS,NLAYS )  ! reciprocal density X Jacobian
      REAL         DENS1  ( NCOLS,NROWS )        ! layer 1 air density
!     REAL         DEPV   ( NCOLS,NROWS,N_SPC_DEPV+1 ) ! deposition velocities
!     REAL         MDEPV  ( NCOLS,NROWS,N_SPC_DEPV+1 ) ! deposition velocities
                                                       ! X air density for all
                                                       ! but aerosol species
      REAL         DEPV  ( N_SPC_DEPV+1,NCOLS,NROWS ) ! dep vel X dens/msfx2

C Local Variables:

      CHARACTER( 16 ), SAVE :: PNAME = 'VDIFFIM'
      CHARACTER( 16 ), SAVE :: DDEP_SPC( N_SPC_DDEP + 1 )
      CHARACTER( 16 ), SAVE :: CTM_SSEMDIAG = 'CTM_SSEMDIAG'  ! env var for SSEMDIAG file
      CHARACTER( 80 ) :: VARDESC                ! environment variable description

      LOGICAL, SAVE :: FIRSTIME = .TRUE.
      INTEGER, SAVE :: WSTEP  = 0               ! local write counter
      INTEGER  STATUS                           ! ENV... status

      REAL          DX1, DX2                    ! CX x1- and x2-cell widths
      REAL, ALLOCATABLE, SAVE :: DX3F ( : )
      REAL, ALLOCATABLE, SAVE :: RDX3F( : )     ! reciprocal layer thickness
      REAL          X3M  ( NLAYS )              ! middle layer heigth
      REAL          DX3M ( NLAYS )              ! layer thickness at middle
      REAL, ALLOCATABLE, SAVE :: RDX3M( : )     ! reciprocal layer thickness
      REAL          CONVPA           ! conversion factor to pressure in Pascals
      REAL          CONVEM           ! conversion for emissions rates to Kg/s
      REAL, SAVE :: CNVTE                       ! combined conversion factor
      REAL       :: CNVTR                       ! combined conversion factor

      REAL, ALLOCATABLE, SAVE :: CNGRD( :,:,:,: )  ! cgrid replacement

!     REAL, ALLOCATABLE, SAVE :: DDEP( :,:,: )  ! ddep accumulator
!     REAL, ALLOCATABLE, SAVE :: DDEP_PA( :,:,: )! ddep for process analysis
      REAL          WRDD( NCOLS,NROWS )         ! ddep write buffer

      INTEGER, SAVE :: DEPV_MAP( N_SPC_DEPV+1 ) ! global depv map to CGRID
      INTEGER, SAVE :: DIFF_MAP( N_SPC_DIFF+1 ) ! global diff map to CGRID
      INTEGER, SAVE :: DF2DV   ( N_SPC_DIFF+1 ) ! map from diff spc to depv spc
      INTEGER, SAVE :: DF2EM   ( N_SPC_DIFF+1 ) ! map from diff spc to emis spc
      INTEGER, SAVE :: DD2DV   ( N_SPC_DDEP+1 ) ! map from ddep spc to depv spc
      INTEGER, SAVE :: DV2DF   ( N_SPC_DEPV )   ! map from depv spc to diff spc

      INTEGER, SAVE :: ELAYS                    ! no. of emis integration layers
                                                ! ELAYS must be .LT. NLAYS
      INTEGER          EMISLYRS                 ! no. of file emissions layers

      REAL, ALLOCATABLE, SAVE :: VDEMIS( :,:,:,: ) ! total emissions array
!     REAL, ALLOCATABLE, SAVE :: EMIS_PA( :,:,:,: ) ! emis for process analysis
      REAL, ALLOCATABLE, SAVE :: VDEMIS_AE( :,:,:,: ) ! aerosol emissions
      REAL, ALLOCATABLE, SAVE :: VDEMIS_NR( :,:,:,: ) ! nonreactive gas emis
      REAL, ALLOCATABLE, SAVE :: VDEMIS_TR( :,:,:,: ) ! tracer emissions

      LOGICAL, SAVE :: EM_TRAC = .FALSE.        ! do tracer emissions?
      LOGICAL, SAVE :: SSEMDIAG                 ! flag for creating SSEMIS
                                                ! output file
      INTEGER, SAVE :: NEMIS_AE                 ! no. of aero emis species
      INTEGER, SAVE :: N_SPC_CGRID              ! no. of CGRID species
!     INTEGER, SAVE :: NAESPCEMIS               ! no. of species on the PM
                                                ! emissions input file. Set in
                                                ! OPEMIS the value changes with
                                                ! the type of emissions file.

!     REAL, SAVE :: DD_CONV( N_SPC_DEPV+1 )     ! ddep spc conversion factors

      REAL         DD_FAC( N_SPC_DEPV)          ! combined subexpression
      REAL           DDBF( N_SPC_DEPV)          ! secondary DDEP
      REAL           CONC( N_SPC_DIFF,NLAYS )   ! secondary CGRID expression
      REAL           EMIS( N_SPC_DIFF,NLAYS )   ! emissions subexpression
      REAL         EDDYV ( NCOLS,NROWS,NLAYS )  ! from EDYINTB
      REAL         SEDDY ( NLAYS,NCOLS,NROWS )  ! flipped EDDYV
      INTEGER      NSTEPS( NCOLS,NROWS )        ! diffusion time steps
!     REAL         DT    ( NCOLS,NROWS )        ! eddy diff. delta T
      REAL         DELT                         ! DT
      REAL         DTDENS1                      ! DT * layer 1 air density
      REAL         DTSEC                        ! model time step in seconds

C ACM Local Variables
      REAL        MBAR                          ! ACM2 mixing rate (S-1)
      REAL        HOL   ( NCOLS,NROWS )         ! PBL over Monin-Obukhov Len
      REAL        XPBL  ( NCOLS,NROWS )         ! PBL HT in gen coords
      INTEGER     LPBL  ( NCOLS,NROWS )         ! layer containing PBL HT
      LOGICAL     CONVCT( NCOLS,NROWS )         ! flag for ACM
      REAL        MEDDY
      REAL        EDDY  ( NLAYS )
      REAL        MBARKS( NLAYS )               ! by layer
      REAL        MDWN  ( NLAYS )               ! ACM down mix rate
      REAL        MFAC                          ! intermediate loop factor
      REAL        AA    ( NLAYS )               ! matrix column one
      REAL        BB    ( NLAYS )               ! diagonal
      REAL        CC    ( NLAYS )               ! subdiagonal
      REAL        EE    ( NLAYS )               ! superdiagonal
      REAL        DD    ( N_SPC_DIFF,NLAYS )    ! R.H.S
      REAL        UU    ( N_SPC_DIFF,NLAYS )    ! returned solution
      REAL        XPLUS
      REAL        XMINUS
      REAL        EFAC1 ( N_SPC_DEPV )
      REAL        EFAC2 ( N_SPC_DEPV )
      REAL        FNL
      INTEGER     NLP, NL, LCBL
      REAL        DTLIM, DTS, DTACM, RZ, DELC, LFAC1, LFAC2

      INTEGER, SAVE :: LOGDEV
 
      INTEGER      ALLOCSTAT
      INTEGER      C, R, L, S, V, N             ! loop induction variables
      INTEGER      STRT, FINI                   ! loop induction variables
      INTEGER      MDATE, MTIME, MSTEP          ! internal simulation date&time

      LOGICAL, SAVE :: READEDDY = .FALSE.       ! eddyv from METCRO3D if .true.
      CHARACTER( 16 ) :: FILE_EDDY = 'FILE_EDDY'! env var for eddyv from file
                                                ! array in vert. mixing
!     LOGICAL, SAVE :: EDDY_STATS = .FALSE.
!     REAL DT_AVG                               ! avg eddy delta T 
!     REAL NSTP_AVG                             ! avg no. of integration steps

!     CHARACTER( 16 ) :: VNAME

      INTERFACE
!        SUBROUTINE RDMET( MDATE, MTIME, RDEPVHT, RJACM, RVJACMF, RRHOJ,
!    &                     DENS1 )
!           IMPLICIT NONE
!           INTEGER, INTENT( IN )       :: MDATE, MTIME
!           REAL, INTENT( OUT )         :: RDEPVHT( :,: )
!           REAL, INTENT( OUT )         :: RJACM  ( :,:,: )
!           REAL, INTENT( OUT )         :: RVJACMF( :,:,: )
!           REAL, INTENT( OUT )         :: RRHOJ  ( :,:,: )
!           REAL, INTENT( OUT )         :: DENS1  ( :,: )
!        END SUBROUTINE RDMET
!        SUBROUTINE RDDEPV ( MDATE, MTIME, MSTEP, CGRID, DEPV )
         SUBROUTINE RDDEPV ( MDATE, MTIME, MSTEP, DEPV )
            IMPLICIT NONE
            INTEGER, INTENT( IN )       :: MDATE, MTIME, MSTEP
!           REAL, POINTER               :: CGRID( :,:,:,: )
            REAL, INTENT( OUT )         :: DEPV( :,:,: )
         END SUBROUTINE RDDEPV
         SUBROUTINE RDEMIS_GC ( MDATE, MTIME, EMISLYRS, NSPC_EMIS, VDEMIS )
            IMPLICIT NONE
            INTEGER, INTENT( IN )       :: MDATE, MTIME, EMISLYRS, NSPC_EMIS
            REAL, INTENT( OUT )         :: VDEMIS( :,:,:,: )
         END SUBROUTINE RDEMIS_GC
         SUBROUTINE RDEMIS_NR ( MDATE, MTIME, EMISLYRS, NSPC_EMIS, VDEMIS )
            IMPLICIT NONE
            INTEGER, INTENT( IN )       :: MDATE, MTIME, EMISLYRS, NSPC_EMIS
            REAL, INTENT( OUT )         :: VDEMIS( :,:,:,: )
         END SUBROUTINE RDEMIS_NR
         SUBROUTINE RDEMIS_TR ( MDATE, MTIME, EMISLYRS, NSPC_EMIS, VDEMIS )
            IMPLICIT NONE
            INTEGER, INTENT( IN )       :: MDATE, MTIME, EMISLYRS, NSPC_EMIS
            REAL, INTENT( OUT )         :: VDEMIS( :,:,:,: )
         END SUBROUTINE RDEMIS_TR
!        SUBROUTINE PA_UPDATE_EMIS ( PNAME, VDEMIS, JDATE, JTIME, TSTEP )
!           IMPLICIT NONE
!           CHARACTER( * ), INTENT( IN ) :: PNAME
!           REAL, INTENT( IN )           :: VDEMIS( :,:,:,: )
!           INTEGER, INTENT( IN )        :: JDATE, JTIME
!           INTEGER, INTENT( IN )        :: TSTEP( 2 )
!        END SUBROUTINE PA_UPDATE_EMIS
!        SUBROUTINE PA_UPDATE_DDEP ( PNAME, DDEP, JDATE, JTIME, TSTEP )
!           IMPLICIT NONE
!           CHARACTER( * ), INTENT( IN ) :: PNAME
!           REAL, INTENT( IN )           :: DDEP( :,:,: )
!           INTEGER, INTENT( IN )        :: JDATE, JTIME
!           INTEGER, INTENT( IN )        :: TSTEP( 2 )
!        END SUBROUTINE PA_UPDATE_DDEP
!        SUBROUTINE CONV_CGRID ( CGRID, JDATE, JTIME, CNGRD )
         SUBROUTINE CONV_CGRID ( JDATE, JTIME, CNGRD )
            IMPLICIT NONE
!           REAL, POINTER :: CGRID( :,:,:,: )
            INTEGER, INTENT( IN )        :: JDATE, JTIME
            REAL, INTENT( OUT ) :: CNGRD( :,:,:,: )
         END SUBROUTINE CONV_CGRID
!        SUBROUTINE REV_CGRID ( CNGRD, JDATE, JTIME, CGRID )
         SUBROUTINE REV_CGRID ( CNGRD, JDATE, JTIME )
            IMPLICIT NONE
            REAL, INTENT( IN ) :: CNGRD( :,:,:,: )
            INTEGER, INTENT( IN )        :: JDATE, JTIME
!           REAL, POINTER :: CGRID( :,:,:,: )
         END SUBROUTINE REV_CGRID
         SUBROUTINE EDDYX ( JDATE, JTIME, TSTEP,
     &                      EDDYV, HOL, XPBL, LPBL, CONVCT )
            IMPLICIT NONE
            INTEGER, INTENT( IN )       :: JDATE, JTIME, TSTEP
            REAL, INTENT( OUT )         :: EDDYV ( :,:,: )
            REAL, INTENT( OUT )         :: HOL   ( :,: )
            REAL, INTENT( OUT )         :: XPBL  ( :,: )
            INTEGER, INTENT( OUT )      :: LPBL  ( :,: )
            LOGICAL, INTENT( OUT )      :: CONVCT( :,: )
         END SUBROUTINE EDDYX
      END INTERFACE

C-----------------------------------------------------------------------

      IF ( FIRSTIME ) THEN

         FIRSTIME = .FALSE.
         LOGDEV = INIT3()

C for emissions (form COORD.EXT) .......................................

         IF ( GDTYP_GD .EQ. LATGRD3 ) THEN
            DX1 = DG2M * XCELL_GD ! in m.
            DX2 = DG2M * YCELL_GD
     &          * COS( PI180*( YORIG_GD + YCELL_GD * FLOAT( GL_NROWS/2 ))) ! in m.
         ELSE
            DX1 = XCELL_GD        ! in m.
            DX2 = YCELL_GD        ! in m.
         END IF

C create global maps

         CALL VDIFF_MAP ( DF2EM, DF2DV, DD2DV, DEPV_MAP, DIFF_MAP, DDEP_SPC,
     &                    DV2DF )

C set vertical layer definitions from COORD.EXT

         ALLOCATE ( DX3F( NLAYS ),
     &              RDX3F( NLAYS ),
     &              RDX3M( NLAYS ), STAT = ALLOCSTAT )
         IF ( ALLOCSTAT .NE. 0 ) THEN
            XMSG = 'Failure allocating DX3F, RDX3F or RDX3M'
            CALL M3EXIT( PNAME, JDATE, JTIME, XMSG, XSTAT1 )
         END IF

         DO L = 1, NLAYS
            DX3F( L )  = X3FACE_GD( L ) - X3FACE_GD( L-1 )
            RDX3F( L ) = 1.0 / DX3F( L )
            X3M( L ) = 0.5 * ( X3FACE_GD( L ) + X3FACE_GD( L-1 ) )
         END DO

         DO L = 1, NLAYS - 1
            RDX3M( L ) = 1.0 / ( X3M( L+1 ) - X3M( L ) )
         END DO
         RDX3M( NLAYS ) = 0.0

C set molecular weights

!        S = 0
!        DO V = 1, N_GC_DEPV
!           S = S + 1
!           DD_CONV( S ) = CNVTD * GC_MOLWT( GC_DEPV_MAP( V ) )
!        END DO 

!        DO V = 1, N_AE_DEPV
!           S = S + 1
!           IF ( AE_SPC( AE_DEPV_MAP( V ) )( 1:3 ) .EQ. 'NUM' ) THEN
!!             DD_CONV( S ) = M2PHA ! irrelevant, since not deposited
!              DD_CONV( S ) = CNVTD * AVO * 1.0E+03    ! --> #/Ha
!           ELSE IF ( AE_SPC( AE_DEPV_MAP( V ) )( 1:3 ) .EQ. 'SRF' ) THEN
!!             DD_CONV( S ) = M2PHA ! irrelevant, since not deposited
!              DD_CONV( S ) = M2PHA * 1.0E+03 / MWAIR  ! --> M**2/Ha
!           ELSE
!!             DD_CONV( S ) = M2PHA / GPKG / MGPG
!              DD_CONV( S ) = CNVTD * AE_MOLWT( AE_DEPV_MAP( V ) )
!           END IF
!        END DO

!        DO V = 1, N_NR_DEPV
!           S = S + 1
!           DD_CONV( S ) = CNVTD * NR_MOLWT( NR_DEPV_MAP( V ) )
!        END DO

!        DO V = 1, N_TR_DEPV
!           S = S + 1
!           DD_CONV( S ) = CNVTD * TR_MOLWT( TR_DEPV_MAP( V ) )
!        END DO

C Open the met files

         CALL OPMET ( JDATE, JTIME, CONVPA )
 
C Open Emissions files

         CALL OPEMIS ( JDATE, JTIME, NEMIS, EM_TRAC, CONVEM, EMISLYRS )


         ELAYS = MIN ( EMISLYRS, NLAYS - 1 )

C Set output file characteristics based on COORD.EXT and open the dry dep file

!        IF ( MYPE .EQ. 0 ) CALL OPDDEP ( JDATE, JTIME, TSTEP( 1 ), N_SPC_DDEP )

C Get sea-salt-emission diagnostic file flag 

         SSEMDIAG = .FALSE.         ! default
         VARDESC = 'Flag for writing the sea-salt-emission diagnostic file'
         SSEMDIAG = ENVYN( CTM_SSEMDIAG, VARDESC, SSEMDIAG, STATUS )
         IF ( STATUS .NE. 0 ) WRITE( LOGDEV, '(5X, A)' ) VARDESC
         IF ( STATUS .EQ. 1 ) THEN
            XMSG = 'Environment variable improperly formatted'
            CALL M3EXIT ( PNAME, JDATE, JTIME, XMSG, XSTAT2 )
         ELSE IF ( STATUS .EQ. -1 ) THEN
            XMSG =
     &          'Environment variable set, but empty ... Using default:'
            WRITE( LOGDEV, '(5X, A, I9)' ) XMSG, JTIME
         ELSE IF ( STATUS .EQ. -2 ) THEN
            XMSG = 'Environment variable not set ... Using default:'
            WRITE( LOGDEV, '(5X, A, I9)' ) XMSG, JTIME
         END IF

C Open the sea-salt emission file if running the AE4 aerosol mechanism

         IF ( ( INDEX ( MECHNAME, 'AE4' ) .GT. 0 ) .AND. SSEMDIAG ) THEN
            IF ( MYPE .EQ. 0 ) CALL OPSSEMIS ( JDATE, JTIME, TSTEP( 1 ) )
         END IF

C Allocate and initialize dry deposition array

!        ALLOCATE ( DDEP( N_SPC_DEPV,MY_NCOLS,MY_NROWS ), STAT = ALLOCSTAT )
!        IF ( ALLOCSTAT .NE. 0 ) THEN
!           XMSG = 'Failure allocating DDEP'
!           CALL M3EXIT( PNAME, JDATE, JTIME, XMSG, XSTAT1 )
!        END IF
            
!        DDEP = 0.0

         IF ( N_AE_SPC .GT. 0 ) THEN
            WRITE( LOGDEV,'( /5X, A )' ) 'Aerosol Emissions Processing in '
     &                                // 'Vertical diffusion ...'
            NEMIS_AE = N_AE_EMIS  ! from AE_EMIS.EXT
         ELSE
            NEMIS_AE = 0
         END IF

         N_SPC_EMIS = NEMIS
     &              + NEMIS_AE
     &              + N_NR_EMIS
     &              + N_TR_EMIS

         ALLOCATE ( VDEMIS ( N_SPC_EMIS+1,ELAYS,MY_NCOLS,MY_NROWS ),
     &              STAT = ALLOCSTAT )
         IF ( ALLOCSTAT .NE. 0 ) THEN
            XMSG = 'VDEMIS memory allocation failed'
            CALL M3EXIT ( PNAME, JDATE, JTIME, XMSG, XSTAT1 )
         END IF

         IF ( N_AE_SPC .GT. 0 ) THEN
            ALLOCATE ( VDEMIS_AE( NEMIS_AE,ELAYS,MY_NCOLS,MY_NROWS ),
     &                 STAT = ALLOCSTAT )
            IF ( ALLOCSTAT .NE. 0 ) THEN
               XMSG = 'VDEMIS_AE memory allocation failed'
               CALL M3EXIT ( PNAME, JDATE, JTIME, XMSG, XSTAT1 )
            END IF
         END IF

         IF ( N_NR_EMIS .GT. 0 ) THEN
            ALLOCATE ( VDEMIS_NR( N_NR_EMIS,ELAYS,MY_NCOLS,MY_NROWS ),
     &                 STAT = ALLOCSTAT )
            IF ( ALLOCSTAT .NE. 0 ) THEN
               XMSG = 'VDEMIS_NR memory allocation failed'
               CALL M3EXIT ( PNAME, JDATE, JTIME, XMSG, XSTAT1 )
            END IF
         END IF

         IF ( EM_TRAC .AND. N_TR_EMIS .GT. 0 ) THEN
            ALLOCATE ( VDEMIS_TR( N_TR_EMIS,ELAYS,MY_NCOLS,MY_NROWS ),
     &                 STAT = ALLOCSTAT )
            IF ( ALLOCSTAT .NE. 0 ) THEN
               XMSG = 'VDEMIS_TR memory allocation failed'
               CALL M3EXIT ( PNAME, JDATE, JTIME, XMSG, XSTAT1 )
            END IF
         END IF

!        IF ( LIPR ) THEN
!           ALLOCATE ( EMIS_PA( MY_NCOLS,MY_NROWS,ELAYS,N_SPC_EMIS+1 ),
!    &                 STAT = ALLOCSTAT )
!           IF ( ALLOCSTAT .NE. 0 ) THEN
!              XMSG = 'EMIS_PA memory allocation failed'
!              CALL M3EXIT ( PNAME, JDATE, JTIME, XMSG, XSTAT1 )
!           END IF
!           ALLOCATE ( DDEP_PA( MY_NCOLS,MY_NROWS,N_SPC_DEPV ),
!    &                 STAT = ALLOCSTAT )
!           IF ( ALLOCSTAT .NE. 0 ) THEN
!              XMSG = 'DDEP_PA memory allocation failed'
!              CALL M3EXIT ( PNAME, JDATE, JTIME, XMSG, XSTAT1 )
!           END IF
!        END IF

C combined gas emssions conversion factor

         CNVTE = CMLMR * CONVPA * CONVEM * MWAIR / ( DX1 * DX2 )

         N_SPC_CGRID = SIZE ( CGRID,4 )

         ALLOCATE ( CNGRD( N_SPC_CGRID,NLAYS,MY_NCOLS,MY_NROWS ),
     &              STAT = ALLOCSTAT )
         IF ( ALLOCSTAT .NE. 0 ) THEN
            XMSG = 'Failure allocating CNGRD'
            CALL M3EXIT( PNAME, JDATE, JTIME, XMSG, XSTAT1 )
         END IF

         CNGRD = 0.0

         READEDDY = ENVYN( FILE_EDDY, 'Read eddyv from file', READEDDY, FINI )
         IF ( FINI .EQ. 1 ) THEN
            XMSG = 'Environment variable FILE_EDDY improperly formatted'
            CALL M3EXIT( PNAME, JDATE, JTIME, XMSG, XSTAT2 )
            ELSE IF ( FINI .EQ. -1 ) THEN
            XMSG = 'Environment variable FILE_EDDY set, but empty'
     &           // ' ... Using default:'
            WRITE( LOGDEV, '(5X, A, 1X, L4)' ) XMSG, READEDDY
            ELSE IF ( FINI .EQ. -2 ) THEN
            XMSG = 'Environment variable FILE_EDDY not set ... Using default:'
            WRITE( LOGDEV, '(5X, A, 1X, L4)' ) XMSG, READEDDY
            END IF

      END IF          !  if Firstime

      MDATE = JDATE
      MTIME = JTIME
      MSTEP = TIME2SEC( TSTEP( 2 ) )
      DTSEC = FLOAT( MSTEP )
      CALL NEXTIME ( MDATE, MTIME, SEC2TIME( MSTEP / 2 ) )

C read & interpolate met data

      CALL RDMET ( MDATE, MTIME, RDEPVHT, RJACM, RVJACMF, RRHOJ, DENS1 )

C read & interpolate deposition velocities

!     CALL RDDEPV ( MDATE, MTIME, TSTEP( 2 ), CGRID, DEPV )
      CALL RDDEPV ( MDATE, MTIME, TSTEP( 2 ), DEPV )

C Initialize deposition velocities for nondeposited species to zero

      DO R = 1, MY_NROWS
         DO C = 1, MY_NCOLS
            DEPV( N_SPC_DEPV+1,C,R ) = 0.0 ! accounts for dry dep. species
         END DO                            ! names as a subset of the
      END DO                               ! vert. diffused species list

C read & interpolate emissions (create VDEMIS in the species class order)

      VDEMIS = 0.0

      CALL RDEMIS_GC ( MDATE, MTIME, ELAYS, NEMIS, VDEMIS )

C reactive gases (conversion to ppmv/s) VDEMIS in this order from RDEMIS

      STRT = 1
      FINI = NEMIS
      DO R = 1, MY_NROWS
         DO C = 1, MY_NCOLS
            DO L = 1, ELAYS
               CNVTR = CNVTE * RDX3F( L ) * RRHOJ( C,R,L )
               DO V = STRT, FINI
                  VDEMIS( V,L,C,R ) = VDEMIS( V,L,C,R ) * CNVTR
               END DO
            END DO
         END DO
      END DO

C aerosol emissions - all units conversions done in RDEMIS_AE for aerosols

      IF ( N_AE_SPC .GT. 0 ) THEN
C        RDEMIS_AE in f90 module AERO_EMIS
         CALL RDEMIS_AE ( MDATE, MTIME, TSTEP, ELAYS, RJACM, VDEMIS, VDEMIS_AE )
      END IF

      STRT = NEMIS + 1
      FINI = NEMIS + NEMIS_AE
      DO R = 1, MY_NROWS
         DO C = 1, MY_NCOLS
            DO L = 1, ELAYS
               DO V = STRT, FINI
                  S = V + 1 - STRT
                  VDEMIS( V,L,C,R ) = VDEMIS_AE( S,L,C,R )
               END DO
            END DO
         END DO
      END DO

C non-reactive gases (conversion to ppmv/s) VDEMIS in this order from RDEMIS

      IF ( N_NR_EMIS .GT. 0 ) THEN
         CALL RDEMIS_NR ( MDATE, MTIME, ELAYS, N_NR_EMIS, VDEMIS_NR )
      END IF

      STRT = NEMIS + NEMIS_AE + 1
      FINI = NEMIS + NEMIS_AE + N_NR_EMIS
      DO R = 1, MY_NROWS
         DO C = 1, MY_NCOLS
            DO L = 1, ELAYS
               CNVTR = CNVTE * RDX3F( L ) * RRHOJ( C,R,L )
               DO V = STRT, FINI
                  S = V + 1 - STRT
                  VDEMIS( V,L,C,R ) = VDEMIS_NR( S,L,C,R ) * CNVTR
               END DO
            END DO
         END DO
      END DO

C tracer gases (conversion to ppmv/s)

      IF ( EM_TRAC .AND. N_TR_EMIS .GT. 0 ) THEN
         CALL RDEMIS_TR ( MDATE, MTIME, ELAYS, N_TR_EMIS, VDEMIS_TR )
      END IF

      STRT = NEMIS + NEMIS_AE + N_NR_EMIS + 1
      FINI = NEMIS + NEMIS_AE + N_NR_EMIS + N_TR_EMIS
      DO R = 1, MY_NROWS
         DO C = 1, MY_NCOLS
            DO L = 1, ELAYS
               CNVTR = CNVTE * RDX3F( L ) * RRHOJ( C,R,L )
               DO V = STRT, FINI
                  S = V + 1 - STRT
                  VDEMIS( V,L,C,R ) = VDEMIS_TR( S,L,C,R ) * CNVTR
               END DO
            END DO
         END DO
      END DO

C zero out emissions values for species not included in diffused list
CCCCCC UNNECESSARY - DONE ABOVE

!     DO R = 1, MY_NROWS
!        DO C = 1, MY_NCOLS
!           DO L = 1, ELAYS
!              VDEMIS( N_SPC_EMIS+1,L,C,R ) = 0.0  ! accounts for emissions
!           END DO                                 ! species names as a subset
!        END DO                                    ! of the vert. diffused
!     END DO                                       ! species list

!     IF ( LIPR ) THEN
!        DO S = 1, N_SPC_EMIS+1
!           DO L = 1, ELAYS
!              DO R = 1, MY_NROWS
!                 DO C = 1, MY_NCOLS
!                    EMIS_PA( C,R,L,S ) = VDEMIS( S,L,C,R )
!                 END DO
!              END DO
!           END DO
!        END DO
!        CALL PA_UPDATE_EMIS ( 'VDIF', EMIS_PA, JDATE, JTIME, TSTEP )
!     END IF

      IF ( READEDDY ) THEN
         CALL EDDYREAD ( JDATE, JTIME, TSTEP( 2 ), EDDYV )
         ELSE
         CALL EDDYX ( JDATE, JTIME, TSTEP( 2 ), EDDYV,
     &                HOL, XPBL, LPBL, CONVCT )
         END IF

C EDDYV returned = Kz, where Kz is in m**2/sec

      DO R = 1, MY_NROWS
         DO C = 1, MY_NCOLS
            DO L = 1, NLAYS
               SEDDY( L,C,R ) = EDDYV( C,R,L )
     &                        * RVJACMF( C,R,L ) * RDX3M( L ) ! * DELT
            END DO
         END DO
      END DO

      IF ( IFACM .EQ. 0 ) CONVCT = .FALSE.   ! no ACM

C Convert non-molar mixing ratio species and re-order CGRID

      CALL CONV_CGRID ( MDATE, MTIME, CNGRD )

      IF ( WSTEP .EQ. 0 ) DDEP = 0.0

C ------------------------------------------- Row, Col LOOPS -----------

      DO 345 R = 1, MY_NROWS
      DO 344 C = 1, MY_NCOLS

C ACM insert

         DTLIM = DTSEC

C Note: DT has been moved from EDDY to here, dt = .75 dzf dzh / Kz

         DO L = 1, NLAYS - 1
            DTLIM = MIN( DTLIM, 0.75 / ( SEDDY( L,C,R ) * RDX3F( L ) ) )
         END DO
         MBARKS = 0.0
         MDWN = 0.0

C New couple ACM & EDDY ------------------------------------------------

         MBAR = 0.0

         IF ( CONVCT( C,R ) ) THEN   ! Do ACM for this column
            LCBL = LPBL( C,R )
            MEDDY = SEDDY( 1,C,R ) / ( XPBL( C,R ) - X3FACE_GD( 1 ) )
            FNL = 1.0 / ( 1.0 + ( ( KARMAN / ( -HOL( C,R ) ) ) ** 0.3333 )
     &                / ( 0.72 * KARMAN ) )

!           IF ( FNL .GT. 1.0 ) WRITE( LOGDEV,* ) ' FNL= ', FNL

            MBAR = MEDDY * FNL
            DO L = 1, LCBL - 1
               SEDDY( L,C,R ) = SEDDY( L,C,R  ) * ( 1.0 - FNL )
            END DO

            IF ( MBAR .LT. EPS ) THEN
               WRITE( LOGDEV,* ) ' EDDYV, MBAR, FNL, HOL = ',
     &                             EDDYV( C,R,1 ), MBAR, FNL, HOL( C,R )
               CONVCT( C,R ) = .FALSE.
               LCBL = 1
               XMSG = '*** ACM fails ***'
               CALL M3EXIT( PNAME, MDATE, MTIME, XMSG, XSTAT2 )
            END IF

            IF ( ( FNL .LE. 0.0 ) .OR.   ! never gonna happen for CONVCT
     &           ( LCBL .GE. NLAYS-1 ) .OR.    ! .GT. never gonna happen
     &           ( HOL( C,R ) .GT. -0.00001 ) )   ! never gonna happen
     &         WRITE( LOGDEV,1015 ) LCBL, MBAR, FNL, EDDYV( C,R,1 ),
     &                              SEDDY( 1,C,R ), HOL( C,R )
1015           FORMAT( ' LCBL, MBAR, FNL, SEDDY1, HOL:', I3, 1X, 5(1PE13.5) )

            DO L = 1, LCBL - 1
               MBARKS( L ) = MBAR
               MDWN( L ) = MBAR * ( XPBL( C,R ) - X3FACE_GD( L-1 ) )
     &                   * RDX3F( L )
            END DO

            MBARKS( LCBL ) = MBAR * ( XPBL( C,R ) - X3FACE_GD( LCBL-1 ) )
     &                     * RDX3F( LCBL )
            MDWN( LCBL ) = MBARKS( LCBL )

C Modify Timestep for ACM

            RZ     = ( X3FACE_GD( LCBL ) - X3FACE_GD( 1 ) ) * RDX3F( 1 )
            DTACM  = 1.0 / ( MBAR * RZ )
            DTLIM  = MIN( 0.75 * DTACM, DTLIM )
         ELSE
            LCBL = 1
         END IF

C-----------------------------------------------------------------------

         NLP = INT( DTSEC / DTLIM + 0.99 )
         DTS = DTSEC / NLP
         DTDENS1 = DTS * DENS1( C,R )

!         IF ( R .EQ. MY_NROWS / 2 .AND. C .EQ. MY_NCOLS / 2 )
!     &      WRITE( LOGDEV,1021 ) CONVCT( C,R ), DTS, EDDYV( C,R,1 ),
!     &                           MBAR, FNL
!1021        FORMAT( ' CONVCT, DTS, EDDYV, MBAR, FNL: ',
!     &              L3, 1X, 4(1PE13.5) )

C End ACM insert

         DO L = 1, NLAYS
            DO V = 1, N_SPC_DIFF
               CONC( V,L ) = CNGRD( DIFF_MAP( V ),L,C,R )
!              CONC( V,L ) = CGRID( C,R,L,DIFF_MAP( V ) )
            END DO
         END DO

         DO V = 1, N_SPC_DEPV
!           DDBF( V ) = DDEP( V,C,R )
            DDBF( V ) = DDEP( C,R,V )
            DD_FAC( V ) = DTDENS1 * DD_CONV( V ) * DEPV( V,C,R )
         END DO

         EMIS = 0.0
         DO L = 1, ELAYS
            DO V = 1, N_SPC_DIFF
               EMIS( V,L ) = VDEMIS( DF2EM( V ),L,C,R ) * DTS
            END DO
         END DO

C-----------------------------------------------------------------------

         DO L = 1, NLAYS
            EDDY( L ) = SEDDY( L,C,R )
         END DO

         DO V = 1, N_SPC_DEPV
         EFAC1( V ) = EXP( -DEPV( V,C,R ) * RDEPVHT( C,R ) * THBAR * DTS )
         EFAC2( V ) = EXP( -DEPV( V,C,R ) * RDEPVHT( C,R ) * THETA * DTS )
         END DO

         DO 301 NL = 1, NLP      ! loop over sub time

            DO V = 1, N_SPC_DEPV
               DDBF( V ) = DDBF( V )
     &                   + THBAR * DD_FAC( V ) * CONC( DV2DF( V ),1 )
               CONC( DV2DF( V ),1 ) = EFAC1( V ) * CONC( DV2DF( V ),1 )
            END DO

C Init variables for use below

            DO L = 1, NLAYS
               AA( L ) = 0.0
               BB( L ) = 0.0
               CC( L ) = 0.0
               EE( L ) = 0.0
               DO V = 1, N_SPC_DIFF
                  DD( V,L ) = 0.0
                  UU( V,L ) = 0.0
               END DO
            END DO

C Compute tendency of CBL concentrations - semi-implicit solution
C Define arrays A,B,E which make up MATRIX and D which is RHS

            IF ( CONVCT( C,R ) ) THEN
               DO L = 2, LCBL
                  AA( L )   = -CRANKP * MBARKS( L ) * DTS
                  BB( L )   = 1.0 + CRANKP * MDWN( L ) * DTS
                  EE( L-1 ) = -CRANKP * MDWN( L ) * DTS * DX3F( L )
     &                      * RDX3F( L-1 )
                  MFAC = DX3F( L+1 ) * RDX3F( L ) * MDWN( L+1 )
                  DO V = 1, N_SPC_DIFF
                     DELC = DTS * ( MBARKS( L ) * CONC( V,1 )
     &                              - MDWN( L ) * CONC( V,L )
     &                              + MFAC      * CONC( V,L+1 ) )
                     DD( V,L ) = CONC( V,L ) + CRANKQ * DELC
                  END DO
               END DO
            END IF

            AA( 2 ) = AA( 2 ) - EDDY( 1 ) * CRANKP * RDX3F( 2 ) * DTS
            EE( 1 ) = EE( 1 ) - EDDY( 1 ) * CRANKP * RDX3F( 1 ) * DTS

            DO L = 2, NLAYS
               IF ( L .GT. LCBL ) THEN
                  BB( L ) = 1.0
                  DO V = 1, N_SPC_DIFF
                     DD( V,L ) = CONC( V,L )
                  END DO
               END IF
               XPLUS  = EDDY( L )   * RDX3F( L ) * DTS
               XMINUS = EDDY( L-1 ) * RDX3F( L ) * DTS
               BB( L ) = BB( L ) + ( XPLUS + XMINUS ) * CRANKP
               CC( L ) = - XMINUS * CRANKP
               EE( L ) = EE( L ) - XPLUS * CRANKP
               IF ( L .EQ. NLAYS ) THEN
                  DO V = 1, N_SPC_DIFF
                     DD( V,L ) = DD( V,L )
     &                         - CRANKQ * XMINUS
     &                         * ( CONC( V,L ) - CONC( V,L-1 ) )
                  END DO
               ELSE
                  LFAC1 = CRANKQ * XPLUS
                  LFAC2 = CRANKQ * XMINUS
                  DO V = 1, N_SPC_DIFF
                     DD( V,L ) = DD( V,L )
     &                         + LFAC1
     &                         * ( CONC( V,L+1 ) - CONC( V,L ) )
     &                         - LFAC2
     &                         * ( CONC( V,L ) - CONC( V,L-1 ) )
                     IF ( L .LE. ELAYS ) DD( V,L ) = DD( V,L ) + EMIS( V,L )
                  END DO
               END IF
            END DO

            BB( 1 ) = 1.0
            DO V = 1, N_SPC_DIFF
               DD( V,1 ) = CONC( V,1 )
            END DO

            IF ( CONVCT( C,R ) ) THEN
               LFAC1 = ( XPBL( C,R ) - X3FACE_GD( 1 ) ) * RDX3F( 1 ) * DTS
               LFAC2 = CRANKQ * MDWN( 2 ) * DX3F( 2 )
     &               * RDX3F( 1 ) * DTS
               BB( 1 ) = BB( 1 ) + CRANKP * MBARKS( 1 ) * LFAC1
               LFAC1 = CRANKQ * MBARKS( 1 ) * LFAC1
               DO V = 1, N_SPC_DIFF
                  DD( V,1 ) = DD( V,1 )
     &                      - LFAC1 * CONC( V,1 )
     &                      + LFAC2 * CONC( V,2 ) ! net mixing above
               END DO
            END IF

            BB( 1 ) = BB( 1 ) + CRANKP * EDDY( 1 ) * RDX3F( 1 ) * DTS
            LFAC1 = CRANKQ * EDDY( 1 ) * RDX3F( 1 ) * DTS
            DO V = 1, N_SPC_DIFF
               DD( V,1 ) = DD( V,1 )
     &                   + LFAC1 * ( CONC( V,2 ) - CONC( V,1 ) )
     &                   + EMIS( V,1 )
            END DO

C Subroutine MATRIX then solves for U if ACM2, else TRI solves for U

            IF ( CONVCT( C,R ) ) THEN
               CALL MATRIX ( AA, BB, CC, DD, EE, UU )
            ELSE
               CALL TRI ( CC, BB, EE, DD, UU )
            END IF

C Load into CGRID
            DO L = 1, NLAYS
               DO V = 1, N_SPC_DIFF
                  CONC( V,L ) = UU( V,L )
               END DO
            END DO
            
            DO V = 1, N_SPC_DEPV
               DDBF( V ) = DDBF( V )
     &                   + THETA * DD_FAC( V ) * CONC( DV2DF( V ),1 )
               CONC( DV2DF( V ),1 ) = EFAC2( V ) * CONC( DV2DF( V ),1 )
            END DO

301      CONTINUE                 ! end sub time loop

         DO L = 1, NLAYS
            DO V = 1, N_SPC_DIFF
               CNGRD( DIFF_MAP( V ),L,C,R ) = CONC( V,L )
!              CGRID( C,R,L,DIFF_MAP( V ) ) = CONC( V,L )
            END DO
         END DO

         DO V = 1, N_SPC_DEPV
!           DDEP( V,C,R ) = DDBF( V )
            DDEP( C,R,V ) = DDBF( V )
         END DO

344   CONTINUE         !  end loop on col C
345   CONTINUE         !  end loop on row R

C Revert non-molar mixing ratio species and re-order CGRID

      CALL REV_CGRID ( CNGRD, MDATE, MTIME )

C If last call this hour:  write accumulated depositions:

      WSTEP = WSTEP + TIME2SEC( TSTEP( 2 ) )
      IF ( WSTEP .GE. TIME2SEC( TSTEP( 1 ) ) ) THEN
!        MDATE = JDATE
!        MTIME = JTIME
!        CALL NEXTIME( MDATE, MTIME, TSTEP( 2 ) )
         WSTEP = 0

!        DO V = 1, N_SPC_DDEP
!           S = DD2DV( V )
!           DO R = 1, MY_NROWS
!              DO C = 1, MY_NCOLS
!                 WRDD( C,R ) = DDEP( S,C,R )
!              END DO
!           END DO

!           IF ( .NOT. WRITE3( CTM_DRY_DEP_1, DDEP_SPC( V ),
!    &                 MDATE, MTIME, WRDD ) ) THEN
!              XMSG = 'Could not write ' // CTM_DRY_DEP_1 // ' file'
!              CALL M3EXIT( PNAME, MDATE, MTIME, XMSG, XSTAT1 )
!           END IF

!        END DO

!        WRITE( LOGDEV, '( /5X, 3( A, :, 1X ), I8, ":", I6.6 )' )
!    &         'Timestep written to', CTM_DRY_DEP_1,
!    &         'for date and time', MDATE, MTIME

!        IF ( LIPR ) THEN
!!          DO V = 1, N_SPC_DDEP
!           DO V = 1, N_SPC_DEPV
!              DO R = 1, MY_NROWS
!                 DO C = 1, MY_NCOLS
!                    DDEP_PA( C,R,V ) = DDEP( V,C,R )
!                 END DO
!              END DO
!           END DO
!           CALL PA_UPDATE_DDEP ( 'VDIF', DDEP_PA, JDATE, JTIME, TSTEP )
!        END IF

C re-set dry deposition array to zero

!        DDEP = 0.0

      END IF

      RETURN
      END