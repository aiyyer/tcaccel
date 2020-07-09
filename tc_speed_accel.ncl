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
; July 5, 2020  : Updated to use Terrell's method
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
begin

; Basic params
  Rearth = todouble(6.356e6)  ;in m (Must be in m)
  pi = 4.*atan(todouble(1.))
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
  dateBeg = dble2flt(cd_inv_calendar(1979,1,1,0,0,0,time@units, 0))
  indices   :=  ind( basin(:,0) .eq. "NA" .and. time .ge. dateBeg )
  ;print (indices + " " + cd_calendar(time(indices),-3) + " " + basin(indices,0) )
  
; base is now the storm number for the first storm in 1950
  delete(time)
  delete(basin)
;
;----------------------------------------------------------------------------
; Now read all the track data  [faster to read all data first]
  time        = fileIn->time 
  lat         = todouble(fileIn->lat)
  lon         = todouble(fileIn->lon )  
  numobs      = toint(short2flt(fileIn->numobs))
  basin       = chartostring(fileIn->basin)
  nature      = fileIn->nature
; read the speed from IBTracs
  speed       = short2flt(fileIn->storm_speed)
  name =  chartostring(fileIn->name)

;-----------------------------------------------------------------------------  
; Now subset only the ones that we need   
  time        := time(indices,:)
  lat         := lat(indices,:)
  lon         := lon (indices,:)  
  numobs      := numobs(indices)
  basin       := basin(indices,:)
  nature      :=  nature(indices,:,:)
; read the speed from IBTracs
  speed       := speed(indices,:)
  name        := name(indices)
  print (cd_calendar(time(:,0),-3) + " " + name )

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
  
;
; We will calculate TC speed ourselves
; in the IBtracs file:IBTrACS.ALL.v04r00.nc"
;  
; define the calculated speed
  speedC = todouble(speed)
  speedC = speedC@_FillValue
  printVarSummary(speedC)
  
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
    if ( numDays .ge. 1. ) then ; storm must live at least 1 days
      
; loop over each track point      
      do j = 1,ntimes-2
        curTime = cd_calendar(stormTime(j),-5)
        hour = curTime(0,3)
;
;
; only consider the three hourly reports        
;        if ( mod(hour,3) .ne. 0 ) then
;          print ("can't get here")
;          exit
;        end if
;
        deltaTime = stormTime(j+1)-stormTime(j-1)   ; in units of days
        deltaTime = deltaTime*24.*3600.             ; in units of seconds
;
;        
        LatP = stormLat(j+1)
        Lat0 = stormLat(j)
        LatM = stormLat(j-1)
;        
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
      speedC(i,:)           = speedC@_FillValue
      speedC(i,0:ntimes-1)  = stormSpeed(0:ntimes-1)
       origJ(i,0:ntimes-1)   = stormj(0:ntimes-1)


;       print ( stormSpeed(0:ntimes-1) + " " +  stormSpeedIB(0:ntimes-1) )
;       exit
;       print (i + " " + ntimes )
;       print ( speedC(i,0:ntimes-1) + " " + lat(i,0:ntimes-1) + " " + lon(i,0:ntimes-1)  + " " + cd_calendar(time(i,0:ntimes-1),-3) )
       
;
; at this time, we have the speeds
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
      accelSpeed(i,0:ntimes-1)  =  ac_term1(0:ntimes-1)  ; m/s per day
;...........................................................................
      
; Curvature acceleration      
      ac_term2 :=ac_term1
      ac_term2=ac_term2@_FillValue
      LonRef = 0.

      do j = 1,ntimes-2
          Lon1 = stormLon(j+1)*pi/180.
          Lon0 = stormLon(j)  *pi/180.
          Lon2 = stormLon(j-1)*pi/180.          
          Lat1 = stormLat(j+1)*pi/180.
          Lat0 = stormLat(j)*pi/180.
          Lat2 = stormLat(j-1)*pi/180.
      
          A := new( (/1,3/), "double" )
          B := A
          C := A
;          
; Mercator conformal projection          
          C(0,:) = (/Rearth*(Lon1-LonRef), Rearth*log(tan(.25*pi + .5*Lat1)),  0. /)  
          A(0,:) = (/Rearth*(Lon0-LonRef), Rearth*log(tan(.25*pi + .5*Lat0)),  0. /)  
          B(0,:) = (/Rearth*(Lon2-LonRef), Rearth*log(tan(.25*pi + .5*Lat2)),  0. /)  

; Now we estimate the radius and center of the circle passing through the coordinates A,B,C          
;         D = cross(B-A,C-A);

          BA := B
          BA  = B-A          
          CA := C
          CA  = C-A          
          D  := CA
          D =  crossp3(BA,CA)
;
;         b = norm(A-C);
          AC := A
          AC = A-C
          b = sqrt( AC(0,0)*AC(0,0) + AC(0,1)*AC(0,1) + AC(0,2)*AC(0,2))
;
;         c = norm(A-B)        
          AB := A
          AB = A-B
          c = sqrt( AB(0,0)*AB(0,0) + AB(0,1)*AB(0,1) + AB(0,2)*AB(0,2))           
;
;         d = norm(D)
          d = sqrt( D(0,0)*D(0,0) + D(0,1)*D(0,1) + D(0,2)*D(0,2))
;          
          E := D
          E = crossp3(D,BA)          
          F := D
          F = crossp3(D,CA)
          G := D
          if ( d .eq. 0. ) then
            R = 1.e10
                                ;M = 0.0
          else
            G = (b*b*E - c*c*F)/(.5*d*d)
            M = G
            M = G +  A   ;coordinate center
            R = sqrt( G(0,0)*G(0,0) + G(0,1)*G(0,1) + G(0,2)*G(0,2))
          end if          
          

    dd1 = sqrt ((A(0,0)-M(0,0))^2 + (A(0,1)-M(0,1))^2 )
    dd2 = sqrt ((B(0,0)-M(0,0))^2 + (B(0,1)-M(0,1))^2 )
    dd3 = sqrt ((B(0,0)-M(0,0))^2 + (B(0,1)-M(0,1))^2 )     

   

    diff1 =  abs(tointeger(100*(R-dd1)/R))
    diff2 =  abs(tointeger(100*(R-dd2)/R))
    diff3 =  abs(tointeger(100*(R-dd3)/R))

   

    ;print ( Lat1 + " " + Lat0 + " " + Lat2 )
    ;print ( Lon1 + " " + Lon0 + " " + Lon2 )
    ;print ( "R = " +  R  + " " + dd1 + " " + dd2 + " " + dd3)
    ;print ( "diff = " +  diff1 + " " + diff2 + " " + diff3)

    

    RR = tointeger(R*1.e-3)

    if ( .not.ismissing(RR) ) then
      if ( RR .ge. 500 .and. RR .le. 10000) then
        if ( max((/diff1,diff2,diff3/)) .ge. 5 ) then
                               
                                ;print ( Lon1*180./pi + " " + Lon0*180./pi + " " + Lon2*180./pi )
                                ;print ( "R = " +  R  + " " + dd1 + " " + dd2 + " " + dd3)
          
          print ( "=========")
           print ( Lat1*180./pi + " " + Lat0*180./pi + " " + Lat2*180./pi )
          print ( "diff = " +  diff1 + " " + diff2 + " " + diff3)
          
          print ( "i j RR = "  + i + " " + j + " " + RR)
                                ;exit
        end if
      end if
    end if
    
    ac_term2(j) = stormSpeed(j)*stormSpeed(j)/R ; m/s per s 
    ac_term2(j) = ac_term2(j)*24.*3600.         ; m/s per day     
    
    
; also treat the j=0 and j=ntimes-1 points now
; We will use the same Radius of curvature as the point next to it
    if ( j .eq. 1 ) then
      ac_term2(j-1) = (stormSpeed(j-1)*stormSpeed(j-1)/R)*24.*3600.  
    end if
    if ( j .eq. (ntimes-2) ) then
      ac_term2(j+1) = (stormSpeed(j+1)*stormSpeed(j+1)/R)*24.*3600.  
    end if
  end do
  
;.............................................................................................................
; Now store all accel curv values in the large array
  accelCurve(i,0:ntimes-1) = ac_term2(0:ntimes-1)      
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


fileName = "tcSpeed_old.nc"
system( "rm " + fileName )
setfileoption("nc", "format", "NETCDF4") 
outFile = addfile( fileName, "c" )
outFile->numobs=numobs
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
;===========================================================================================
  
end


