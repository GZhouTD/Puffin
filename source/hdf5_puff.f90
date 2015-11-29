module hdf5_puff

USE ArrayFunctions
USE TypesandConstants
USE Globals
USE ParallelSetUp
Use avWrite
use paratype
use HDF5

implicit none 

contains


  SUBROUTINE  WriteAttributeData(zDataFileName, &
       iNodes,&
       iNumElectrons, &
       sLengthOfElm, &
       sStepSize, &
       nSteps, &
       sLenEPulse, &
       sWigglerLength, &
       sSigmaGaussian, &
       sA0_Re, &
       sA0_Im, &
       rho,aw,epsilon,gamma_r, &
       kbeta, ff, &
       lam_w, lam_r, &
       l_g, l_c, &
       npk_bar, &
       totalNumberElectrons, &
       nWaveEquations, &
       nElectronEquations, &  
       sZ, &
       iWriteNthSteps, &
       iIntWriteNthSteps, &
       sSeedSigma, &
       qSwitch, &
       fx, &
       fy, &
       qOK)

! Write input data used to create results
!
! zDataFileName      - INPUT  - Data file name
! iNodes             - INPUT  - Number of Nodes
! iNumElectrons      - INPUT  - number of electrons
! sLengthOfElm       - INPUT  - Element length
! sStepSize          - INPUT  - Integration step size
! nSteps             - INPUT  - Number of steps 
! sLenEPulse 	     - INPUT  - L-electron pulse
! sWigglerLength     - INPUT  - Wiggler length
! sSigmaGaussian     - INPUT  - e-pulse sigma
! sA0_Re,            - INPUT  - Initial field value (real)
! sA0_Im,            - INPUT  - Initial field value (imag)
! iTotalNumElectrons - INPUT  - Acutal Number of electrons used
! nWaveEquations     - INPUT  - Number of Wave Equations
! nElectronEquations - INPUT  - Number of Electron Equations
! sZ                 - UPDATE - IN: Starting z position
! iWriteNthSteps     - UPDATE - Steps to write data at
! sSeedSigma         - INPUT  - Sigma of initial seed field
! qSwitch            - UPDATE - Optional if letting electrons
!                               evolve, field evolve,
!                               diffraction,
!                               gauss inital field
! sx0_offset         - INPUT  - Electron offset value
! sy0_offset         - INPUT  - Electron offset value
! qOK                - OUTPUT - Error flag
!

    IMPLICIT NONE


!  LIst of variables to write as attributes available at FssdsPuffin.f90 lines 250 - 375	
!
    CHARACTER(32_IP), INTENT(IN) :: zDataFileName
    INTEGER(KIND=IP), INTENT(IN) :: iNodes(:)
    INTEGER(KIND=IP), INTENT(IN) :: iNumElectrons(:)
    REAL(KIND=WP),    INTENT(IN) :: sLengthOfElm(:)
    REAL(KIND=WP),    INTENT(IN) :: sStepSize
    INTEGER(KIND=IP), INTENT(IN) :: nSteps
    REAL(KIND=WP),    INTENT(IN) :: sLenEPulse(:)   
    REAL(KIND=WP),    INTENT(IN) :: sWigglerLength(:) 
    REAL(KIND=WP),    INTENT(IN) :: sSigmaGaussian(:)
    REAL(KIND=WP),    INTENT(IN) :: sA0_Re   
    REAL(KIND=WP),    INTENT(IN) :: sA0_Im   
    REAL(KIND=WP),    INTENT(IN) :: rho,aw,epsilon,gamma_r
    REAL(KIND=WP),    INTENT(IN) :: kbeta, ff
    real(kind=wp),    intent(in) :: lam_w, lam_r, l_g, l_c
    real(kind=wp),    intent(in) :: npk_bar
    INTEGER(KIND=IPL), INTENT(IN) :: totalNumberElectrons
    INTEGER(KIND=IP), INTENT(IN) :: nWaveEquations    
    INTEGER(KIND=IP), INTENT(IN) :: nElectronEquations
    REAL(KIND=WP),    INTENT(IN) :: sZ
    INTEGER(KIND=IP), INTENT(IN) :: iWriteNthSteps, iIntWriteNthSteps
    REAL(KIND=WP),    INTENT(IN) :: sSeedSigma(:)
    LOGICAL,          INTENT(IN) :: qSwitch(:)
    REAL(KIND=WP),    INTENT(IN) :: fx,fy
  
    LOGICAL,          INTENT(OUT) :: qOK      
!
! Define local variables
! 
! tParamFile   - Write Parameter data to file
! qOKL         - Local error flag
!	
    TYPE(cFileType) :: tParamFile
    LOGICAL         :: qOKL
!********************************************************
! BEGIN:-
! Set error flag to false         
    qOK = .FALSE.    

    If (tProcInfo_G%qROOT) Then

! Open the file to receive data output -
! This subroutine is in IO.f90 line 793
       tParamFile%qFormatted = .TRUE.
!       call InitBasicSDDSFile('Param' // TRIM(zDataFileName),  or some other init for HDF5
!       If (.NOT. qOKL) Goto 1000
    End If 

!  Set error flag and exit         
    qOK = .TRUE.				    
    GoTo 2000     

! Error Handler - Error log Subroutine in CIO.f90 line 709
1000 call Error_log('Error in hdf5_puff:WriteAttributeData',&
          tErrorLog_G)
    Print*,'Error in hdf5_puff:WriteAttributeData'
2000 CONTINUE
  END SUBROUTINE WriteAttributeData


	subroutine wr_h5(sA, sZ, istep, tArrayA, tArrayE, tArrayZ, &
                     iIntWr, iWr, qSep, zDFname, qWriteFull, &
                     qWriteInt, qOK)

    implicit none

! Write Data FileS


    real(kind=wp), intent(in) :: sA(:), sZ
    type(cArraySegment), intent(inout) :: tArrayA(:), tArrayE(:), tArrayZ
    integer(kind=ip), intent(in) :: istep
    integer(kind=ip), intent(in) :: iIntWr, iWr
    character(32_IP), intent(in) :: zDFName
    logical, intent(in) :: qSep
    logical, intent(inout) :: qOK
    integer :: error
    logical :: qWriteInt, qWriteFull
    error = 0
    if (qWriteFull) then

      call outputH5BeamFiles(iStep, error)
      if (error .ne. 0) goto 1000

      call outputH5Field(sA, iStep, error)
      if (error .ne. 0) goto 1000

!      call outputH5Z(sZ, tArrayZ, iStep, qSep, zDFName, qOKL)
!      if (.not. qOKL) goto 1000

    end if

!    if (qWriteInt) then
!
!      call writeIntData(sA)
!    
!    end if

!  Set error flag and exit         
    error = 0            
    goto 2000     

! Error Handler - Error log Subroutine in CIO.f90 line 709

1000 call Error_log('Error in hdfPuffin:wr_h5',&
          tErrorLog_G)
    print*,'Error in hdfPuffin:wr_h5'
2000 continue

    end subroutine wr_h5

  subroutine outputH5BeamFiles(iStep, error)


    implicit none

! Output the electron bean macroparticle 
! 6D phase space coordinates in Puffin.
! 
! tArrayE   -      Array describing the 
!                  layout of data in 
!                  sV
!
    INTEGER(HID_T) :: file_id       ! File identifier
    INTEGER(HID_T) :: dset_id       ! Dataset identifier 
    INTEGER(HID_T) :: dspace_id     ! Dataspace identifier in memory
    INTEGER(HID_T) :: filespace     ! Dataspace identifier in file
    INTEGER(HID_T) :: attr_id       ! Attribute identifier
    INTEGER(HID_T) :: aspace_id     ! Attribute Dataspace identifier
    INTEGER(HID_T) :: atype_id      ! Attribute Data type identifier
    INTEGER(HID_T) :: group_id      ! Group identifier
!    type(cArraySegment), intent(inout) :: tArrayE(:)
    integer(kind=ip), intent(in) :: iStep
!    logical, intent(in) :: qSeparate
    CHARACTER(LEN=9), PARAMETER :: dsetname = "electrons"     ! Dataset name
    CHARACTER(LEN=16) :: aname   ! Attribute name
!    character(32_IP), intent(in) :: zDFName
    character(32_IP) :: filename
!    logical, intent(inout) :: qOK
!    INTEGER(HSIZE_T), DIMENSION(1) :: dims = (/iGloNumElectrons_G/) ! Dataset dimensions
!    INTEGER     ::   rank = 1                        ! Dataset rank
    INTEGER(HSIZE_T), DIMENSION(2) :: dims 
    INTEGER(HSIZE_T), DIMENSION(2) :: doffset! Offset for write
    INTEGER(HSIZE_T), DIMENSION(2) :: dsize ! Size of hyperslab to write
    INTEGER     ::   rank = 2               ! Particle Dataset rank
    INTEGER     ::  arank = 1               ! Attribute Dataset rank
    INTEGER(HSIZE_T), DIMENSION(1) :: adims ! Attribute dims
    INTEGER(HSIZE_T), DIMENSION(1) :: attr_data_int 
    INTEGER     :: numSpatialDims = 3   ! Attr content,  
!assumed 3D sim. May be 1D.
!    TYPE(C_PTR) :: f_ptr
    REAL(kind=WP) :: attr_data_double
    CHARACTER(LEN=100) :: attr_data_string
    INTEGER(HSIZE_T) :: attr_string_len
    CHARACTER(LEN=4), PARAMETER :: timegrpname = "time"  ! Group name
    CHARACTER(LEN=12), PARAMETER :: limgrpname = "globalLimits"  ! Group name
    REAL(kind=WP), ALLOCATABLE :: limdata (:)  ! Data to write
    ! Local vars

    !integer(kind=ip) :: iep
    integer :: error ! Error flag
    attr_data_int(1)=numSpatialDims
    adims(1)=1
    adims = (/1/) 
    dims = (/7,iNumberElectrons_G/) ! Dataset dimensions
    doffset=(/0,0/)
    dsize=(/1,iNumberElectrons_G/)
    attr_data_string="electrons_x,electrons_y,electrons_z,electrons_px," // &
      "electrons_py,electrons_gamma,electrons_weight"
    attr_string_len=94

! For one file per rank only at the moment
! Individual and collective writing to combined file to come

! Prepare filename

    filename = ( trim(adjustl(IntegerToString(iStep))) // '_' // &
        trim(adjustl(IntegerToString(tProcInfo_G%Rank))) // &
		 '_electrons.h5' )

    CALL h5open_f(error)
!    Print*,'hdf5_puff:outputH5BeamFiles(file opened)'
!
! Create a new file using default properties.
!
    CALL h5fcreate_f(filename, H5F_ACC_TRUNC_F, file_id, error)
!    Print*,'hdf5_puff:outputH5BeamFiles(file created)'
!
! Create the big dataspace in the file.
!
    CALL h5screate_simple_f(rank, dims, filespace, error)
!    Print*,'hdf5_puff:outputH5BeamFiles(filespace created)'

!
! Create the dataset with default properties.
!
    CALL h5dcreate_f(file_id, dsetname, H5T_NATIVE_DOUBLE, filespace, &
       dset_id, error)
!    Print*,'hdf5_puff:outputH5BeamFiles(dataset created)'
    CALL h5sclose_f(filespace, error)
!    Print*,'hdf5_puff:outputH5BeamFiles(filespace closed)'

!
! Create a smaller space to buffer the data writes
!
    CALL h5screate_simple_f(rank, dsize, dspace_id, error)
!    Print*,'hdf5_puff:outputH5BeamFiles(memory dataspace allocated)'

! 
! Select hyperslab in the file.
!
    CALL H5Dget_space_f(dset_id, filespace, error)
    CALL h5sselect_hyperslab_f(filespace, H5S_SELECT_SET_F, doffset, &
       dsize, error)   
    CALL h5dwrite_f(dset_id, H5T_NATIVE_DOUBLE, sElX_G, dims, error, &
       file_space_id = filespace, mem_space_id = dspace_id)
!
! End access to the dataset and release resources used by it.
!
    CALL h5sclose_f(filespace, error) 
!    CALL h5sclose_f(dspace_id, error) 
  
! repeat for some next y dataset
    doffset=(/1,0/)

    CALL H5Dget_space_f(dset_id, filespace, error)
    CALL h5sselect_hyperslab_f(filespace, H5S_SELECT_SET_F, doffset, &
       dsize, error)
    CALL h5dwrite_f(dset_id, H5T_NATIVE_DOUBLE, sElY_G, dims, error, &
       file_space_id = filespace, mem_space_id = dspace_id)
! was       dspace_id, filespace)
    CALL h5sclose_f(filespace, error) 

!
! repeat for some next z dataset
    doffset=(/2,0/)

    CALL H5Dget_space_f(dset_id, filespace, error)
    CALL h5sselect_hyperslab_f(filespace, H5S_SELECT_SET_F, doffset, &
       dsize, error)
    CALL h5dwrite_f(dset_id, H5T_NATIVE_DOUBLE, sElZ2_G, dims, error, &
       file_space_id = filespace, mem_space_id = dspace_id)
! was       dspace_id, filespace)
    CALL h5sclose_f(filespace, error) 


! repeat for some next px dataset
    doffset=(/3,0/)

    CALL H5Dget_space_f(dset_id, filespace, error)
    CALL h5sselect_hyperslab_f(filespace, H5S_SELECT_SET_F, doffset, &
       dsize, error)
    CALL h5dwrite_f(dset_id, H5T_NATIVE_DOUBLE, sElPX_G, dims, error, &
       file_space_id = filespace, mem_space_id = dspace_id)
! was       dspace_id, filespace)
    CALL h5sclose_f(filespace, error) 


! repeat for some next py dataset
    doffset=(/4,0/)

    CALL H5Dget_space_f(dset_id, filespace, error)
    CALL h5sselect_hyperslab_f(filespace, H5S_SELECT_SET_F, doffset, &
       dsize, error)
    CALL h5dwrite_f(dset_id, H5T_NATIVE_DOUBLE, sElPY_G, dims, error, &
       file_space_id = filespace, mem_space_id = dspace_id)
! was       dspace_id, filespace)
    CALL h5sclose_f(filespace, error) 


! repeat for some next gamma dataset (actually beta*gamma)
    doffset=(/5,0/)

    CALL H5Dget_space_f(dset_id, filespace, error)
    CALL h5sselect_hyperslab_f(filespace, H5S_SELECT_SET_F, doffset, &
       dsize, error)
    CALL h5dwrite_f(dset_id, H5T_NATIVE_DOUBLE, sElgam_G, dims, error, &
       file_space_id = filespace, mem_space_id = dspace_id)
! was       dspace_id, filespace)
    CALL h5sclose_f(filespace, error) 
!
! 
! put Chi in the file, slightly redundant as charge on a macroparticle
! doesn't increase or decrease through the simulation. But does make
! Everything self contained. Perhaps we use in future a funky h5 technique
! to point this column at a separate file which holds the data, reducing 
! the size of this column from every written file.
    doffset=(/6,0/)

    CALL H5Dget_space_f(dset_id, filespace, error)
    CALL h5sselect_hyperslab_f(filespace, H5S_SELECT_SET_F, doffset, &
       dsize, error)
    CALL h5dwrite_f(dset_id, H5T_NATIVE_DOUBLE, s_chi_bar_G, dims, error, &
       file_space_id = filespace, mem_space_id = dspace_id)
! was       dspace_id, filespace)
    CALL h5sclose_f(filespace, error) 

!
! Terminate access to the data space.
!
    CALL h5sclose_f(dspace_id, error)
  
!
!
! ATTRIBUTES FOR PARTICLE DATASET
!
!
! simple dataset for array of vals
!    CALL h5screate_simple_f(arank, adims, aspace_id, error)

! scalar dataset for simpler values
    CALL h5screate_f(H5S_SCALAR_F, aspace_id, error)

!
! Create datatype for the attribute.
!
    CALL h5tcopy_f(H5T_NATIVE_INTEGER, atype_id, error)
!    CALL h5tset_size_f(atype_id, attrlen, error)



!
! Create dataset attribute.
!
    aname = "vsNumSpatialDims"
    CALL h5acreate_f(dset_id, aname, atype_id, aspace_id, attr_id, error)
!    Print*,'hdf5_puff:outputH5BeamFiles(attribute created)'
!
  ! Write the attribute data.
  !
  !data_dims(1) = 2
!    f_ptr = C_LOC(numSpatialDims)
! ignore attr dim by setting to zero below
    CALL h5awrite_f(attr_id, atype_id, numSpatialDims, adims, error) !

! Close the attribute.
!
    CALL h5aclose_f(attr_id, error)

! next attribute
    aname="numSpatialDims"
    CALL h5acreate_f(dset_id, aname, atype_id, aspace_id, attr_id, error)
    CALL h5awrite_f(attr_id, atype_id, numSpatialDims, adims, error) 
    CALL h5aclose_f(attr_id, error)
    CALL h5tclose_f(atype_id, error)

! integers done, move onto floats
    CALL h5tcopy_f(H5T_NATIVE_DOUBLE, atype_id, error)
    aname="time"
    attr_data_double=1.0*iStep*sStepSize/c
    CALL h5acreate_f(dset_id, aname, atype_id, aspace_id, attr_id, error)
    CALL h5awrite_f(attr_id, atype_id, attr_data_double, adims, error) 
    CALL h5aclose_f(attr_id, error)
! then
    aname="mass"
!    attr_data_double=9.10938356E-31
    attr_data_double=m_e
    CALL h5acreate_f(dset_id, aname, atype_id, aspace_id, attr_id, error)
    CALL h5awrite_f(attr_id, atype_id, attr_data_double, adims, error) 
    CALL h5aclose_f(attr_id, error)
    aname="charge"
!    attr_data_double=1.602176487E-19
    attr_data_double=q_e
    CALL h5acreate_f(dset_id, aname, atype_id, aspace_id, attr_id, error)
    CALL h5awrite_f(attr_id, atype_id, attr_data_double, adims, error) 
    CALL h5aclose_f(attr_id, error)
    Print*,'hdf5_puff:outputH5BeamFiles(charge written)'
    CALL h5tclose_f(atype_id, error)

! then text attributes
    CALL h5tcopy_f(H5T_NATIVE_CHARACTER, atype_id, error)
!    Print*,'hdf5_puff:outputH5BeamFiles(atype_id set to string)'
    CALL h5tset_size_f(atype_id, attr_string_len, error)
!    Print*,'hdf5_puff:outputH5BeamFiles(string length declared)'
    CALL h5tset_strpad_f(atype_id, H5T_STR_SPACEPAD_F, error)
!    Print*,'hdf5_puff:outputH5BeamFiles(string padding enabled)'
    aname="vsLabels"
    CALL h5acreate_f(dset_id, aname, atype_id, aspace_id, attr_id, error)
!    Print*,'hdf5_puff:outputH5BeamFiles(lables attribute created)'
    CALL h5awrite_f(attr_id, atype_id, attr_data_string, adims, error) 
!    Print*,'hdf5_puff:outputH5BeamFiles(lables attribute written)'
    CALL h5aclose_f(attr_id, error)
!    Print*,'hdf5_puff:outputH5BeamFiles(lables attribute closed)'
    aname="vsType"
    attr_data_string="variableWithMesh"
    attr_string_len=16
    CALL h5tset_size_f(atype_id, attr_string_len, error)
    CALL h5acreate_f(dset_id, aname, atype_id, aspace_id, attr_id, error)
!    Print*,'hdf5_puff:outputH5BeamFiles(type attribute created)'
    CALL h5awrite_f(attr_id, atype_id, attr_data_string, adims, error) 
!    Print*,'hdf5_puff:outputH5BeamFiles(type attribute written)'
    CALL h5aclose_f(attr_id, error)
!    Print*,'hdf5_puff:outputH5BeamFiles(type attribute closed)'
    print*,error
    aname="vsTimeGroup"
    attr_data_string="time"
    attr_string_len=4
    CALL h5tset_size_f(atype_id, attr_string_len, error)
    CALL h5acreate_f(dset_id, aname, atype_id, aspace_id, attr_id, error)
    CALL h5awrite_f(attr_id, atype_id, attr_data_string, adims, error) 
    CALL h5aclose_f(attr_id, error)
    aname="vsLimits"
    attr_data_string="globalLimits"
    attr_string_len=12
    CALL h5tset_size_f(atype_id, attr_string_len, error)
    CALL h5acreate_f(dset_id, aname, atype_id, aspace_id, attr_id, error)
    CALL h5awrite_f(attr_id, atype_id, attr_data_string, adims, error) 
    CALL h5aclose_f(attr_id, error)


! We make a group
    CALL h5gcreate_f(file_id, timegrpname, group_id, error)
    aname="vsType"
    attr_data_string="time"
    attr_string_len=4
    CALL h5tset_size_f(atype_id, attr_string_len, error)
    CALL h5acreate_f(group_id, aname, atype_id, aspace_id, attr_id, error)
    CALL h5awrite_f(attr_id, atype_id, attr_data_string, adims, error) 
    CALL h5aclose_f(attr_id, error)
    CALL h5tclose_f(atype_id, error)

    CALL h5tcopy_f(H5T_NATIVE_DOUBLE, atype_id, error)
    aname="vsTime"
    attr_data_double=1.0*iStep*sStepSize/c
    CALL h5acreate_f(group_id, aname, atype_id, aspace_id, attr_id, error)
    CALL h5awrite_f(attr_id, atype_id, attr_data_double, adims, error) 
    CALL h5aclose_f(attr_id, error)
    CALL h5tclose_f(atype_id, error)
    CALL h5tcopy_f(H5T_NATIVE_INTEGER, atype_id, error)
    aname="vsStep"
    CALL h5acreate_f(group_id, aname, atype_id, aspace_id, attr_id, error)
 !   Print*,error
 !   Print*,'Creating vsStep'
    CALL h5awrite_f(attr_id, atype_id, iStep, adims, error) 
!    Print*,error
!    Print*,'Writing vsStep'
    CALL h5tclose_f(atype_id, error)
    CALL h5aclose_f(attr_id, error)
!    Print*,error
!    Print*,'Closing vsStep'
    CALL h5gclose_f(group_id, error)
!    Print*,error
!    Print*,'Closing timeGroup'

! We make another group
    CALL h5gcreate_f(file_id, limgrpname, group_id, error)
    CALL h5tcopy_f(H5T_NATIVE_CHARACTER, atype_id, error)
    aname="vsType"
    attr_data_string="limits"
    attr_string_len=6
    CALL h5tset_size_f(atype_id, attr_string_len, error)
    CALL h5acreate_f(group_id, aname, atype_id, aspace_id, attr_id, error)
    CALL h5awrite_f(attr_id, atype_id, attr_data_string, adims, error) 
    CALL h5aclose_f(attr_id, error)
    aname="vsKind"
    attr_data_string="Cartesian"
    attr_string_len=9
    CALL h5tset_size_f(atype_id, attr_string_len, error)
    CALL h5acreate_f(group_id, aname, atype_id, aspace_id, attr_id, error)
    CALL h5awrite_f(attr_id, atype_id, attr_data_string, adims, error) 
    CALL h5aclose_f(attr_id, error)
    CALL h5sclose_f(aspace_id, error)

! And the limits themselves which require non-scalar attributes
    adims = (/numSpatialDims/) 
    CALL h5screate_simple_f(arank, adims, aspace_id, error)
    aname="vsLowerBounds"
    CALL h5tcopy_f(H5T_NATIVE_DOUBLE, atype_id, error)
    CALL h5acreate_f(group_id, aname, atype_id, aspace_id, attr_id, error)
    Print*,'hdf5_puff:outputH5BeamFiles(lower bounds attribute created)'
    ALLOCATE ( limdata(numSpatialDims))
    limdata(1)=-0.5*NX_G*sLengthOfElmX_G
    limdata(2)=-0.5*NY_G*sLengthOfElmY_G
    limdata(3)=-0.5*NZ2_G*sLengthOfElmZ2_G
    CALL h5awrite_f(attr_id, atype_id, limdata, adims, error) 
    CALL h5aclose_f(attr_id, error)
    aname="vsUpperBounds"
    CALL h5acreate_f(group_id, aname, atype_id, aspace_id, attr_id, error)
    Print*,'hdf5_puff:outputH5BeamFiles(upper bounds attribute created)'
    limdata(1)=0.5*NX_G*sLengthOfElmX_G
    limdata(2)=0.5*NY_G*sLengthOfElmY_G
    limdata(3)=0.5*NZ2_G*sLengthOfElmZ2_G
    CALL h5awrite_f(attr_id, atype_id, limdata, adims, error) 
    CALL h5aclose_f(attr_id, error)
    DEALLOCATE ( limdata)
    CALL h5tclose_f(atype_id, error)
    CALL h5sclose_f(aspace_id, error)
    
    CALL h5gclose_f(group_id, error)

!
! Close the attribute should be done above. 
!
!    CALL h5aclose_f(attr_id, error)
! Terminate access to the data space.
!

    CALL h5dclose_f(dset_id, error)

!
! Close the file.
!
    CALL h5fclose_f(file_id, error)

!Close the interface
!    CALL h5close_f(error)

!      end if
!		    end if
!      end do



!     Write full 6D electron phase space
!     to file. This will create very large
!     files!!!

!    call wrt_phs_coord(iRe_X_CG, sElX_G, qOKL)
!    call wrt_phs_coord(iRe_Y_CG, sElY_G, qOKL)
!    call wrt_phs_coord(iRe_Z2_CG, sElZ2_G, qOKL)
!    call wrt_phs_coord(iRe_PPerp_CG, sElPX_G, qOKL)
!    call wrt_phs_coord(iIm_PPerp_CG, sElPY_G, qOKL)
!    call wrt_phs_coord(iRe_Gam_CG, sElGam_G, qOKL)
!    if (.not. qOKL) goto 1000
!     size(iRe_X_CG)
!     Set error flag and exit

!    qOK = .true.            
    goto 2000


!     Error Handler - Error log Subroutine in CIO.f90 line 709

1000 call Error_log('Error in hdf5_puff:outputBeamFiles',tErrorLog_G)
    print*,'Error in hdf5_puff:outputBeamFiles'

2000 continue


  end subroutine outputH5BeamFiles

  subroutine outputH5Field(sA, iStep, error)


    implicit none

! Output the electron bean macroparticle 
! 6D phase space coordinates in Puffin.
! 
! tArrayE   -      Array describing the 
!                  layout of data in 
!                  sV
!
    real(kind=wp), intent(in) :: sA(:)
    INTEGER(HID_T) :: file_id       ! File identifier
    INTEGER(HID_T) :: dset_id       ! Dataset identifier 
    INTEGER(HID_T) :: dspace_id     ! Dataspace identifier in memory
    INTEGER(HID_T) :: filespace     ! Dataspace identifier in file
    INTEGER(HID_T) :: attr_id       ! Attribute identifier
    INTEGER(HID_T) :: aspace_id     ! Attribute Dataspace identifier
    INTEGER(HID_T) :: atype_id      ! Attribute Data type identifier
    INTEGER(HID_T) :: group_id      ! Group identifier
    integer(kind=ip), intent(in) :: iStep
! may yet need this, but field data is not separated amongst cores
!    logical, intent(in) :: qSeparate
    CHARACTER(LEN=9), PARAMETER :: dsetname = "Aperp"     ! Dataset name
    CHARACTER(LEN=16) :: aname   ! Attribute name
!    character(32_IP), intent(in) :: zDFName
    character(32_IP) :: filename
    INTEGER(HSIZE_T), DIMENSION(4) :: dims 
! Data as component*reducedNX*reducedNY*reducedNZ2
    INTEGER     ::   rank = 4               ! Dataset rank
    INTEGER(HSIZE_T), DIMENSION(1) :: adims ! Attribute dims
    REAL(kind=WP) :: attr_data_double
    CHARACTER(LEN=100) :: attr_data_string
    INTEGER(HSIZE_T) :: attr_string_len
    INTEGER(kind=IP) :: numSpatialDims = 3   ! Attr content,  
    INTEGER     ::  arank = 1               ! Attribute Dataset rank
    CHARACTER(LEN=4), PARAMETER :: timegrpname = "time"  ! Group name
    CHARACTER(LEN=12), PARAMETER :: limgrpname = "globalLimits"  ! Group name
    CHARACTER(LEN=10), PARAMETER :: meshScaledGrpname = "meshScaled"  ! Group name
    CHARACTER(LEN=6), PARAMETER :: meshSIGrpname = "meshSI"  ! Group name
    REAL(kind=WP), ALLOCATABLE :: limdata (:)  ! Data to write
    INTEGER(kind=IP), ALLOCATABLE :: numcelldata (:)  ! Data to write
    ! Local vars    integer :: error ! Error flag
    integer :: error ! Error flag

   
!Fields are all available to rank zero, and we will worry about
!parallel writing this in due course. 
    if (tProcInfo_G%qRoot) then
      dims = (/2,NX_G,NY_G,NZ2_G/) ! Dataset dimensions

      filename = ( trim(adjustl(IntegerToString(iStep))) // '_' // &
        trim(adjustl(IntegerToString(tProcInfo_G%Rank))) // &
		 '_Aperp.h5' )
      PRINT *,'size of sA'
      PRINT *, size(sA)
      CALL h5open_f(error)
!    Print*,'hdf5_puff:outputH5BeamFiles(file opened)'
!
! Create a new file using default properties.
!
      CALL h5fcreate_f(filename, H5F_ACC_TRUNC_F, file_id, error)
!    Print*,'hdf5_puff:outputH5BeamFiles(file created)'
!
! Create the big dataspace in the file.
!
      CALL h5screate_simple_f(rank, dims, filespace, error)
      Print*,'hdf5_puff:outputH5Field(filespace created)'
      Print*,error
!
! Create the dataset with default properties.
!
      CALL h5dcreate_f(file_id, dsetname, H5T_NATIVE_DOUBLE, filespace, &
       dset_id, error)
      Print*,'hdf5_puff:outputH5Field(dataset created)'
      Print*,error

!
! Create a space in memory to buffer the data writes
!
!      CALL h5screate_simple_f(rank, dims, dspace_id, error)
!      Print*,'hdf5_puff:outputH5BeamFiles(memory dataspace allocated)'

!  try without dataspaces
      CALL h5dwrite_f(dset_id, H5T_NATIVE_DOUBLE, sA, dims, error)
      Print*,'hdf5_puff:outputH5Field(write done)'
      Print*,error

!      CALL h5dwrite_f(dset_id, H5T_NATIVE_DOUBLE, sA, dims, error, &
!        file_space_id = filespace, mem_space_id = dspace_id)
      CALL h5sclose_f(filespace, error)
      Print*,'hdf5_puff:outputH5Field(filespace closed)'
      Print*,error
!

! ATTRIBUTES FOR FIELD DATASET
!
!
! simple dataset for array of vals
!    CALL h5screate_simple_f(arank, adims, aspace_id, error)

! scalar dataset for simpler values
    CALL h5screate_f(H5S_SCALAR_F, aspace_id, error)
    Print*,'hdf5_puff:outputH5Field(scalar space created)'

!
! Create datatype for the attribute.
!
    CALL h5tcopy_f(H5T_NATIVE_DOUBLE, atype_id, error)
    aname="time"
    attr_data_double=1.0*iStep*sStepSize/c
    CALL h5acreate_f(dset_id, aname, atype_id, aspace_id, attr_id, error)
!    Print*,'hdf5_puff:outputH5Field(time attrib created)'
    CALL h5awrite_f(attr_id, atype_id, attr_data_double, adims, error) 
!    Print*,'hdf5_puff:outputH5Field(time attrib written)'
    CALL h5aclose_f(attr_id, error)
!    Print*,'hdf5_puff:outputH5Field(time attrib closed)'
    CALL h5tclose_f(atype_id, error)
!    Print*,'hdf5_puff:outputH5Field(time attrib type closed)'
! then text attributes
    CALL h5tcopy_f(H5T_NATIVE_CHARACTER, atype_id, error)
!    Print*,'hdf5_puff:outputH5BeamFiles(atype_id set to string)'
    aname="vsLabels"
    attr_data_string="A_perp_Re_scaled,A_perp_Im_scaled"
    attr_string_len=33
    CALL h5tset_size_f(atype_id, attr_string_len, error)
    Print*,'hdf5_puff:outputH5Field(string length declared)'
    CALL h5tset_strpad_f(atype_id, H5T_STR_SPACEPAD_F, error)
    Print*,'hdf5_puff:outputH5Field(string padding enabled)'
    CALL h5acreate_f(dset_id, aname, atype_id, aspace_id, attr_id, error)
!    Print*,'hdf5_puff:outputH5BeamFiles(lables attribute created)'
    CALL h5awrite_f(attr_id, atype_id, attr_data_string, adims, error) 
!    Print*,'hdf5_puff:outputH5BeamFiles(lables attribute written)'
    CALL h5aclose_f(attr_id, error)
!    Print*,'hdf5_puff:outputH5BeamFiles(lables attribute closed)'
    aname="vsType"
    attr_data_string="variable"
    attr_string_len=8
    CALL h5tset_size_f(atype_id, attr_string_len, error)
    CALL h5acreate_f(dset_id, aname, atype_id, aspace_id, attr_id, error)
!    Print*,'hdf5_puff:outputH5BeamFiles(type attribute created)'
    CALL h5awrite_f(attr_id, atype_id, attr_data_string, adims, error) 
!    Print*,'hdf5_puff:outputH5BeamFiles(type attribute written)'
    CALL h5aclose_f(attr_id, error)
    aname="vsCentering"
    attr_data_string="nodal"
    attr_string_len=5
    CALL h5tset_size_f(atype_id, attr_string_len, error)
    CALL h5acreate_f(dset_id, aname, atype_id, aspace_id, attr_id, error)
!    Print*,'hdf5_puff:outputH5BeamFiles(type attribute created)'
    CALL h5awrite_f(attr_id, atype_id, attr_data_string, adims, error) 
!    Print*,'hdf5_puff:outputH5BeamFiles(type attribute written)'
    CALL h5aclose_f(attr_id, error)
!    Print*,'hdf5_puff:outputH5BeamFiles(type attribute closed)'
    print*,error
    aname="vsIndexOrder"
    attr_data_string="compMajorF"
    attr_string_len=10
    CALL h5tset_size_f(atype_id, attr_string_len, error)
    CALL h5acreate_f(dset_id, aname, atype_id, aspace_id, attr_id, error)
!    Print*,'hdf5_puff:outputH5BeamFiles(type attribute created)'
    CALL h5awrite_f(attr_id, atype_id, attr_data_string, adims, error) 
!    Print*,'hdf5_puff:outputH5BeamFiles(type attribute written)'
    CALL h5aclose_f(attr_id, error)
!    Print*,'hdf5_puff:outputH5BeamFiles(type attribute closed)'
    print*,error
    aname="vsTimeGroup"
    attr_data_string=timegrpname
    Print*,'hdf5_puff:outputH5Field(time group name being written)'
!
!    Print*,size(timegrpname) - need to figure length of string.
!
    attr_string_len=4
    CALL h5tset_size_f(atype_id, attr_string_len, error)
    Print*,error
    CALL h5acreate_f(dset_id, aname, atype_id, aspace_id, attr_id, error)
    Print*,error
    CALL h5awrite_f(attr_id, atype_id, attr_data_string, adims, error) 
    Print*,error
    CALL h5aclose_f(attr_id, error)
    Print*,'hdf5_puff:outputH5Field(time group attributes closed)'
    Print*,error
    aname="vsLimits"
    attr_data_string=limgrpname
    attr_string_len=12
    CALL h5tset_size_f(atype_id, attr_string_len, error)
    CALL h5acreate_f(dset_id, aname, atype_id, aspace_id, attr_id, error)
    CALL h5awrite_f(attr_id, atype_id, attr_data_string, adims, error) 
    CALL h5aclose_f(attr_id, error)
    Print*,'hdf5_puff:outputH5Field(lim group attributes closed)'
    aname="vsMesh"
    attr_data_string=meshScaledGrpname
    attr_string_len=10
    CALL h5tset_size_f(atype_id, attr_string_len, error)
    Print*,error
    CALL h5acreate_f(dset_id, aname, atype_id, aspace_id, attr_id, error)
    Print*,'hdf5_puff:outputH5Field(mesh attributes created)'
    Print*,error
    CALL h5awrite_f(attr_id, atype_id, attr_data_string, adims, error) 
    Print*,error
    CALL h5aclose_f(attr_id, error)
    Print*,'hdf5_puff:outputH5Field(mesh attributes closed)'
    Print*,error
    CALL h5sclose_f(aspace_id, error)
    Print*,'hdf5_puff:outputH5Field(close scalar space)'
    Print*,error
    CALL h5tclose_f(atype_id, error)
    Print*,error


      CALL h5dclose_f(dset_id, error)
   Print*,'hdf5_puff:outputH5Field(close dataset work on groups)'
    Print*,error
 

! with the main dataset done we work on the other groups with attributes
! We make a group
    CALL h5gcreate_f(file_id, timegrpname, group_id, error)
!   Print*,'hdf5_puff:outputH5Field(group timegrpname created)'
!    Print*,error
    CALL h5tcopy_f(H5T_NATIVE_CHARACTER, atype_id, error)
!   Print*,'hdf5_puff:outputH5Field(set timegrpname type)'
!    Print*,error
    CALL h5tset_strpad_f(atype_id, H5T_STR_SPACEPAD_F, error)
!    Print*,'hdf5_puff:outputH5Field(string padding enabled)'
    aname="vsType"
    attr_data_string="time"
    attr_string_len=4
    CALL h5tset_size_f(atype_id, attr_string_len, error)
!   Print*,'hdf5_puff:outputH5Field(set timegrpname size)'
!    Print*,error
    CALL h5screate_f(H5S_SCALAR_F, aspace_id, error)
    Print*,'hdf5_puff:outputH5Field(scalar attribute space created)'
    Print*,error   
    CALL h5acreate_f(group_id, aname, atype_id, aspace_id, attr_id, error)
   Print*,'hdf5_puff:outputH5Field(create timegrpname time attribute)'
    Print*,error
    CALL h5awrite_f(attr_id, atype_id, attr_data_string, adims, error) 
   Print*,'hdf5_puff:outputH5Field(write timegrpname time attribute)'
    Print*,error
    CALL h5aclose_f(attr_id, error)
   Print*,'hdf5_puff:outputH5Field(close timegrpname time attribute)'
    Print*,error

    CALL h5tclose_f(atype_id, error)
   Print*,'hdf5_puff:outputH5Field(close timegrpname time attributetype )'
    Print*,error

    CALL h5tcopy_f(H5T_NATIVE_DOUBLE, atype_id, error)
    aname="vsTime"
    attr_data_double=1.0*iStep*sStepSize/c
    CALL h5acreate_f(group_id, aname, atype_id, aspace_id, attr_id, error)
    Print*,error
    CALL h5awrite_f(attr_id, atype_id, attr_data_double, adims, error) 
    Print*,error
    CALL h5aclose_f(attr_id, error)
    Print*,error
    CALL h5tclose_f(atype_id, error)
    Print*,error
    CALL h5tcopy_f(H5T_NATIVE_INTEGER, atype_id, error)
    Print*,error
    aname="vsStep"
    CALL h5acreate_f(group_id, aname, atype_id, aspace_id, attr_id, error)
    Print*,error
    Print*,'Creating vsStep'
    CALL h5awrite_f(attr_id, atype_id, iStep, adims, error) 
    Print*,error
    Print*,'Writing vsStep'
    CALL h5tclose_f(atype_id, error)
    CALL h5aclose_f(attr_id, error)
    Print*,error
    Print*,'Closing vsStep'
    Print*,error
    CALL h5gclose_f(group_id, error)
    Print*,'Closing timeGroup'
    Print*,error

! We make another group
    CALL h5gcreate_f(file_id, limgrpname, group_id, error)
    Print*,error
    
    CALL h5tcopy_f(H5T_NATIVE_CHARACTER, atype_id, error)
    Print*,error
    aname="vsType"
    attr_data_string="limits"
    attr_string_len=6
    CALL h5tset_size_f(atype_id, attr_string_len, error)
    Print*,error
    CALL h5acreate_f(group_id, aname, atype_id, aspace_id, attr_id, error)
    Print*,error
    CALL h5awrite_f(attr_id, atype_id, attr_data_string, adims, error) 
    Print*,error
    CALL h5aclose_f(attr_id, error)
    aname="vsKind"
    attr_data_string="Cartesian"
    attr_string_len=9
    CALL h5tset_size_f(atype_id, attr_string_len, error)
    Print*,error
    CALL h5acreate_f(group_id, aname, atype_id, aspace_id, attr_id, error)
    Print*,error
    CALL h5awrite_f(attr_id, atype_id, attr_data_string, adims, error) 
    Print*,error
    CALL h5tclose_f(atype_id, error)
    Print*,error
    CALL h5aclose_f(attr_id, error)
    Print*,error
    CALL h5sclose_f(aspace_id, error)
    Print*,error
! And the limits themselves which require non-scalar attributes
    adims = (/numSpatialDims/) 
    CALL h5screate_simple_f(arank, adims, aspace_id, error)
    aname="vsLowerBounds"
    CALL h5tcopy_f(H5T_NATIVE_DOUBLE, atype_id, error)
    CALL h5acreate_f(group_id, aname, atype_id, aspace_id, attr_id, error)
    Print*,'hdf5_puff:outputH5Field(lower bounds attribute created)'
    ALLOCATE ( limdata(numSpatialDims))
    limdata(1)=-0.5*(NX_G-1_IP)*sLengthOfElmX_G
    limdata(2)=-0.5*(NY_G-1_IP)*sLengthOfElmY_G
    limdata(3)=-0.5*NZ2_G*sLengthOfElmZ2_G
    CALL h5awrite_f(attr_id, atype_id, limdata, adims, error) 
    Print*,error
    CALL h5aclose_f(attr_id, error)
    Print*,error
    aname="vsUpperBounds"
    CALL h5acreate_f(group_id, aname, atype_id, aspace_id, attr_id, error)
    Print*,'hdf5_puff:outputH5Field(upper bounds attribute created)'
    Print*,error
    limdata(1)=0.5*(NX_G-1)*sLengthOfElmX_G
    limdata(2)=0.5*(NY_G-1)*sLengthOfElmY_G
    limdata(3)=0.5*NZ2_G*sLengthOfElmZ2_G
    CALL h5awrite_f(attr_id, atype_id, limdata, adims, error) 
    Print*,error   
    CALL h5aclose_f(attr_id, error)
    Print*,error   
    DEALLOCATE ( limdata)
    CALL h5tclose_f(atype_id, error)
    Print*,error   
    CALL h5sclose_f(aspace_id, error)
    Print*,error   
    
    CALL h5gclose_f(group_id, error)
    Print*,error   


! We make a mesh group
    CALL h5gcreate_f(file_id, meshScaledGrpname, group_id, error)
    CALL h5tcopy_f(H5T_NATIVE_CHARACTER, atype_id, error)
    aname="vsType"
    attr_data_string="mesh"
    attr_string_len=4
    CALL h5tset_size_f(atype_id, attr_string_len, error)
    Print*,error   
    CALL h5screate_f(H5S_SCALAR_F, aspace_id, error)
    Print*,'hdf5_puff:outputH5Field(scalar attribute space created)'
    Print*,error   
    CALL h5acreate_f(group_id, aname, atype_id, aspace_id, attr_id, error)
    Print*,error   
    CALL h5awrite_f(attr_id, atype_id, attr_data_string, adims, error) 
    Print*,error   
    CALL h5aclose_f(attr_id, error)
    Print*,error   
    aname="vsIndexOrder"
    attr_data_string="compMajorF"
    attr_string_len=10
    CALL h5tset_size_f(atype_id, attr_string_len, error)
    CALL h5acreate_f(group_id, aname, atype_id, aspace_id, attr_id, error)
!    Print*,'hdf5_puff:outputH5BeamFiles(type attribute created)'
    CALL h5awrite_f(attr_id, atype_id, attr_data_string, adims, error) 
!    Print*,'hdf5_puff:outputH5BeamFiles(type attribute written)'
    CALL h5aclose_f(attr_id, error)
!    Print*,'hdf5_puff:outputH5BeamFiles(type attribute closed)'
    print*,error
    aname="vsCentering"
    attr_data_string="nodal"
    attr_string_len=5
    CALL h5tset_size_f(atype_id, attr_string_len, error)
    Print*,error   
    Print*,'hdf5_puff:outputH5Field(nodal type resized)'
    CALL h5acreate_f(group_id, aname, atype_id, aspace_id, attr_id, error)
    Print*,'hdf5_puff:outputH5Field(nodal centering attribute created)'
    Print*,error   
!    Print*,'hdf5_puff:outputH5BeamFiles(type attribute created)'
    CALL h5awrite_f(attr_id, atype_id, attr_data_string, adims, error) 
    Print*,error   
!    Print*,'hdf5_puff:outputH5BeamFiles(type attribute written)'
    CALL h5aclose_f(attr_id, error)
    Print*,error   
!    Print*,'hdf5_puff:outputH5BeamFiles(type attribute closed)'
    print*,error
    aname="vsKind"
    attr_data_string="uniform"
    attr_string_len=7
    CALL h5tset_size_f(atype_id, attr_string_len, error)
    CALL h5acreate_f(group_id, aname, atype_id, aspace_id, attr_id, error)
    CALL h5awrite_f(attr_id, atype_id, attr_data_string, adims, error) 
    CALL h5tclose_f(atype_id, error)
    CALL h5aclose_f(attr_id, error)
    CALL h5sclose_f(aspace_id, error)
! And the limits themselves which require non-scalar attributes
    adims = (/numSpatialDims/) 
    CALL h5screate_simple_f(arank, adims, aspace_id, error)
    aname="vsLowerBounds"
    CALL h5tcopy_f(H5T_NATIVE_DOUBLE, atype_id, error)
    CALL h5acreate_f(group_id, aname, atype_id, aspace_id, attr_id, error)
    Print*,'hdf5_puff:outputH5Field(mesh lower bounds attribute created)'
    ALLOCATE ( limdata(numSpatialDims))
    limdata(1)=-0.5*(NX_G-1)*sLengthOfElmX_G
    limdata(2)=-0.5*(NY_G-1)*sLengthOfElmY_G
    limdata(3)=-0.5*NZ2_G*sLengthOfElmZ2_G
    CALL h5awrite_f(attr_id, atype_id, limdata, adims, error) 
    CALL h5aclose_f(attr_id, error)
    aname="vsUpperBounds"
    CALL h5acreate_f(group_id, aname, atype_id, aspace_id, attr_id, error)
    Print*,'hdf5_puff:outputH5Field(mesh upper bounds attribute created)'
    limdata(1)=0.5*(NX_G-1)*sLengthOfElmX_G
    limdata(2)=0.5*(NY_G-1)*sLengthOfElmY_G
    limdata(3)=0.5*NZ2_G*sLengthOfElmZ2_G
    CALL h5awrite_f(attr_id, atype_id, limdata, adims, error) 
    CALL h5aclose_f(attr_id, error)
    DEALLOCATE ( limdata)
    CALL h5tclose_f(atype_id, error)

! Integers
    aname="vsStartCell"
    CALL h5tcopy_f(H5T_NATIVE_INTEGER, atype_id, error)
    CALL h5acreate_f(group_id, aname, atype_id, aspace_id, attr_id, error)
    Print*,'hdf5_puff:outputH5Field(startcell attribute created)'
    ALLOCATE ( numcelldata(numSpatialDims))
    numcelldata(1)=0
    numcelldata(2)=0
    numcelldata(3)=0
    CALL h5awrite_f(attr_id, atype_id, numcelldata, adims, error) 
    CALL h5aclose_f(attr_id, error)
    aname="vsNumCells"
    CALL h5acreate_f(group_id, aname, atype_id, aspace_id, attr_id, error)
    Print*,'hdf5_puff:outputH5Field(numcells attribute created)'
    numcelldata(1)=NX_G-1
    numcelldata(2)=NY_G-1
    numcelldata(3)=NZ2_G-1
    CALL h5awrite_f(attr_id, atype_id, numcelldata, adims, error) 
    CALL h5aclose_f(attr_id, error)
    DEALLOCATE ( numcelldata)
    CALL h5tclose_f(atype_id, error)


    CALL h5sclose_f(aspace_id, error)
    
    CALL h5gclose_f(group_id, error)


!
! Close the file.
!
      CALL h5fclose_f(file_id, error)


    End If 

!      if (tProcInfo_G%qRoot) then

  end subroutine outputH5Field

!  subroutine createH5Files(tArrayY, zDFName, zOptionalString, qOK)
!
!    implicit none

! Create "Full" Files - creates either 
! the full data sets for the field and 
! electron phase space.

!    type(cArraySegment), intent(inout) :: tArrayY(:)
!   character(32_IP), intent(in)   ::   zDFName
!    character(*), intent(in), optional  :: zOptionalString
!    logical, intent(inout) :: qOK

!    integer(kind=ip) :: iap
!    character(32_IP) :: zFileName
!    logical :: qOptional, qOKL



!    qOK = .false.


!    if (present(zOptionalString)) then

!      if (len(trim(adjustl(zOptionalString))) > 0) then

!        qOptional = .TRUE.
    
!      end if
  
!    end if

!     Loop around array segments, creating files

!    do iap = 1, size(tArrayY)

!      if (tArrayY(iap)%qWrite) then
        
!        if (tProcInfo_G%qRoot) then

!     Prepare filename      

!          zFilename = (trim(adjustl(tArrayY(iap)%zVariable)) // trim(adjustl(zDFName)) // '.h5')

!          if (qOptional) then

!            zFilename = (trim(adjustl(zOptionalString)) // '_' // trim(adjustl(zFilename)) // '.h5')

!          end if
!          call CreateSDDSFile(zFilename, &
!                              tArrayY(iap)%zVariable, &
!                              tArrayY(iap)%tFileType, &
!                              qOKL)    
      

!        end if


 !     end if

 !   end do

!     Set error flag and exit

!    qOK = .true.
!    goto 2000


!     Error Handler - Error log Subroutine in CIO.f90 line 709

!1000 call Error_log('Error in sddsPuffin:createFFiles',tErrorLog_G)
!    print*,'Error in sddsPuffin:createFFiles'

!2000 continue


!  end subroutine createH5Files


FUNCTION IntegerToString(iInteger)

! Convert an integer into a string

! iInteger    - INPUT  - Integer to convert

! Define variables

        IMPLICIT NONE

        INTEGER(KIND=IP),          INTENT(IN)                   :: iInteger
        CHARACTER(32_IP)                                        :: IntegerToString

! Define local variables

        CHARACTER(32_IP) :: zCharacter

! Write character to internal file

      write(zCharacter,*) iInteger

! Output without blanks

      IntegerToString = TRIM(ADJUSTL(zCharacter))

!  Set error flag and exit

       GoTo 2000

! Error Handler - Error log Subroutine in CIO.f90 line 709

1000 call Error_log('Error in sddsPuffin:IntegerToString',tErrorLog_G)
      Print*,'Error in sddsPuffin:IntegerToString'
2000 CONTINUE


END FUNCTION IntegerToString
	
	
end module hdf5_puff

