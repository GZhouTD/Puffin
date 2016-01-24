!************* THIS HEADER MUST NOT BE REMOVED *******************!
!** Copyright 2013, Lawrence Campbell and Brian McNeil.         **!
!** This program must not be copied, distributed or altered in  **!
!** any way without the prior permission of the above authors.  **!
!*****************************************************************!

module RK4int

use ParallelInfoType
use TransformInfoType
use FFTW_Constants
use Globals
use Derivative
use IO
use ParaField


contains

subroutine rk4par(sA,A_local,sZ,h,recvs,displs,qD)

  implicit none
!
! Perform 4th order Runge-Kutta integration, tailored
! to Puffin and its method of parallelization: 
! This is NOT a general, all-purpose RK4 routine, it
! is specific to Puffin. Includes MPI_gathers and 
! scatters etc between calculation of derivatives for 
! use with the parallel field derivative.
!
!                ARGUMENTS
!
! y       INPUT/OUTPUT   Electron values
! SA      INPUT/OUTPUT   Field values
! x       INPUT          Propagation distance zbar
! h       INPUT          Step size in zbar
      
  REAL(KIND=WP),  DIMENSION(:), INTENT(INOUT) :: sA, A_local
  REAL(KIND=WP),  INTENT(IN)                  :: sZ
  REAL(KIND=WP),                INTENT(IN)  :: h
  INTEGER(KIND=IP),DIMENSION(:),INTENT(IN)  :: recvs,displs
  LOGICAL, INTENT(INOUT) :: qD

!               LOCAL ARGS
!
! h6         Step size divided by 6
! hh         Half of the step size 
! xh         x position incremented by half a step
! dym        Intermediate derivatives
! dyt        Intermediate derivatives
! yt         Incremental solution
! dAdx       Field derivative
! dydx       Electron derivatives

  INTEGER(KIND=IP) :: iy,idydx,iyout,i,p
  REAL(KIND=WP)    :: h6, hh, szh
  !REAL(KIND=WP), DIMENSION(size(y)) :: dym, dyt, yt

  REAL(KIND=WP), DIMENSION(iNumberElectrons_G) :: dxm, dxt, xt    ! *t is 'temp', for use in next rhs call...
  REAL(KIND=WP), DIMENSION(iNumberElectrons_G) :: dym, dyt, yt
  REAL(KIND=WP), DIMENSION(iNumberElectrons_G) :: dpxm, dpxt, pxt
  REAL(KIND=WP), DIMENSION(iNumberElectrons_G) :: dpym, dpyt, pyt
  REAL(KIND=WP), DIMENSION(iNumberElectrons_G) :: dz2m, dz2t, z2t
  REAL(KIND=WP), DIMENSION(iNumberElectrons_G) :: dpz2m, dpz2t, pz2t  

  REAL(KIND=WP), DIMENSION(:),ALLOCATABLE :: dadz_r0, dadz_i0
  REAL(KIND=WP), DIMENSION(:),ALLOCATABLE :: dadz_r1, dadz_i1
  REAL(KIND=WP), DIMENSION(:),ALLOCATABLE :: dadz_r2, dadz_i2

  REAL(KIND=WP), DIMENSION(:),ALLOCATABLE :: A_localtr0, A_localti0
  REAL(KIND=WP), DIMENSION(:),ALLOCATABLE :: A_localtr1, A_localti1
  REAL(KIND=WP), DIMENSION(:),ALLOCATABLE :: A_localtr2, A_localti2
  REAL(KIND=WP), DIMENSION(:),ALLOCATABLE :: A_localtr3, A_localti3

  REAL(KIND=WP), DIMENSION(:),ALLOCATABLE :: dxdx, dydx, dz2dx, dpxdx, dpydx, dpz2dx
  REAL(KIND=WP), DIMENSION(:),ALLOCATABLE :: dAdx
  REAL(KIND=WP), DIMENSION(:),ALLOCATABLE :: A_localt 
  INTEGER(KIND=IP) :: error, trans

!    Transverse nodes

  trans = (NX_G)*(NY_G)

!    Step sizes

  hh = h * 0.5_WP    
  h6 = h / 6.0_WP
  szh = sz + hh

  allocate(DxDx(iNumberElectrons_G))	  
  allocate(DyDx(iNumberElectrons_G))    
  allocate(DpxDx(iNumberElectrons_G))    
  allocate(DpyDx(iNumberElectrons_G))    
  allocate(Dz2Dx(iNumberElectrons_G))    
  allocate(Dpz2Dx(iNumberElectrons_G))    


  allocate(dadz_r0(tllen), dadz_i0(tllen))
  allocate(dadz_r1(tllen), dadz_i1(tllen))
  allocate(dadz_r2(tllen), dadz_i2(tllen))

  allocate(A_localtr0(tllen), A_localti0(tllen))
  allocate(A_localtr1(tllen), A_localti1(tllen))
  allocate(A_localtr2(tllen), A_localti2(tllen))
  allocate(A_localtr3(tllen), A_localti3(tllen))

  dadz_r0 = 0_wp
  dadz_r1 = 0_wp
  dadz_r2 = 0_wp
  dadz_i0 = 0_wp
  dadz_i1 = 0_wp
  dadz_i2 = 0_wp

  A_localtr0 = 0_wp
  A_localtr1 = 0_wp
  A_localtr2 = 0_wp
  A_localtr3 = 0_wp
  A_localtr0 = 0_wp
  A_localtr1 = 0_wp
  A_localtr2 = 0_wp
  A_localtr3 = 0_wp



  A_localtr0 = ac_rfield
  A_localti0 = ac_ifield

!  allocate(DADx(2*local_rows))
!  allocate(A_localt(2*local_rows))

!    A_local from A_big	  

  if (qD) then

!    if (tTransInfo_G%qOneD) then
!       A_local(1:local_rows)=sA(fst_row:lst_row)
!       A_local(local_rows+1:2*local_rows)=&
!            sA(fst_row+iNumberNodes_G:lst_row+iNumberNodes_G)
!    ELSE
!       CALL getAlocalFS(sA,A_local)
!    END if
!
    qD = .false.
!
  end if

!    First step       
!    Incrementing Y and A
!    Error checking         

!  iy = size(sElX_G)
!  idydx = size(dxdx)
      
!  if (iy /= idydx ) then
!     goto 1000
!  end if
  
!    Get derivatives

  call derivs(sZ, A_localtr0, A_localti0, &
              sElX_G, sElY_G, sElZ2_G, sElPX_G, sElPY_G, sElGam_G, &
              dxdx, dydx, dz2dx, dpxdx, dpydx, dpz2dx, &
              dadz_r0, dadz_i0)



!  allocate(dAm(2*local_rows),dAt(2*local_rows))
  !print*, dpydx

!    Increment local electron and field values
  
  xt = sElX_G      +  hh*dxdx
  yt = sElY_G      +  hh*dydx
  z2t = sElZ2_G    +  hh*dz2dx
  pxt = sElPX_G    +  hh*dpxdx
  pyt = sElPY_G    +  hh*dpydx
  pz2t = sElGam_G  +  hh*dpz2dx





  A_localtr1 = A_localtr0 + hh * dadz_r0
  A_localti1 = A_localti0 + hh * dadz_i0



!    Update large field array with new values 
!  call local2globalA(A_localt,sA,recvs,displs,tTransInfo_G%qOneD)

  call upd8a(A_localtr1, A_localti1)





!    Second step       
!    Get derivatives

  call derivs(szh, A_localtr1, A_localti1, &
       xt, yt, z2t, pxt, pyt, pz2t, &
       dxt, dyt, dz2t, dpxt, dpyt, dpz2t, &
       dadz_r1, dadz_i1)





!    Incrementing with newest derivative value...

  xt = sElX_G      +  hh*dxt
  yt = sElY_G      +  hh*dyt
  z2t = sElZ2_G    +  hh*dz2t
  pxt = sElPX_G    +  hh*dpxt
  pyt = sElPY_G    +  hh*dpyt
  pz2t = sElGam_G  +  hh*dpz2t




  A_localtr2 = A_localtr1 + hh * dadz_r1
  A_localti2 = A_localti1 + hh * dadz_i1



!    Update full field array

!  call local2globalA(A_localt,sA,recvs,displs,tTransInfo_G%qOneD)


  call upd8a(A_localtr2, A_localti2)

!    Third step       
!    Get derivatives



  call derivs(szh, A_localtr2, A_localti2, &
       xt, yt, z2t, pxt, pyt, pz2t, &
       dxm, dym, dz2m, dpxm, dpym, dpz2m, &
       dadz_r2, dadz_i2)






!    Incrementing

  xt = sElX_G      +  h * dxm
  yt = sElY_G      +  h * dym
  z2t = sElZ2_G    +  h * dz2m
  pxt = sElPX_G    +  h * dpxm
  pyt = sElPY_G    +  h * dpym
  pz2t = sElGam_G  +  h * dpz2m

  A_localtr3 = A_localtr2 + h * dadz_r2
  A_localti3 = A_localti2 + h * dadz_i2


!  call local2globalA(A_localt, sA, recvs, displs, tTransInfo_G%qOneD)

  call upd8a(A_localtr3, A_localti3)



  dxm = dxt + dxm
  dym = dyt + dym
  dz2m = dz2t + dz2m
  dpxm = dpxt + dpxm
  dpym = dpyt + dpym
  dpz2m = dpz2t + dpz2m

  dadz_r2 = dadz_r1 + dadz_r2
  dadz_i2 = dadz_i1 + dadz_i2

  dadz_r1 = 0_wp
  dadz_i1 = 0_wp

!    Fourth step       

  szh = sz + h


!    Get derivatives

  call derivs(szh, A_localtr3, A_localti3, &
       xt, yt, z2t, pxt, pyt, pz2t, &
       dxt, dyt, dz2t, dpxt, dpyt, dpz2t, &
       dadz_r1, dadz_i1)  


!    Accumulate increments with proper weights       

  sElX_G    = sElX_G   + h6 * ( dxdx   + dxt   + 2.0_WP * dxm  )
  sElY_G    = sElY_G   + h6 * ( dydx   + dyt   + 2.0_WP * dym  )
  sElZ2_G   = sElZ2_G  + h6 * ( dz2dx  + dz2t  + 2.0_WP * dz2m )
  sElPX_G   = sElPX_G  + h6 * ( dpxdx  + dpxt  + 2.0_WP * dpxm )
  sElPY_G   = sElPY_G  + h6 * ( dpydx  + dpyt  + 2.0_WP * dpym )
  sElGam_G  = sElGam_G + h6 * ( dpz2dx + dpz2t + 2.0_WP * dpz2m)

  ac_rfield = ac_rfield + h6 * (dadz_r0 + dadz_r1 + 2.0_WP * dadz_r2)
  ac_ifield = ac_ifield + h6 * (dadz_i0 + dadz_i1 + 2.0_WP * dadz_i2)



  call upd8a(ac_rfield, ac_ifield)



!  call local2globalA(A_local,sA,recvs,displs,tTransInfo_G%qOneD)

!    Deallocating temp arrays

!  deallocate(dAm,dAt,A_localt)

!  deallocate(DADx)

  deallocate(dadz_r0, dadz_i0)
  deallocate(dadz_r1, dadz_i1)
  deallocate(dadz_r2, dadz_i2)

  deallocate(A_localtr0, A_localti0)
  deallocate(A_localtr1, A_localti1)
  deallocate(A_localtr2, A_localti2)
  deallocate(A_localtr3, A_localti3)

  deallocate(DxDx)    
  deallocate(DyDx)    
  deallocate(DpxDx)    
  deallocate(DpyDx)    
  deallocate(Dz2Dx)    
  deallocate(Dpz2Dx)    

!   Set error flag and exit         

  GOTO 2000

!   Error Handler - Error log Subroutine in CIO.f90 line 709

1000 CALL Error_log('Error in MathLib:rk4',tErrorLog_G)
  PRINT*,'Error in MathLib:rk4'
2000 CONTINUE

end subroutine rk4par


!subroutine RK4_inc



!end subroutine RK4_inc

! Note - the dxdz ad intermediates should all be global,
! if allocating outside of RK4 routine.
!
! They should be passed through to rhs / derivs, and
! be local in there, I think....
!
! All those vars being passed into rhs? GLOBAL.
! Only the arrays should be global.
! Same for the equations module...
!
! Scoop out preamble of rhs, defining temp vars.
! These can all be defined outside this routine to make
! it more readable
! 
! label consistently - *_g for main global,
!                      *_rg for rhs global,
!                      *_dg for diffraction global
!
! Check 3D und eqns - are they general? i.e. can kx and ky be anything?
! 
! Lj, field4elec (real and imag) and dp2f should be global?
!
! Interface for private var access??
! So have dp2f, field4elec and Lj private arrays in the equations module,
! and interface dp2f and field4elec to rhs.f90 to alter them...
! OR alter them through a subroutine....
! SO Lj is common to both field and e eqns...
! whereas field4elec and dp2f are e only.
! So only making Lj and dp2f private to eqns for now
! In fact, they are just globallay defined ATM until
! we get this working....
! Rename eqns to electron eqns or something...
!
! Make rhs / eqns vars global
! fix dp2f interface in rhs.f90 ... DONE 
! only allocate / calc dp2f when it will be used!
!

end module rk4int
