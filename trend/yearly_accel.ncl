; a program to:
;
;=====================================================================
; extract the acceleration data and create a file with yearly
; values
;======================================================================
; Nov 9, 2020
;----------------------------------------------------------------------

begin

  basinAnalysis = "NA" 
  fileName = "../tcMotion.nc"
  startYear = 1966
  endYear   = 2019
  variable = (/"speed","accelSpeed","accelCurve"/)


;=============================================================================    
  ivar       =   1 
  latS = 20.
  latN = 40.
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
  
;===================================================================== 
; first establish some basic stats for this lat-bin
; create array to store all accel data for some more stats
  datA     := new (25000,"double")
  datA@_FillValue = dat@_FillValue
  
  icount    = 0
  nrCount   = 0
  totCount  = 0
  tsCount   = 0
  etCount   = 0
  
  datA   = datA@_FillValue
  dateA  = datA


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
                      dateA(icount)  = time(i,j)
                      icount = icount + 1
                      date=cd_calendar(time(i,j),-5)
                      iy = date(0,0)-startYear                   
                      ii = ycount(iy)
                      yearly(iy,ii) = A
                      ycount(iy) =  ycount(iy) + 1
                    else
                      ;date=cd_calendar(time(i,j),-5)
                      ;print ( i + " " + j + " " +  A + " " + date(0,0))
                      
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
    
  x    := fspan(0,nYears-1,nYears) + startYear  
  yearly!0 = "year"
  yearly!1 = "acceleration"
  yearly&year =x     
  print ( x + " " + ycount )
  printVarSummary(yearly)
  
  ycount!0    = "year"
  ycount&year = x



  N = sum(ycount)
  print ("N = " + N)
  
  accel = new(N,"float")
  years = new(N,"float")
 

  
 i=0
 do iy =0,nYears-1
   do j=0,ycount(iy)-1
     accel(i) = tofloat(yearly(iy,j))
     years(i) = x(iy)
     i = i + 1
   end do
 end do

  
  print (" " )
  print (" " )
  

                                ; write out the yearly data
  system ( "rm dat.nc")
  ncdf = addfile("dat.nc" ,"c")  ; open output netCDF file
  ncdf->startYear=startYear
  ncdf->endYear=endYear
  ncdf->latS=latS
  ncdf->latN=latN


  
 ; ncdf->years=years
 ; ncdf->accel=accel

  
  ncdf->accel=(/datA(0:icount-1)/)
  ncdf->years=(/dateA(0:icount-1)/)

  print (dateA(0:icount-1)  + " " + datA(0:icount-1))
end

