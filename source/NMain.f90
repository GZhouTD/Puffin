!************* THIS HEADER MUST NOT BE REMOVED *******************!
!** Copyright 2013, Lawrence Campbell and Brian McNeil.         **!
!** This program must not be copied, distributed or altered in  **!
!** any way without the prior permission of the above authors.  **!
!*****************************************************************!

program main

use FFTW_Constants
use transforms
use sddsPuffin
use lattice
use Setup
use undulator

!!!!!!!!!!!!!!!!!!! Puffin Version 1.4.4 !!!!!!!!!!!!!!!!!!!
!
! A program for solving an unaveraged 3D FEL system. This 
! parallel MPI code requires the MPI transforms in FFTW v2.5.1.
! The system of equations and numerical solution is presented 
! in:
!
! LT Campbell and BWJ McNeil, Physics of Plasmas 19, 093119 (2012)
!
! Written by Lawrence Campbell, Cynthia Nam, and Dr. Pamela Johnston.
! University of Strathclyde, Glasgow
!
! Contact: lawrence.campbell@strath.ac.uk
!
!                       ARGUMENTS 
!
!
!   sA                    Array containing the values of the
!                         real and imaginary parts of the 
!                         scaled radiation field at the 
!                         radiation field nodes. The radiation
!                         field nodes are arranged in a 3D grid
!                         in x, y and z2. The field values at 
!                         each node are assigned to this 1D
!                         array in order of x, y and z2 (see
!                         documentation). For Nn nodes, sA(1:Nn)
!                         contains the real radiation field 
!                         values and sA(Nn+1:2*Nn) contains
!                         the imaginary field values.
!
!   sZ                    Propagation distance in z through 
!                         the undulator.
!
!   qOKL                  Error flag.

implicit none

!real(kind=wp), allocatable  :: sA(:)
real(kind=wp)    :: sZ
integer(kind=ip) :: iL

logical          :: qOKL

!           Read in data file and initialize system

call init(sZ,qOKL)



call Get_time(start_time)







if (tProcInfo_G%qRoot) print*,' starting..... '

if (tProcInfo_G%qRoot) OPEN(UNIT=137,FILE='rec.out',STATUS='REPLACE',FORM='FORMATTED')
if (tProcInfo_G%qRoot) WRITE(137,*) ' starting..... '

!!!!!!!!!!!!!!!!!!!!!!!  BEGIN INTEGRATION !!!!!!!!!!!!!!!!!!!!!!!!




do iL = 1, modNum




  if (iElmType(iL) == iUnd) then 
 
    call UndSection(iL, sZ)
 
  else if (iElmType(iL) == iQuad) then
 
!    call Quad
 
  else if (iElmType(iL) == iChic) then
 
    call disperse(iL)
 
  else if (iElmType(iL) == iDrift) then
 
!    call drift
 
  end if
  


end do


call cleanup(sZ)   !     Clear arrays and stucts used during integration


CLOSE(UNIT=137,STATUS='KEEP') 





goto 2000     !       Exit

            
1000 call Error_log('Error in Main',tErrorLog_G)
print*,'Error in Main'
print*, 'Check error log file for details, ',tErrorLog_G%zFileName
call UnDefineParallelLibrary(qOKL)

2000 continue

if (tProcInfo_G%qRoot) print*,'Exited successfully'

end program main


