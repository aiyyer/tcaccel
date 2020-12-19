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
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------


begin

;---------------------------------------------------------------------------  
; user inputs
  startYear = 1980
  endYear   = 2019
  nYears    = endYear - startYear + 1

  LatS =  30
  LatN =  40 
  LonW = -120 
  LonE =  0
  basinAnalysis = "NA"  ;WP

; sdev threshold factor
  sfac = 1.5

; the sfac is used to determine the threshold accel, decel values.
; thresh = mean +/- sfac*sdev  
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
  endTime = cd_inv_calendar(endYear,12,31,24,0,0,time@units, 0)
;
  dat = fileIn->accelCurve




  if ( dat@units .eq. "m/s per day" ) then
    dat = dat*3.6 ; now km/hr per day
    dat@units = "km/hr per day" 
  else
    print (" dat Units unexpected! Terminating code!")
    exit
  end if
  
  speed=fileIn->speed
  time= fileIn->time
  Lat = fileIn->lat
  Lon = fileIn->lon
  numobs      = fileIn->numobs
  nature      = fileIn->nature
;  basin       = fileIn->basin
;
  dims  = dimsizes(time)
  nStorms  = dims(0)

  xmax   =  30.
; create array to store all accel data for some more stats
  datA   = new (60000,typeof(dat))
  icount = 0

; define output arrays  
  N = 2000

       iHigh = 0
   speedHigh   = new (N, typeof(speed) )
   accelHigh   = new (N, typeof(dat) )
     LatHigh     = new (N, typeof(Lat))
     LonHigh     = new (N, typeof(Lon))
    timeHigh    = new (N, typeof(time))
  iStormHigh  = new (N, "integer")
  jStormHigh  = new (N, "integer")

       iZero = 0
   speedZero   = new (N,  typeof(speed) )
   accelZero   = new (N, typeof(dat) )
     LatZero  = new (N, typeof(Lat))
     LonZero  = new (N, typeof(Lon))
    timeZero = new (N, typeof(time))
  iStormZero  = new (N, "integer")
  jStormZero  = new (N, "integer")


  
  accelHigh@units = dat@units
  accelHigh@long_name =  dat@long_name

  accelZero@units =  dat@units
  accelZero@long_name =  dat@long_name

;===================================================================================
;===================================================================================  
;===================================================================================
  
  do iuber = 0,2
    
    
; loop over storms  
    do i = 0,nStorms-1
      do j = 0, numobs(i)-1
        A = dat(i,j)
                                ;print ( i + " " + j + " " + A + " " +  chartostring(nature(i,j,:)))
; apply the relevant checks
        if ( time(i,0) .ge. startTime .and. time(i,0) .le. endTime ) then
;          if ( chartostring(basin(i,j,:)) .eq. basinAnalysis) then
            if ( Lat(i,j) .ge. LatS .and. Lat(i,j) .le. LatN ) then
              if ( Lon(i,j) .ge. LonW .and. Lon(i,j) .le. LonE ) then              
                Nat = chartostring(nature(i,j,:))
                if ( Nat .eq. "TS" ) then                     
                  
;...........................................................        
                  if ( iuber .eq. 0 ) then
; ignore spuriously large values of accel
; this is controlled by the xmax value
                    if (.not.ismissing(A)) then                
                      if ( abs(A) .le. xmax ) then 
                        datA(icount) = A
                        date=cd_calendar(time(i,j),-3)
;                  print ( icount + " " + date + " " +  A )
                        icount = icount + 1
                      end if
                    end if
                  end if
                  
;...........................................................        
                  if ( iuber .eq. 1 ) then
; ignore spuriously large values of accel
; this is controlled by the xmax value
                    if (.not.ismissing(A)) then                
                      if ( abs(A) .le. xmax ) then 
                        if ( A .ge. (ave+ (std*sfac) ) ) then    
                          speedHigh(iHigh)   = speed(i,j)
                          accelHigh(iHigh)   = A
                          LatHigh(iHigh)     = Lat(i,j)
                          LonHigh(iHigh)     = Lon(i,j)
                          timeHigh(iHigh)    = time(i,j)
                          iStormHigh(iHigh)  = i
                          jStormHigh(iHigh)  = j
                          iHigh = iHigh + 1  
                        end if
                        
; for ZERO accel
                        
                        if ( A .lt. 0.05*std ) then 
                          speedZero(iZero)   = speed(i,j)
                          accelZero(iZero)   = A
                          LatZero(iZero)  = Lat(i,j)
                          LonZero(iZero)  = Lon(i,j)
                          timeZero(iZero) = time(i,j)
                          iStormZero(iZero)  = i
                          jStormZero(iZero)  = j
                          iZero = iZero + 1  
                        end if
                        
                        
                      end if
                    end if  
                  end if
                    
;...........................................................
                end if ;nature
              end if ;lon
            end if ;lat        
;          end if ;basin
        end if ;time
      end do ;j
    end do ;i
    
    if ( iuber .eq. 0 ) then
      print ( "icount = " + icount )
      ave = avg( datA(0:icount-1) )
      std = stddev(datA(0:icount-1) )
      med = dim_median( datA(0:icount-1) )
      print ("Mean Median and Sdev = " + ave + " " + med + " " +  std)      
    end if
  end do
  

;
;  
;
  speedHigh!0 = "HighCount"
  accelHigh!0 = "HighCount"
  LatHigh!0 = "HighCount"
  LonHigh!0 = "HighCount"
  timeHigh!0 = "HighCount"
  iStormHigh!0 = "HighCount"
  jStormHigh!0 = "HighCount"
;
  speedZero!0 = "ZeroCount"
  accelZero!0 = "ZeroCount"
  LatZero!0 = "ZeroCount"
  LonZero!0 = "ZeroCount"
  timeZero!0 = "ZeroCount"
  iStormZero!0 = "ZeroCount"
  jStormZero!0 = "ZeroCount"
;
;
  fileName = "tcAcc_dates_curvature" + LonW + "_" + LonE + "_" + LatN + "_" + LatS+"_"+ basinAnalysis + ".nc"
  system( "rm " + fileName )
 ; setfileoption("nc", "format", "NETCDF4") 
  outFile = addfile( fileName, "c" )
  outFile->ave=ave
  outFile->std=std
  outFile->sfac=sfac
  outFile->LatS=LatS
  outFile->LatN=LatN
  outFile->LonW=LonW
  outFile->LonE=LonE

  N=iHigh-1
  speedHigh2 :=speedHigh(0:N)
  accelHigh2 :=accelHigh(0:N)
  LatHigh2   :=LatHigh(0:N)
  LonHigh2   :=LonHigh(0:N)
  iStormHigh2:=iStormHigh(0:N)
  jStormHigh2:=jStormHigh(0:N)
  timeHigh2  :=timeHigh(0:N)

  outFile->speedHigh=speedHigh2
  outFile->accelHigh=accelHigh2
  outFile->LatHigh=LatHigh2
  outFile->LonHigh=LonHigh2
  outFile->iStormHigh=iStormHigh2
  outFile->jStormHigh=jStormHigh2
  outFile->timeHigh=timeHigh2
  outFile->HighCount=N
 ; print ( speedHigh2 + " " + accelHigh2)


  print ("rapid accel cases:")
  print ( "mean accel = " + avg(accelHigh2) + " " + "median accel = " + dim_median(accelHigh2) )
  print ( "max accel = " + max(accelHigh2) + " " + "min accel = " + min(accelHigh2) )
  print ( "mean lat = " + avg(LatHigh2) + " " + "median lat = " + dim_median(LatHigh2) )
  print ( "max lat = " + max(LatHigh2) + " " + "min lat = " + min(LatHigh2) )
  print ( "mean speed  = " + avg(speedHigh2) + " " + "median speed = " + dim_median(speedHigh2) )


  N=iZero-1
  speedZero2 :=speedZero(0:N)
  accelZero2 :=accelZero(0:N)
  LatZero2   :=LatZero(0:N)
  LonZero2   :=LonZero(0:N)
  iStormZero2:=iStormZero(0:N)
  jStormZero2:=jStormZero(0:N)
  timeZero2  :=timeZero(0:N)

  ;print ( speedZero2 + " " + accelZero2)
  outFile->speedZero=speedZero2
  outFile->accelZero=accelZero2
  outFile->LatZero=LatZero2
  outFile->LonZero=LonZero2
  outFile->iStormZero=iStormZero2
  outFile->jStormZero=jStormZero2
  outFile->timeZero=timeZero2
  outFile->ZeroCount=N


  print (" " )
  print ("zero accel cases:")
  print ( "mean accel = " + avg(accelZero2) + " " + "median accel = " + dim_median(accelZero2) )
  print ( "max accel = " + max(accelZero2) + " " + "min accel = " + min(accelZero2) )
  print ( "mean lat = " + avg(LatZero2) + " " + "median lat = " + dim_median(LatZero2) )
  print ( "max lat = " + max(LatZero2) + " " + "min lat = " + min(LatZero2) )
 
  print ( "mean speed  = " + avg(speedZero2) + " " + "median speed = " + dim_median(speedZero2) )

  print ( " iHigh, iZero = "  + iHigh + " " + iZero)
;===================================================================================
;===================================================================================  
;===================================================================================
  
end


