module MASPin

use paratype
use globals
use ParallelSetUp
use parBeam

implicit none

contains


  subroutine readMASPfile(zFile)

    character(*), intent(in) :: zFile


    integer(kind=ip) :: nMPs, nMPsLoc
    integer(kind=ip) :: nBlanks_head, nBlanks
    integer :: fid

    integer(kind=ip) :: ir, ij, ios
    integer(kind=ip), allocatable :: recvs_eb(:), displs_eb(:)

    real(kind=wp) :: dV_bar
    
    real(kind=wp) :: dummy1, dummy2, dummy3

    integer :: error

    fid = 132

    dV_bar = 1.884986038391355e-05
    nMPs = 3455789_ip
    iGloNumElectrons_G = nMPs

    dummy1 = 1.0_wp

    ! Split into local num per process

!   Don't care about globLen, etc, only care about numbers of
!   macroparticles...

    call splitBeam(nMPs, dummy1, tProcInfo_G%size, tProcInfo_G%rank, &
                   nMPsLoc, dummy2, dummy3)

    call mpi_barrier(tProcInfo_G%comm, error)

    if ( tProcInfo_G%qRoot ) print*, 'made it 0.1'

    allocate(recvs_eb(tProcInfo_G%size), displs_eb(tProcInfo_G%size))

    call mpi_barrier(tProcInfo_G%comm, error)

    if ( tProcInfo_G%qRoot ) print*, 'made it 0.2'


    call getGathArrs(nMPsLoc,recvs_eb,displs_eb)


    call mpi_barrier(tProcInfo_G%comm, error)

    if ( tProcInfo_G%qRoot ) print*, 'made it 0.3', ' and displs = ', displs_eb


    call mpi_barrier(tProcInfo_G%comm, error)

    if ( tProcInfo_G%qRoot ) print*, 'made it 1'

    iNumberElectrons_G = nMPsLoc

    ! Allocate local MP arrays

    allocate(sElX_G(nMPsLoc),   &
             sElY_G(nMPsLoc),   &
             sElZ2_G(nMPsLoc),  &
             sElPX_G(nMPsLoc),  &
             sElPY_G(nMPsLoc),  &
             sElGam_G(nMPsLoc), &
             s_chi_bar_G(nMPsLoc), &
             s_Normalised_chi_G(nMPsLoc))

    call mpi_barrier(tProcInfo_G%comm, error)

    if ( tProcInfo_G%qRoot ) print*, 'made it 1.1'


    ! read file

    nBlanks_head = 1_ip   ! number of lines in header

    do ir = 0,tProcInfo_G%size-1

      if (ir == tProcInfo_G%rank) then

        OPEN(UNIT=fid,FILE=zFile,IOSTAT=ios,&
             ACTION='READ',POSITION='REWIND')   
  
        nBlanks = displs_eb(ir+1) + nBlanks_head
        print*, 'num of blanks now ', nblanks
        do ij = 1,nBlanks 
        	READ(UNIT=fid, FMT=*) 
        end do

        !do ij = displs_eb(ir+1)+1, nMPsLoc + displs_eb(ir+1)
        do ij = 1, nMPsLoc

          read(UNIT=fid, FMT=*) sElX_G(ij), sElY_G(ij), &
                                sElPX_G(ij), sElPY_G(ij), &
                                sElGam_G(ij), sElZ2_G(ij), &
                                s_chi_bar_G(ij)

        end do

      end if

      call mpi_barrier(tProcInfo_G%comm, error)

      if ( tProcInfo_G%qRoot ) print*, 'made it 1.2 on loop with rank ', ir, &
                               ' with displs  ', displs_eb(ir+1)
  

    end do


    s_Normalised_chi_G = s_chi_bar_G / dV_bar

    ! exit

  end subroutine readMASPfile


end module MASPin

