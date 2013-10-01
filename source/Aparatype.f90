MODULE paratype

IMPLICIT NONE

!Define the different types of data
INTEGER, PARAMETER     ::      short   =SELECTED_INT_KIND(4), &
                               long    =SELECTED_INT_KIND(9), &
                               spec    =SELECTED_INT_KIND(14), &
                               float   =SELECTED_REAL_KIND(P=6),&
                               double  =SELECTED_REAL_KIND(P=14)

INTEGER, PARAMETER     ::      SP      =float
INTEGER, PARAMETER     ::      WP      =double
INTEGER, PARAMETER     ::      IPL     =spec
INTEGER, PARAMETER     ::      IP      =long
INTEGER, PARAMETER     ::      LP      =long

INTEGER, PARAMETER     ::      LGT     =KIND(.true.)	

END MODULE paratype


