

  subroutine InitBasicSDDSFile(zOutFile, tFileType, qOK)

    implicit none


! Initialise SDDS output files 
!
! zOutFile        - INPUT   - Output file name    
! tFileType       - OUTPUT  -File type properties
! qOK             - OUTPUT  - Error flag
	
    character(*),   intent(in)      :: zOutFile
    type(cFileType),intent(inout)   :: tFileType
    logical,        intent(out)     :: qOK      

! Local Scalars

    logical :: qOKL



!     Set error flag to false

    qOK = .FALSE.


!     Open the file to receive output
!     OpenFileForOutput subroutine starts on line 474 in this file

    call OpenFileForOutput(zOutFile, tFileType, qOKL)
    If (.NOT. qOKL) Goto 1000  

!     Write required header at the top of the file

    call WriteSDDSHeader(tFileType,qOKL)
    If (.NOT. qOKL) Goto 1000  


!     Set error flag and exit

    qOK = .TRUE.
    GoTo 2000

!     Error Handler

1000 call Error_log('Error in DIO: InitialiseSDDSFile',tErrorLog_G)
    print*,'Error in DIO: InitialiseSDDSFile'

2000 continue

  end subroutine InitBasicSDDSFile







  subroutine WriteSDDSHeader(tFileType, qOK)

    implicit none

! Write SDDS file header
!
! tFileType - INPUT    - Properties of output file
! qOK       - OUTPUT   - Error flag
!
! Define local variables

    type(cFileType), intent(inout)  :: tFileType
    logical,         intent(out)    :: qOK      



!     Set error flag to false

    qOK = .FALSE.


!     Write SDDS header       

    CALL SddsWriteVersion('1',tFileType)



!     Set error flag and exit         

    qOK = .TRUE.                            
    GoTo 2000     

!     Error Handler

1000 call Error_log('Error in DIO:  WriteSDDSHeader',tErrorLog_G)
    Print*,'Error in DIO: WriteSDDSHeader'

2000 CONTINUE     

  end subroutine WriteSDDSHeader 








  subroutine WriteSDDSNewPage(tFileType, qOK)

    implicit none

! Write SDDS page number
!
! tFileType - INPUT    - Properties of output file
! qOK       - OUTPUT   - Error flag

! Define local variables

    type(cFileType),intent(inout)  :: tFileType
    logical,        intent(out)    :: qOK      




!     Set error flag to false         
      qOK = .FALSE.


!     Increase page number count         

    tFileType%iPage = tFileType%iPage + 1_IP

!     Write SDDS header

    if (tFileType%qFormatted) then
      call SddsWritePage(tFileType%iPage,tFileType)
    end if




!     Set error flag and exit         

    qOK = .TRUE.                            
    goto 2000     

!     Error Handler

1000 call Error_log('Error in DIO:  WriteSDDSNewPage',tErrorLog_G)
    print*,'Error in DIO: WriteSDDSNewPage'

2000 CONTINUE     


      END SUBROUTINE WriteSDDSNewPage
