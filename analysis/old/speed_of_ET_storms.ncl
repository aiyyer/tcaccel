; a program to:
;             calculate some basic stats related to speed/accel of storms 
;             classified as ET
;----------------------------------------------------------------------------
; NCSU Tropical Dynamics Group
; A. Aiyyer
; Dec 5, 2019
; Aug 9. 2020 
;----------------------------------------------------------------------------

begin
  
; user inputs
  startYear = 1980
  endYear   = 2019
  nYears    = endYear - startYear + 1
  basinAnalysis = "NA"

  print ( "Start Year = " + startYear + " end year = " + endYear)

; choose the latitude band
  latS = 0. 
  latN = 90.


;--------------------------------------------------------------------------      
  fileName = "../tcSpeed.nc"
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
  
  accelS   = fileIn->accelSpeed
  accelC   = fileIn->accelCurve
  speed    = fileIn->speed  
  time     = fileIn->time
  Lat      = fileIn->lat
  Lon      = fileIn->lon
  numobs   = fileIn->numobs
  nature   = fileIn->nature
  ;basin       = fileIn->basin
  dims     = dimsizes(time)
  nStorms  = dims(0)
;  
  if ( speed@units .eq. "m/s" ) then
    speed = speed*3.6 ; now km/hr per day
    speed@units = "km/hr per day" 
  else
    print ("Units unexpected! Terminating code!")
    exit
  end if
  if ( accelC@units .eq. "m/s per day" ) then
    accelC = accelC*3.6 ; now km/hr per day
    accelC@units = "km/hr per day" 
  else
    print ("Units unexpected! Terminating code!")
    exit
  end if
  if ( accelS@units .eq. "m/s per day" ) then
    accelS = accelS*3.6 ; now km/hr per day
    accelS@units = "km/hr per day" 
  else
    print ("Units unexpected! Terminating code!")
    exit
  end if
;

  nn=3500
  accelET:= new( (/2,nn/),typeof(accelS) )
  accelET = accelS@_FillValue
  speedET = new( (/nn/),typeof(accelS) )
  speedET=speedET@_FillValue
;======================================================================================
; first establish some basic stats for this lat-bin
; create array to store all accel data for some more stats
  icount    = 0
  ETCount = 0
;
  iSormCount = 0
; loop over storms  
  do i = 0,nStorms-1

    if ( numobs(i) .ne. 0 ) then
      numDays = todouble(time(i,numobs(i)-1) - time(i,0))
      
;   storm must live at least 2 days
      if (  numDays .ge. 2 ) then
        
        
         
          if ( time(i,0) .ge. startTime .and. time(i,0) .le. endTime ) then
            iSormCount = iSormCount+1
            do j = 1, numobs(i)-2
              
; apply the relevant checks
              ;if ( chartostring(basin(i,j,:)) .eq. basinAnalysis) then
                if ( Lat(i,j) .ge. latS .and. Lat(i,j) .le. latN ) then  
                  if ( chartostring(nature(i,j,:)) .eq. "ET" ) then
                    accelET(0,ETCount) = accelS(i,j)
                    accelET(1,ETCount) = accelC(i,j)
                    speedET(ETCount)   = speed(i,j)
                    ;print ( ETCount + " " + accelET(0,ETCount) + " "  + speedET(ETCount)  )
                    ETCount=ETCount+1
                  end if
                end if
              ;end if
            end do
          end if
        end if ;numdays
      end if
    end do ;i

    print ("Total Storms = " + iSormCount)
    print ( "count  = " + ETCount)
    medianS = dim_median_n(speedET(0:ETCount-1),0 )
    meanS   = avg(speedET(0:ETCount-1))

    print ( "median, mean S  = " + meanS + " " + medianS )


    medianSA = dim_median_n(accelET(0,0:ETCount-1),0 )
    meanSA   = avg(accelET(0,0:ETCount-1))

    print ( "median, mean SA  = " + meanSA + " " + medianSA )


    medianCA = dim_median_n(accelET(1,0:ETCount-1),0 )
    meanCA   = avg(accelET(1,0:ETCount-1))

    print ( "median, mean CA  = " + meanCA + " " + medianCA )

    
  end