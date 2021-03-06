!
 SUBROUTINE CONVECT_UPDRAFT_SHAL( KLON, KLEV,                                &
                           & KICE, PPRES, PDPRES, PZ, PTHL, PTHV, PTHES, PRW,&
                           & PTHLCL, PTLCL, PRVLCL, PWLCL, PZLCL, PTHVELCL,  &
                           & PMFLCL, OTRIG, KLCL, KDPL, KPBL,                &
                           & PUMF, PUER, PUDR, PUTHL, PUTHV, PWU,           &
                           & PURW, PURC, PURI, PCAPE, KCTL, KETL )
!#############################################################################

!!**** Compute updraft properties from DPL to CTL.
!!
!!
!!    PURPOSE
!!    -------
!!      The purpose of this routine is to determine updraft properties
!!      ( mass flux, thermodynamics, precipitation )
!!
!!
!!**  METHOD
!!    ------
!!      Computations are done at every model level starting from bottom.
!!      The use of masks allows to optimise the inner loops (horizontal loops).
!!
!!
!!
!!    EXTERNAL
!!    --------
!!     Routine CONVECT_MIXING_FUNCT
!!     Routine CONVECT_CONDENS
!!
!!
!!    IMPLICIT ARGUMENTS
!!    ------------------
!!      Module YOMCST
!!          RG                 ! gravity constant
!!          RATM               ! reference pressure
!!          RD, RV           ! gaz  constants for dry air and water vapor
!!          RCPD, RCPV, RCW    ! Cp of dry air, water vapor and liquid water
!!          RTT                ! triple point temperature
!!          RLVTT              ! vaporisation heat at RTT
!!
!!
!!      Module YOE_CONVPAR_SHAL
!!          XA25               ! reference grid area
!!          XCRAD              ! cloud radius
!!          XCDEPTH            ! minimum necessary cloud depth
!!          XCDEPTH_D          ! maximum allowed   cloud depth
!!          XENTR              ! entrainment constant
!!          XNHGAM             ! coefficient for buoyancy term in w eq.
!!                             ! accounting for nh-pressure
!!          XTFRZ1             ! begin of freezing interval
!!          XTFRZ2             ! begin of freezing interval
!!
!!     Module YOE_CONVPAREXT
!!          JCVEXB, JCVEXT     ! extra levels on the vertical boundaries
!!
!!    REFERENCE
!!    ---------
!!
!!      Book1,2 of documentation ( routine CONVECT_UPDRAFT)
!!      Kain and Fritsch, 1990, J. Atmos. Sci., Vol.
!!      Kain and Fritsch, 1993, Meteor. Monographs, Vol.
!!
!!    AUTHOR
!!    ------
!!      P. BECHTOLD       * Laboratoire d'Aerologie *
!!
!!    MODIFICATIONS
!!    -------------
!!      Original    07/11/95
!!   Last modified  10/12/97
!-------------------------------------------------------------------------------


!*       0.    DECLARATIONS
!              ------------

USE YOMCST
USE YOE_CONVPAR_SHAL
USE YOE_CONVPAREXT
#include "tsmbkind.cdk"

IMPLICIT NONE
#include <arch_specific.hf>

!*       0.1   Declarations of dummy arguments :

INTEGER_M, INTENT(IN)                    :: KLON  ! horizontal dimension
INTEGER_M, INTENT(IN)                    :: KLEV  ! vertical dimension
INTEGER_M, INTENT(IN)                    :: KICE  ! flag for ice ( 1 = yes,
                                                  !                0 = no ice )
REAL_B, DIMENSION(KLON,KLEV), INTENT(IN) :: PTHL  ! grid scale enthalpy (J/kg)
REAL_B, DIMENSION(KLON,KLEV), INTENT(IN) :: PTHV  ! grid scale theta_v
REAL_B, DIMENSION(KLON,KLEV), INTENT(IN) :: PTHES ! grid scale saturated theta_e
REAL_B, DIMENSION(KLON,KLEV), INTENT(IN) :: PRW   ! grid scale total water
                                                  ! mixing ratio
REAL_B, DIMENSION(KLON,KLEV), INTENT(IN) :: PPRES ! pressure (P)
REAL_B, DIMENSION(KLON,KLEV), INTENT(IN) :: PDPRES! pressure difference between
                                                  ! bottom and top of layer (Pa)
REAL_B, DIMENSION(KLON,KLEV), INTENT(IN) :: PZ    ! height of model layer (m)
REAL_B, DIMENSION(KLON),     INTENT(IN) :: PTHLCL ! theta at LCL
REAL_B, DIMENSION(KLON),     INTENT(IN) :: PTLCL  ! temp. at LCL
REAL_B, DIMENSION(KLON),     INTENT(IN) :: PRVLCL ! vapor mixing ratio at  LCL
REAL_B, DIMENSION(KLON),     INTENT(IN) :: PWLCL  ! parcel velocity at LCL (m/s)
REAL_B, DIMENSION(KLON),     INTENT(IN) :: PMFLCL ! cloud  base unit mass flux
                                                  ! (kg/s)
REAL_B, DIMENSION(KLON),     INTENT(IN) :: PZLCL  ! height at LCL (m)
REAL_B, DIMENSION(KLON),     INTENT(IN) :: PTHVELCL  ! environm. theta_v at LCL (K)
LOGICAL, DIMENSION(KLON),  INTENT(INOUT):: OTRIG  ! logical mask for convection
INTEGER_M, DIMENSION(KLON),  INTENT(IN) :: KLCL   ! contains vert. index of LCL
INTEGER_M, DIMENSION(KLON),  INTENT(IN) :: KDPL   ! contains vert. index of DPL
INTEGER_M, DIMENSION(KLON),  INTENT(IN) :: KPBL   !  " vert. index of source layertop


INTEGER_M, DIMENSION(KLON),  INTENT(OUT):: KCTL   ! contains vert. index of CTL
INTEGER_M, DIMENSION(KLON),  INTENT(OUT):: KETL   ! contains vert. index of 
                                                  !equilibrium (zero buoyancy) level
REAL_B, DIMENSION(KLON,KLEV), INTENT(OUT):: PUMF  ! updraft mass flux (kg/s)
REAL_B, DIMENSION(KLON,KLEV), INTENT(OUT):: PUER  ! updraft entrainment (kg/s)
REAL_B, DIMENSION(KLON,KLEV), INTENT(OUT):: PUDR  ! updraft detrainment (kg/s)
REAL_B, DIMENSION(KLON,KLEV), INTENT(OUT):: PUTHL ! updraft enthalpy (J/kg)
REAL_B, DIMENSION(KLON,KLEV), INTENT(OUT):: PUTHV ! updraft theta_v (K)
REAL_B, DIMENSION(KLON,KLEV), INTENT(OUT):: PWU   ! updraft vertical velocity (m/s)
REAL_B, DIMENSION(KLON,KLEV), INTENT(OUT):: PURW  ! updraft total water (kg/kg)
REAL_B, DIMENSION(KLON,KLEV), INTENT(OUT):: PURC  ! updraft cloud water (kg/kg)
REAL_B, DIMENSION(KLON,KLEV), INTENT(OUT):: PURI  ! updraft cloud ice   (kg/kg)
REAL_B, DIMENSION(KLON),     INTENT(OUT):: PCAPE  ! available potent. energy

!*       0.2   Declarations of local variables :

INTEGER_M :: IIE, IKB, IKE  ! horizontal and vertical loop bounds
INTEGER_M :: JI             ! horizontal loop index
INTEGER_M :: JK, JKP, JKM, JK1, JK2, JKMIN   ! vertical loop index
REAL_B    :: ZEPSA, ZCVOCD  ! R_v / R_d, C_pv / C_pd
REAL_B    :: ZCPORD, ZRDOCP ! C_pd / R_d, R_d / C_pd

REAL_B, DIMENSION(KLON)    :: ZUT             ! updraft temperature (K)
REAL_B, DIMENSION(KLON)    :: ZUW1, ZUW2      ! square of updraft vert.
                                              ! velocity at levels k and k+1
REAL_B, DIMENSION(KLON)    :: ZE1,ZE2,ZD1,ZD2 ! fractional entrainm./detrain
                                              ! rates at levels k and k+1
REAL_B, DIMENSION(KLON)    :: ZMIXF           ! critical mixed fraction
REAL_B, DIMENSION(KLON)    :: ZCPH            ! specific heat C_ph
REAL_B, DIMENSION(KLON)    :: ZLV, ZLS        ! latent heat of vaporis., sublim.
REAL_B, DIMENSION(KLON)    :: ZURV            ! updraft water vapor at level k+1
REAL_B, DIMENSION(KLON)    :: ZPI             ! Pi=(P0/P)**(Rd/Cpd)
REAL_B, DIMENSION(KLON)    :: ZTHEUL          ! theta_e for undilute ascent
REAL_B, DIMENSION(KLON)    :: ZWORK1, ZWORK2, ZWORK3  ! work arrays
REAL_B, DIMENSION(KLON)    :: ZWORK4, ZWORK5, ZWORK6  ! work arrays
INTEGER_M, DIMENSION(KLON) :: IWORK           ! wok array
LOGICAL, DIMENSION(KLON) :: GWORK1, GWORK2, GWORK4, GWORK5
                                              ! work arrays
LOGICAL, DIMENSION(KLON,KLEV) :: GWORK6       ! work array


!-------------------------------------------------------------------------------

!        0.3   Set loop bounds
!              ---------------

IKB = 1 + JCVEXB
IKE = KLEV - JCVEXT
IIE = KLON


!*       1.     Initialize updraft properties and local variables
!               -------------------------------------------------

ZEPSA      = RV / RD
ZCVOCD     = RCPV / RCPD
ZCPORD     = RCPD / RD
ZRDOCP     = RD / RCPD

PUMF(:,:)  = _ZERO_
PUER(:,:)  = _ZERO_
PUDR(:,:)  = _ZERO_
PUTHL(:,:) = _ZERO_
PUTHV(:,:) = _ZERO_
PWU(:,:)   = _ZERO_
PURW(:,:)  = _ZERO_
PURC(:,:)  = _ZERO_
PURI(:,:)  = _ZERO_
ZUW1(:)    = PWLCL(:) * PWLCL(:)
ZUW2(:)    = _ZERO_
ZE1(:)     = _ZERO_
ZD1(:)     = _ZERO_
PCAPE(:)   = _ZERO_
KCTL(:)    = IKB
KETL(:)    = KLCL(:)
GWORK2(:)  = .TRUE.
GWORK5(:)  = .TRUE.
ZPI(:)     = _ONE_
ZWORK3(:)  = _ZERO_
ZWORK4(:)  = _ZERO_
ZWORK5(:)  = _ZERO_
ZWORK6(:)  = _ZERO_
GWORK1(:)  = .FALSE.
GWORK4(:)  = .FALSE.


!*       1.1    Compute undilute updraft theta_e for CAPE computations
!               Bolton (1980) formula.
!               Define accurate enthalpy for updraft
!               -----------------------------------------------------

ZTHEUL(:) = PTLCL(:) * ( PTHLCL(:) / PTLCL(:) ) ** ( 1._JPRB - 0.28_JPRB * PRVLCL(:) )  &
          &          * EXP( ( 3374.6525_JPRB / PTLCL(:) - 2.5403_JPRB )       &
          &          * PRVLCL(:) * ( _ONE_ + 0.81_JPRB * PRVLCL(:) ) )


ZWORK1(:) = ( RCPD + PRVLCL(:) * RCPV ) * PTLCL(:)                            &
          & + ( _ONE_ + PRVLCL(:) ) * RG * PZLCL(:)


!*       2.     Set updraft properties between DPL and LCL
!               ------------------------------------------

JKP = MAXVAL( KLCL(:) )
JKM = MINVAL( KDPL(:) )
DO JK = JKM, JKP
   DO JI = 1, IIE
   IF ( JK >= KDPL(JI) .AND. JK < KLCL(JI) ) THEN
        PUMF(JI,JK)  = PMFLCL(JI)
        PUTHL(JI,JK) = ZWORK1(JI)
        PUTHV(JI,JK) = PTHLCL(JI) * ( _ONE_ + ZEPSA * PRVLCL(JI) ) /         &
                     &            ( _ONE_ + PRVLCL(JI) )
        PURW(JI,JK)  = PRVLCL(JI)
   ENDIF
   ENDDO
ENDDO


!*       3.     Enter loop for updraft computations
!               ------------------------------------

JKMIN = MINVAL( KLCL(:) - 1 )
DO JK = MAX( IKB + 1, JKMIN ), IKE - 1
  ZWORK6(:) = _ONE_
  JKP = JK + 1

  GWORK4(:) = JK >= KLCL(:) - 1
  GWORK1(:) = GWORK4(:) .AND. GWORK2(:) ! this mask is used to confine
                           ! updraft computations between the LCL and the CTL

  WHERE( JK == KLCL(:) - 1 ) ZWORK6(:) = _ZERO_ ! factor that is used in buoyancy
                                        ! computation at first level above LCL


!*       4.     Estimate condensate, L_v L_i, Cph and theta_v at level k+1
!               ----------------------------------------------------------

    ZWORK1(:) = PURC(:,JK)
    ZWORK2(:) = PURI(:,JK)
    CALL CONVECT_CONDENS( KLON, KICE, PPRES(:,JKP), PUTHL(:,JK), PURW(:,JK),&
                        & ZWORK1, ZWORK2, PZ(:,JKP), GWORK1, ZUT, ZURV,     &
                        & PURC(:,JKP), PURI(:,JKP), ZLV, ZLS, ZCPH )


  ZPI(:) = ( RATM / PPRES(:,JKP) ) ** ZRDOCP
  WHERE ( GWORK1(:) )

    PUTHV(:,JKP) = ZPI(:) * ZUT(:) * ( _ONE_ + ZEPSA * ZURV(:) )           &
                 &       / ( _ONE_ + PURW(:,JK) )


!*       5.     Compute square of vertical velocity using entrainment
!               at level k
!               -----------------------------------------------------

    ZWORK3(:) = PZ(:,JKP) - PZ(:,JK) * ZWORK6(:) -         &
              &      ( _ONE_ - ZWORK6(:) ) * PZLCL(:)        ! level thickness
    ZWORK4(:) = PTHV(:,JK) * ZWORK6(:) +                   &
              &  ( _ONE_ - ZWORK6(:) ) * PTHVELCL(:)
    ZWORK5(:) = _TWO_ * ZUW1(:) * PUER(:,JK) / MAX( .1_JPRB, PUMF(:,JK) )
    ZUW2(:)   = ZUW1(:) + ZWORK3(:) * XNHGAM * RG *        &
              &   ( ( PUTHV(:,JK) + PUTHV(:,JKP) ) /       &
              &   ( ZWORK4(:) + PTHV(:,JKP) ) - _ONE_ )    & ! buoyancy term
              & - ZWORK5(:)                                  ! entrainment term


!*       6.     Update total precipitation: dr_r=(r_c+r_i)*exp(-rate*dz)
!               --------------------------------------------------------

!                    compute level mean vertical velocity
    ZWORK2(:)   = _HALF_ *                                                    &
                &      ( SQRT( MAX( 1.E-2_JPRB, ZUW2(:) ) ) +                 &
                &        SQRT( MAX( 1.E-2_JPRB, ZUW1(:) ) ) )


!*       7.     Update r_c, r_i, enthalpy, r_w  for precipitation
!               -------------------------------------------------------

    PURW(:,JKP)  = PURW(:,JK)
    PURC(:,JKP)  = PURC(:,JKP)
    PURI(:,JKP)  = PURI(:,JKP)
    PUTHL(:,JKP) = PUTHL(:,JK)

    ZUW1(:)      = ZUW2(:)
    PWU(:,JKP)   =SQRT(MAX(ZUW1(:),1.E-2_JPRB))

  END WHERE


!*       8.     Compute entrainment and detrainment using conservative
!               variables adjusted for precipitation ( not for entrainment)
!               -----------------------------------------------------------

!*       8.1    Compute critical mixed fraction by estimating unknown
!               T^mix r_c^mix and r_i^mix from enthalpy^mix and r_w^mix
!               We determine the zero crossing of the linear curve
!               evaluating the derivative using ZMIXF=0.1.
!               -----------------------------------------------------

    ZMIXF(:)  = 0.1_JPRB   ! starting value for critical mixed fraction
    ZWORK1(:) = ZMIXF(:) * PTHL(:,JKP)                                     &
              &      + ( _ONE_ - ZMIXF(:) ) * PUTHL(:,JKP) ! mixed enthalpy
    ZWORK2(:) = ZMIXF(:) * PRW(:,JKP)                                      &
              &      + ( _ONE_ - ZMIXF(:) ) * PURW(:,JKP)  ! mixed r_w

    CALL CONVECT_CONDENS( KLON, KICE, PPRES(:,JKP), ZWORK1, ZWORK2,        &
                        & PURC(:,JKP), PURI(:,JKP), PZ(:,JKP), GWORK1, ZUT,&
                        & ZWORK3, ZWORK4, ZWORK5, ZLV, ZLS, ZCPH )
!        put in enthalpy and r_w and get T r_c, r_i (ZUT, ZWORK4-5)

     ! compute theta_v of mixture
    ZWORK3(:) = ZUT(:) * ZPI(:) * ( _ONE_ + ZEPSA * (                          &
              & ZWORK2(:) - ZWORK4(:) - ZWORK5(:) ) ) / ( _ONE_ + ZWORK2(:) )
     ! compute final value of critical mixed fraction using theta_v
     ! of mixture, grid-scale and updraft
    ZMIXF(:) = MAX( _ZERO_, PUTHV(:,JKP) - PTHV(:,JKP) ) * ZMIXF(:) /          &
             &                ( PUTHV(:,JKP) - ZWORK3(:) + 1.E-10_JPRB )
    ZMIXF(:) = MAX( _ZERO_, MIN( _ONE_, ZMIXF(:) ) )


!*       8.2     Compute final midlevel values for entr. and detrainment
!                after call of distribution function
!                -------------------------------------------------------


    CALL CONVECT_MIXING_FUNCT ( KLON, ZMIXF, 1, ZE2, ZD2 )
!       Note: routine MIXING_FUNCT returns fractional entrainm/detrainm. rates

! ZWORK1(:) = XENTR * PMFLCL(:) * PDPRES(:,JKP) / XCRAD ! rate of env. inflow
!*MOD
  ZWORK1(:) = XENTR * RG / XCRAD * PUMF(:,JK) * ( PZ(:,JKP) - PZ(:,JK) )
! ZWORK1(:) = XENTR * pumf(:,jk) * PDPRES(:,JKP) / XCRAD ! rate of env. inflow
!*MOD
  ZWORK2(:) = _ZERO_
  WHERE ( GWORK1(:) ) ZWORK2(:) = _ONE_
  WHERE ( PUTHV(:,JKP) > PTHV(:,JKP) )
    PUER(:,JKP) = _HALF_ * ZWORK1(:) * ( ZE1(:) + ZE2(:) ) * ZWORK2(:)
    PUDR(:,JKP) = _HALF_ * ZWORK1(:) * ( ZD1(:) + ZD2(:) ) * ZWORK2(:)
  ELSEWHERE
    PUER(:,JKP) = _ZERO_
    PUDR(:,JKP) = ZWORK1(:) * ZWORK2(:)
  END WHERE

!*       8.3     Determine equilibrium temperature level
!                --------------------------------------

   WHERE ( PUTHV(:,JKP) > PTHV(:,JKP) .AND. JK > KLCL(:) + 1 &
         & .AND. GWORK1(:) )
         KETL(:) = JKP            ! equilibrium temperature level
   END WHERE

!*       8.4     If the calculated detrained mass flux is greater than
!                the total updraft mass flux, or vertical velocity is
!                negative, all cloud mass detrains at previous model level,
!                exit updraft calculations - CTL is attained
!                -------------------------------------------------------

  WHERE( GWORK1(:) )                                                   &
       & GWORK2(:) = PUMF(:,JK) - PUDR(:,JKP) > 10._JPRB .AND. ZUW2(:) > _ZERO_
  WHERE ( GWORK2(:) ) KCTL(:) = JKP   ! cloud top level
  GWORK1(:) = GWORK2(:) .AND. GWORK4(:)

  IF ( COUNT( GWORK2(:) ) == 0 ) EXIT


!*       9.   Compute CAPE for undilute ascent using theta_e and
!             theta_es instead of theta_v. This estimation produces
!             a significantly larger value for CAPE than the actual one.
!             ----------------------------------------------------------

  WHERE ( GWORK1(:) )

    ZWORK3(:)   = PZ(:,JKP) - PZ(:,JK) * ZWORK6(:) -                      &
                & ( _ONE_ - ZWORK6(:) ) *  PZLCL(:)              ! level thickness
    ZWORK2(:)   = PTHES(:,JK) + ( _ONE_ - ZWORK6(:) ) *                   &
   & ( PTHES(:,JKP) - PTHES(:,JK) ) / ( PZ(:,JKP) - PZ(:,JK) ) *          &
   & ( PZLCL(:) - PZ(:,JK) ) ! linear interpolation for theta_es at LCL
                            ! ( this is only done for model level just above LCL

    ZWORK1(:) = ( _TWO_ * ZTHEUL(:) ) / ( ZWORK2(:) + PTHES(:,JKP) ) - _ONE_
    PCAPE(:)  = PCAPE(:) + RG * ZWORK3(:) * MAX( _ZERO_, ZWORK1(:) )


!*       10.   Compute final values of updraft mass flux, enthalpy, r_w
!              at level k+1
!              --------------------------------------------------------

    PUMF(:,JKP)  = PUMF(:,JK) - PUDR(:,JKP) + PUER(:,JKP)
    PUMF(:,JKP)  = MAX( PUMF(:,JKP), 0.1_JPRB )
    PUTHL(:,JKP) = ( PUMF(:,JK)  * PUTHL(:,JK) +                             &
                 &   PUER(:,JKP) * PTHL(:,JK) - PUDR(:,JKP) * PUTHL(:,JK) )  &
                 &  / PUMF(:,JKP)
    PURW(:,JKP)  = ( PUMF(:,JK)  * PURW(:,JK) +                              &
                 &   PUER(:,JKP) * PRW(:,JK) - PUDR(:,JKP) * PURW(:,JK) )    &
                 &  / PUMF(:,JKP)


    ZE1(:) = ZE2(:) ! update fractional entrainment/detrainment
    ZD1(:) = ZD2(:)

  END WHERE

ENDDO

!*       12.1    Set OTRIG to False if cloud thickness < 0.5km
!                or > 3km (deep convection) or CAPE < 1
!                ------------------------------------------------

    DO JI = 1, IIE
          JK  = KCTL(JI)
          ZWORK1(JI) = PZ(JI,JK) - PZLCL(JI)
          OTRIG(JI) = ZWORK1(JI) >= XCDEPTH  .AND. ZWORK1(JI) < XCDEPTH_D &
                    & .AND. PCAPE(JI) > _ONE_
    ENDDO
    WHERE( .NOT. OTRIG(:) )
          KCTL(:) = IKB
    END WHERE
KETL(:) = MAX( KETL(:), KLCL(:) + 2 )
KETL(:) = MIN( KETL(:), KCTL(:) )


!*       12.2    If the ETL and CTL are the same detrain updraft mass
!                flux at this level
!                -------------------------------------------------------

ZWORK1(:) = _ZERO_
WHERE ( KETL(:) == KCTL(:) ) ZWORK1(:) = _ONE_

DO JI = 1, IIE
    JK = KETL(JI)
    PUDR(JI,JK)   = PUDR(JI,JK) +                                    &
                  &       ( PUMF(JI,JK) - PUER(JI,JK) )  * ZWORK1(JI)
    PUER(JI,JK)   = PUER(JI,JK) * ( _ONE_ - ZWORK1(JI) )
    PUMF(JI,JK)   = PUMF(JI,JK) * ( _ONE_ - ZWORK1(JI) )
    JKP = KCTL(JI) + 1
    PUER(JI,JKP)  = _ZERO_ ! entrainm/detr rates have been already computed
    PUDR(JI,JKP)  = _ZERO_ ! at level KCTL+1, set them to zero
    PURW(JI,JKP)  = _ZERO_
    PURC(JI,JKP)  = _ZERO_
    PURI(JI,JKP)  = _ZERO_
    PUTHL(JI,JKP) = _ZERO_
    PURC(JI,JKP+1)= _ZERO_
    PURI(JI,JKP+1)= _ZERO_
ENDDO

!*       12.3    Adjust mass flux profiles, detrainment rates, and
!                precipitation fallout rates to reflect linear decrease
!                in mass flux between the ETL and CTL
!                -------------------------------------------------------

ZWORK1(:) = _ZERO_
JK1 = MINVAL( KETL(:) )
JK2 = MAXVAL( KCTL(:) )

DO JK = JK1, JK2
    DO JI = 1, IIE
    IF( JK > KETL(JI) .AND. JK <= KCTL(JI) ) THEN
        ZWORK1(JI) = ZWORK1(JI) + PDPRES(JI,JK)
    ENDIF
    ENDDO
ENDDO

DO JI = 1, IIE
    JK = KETL(JI)
    ZWORK1(JI) = PUMF(JI,JK) / MAX( _ONE_, ZWORK1(JI) )
ENDDO

DO JK = JK1 + 1, JK2
    JKP = JK - 1
    DO JI = 1, IIE
    IF ( JK > KETL(JI) .AND. JK <= KCTL(JI) ) THEN
        PUDR(JI,JK)  = PDPRES(JI,JK) * ZWORK1(JI)
        PUMF(JI,JK)  = PUMF(JI,JKP) - PUDR(JI,JK)
    ENDIF
    ENDDO
ENDDO

!         12.4   Set mass flux and entrainment in the source layer.
!                Linear increase throughout the source layer.
!                -------------------------------------------------------

!IWORK(:) = MIN( KPBL(:), KLCL(:) - 1 )
IWORK(:) = KPBL(:)
DO JI = 1, IIE
     JK  = KDPL(JI)
     JKP = IWORK(JI)
!          mixed layer depth
     ZWORK2(JI) = PPRES(JI,JK) - PPRES(JI,JKP) + PDPRES(JI,JK)
ENDDO

JKP = MAXVAL( IWORK(:) )
DO JK = JKM, JKP
   DO JI = 1, IIE
   IF ( JK >= KDPL(JI)  .AND. JK <= IWORK(JI) ) THEN
       PUER(JI,JK) = PUER(JI,JK) + PMFLCL(JI) * PDPRES(JI,JK) / ( ZWORK2(JI) + 0.1_JPRB )
       PUMF(JI,JK) = PUMF(JI,JK-1) + PUER(JI,JK)
   ENDIF
   ENDDO
ENDDO


!*       13.   If cloud thickness is smaller than  .5 km or > 3 km
!              no shallow convection is allowed
!              Nota: For technical reasons, we stop the convection
!                    computations in this case and do not go back to
!                    TRIGGER_FUNCT to look for the next unstable LCL
!                    which could produce a thicker cloud.
!              ---------------------------------------------------

GWORK6(:,:) = SPREAD( OTRIG(:), DIM=2, NCOPIES=KLEV )
WHERE ( .NOT. GWORK6(:,:) )
    PUMF(:,:)  = _ZERO_
    PUDR(:,:)  = _ZERO_
    PUER(:,:)  = _ZERO_
    PWU(:,:)   = _ZERO_
    PUTHL(:,:) = PTHL(:,:)
    PURW(:,:)  = PRW(:,:)
    PURC(:,:)  = _ZERO_
    PURI(:,:)  = _ZERO_
END WHERE

END SUBROUTINE CONVECT_UPDRAFT_SHAL

