; a program to:
;
;=====================================================================
; Calculate the trend in TC acceleration/speed in latitude bands
; user specifies the width of the band and overlap
;
; This versoin sorts the trends and uses percentiles to define
; extreme values of acceleration
;
;
; NCSU Tropical Dynamics Group
; A. Aiyyer
;
;======================================================================
; Last Update Sep 21, 2020
;             -Some more testing to confirm results of trends
;
;             Sep 30, 2020
;             - added qsort
;----------------------------------------------------------------------

begin

  basinAnalysis = "NA" ;"WP" ;"NA"
  fileName = "../tcMotion.nc"
  startYear = 1966
  endYear   = 2019
  variable = (/"speed","accelSpeed","accelCurve"/)
  
  ivar       =  1 ;1
  threshFlag =  1 ;1

  ; sfac denotes the percentile to use a threshold
  sfac       =  .80

  var = variable(ivar)
    
; choose the latitude band
  
  latS =   5. ; 5.0
  dlat =  20.  ;10. ;10.0
  latN = latS + dlat    
  nn   = 6

; entire basin 
;  latS = -90. ; 5.0
;  dlat =  180.  ;10. ;10.0
;  latN = latS + dlat    
;  nn = 1


  latS = 20. ; 5.0
  dlat = 20.  ;10. ;10.0
  latN = latS + dlat    
  nn = 1


  latS = -90. ; 5.0
  dlat =  180.  ;10. ;10.0
  latN = latS + dlat    
  nn = 1

  
  nYears    = endYear - startYear + 1
  print ( "Start Year = " + startYear + " end year = " + endYear + " " + nYears)
  
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
  endTime   = cd_inv_calendar(endYear,12,31,24,0,0,time@units, 0)
;
  
  dat := fileIn->$var$
  dat@name = var
  ;printVarSummary(dat)

  if ( var .eq. "speed"  .or. var .eq. "speedIB" ) then
    Amax = 30.*3.6
    if ( dat@units .eq. "m/s" ) then
      dat := dat*3.6 ; now km/hr per day
      dat@units = "km/hr" 
    else
      print ("Units unexpected! Terminating code!")
      exit
    end if
  end if  
  if ( var .eq. "accelSpeed" .or. var .eq.  "accelCurve" ) then
    Amax = 120.*3.6
    if ( dat@units .eq. "m/s per day" ) then
      dat := dat*3.6 ; now km/hr per day
      dat@units = "km/hr per day" 
    else
      print ("Units unexpected! Terminating code!")
      exit
    end if
  end if
  
  basin = fileIn->basin
  
  time  = fileIn->time
  Lat   = fileIn->lat
  Lon   = fileIn->lon
  numobs      = fileIn->numobs
  nature      = fileIn->nature
  dims        = dimsizes(time)
  nStorms     = dims(0)
  datYaLL := new( (/nn,nYears/),"double")
  datYaLL@_FillValue = dat@_FillValue
  
;===================================================================== 
  clat     = new(nn,"double")
  clat     = dat@_FillValue
  trend    = clat
  signi    = clat
  trendL   = clat
  signiL   = clat
  latCount = new(nn,"integer")
  latAve   = clat
  latMed   = clat
  latSD    = clat
  latSouth = clat
  latNorth = clat
  latSouth = clat
  latNorth = clat
;===================================================================== 
 
 
 
 
 do imain = 0,nn-1
   
   print ("---------------------------------------------")
;======================================================================================
; first establish some basic stats for this lat-bin
; create array to store all accel data for some more stats
   datA     := new (700000,"double")
   datA@_FillValue = dat@_FillValue
   
   icount    = 0
   nrCount   = 0
   totCount  = 0
   tsCount   = 0
   etCount   = 0

   datA = datA@_FillValue

   latSouth(imain) = latS
   latNorth(imain) = latN
   yearly := new((/nYears,20000/),"double")
   ycount := new((/nYears/),"integer")
   yearly@_FillValue = dat@_FillValue
   ycount = 0
   yearly = yearly@_FillValue    
   ic     = 0
   count  = 0.
   stormCount = 0
   
; loop over storms  
    do i = 0,nStorms-1
      
      if ( numobs(i) .gt. 0 ) then
        if ( time(i,0) .ge. startTime .and. time(i,numobs(i)-1) .le. endTime ) then
          numDays = todouble(time(i,numobs(i)-1) - time(i,0))        
          
;   storm must live at least 1 days
          if (  numDays .ge. 3 ) then          
            stormCount = stormCount + 1
            ;print ( i + " " + stormCount + " " +  numobs(i) + " " +  cd_calendar(time(i,0),-3) + " " +  cd_calendar(time(i,numobs(i)-1),-3) )
            
            do j = 0, numobs(i)-1
              
             if ( basin(i,j) .eq. basinAnalysis ) then
                A = dat(i,j)              
; apply the relevant checks
                
                if ( Lat(i,j) .ge. latS .and. Lat(i,j) .le. latN ) then  
                  totCount = totCount+1

                  if ( chartostring(nature(i,j,:)) .eq. "NR" .or. chartostring(nature(i,j,:)) .eq. "MX") then
                    nrCount = nrCount + 1
                  end if

                  
                  if ( chartostring(nature(i,j,:)) .eq. "ET" ) then
                    etCount = etCount + 1
                  end if
                  
;-------------------------------------------------------------------------                
                  if ( chartostring(nature(i,j,:)) .ne. "ET" .and.  chartostring(nature(i,j,:)) .ne. "NR" ) then
                    
                    if (.not.ismissing(A)) ;;; .and. abs(A) .le. Amax ) then
                      ;print ( i + " " + j + icount + " " + A(icount) )
                      tsCount        = tsCount + 1
                      datA(icount)   = A
                      icount = icount + 1
                      date=cd_calendar(time(i,j),-5)
                      iy = date(0,0)-startYear                   
                      ii = ycount(iy)
                      yearly(iy,ii) = A
                      ycount(iy) =  ycount(iy) + 1
                    else
                      date=cd_calendar(time(i,j),-5)
                      print ( i + " " + j + " " +  A + " " + date(0,0))
                      
                  end if ;Amax
                  
                  
                end if ; nature
;-------------------------------------------------------------------------
                
              end if ; lat
              
            end if  ;basin
            
            
          end do ; j
        end if ;numdays
      end if ;time
      
    end if ;numobs 
  end do ;i
  

    print ( "icount = " + icount)
    ave =    avg(datA(0:icount-1) )
    std = stddev(datA(0:icount-1) )
    med = dim_median( datA(0:icount-1) )

    print ("pre sorting")
    print ( "Lat range " + latS + " " + latN + " Mean Median Sdev = " + ave + " " + med + " " +  std)
    
    NRper = tofloat(nrCount*100)/tofloat(totCount)
    TSper = tofloat(tsCount*100)/tofloat(totCount)
    ETper = tofloat(etCount*100)/tofloat(totCount)
    
    print ( "tot count=" + totCount + " NR count="+nrCount + " NR per="+ NRper)
    print ( "tot count=" + totCount + " TS count="+tsCount + " ts per="+ TSper)
    print ( "tot count=" + totCount + " ET count="+etCount + " ET per="+ ETper)
    sumP = TSper+NRper+ETper
    print ( "Sum should be 100 " +sumP ) 
    latAve(imain)   = ave
    latMed(imain)   = med
    latSD(imain)    = std
    latCount(imain) = icount
;
;=======================================================================================
;
    yearlyThresh = yearly


    if ( threshFlag .ne. 0 ) then
      yearlyThresh =  yearlyThresh@_FillValue
    end if    
    if ( threshFlag .eq. 1 ) then
      print ("post sorting")

; lets sort the data:
      datSorted := datA(0:icount-1)
      qsort(datSorted)
      print ( "Lat range " + latS + " " + latN + " Mean = " + avg(datSorted) )
      npts = tofloat(dimsizes(datSorted))
      nF  = tointeger(sfac*npts)
      thresh =  datSorted(nF)
      print ("sfac = " + sfac + " " +  npts + " " + nF + " thresh =  "+ thresh)
      yearlyThresh =  yearlyThresh@_FillValue
      yearlyThresh = where ( yearly .gt. thresh, yearly, yearly@_FillValue)
    end if

    
    if ( threshFlag .eq. -1 ) then      
; lets sort the data:
      datSorted := datA(0:icount-1)
      qsort(datSorted)
      datSorted  := datSorted(::-1)
      print ( datSorted(0) + " " +  datSorted(icount-1) )
      print ( "Lat range " + latS + " " + latN + " Mean = " + avg(datSorted) )
      npts = tofloat(dimsizes(datSorted))
      
      nF  = tointeger(sfac*npts)
      thresh =  datSorted(nF)
      print ( npts + " " + nF + " percentile = " + sfac + " thresh =  "+ thresh)
      yearlyThresh = where ( yearly .lt. thresh, yearly, yearly@_FillValue)
    end if
    
    print ( "icount = " + icount + " " + sum(ycount) + " " + sum(yearlyThresh) )
    


    

    
    datY := new(nYears,"double") 
 
    datY@_FillValue = yearlyThresh@_FillValue
    datC = datY

    
    x    := fspan(0,nYears-1,nYears) + startYear

    do iy=0,nYears-1
      
      N = num(.not.ismissing(yearlyThresh(iy,:)))
      ;print ( iy + " " + N )
      
      med     =   yearlyThresh@_FillValue
      datY(iy) =  yearlyThresh@_FillValue
      icc =  ycount(iy)
      if ( icc .gt. 0 ) then
        med     =    dim_median(yearlyThresh(iy,:))
        ave     =    avg(yearlyThresh(iy,:))
        datY(iy) =   ave
      else
        med     =   yearlyThresh@_FillValue
        datY(iy) =  yearlyThresh@_FillValue
      end if
      ;print ( x(iy) + " " +   datY(iy) + " " + N )
    end do
 

    ;print ( "sum = " + sum( datY ) )
    print ( "mean = " + avg(datY)  + " " + dim_avg_n_Wrap (dim_avg_n_Wrap(yearlyThresh,1),0) )

;=================================================================================    
    opt  = False
    pt   = trend_manken(datY, opt, 0) 
    pt(0) = 1.-pt(0)

    if(any(ismissing(datY))) then
      print("Your data contains some missing values. Beware.")
    end if
    print ("MK trend and prob dat = " + pt(1) + " " + pt(0) )    


    clat(imain)  = .5*(latS + latN)
    trend(imain) = pt(1)
    signi(imain) = pt(0)

    latSouth(imain) = latS
    latNorth(imain) = latN
    
; calculate the regression coefficient (slope)    
    y = datY
    rc    = regline(x, y)          ; slope           
    rc@units = " "           

;    df   = rc@nptxy-2

    sigr = 0.05                        ; critical sig lvl for r
    df = equiv_sample_size (datY, sigr,0)

    prob = betainc(df/(df+rc@tval^2), df/2.0, 0.5)

    
    print("rc trend and prob = " + rc + " " + prob + " df = " + df)
    trendL(imain) = rc
    signiL(imain) = prob

;-------------------------------------------------------------------------------------------


    datYaLL(imain,:) = datY

    
    latS = latS + 5.0 ;dlat*.5
    latN = latN + 5.0 ;dlat*.5

    
  end do

  print (" " )
  print (" " )

  do i = 0,nn-1
    
    outString := ( sprinti("%2i",tointeger(latSouth(i)) )  + "--" + sprinti("%2i",tointeger(latNorth(i))) + " & " + sprinti("%5i",latCount(i)) + " &  " + sprintf("%5.2f",latAve(i)) + " & " +  sprintf("%5.2f",latMed(i)) + " & " +  sprintf("%5.1f",latSD(i))  + "\\")
    print  ( " " + outString ) 
  end do
  
  
  print (" " )
  print (" " )


  
  do i = 0,nn-1


    outString := ( sprinti("%2i",tointeger(latSouth(i)) )  + "--" + sprinti("%2i",tointeger(latNorth(i)))  + " & " +  sprintf("%6.3f",trendL(i)) + " & " +  sprintf("%4.2f",signiL(i))  + " & " +  sprintf("%6.3f",trend(i)) + " & " +  sprintf("%4.2f",signi(i)) + "\\")


    
    print  ( " " + outString ) 

  end do

  datYaLL@name = var
  
                                ; write out the yearly data
  system ( "rm dat.nc")
  ncdf = addfile("dat.nc" ,"c")  ; open output netCDF file
  ncdf->startYear=startYear
  ncdf->endYear=endYear
  ncdf->ave=datYaLL
  ncdf->latSouth=latSouth
  ncdf->latNorth=latNorth

  if ( threshFlag .eq. 1 ) then
    ncdf->threshFlag=threshFlag
    ncdf->sfac=sfac
  end if
end

