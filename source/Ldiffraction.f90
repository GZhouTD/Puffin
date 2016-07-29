module PDiff



use paratype
use parallelinfotype
use transforminfotype
use transforms
use masks
USE FFTW_Constants
USE Globals
use IO

implicit none

contains



SUBROUTINE multiplyexp(h,Field,qOK)

  IMPLICIT NONE
!
! Subroutine to calculate the RHS of the diffraction
! solution in Fourier space.
!
!                    ARGUMENTS
!
! h          IN                Integration step size
! Field     INOUT    local portion of Fourier transformed field
! qOK       OUT       Error flag; if .false. error has occured

  REAL(KIND=WP), INTENT(IN) :: h

  COMPLEX(C_DOUBLE_COMPLEX), pointer, &
                INTENT(INOUT) :: field(:)

  LOGICAL, INTENT(OUT) :: qOK

!                    LOCAL ARGS
!
! posI                        Imaginary unit
!                             (square root of -1)
! ind,x_inc,y_inc,z2_inc      Indices for loop
! loc_nz2                     Number of FT field nodes
!                             on the local process
   
  COMPLEX(KIND=WP) :: posI
  INTEGER(KIND=IP) :: ind,x_inc,y_inc,z2_inc
  INTEGER(KIND=IP) :: loc_nz2
  REAL(KIND=WP) :: cutoff,delz2

!------------------------------------------------------
!                      Begin

  qOK = .FALSE.

  posI=CMPLX(0.0,1.0,KIND=WP)
  delz2=sLengthOfElmZ2_G
  cutoff=2.0_WP*pi*sfilt/(REAL(NZ2_G,KIND=WP)*delz2)
  loc_nz2 = tTransInfo_G%loc_nz2

!      Main loop, multiply FT field by exp factor
  
  DO z2_inc=0,loc_nz2-1_IP
     DO y_inc=0,NY_G-1_IP
        DO x_inc=0,NX_G-1_IP

           ind=x_inc+y_inc*NX_G+z2_inc*NX_G*NY_G

           IF ((kz2_loc_G(z2_inc)>cutoff) .OR. &
                (kz2_loc_G(z2_inc)<-cutoff)) THEN
              
              IF (kz2_loc_G(z2_inc)/=0.0_WP) THEN

                Field(ind)=exp(posI*h*(kx_G(x_inc)**2 + &
                           ky_G(y_inc)**2) / &
                           (2.0_WP*kz2_loc_G(z2_inc)))*Field(ind)

              END IF

           ELSE
              
              IF (qFilter) Field(ind) = CMPLX(0.0, 0.0, C_DOUBLE_COMPLEX)
              
           END IF

        END DO
     END DO
  END DO

!              Set error flag and exit

  qOK = .TRUE.

  GOTO 2000

1000  CALL Error_log('Error in transforms:RearrangeExp',tErrorLog_G)

2000 CONTINUE

END SUBROUTINE multiplyexp

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

SUBROUTINE DiffractionStep(h, sAr, sAi, qOK)

  IMPLICIT NONE
!
! Subroutine to perform free space radiation field diffraction 
! in the dimensionless scaled notation.
! Diffraction step algorithm described in
! LT Campbell and BWJ McNeil, Physics of Plasmas 19, 093119 (2012)
!
!                       ARGUMENTS
!
! h            IN         step size forward in units of
!                         zbar
! recvs and
! displs       IN         Arrays for MPI communication.
!                         They describe the layout of data
!                         across processes. See MPI docs.
! sV           IN         Electron macroparticle array, 
!                         containing coordinates in each 
!                         of the 6 scaled dimensions of this
!                         process's local macroparticles.
! sA           INOUT      Input as global field array at
!                         zbar. Output as global field array
!                         at zbar + h.
! qOK          OUT        Error flag; if .false. error has occured

  REAL(KIND=WP), INTENT(IN)      ::   h
  REAL(KIND=WP), DIMENSION(:), INTENT(INOUT)  :: sAr, sAi
  LOGICAL, INTENT(OUT)  ::  qOK

!                       LOCAL ARGS
!
! work          'work' array used to speed up parallel
!               transforms in FFTW
! sA_local      The local Fourier transformed field array
! qOKL          Local error flag

  COMPLEX(KIND=WP), DIMENSION(:), ALLOCATABLE :: &
       work,sA_local
  integer(kind=ip) :: ntrh
  LOGICAL :: qOKL
  integer :: error

!                      Begin

  qOK = .FALSE.

!     Allocate arrays and get distributed FT of field. 
!     Transforming from A(x,y,z2,zbar) to A(kx,ky,kz2,zbar)


  if (tProcInfo_G%QROOT ) then
    print*,' inside diffraction... ',iCsteps, end_time-start_time
  end if

    
  call Get_time(tr_time_s)


!  ALLOCATE(sA_local(0:tTransInfo_G%TOTAL_LOCAL_SIZE-1))
!  ALLOCATE(work(0:tTransInfo_G%TOTAL_LOCAL_SIZE-1))

  call Get_time(tr_time_e)

  if (tProcInfo_G%QROOT ) then
    print*,' allocating arrays took... ', tr_time_e-tr_time_s
  end if


  sA_local = 0.0_wp
  ntrh = NX_G * NY_G

  Afftw(0:(tTransInfo_G%loc_nz2 * ntrh) - 1) = &
          CMPLX(sAr(1:tTransInfo_G%loc_nz2 * ntrh), &
                 sAi(1:tTransInfo_G%loc_nz2 * ntrh), C_DOUBLE_COMPLEX)

  call Get_time(tr_time_e)

  if (tProcInfo_G%QROOT ) then
    print*,' assigning data took... ', tr_time_e-tr_time_s
  end if

!  CALL setupParallelFourierField(sA_local, work, qOKL) 

  CALL Transform(tTransInfo_G%fplan, &
       Afftw, &
       qOKL)


!  call mpi_barrier(tProcInfo_G%comm, error)
!  print*, size(sA_local), size(sAr), size(sAi), tTransInfo_G%loc_nz2

!  CALL fftwnd_f77_mpi(tTransInfo_G%fplan,1,sA_local,&
!                      work,USE_WORK,&
!                      FFTW_NORMAL_ORDER) 


  call Get_time(tr_time_e)

  if (tProcInfo_G%QROOT ) then
    print*,' forward transform took... ', tr_time_e-tr_time_s
  end if


!  call mpi_barrier(tProcInfo_G%comm, error)
!  print*, 'made it here!!!!'


!    Multiply field by the exp factor to obtain A(kx,ky,kz2,zbar+h)

  CALL MultiplyExp(h,Afftw,qOKL)	

 
  call Get_time(tr_time_e)

  if (tProcInfo_G%QROOT ) then
    print*,' multiply exp took... ', tr_time_e-tr_time_s
  end if


!   Perform the backward fourier transform to obtain A(x,y,z2,zbar+h)

  CALL Transform(tTransInfo_G%bplan, &
       Afftw, &
       qOKL)



!  CALL fftwnd_f77_mpi(tTransInfo_G%bplan,1,sA_local,&
!                      work,USE_WORK,&
!                      FFTW_NORMAL_ORDER) 

  call Get_time(tr_time_e)

  if (tProcInfo_G%QROOT ) then
    print*,' back transform took... ', tr_time_e-tr_time_s
  end if



!  call mpi_barrier(tProcInfo_G%comm, error)
!  print*, 'made it here  2!!!!'





 ! IF (.NOT. qOKL) GOTO 1000

!      Scale the field data to normalize transforms

  Afftw = Afftw/ffact


!      Now solve for the absorbing boundary layer

  CALL AbsorptionStep(sA_local,work,h,tTransInfo_G%loc_nz2,ffact)

  call Get_time(tr_time_e)

  if (tProcInfo_G%QROOT ) then
    print*,' absorption step took... ', tr_time_e-tr_time_s
  end if


  DEALLOCATE(work)

!   Collect data back onto global field var sA on every process

!  CALL gather2Acomtoreal(sA_local,sA, &
!       (NX_G*NY_G*tTransInfo_G%loc_nz2), &
!       NX_G*NY_G*NZ2_G, &
!       tTransInfo_G%TOTAL_LOCAL_SIZE, &
!       recvs,displs)



! assign data back to real and img parts for integration 
! through undulator

  sAr(1:tTransInfo_G%loc_nz2 * ntrh) = &
          real(sA_local(0:(tTransInfo_G%loc_nz2 * ntrh) - 1), &
                            kind=wp)


  sAi(1:tTransInfo_G%loc_nz2 * ntrh) = &
          aimag(sA_local(0:(tTransInfo_G%loc_nz2 * ntrh) - 1))

!call mpi_barrier(tProcInfo_G%comm, error)
!  call mpi_finalize(error)
!  stop


  DEALLOCATE(sA_local)


!        Clear up field emerging outside e-beam

!  CALL clearA(sA, qOKL)

!              Set error flag and exit

  qOK = .TRUE.

  GOTO 2000

1000  CALL Error_log('Error in transforms:DiffractionStep',tErrorLog_G)

2000 CONTINUE

END SUBROUTINE DiffractionStep

!***********************************************************

SUBROUTINE AbsorptionStep(sAl,work,h,loc_nz2,ffact)

! This subroutine implements a boundary region
! in the x, y and z2 directions. The method used
! is similar to e.g. REF.
!
! The boundary layer absorbs the outgoing radiation
! to minimize the reflections of the diffracted 
! radiation.
!
! Written by
! Dr L.T. Campbell
! University of Hamburg
! Oct 2013



! 
! APPLY ABSORPTION FIRST IN THE TRANSVERSE DIRECTION,
! THEN IN THE LONGITUDINAL. 
!
! SO, FIRST, TRANSVERSE MASK, THEN FT, THEN:
!
!          NEW_Af = Af * EXP(delz*beta*(-kx-ky)/kz2)
!
! i.e. EXPONENTIALLY DECREASE FREQUENCY COMPONENTS 
! DEPENDANT ON *BOTH* TRANSVERSE AND LONGITUDINAL 
! WAVENUMBER.
!
! THEN FFT BACK TO A.
!
! THEN APPLY LONGITUDINAL MASK, AND FFT AGAIN
!
! THEN ABSORB LONGITUDINAL PROP FROM DIFFRACTION
!
!
!
!                ARGUMENTS

  COMPLEX(KIND=WP), INTENT(INOUT) :: sAl(0:tTransInfo_G%TOTAL_LOCAL_SIZE-1)
  COMPLEX(KIND=WP), INTENT(INOUT) :: work(0:tTransInfo_G%TOTAL_LOCAL_SIZE-1)
  INTEGER(KIND=IP), INTENT(IN) :: loc_nz2
  REAL(KIND=WP), INTENT(IN) :: h,ffact

!               LOCAL ARGS

  REAL(KIND=WP), allocatable :: mask(:), mask_z2(:)
  COMPLEX(KIND=WP), allocatable :: sAnb(:)
  COMPLEX(KIND=WP) :: posI
  INTEGER(KIND=IP) :: iz2, x_inc, y_inc, z2_inc, ind
  integer :: error
  LOGICAL :: qOKL



! ****************************

  allocate(mask(NX_G*NY_G), mask_z2(0:tTransInfo_G%loc_nz2-1))
  allocate(sAnb(0:tTransInfo_G%TOTAL_LOCAL_SIZE-1))

! ****************************



  posI=CMPLX(0.0,1.0,KIND=WP)

  CALL getMask(NX_G, NY_G, sLengthOfElmX_G, sLengthOfElmY_G, &
               NBX_G, NBY_G, mask)
 


!  Now also using boundary in z2....so mask in z2 is....

  IF (loc_nz2 > 0) THEN

    mask_z2 = getZ2Mask(sLengthOfElmZ2_G, nZ2_G, tTransInfo_G%loc_nz2,   &
                         nBZ2_G, tTransInfo_G%loc_z2_start)

!!!!!      sAl is local      !!!!!
!!!!!      goes from 0,total_local_size     !!!!!!!

  

    DO iz2 = 0_IP, loc_nz2 - 1_IP
  
      sAnb(NX_G*NY_G*iz2 : NX_G*NY_G*(iz2+1_IP) - 1_IP)  = (1.0_WP - (mask   +  ( mask_z2(iz2) *  (1.0_WP - mask) ) ) ) * &
                                                            sAl(NX_G*NY_G*iz2 : NX_G*NY_G*(iz2+1_IP) - 1_IP)




!    sAnb(NX_G*NY_G*iz2 : NX_G*NY_G*(iz2+1_IP) - 1_IP) =   (1.0_WP - mask_z2(iz2)) * sAnb(NX_G*NY_G*iz2 : NX_G*NY_G*(iz2+1_IP) - 1_IP)



      sAl(NX_G*NY_G*iz2 : NX_G*NY_G*(iz2+1_IP) - 1_IP) =  (mask   +  ( mask_z2(iz2) *  (1.0_WP - mask) ) ) * &
                                                           sAl(NX_G*NY_G*iz2 : NX_G*NY_G*(iz2+1_IP) - 1_IP)
  
  
    END DO
  
  END IF

!     FFT sAb

  CALL Transform(tTransInfo_G%fplan, &
       work, sAl, qOKL)

!     Apply filter, by decreasing fourier coefficients

  DO z2_inc=0,loc_nz2-1_IP
    DO y_inc=0,NY_G-1_IP
      DO x_inc=0,NX_G-1_IP

        ind=x_inc+y_inc*NX_G+z2_inc*NX_G*NY_G
              
        IF (kz2_loc_G(z2_inc)/=0.0_WP) THEN

              !  sAl(ind)=exp(-posI*h*(kx_G(x_inc)**2 + &
              !             ky_G(y_inc)**2) / &
              !             (2.0_WP*kz2_loc_G(z2_inc)))*sAl(ind)

         sAl(ind) = exp(-h*sBeta_G*(abs(kx_G(x_inc)) + &
                       abs(ky_G(y_inc))) / &
                       (sqrt(abs(2.0_WP * kz2_loc_G(z2_inc))))) * sAl(ind)

!          sAl(ind) = exp(-h*sBeta_G) * sAl(ind)

        END IF

      END DO
    END DO
  END DO

!     Inverse FFT

  CALL Transform(tTransInfo_G%bplan, &
       work, &
       sAl, &
       qOKL)

!CALL MPI_BARRIER(tProcInfo_G%comm,error)

!  IF (.NOT. qOKL) GOTO 1000

!     Scale the field data to normalize transforms

  sAl = sAl / ffact

!     Recombine masked field around boundary with remainder

  sAl = sAl + sAnb


  deallocate(mask, mask_z2)
  deallocate(sAnb)

END SUBROUTINE AbsorptionStep


! PUT IN ANOTHER FILE
!**************************************************
!**************************************************
!**************************************************
!**************************************************

!**************************************************

SUBROUTINE clearA(sA, qOK)

! qOK       OUT      Error flag; if .false. error has occured

  IMPLICIT NONE

  REAL(KIND=WP),INTENT(INOUT) :: sA(:)
  LOGICAL, INTENT(OUT) :: qOK
  INTEGER(KIND=IP) :: error,iz2A,nA,trans
  REAL(KIND=WP) :: loc_max,glo_max

!------------------------------------------------------
!                      Begin

  qOK = .FALSE.

! Set field to zero behind electrons...

! Find furthest back electron
  loc_max = MAXVAL(sElZ2_G)

  CALL MPI_ALLREDUCE(loc_max,glo_max,1,MPI_DOUBLE_PRECISION,&
       MPI_MAX,MPI_COMM_WORLD,error)

! Get corresponding node and increment by 1
  iz2A  = ceiling(glo_max/sLengthOfElmZ2_G)  + 2_IP

  trans=NX_G*NY_G
  nA=size(sA)/2

! Force trailing nodes = 0
  if (seedend<nA) then
    if (iz2A > seedend) then !if electron has passed end of seed
      if (iz2A < nA) then
        sA(((iz2A-1)*trans+1):nA)=0.0_WP !real
        sA(((iz2A-1)*trans+1+nA):2*nA)=0.0_WP !imag
      end if
    else
      sA(((seedend-1)*trans+1):nA)=0.0_WP !real
      sA(((seedend-1)*trans+1+nA):2*nA)=0.0_WP !imag
    end if
  end if
!Other initial condition is z2(0)=0
  sA(1:trans)=0.0_WP
  sA(nA+1:nA+trans)=0.0_WP

!              Set error flag and exit

  qOK = .TRUE.

  GOTO 2000

1000  CALL Error_log('Error in transforms:clearA',tErrorLog_G)

2000 CONTINUE

END SUBROUTINE clearA

!**************************************************

end module PDiff
