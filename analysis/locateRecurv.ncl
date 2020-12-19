;***************************************************************************
;**********                                                    *************
;**********  A "quick and dirty" function to determine the     *************
;**********  recurvature location of tropical cyclones         *************
;**********                                                    *************
;***************************************************************************
;***************************************************************************
; A. Aiyyer 
; 12.13.2020
; based on my recurv code used in Aiyyer(2015)




undef ("locateRecurv")

function locateRecurv(LatSP,LonSP,ntime,LonSign)


begin

  jRecurv = -9

; if needed convert negative lons to positive
  if (LonSign .eq. 1 ) then
    LonSP = where(LonSP.lt.0, LonSP+360, LonSP) 
  end if
  
; lets smooth the lat lon a little     
    LL :=  LonSP
    LA :=  LatSP

; simple 1-2-1 filter    
;    do ii =  2,ntime-2
;      LL(ii) = .25*(LonSP(ii-1) + 2.*LonSP(ii) + LonSP(ii+1))
;      LA(ii) = .25*(LatSP(ii-1) + 2.*LatSP(ii) + LatSP(ii+1))
;    end do

;Savitzky–Golay filter 1
    do ii =  3,ntime-3
      LL(ii) = (-3.*LonSP(ii-2) + 12.*LonSP(ii-1) + 17.*LonSP(ii) +  12.*LonSP(ii+1) - 3.*LonSP(ii+2))/35.0
      LA(ii) = (-3.*LatSP(ii-2) + 12.*LatSP(ii-1) + 17.*LatSP(ii) +  12.*LatSP(ii+1) - 3.*LatSP(ii+2))/35.0
    end do

;Savitzky–Golay filter 2
;    do ii =  4,ntime-4
;      LL(ii) = (5.*LonSP(ii-3) + -30.*LonSP(ii-2) + 75.*LonSP(ii-1) + 131.*LonSP(ii) +  75.*LonSP(ii+1) - 30.*LonSP(ii+2) + 5.*LonSP(ii+3)  )/231.
;      LA(ii) = (5.*LatSP(ii-3) + -30.*LatSP(ii-2) + 75.*LatSP(ii-1) + 131.*LatSP(ii) +  75.*LatSP(ii+1) - 30.*LatSP(ii+2) + 5.*LatSP(ii+3)  )/231.
;    end do

    jFound  = 0
    irecurv = 0
    nrecurv = 0

    recurJ = new(10,"integer")
    recurJ = -9
    
    do it = 4,ntime-4 ; start a little further into the track  
      val1 =  LL(it+1)-LL(it)
      val2 =  LL(it)-LL(it-1)
      val3 =  LL(it+2) - 2.*LL(it) + LL(it-2)
      val4 =  LA(it+3)  - LA(it)
      val5 =  LonSP(it+3) - LonSP(it)

      if ( (val1 .ge. 0. ) .and. ( val2 .le. 0. ) .and. (val3 .ge. 0. ) ) then              
        if (  (val5   .ge. 0.) .and.(val4   .ge. 0.) ) then
          jRecurv = it
          recurJ(nrecurv) = it
          nrecurv = nrecurv + 1
          if ( nrecurv .gt. 10 ) then
            print ("Num recurv exceeded!!! Exit code!!! Leaving locateRecurv")
            exit
          end if
        end if
      end if 
    end do ;it
  

 return(recurJ)

  
end