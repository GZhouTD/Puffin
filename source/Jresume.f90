! Copyright 2012-2017, University of Strathclyde
! Authors: Lawrence T. Campbell
! License: BSD-3-Clause

MODULE RESUME

  USE paratype
  USE typesandconstants
  USE Globals
  USE typempicomm
  USE sddsPuffin

  IMPLICIT NONE

  CONTAINS

  SUBROUTINE initFD(sA,sZ,qOK)

! Subroutine to read in the dump files produced,
! so in event of system failure can resume from 
! last dump files
!
! -Lawrence

!         ARGUMENTS

    REAL(KIND=WP), ALLOCATABLE, INTENT(OUT) :: sA(:)
    REAL(KIND=WP), INTENT(OUT) :: sZ
    LOGICAL, INTENT(OUT)  ::  qOK

!         LOCAL ARGS:-

    INTEGER(KIND=IP) :: sendbuff,recvbuff,req,lrank,rrank
    integer statr(MPI_STATUS_SIZE)
    integer sendstat(MPI_STATUS_SIZE)
    INTEGER(KIND=IP) :: i
    LOGICAL :: qOKL
    INTEGER :: error

!     Set error flag

    qOK = .FALSE.
  
!     Read in the number of macroparticles in each local process

    CALL READNELEC(tProcInfo_G%rank,iNumberElectrons_G)

!     Sum the number of local macroparticles to get the total number of 
!     macroparticles in the system
   
    CALL MPI_ALLREDUCE(iNumberElectrons_G,iGloNumElectrons_G,&
                 1, MPI_INTEGER,MPI_SUM,tProcInfo_G%comm,error)
   
    DEALLOCATE(s_chi_bar_G,s_Normalised_chi_G)

    ALLOCATE(s_chi_bar_G(iNumberElectrons_G),&
           s_Normalised_chi_G(iNumberElectrons_G))


    ALLOCATE(sElX_G(iNumberElectrons_G))
    ALLOCATE(sElY_G(iNumberElectrons_G))
    ALLOCATE(sElZ2_G(iNumberElectrons_G))
    ALLOCATE(sElPX_G(iNumberElectrons_G))
    ALLOCATE(sElPY_G(iNumberElectrons_G))
    ALLOCATE(sElGam_G(iNumberElectrons_G))


    ALLOCATE(sA(nFieldEquations_CG*iNumberNodes_G))
    
    if (iNumberElectrons_G > 0_IP) then
      call READINCHIDATA(s_chi_bar_G,s_Normalised_chi_G,tProcInfo_G%rank)
    end if
    
    if (tProcInfo_G%qRoot) PRINT*, 'RESUMING, reading in previous data'

    call READDUMP(sA,tProcInfo_G%rank,NX_G*NY_G*NZ2_G,&
        iNumberElectrons_G,sz,start_step,&
        tArrayA(1)%tFileType%iPage)

!     MPI - send sA from root to all other processes

    call MPI_BCAST(sA,nFieldEquations_CG*iNumberNodes_G, &
                   MPI_DOUBLE_PRECISION,0,&
                   tProcInfo_G%comm,error) 

!     MPI - send SDDS page number from root to all other processes

    call MPI_BCAST(tArrayA(1)%tFileType%iPage,1, &
                   MPI_INTEGER,0,&
                   tProcInfo_G%comm,error)  

!     MPI - send step number from root to all other processes

    call MPI_BCAST(start_step,1, &
                   MPI_INTEGER,0,&
                   tProcInfo_G%comm,error) 

!     MPI - send position in undulator sZ from root to all other processes

    call MPI_BCAST(sz,1, MPI_DOUBLE_PRECISION,0,&
                   tProcInfo_G%comm,error) 

!     Pass around most recent page numbers for SDDS
  
    tArrayA(2)%tFileType%iPage = tArrayA(1)%tFileType%iPage
    tArrayE(1)%tFileType%iPage = tArrayA(1)%tFileType%iPage
    tArrayE(2)%tFileType%iPage = tArrayA(1)%tFileType%iPage
    tArrayE(3)%tFileType%iPage = tArrayA(1)%tFileType%iPage
    tArrayE(4)%tFileType%iPage = tArrayA(1)%tFileType%iPage
    tArrayE(5)%tFileType%iPage = tArrayA(1)%tFileType%iPage
    tArrayE(6)%tFileType%iPage = tArrayA(1)%tFileType%iPage
    tArrayZ%tFileType%iPage = tArrayA(1)%tFileType%iPage
  
    start_step = start_step + 1_IP
	
!tArrayE(:)%tFileType%iFileLength=iNumberElectrons_G

!    Set up arrays of pointers to locations of data

!    CALL SetUpElectronArray(tArrayE,tArrayA,iNumberElectrons_G, &
!                            iNumberNodes_G,qOKL)
!    IF (.NOT. qOKL) Goto 1000

!     Define processes to the left and right, for 
!     a ring communication

    IF (tProcInfo_G%rank == tProcInfo_G%size-1) THEN
    
      rrank = 0
      lrank = tProcInfo_G%rank-1
       
    ELSE IF (tProcInfo_G%rank==0) THEN
    
      rrank = tProcInfo_G%rank+1
      lrank = tProcInfo_G%size-1
       
    ELSE
    
      rrank = tProcInfo_G%rank+1
      lrank = tProcInfo_G%rank-1
       
    END IF

    procelectrons_G(1) = iNumberElectrons_G
  
    sendbuff = iNumberElectrons_G
    recvbuff = iNumberElectrons_G

!     Send local macroparticle numbers to define Allgather arrays
    
    DO i=2,tProcInfo_G%size
    
      CALL MPI_ISSEND( sendbuff,1,MPI_INTEGER,rrank,0,tProcInfo_G%comm,req,error )
      CALL MPI_RECV( recvbuff,1,MPI_INTEGER,lrank,0,tProcInfo_G%comm,statr,error )
      CALL MPI_WAIT( req,sendstat,error )	  
  
      procelectrons_G(i) = recvbuff
    
      sendbuff=recvbuff
      
    END DO

    PRINT*, 'resuming from step ', start_step

!     Set error flag to success and exit

    qOK = .TRUE.
  
    GOTO 2000

1000 CALL Error_log('Error in setupcalcs:GetInnerNodes',tErrorLog_G)

2000 CONTINUE

  END SUBROUTINE initFD






!==========================================================================

SUBROUTINE READNELEC(rank,nelectrons)

  INTEGER(KIND=IP),INTENT(IN) :: rank
  INTEGER(KIND=IPL),INTENT(INOUT) :: nelectrons
  CHARACTER(1024_IP) :: FileName
  
  FileName = 'nelectrons'//TRIM(IntegerToString(RANK))//'.dump'
 
  OPEN(UNIT=213,FILE=FileName,STATUS='OLD',ACTION='READ',POSITION='REWIND',&
  FORM='UNFORMATTED')
  READ(213) nelectrons
  CLOSE(UNIT=213,STATUS='KEEP')

END SUBROUTINE

!========================================================================== 

SUBROUTINE READDUMP(sA,rank,nnodes,nelectrons,sz,istep,page)

 REAL(KIND=WP),DIMENSION(:),INTENT(OUT) :: sA
 INTEGER(KIND=IP),INTENT(OUT) :: istep,page
 integer(kind=ip),intent(in) :: rank
 INTEGER(KIND=IP),INTENT(IN) :: nnodes
 INTEGER(KIND=IPL), INTENT(INOUT) :: nelectrons
 REAL(KIND=WP),INTENT(OUT) :: sz

 CHARACTER(1024_IP) :: FileName

! FIELD

if (rank==0) then

! Real part
 FileName = 'reA'//TRIM(IntegerToString(RANK))//'.dump'
 

 OPEN(UNIT=213,FILE=FileName,STATUS='OLD',ACTION='READ',POSITION='REWIND',&
 FORM='UNFORMATTED')
 READ(213) sA(1:nnodes)
 CLOSE(UNIT=213,STATUS='KEEP')
! Imaginary part
 FileName = 'imA'//TRIM(IntegerToString(RANK))//'.dump'
 
 OPEN(UNIT=213,FILE=FileName,STATUS='OLD',ACTION='READ',POSITION='REWIND',&
 FORM='UNFORMATTED')
 READ(213) sA(nnodes+1:2*nnodes)
 CLOSE(UNIT=213,STATUS='KEEP') 

end if

! ELECTRONS

if (nelectrons>0) then

! re pperp
 FileName = 'rePPerp'//TRIM(IntegerToString(RANK))//'.dump'
 
 OPEN(UNIT=213,FILE=FileName,STATUS='OLD',ACTION='READ',POSITION='REWIND',&
 FORM='UNFORMATTED')
 READ(213) sElPX_G
 CLOSE(UNIT=213,STATUS='KEEP') 
! Im pperp
 FileName = 'imPPerp'//TRIM(IntegerToString(RANK))//'.dump'
 
 OPEN(UNIT=213,FILE=FileName,STATUS='OLD',ACTION='READ',POSITION='REWIND',&
 FORM='UNFORMATTED')
 READ(213) sElPY_G
 CLOSE(UNIT=213,STATUS='KEEP') 
  sElPY_G = -sElPY_G

! Q 
 FileName = 'Q'//TRIM(IntegerToString(RANK))//'.dump'
 
 OPEN(UNIT=213,FILE=FileName,STATUS='OLD',ACTION='READ',POSITION='REWIND',&
 FORM='UNFORMATTED')
 READ(213) sElGam_G
 CLOSE(UNIT=213,STATUS='KEEP') 
! Z2 
 FileName = 'Z2-'//TRIM(IntegerToString(RANK))//'.dump'
 
 OPEN(UNIT=213,FILE=FileName,STATUS='OLD',ACTION='READ',POSITION='REWIND',&
 FORM='UNFORMATTED')
 READ(213) sElZ2_G
 CLOSE(UNIT=213,STATUS='KEEP') 
! X 
 FileName = 'X'//TRIM(IntegerToString(RANK))//'.dump'
 
 OPEN(UNIT=213,FILE=FileName,STATUS='OLD',ACTION='READ',POSITION='REWIND',&
 FORM='UNFORMATTED')
 READ(213) sElX_G
 CLOSE(UNIT=213,STATUS='KEEP')
! Y
 FileName = 'Y'//TRIM(IntegerToString(RANK))//'.dump'
 
 OPEN(UNIT=213,FILE=FileName,STATUS='OLD',ACTION='READ',POSITION='REWIND',&
 FORM='UNFORMATTED')
 READ(213) sElY_G
 CLOSE(UNIT=213,STATUS='KEEP') 

end if
 
! step

if (rank==0) then

 FileName = 'step'//TRIM(IntegerToString(RANK))//'.dump'
 
 OPEN(UNIT=213,FILE=FileName,STATUS='OLD',ACTION='READ',POSITION='REWIND',&
 FORM='UNFORMATTED')
 READ(213) istep
 CLOSE(UNIT=213,STATUS='KEEP') 

! Z
 FileName = 'Z'//TRIM(IntegerToString(RANK))//'.dump'

 OPEN(UNIT=213,FILE=FileName,STATUS='OLD',ACTION='READ',POSITION='REWIND',&
 FORM='UNFORMATTED')
 READ(213) sz
 CLOSE(UNIT=213,STATUS='KEEP')  

! page
 FileName = 'page'//TRIM(IntegerToString(RANK))//'.dump'
 
 OPEN(UNIT=213,FILE=FileName,STATUS='OLD',ACTION='READ',POSITION='REWIND',&
 FORM='UNFORMATTED')
 READ(213) page
 CLOSE(UNIT=213,STATUS='KEEP') 

end if

END SUBROUTINE READDUMP
!------------------------------------------------------------------

!===================================================================

SUBROUTINE READINCHIDATA(chibar,normchi,rank)

 REAL(KIND=WP),DIMENSION(:),INTENT(OUT) :: chibar
 REAL(KIND=WP),DIMENSION(:),INTENT(OUT) :: normchi
 INTEGER(KIND=IP),INTENT(IN) :: rank

 CHARACTER(1024_IP) :: FileName

! FIELD
! Real part
 FileName = 'chibar' // TRIM(IntegerToString(RANK))//'.dump'
 
 OPEN(UNIT=213,FILE=FileName,STATUS='OLD',ACTION='READ',POSITION='REWIND',&
 FORM='UNFORMATTED')
 READ(213) chibar
 CLOSE(UNIT=213,STATUS='KEEP')
! Imaginary part
 FileName = 'normchi' // TRIM(IntegerToString(RANK))//'.dump'
 
 OPEN(UNIT=213,FILE=FileName,STATUS='OLD',ACTION='READ',POSITION='REWIND',&
 FORM='UNFORMATTED')
 READ(213) normchi
 CLOSE(UNIT=213,STATUS='KEEP') 

        
END SUBROUTINE READINCHIDATA

!___________--------------------------=============++++++++++++++++++++===
!-----------------++=========________________=====================+++++++++

END MODULE RESUME
