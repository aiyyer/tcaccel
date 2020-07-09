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
;
;----------------------------------------------------------------------------
; Output: All arrays in the same format as the ibtracs data arrays
;         (a) TC forward speed (S) in m/s
;         (b) TC speed acceleration (DS/Dt) in m/s per day
;         (c) TC curvature acceleration in  (S^2/R) in m/s per day
;         (d) other parameters from ibtracs
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
;
;
;
;

load "rad_curv.ncl"

begin
  
  masterCount = todouble(0.)
  masterBias  = todouble(0.)
  masterRMS   = todouble(0.)

; Basic params
  Rearth = todouble(6.356e6)  ;in m (Must be in m)
  pi     = 4.*atan(todouble(1.))
;
;   
; the ibtracs file  
  fileName = "IBTrACS.ALL.v04r00.nc"
  fileIn = addfile( fileName, "r" )

;-----------------------------------------------------------------------------  
; read time stamp for the first record for each TC from ibtracs
  time        = fileIn->time(:,0)
  basin       = chartostring(fileIn->basin)
  printVarSummary(basin)
    
; we expect time units to be in days
  unitsExpected  = "days since 1858-11-17 00:00:00"
  if (time@units .ne. unitsExpected ) then
    print ("Read from file: " + time@units)
    print ("Expected      : " + unitsExpected)
    print ("Error in timeunits. Unexpected units. Terminating code!!!")
    exit
  end if
;
; Locate the record for 1950 onwards
  dateBeg = dble2flt(cd_inv_calendar(1980,1,1,0,0,0,time@units, 0))
  indices   :=  ind(basin(:,0) .eq. "NA" .and. time .ge. dateBeg )

  
; base is now the storm number for the first storm in 1950
  delete(time)
  delete(basin)
;
;----------------------------------------------------------------------------
; Now read all the track data  [faster to read all data first]

  time        = fileIn->time 
  lat         = flt2dble(fileIn->lat)
  lon         = flt2dble(fileIn->lon )  
  numobs      = toint(short2flt(fileIn->numobs))
  basin       = chartostring(fileIn->basin)
  nature      = fileIn->nature
  sid         = chartostring(fileIn->sid)


; read the speed from IBTracs

  speed       = short2flt(fileIn->storm_speed)
  name        =  chartostring(fileIn->name)
  print (cd_calendar(time(indices,0),-3) + " " + name(indices) + " " + sid(indices) + " " + indices )
 

;-----------------------------------------------------------------------------  
; Now subset only the ones that we need   
  time        :=     time(indices,:)
  lat         :=      lat(indices,:)
  lon         :=     lon (indices,:)  
  numobs      :=   numobs(indices)
  basin       :=    basin(indices,:)
  nature      :=   nature(indices,:,:)
; read the speed from IBTracs
  speed       :=    speed(indices,:)
  name        :=     name(indices)
  sid        :=     sid(indices)


;
;------------------------------------------------------------------
;    
; convert speed to m/s
  if ( speed@units .eq. "kts" ) then
    speed = speed*0.514   
    speed@units = "m/s"
  else
    print ("Error! Unknown translation speed units")
    print (speed@units)
    print ("Terminating code!!!! Please check")
  end if


; create array to store speed calculated by us
; simply copy the ibtracs speed array
  speedC = flt2dble(speed)
  speedC = speedC@_FillValue  
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

  origJ = tointeger(lat)
  origJ = origJ@_FillValue
  
;============================================================================================
; Loop over all storms  
  do i = 0, nStorms-1

;......................................................................    
; first extract only 3 hourly reports at synoptic hours 0,3,6...21    
    ntimes     = numobs(i)
    ntimes_old = ntimes    
; create new temporary arrays for dates,lat,lon
    stormTime   :=   time(i,0:ntimes-1)
    stormLat    :=    lat(i,0:ntimes-1)
    stormLon     :=    lon(i,0:ntimes-1)
    stormSpeedIB  := speed(i,0:ntimes-1)
    stormnature := nature(i,0:ntimes-1,:)
    stormj      :=  origJ(i,0:ntimes-1)
    stormSpeed  := todouble(stormSpeedIB)
    stormLat   =   stormLat@_FillValue
    stormSpeed = stormSpeed@_FillValue
    
; loop over all times for this storm and extract only hours 0,3,..,21
    is = 0   
    do j = 0,ntimes-1      
      curTime = cd_calendar(time(i,j),-5)
      hour    = curTime(0,3)      
; only consider the three hourly reports
      if ( mod(hour,3) .eq. 0 ) then
        stormTime(is)     = (/time(i,j)/)
        stormLat(is)      = (/lat(i,j)/)
        stormLon(is)      = (/lon(i,j)/)
        stormnature(is,:) = (/nature(i,j,:)/)
        stormSpeedIB(is)  = (/speed(i,j)/)
        stormj(is) = j
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
    if ( numDays .ge. 2. ) then ; storm must live at least 2 days

      print (cd_calendar(time(i,0),-3) + " " + name(i) )
; loop over each track point      
      do j = 1,ntimes-2
        curTime = cd_calendar(stormTime(j),-5)
        hour = curTime(0,3)
        deltaTime = stormTime(j+1)-stormTime(j-1)   ; in units of days
        deltaTime = deltaTime*24.*3600.             ; in units of seconds

        LatP = stormLat(j+1)
        Lat0 = stormLat(j)
        LatM = stormLat(j-1)
        LonP = stormLon(j+1)
        Lon0 = stormLon(j)
        LonM = stormLon(j-1)
;        
; calculate the total distance traveled as sum of individual legs of the
; centered difference ->this is a better estimate when the track is
; curved
;        
        distance =  gc_latlon(LatP,LonP,Lat0,Lon0,2,3) + gc_latlon(LatM,LonM,Lat0,Lon0,2,3)
        stormSpeed(j) = distance/todouble(deltaTime)
      end do ;j
;
; calculate speed at end points      
      j = 0 
      deltaTime = stormTime(j+1)-stormTime(j)   ; in units of days
      deltaTime = deltaTime*24.*3600.   
      LatP = stormLat(j+1)
      Lat0 = stormLat(j)
;      
      LonP = stormLon(j+1)
      Lon0 = stormLon(j)
      distance =  gc_latlon(LatP,LonP,Lat0,Lon0,2,3)
      stormSpeed(j) = distance/todouble(deltaTime)
;  
      j = ntimes-1
      deltaTime = stormTime(j)-stormTime(j-1)   ; in units of days
      deltaTime = deltaTime*24.*3600.   
      LatM = stormLat(j-1)
      Lat0 = stormLat(j)
;      
      LonM = stormLon(j-1)
      Lon0 = stormLon(j)
      distance =  gc_latlon(LatM,LonM,Lat0,Lon0,2,3)
      stormSpeed(j) = distance/todouble(deltaTime)
;
;----------------------------------------------------------------------------------------
;     
; For this storm Update all arrays
;
      numobs(i)               = ntimes     ; this is the new numobs for this storm      
      time(i,:)               = time@_FillValue
      time(i,0:ntimes-1)      =   stormTime(0:ntimes-1)
      nature(i,0:ntimes-1,:)  = stormnature(0:ntimes-1,:)    
; 
      lat(i,:)  = lat@_FillValue
      lon(i,:)  = lon@_FillValue
      lat(i,0:ntimes-1) = stormLat(0:ntimes-1)
      lon(i,0:ntimes-1) = stormLon(0:ntimes-1)
;      
      speedC(i,0:ntimes-1)  =  (/stormSpeed(0:ntimes-1)/)
       origJ(i,0:ntimes-1)   = (/stormj(0:ntimes-1)/)

; at this time, we have the speeds

       ;print ( cd_calendar(time(i,0:ntimes-1),-3) + " " + speed(i,0:ntimes-1) + " " + speedC(i,0:ntimes-1) )

;
;       do ip = 0,ntimes-1
;         masterBias  = masterBias*masterCount/(masterCount + 1.) + (speed(i,ip)-speedC(i,ip))/(masterCount + 1.)
;         masterRMS   = masterRMS*masterCount/(masterCount + 1.) +   ((speed(i,ip)-speedC(i,ip))^2)/(masterCount + 1.)
;         masterCount = masterCount + 1       
;       end do
;---------------------------------------------------------------------------------------

; 
; Now we calculate the acceleration
;...........................................................................
;
; Speed acceleration      
;
; ac_term1 is the tangential acceleration DS/Dt
;
       ac_term1 := stormSpeed ; just creates a new array
       ac_term1 = ac_term1@_FillValue ;fill it with missing values
       do j = 1,ntimes-2
         deltaTime = stormTime(j+1)-stormTime(j-1)  ; in units of days
         speed2 = stormSpeed(j+1)
         speed1 = stormSpeed(j-1)
; calculate acceleration using centered difference in time
         ac_term1(j) =  (speed2-speed1)/todouble(deltaTime) ; m/s per day
       end do
       
; calculate accel at end points using onesided diff   
       j = 0      
       deltaTime = stormTime(j+1)-stormTime(j)   ; in units of days
       speed2 = stormSpeed(j+1)
       speed1 = stormSpeed(j)
       ac_term1(j) =  (speed2-speed1)/todouble(deltaTime) ; m/s per day
       
       j = ntimes-1
       deltaTime = stormTime(j)-stormTime(j-1)   ; in units of days
       speed2 = stormSpeed(j)
       speed1= stormSpeed(j-1)
       ac_term1(j) =  (speed2-speed1)/todouble(deltaTime) ; m/s per day

; Now store all accel speed values in the large array
       accelSpeed(i,0:ntimes-1)  =  (/ac_term1(0:ntimes-1)/)  ; m/s per day
;...........................................................................       
; Curvature acceleration      
       ac_term2 :=ac_term1
       ac_term2  =ac_term2@_FillValue
 
       R        := ac_term2
       circParams := rad_curv(lat(i,:),lon(i,:),ntimes)
       R(0:ntimes-1) = circParams(2,:)
       
       ;print ("ntimes = " + ntimes)
       ac_term2(0:ntimes-1) = stormSpeed(0:ntimes-1)*stormSpeed(0:ntimes-1)/R(0:ntimes-1) ; m/s per s 
       ac_term2(0:ntimes-1) = ac_term2(0:ntimes-1)*24.*3600.                  ; m/s per day     
       
; also treat the j=0 and j=ntimes-1 points now
; We will use the same Radius of curvature as the point next to it
       j=1
       ac_term2(j-1) = (stormSpeed(j-1)*stormSpeed(j-1)/R(j))*24.*3600.  
       
       j=ntimes-2
       ac_term2(j+1) = (stormSpeed(j+1)*stormSpeed(j+1)/R(j))*24.*3600.  

       print ( "storm " + i + " " + max(ac_term1) + " " + min (ac_term1) )
       print ( "storm " + i + " " + max(ac_term2) + " " + min (ac_term2) )
       print (cd_calendar(time(i,0:ntimes-1),-3) + " " + tointeger(R(0:ntimes-1)*1.e-3) + " " + tofloat(ac_term1(0:ntimes-1)) + " " + tofloat(ac_term2(0:ntimes-1)))
       print ( " " )
     
;.............................................................................................................
; Now store all accel curv values in the large array
     accelCurve(i,0:ntimes-1) = (/ac_term2(0:ntimes-1)/)      
     
   else

     numobs(i) = 0
     time(i,:) = time@_FillValue
     lat(i,:)  = lat@_FillValue
     lon(i,:)  = lon@_FillValue
     speedC(i,:) = speedC@_FillValue
     accelSpeed(i,:)=accelSpeed@_FillValue
     accelCurve(i,:)=accelCurve@_FillValue
     
   end if
end do ; loop over storms

;===========================================================================================  


accelCurve@long_name = "Normal Acceleration"
accelSpeed@long_name = "Tangential Acceleration"

accelSpeed@units = "m/s per day"
accelCurve@units = "m/s per day"


fileName = "tcSpeed.nc"
system( "rm " + fileName )
setfileoption("nc", "format", "NETCDF4") 
outFile = addfile( fileName, "c" )
outFile->numobs=numobs
outFile->sid=sid
outFile->nature=nature
outFile->lat=lat
outFile->lon=lon
outFile->speed=speedC
outFile->accelSpeed=accelSpeed
outFile->accelCurve=accelCurve
outFile->time=time
outFile->origJ=origJ

;===========================================================================================  
print ( "*************************************************" )
print ( "*****   Normal Code Termination  ****************" )
print ( "*************************************************" )

;  print ("bias and rms for speeds:")
;  print ("count = " + masterCount + " " + masterBias + " " + sqrt(masterRMS))
;===========================================================================================

end


