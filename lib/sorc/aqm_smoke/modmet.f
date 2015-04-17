        MODULE MODMET

!***********************************************************************
!  Module body starts at line
!
!  DESCRIPTION:
!     This module contains the derived meteorology data for applying emission
!     factors to activity data.
!
!  PRECONDITIONS REQUIRED:
!
!  SUBROUTINES AND FUNCTIONS CALLED:
!
!  REVISION HISTORY:
!     Created 6/99 by M. Houyoux
!
!***************************************************************************
!
! Project Title: Sparse Matrix Operator Kernel Emissions (SMOKE) Modeling
!                System
! File: @(#)$Id: modmet.f,v 1.8 2004/06/03 14:19:06 cseppan Exp $
!
! COPYRIGHT (C) 2004, Environmental Modeling for Policy Development
! All Rights Reserved
! 
! Carolina Environmental Program
! University of North Carolina at Chapel Hill
! 137 E. Franklin St., CB# 6116
! Chapel Hill, NC 27599-6116
! 
! smoke@unc.edu
!
! Pathname: $Source: /afs/isis/depts/cep/emc/apps/archive/smoke/smoke/src/emmod/modmet.f,v $
! Last updated: $Date: 2004/06/03 14:19:06 $ 
!
!****************************************************************************

        IMPLICIT NONE

!...........   Setting for range of valid min/max temperatures
        REAL, PUBLIC :: MINTEMP = 0.   ! minimum temperature
        REAL, PUBLIC :: MAXTEMP = 0.   ! maximum temperature

!...........   Source-based meteorology data (dim: NSRC)
        REAL, ALLOCATABLE, PUBLIC :: TASRC   ( : )   ! temperature in Kelvin
        REAL, ALLOCATABLE, PUBLIC :: QVSRC   ( : )   ! water vapor mixing ratio
        REAL, ALLOCATABLE, PUBLIC :: PRESSRC ( : )   ! pressure in pascals

!...........   Hourly meteorology data
!...              for Mobile5 processing, index 0 = 12 AM local time
!...              for Mobile6 processing, index 0 = 6 AM local time
        REAL,    ALLOCATABLE, PUBLIC :: TKHOUR  ( :,: ) ! temps by source per hour (Premobl)
                                                        ! temps by county per hour (Emisfac)
        REAL,    ALLOCATABLE, PUBLIC :: QVHOUR  ( :,: ) ! mixing ratios by source per hour (Premobl)
                                                        ! mixing ratios by county per hour (Emisfac)
        REAL,    ALLOCATABLE, PUBLIC :: BPHOUR  ( :,: ) ! barometric pressure by source (Premobl)
                                                        ! barometric pressure by county (Emisfac)
        REAL,    ALLOCATABLE, PUBLIC :: RHHOUR  ( :,: ) ! relative humidity by county per hour

        REAL,    ALLOCATABLE, PUBLIC :: TDYCNTY ( : )   ! daily temps by county
        REAL,    ALLOCATABLE, PUBLIC :: QVDYCNTY( : )   ! daily mixing ratios by county
        REAL,    ALLOCATABLE, PUBLIC :: BPDYCNTY( : )   ! daily barometric pressure by county
        INTEGER, ALLOCATABLE, PUBLIC :: DYCODES ( : )   ! FIPS codes for daily counties

        REAL,    ALLOCATABLE, PUBLIC :: TWKCNTY ( : )   ! weekly temps by county
        REAL,    ALLOCATABLE, PUBLIC :: QVWKCNTY( : )   ! weekly mixing ratios by county
        REAL,    ALLOCATABLE, PUBLIC :: BPWKCNTY( : )   ! weekly barometric pressure by county
        INTEGER, ALLOCATABLE, PUBLIC :: WKCODES ( : )   ! FIPS codes for weekly counties

        REAL,    ALLOCATABLE, PUBLIC :: TMNCNTY ( : )   ! monthly temps by county
        REAL,    ALLOCATABLE, PUBLIC :: QVMNCNTY( : )   ! monthly mixing ratios by county
        REAL,    ALLOCATABLE, PUBLIC :: BPMNCNTY( : )   ! monthly barometric pressure by county
        INTEGER, ALLOCATABLE, PUBLIC :: MNCODES ( : )   ! FIPS codes for monthly counties

        REAL,    ALLOCATABLE, PUBLIC :: TEPCNTY ( : )   ! episode temps by county
        REAL,    ALLOCATABLE, PUBLIC :: QVEPCNTY( : )   ! episode mixing ratios by county
        REAL,    ALLOCATABLE, PUBLIC :: BPEPCNTY( : )   ! episode barometric pressure by county
        INTEGER, ALLOCATABLE, PUBLIC :: EPCODES ( : )   ! FIPS codes for episode counties

!...........   Daily meteorology data
        REAL,    ALLOCATABLE, PUBLIC :: BPDAY( : )      ! average daily barometric pressure by county

        END MODULE MODMET