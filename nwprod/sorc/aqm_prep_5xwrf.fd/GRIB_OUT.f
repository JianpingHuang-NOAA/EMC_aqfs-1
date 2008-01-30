      SUBROUTINE GRIB_OUT (JMAXOT,FMIN,FMAX,SCAL,KPDSIN,KGDSOUT,
     &      TYPE4,IOUTUN,MDLID,KGRID,IBOUT,NOUT,LOUT,FOUT,IRET)
C$$$  SUBPROGRAM DOCUMENTATION BLOCK
C                .      .    .                                       .
C   SUBPROGRAM: GRIB_OUT
C   PRGMMR: BALDWIN          ORG: NP22        DATE: 98-08-11  
C
C ABSTRACT: GRIB_OUT PACKS UP A FIELD INTO GRIB AND WRITES IT OUT.
C
C PROGRAM HISTORY LOG:
C   98-08-11  BALDWIN     ORIGINATOR
C
C USAGE:  CALL GRIB_OUT (JMAXOT,FMIN,FMAX,SCAL,KPDSIN,KGDSOUT,
C    &           TYPE4,IOUTUN,MDLID,KGRID,IBOUT,NOUT,LOUT,FOUT,IRET)
C
C   INPUT:
C         JMAXOT            INTEGER - DIMENSION OF FOUT,LOUT
C         FMIN              REAL    - MIN VALUE OF FIELD
C         FMAX              REAL    - MAX VALUE OF FIELD
C         SCAL              REAL    - BINARY SCALE FACTOR 
C         KPDSIN(25)        INTEGER - KPDS FOR INPUT
C         KGDSOUT(22)       INTEGER - KGDS FOR OUTPUT GRID
C         TYPE4             CHAR*4  - TYPE OF WMO HEADER INFO TO ADD
C         IOUTUN            INTEGER - UNIT TO WRITE OUTPUT TO 
C         MDLID             INTEGER - MODEL ID NUMBER PDS OCTET 6
C         IBOUT             INTEGER - FLAG INDICATING BITMAP
C         NOUT              INTEGER - NUMBER OF POINTS IN OUTPUT GRID
C         FOUT(JMAXOT)      REAL    - FIELD TO OUTPUT
C         LOUT(JMAXOT)      LOGICAL*1 - BITMAP CORRESPONDING TO FOUT
C
C   OUTPUT:
C         IRET              INTEGER - RETURN CODE
C
C   RETURN CODES:
C     IRET =   0 - NORMAL EXIT
C
C ATTRIBUTES:
C   LANGUAGE: FORTRAN 90
C   MACHINE : CRAY J-916
C
C    
      PARAMETER (LUNKWB=41,LUNTIM=42,LUNPRM=43,LUNGRD=44,LUNLVL=45)
      INTEGER KPDSIN(25),KPDSOUT(25),KGDSOUT(22)
c      INTEGER KPDSIN(200),KPDSOUT(200),KGDSOUT(200)
      LOGICAL*1 LOUT(JMAXOT)
      REAL FOUT(JMAXOT)
      CHARACTER TYPE4*4,TYPE1*1
C      CHARACTER GRIB(200+17*JMAXOT/8),GRIBWMO(210+17*JMAXOT/8)
      CHARACTER GRIB(5*JMAXOT),GRIBWMO(5*JMAXOT)

      IRET=0

C  PACK INTO GRIB WRITE STUFF OUT
C
        CALL FNDBIT  ( FMIN, FMAX, SCAL, NBITSOUT,
     &                 ISCALO, RMN, IRET5)
        KPDSOUT=KPDSIN
        KPDSOUT(22)=ISCALO
        KPDSOUT(2)=MDLID
        KPDSOUT(3)=KGRID
        KPDSOUT(4)=128+64*IBOUT

       IF (IRET5.NE.0) THEN
          IRET=IRET5
          RETURN
       ELSE

        CALL PUT_GB(KGRID,NOUT,NBITSOUT,KPDSOUT,KGDSOUT,
     &              LOUT,FOUT,LGRIB,GRIB,IRET6)

        IF (IRET6.NE.0) THEN
          IRET=IRET6
          RETURN
        ELSE
          LUGBOUT=IOUTUN
          NUMT=INDEX(TYPE4,' ')-1
          IF (NUMT.LT.0) NUMT=LEN(TYPE4)
          DO II=1,NUMT
           TYPE1=TYPE4(II:II)
           IF (TYPE1.NE.'X') THEN
             CALL ADD_WMO  ( GRIB, TYPE1,
     &        LUNKWB, LUNTIM, LUNPRM, LUNGRD, LUNLVL,
     &        GRIBWMO, LGRIB1, IRET7)
             IF (IRET7.EQ.0) then
             CALL WRYTE(LUGBOUT,LGRIB1,GRIBWMO)
             endif
           ELSE
             CALL WRYTE(LUGBOUT,LGRIB,GRIB)
           ENDIF
          ENDDO
        ENDIF
       ENDIF
       RETURN
       END
