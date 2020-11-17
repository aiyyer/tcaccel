; a program to:
;
;=====================================================================
; extract the speed and acceleration data to perform QR analysis
; QR analysis done by accompanying python code
;======================================================================
; Nov  9, 2020
; Nov 13, 2020
;
;
; A. Aiyyer
; NCSU Large Scale Dynamics Group
;----------------------------------------------------------------------
;  reads:     tcMotion.nc
;
;  output:    
;
;----------------------------------------------------------------------




begin
  basinAnalysis = "NA" 
  fileName = "../tcMotion.nc"
  startYear = 1966
  endYear   = 2019
  variable = (/"speed","accelSpeed","accelCurve"/)
;=============================================================================    
; some user inputs
  
  ivar = 0
  latS = 0.  ;20.
  latN = 90.  ;40.
  mon1 = 1
  mon2 = 12

  
;=============================================================================  

  var = variable(ivar)  
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
  if ( var .eq. "speed"  .or. var .eq. "speedIB" ) then
    Amax = 30.*3.6
    if ( dat@units .eq. "m/s" ) then
      dat := dat*3.6 ; now km/hr per day
      dat@units = "km/hr"
      dat@name  = "Speed"
      
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
      dat@name  = "Acceleration"
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
  
;===================================================================== 
; first establish some basic stats for this lat-bin
; create array to store all accel data for some more stats
  Data        := new (40000,typeof(dat))
  Data@_FillValue = dat@_FillValue
  copy_VarAtts(dat,Data)
  Dates       := new (40000,typeof(time))
  Dates@units = time@units 
  Data = Data@_FillValue 
  
  icount    = 0
  nrCount   = 0
  totCount  = 0
  tsCount   = 0
  etCount   = 0
  
  
; loop over storms  
    do i = 0,nStorms-1
      if ( numobs(i) .gt. 0 ) then
        if ( time(i,0) .ge. startTime .and. time(i,numobs(i)-1) .le. endTime ) then
          numDays = todouble(time(i,numobs(i)-1) - time(i,0))        
          
;   storm must live at least 1 days
          if (  numDays .ge. 3 ) then          
           
            do j = 0, numobs(i)-1
              date=cd_calendar(time(i,j),-5)
              month = date(0,1)
              if (month .ge. mon1 .and. month .le. mon2 ) then
                
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
                      
                      if (.not.ismissing(A)) 
                        tsCount         = tsCount + 1
                         Data(icount)   = A
                        Dates(icount)   = time(i,j)
                        icount = icount + 1
                      end if ;Amax
                                            
                    end if ; nature
;-------------------------------------------------------------------------
                    
                  end if ; lat                  
                end if  ;basin
           
              end if ;month
          end do
        end if ;numdays
      end if ;time
      
    end if ;numobs 
  end do ;i

  
;=======================================================================================

  print ( "Track points that met threhsolds = " + icount)
  print ( "Min Max " + min(Data(0:icount-1)) + " " + max (Data(0:icount-1)) )
  ave =    avg(Data(0:icount-1) )
  std = stddev(Data(0:icount-1) )
  med = dim_median( Data(0:icount-1) )
  print ( "Lat range " + latS + " " + latN + " Mean Median Sdev = " + ave + " " + med + " " +  std)
  NRper = tofloat(nrCount*100)/tofloat(totCount)
  TSper = tofloat(tsCount*100)/tofloat(totCount)
  ETper = tofloat(etCount*100)/tofloat(totCount)
  
  print ( "tot count=" + totCount + " NR count="+nrCount + " NR per="+ NRper)
  print ( "tot count=" + totCount + " TS count="+tsCount + " ts per="+ TSper)
  print ( "tot count=" + totCount + " ET count="+etCount + " ET per="+ ETper)
  sumP = TSper+NRper+ETper
  print ( "Sum should be 100 " +sumP ) 
;=======================================================================================
 
  Fracyear = yyyymmddhh_to_yyyyfrac(cd_calendar(Dates(0:icount-1),-3),0)

                                ; write out the yearly data
  system ( "rm dat.nc")
  ncdf = addfile("dat.nc" ,"c")  ; open output netCDF file
  ncdf->startYear=startYear
  ncdf->endYear=endYear
  ncdf->latS=latS
  ncdf->latN=latN
  ncdf->Dates=Dates(0:icount-1) 
  ncdf->Data=Data(0:icount-1) 
  ncdf->Fracyear=Fracyear

;=======================================================================================
  yearly := new(nYears,typeof(Data) )
  ycount := yearly
  ycount = 0.0
  yearly = 0.0
  
  do i = 0,icount-1
    dateDecode = cd_calendar(Dates(i),-5)
    iy = dateDecode(0,0) - startYear


    
    a =  ycount(iy)
    b = a+1.
    yearly(iy)   = yearly(iy)*a/b + Data(i)/b    
    ycount(iy)   = ycount(iy) + 1.
    
  end do
  years   := fspan(0,nYears-1,nYears) + startYear

  
  print ( "Mean of yearly mean data  = " + avg(Data) )
  print ( "Median        = " + dim_median(Data))
  ; calculate the regression coefficient (slope)     
  rc    = regline(years,yearly)          ; slope           
  rc@units = " "             
  sigr = 0.05                        ; critical sig lvl for r
  df = equiv_sample_size (yearly, sigr,0)
  prob = betainc(df/(df+rc@tval^2), df/2.0, 0.5)  
  print("rc trend and prob = " + rc + " " + prob + " df = " + df)
  
  print ( "================================================")
  
  ncdf->years=years
  ncdf->yearly=yearly

;=======================================================================================
  print ("Output data")
  print ( "Mean of all data  = " + avg(Data) )
  print ( "Median        = " + dim_median(Data))
  ; calculate the regression coefficient (slope)     
  rc    = regline(Dates(0:icount-1) ,Data(0:icount-1) )          ; slope           
  rc@units = " "             
  sigr = 0.05                        ; critical sig lvl for r
  df = equiv_sample_size (Data(0:icount-1) , sigr,0)
  prob = betainc(df/(df+rc@tval^2), df/2.0, 0.5)  
  rc=rc*365.
  print("rc trend and prob = " + rc + " " + prob + " df = " + df)
  
  
  
end

