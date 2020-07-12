;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
; a program to:
; check how many storms underwent ET out of those flagged for composites
;  
;
;---------------------------------------------------------------------------
; Aiyyer 
; NCSU Tropical Dynamics Group
;
;
;
; Updates
;
; Dec 3 2019
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
; 

begin


;=================================================
; the ibtracs file  
  fileName = "../dat/IBTrACS.ALL.v04r00.nc"
  fileIB = addfile( fileName, "r" )



  LatS =  30
  LatN =  40
  LonW = -180 
  LonE =  180
  basinAnalysis = "NA" 
  ;fileName = "tcAcc_dates_curvature" + LonW + "_" + LonE + "_" + LatN + "_" + LatS+"_"+ basinAnalysis + ".nc"

  dir = "./" ;"/home/anant/data50/data/tcaccel/one/tang/"
  fileName = dir + "tcAcc_dates" + LonW + "_" + LonE + "_" + LatN + "_" + LatS+"_"+ basinAnalysis + ".nc"
  inFile = addfile( fileName, "r" )
 


  types = (/"Low","High","Zero"/)


  do itype = 0,2
    print ( " ")

    type = types(itype)
    
    if ( type .eq. "Zero" ) then
      RecLat    := inFile->LatZero
      RecLon    := inFile->LonZero
      RecDate   := inFile->timeZero
      iStorm    := inFile->iStormZero
      jStorm    := inFile->jStormZero
    end if
    
    if ( type .eq. "High" ) then
      RecLat  := inFile->LatHigh
      RecLon  := inFile->LonHigh
      RecDate := inFile->timeHigh
      iStorm  := inFile->iStormHigh
      jStorm  := inFile->jStormHigh
    end if
    
    if (type .eq. "Low" ) then
      RecLat  := inFile->LatLow
      RecLon  := inFile->LonLow
      RecDate := inFile->timeLow
      iStorm  := inFile->iStormLow
      jStorm  := inFile->jStormLow
    end if
    
    
    
;----------------------------------------------------------------
; Subset the TC locations for user specified bounds  
    NR := dimsizes(RecLat)
    
;----------------------------------------------------------------
    LatMedian := dim_median(RecLat)
    LonMedian := dim_median(RecLon)  
    LatMean   := dim_avg(RecLat)
    LonMean   := dim_avg(RecLon)
    print ( "Num storms = " + NR )
    print ("Median " + LatMedian + "  " + LonMedian)
    print ("Mean   " + LatMean + "  " + LonMean)


;-----------------------------------------------------------------

    nStorms = 0
    sOld = -9

    sFlag   := new(NR,"integer")
    sIndex  :=  new( (/NR,20/),"integer")
    sCount  := new(NR,"integer")

    sIndex=-9
    
    sFlag = 1

    j = 0
    do i = 0,NR-1
      stormNum := iStorm(i)
      stormJ   := jStorm(i)
      if ( stormNum .ne. sOld ) then
        j=0
        sIndex(nStorms,j) = i
        sCount(nStorms) = j + 1
      end if
      if ( stormNum .eq. sOld) then
        j = j + 1
        nStorms= nStorms-1
        sFlag(i) = 0
        sIndex(nStorms,j) = i
        sCount(nStorms)   = j+1
      end if
      ;print ( i +  " " + nStorms + " " + j + " " +  sFlag(i) + " " + stormNum + " " + stormJ)
      nStorms = nStorms + 1
      sOld = stormNum
    end do

    ;print ( sIndex(0:nStorms-1,0)  + " " +  sIndex(0:nStorms-1,1)  + " " +  sIndex(0:nStorms-1,2) ) 

    print ( "Number of storm events    = " + NR)
    print ( "Number of Unique Storms   = " + nStorms)


;-----------------------------------------------------------------
    iET = 0
; loop over unique storms
    do iS = 0,nStorms

        ETFlag = 0

; loop over each point within this storm that made the cut in the acc dates for comp program      
      do jS = 0,sCount(iS)-1
        ;print ( iS + " " + jS + " " + sIndex(iS,jS) )


        i =  sIndex(iS,jS)


        stormNum := iStorm(i)
        stormJ   := jStorm(i)

        
        ;dateTemp = tointeger(cd_calendar(RecDate(i),0))
        ;month = dateTemp(0,1)
        ;year  = dateTemp(0,0)       
      ;;if ( month .ge. 6 .and. month .le. 11 .and. year .lt. 2016) then

        
        LA := RecLat(i)
        LL := RecLon(i)
        
        lat         = fileIB->lat(stormNum,:)
        lon         = fileIB->lon(stormNum,:)
        nature      = fileIB->nature(stormNum,:,:)
        numobs      = toint(short2flt(fileIB->numobs(stormNum)))
        time        = fileIB->time(stormNum,:)
        
        
        ;print ( i + " " + stormNum + " " + stormJ +" " +lat(stormJ) + " " + LA + " " + lon(stormJ) + " " + LL )
        
        dateRef = time(stormJ)
        do j = stormJ,stormJ+22
          if ( j .ge. 0 .and. j.lt.numobs) then            
            deltaTime = time(j) - dateRef
            StypeA = chartostring(nature(j,:))
            if ( abs(deltaTime) .le. 1.) then
              if ( StypeA .eq. "ET" ) then
                ETFlag = 1
              end if
            end if
          end if
        end do ;j
      end do ;jS

       if ( ETFlag .eq. 1 ) then
          iET = iET + 1
        end if
        ;print ( i + " " + ETFlag + " " + iET )
     
  end do


    perc = 100*tofloat(iET)/tofloat(nStorms)
    print (  nStorms+ " " + iET + " " + perc)
    
  end do



end
