; a program to:
;              Plot composite ET relative speed and accel as a function of time
;
;
;
;-----------------------------------------------------------------------------
; NCSU Tropical Dynamics Group
; A. Aiyyer
; Nov 4, 2019
;.............................................................................
;   Input  -> tcSpeed.nc which is created by tc_speed.ncl
;   Output -> A pdf file showing time series of ensemble average speed and two
;             types of acceleration (speed and curvature)
;
;             ensemble avg refers to composite over all storms
;             in the specified basin, time period etc. 
;-----------------------------------------------------------------------------
;
; updated with comments and to include the first and last TC position
; Dec 5, 2019 
;-----------------------------------------------------------------------------
;
;
begin
;  
; user inputs
  startYear = 1979
  endYear   = 2018
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

; read the two acceleration date  
  accelS   = fileIn->accelSpeed  ;tangential
  accelC   = fileIn->accelCurve  ;curvature/normal
; read the speeds  
  speed   = fileIn->speed
    
  time  = fileIn->time
  Lat   = fileIn->lat
  Lon   = fileIn->lon
  numobs      = fileIn->numobs
  nature      = fileIn->nature
;  basin       = fileIn->basin
  dims        = dimsizes(time)
  nStorms     = dims(0)

  
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


; bin size in hours
  lagH = 72
  dh   = 6
  nn   = 250
  nh   = 2*lagH/dh + 1
  nh2  = (nh-1)/2


; these arrays will hold the accel and speed values for each storm
; for the lags defined above 
  accelET:= new( (/2,nn,nh/),"double")
  accelET@_FillValue =  accelS@_FillValue
  accelET            = accelET@_FillValue
;
  speedET = new( (/nn,nh/),"double")
  speedET@_FillValue = speed@_FillValue 
  speedET            = speedET@_FillValue

;  
;======================================================================================
; first establish some basic stats for this lat-bin
; create array to store all accel data for some more stats
    icount    = 0
    nrCount   = 0
    totCount  = 0
    tsCount   = 0
    ETCount   = 0

    
;loop over storms  
    do i = 0,nStorms-1
      if ( numobs(i) .ne. 0 ) then
        numDays = todouble(time(i,numobs(i)-1) - time(i,0))
        
;storm must live at least 1 days
      if (  numDays .ge. 1 ) then
        if ( time(i,0) .ge. startTime .and. time(i,0) .le. endTime ) then

; initialize flag          
          ETflag = 0

; temporarily store the speed and accel for this TC in
; new arrays          
          speedAccel := accelS(i,0:numobs(i)-1)    ;accel for this track
          curvAccel := accelC(i,0:numobs(i)-1)    ;accel for this track

          ; smooth the curvature accel?
          ;opt   = 0
          ;nave  = 5
          ;curvAccel  :=  runave (accelC(i,0:numobs(i)-1)  , nave, opt)
          
          stormSpeed := speed(i,0:numobs(i)-1)    ;speed for this track
          dates:=  time(i,0:numobs(i)-1)    ;dates along the track

          speedAccel!0    = "time"
          speedAccel&time = dates
          curvAccel!0     = "time"
          curvAccel&time  = dates
          stormSpeed!0    = "time"
          stormSpeed&time = dates

 ; now loop over all track points         
          do j = 0, numobs(i)-1
         
; apply the relevant checks
            ;if ( chartostring(basin(i,j,:)) .eq. basinAnalysis) then
              if ( Lat(i,j) .ge. latS .and. Lat(i,j) .le. latN ) then  
                totCount = totCount+1

                if ( ETflag .eq. 0 ) then
                  if ( chartostring(nature(i,j,:)) .eq. "ET" ) then
                    ETflag = 1
                    ;print ( ETCount + " " + i + " " + j + " " + Lat(i,j) + " " + cd_calendar( time(i,j),-3))

; now that we have found the ET, lets take each dh hour period spannning lagH hours before and after
; and record the speed/accel
                    
                    
; loop over the times before and after the first ET designation
                    do ih = -nh2,nh2
                      
                        ah    = ih*dh/24.  ;in days, this is the lag relative to ET designation
                        date := dates(j)   ;the reference date at ET designation
                        date  = date + ah  ;the date corresponding to the lag ah

; check that we are not running into the track begin/end                        
                        if ( date .ge. dates(0) .and.  date .le. dates(numobs(i)-1))
                          accelET(0,ETCount,ih+nh2)  = speedAccel({date})
                          accelET(1,ETCount,ih+nh2)  = curvAccel({date})
                          speedET(ETCount,ih+nh2)    = stormSpeed({date})
                        end if
                        
                    end do  ;ih
                    
                    ETCount = ETCount + 1
                  end if ;ET
                end if   ;ETflag
                
                
              end if ; lat              
            ;end if ;basin
          end do ; j
          
        end if
      end if ;numdays
    end if
    end do ;i


    d1 = -nh2*dh
    d2 =  nh2*dh
    hours = fspan(d1,d2,nh)
    meanA   =    dim_avg_n( accelET,1 )
    medianA = dim_median_n( accelET,1 )
    meanS   =    dim_avg_n( speedET,0 )
    medianS = dim_median_n( speedET,0 )

;    do i = 0,32
;      amin = min(accelET(0,:,i))
;      amax = max(accelET(0,:,i))
;      print ( hours(i)  + " " + meanA(0,i) + "  " + medianA(0,i) + " " + amin + " " + amax)
;    end do

    yMin = -20.
    yMax =  20.
    
    wks = gsn_open_wks("pdf", "lagAS")                ; create postscript file
    
; resources for "left" variable
    resL                        = True 
    resL@xyLineThicknesses      = (/4.,4./)                  ; thicker line
    resL@tiYAxisString = "Acceleration (km/hr/day)"
    resL@tiXAxisString = "Hour Relative to ET"
    resL@gsnDraw   = False                             ; don't draw yet
    resL@gsnFrame  = False                             ; don't advance yet
    resL@xyExplicitLegendLabels = (/"Tangential Acceleration","Curvature Acceleration "/)         ; create explicit labels
    
    resL@pmLegendDisplayMode    = "Always"            ; turn on legend
    resL@pmLegendSide           = "Top"               ; Change location of 
    resL@pmLegendParallelPosF   = .8                  ; move units right
    resL@pmLegendOrthogonalPosF = -0.3                ; move units down
    resL@pmLegendWidthF         = 0.15                ; Change width and
    resL@pmLegendHeightF        = 0.16                ; height of legend.
    resL@lgPerimOn              = False               ; turn off box around
    resL@lgLabelFontHeightF     = .01                 ; label font height
    resL@lgItemOrder  = (/1,0/)   ; Reorder the legends
    
    
; resources for "right" variable
    resR                        = True                      
    resR@xyDashPatterns         = 1                   ; dashed line for 2nd
    resR@xyLineThicknesses      = 4.                   ; thicker line
    resR@tiYAxisString = "Speed (km/hr)"   ; axis string
    resR@gsnDraw   = False                             ; don't draw yet
    resR@gsnFrame  = False                             ; don't advance yet
    resR@xyExplicitLegendLabels =  (/"Forward Speed          "/)         ; create explicit labels
    resR@pmLegendDisplayMode    = "Always"            ; turn on legend
    resR@pmLegendSide           = "Top"               ; Change location of 
    resR@pmLegendParallelPosF   = .8                  ; move units right
    resR@pmLegendOrthogonalPosF = -0.3                ; move units down
    resR@pmLegendWidthF         = 0.15                ; Change width and
    resR@pmLegendHeightF        = 0.16                ; height of legend.
    resR@lgPerimOn              = False               ; turn off box around
    resR@lgLabelFontHeightF     = .01                 ; label font height
    
    
    
    
    
    resL@trXMinF = -1*lagH
    resL@trXMaxF =  1*lagH
    
    
    resR@trXMinF =  -1*lagH
    resR@trXMaxF =   1*lagH
    
    resL@tmXBMode        = "Manual"	
    resL@tmXBTickStartF  =  -1*lagH
    resL@tmXBTickEndF    = 1*lagH
    resL@tmXBTickSpacingF= dh*3
    
    resR@tmXBMode        = "Manual"	
    resR@tmXBTickStartF  =  -1*lagH
    resR@tmXBTickEndF    = 1*lagH
    resR@tmXBTickSpacingF= dh*3
    
                                ;resL@tmXBMode        = "Explicit"	
                                ;resL@tmXBValues      = ispan(-1*lagH, 1*lagH,dh)
    
                                ;resR@tmXBMode        = "Explicit"	
                                ;resR@tmXBValues      = ispan(-1*lagH, 1*lagH,dh)
    
    
    
    resp                  = True                      ; polyline mods desired
    resp@gsLineColor      = "red"                     ; color of lines
    resp@gsLineThicknessF = 1.0                       ; thickness of lines
    resp@gsLineLabelString= "ET"                    ; adds a line label string
    
    xx = (/ 0., 0./)
    yy = (/-8., 20. /)
    
    
    resL@xyLineColors= (/"black", "gray"/)        ; set polymarker color
    plot = gsn_csm_xy2(wks,hours,meanA(:,:),meanS,resL,resR)
    

    ; draw a vertical line to mark ET which is x=0 line
    resp                  = True                      ; polyline mods desired
    resp@gsLineColor      = "red"                     ; color of lines
    resp@gsLineThicknessF = 2.0                       ; thickness of lines
    resp@gsLineLabelString= "ET"                    ; adds a line label string
    xx = (/ 0., 0./)
    yy = (/-10., 25. /)
    dum=gsn_add_polyline(wks,plot,xx,yy,resp)      
    
    draw(plot)
    frame(wks)
    
    
    print ( "Normal code end")
    
end

