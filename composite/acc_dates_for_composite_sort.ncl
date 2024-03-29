;----------------------------------------------------------------------------
; a program to:
;
; read the TC acceleration data and extract dates that match
; user specified threshold for rapid accel, decel and zero accel cases
; The output file will be used to calculate storm centered composites
; of various variables from gridded reanlysis data
;
;
;----------------------------------------------------------------------------
; Aiyyer 
; NCSU Tropical Dynamics Group
;
;----------------------------------------------------------------------------
; Oct 15, 2019
; Oct 02, 2020 Now uses sorted data and percentiles
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------


begin

;---------------------------------------------------------------------------  
; user inputs

  accelType = 2; 1 = tang 2 = curv

  startYear = 1980
  endYear   = 2016

  nYears    = endYear - startYear + 1

  LatS =  30
  LatN =  40 
  basinAnalysis = "NA"  ;WP

; sdev threshold factor = percentile
  sfac  = 0.9
  
  print ( "sfac  = " + sfac )
; the sfac is used to determine the threshold accel, decel values.
; thresh = mean +/- sfac*sdev  
;--------------------------------------------------------------------------  
  fileName = "../tcMotion.nc"
  fileIn = addfile( fileName, "r" )
  time        = fileIn->time
; we expect time units to be in days
  unitsExpected  = "days since 1858-11-17 00:00:00"
  if (time@units .ne. unitsExpected ) then
    print ("Read from file: " + time@units)
    print ("Expected      : " + unitsExpected)
    print ("Error in timeunits. Unexpected units. Terminating code!!!")
    exit
  end if
; set the start and end times to consider  
  startTime = cd_inv_calendar(startYear,1,1,0,0,0,time@units,  0)
  endTime = cd_inv_calendar(endYear,12,31,24,0,0,time@units, 0)
;


  if ( accelType .eq. 1 ) then
    dat = fileIn->accelSpeed
    fileName = "tcAcc_dates_tang"  + "_" + LatN + "_" + LatS+"_"+ basinAnalysis + ".nc"
  end if
  if ( accelType .eq. 2 ) then
    dat = fileIn->accelCurve
    fileName = "tcAcc_dates_curv"  + "_" + LatN + "_" + LatS+"_"+ basinAnalysis + ".nc"
end if

  if ( dat@units .eq. "m/s per day" ) then
    dat = dat*3.6 ; now km/hr per day
    dat@units = "km/hr per day" 
  else
    print (" dat Units unexpected! Terminating code!")
    exit
  end if
  basin = fileIn->basin

;
; read some other variables to be saved in output files
;  
  speed=fileIn->speed
  time= fileIn->time
  Lat = fileIn->lat
  Lon = fileIn->lon
  origJ = fileIn->origJ
  
  numobs      = fileIn->numobs
  nature      = fileIn->nature
;
  dims  = dimsizes(time)
  nStorms  = dims(0)
;
  xmax   =  120.*3.6
; create array to store all accel data for some more stats
  datA   = new ( (/4,60000/),typeof(dat))
  icount = 0

; define output arrays  
  N = 4000
  iHigh = 0
  iHighET = 0

   accelHigh   = new (N,   typeof(dat))
     LatHigh   = new (N, typeof(Lat))
     LonHigh   = new (N, typeof(Lon))
    timeHigh   = new (N, typeof(time))

  iLow = 0
  iLowET = 0

   accelLow   = new (N,  typeof(dat))
     LatLow     = new (N, typeof(Lat))
     LonLow     = new (N, typeof(Lon))
    timeLow    = new (N, typeof(time))

  iZero = 0
  iZeroET = 0

   accelZero   = new (N, typeof(dat))
     LatZero  = new (N, typeof(Lat))
     LonZero  = new (N, typeof(Lon))
    timeZero = new (N, typeof(time))


  
  accelHigh@units = "m/s per day"
  accelHigh@long_name = "acceleration"
  accelLow@units = "m/s per day"
  accelLow@long_name = "acceleration"
  accelZero@units = "m/s per day"
  accelZero@long_name = "acceleration"

;===================================================================================
;===================================================================================  
;===================================================================================
    STcount  = 0

; loop over storms  
    do i = 0,nStorms-1
      if ( numobs(i) .gt. 0 ) then
        do j = 0, numobs(i)-1
          if ( basin(i,j) .eq. basinAnalysis ) then
            A = dat(i,j)
            if ( time(i,0) .ge. startTime .and. time(i,numobs(i)-1) .le. endTime ) then


              curTime = cd_calendar(time(i,j),-5)
              hour    = curTime(0,3)      

              if ( mod(hour,6) .eq. 0 ) then
                
                numDays = todouble(time(i,numobs(i)-1) - time(i,0))        
                
                if (  numDays .ge. 3 ) then          
                  
                  if ( Lat(i,j) .ge. LatS .and. Lat(i,j) .le. LatN ) then
                    
                    if ( chartostring(nature(i,j,:)) .ne. "ET" .and.  chartostring(nature(i,j,:)) .ne. "NR" ) then
                      if (.not.ismissing(A)  .and. abs(A) .le. xmax) then
                        datA(0,icount) = A
                        datA(1,icount) = time(i,j)
                        datA(2,icount) = i
                        datA(3,icount) = j
                        icount = icount + 1
                      end if ; missing
                      
                    end if ; lat
                  end if ;nat         
                end if ;numdays
                
              end if
            end if ;time
          end if ;basin
        end do ;j
        
      end if ;numobs
    end do ;i
    
    print ( "icount = " + icount )
    ave = avg( datA(0,0:icount-1) )
    std = stddev(datA(0,0:icount-1) )
    med = dim_median( datA(0,0:icount-1) )
    print ("Mean Median and Sdev = " + ave + " " + med + " " +  std)
                                ; lets sort the data:
    datSortedIndex := dim_pqsort( datA(0,0:icount-1),1)
    
    NTHU = tointeger(sfac*icount)
    NTHL = tointeger((1.-sfac)*icount)
    
    
    print ( "icount, NTHU, NTHL =  " + icount + " " + NTHU + " " + NTHL)
                                ; lets get the bottom percentile




; along with separating the cases for the composites, we will also
; check how many of the member storms became ET
    indexJ = new(500,"integer")
    indexI = new(500,"integer")
    indexJ = -9
    indexI = -9
    
    iLow = 0
    do iSort = 0,NTHL
      ii = datSortedIndex(iSort)
      i = tointeger(datA(2,ii))
      j = tointeger(datA(3,ii))
      ;print (iSort + " " +  datA(0,ii) + " " +  dat(i,j)  +  " " + cd_calendar(time(i,j),-3) + " " + cd_calendar(datA(1,ii),-3) )

      ;print ( iSort + " " + i + " " + j + " " +  dat(i,j) )
      accelLow(iLow)   =  dat(i,j)
      LatLow(iLow)     =  Lat(i,j)
      LonLow(iLow)     =  Lon(i,j)
      timeLow(iLow)    = time(i,j)
      indexI(iLow)     = i
      indexJ(iLow)     = j
      iLow = iLow + 1
    end do
  
    indsUnique = get_unique_values( indexI(0:iLow-1)  )
    etCount = 0
    do k=0,dimsizes(indsUnique)-1
      indsk := ind(indexI.eq.indsUnique(k))      
      etFlag = 0
      do itimes = 0,dimsizes(indsk)-1
        ii = indsk(itimes)
        i = indexI(ii)
        j = indexJ(ii)
                                ;print ( k + " " +indsUnique(k) + " " +  dimsizes(indsk) + " " + )
                                ;print ( k + " " + i + " " + j  + " " +  cd_calendar(time(i,j),-3) + " " + time(i,j))
        
; now check if this storm underwent ET
        
        do m = j, numobs(i)-1
          deltaDays =time(i,m)- time(i,j) 
                                ;print (  cd_calendar(time(i,j),-3) + " " +  cd_calendar(time(i,m),-3) + " " + chartostring(nature(i,m,:)) + " " + deltaDays)
          
          if ( deltaDays .le. 3.0 ) then
            if (  chartostring(nature(i,m,:)) .eq. "ET" ) then
              etFlag = 1
            end if
          end if
        end do
      end do

      
      if ( etFlag .eq. 1 ) then
                                ;print ("OK ET" )
        etCount = etCount + 1
      end if
      
    end do
    
    uniqCount = count_unique_values( indexI(0:iLow-1) ) 
    print ( "Unique storms in LOW = " + uniqCount)
    print ( "Number of ET  in LOW = " + etCount )

    percent = tofloat(etCount)*100./tofloat(uniqCount)
    print ( "Percent              = " + percent )

;
;=============================================================================================
;    
    indexJ := new(500,"integer")
    indexI := new(500,"integer")
    indexJ = -9
    indexI = -9    
    iHigh=0
    do iSort = NTHU-1,icount-1
      ii = datSortedIndex(iSort)
      i = tointeger(datA(2,ii))
      j = tointeger(datA(3,ii))
      ;print (iSort + " " +  datA(0,ii) + " " +  dat(i,j)  +  " " + cd_calendar(time(i,j),-3) + " " + cd_calendar(datA(1,ii),-3) )
      accelHigh(iHigh)   =  dat(i,j)
      LatHigh(iHigh)     =  Lat(i,j)
      LonHigh(iHigh)     =  Lon(i,j)
      timeHigh(iHigh)    = time(i,j)
      ;print (iHigh + " " + iSort)
      indexI(iHigh)     = i
      indexJ(iHigh)     = j
      iHigh             = iHigh + 1  
    end do

    indsUnique := get_unique_values( indexI(0:iHigh-1)  )
    etCount = 0
    
    do k=0,dimsizes(indsUnique)-1
      indsk := ind(indexI.eq.indsUnique(k))      
      etFlag = 0
      
      do itimes = 0,dimsizes(indsk)-1
        ii = indsk(itimes)
        i  = indexI(ii)
        j  = indexJ(ii)
                                ;print ( k + " " +indsUnique(k) + " " +  dimsizes(indsk) + " " + )
                                ;print ( k + " " + i + " " + j  + " " +  cd_calendar(time(i,j),-3) + " " + time(i,j))      
; now check if this storm underwent ET
        do m = j, numobs(i)-1
          deltaDays =time(i,m)- time(i,j) 
                                ;print (  cd_calendar(time(i,j),-3) + " " +  cd_calendar(time(i,m),-3) + " " + chartostring(nature(i,m,:)) + " " + deltaDays)
          if ( deltaDays .le. 3.0 ) then
            if (  chartostring(nature(i,m,:)) .eq. "ET" ) then
              etFlag = 1
            end if
          end if
        end do
      end do        
      if ( etFlag .eq. 1 ) then
        ;print ("OK ET "  + etCount + " " + k + " " + itimes )
        etCount = etCount + 1
      end if
      
      
    end do
    
    uniqCount = count_unique_values( indexI(0:iHigh-1) ) 
    print ( "Unique storms in High = " + uniqCount)
    print ( "Number of ET  in High = " + etCount )

    percent = tofloat(etCount)*100./tofloat(uniqCount)
    print ( "Percent              = " + percent )
   
;
;=============================================================================================
;    
    
    iZero = 0
    do iSort = 0,icount-1

      ii = datSortedIndex(iSort)
      i = tointeger(datA(2,ii))
      j = tointeger(datA(3,ii))

      A =   dat(i,j)

      if ( abs(A) .lt. 1.0 ) then
        accelZero(iZero)   =  dat(i,j)
        LatZero(iZero)     =  Lat(i,j)
        LonZero(iZero)     =  Lon(i,j)
        timeZero(iZero)    = time(i,j)
        ;print (iZero+ " " + A + " " +   datA(0,ii))
        iZero=iZero+1
      end if
    end do




    
;  
    accelLow!0 = "LowCount"
    LatLow!0 = "LowCount"
    LonLow!0 = "LowCount"
    timeLow!0 = "LowCount"
;
    accelHigh!0 = "HighCount"
    LatHigh!0 = "HighCount"
    LonHigh!0 = "HighCount"
    timeHigh!0 = "HighCount"
    
       ;
    accelZero!0 = "ZeroCount"
    LatZero!0 = "ZeroCount"
    LonZero!0 = "ZeroCount"
    timeZero!0 = "ZeroCount"
   




    
    system( "rm " + fileName )
                                ; setfileoption("nc", "format", "NETCDF4") 
    outFile = addfile( fileName, "c" )
    outFile->sfac=sfac
    outFile->LatS=LatS
    outFile->LatN=LatN
    
    N=iHigh-1
    accelHigh2 :=accelHigh(0:N)
    LatHigh2 :=LatHigh(0:N)
    LonHigh2 :=LonHigh(0:N)
    timeHigh2 :=timeHigh(0:N)
    
    outFile->accelHigh=accelHigh2
    outFile->LatHigh=LatHigh2
    outFile->LonHigh=LonHigh2
    outFile->timeHigh=timeHigh2
    outFile->HighCount=N
                                ;print ( iStormHigh2 + " " + jStormHigh2 + " " + LatHigh2 + " " + LonHigh2 )
    print ("rapid accel cases:")
    print ( "mean accel = " + avg(accelHigh2) + " " + "median accel = " + dim_median(accelHigh2) )
    print ( "max accel = " + max(accelHigh2) + " " + "min accel = " + min(accelHigh2) )
    
    
    print ( "mean lat = " + avg(LatHigh2) + " " + "median lat = " + dim_median(LatHigh2) )
    print ( "max lat = " + max(LatHigh2) + " " + "min lat = " + min(LatHigh2) )
    
    N=iLow-1
    accelLow2 :=accelLow(0:N)
    LatLow2   :=LatLow(0:N)
    LonLow2   :=LonLow(0:N)
    timeLow2  :=timeLow(0:N)
    
    outFile->accelLow=accelLow2
    outFile->LatLow=LatLow2
    outFile->LonLow=LonLow2
    outFile->timeLow=timeLow2
    outFile->LowCount=N
    


    N=iZero-1
    accelZero2 :=accelZero(0:N)
    LatZero2   :=LatZero(0:N)
    LonZero2   :=LonZero(0:N)
    timeZero2  :=timeZero(0:N)
    
    outFile->accelZero=accelZero2
    outFile->LatZero=LatZero2
    outFile->LonZero=LonZero2
    outFile->timeZero=timeZero2
    outFile->ZeroCount=N


    print (" " )
    print ("zero accel cases:")
    print ( "mean accel = " + avg(accelZero2) + " " + "median accel = " + dim_median(accelZero2) )
    print ( "max accel = " + max(accelZero2) + " " + "min accel = " + min(accelZero2) )
    print ( "mean lat = " + avg(LatZero2) + " " + "median lat = " + dim_median(LatZero2) )
    print ( "mean lat = " + avg(LatZero2) + " " + "median lat = " + dim_median(LatZero2) )
    print ( "max lat = " + max(LatZero2) + " " + "min lat = " + min(LatZero2) )
    
    print ( "iLow , iHigh, iZero = "  + iLow + " " + iHigh + " " + iZero)
    print ( "iLowET , iHighET, iZero = "  + iLowET + " " + iHighET + " " + iZeroET)
    
    

    
    print (" " )
    print ("rapid decel cases:")
    print ( "mean accel = " + avg(accelLow2) + " " + "median accel = " + dim_median(accelLow2) )
    print (  "max accel  = " + max(accelLow2) + " " + "min     accel = " + min(accelLow2) )
    print (  "mean lat = " + avg(LatLow2) + " max lat = " + max(LatLow2) + " " + "min lat = " + min(LatLow2) )
    
    print ( "mean lat = " + avg(LatLow2) + " " + "median lat = " + dim_median(LatLow2) )
    print ( "max lat = " + max(LatLow2) + " " + "min lat = " + min(LatLow2) )
    
    
    
    print ( "iLow , iHigh, iZero = "  + iLow + " " + iHigh + " " + iZero)

  
;===================================================================================
;===================================================================================  
;===================================================================================
  
end


