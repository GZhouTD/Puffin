! ###############################################
! Copyright 2012-2017, University of Strathclyde
! Authors: Lawrence T. Campbell
! License: BSD-3-Clause
! ###############################################

!> @author
!> Lawrence Campbell,
!> University of Strathclyde,
!> Glasgow, UK
!> @brief
!> This module contains the type definition to hold the scaling constants
!> describing the z2 radiation frame used in Puffin.

module typeScale

  use paratype
  use typesAndConstants
  
  implicit none

  type fScale

    real(kind=wp) :: eta
    real(kind=wp) :: rho
    real(kind=wp) :: aw
    real(kind=wp) :: lambda_w
    real(kind=wp) :: gamma_r

    real(kind=wp) :: lambda_r
    real(kind=wp) :: lc, lg
    real(kind=wp) :: ux, uy
    real(kind=wp) :: kappa
    logical :: qOneD

  end type fScale


  INTERFACE scaleG
      MODULE PROCEDURE scaleG_single, scaleG_array
  END INTERFACE


  INTERFACE unscaleG
      MODULE PROCEDURE unscaleG_single, unscaleG_array
  END INTERFACE


  INTERFACE scaleX
      MODULE PROCEDURE scaleX_single, scaleX_array
  END INTERFACE


  INTERFACE unscaleX
      MODULE PROCEDURE unscaleX_single, unscaleX_array
  END INTERFACE


  INTERFACE scalePx
      MODULE PROCEDURE scalePx_single, scalePx_array
  END INTERFACE


  INTERFACE unscalePx
      MODULE PROCEDURE unscalePx_single, unscalePx_array
  END INTERFACE


  INTERFACE scaleT
      MODULE PROCEDURE scaleT_single, scaleT_array
  END INTERFACE


  INTERFACE unscaleT
      MODULE PROCEDURE unscaleT_single, unscaleT_array
  END INTERFACE


  contains





!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!  Scaling of emittance



!> @author
!> Lawrence Campbell,
!> University of Strathclyde,
!> Glasgow, UK
!> @brief
!> Convert unnormalised emittance -> Puffin scaled emittance
!> @param[in] tScaling Custom Fortran type describing scaling
!> @param[inout] sEmit Input geometric emittance, is output as Scaled emittance

    subroutine scaleEmit(tScaling, sEmit)

      real(kind=wp), intent(inout) :: sEmit
      type(fScale), intent(in) :: tScaling

      sEmit = sEmit / (tScaling%lambda_r / (4.0_wp * pi) )

    end subroutine scaleEmit

!> @author
!> Lawrence Campbell,
!> University of Strathclyde,
!> Glasgow, UK
!> @brief
!> Convert Puffin scaled emittance ->  unnormalised emittance
!> @param[in] tScaling Custom Fortran type describing scaling
!> @param[inout] sEmit Input Scaled emittance, is output as geometric emittance

    subroutine unscaleEmit(tScaling, sEmit)

      real(kind=wp), intent(inout) :: sEmit
      type(fScale), intent(in) :: tScaling


      sEmit = sEmit * (tScaling%lambda_r / (4.0_wp * pi) )

    end subroutine unscaleEmit

!!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!





!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!  Scaling of energy - gamma


!> @author
!> Lawrence Campbell,
!> University of Strathclyde,
!> Glasgow, UK
!> @brief
!> Convert Lorentz (gamma) factor ->  Puffin scaled energy
!> @param[in] tScaling Custom Fortran type describing scaling
!> @param[inout] sGamma Lorentz factor in input, Scaled energy on output

    subroutine scaleG_single(tScaling, sGamma)

      type(fScale), intent(in) :: tScaling
      real(kind=wp), intent(inout) :: sGamma

      sGamma = sGamma / tScaling%gamma_r

    end subroutine scaleG_single

!> @author
!> Lawrence Campbell,
!> University of Strathclyde,
!> Glasgow, UK
!> @brief
!> Convert Puffin scaled energy ->  Lorentz (gamma) factor
!> @param[in] tScaling Custom Fortran type describing scaling
!> @param[inout] sGamma Scaled energy in input, Lorentz factor on output

    subroutine unscaleG_single(tScaling, sGamma)

      type(fScale), intent(in) :: tScaling
      real(kind=wp), intent(inout) :: sGamma

      sGamma = sGamma * tScaling%gamma_r

    end subroutine unscaleG_single


!> @author
!> Lawrence Campbell,
!> University of Strathclyde,
!> Glasgow, UK
!> @brief
!> Convert Lorentz (gamma) factor ->  Puffin scaled energy
!> @param[in] tScaling Custom Fortran type describing scaling
!> @param[inout] sGamma Lorentz factor in input, Scaled energy on output

    subroutine scaleG_array(tScaling, sGamma)

      type(fScale), intent(in) :: tScaling
      real(kind=wp), intent(inout) :: sGamma(:)

      sGamma = sGamma / tScaling%gamma_r

    end subroutine scaleG_array

!> @author
!> Lawrence Campbell,
!> University of Strathclyde,
!> Glasgow, UK
!> @brief
!> Convert Puffin scaled energy ->  Lorentz (gamma) factor
!> @param[in] tScaling Custom Fortran type describing scaling
!> @param[inout] sGamma Scaled energy in input, Lorentz factor on output

    subroutine unscaleG_array(tScaling, sGamma)

      type(fScale), intent(in) :: tScaling
      real(kind=wp), intent(inout) :: sGamma(:)
    
      sGamma = sGamma * tScaling%gamma_r
    
    end subroutine unscaleG_array


!!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!  Scaling of transverse coordinate X

    subroutine scaleX_single(sx, Lg, Lc)

      real(kind=wp), intent(inout) :: sx
      real(kind=wp), intent(in) :: Lg, Lc

      sx = sx / sqrt(Lg*Lc)

    end subroutine scaleX_single


    subroutine unscaleX_single(sx, Lg, Lc)

  	  real(kind=wp), intent(inout) :: sx
      real(kind=wp), intent(in) :: Lg, Lc

      sx = sx * sqrt(Lg*Lc)

    end subroutine unscaleX_single


    subroutine scaleX_array(sx, Lg, Lc)

      real(kind=wp), intent(inout) :: sx(:)
      real(kind=wp), intent(in) :: Lg, Lc

      sx = sx / sqrt(Lg*Lc)

    end subroutine scaleX_array


    subroutine unscaleX_array(sx, Lg, Lc)

      real(kind=wp), intent(inout) :: sx(:)
      real(kind=wp), intent(in) :: Lg, Lc

      sx = sx * sqrt(Lg*Lc)

    end subroutine unscaleX_array

!!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!! Scaling of transverse momenta px



    subroutine scalePx_single(sPx, sgamma, saw)

!    Inputting dx/dz, outputting \bar{px}

      real(kind=wp), intent(inout) :: sPx
      real(kind=wp), intent(in) :: saw, sgamma


      sPx = sPx * sgamma / saw

    end subroutine scalePx_single



    subroutine unscalePx_single(sPx, sgamma, saw)

!    Inputting \bar{px}, outputting dx/dz

      real(kind=wp), intent(inout) :: sPx
      real(kind=wp), intent(in) :: saw, sgamma


      sPx = sPx * saw / sgamma 

    end subroutine unscalePx_single



    subroutine scalePx_array(sPx, sgamma, saw)

!    Inputting dx/dz, outputting \bar{px}

      real(kind=wp), intent(inout) :: sPx(:)
      real(kind=wp), intent(in) :: saw, sgamma(:)


      sPx = sPx * sgamma / saw

    end subroutine scalePx_array



    subroutine unscalePx_array(sPx, sgamma, saw)

!    Inputting \bar{px}, outputting dx/dz

      real(kind=wp), intent(inout) :: sPx(:)
      real(kind=wp), intent(in) :: saw, sgamma(:)


      sPx = sPx * saw / sgamma 

    end subroutine unscalePx_array






!!  subroutine scalePx_single(sPx, saw)
!!  
!!  !    Inputting px, outputting \bar{px}
!!  
!!  	real(kind=wp), intent(inout) :: sPx
!!      real(kind=wp), intent(in) :: saw
!!  
!!      sPx = sPx / saw / m_e / c
!!  
!!  end subroutine scalePx_single
!!  
!!  
!!  subroutine unscalePx_single(sPx, saw)
!!  
!!  !    Inputting \bar{px}, outputting px
!!  
!!  	real(kind=wp), intent(inout) :: sPx
!!      real(kind=wp), intent(in) :: saw
!!  
!!      sPx = sPx * saw * m_e * c
!!  
!!  end subroutine unscalePx_single
!!  
!!  subroutine scalePx_array(sPx, saw)
!!  
!!  !    Inputting px, outputting \bar{px}
!!  
!!  	real(kind=wp), intent(inout) :: sPx(:)
!!      real(kind=wp), intent(in) :: saw
!!  
!!      sPx = sPx / saw / m_e / c
!!  
!!  end subroutine scalePx_array
!!  
!!  
!!  subroutine unscalePx_array(sPx, saw)
!!  
!!  !    Inputting \bar{px}, outputting px
!!  
!!  	real(kind=wp), intent(inout) :: sPx(:)
!!      real(kind=wp), intent(in) :: saw
!!  
!!      sPx = sPx * saw * m_e * c
!!  
!!  end subroutine unscalePx_array


!!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!! Scaling of t -> z2

    subroutine scaleT_single(sT, Lc)

! Subroutine to scale t -> z2, for use in Puffin
! Takes in Lc, the cooperation length

      real(kind=wp), intent(inout) :: sT
      real(kind=wp), intent(in) :: Lc

      sT = c * sT / Lc

    end subroutine scaleT_single


    subroutine unscaleT_single(sT, Lc)

      real(kind=wp), intent(inout) :: sT
      real(kind=wp), intent(in) :: Lc

      sT = sT * Lc / c

    end subroutine unscaleT_single

    subroutine scaleT_array(sT, Lc)

! Subroutine to scale t -> z2, for use in Puffin
! Takes in Lc, the cooperation length

      real(kind=wp), intent(inout) :: sT(:)
      real(kind=wp), intent(in) :: Lc

      sT = c * sT / Lc

    end subroutine scaleT_array


    subroutine unscaleT_array(sT, Lc)

      real(kind=wp), intent(inout) :: sT(:)
      real(kind=wp), intent(in) :: Lc

      sT = sT * Lc / c

    end subroutine unscaleT_array

!!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!! Scaling of z -> zbar

    subroutine scaleZ(sZ, Lg)

      real(kind=wp), intent(inout) :: sZ
      real(kind=wp), intent(in) :: Lg

      sZ = sZ / Lg

    end subroutine scaleZ


    subroutine unscaleZ(sZ, Lg)

      real(kind=wp), intent(inout) :: sZ
      real(kind=wp), intent(in) :: Lg

      sZ = sZ * Lg

    end subroutine unscaleZ

!!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!







end module typeScale
