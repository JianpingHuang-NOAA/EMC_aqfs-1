      SUBROUTINE GRIB_IN (JMAXIN,IBUFSIZE,IBUF,KPDSIN,KGDSIN,
     &      FIN,LIN,MBYTES,KSTART,IRET)
C$$$  SUBPROGRAM DOCUMENTATION BLOCK
C                .      .    .                                       .
C   SUBPROGRAM: GRIB_IN 
C   PRGMMR: BALDWIN          ORG: NP22        DATE: 98-08-11  
C
C ABSTRACT: GRIB_IN  UNPACKS A GRIB FIELD 
C
C PROGRAM HISTORY LOG:
C   98-08-11  BALDWIN     ORIGINATOR
C
C USAGE:  CALL GRIB_IN (JMAXIN,IBUFSIZE,IBUF,KPDSIN,KGDSIN,
C    &      FIN,LIN,MBYTES,KSTART,IRET)
C
C   INPUT:
C         JMAXIN            INTEGER - MAX DIMENSION OF FIN
C         IBUFSIZE          INTEGER - DIMENSION OF IBUF
C         IBUF(IBUFSIZE)    CHAR*1  - GRIB MESSAGES
C         MBYTES            INTEGER - NUMBER OF BYTES IN REQUEST GRIB RECORD
C         KSTART            INTEGER - STARTING BYTE FOR REQUESTED GRIB RECORD
C
C   OUTPUT:
C         KPDSIN(25)        INTEGER - KPDS FOR UNPACKED FIELD
C         KGDSIN(22)        INTEGER - KGDS FOR UNPACKED FIELD
C         FIN(JMAXIN)       REAL    - UNPACKED FIELD
C         LIN(JMAXIN)       LOGICAL*1 - BITMAP CORRESPONDING TO FIN
C         IRET              INTEGER - RETURN CODE
C
C   RETURN CODES:
C     IRET =   0 - NORMAL EXIT
C              NONZERO - W3FI63 RETURN CODE
C
C ATTRIBUTES:
C   LANGUAGE: FORTRAN 90
C   MACHINE : CRAY J-916
C
C    
      INTEGER KPDSIN(25),KPTR(20),KGDSIN(22)
c      INTEGER KPDSIN(200),KPTR(20),KGDSIN(200)
      LOGICAL*1 LIN(JMAXIN)
      REAL FIN(JMAXIN)
      CHARACTER IBUF(IBUFSIZE)*1,MSGA(200+17*JMAXIN/8)

      IRET=0

C
C     UNPACK GRIB RECORD
C
C
C          MOVE GRIB RECORD SO IT IS ON WORD BOUNDARY
C
           CALL XMOVEX(MSGA,IBUF(KSTART),MBYTES)
C
           CALL W3FI63(MSGA,KPDSIN,KGDSIN,LIN,FIN,KPTR,KRET)

           IF(KRET.NE.0) THEN
               PRINT *,'W3FI63 GRIB UNPACKER ERROR = ',KRET
               IRET=KRET
           END IF

       RETURN
       END
