;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
; a program to:
;
; read the IBTraCS database and calculate the TC forward speed
; and accelerations (speed and curvature)
;
;
; Aiyyer 
; NCSU Tropical Dynamics Group
;
; Aug 28, 2019
; 
; 
;............................................................................
; Updates
;
; Nov 25, 2019  : In this version we will only deal with 3 hourly reports.
; 
; Dec  1, 2019  : Modified curvature accel calculation to use Mercator Proj.
; July 5, 2020  : Updated to use Terrell's method instead of mercator
; Sep 19, 2020  : Updated to do all basins and all available tracks (> 3 days)
;----------------------------------------------------------------------------
; Output: All arrays in the same format as the ibtracs data arrays
;         (a) TC forward speed (S) in m/s
;         (b) TC speed acceleration (DS/Dt) in m/s per day
;         (c) TC curvature acceleration in  (S^2/R) in m/s per day
;         (d) other parameters from ibtracs
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------

begin
  

; Basic params
;
;   
; the ibtracs file
  iyBeg = 1949
  fileName = "Allstorms.ibtracs_wmo.v03r10.nc"
  fileIn = addfile( fileName, "r" )
  
  
  print ( "reading IBTrACS data from : "  + fileName)
;-----------------------------------------------------------------------------  
  time        = fileIn->time_wmo
 
; we expect time units to be in days
  unitsExpected  = "days since 1858-11-17 00:00:00"
  if (time@units .ne. unitsExpected ) then
    print ("Read from file: " + time@units)
    print ("Expected      : " + unitsExpected)
    print ("Error in timeunits. Unexpected units. Terminating code!!!")
    exit
  end if


  lat         = todouble(fileIn->lat_wmo)
  lon         = todouble(fileIn->lon_wmo)  
  numobs      = toint(short2flt(fileIn->numObs))
  basin       = toint(fileIn->basin)
  nature      = fileIn->nature_wmo
 
  lat = lat*.01
  lon = lon*.01

  
;
;------------------------------------------------------------------
;    


; create array to store speed calculated by us
; simply copy the ibtracs speed array
  speedC = (/lat/)
  speedC = speedC@_FillValue
  speedC@units = "m/s" 
  
;  
; define arrays for acceleration
  accelSpeed  = speedC  
  accelCurve  = speedC
  dims = dimsizes(numobs)
  nStorms = dims
  
  print ("number of storms = " + nStorms)
  
;
; create a variable to store delta time  
; copying from time sets the attributes
  deltaTime = time(0,0) 
  numDays   = time(0,0)


;============================================================================================
; Loop over all storms  
  do i = 0,nStorms-1
    
;......................................................................    
; first extract only synoptic hours 0,3,6...21    
    ntimes     = numobs(i)    
    ntimes_old = ntimes    

; create new temporary arrays for dates,lat,lon
    stormTime     :=   (/ time(i,0:ntimes-1)/)
    stormTime@units = time@units
    stormLat      :=    (/ lat(i,0:ntimes-1)/)
    stormLon      :=    (/ lon(i,0:ntimes-1)/)
    stormnature   :=    (/nature(i,0:ntimes-1)/)
    stormBasin    :=    (/ basin(i,0:ntimes-1)/)
    stormSpeed    :=    (/stormLat/)

    stormLat      =   stormLat@_FillValue
    stormLon      =   stormLat@_FillValue

    stormSpeed    =   stormSpeed@_FillValue
        
; loop over all times for this storm and extract only hours 0,3,..,21
    is = 0   

    do j = 0,ntimes-1      
      curTime = cd_calendar(time(i,j),-5)
      hour    = curTime(0,3)

; only consider the three hourly reports
      if ( mod(hour,6) .eq. 0 ) then

        ;print ( j + " " + hour + " " +  cd_calendar(time(i,j),-3) )
        stormTime(is)     = (/time(i,j)/)        
        stormLat(is)      = (/lat(i,j)/)
        stormLon(is)      = (/lon(i,j)/)
        stormnature(is) = (/nature(i,j)/)
        stormBasin(is)    = (/basin(i,j)/)
        is = is + 1
      end if
    end do
    
; reset the ntimes to reflect only the 3 hourly reports
    ntimes   = is
    if ( ntimes .gt. 2 ) then
      numDays = todouble(stormTime(ntimes-1) - stormTime(0))
    else
      numDays = 0.
    end if
    
;............................................................
    if ( numDays .ge. 1. ) then ; storm must live at least 1 days
      

; loop over each track point      
      do j = 0,ntimes-2
        deltaTime = stormTime(j+1)-stormTime(j)   ; in units of days      
        LatP = stormLat(j+1)
        Lat0 = stormLat(j)
        LonP = stormLon(j+1)
        Lon0 = stormLon(j)    
        distance =  gc_latlon(LatP,LonP,Lat0,Lon0,2,3)
        stormSpeed(j) = distance/todouble(deltaTime*24.*3600.)
      end do ;j

      
      j = ntimes-1
      deltaTime = stormTime(j)-stormTime(j-1)   ; in units of days
      LatM = stormLat(j-1)
      Lat0 = stormLat(j)
;      
      LonM = stormLon(j-1)
      Lon0 = stormLon(j)
      distance =  gc_latlon(LatM,LonM,Lat0,Lon0,2,3)
      stormSpeed(j) = distance/todouble(deltaTime*24.*3600.)
;
;----------------------------------------------------------------------------------------
;     
; For this storm Update all arrays
;
      numobs(i)               = ntimes     ; this is the new numobs for this storm
      time(i,:)               = time@_FillValue      
      time(i,0:ntimes-1)      =   (/stormTime(0:ntimes-1)/)
      nature(i,0:ntimes-1)    =  (/stormnature(0:ntimes-1)/)
      lat(i,:)  = lat@_FillValue
      lon(i,:)  = lon@_FillValue
      lat(i,0:ntimes-1) = stormLat(0:ntimes-1)
      lon(i,0:ntimes-1) = stormLon(0:ntimes-1)      
      speedC(i,0:ntimes-1)  =  (/stormSpeed(0:ntimes-1)/)
      basin(i,0:ntimes-1)  =   (/stormBasin(0:ntimes-1)/)

      print ( i + " " + speedC(i,0) + " " + speedC(i,ntimes-1) )
       
; at this time, we have the speeds
;      print ( cd_calendar(time(i,0:ntimes-1),-3) + " " + speedC(i,0:ntimes-1))
;---------------------------------------------------------------------------------------


   else

     numobs(i) = 0
     time(i,:) = time@_FillValue
     lat(i,:)  = lat@_FillValue
     lon(i,:)  = lon@_FillValue
     speedC(i,:) = speedC@_FillValue
     
   end if


   
end do ; loop over storms

;===========================================================================================  



fileName = "tcMotion.nc"
system( "rm " + fileName )
setfileoption("nc", "format", "NETCDF4") 
outFile = addfile( fileName, "c" )
outFile->numobs=numobs
outFile->nature=nature
outFile->basin=basin
outFile->lat=lat
outFile->lon=lon
outFile->speed=speedC
outFile->time=time

;===========================================================================================  
print ( "*************************************************" )
print ( "*****   Normal Code Termination  ****************" )
print ( "*************************************************" )



;===========================================================================================

end


