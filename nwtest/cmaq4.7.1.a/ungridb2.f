
C RCS file, release, date & time of last delta, author, state, [and locker]
C $Header: /project/work/rep/CCTM/src/vdiff/acm2_inline/ungridb2.f,v 1.2 2008/08/30 13:32:48 yoj Exp $

C what(1) key, module and SID; SCCS file; date and time of last delta:
C %W% %P% %G% %U%

C.......................................................................
C Version "@(#)$Header: /project/work/rep/CCTM/src/vdiff/acm2_inline/ungridb2.f,v 1.2 2008/08/30 13:32:48 yoj Exp $"
C EDSS/Models-3 I/O API.  Copyright (C) 1992-1999 MCNC
C Distributed under the GNU LESSER GENERAL PUBLIC LICENSE version 2.1
C See file "LGPL.txt" for conditions of use.
C.......................................................................

C:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
        SUBROUTINE  UNGRIDB2( NCOLS, NROWS, XORIG, YORIG, XCELL, YCELL,
!    &                        NPTS, XLOC, YLOC, NU, CU, K )
     &                        NPTS, XLOC, YLOC, NU, CU, IN )
!    &                        NPTS, XLOC, YLOC, NU, CU )

C-----------------------------------------------------------------------
 
C  FUNCTION:
C       computes "ungridding" matrices to be used by BMATVEC() and BILIN(),
C      for program LAYPOINT, etc., to perform bilinear interpolation
C      from a grid to a set of locations { <XLOC(S),YLOC(S)>, S=1:NPTS }
 
C  SEE ALSO:
C       BILIN()   which performs combined interpolate-only,
C                 preserving the subscript-order.
C       BMATVEC() which performs combined interpolate-and-transpose,
C                 e.g., for SMOKE program LAYPOINT, changing LAYER
C                 from an outermost subscript to an innermost
 
C  PRECONDITIONS:  none
 
C  SUBROUTINES AND FUNCTIONS CALLED:  none
 
C  REVISION  HISTORY:
C      prototype 12/95 by CJC
C      6 aug 07: yoj - fix indexing for left or below grid
 
C-----------------------------------------------------------------------

      IMPLICIT NONE

C Arguments:

        INTEGER,   INTENT( IN )  :: NCOLS, NROWS  ! number of grid columns, rows
        REAL( 8 ), INTENT( IN )  :: XORIG, YORIG  ! X,Y coords of LL grid corner [m]
        REAL( 8 ), INTENT( IN )  :: XCELL, YCELL  ! X,Y direction cell size [m]
        INTEGER,   INTENT( IN )  :: NPTS          ! number of (point-source) locations
        REAL,      INTENT( IN )  :: XLOC( NPTS )  ! X point coordinates from xorig [m]
        REAL,      INTENT( IN )  :: YLOC( NPTS )  ! Y point coordinates from yorig [m]
        INTEGER,   INTENT( OUT ) :: NU( 4,NPTS )  ! single-indexed subscripts into grid
        REAL,      INTENT( OUT ) :: CU( 4,NPTS )  ! coefficients
!       INTEGER,   INTENT( OUT ) :: K             ! single-indexed subscript into grid
        integer,   intent( out ) :: in            ! count in grid

C Local Variables:

        INTEGER      S          ! source counter
        INTEGER      C, R       ! indices into doubly-indexed grid
        INTEGER      K          ! index   into singly-indexed grid
        REAL( 8 ) :: DDX, DDY   ! inverse cell size
        REAL( 8 ) :: XD0, YD0   ! center of LL cell
        REAL         X, Y       ! grid-normal coords of point
        REAL         P, Q       ! linear-interpolation coeffs

C-----------------------------------------------------------------------

        DDX = 1.0D0 / XCELL           ! [1/m] DDX truncated to REAL( 4 )
        DDY = 1.0D0 / YCELL           ! [1/m] DDY truncated to REAL( 4 )
        XD0 = XORIG + 0.5D0 * XCELL   ! [m]   XD0 truncated to REAL( 4 )
        YD0 = YORIG + 0.5D0 * YCELL   ! [m]   YD0 truncated to REAL( 4 )

        in = 0

        DO  11  S = 1, NPTS
            
            !!  Hacks to fix this up to deal with the fact
            !!  that computer languages do the WRONG THING
            !!  for negative-number integer conversions and remainders:

            X = SNGL( DDX * ( XLOC( S ) - XD0 ) ) ! normalized grid coords
            IF ( X .GE. 0.0 ) THEN
                C = 1 + INT( X )                  ! truncated to integer
                X = MOD( X, 1.0 )                 ! trapped between 0 and 1
            ELSE
!               C = -1 - INT( -X )                ! truncated to integer
!               X = 1.0 - MOD( -X, 1.0 )          ! trapped between 0 and 1
                C = - INT( -X )                   ! truncated to integer
                X = - MOD( -X, 1.0 )              ! trapped between 0 and 1
            END IF

            Y = SNGL( DDY * ( YLOC( S ) - YD0 ) ) !  normalized grid coords
            IF ( Y .GE. 0.0 ) THEN
                R = 1 + INT( Y )                  ! truncated to integer
                Y = MOD( Y, 1.0 )                 ! trapped between 0 and 1
            ELSE
!               R = -1 - INT( -Y )                ! truncated to integer
!               Y = 1.0 - MOD( -Y, 1.0 )          ! trapped between 0 and 1
                R = - INT( -Y )                   ! truncated to integer
                Y = - MOD( -Y, 1.0 )              ! trapped between 0 and 1
            END IF

            IF ( R .LT. 1 ) THEN                  ! r below grid

                IF ( C .LT. 1 ) THEN              ! c left of grid

                    K = 1
                    NU( 1,S ) = K
                    NU( 2,S ) = K
                    NU( 3,S ) = K
                    NU( 4,S ) = K
                    CU( 1,S ) = 1.0
                    CU( 2,S ) = 0.0
                    CU( 3,S ) = 0.0
                    CU( 4,S ) = 0.0

                ELSE IF ( C .GT. NCOLS - 1 ) THEN ! c right of grid

                    K = NCOLS
                    NU( 1,S ) = K
                    NU( 2,S ) = K
                    NU( 3,S ) = K
                    NU( 4,S ) = K
                    CU( 1,S ) =  1.0
                    CU( 2,S ) =  0.0
                    CU( 3,S ) =  0.0
                    CU( 4,S ) =  0.0

                ELSE                              ! c in the grid

                    K = C
                    NU( 1,S ) = K
                    NU( 2,S ) = K + 1
                    NU( 3,S ) = K
                    NU( 4,S ) = K
                    CU( 1,S ) = 1.0 - X
                    CU( 2,S ) = X
                    CU( 3,S ) = 0.0 
                    CU( 4,S ) = 0.0

                END IF

            ELSE IF ( R .GT. NROWS - 1 ) THEN     ! r above grid

                IF ( C .LT. 1 ) THEN              ! c left of grid

                    K = ( NROWS - 1 ) * NCOLS + 1
                    NU( 1,S ) = K
                    NU( 2,S ) = K
                    NU( 3,S ) = K
                    NU( 4,S ) = K
                    CU( 1,S ) = 1.0
                    CU( 2,S ) = 0.0
                    CU( 3,S ) = 0.0
                    CU( 4,S ) = 0.0

                ELSE IF ( C .GT. NCOLS - 1 ) THEN ! c right of grid

                    K = NROWS * NCOLS
                    NU( 1,S ) = K
                    NU( 2,S ) = K
                    NU( 3,S ) = K
                    NU( 4,S ) = K
                    CU( 1,S ) = 1.0
                    CU( 2,S ) = 0.0
                    CU( 3,S ) = 0.0
                    CU( 4,S ) = 0.0

                ELSE                              ! c in the grid

                    K = ( NROWS - 1 ) * NCOLS  +  C
                    NU( 1,S ) = K
                    NU( 2,S ) = K + 1
                    NU( 3,S ) = K
                    NU( 4,S ) = K
                    CU( 1,S ) = 1.0 - X
                    CU( 2,S ) = X
                    CU( 3,S ) = 0.0
                    CU( 4,S ) = 0.0

                END IF

            ELSE                                  ! r in the grid

                IF ( C .LT. 1 ) THEN              ! c left of grid

                    K = ( R - 1 ) * NCOLS + 1
                    NU( 1,S ) = K
                    NU( 2,S ) = K
                    NU( 3,S ) = K + NCOLS
                    NU( 4,S ) = K + NCOLS
                    CU( 1,S ) =  1.0 - Y
                    CU( 2,S ) =  0.0
                    CU( 3,S ) =  Y
                    CU( 4,S ) =  0.0

                ELSE IF ( C .GT. NCOLS - 1 ) THEN ! c right of grid

                    K = R * NCOLS
                    NU( 1,S ) = K
                    NU( 2,S ) = K
                    NU( 3,S ) = K + NCOLS
                    NU( 4,S ) = K + NCOLS
                    CU( 1,S ) =  1.0 - Y
                    CU( 2,S ) =  0.0
                    CU( 3,S ) =  Y
                    CU( 4,S ) =  0.0

                ELSE                              ! c in the grid

                    K = ( R - 1 ) * NCOLS  +  C
                    NU( 1,S ) = K
                    NU( 2,S ) = K + 1
                    NU( 3,S ) = K + NCOLS
                    NU( 4,S ) = K + NCOLS + 1
                    P = 1.0 - X
                    Q = 1.0 - Y
                    CU( 1,S ) =  P * Q
                    CU( 2,S ) =  X * Q
                    CU( 3,S ) =  P * Y
                    CU( 4,S ) =  X * Y

                    in = in + 1

                END IF

            END IF      !  end computing bilinear interpolation matrix

11      CONTINUE        !  end matrix computation loop on point sources

        RETURN
        END

