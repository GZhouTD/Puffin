!************* THIS HEADER MUST NOT BE REMOVED *******************!
!** Copyright 2013, Lawrence Campbell and Brian McNeil.         **!
!** This program must not be copied, distributed or altered in  **!
!** any way without the prior permission of the above authors.  **!
!*****************************************************************!

!> @author
!> Lawrence Campbell,
!> University of Strathclyde, 
!> Glasgow, UK
!> @brief
!> Module to calculate d/dz of the field values and electron macroparticle 
!> coordinates.

module rhs

! Module to calculate the RHS of the field source equation
! and d/dz of electron equations.
!

use paratype
use ArrayFunctions
use Globals
use Functions
use TransformInfoType
use ParallelInfoType
use Equations2
use wigglerVar
use FiElec1D
use FiElec
use gtop2
use ParaField
use bfields2


implicit none

contains

  subroutine getrhs(sz, &
                    sEAr, sEAi, &
                    sx, sy, sz2, &
                    spr, spi, sgam, &
                    sdx, sdy, sdz2, &
                    sdpr, sdpi, sdgam, &                    
                    sEDADzr, sEDADzi, &
                    qOK)

  use rhs_vars

  implicit none

! Inputs %%%
!
! sZ - Propagation distance
! sA - current radiation field vals
! sy - current electron coordinates in all dimensions
! 
! Output
! sb  - d/dz of electron phase space positions
! sDADz - RHS of field source term

  real(kind=wp), intent(in) :: sz
  real(kind=wp), intent(in) :: sEAr(:,:), sEAi(:,:)
  real(kind=wp), intent(in)  :: sx(:), sy(:), sz2(:), &
                                spr(:), spi(:), sgam(:)

  
  real(kind=wp), intent(inout)  :: sdx(:), sdy(:), sdz2(:), &
                                   sdpr(:), sdpi(:), sdgam(:)

  real(kind=wp), intent(inout) :: sEDADzr(:,:), sEDADzi(:,:) !!!!!!!
  logical, intent(inout) :: qOK

  integer(kind=ipl) :: i, z2node
  
  
  integer(kind=ip) :: xnode, ynode
  real(kind=wp) :: locx, x_in1, x_in2, &
                   locy, y_in1, y_in2, &
                   locz2, z2_in1, z2_in2
  real(kind=wp) :: tx, ty, tz2, tpr, tpi, tgam, &
                   tdx, tdy, tdz2, tdpr, tdpi, tdgam, &
                   bxut, byut, bzut, tp2

  integer(kind=ip) :: ii, ipart, iv, iElm

  integer :: error
  logical qOKL

!     Begin

  qOK = .false.
  qOKL = .false.
    
!     SETUP AND INITIALISE THE PARTICLE'S POSITION
!     ALLOCATE THE ARRAYS

!  allocate(Lj(iNumberElectrons_G)) 
!!  allocate(p_nodes(iNumberElectrons_G))
!!  call alct_e_srtcts(iNumberElectrons_G)
!!  
!!  if (tTransInfo_G%qOneD) then
!!    allocate(lis_GR(2,iNumberElectrons_G))
!!  else
!!    allocate(lis_GR(8,iNumberElectrons_G))
!!  end if


!     Initialise right hand side to zero

  sField4ElecReal = 0.0_WP
  sField4ElecImag = 0.0_WP


  call rhs_tmsavers(sz)  ! This can be moved later...

!     Adjust undulator tuning

  call getAlpha(sZ)
  call adjUndPlace(sZ)


!  nVCS = 64_ip

  do ii = 1, iNumberElectrons_G, nVCS

!    call getP2_T(sp2, sgam, spr, spi, sEta_G, sGammaR_G, saw_G)

!$OMP SIMD
    do i = 1, MIN(nVCS, iNumberElectrons_G - ii + 1_ip)
      
      ipart = i + ii - 1

!                    Get element for this particle 
      p_nodes(i) = (floor( (sx(ipart)+halfx)  / dx)  + 1_IP) + &
                    (floor( (sy(ipart)+halfy)  / dy) * (nspinDX-1_ip) )  + &   !  y 'slices' before primary node
                    ( (nspinDX-1_ip) * (nspinDY-1_ip) * &
                              floor(sz2(ipart)  / dz2) ) - &
                      (fz2-1)*((nspinDX-1_ip) * (nspinDY-1_ip))  ! transverse slices before primary node


!        Get instantaneous dadz
      call getP2_T(tp2, sgam(ipart), spr(ipart), spi(ipart), &
                    sEta_G, sGammaR_G, saw_G)

      sp2(i) = tp2

      dadz_w(i) = (s_chi_bar_G(ipart)/dV3) &
                  * (1.0_wp + sEta_G * tp2 ) &
                          / sgam(ipart)

      xnode = floor( (sx(ipart) + halfx ) / dx)  + 1_IP
      locx = sx(ipart) + halfx - real(xnode  - 1_IP, kind=wp) * dx
      x_in2 = locx / dx
      x_in1 = (1.0_wp - x_in2)
      ynode = floor( (sy(ipart) + halfy )  / dy)  + 1_IP
      locy = sy(ipart) + halfy - real(ynode  - 1_IP, kind=wp) * dy
      y_in2 = locy / dy
      y_in1 = (1.0_wp - y_in2)
      z2node = floor(sz2(ipart)  / dz2)  + 1_IP
      locz2 = sz2(ipart) - real(z2node  - 1_IP, kind=wp) * dz2
      z2_in2 = locz2 / dz2
      z2_in1 = (1.0_wp - z2_in2)
      

!            Get weights for interpolant

      lis_GR(1,i) = x_in1 * y_in1 * z2_in1
      lis_GR(2,i) = x_in2 * y_in1 * z2_in1
      lis_GR(3,i) = x_in1 * y_in2 * z2_in1
      lis_GR(4,i) = x_in2 * y_in2 * z2_in1
      lis_GR(5,i) = x_in1 * y_in1 * z2_in2
      lis_GR(6,i) = x_in2 * y_in1 * z2_in2
      lis_GR(7,i) = x_in1 * y_in2 * z2_in2
      lis_GR(8,i) = x_in2 * y_in2 * z2_in2

    end do

    do i = 1, MIN(nVCS, iNumberElectrons_G - ii + 1_ip)

      ipart = i + ii - 1
!                  Get element ID

      iElm = p_nodes(i)

!                  Get 'instantaneous' dAdz

      !dadzRInst = dadz_w(i) * spr(i)
!$OMP SIMD
      do iv = 1, 8
        sEDADzr(iv, iElm) =         &
          lis_GR(iv,i) * (dadz_w(i) * spr(ipart)) + sEDADzr(iv, iElm)
!      end do

      !dadzIInst = dadz_w(i) * spi(i)

! !$OMP SIMD
!      do iv = 1, 8
        sEDADzi(iv, iElm) =         &
            lis_GR(iv,i) * (dadz_w(i) * spi(ipart)) + sEDADzi(iv, iElm)
!      end do

! !$OMP SIMD
!      do iv = 1, 8

        sField4ElecReal(i) = sField4ElecReal(i) + lis_GR(iv,i) * sEAr(iv, iElm)

        sField4ElecImag(i) = sField4ElecImag(i) + lis_GR(iv,i) * sEAi(iv, iElm)
      
      end do 

    end do

!  Now calc d/dz of electron quantities....

!  ...first get b-fields

!$OMP SIMD
    do i = 1, MIN(nVCS, iNumberElectrons_G - ii + 1_ip)

      ipart = i + ii - 1

      tx = sx(ipart)
      ty = sy(ipart)
      tz2 = sz2(ipart)
      tpr = spr(ipart)
      tpi = spi(ipart)
      tgam = sgam(ipart)
      tp2 = sp2(i)
!      call getP2_T(tp2, tgam, tpr, tpi, sEta_G, sGammaR_G, saw_G)

      call getBFields_T(tx, ty, tz2, &
                        bxut, byut, bzut)


      call dz2dz_fT(tx, ty, tz2, tpr, tpi, tgam, tp2, &
                        tdz2, qOKL)

      call dxdz_fT(tx, ty, tz2, tpr, tpi, tgam, tp2, &
                    tdx, qOKL)

      call dydz_fT(tx, ty, tz2, tpr, tpi, tgam, tp2, &
                    tdy, qOKL)

      call dppdz_r_fT(tx, ty, tz2, tpr, tpi, tgam, sZ, tp2, &
                     sField4ElecReal(i), sField4ElecImag(i), &
                     bxut, byut, bzut, tdpr, qOKL)                            

      call dppdz_i_fT(tx, ty, tz2, tpr, tpi, tgam, sz, tp2, &
                     sField4ElecReal(i), sField4ElecImag(i), &
                     bxut, byut, bzut, tdpi, qOKL)

      call dgamdz_fT(tx, ty, tz2, tpr, tpi, tgam, tp2, &
                     sField4ElecReal(i), sField4ElecImag(i), &
                     tdgam, qOKL)


      sdz2(ipart) = tdz2
      sdx(ipart) = tdx
      sdy(ipart) = tdy
      sdpr(ipart) = tdpr
      sdpi(ipart) = tdpi
      sdgam(ipart) = tdgam

    end do





!   END MASTER LOOP

  end do    

!      call getInterps_3D(sx, sy, sz2)
!      if ((qPArrOK_G) .and. (qInnerXYOK_G)) then 
!        call getFFelecs_3D(sEAr, sEAi)    
!        call getSource_3D(sEDADzr, sEDADzi, spr, spi, sgam, sEta_G)
!      end if




!    IF (ioutside>0) THEN 
!       Print*, 'WARNING: ',ioutside,&
!            ' electrons are outside the inner driving core'
!    END IF


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!      Calculate electron d/dz of electron equations - if needed

  if (.not. qElectronFieldCoupling_G) then
    sField4ElecReal = 0.0_WP
    sField4ElecImag = 0.0_WP
  end if


!    if (qElectronsEvolve_G) then   
!
!        call getBFields(sx, sy, sz, &
!                        bxu, byu, bzu)
!
!!     z2
!
!        CALL dz2dz_f(sx, sy, sz2, spr, spi, sgam, &
!                     sdz2, qOKL)
!        !if (.not. qOKL) goto 1000
!
!!     X
!
!        call dxdz_f(sx, sy, sz2, spr, spi, sgam, &
!                    sdx, qOKL)
!        !if (.not. qOKL) goto 1000             
!
!!     Y
!
!        call dydz_f(sx, sy, sz2, spr, spi, sgam, &
!                    sdy, qOKL)
!        !if (.not. qOKL) goto 1000
!
!
!!     PX (Real pperp)
!       
!        call dppdz_r_f(sx, sy, sz2, spr, spi, sgam, sZ, &
!                       sdpr, qOKL)
!        !if (.not. qOKL) goto 1000
!
!
!!     -PY (Imaginary pperp)
!
!        call dppdz_i_f(sx, sy, sz2, spr, spi, sgam, sz, &
!                       sdpi, qOKL)
!        !if (.not. qOKL) goto 1000
!
!!     P2
!
!        call dgamdz_f(sx, sy, sz2, spr, spi, sgam, &
!                     sdgam, qOKL)
!        !if (.not. qOKL) goto 1000
! 
!    end if 







!    if (qFieldEvolve_G) then

!     Sum dadz from different MPI processes together

!        call sum2RootArr(sDADz,ReducedNX_G*ReducedNY_G*NZ2_G*2,0)

!     Boundary condition dadz = 0 at head of field

!        if (tProcInfo_G%qRoot) sDADz(1:ReducedNX_G*ReducedNY_G) = 0.0_WP
!        if (tProcInfo_G%qRoot) sDADz(ReducedNX_G*ReducedNY_G*NZ2_G + 1: &
!                                     ReducedNX_G*ReducedNY_G*NZ2_G + &
!                                     ReducedNX_G*ReducedNY_G) = 0.0_WP
 
        !if (tTransInfo_G%qOneD) then
        !  if (tProcInfo_G%qRoot) sDADz=sDADz !sDADz=6.0_WP*sDADz
        !else
        !   if (tProcInfo_G%qRoot) sDADz=sDADz !216.0_WP/8.0_WP*sDADz
        !end if

!    end if
    
!     Switch field off

    if (.not. qFieldEvolve_G) then
       sEDADzr = 0.0_WP
       sEDADzi = 0.0_WP
    end if

!     if electrons not allowed to evolve then      

    if (.not. qElectronsEvolve_G) then
       sdpr = 0.0_wp
       sdpi = 0.0_wp
       sdgam = 0.0_wp
       sdx   = 0.0_wp
       sdy   = 0.0_wp
       sdz2 = 0.0_wp
    end if

!     Deallocate arrays

!    deallocate(i_n4e,N,iNodeList_Re,iNodeList_Im,i_n4ered)
!    deallocate(sField4ElecReal,sField4ElecImag,Lj,dp2f)
    !deallocate(Lj)
!!    deallocate(lis_GR)
!!    deallocate(p_nodes)
!!    call dalct_e_srtcts()


    ! Set the error flag and exit

    qOK = .true.

    goto 2000 

1000 call Error_log('Error in rhs:getrhs',tErrorLog_G)
    print*,'Error in rhs:getrhs'
2000 continue

  end subroutine getrhs



!        #########################################



subroutine rhs_tmsavers(sz)

use rhs_vars

real(kind=wp), intent(in) :: sz

  ioutside=0


!     Define the size of each element

  dx = sLengthOfElmX_G
  dy = sLengthOfElmY_G
  dz2 = sLengthOfElmZ2_G

  dV3 = sLengthOfElmX_G*sLengthOfElmY_G*sLengthOfElmZ2_G


!     Time savers

  sInv2rho    = 1.0_WP/(2.0_WP * sRho_G)

  ZOver2rho   = sz * sInv2rho
  salphaSq    = (2.0_WP * sGammaR_G * sRho_G / sAw_G)**2

  kbeta = sAw_G / (2.0_WP * sFocusFactor_G * sRho_G * sGammaR_G)
  un = sqrt(fx_G**2.0_WP + fy_G**2.0_WP)


!     number of transverse nodes

  ntrans = NX_G * NY_G

!     Diff between real and imaginary nodes in the reduced system

  retim = nspinDX*nspinDY*nZ2_G


  fkb= sFocusfactor_G * kbeta

  econst = sAw_G/(sRho_G*sqrt(2.0_WP*(fx_G**2.0_WP+fy_G**2.0_WP)))

  nc = 2.0_WP*saw_G**2/(fx_G**2.0_WP + fy_G**2.0_WP)
    
  nd = sqrt((fx_G**2.0_WP+fy_G**2.0_WP)*(sEta_G))/(2.0_WP*sqrt(2.0_WP)* &
                             fkb*sRho_G)
    
  nb = 2.0_WP * sRho_G / ((fx_G**2.0_WP+fy_G**2.0_WP)*sEta_G)
    
  maxEl = maxval(procelectrons_G)
  qoutside=.FALSE.
  iOutside=0_IP

!  halfx = ((ReducedNX_G-1) / 2.0_WP) * sLengthOfElmX_G
!  halfy = ((ReducedNY_G-1) / 2.0_WP) * sLengthOfElmY_G

  halfx = ((nspinDX-1) / 2.0_WP) * sLengthOfElmX_G
  halfy = ((nspinDY-1) / 2.0_WP) * sLengthOfElmY_G


end subroutine rhs_tmsavers



end module rhs
