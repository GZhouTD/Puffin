!************* THIS HEADER MUST NOT BE REMOVED *******************!
!** Copyright 2013-2016, Lawrence Campbell and Brian McNeil.    **!
!** This program must not be copied, distributed or altered in  **!
!** any way without the prior permission of the above authors.  **!
!*****************************************************************!


module avwrite

use paratype
use arrayfunctions
use globals
use functions
use sddsROutput
use createSDDS
use ParallelSetUp
use parafield


implicit none

contains





  subroutine writeIntData()

    implicit none

! Outputs integrated data e.g. power, current
! bunching, etc

    call oPower()

  end subroutine writeIntData










  subroutine oPower()

    implicit none

! This subroutine retrieves the power in z2 and
! outputs it to a file.
!
!
! wfield          array used to hold the field in 3D form

!    complex(kind=wp), allocatable :: wfield(:,:,:)
    real(kind=wp), allocatable :: power(:), &
                                  fr_power(:), &
                                  bk_power(:), &
                                  ac_power(:)

    integer :: error
    allocate(power(nz2_g))
    allocate(ac_power(mainlen), fr_power(tlflen4arr), bk_power(tlelen4arr))

!    allocate(wfield(nx,ny,nz2))

!    wfield = complex(reshape(sA(1:nnodes),(/nx,ny,nz2/)), &
!                reshape(sA(nnodes+1:2*nnodes),(/nx,ny,nz2/)))

  
    if ((ffe_GGG > 0) .and. (tlflen > 0) ) then

      call gPower(fr_rfield, fr_ifield, fr_power)

    end if

    call mpi_barrier(tProcInfo_G%comm, error)
!    print*, 'got FRONT powsss'
    

!    if (count(abs(ac_rfield) > 0.0_wp) <= 0) print*, 'HELP IM RUBBUSH POW'

    call gPower(ac_rfield(1:mainlen*ntrnds_G), ac_ifield(1:mainlen*ntrnds_G), ac_power)

!if (count(abs(ac_power) > 0.0_wp) <= 0) print*, 'HELP IM RUBBUSH'

    call mpi_barrier(tProcInfo_G%comm, error)
    !print*, 'got ACC powsss'

    if ((ees_GGG < nz2_G) .and. (tlelen > 0) ) then

      call gPower(bk_rfield, bk_ifield, bk_power)

    end if



    call mpi_barrier(tProcInfo_G%comm, error)
!    print*, 'got powsss'

    
    call UpdateGlobalPow(fr_power, ac_power, bk_power, power)

    call mpi_barrier(tProcInfo_G%comm, error)
!    print*, 'got glob powwww'



    call writePower(power,tPowF)


    call mpi_barrier(tProcInfo_G%comm, error)
!    print*, 'written'


    deallocate(fr_power, ac_power, bk_power, power)

  end subroutine oPower












  subroutine writePower(power,powFType)

    implicit none

! This subroutine appends the power at the current
! step to the SDDS power file.
!
! inputs

    real(kind=wp), intent(in) :: power(:)
    type(cFileType), intent(inout) :: powFType

    integer(kind=ip) :: nnz2
    logical :: qOKL


    nnz2 = size(power)

    if (tProcInfo_G%qRoot) then 

      call OutputIntegrationData(powFType,&
              power,nnz2,qOKL)

    end if  

  end subroutine writePower







  subroutine initPFile(powFType, qForm)

    implicit none

! This subroutine initializes the SDDS power file
!
! inputs

    type(cFileType), intent(inout) :: powFType
    logical, intent(in) :: qForm

    character(32_IP) :: fname, vname
    logical :: qOKL

    real(kind=wp) :: lx, ly

    powFType%qformatted = qForm
    powFType%zFileName = 'power.sdds' !  filename
    vname = 'power' !  SDDS variable name


    if (tProcInfo_G%qRoot) then

      call CreateSDDSFile(powFType%zFileName, &
                          vname, powFType, qOKL)

    end if
  

    allocate(x_ax_G(NX_G), y_ax_G(NY_G))

    if ( .not. ((NX_G == 1_IP) .and. (NY_G == 1_IP)) ) then
    
      lx = sLengthOfElmX_G * (NX_G-1)
      ly = sLengthOfElmY_G * (NY_G-1)

      x_ax_G = linspace(-lx/2.0_WP, lx/2.0_WP, NX_G)
      y_ax_G = linspace(-ly/2.0_WP, ly/2.0_WP, NY_G)

    end if

  end subroutine initPFile
























  subroutine gPower(rfield, ifield, power)

    implicit none

! This subroutine fetches the temporal Power
! from the 3D field
!
!       ARGUMENTS

    real(kind=wp), intent(in) :: rfield(:), ifield(:)

    real(kind=wp), intent(out) :: power(:)
    
    power = 0.0_wp     ! init

    if ((NX_G == 1_IP) .and. (NY_G == 1_IP)) then

      call fPower_1D(rfield, ifield, power)

    else 

      call fPower_3D(rfield,ifield,x_ax_G,y_ax_G,power)

    end if

  end subroutine gPower













  subroutine fPower_1D(rfield, ifield, power)

    real(kind=wp), intent(in) :: rfield(:), ifield(:)
    real(kind=wp), intent(out) :: power(:)

    power = abs(rfield)**2.0_WP + abs(ifield)**2.0_WP
   ! print*, power

  end subroutine fPower_1D





  subroutine fPower_3D(rfield,ifield,xaxis,yaxis, power)

! This subroutine fetches the temporal Power
! from the 3D field
!
!       ARGUMENTS

    real(kind=wp), intent(in) :: rfield(:), ifield(:), &
                                 xaxis(:), yaxis(:)

    real(kind=wp), intent(out) :: power(:)
    
    real(kind=wp), allocatable :: intens(:), intens2(:,:)
    integer(kind=ip) :: i, bt, et, ntr, nx, ny, nz2, nno

    integer :: error

    nx = NX_G
    ny = NY_G

    ntr = nx * ny ! Num of transverse nodes

    nz2 = size(power)

    allocate(intens(nx*ny), intens2(nx,ny))

    !print*, 'starting loop round trans slices'

    do i = 1, nZ2

      bt = (i-1) * ntr + 1_IP 
      et = i * ntr

      !call mpi_barrier(tProcInfo_G%comm, error)
     ! print*, bt, et, i, nZ2, size(rfield)

      intens = abs(rfield(bt:et))**2.0_WP + abs(ifield(bt:et))**2.0_WP

      !call mpi_barrier(tProcInfo_G%comm, error)
      !print*, 'got intensity', i, intens(1:20)
      


      intens2 = reshape(intens, (/nx,ny/))
      !call mpi_barrier(tProcInfo_G%comm, error)
      !print*, 'reshaped', i


      power(i) = m_trapz2D(xaxis, yaxis, intens2)
      !call mpi_barrier(tProcInfo_G%comm, error)
      !print*, 'integrated', i



      !call mpi_barrier(tProcInfo_G%comm, error)
      !print*, 'power', i, power(i)



    end do

     ! call mpi_finalize(error)
     ! stop

    !print*, 'end of fPower_3D'

    deallocate(intens,intens2)

  end subroutine fPower_3D

























  real function m_trapz2D(x, y, fxy)

    implicit none

! Integration over x and then y, using trapezoidal rule
!
!           ARGUMENTS

    real(kind=wp), dimension(:) :: x,y
    real(kind=wp), dimension(:,:) :: fxy
    integer(kind=ip) :: xe, ye, i, j
    real(kind=wp), allocatable :: cul(:)

    allocate(cul(size(x)))

    xe = size(x)

    do i = 1, xe
      cul(i) = m_trapz(y, fxy(i,:))
    end do

    m_trapz2D = m_trapz(x,cul)

    deallocate(cul)
        
  end function m_trapz2D










  real function m_trapz(x, y, lower, upper)

    implicit none

! Integration of y(x) by trapezoidal rule
!
!           ARGUMENTS

    real(kind=wp), dimension(:) :: x,y
    integer(kind=ip), optional :: lower, upper
    integer(kind=ip) :: l, u, i

    if (present(lower)) then
      l = lower
    else
      l = 1
    end if

    if (present(upper)) then
      u = upper
    else
      u = size(x)
    end if

    m_trapz = 0.0_WP

    do i = l,u-1
      m_trapz = m_trapz + (x(i+1)-x(i))*(y(i+1)+y(i))/2.0
    end do
    
  end function m_trapz



   


  subroutine getCurrNpts(sam_len, npts)

    real(kind=wp), intent(in) :: sam_len
    integer(kind=ip), intent(out) :: npts

    npts = ceiling(sLengthOfElmZ2_G*(NZ2_G-1)/sam_len)  + 1_ip ! round up over length of system

  end subroutine getCurrNpts






  subroutine getCurr(sam_len, Iarray)

    use typesAndConstants

    real(kind=wp), intent(in) :: sam_len
    real(kind=wp), intent(inout) :: Iarray(:)

    integer(kind=ip) :: ij, inl, inu
    real(kind=wp) :: li1, li2, locz2

    Iarray = 0.0_wp   ! initialize

    do ij = 1, size(sElX_G)

      !   Array indices 
      inl = ceiling(sElZ2_G(ij)/sam_len)
      inu = inl + 1

      if ((inu > NZ2_G) .or. (inl<0)) then
        print*, 'NODES OUTSIDE BOUNDS'
        STOP
      end if

      ! Interpolation fractions
      locz2 = sElZ2_G(ij) - (inl-1) * sam_len
      li2 = locz2 / sam_len
      li1 = 1_wp - li2

      if ((li2 < 0.0_wp) .or. (li1<0.0_wp)) then
        print*, 'interps are negative!'
        STOP
      end if

      ! interpolate onto current mesh
      Iarray(inl) = li1 * s_chi_bar_G(ij) + Iarray(inl)
      Iarray(inu) = li2 * s_chi_bar_G(ij) + Iarray(inu)

    end do


    call sum2RootArr(Iarray, size(Iarray), 0)

    Iarray = Iarray * npk_bar_G    ! N_e at each node
    Iarray = Iarray * q_e / sam_len    ! dQ / dz2
    Iarray = Iarray * c / lc_G         ! dQ / dt

  end subroutine getCurr






end module avwrite
