!************* THIS HEADER MUST NOT BE REMOVED *******************!
!** Copyright 2013, Lawrence Campbell and Brian McNeil.         **!
!** This program must not be copied, distributed or altered in  **!
!** any way without the prior permission of the above authors.  **!
!*****************************************************************!

module Equations


use paratype
use ArrayFunctions
use Globals


implicit none

contains

  subroutine dppdz_r(sInv2rho,ZOver2rho,salphaSq,&
    sField4ElecReal,nd,Lj,kbeta,sb,sy,dp2f,qOK)


  	implicit none



    REAL(KIND=WP),INTENT(IN) :: sInv2rho
    REAL(KIND=WP),INTENT(IN) :: ZOver2rho,salphaSq
    REAL(KIND=WP),DIMENSION(:),ALLOCATABLE ,INTENT(IN):: sField4ElecReal
    REAL(KIND=WP),ALLOCATABLE ,INTENT(IN):: Lj(:), dp2f(:)
    REAL(KIND=WP),INTENT(IN) :: kbeta,nd
    REAL(KIND=WP),INTENT(IN) :: sy(:)
    REAL(KIND=WP),INTENT(OUT) :: sb(:)
    logical, intent(inout) :: qOK

    
    LOGICAL :: qOKL

    qOK = .false.

    if (zUndType_G == 'curved') then

!     For curved pole undulator

        call PutValueInVector(iRe_PPerp_CG, &
                sInv2rho * ( cosh(Vector(iRe_X_CG,sy) * kx_und_G) * &
                sinh(Vector(iRe_Y_CG,sy) * ky_und_G) * sqrt(2.0_WP) &
                * sqrt(sEta_G) * Lj * Vector(iIm_PPerp_CG,sy)  &      
                *  cos(ZOver2rho) &
                / (sqrt(salphaSq) * ky_und_G) + &
                cosh(Vector(iRe_X_CG,sy) * kx_und_G) &
                * cosh(Vector(iRe_Y_CG,sy) * ky_und_G) * sin(ZOver2rho) - &
                sEta_G * Vector(iRe_Q_CG,sy) * salphaSq * sField4ElecReal), &
                sb, &
                qOKL)
         if (.not. qOKL) goto 1000


    else if (zUndType_G == 'planepole')  then

!     Re(p_perp) equation for plane-poled undulator

        call PutValueInVector(iRe_PPerp_CG, &
                sInv2rho * (-sField4ElecReal*salphaSq * &
                sEta_G * Vector(iRe_Q_CG,sy) &
                + ((sqrt(6.0_WP) *sRho_G) /sqrt(salphaSq)) * &
                sinh(sInv2rho * Vector(iRe_Y_CG,sy) &
                * sqrt(sEta_G))  * cos(ZOver2rho) * Lj * &
                Vector(iIm_PPerp_CG,sy) + &
                cosh(sInv2rho * Vector(iRe_Y_CG,sy) * &
                sqrt(sEta_G)) *sin(ZOver2rho)), &
                sb,       &       
                qOKL)
        if (.not. qOKL) goto 1000

    else 

!     "normal" PUFFIN case with no off-axis undulator
!     field variation

      if (qFocussing_G) then

        call PutValueInVector(iRe_PPerp_CG, &
                sInv2rho * (fy_G*n2col*sin(ZOver2rho) - &
                (salphaSq * sEta_G * Vector(iRe_Q_CG,sy) * &
                sField4ElecReal ) ) - & 
                nd / Lj * & ! focusing term
                (  ( kbeta**2 * Vector(iRe_X_CG,sy)) + (sEta_G / &
                ( 1.0_WP + (sEta_G * Vector(iRe_Q_CG,sy)) ) * &
                Vector(iRe_X_CG,sb) * dp2f ) ), &
                sb,       &     
                qOKL)
        if (.not. qOKL) goto 1000

      else 


        sb(iPXs:iPXe) = sInv2rho * (fy_G* n2col * sin(ZOver2rho) - &
              ( salphaSq * sEta_G * sy(iP2s:iP2e) * &
              sField4ElecReal ) )


      end if


    end if

    ! Set the error flag and exit

    qOK = .true.

    goto 2000 

    1000 call Error_log('Error in equations:dppdz_r',tErrorLog_G)
    
    print*,'Error in equations:dppdz_r'

    2000 continue

  end subroutine dppdz_r


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!






  subroutine dppdz_i(sInv2rho,ZOver2rho,salphaSq,sField4ElecImag,nd,Lj,kbeta,sb,sy,dp2f,qOK)


  	implicit none



    REAL(KIND=WP),INTENT(IN) :: sInv2rho
    REAL(KIND=WP),INTENT(IN) :: ZOver2rho,salphaSq
    REAL(KIND=WP),DIMENSION(:),ALLOCATABLE ,INTENT(IN):: sField4ElecImag
    REAL(KIND=WP),ALLOCATABLE,INTENT(IN) :: Lj(:), dp2f(:)
    REAL(KIND=WP),INTENT(IN) :: kbeta,nd
    REAL(KIND=WP),INTENT(IN) :: sy(:)
    REAL(KIND=WP),INTENT(OUT) :: sb(:)
    logical, intent(inout) :: qOK

    LOGICAL :: qOKL                   


    qOK = .false.


    if (zUndType_G == 'curved') then


!     For curved pole undulator

        call PutValueInVector(iIM_PPerp_CG, &
                sInv2rho * ( -1.0_WP * sqrt(2.0_WP) * sqrt(sEta_G) &
                * Lj * Vector(iRe_PPerp_CG,sy) &
                * cosh(Vector(iRe_X_CG,sy) * kx_und_G) &
                * sinh(Vector(iRe_Y_CG,sy) * ky_und_G) &
                * cos(ZOver2rho)  / (sqrt(salphaSq) * ky_und_G) &
                + sin(ZOver2rho) * kx_und_G/ky_und_G * &
                sinh(Vector(iRe_X_CG,sy) * kx_und_G) * &
                sinh(Vector(iRe_Y_CG,sy) * ky_und_G) & 
                - sEta_G * Vector(iRe_Q_CG,sy) * salphaSq * &
                sField4ElecImag), &
                sb, &
                qOKL)
        if (.not. qOKL) goto 1000

    else if (zUndType_G == 'planepole') then 

!     Im(p_perp) equation for plane-poled undulator



        call PutValueInVector(iIM_PPerp_CG, &
                sInv2rho * (- sField4ElecImag * salphaSq * &
                sEta_G * Vector(iRe_Q_CG,sy)  &
                - ((sqrt(6.0_WP) * sRho_G)/ sqrt(salphaSq)) * &
                sinh(sInv2rho * Vector(iRe_Y_CG,sy) &
                * sqrt(sEta_G)) * cos(ZOver2rho) * Lj * &
                Vector(iRe_PPerp_CG,sy)) , &
                sb, &
                qOKL)
        if (.not. qOKL) goto 1000

    else

!     "normal" PUFFIN case with no off-axis undulator
!     field variation


      if (qFocussing_G) then

        call PutValueInVector(iIm_PPerp_CG, &
                sInv2rho * (fx_G*n2col*cos(ZOver2rho) - &
                (salphaSq * sEta_G * Vector(iRe_Q_CG,sy) * &
                sField4ElecImag ) ) + &
                nd / Lj * & ! focusing term
                (  ( kbeta**2 * Vector(iRe_Y_CG,sy)) + (sEta_G / &
                ( 1.0_WP + (sEta_G * Vector(iRe_Q_CG,sy)) ) * &
                Vector(iRe_Y_CG,sb) * dp2f ) ), &
                sb,       &     
                qOKL)
        if (.not. qOKL) goto 1000

      else


        sb(iPYs:iPYe) = sInv2rho * (fx_G * n2col * cos(ZOver2rho) - &
                      ( salphaSq * sEta_G * sy(iP2s:iP2e) * &
                      sField4ElecImag ) )

      end if


    end if

    ! Set the error flag and exit

    qOK = .true.

    goto 2000 

    1000 call Error_log('Error in equations:dppdz_i',tErrorLog_G)
    
    print*,'Error in equations:dppdz_i'
    
    2000 continue


  end subroutine dppdz_i







!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

  subroutine dp2dz(sInv2rho,ZOver2rho,salphaSq, &
                      sField4ElecImag,sField4ElecReal, &
                      nd,Lj,kbeta,sb,sy,dp2f,nb,qOK)


  	implicit none



    REAL(KIND=WP),INTENT(IN) :: sInv2rho
    REAL(KIND=WP),INTENT(IN) :: ZOver2rho,salphaSq
    REAL(KIND=WP),DIMENSION(:),ALLOCATABLE ,INTENT(IN):: sField4ElecReal,sField4ElecImag
    REAL(KIND=WP),ALLOCATABLE,INTENT(IN) :: Lj(:), dp2f(:)
    REAL(KIND=WP),INTENT(IN) :: kbeta,nd,nb
    REAL(KIND=WP),INTENT(IN) :: sy(:)
    REAL(KIND=WP),INTENT(OUT) :: sb(:)   
    logical, intent(inout) :: qOK

    LOGICAL :: qOKL


    qOK = .false.

    if (zUndType_G == 'curved') then


!     For curved pole undulator

        call PutValueInVector(iRe_Q_CG, &
                (4_WP * sRho_G / sEta_G) * Lj**2 * &
                ( (Vector(iRe_pPerp_CG,sy) * sField4ElecReal &
                + Vector(iIm_pPerp_CG,sy) * sField4ElecImag) * &
                Vector(iRe_Q_CG,sy) * sEta_G &
                + (1.0_WP/salphaSq) * (1 + sEta_G * Vector(iRe_Q_CG,sy)) &
                * sin(ZOver2rho) * &
                (Vector(iRe_pPerp_CG,sy) * cosh(Vector(iRe_X_CG,sy) &
                * kx_und_G) * cosh(Vector(iRe_Y_CG,sy) * ky_und_G) &
                + Vector(iIm_pPerp_CG,sy) * kx_und_G/ky_und_G * &
                sinh(Vector(iRe_X_CG,sy) * kx_und_G) * &
                sinh(Vector(iRe_Y_CG,sy) * ky_und_G))),&
                sb,&
                qOKL)
        if (.not. qOKL) goto 1000


    else if (zUndType_G == 'planepole') then 

!     p2 equation for plane-poled undulator

 
        call PutValueInVector(iRe_Q_CG, &
                (4_WP * sRho_G / sEta_G) * Lj**2 * &
                ( (Vector(iRe_pPerp_CG,sy) * sField4ElecReal &
                + Vector(iIm_pPerp_CG,sy) * sField4ElecImag) * &
                Vector(iRe_Q_CG,sy) * sEta_G &
                + (1.0_WP/salphaSq) * (1 + sEta_G * Vector(iRe_Q_CG,sy)) &
                * cosh(sInv2rho * Vector(iRe_Y_CG,sy) * sqrt(sEta_G)) &
                * sin(ZOver2rho) *  Vector(iRe_pPerp_CG,sy)  ) , &
                sb,&
                qOKL)
        if (.not. qOKL) goto 1000

 
    else

!     "normal" PUFFIN case with no off-axis undulator
!     field variation

      if (qFocussing_G) then

        call PutValueInVector(iRe_Q_CG, &
                2.0_WP * nb * Lj**2 * &
                ((sEta_G * Vector(iRe_Q_CG,sy) + 1.0_WP) &
                / salphaSq * n2col * &
                (Vector(iIm_pPerp_CG,sy) * fx_G*cos(ZOver2Rho) + &
                Vector(iRe_pPerp_CG,sy) * fy_G*sin(ZOver2rho)) + &
                sEta_G * Vector(iRe_Q_CG,sy) * &
                (Vector(iRe_pPerp_CG,sy)*sField4ElecReal + &
                Vector(iIm_pPerp_CG,sy)*sField4ElecImag)) &
                + dp2f, & 
                sb,&
                qOKL)
        if (.not. qOKL) goto 1000

      else


        sb(iP2s:iP2e) = 2.0_WP * nb * Lj**2.0_WP * &
                ((sEta_G * sy(iP2s:iP2e) + 1.0_WP)/ salphaSq * n2col * &
                (sy(iPYs:iPYe) * fx_G*cos(ZOver2Rho) + &
                sy(iPXs:iPXe) * fy_G*sin(ZOver2rho)) + &
                sEta_G * sy(iP2s:iP2e) * &
                (sy(iPXs:iPXe) * sField4ElecReal + &
                sy(iPYs:iPYe) * sField4ElecImag))

      end if

    end if

    ! Set the error flag and exit

    qOK = .true.

    goto 2000 

    1000 call Error_log('Error in equations:dp2dz',tErrorLog_G)
    
    print*,'Error in equations:dp2dz'

    2000 continue


  end subroutine dp2dz







  subroutine dxdz(sy, Lj, nd, sb, qOK)

!   Calculate dx/dz
!
!              Arguments:

    real(kind=wp), intent(in) :: sy(:), Lj(:), nd
    real(kind=wp), intent(inout) :: sb(:)
    logical, intent(inout) :: qOK

!              Local vars

    logical :: qOKL ! Local error flag


    qOK = .false.


    sb(iXs:iXe) = sy(iPXs:iPXe) * Lj / nd


    qOK = .true.
    
    goto 2000
    
    1000 call Error_log('Error in equations:dxdz',tErrorLog_G)
    
    2000 continue


  end subroutine dxdz





  subroutine dydz(sy, Lj, nd, sb, qOK)

!   Calculate dy/dz
!
!              Arguments:

    real(kind=wp), intent(in) :: sy(:), Lj(:), nd
    real(kind=wp), intent(inout) :: sb(:)
    logical, intent(inout) :: qOK

!              Local vars

    logical :: qOKL ! Local error flag


    qOK = .false.

    sb(iPYs:iPYe) = - sy(iPYs:iPYe) * Lj / nd


    qOK = .true.
    
    goto 2000
    
    1000 call Error_log('Error in equations:dydz',tErrorLog_G)
    
    2000 continue


  end subroutine dydz




  subroutine dz2dz(sy, sb, qOK)

!   Calculate dz2/dz
!
!              Arguments:

    real(kind=wp), intent(in) :: sy(:)
    real(kind=wp), intent(inout) :: sb(:)
    logical, intent(inout) :: qOK

!              Local vars

    logical :: qOKL ! Local error flag


    qOK = .false.

    sb(iZ2s:iZ2e) = sy(iP2s:iP2e)


    qOK = .true.
    
    goto 2000
    
    1000 call Error_log('Error in equations:dz2dz',tErrorLog_G)
    
    2000 continue

  end subroutine dz2dz
  






  subroutine caldp2f(kbeta, sy, sb, dp2f, qOK)

    real(kind=wp), intent(in) :: kbeta, sy(:), sb(:)
    real(kind=wp), intent(out) :: dp2f(:)

    logical, intent(inout) :: qOK

    qOK = .false.

    if (qFocussing_G) then

        dp2f = -(kbeta**2.0_WP) * &   ! New focusing term
               (1.0_WP + (sEta_G * sy(iP2s:iP2e)  ) ) * &
               ( ( sy(iXs:iXe) * sb(iXs:iXe)  ) + & 
               ( sy(iYs:iYe) * sb(iYs:iYe)  ) ) / &
               (1.0_WP + sEta_G * ( ( sb(iXs:iXe) )**2.0_WP  + &
               ( sb(iYs:iYe) )**2.0_WP ) )

    else 

        dp2f=0.0_WP

    end if

    qOK = .true.
    
    goto 2000
    
    1000 call Error_log('Error in equations:caldp2f',tErrorLog_G)
    
    2000 continue

  end subroutine caldp2f


end module equations