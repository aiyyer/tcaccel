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
;
; Sep 22 2020: Clean up code
;
;-----------------------------------------------------------------------------
;
;



begin
;  
; user inputs
  startYear = 1966
  endYear   = 2019
  nYears    = endYear - startYear + 1
  basinAnalysis = "NA"   ;WP, NA...
;--------------------------------------------------------------------------      


  
  fileName = "../tcMotion.nc"
  print ( "Start Year = " + startYear + " end year = " + endYear)

; choose the latitude band
  latS = 0. 
  latN = 90.


;--------------------------------------------------------------------------      

  
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
  basin = fileIn->basin

  time  = fileIn->time
  Lat   = fileIn->lat
  Lon   = fileIn->lon
  numobs      = fileIn->numobs
  nature      = fileIn->nature
  dims        = dimsizes(time)
  nStorms     = dims(0)

  print ( "Num Storms in file process = " + nStorms)
  
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


; go 72 hours prior to 48 hours post ET
  lagM = -72
  lagP =  48
  dh   =  3   ; data is 3 hourly
  nn   =  800 ; number of storms likely in the data
  nh   = (-lagM+lagP) /dh + 1 ; number of hour bins
  hours   = ispan(lagM,lagP,dh)

; these arrays will hold the accel and speed values for each storm
; for the ET-relative hours defined above
  
  accelET:= new( (/2,nn,nh/),"double")
  accelET@_FillValue =  accelS@_FillValue
  accelET            = accelET@_FillValue
  accelET!0 = "type"
  accelET&type = (/"tang","curv"/)
  accelET!1 = "storm"
  accelET!2 = "hour"
  accelET&hour = hours
;
  speedET = new( (/nn,nh/),"double")
  speedET@_FillValue = speed@_FillValue 
  speedET            = speedET@_FillValue
  speedET!0 = "storm"
  speedET!1 = "hour"
  speedET&hour = hours




  latET = new(nn, typeof(Lat) )
  lonET = new(nn, typeof(Lon) )
  
;  
;======================================================================================
; some counters
  
  icount    = 0
  nrCount   = 0
  totCount  = 0
  tsCount   = 0
  ETCount   = 0
  
    
;loop over storms  
    do i = 0,nStorms-1

;
;-----discard non TS storms and storms that form in basins other than what was requested.
;     
      TSFlag       = 0
      BasinFlag    = 0
      
      if (  basin(i,0) .eq. basinAnalysis ) then
        ;print ( i + " matches basin requested = " + basinAnalysis )
        BasinFlag = 1
      end if
      
      do j = 0, numobs(i)-1
        if ( chartostring(nature(i,j,:)) .eq. "TS" ) then
          TSFlag    = 1
        end if
      end do

; Now move forward with this storm
     
      if ( TSFlag .eq. 1 .and. BasinFlag .eq. 1 ) then

        numDays = todouble(0)
        if ( numobs(i) .ne. 0 ) then
          numDays = todouble(time(i,numobs(i)-1) - time(i,0))
        end if

;storm must live at least 3 days
        if (  numDays .ge. 3 ) then          
          if ( time(i,0) .ge. startTime .and. time(i,  numobs(i)-1) .le. endTime ) then
            
            totCount = totCount + 1
            
; temporarily store the speed and accel for this TC in ; new arrays          
            speedAccel := accelS(i,0:numobs(i)-1)    ;accel for this track
            curvAccel  := accelC(i,0:numobs(i)-1)    ;accel for this track
            stormSpeed :=  speed(i,0:numobs(i)-1)    ;speed for this track
            
            
            dates:=  time(i,0:numobs(i)-1)          ;dates along the track
            speedAccel!0    = "time"
            speedAccel&time = dates
            curvAccel!0     = "time"
            curvAccel&time  = dates
            stormSpeed!0    = "time"
            stormSpeed&time = dates
            
            nat :=  chartostring( nature(i,0:numobs(i)-1,:) )
            nat!0      = "time"
            nat&time   = dates
            ETflag = 0
            
                                ; now loop over all track points                    
            do j = 0, numobs(i)-1
              
; apply the relevant checks
              if ( ETflag .eq. 0 ) then
                if ( chartostring(nature(i,j,:)) .eq. "ET" ) then


                  latET(ETCount) = Lat(i,j)
                  lonET(ETCount) = Lon(i,j)
                  
                  
                  ETCount   = ETCount+1
 
                  ETflag = 1
                   deltaDaysToEndOfTrack =  time(i,numobs(i)-1) -  time(i,j)
                   deltaDaysToBegOfTrack =  time(i,j) - time(i,0)
                   
                   
; now that we have found the ET, lets take each dh hour period spannning lagH hours before and after
; and record the speed/accel
                   
; lets make sure that we have TC data after ET
                   
                   
                   deltaDaysToEndOfTrack =  time(i,numobs(i)-1) -  time(i,j)
                   deltaDaysToBegOfTrack =  time(i,j) - time(i,0)
                   
                   ;if (  deltaDaysToEndOfTrack .ge.  2. .and. deltaDaysToBegOfTrack .ge.  3. ) then
                     
                     do ih = lagM,lagP,dh
                       
                       ah    = tofloat(ih)/24.  ;in days, this is the lag relative to ET designation
                       date := dates(j)   ;the reference date at ET designation
                       date  = date + ah  ;the date corresponding to the lag ah
                       
; check that we are not running into the track begin/end                        
                       if ( date .ge. dates(0) .and.  date .le. dates(numobs(i)-1))
                         accelET(0,icount,{ih})  = (/speedAccel({date})/)
                         accelET(1,icount,{ih})  = (/curvAccel({date})/)
                         speedET(  icount,{ih})    = (/stormSpeed({date})/)
                       end if
                       
                       
                     end do  ;ih
                     
                     icount=icount+1
                     
                     
                   ;end if
                   
                   
                   
                 end if
               end if
               
               
             end do ;j
             
             
             
             
             
             
           end if ;time
         end if ; numdays
       end if ; TSflag
       
       
     end do ;i
     
     print ("Qual Storm numbers = " + totCount)
     print ("ET Storm numbers = " + ETCount)
     perET = 100.*tofloat(ETCount)/tofloat(totCount)
     print ("Percent ET = " + perET)
     print ("Storm numbers for composit= " + icount)
     print ("Mean lat of ET = " + avg(latET(0:ETCount-1)) )
     print ("Median lat of ET = " +dim_median(latET(0:ETCount-1)) )
     
     
;====================================================================================================
     
     
     
     
; check how many cases accelerated prior to ET
     
     h1  = -12.0
     h2  = 0
     iP  = 0
     do i = 0,icount-1
       if(.not.all(ismissing(accelET(0,i,{h1:h2})    ))) then
         val = max (accelET(0,i,{h1:h2}))  ; avg
         
         if ( val .gt. 0. ) then
                                ;print ( iP + " " +  ave)
           iP = iP + 1
         end if
       else
       end if
     end do
     perP = 100*tofloat(iP)/tofloat(ETCount)
     
     print ("percent accel = " + perP)
     
     
     meanA   =    dim_avg_n_Wrap(accelET,1 )
     medianA = dim_median_n(accelET,1 )
     meanS   =    dim_avg_n_Wrap( speedET,0 )
     medianS = dim_median_n( speedET,0 )
     
     yMin = -20.
     yMax =  20.
     
     wks = gsn_open_wks("png", "ET_relative_accel_speed")                ; create postscript file
     
; resources for "left" variable
     resL                        = True 
     resL@xyLineThicknesses      = (/8.,8./)                  ; thicker line
     resL@tiYAxisString = "Acceleration (km/hr/day)"
     resL@tiXAxisString = "Hour Relative to ET"
     resL@gsnDraw   = False                             ; don't draw yet
     resL@gsnFrame  = False                             ; don't advance yet
     resL@xyExplicitLegendLabels = (/"Tangential Acceleration","Curvature Acceleration "/)         ; create explicit labels
     
     resL@pmLegendDisplayMode    = "Always"            ; turn on legend
     resL@pmLegendSide           = "Top"               ; Change location of 
     resL@pmLegendParallelPosF   = .22                  ; move units right
     resL@pmLegendOrthogonalPosF = -0.18                ; move units down
     resL@pmLegendWidthF         = 0.12                ; Change width and
     resL@pmLegendHeightF        = 0.10                ; height of legend.
     resL@lgPerimOn              = False               ; turn off box around
     resL@lgLabelFontHeightF     = .013                 ; label font height
     resL@lgItemOrder  = (/1,0/)   ; Reorder the legends
     
     
; resources for "right" variable
     resR                        = True                      
     resR@xyDashPatterns         = 1                   ; dashed line for 2nd
     resR@tiYAxisString = "Speed (km/hr)"   ; axis string
     resR@gsnDraw   = False                             ; don't draw yet
     resR@gsnFrame  = False                             ; don't advance yet
     resR@xyExplicitLegendLabels =  (/"Forward Speed          "/)         ; create explicit labels
     resR@pmLegendDisplayMode    = "Always"            ; turn on legend
     resR@pmLegendSide           = "Top"               ; Change location of 
     resR@pmLegendParallelPosF   = .87                  ; move units right
     resR@pmLegendOrthogonalPosF = -0.15                ; move units down
     resR@pmLegendWidthF         = 0.12                ; Change width and
     resR@pmLegendHeightF        = 0.10                ; height of legend.
     resR@lgPerimOn              = False               ; turn off box around
    
     resR@lgLabelFontHeightF     = .013                 ; label font height
     resR@xyLineThicknesses      = (/8.,8./)                  ; thicker line

     
     resL@trXMinF = lagM
     resL@trXMaxF = lagP
     
     
     resR@trXMinF = lagM
     resR@trXMaxF = lagP
     
     resL@tmXBMode        = "Manual"	
     resL@tmXBTickStartF  = lagM
     resL@tmXBTickEndF    = lagP
     resL@tmXBTickSpacingF= dh*4
     
     resR@tmXBMode        = "Manual"	
     resR@tmXBTickStartF  =  lagM
     resR@tmXBTickEndF    =  lagP
     resR@tmXBTickSpacingF= resL@tmXBTickSpacingF
     
                                ;resL@tmXBMode        = "Explicit"	
                                ;resL@tmXBValues      = ispan(-1*lagH, 1*lagH,dh)
    
                                ;resR@tmXBMode        = "Explicit"	
                                ;resR@tmXBValues      = ispan(-1*lagH, 1*lagH,dh)
    
    
    
    resp                  = True                      ; polyline mods desired
    resp@gsLineColor      = "red"                     ; color of lines
    resp@gsLineThicknessF = 3.0                       ; thickness of lines
    resp@gsLineLabelString= "ET"                      ; adds a line label string
    
      
    resL@xyLineColors= (/"red", "blue"/)        ; set polymarker color
    resR@xyLineColors= (/"green", "purple"/)        ; set polymarker color



   ; smooth the data for display
    opt   = 1         
    nave  = 5

    ;printVarSummary(meanA)
    
    meanA(0,:)  =  runave (meanA(0,:) , nave, opt)
    meanS       =  runave (meanS , nave, opt)
    do ii = 0,1
      nave  = 5
      meanA(1,:)  =  runave (meanA(1,:) , nave, opt)
    end do

    
    plot = gsn_csm_xy2(wks,hours,meanA,meanS,resL,resR)
    ;plot = gsn_csm_xy2(wks,hours,medianA,medianS,resL,resR)

    ; plot = gsn_csm_xy(wks,hours,meanS,resR)

    ; draw a vertical line to mark ET which is x=0 line
    resp                  = True                      ; polyline mods desired
    resp@gsLineColor      = "red"                     ; color of lines
    resp@gsLineThicknessF = 2.0                       ; thickness of lines
    resp@gsLineLabelString= "ET"                    ; adds a line label string
    xx = (/ 0., 0./)
    yy = (/-20., 50. /)
    dum=gsn_add_polyline(wks,plot,xx,yy,resp)      
    
    draw(plot)
    frame(wks)
    print ( "Normal code end")
    
end

