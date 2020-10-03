;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
; a program to:
;
; read the IBTraCS database and 
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------

begin
; user inputs
  startYear = 1970
  endYear   = 2019
  nYears    = endYear - startYear + 1
  basinCheck = "WP"

  fileName = "../IBTrACS.ALL.v04r00.nc"
  fileIn = addfile( fileName, "r" )
  
  
  print ( "reading IBTrACS data from : "  + fileName)
;-----------------------------------------------------------------------------  

  


  time        = fileIn->time
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
  basin       = chartostring(fileIn->basin)  
  lat         = fileIn->lat
  lon         = fileIn->lon
  numobs      = toint(short2flt(fileIn->numobs))
  sid         = chartostring(fileIn->sid)
  nature      = fileIn->nature

  
; read the speed from IBTracs
  speed       = short2flt(fileIn->storm_speed)

  if ( speed@units .eq. "kts" ) then
    speed = speed*0.514   
    speed@units = "m/s"
  else
    print ("Error! Unknown translation speed units")
    print (speed@units)
    print ("Terminating code!!!! Please check")
  end if

;------------------------------------------------------------------


  dims = dimsizes(numobs)
  nStorms = dims
  
  print ("number of storms = " + nStorms)

  type = (/"DS","TS", "ET","SS","NR","MX"/)



  totCount  = 0
  countType = new(6,"integer")
  countType = 0


  Nmax     =  400000
  latType  =  new( (/6,Nmax/), "float")
  latType@_FillValue = -9999.0
  latType  =  latType@_FillValue


  yearlyType = new( (/nYears,6/),"integer")
  yearlyType= 0


  Nmax = 4000
  yearlySpeed = new( (/nYears,Nmax/),"double")
  yearlySpeed@_FillValue  = -9999.0
  yearlySpeed =  yearlySpeed@_FillValue
  yearlyCount =  new( (/nYears/),"integer")
  yearlyCount = 0
  
;============================================================================================
; Loop over all storms  

  do i = 0,nStorms-1
    
    if ( time(i,0) .ge. startTime .and. time(i,numobs(i)-1 ) .le. endTime ) then
      
      
; also check if storm lasts over 2 days
      numDays = time(i,numobs(i)-1) -  time(i,0)
      
;............................................................
      if ( numDays .ge. 3. ) then ; storm must live at least 2 days
        
        
        do j = 0,numobs(i)-1
          
          if ( basin(i,j) .eq. basinCheck ) then

            date = cd_calendar(  time(i,j) ,-5)
            hour = date(0,3)
            
; only consider the three hourly reports
            if ( mod(hour,3) .eq. 0 ) then
              
              iy = date(0,0)-startYear                   


              stormNature = chartostring(nature(i,j,:))
              
              if ( stormNature .ne. "ET" .and.  stormNature .ne. "NR" )  then
                iic = yearlyCount(iy)
                yearlySpeed(iy,iic) = todouble(speed(i,j))
                yearlyCount(iy)     =  yearlyCount(iy) + 1
              end if
              
              totCount = totCount + 1
              do k = 0,5
                if ( chartostring(nature(i,j,:)) .eq. type(k) ) then
                  latType(k, countType(k) ) = lat(i,j)
                  countType(k) = countType(k)+1
                  yearlyType(iy,k) = yearlyType(iy,k) + 1
                end if
              end do
              
            end if
            
          end if ;basin
          
        end do ;j
      end if
    end if
  end do
  


  print ("basin to check = " + basinCheck )
  print ("Year range     = " + startYear + " " + endYear )
  print ("Sample N = " + totCount + " " + sum(countType)  + " " + sum(yearlyCount) )

  percent = tofloat(countType)
  percent = 100.*percent/sum(countType)

  aveLatType = dim_avg_n(latType,1)
  medLatType = dim_median_n(latType,1)

  outString = type

  statString =  sprintf("%6.3f",aveLatType) + " " +  sprintf("%6.3f",medLatType)
  outString = type + " " +  sprinti("%8i",countType) + " " + sprintf("%6.3f",percent) + " " + statString
  
  print (outString)



  do i = 0,nYears-1
    print ( i+startYear + " " +  yearlyType(i,0)  + " " +  yearlyType(i,1)  + " " +  yearlyType(i,2)  + " " +  yearlyType(i,3)  + " " +  yearlyType(i,4)  + " " +  yearlyType(i,5) + " " + yearlyCount(i) )

  end do



  aveSpeed =   dim_avg_n(yearlySpeed,1)
  medSpeed = dim_median_n(yearlySpeed,1)

  aveSpeed= aveSpeed*3.6
  medSpeed= medSpeed*3.6
  x = ispan(startYear,endYear,1)
;  print ("-------------------------")
;  print ( x + " " + aveSpeed)
;  print ("-------------------------")

  opt  = False
  pt   = trend_manken(aveSpeed, opt, 0) 
  pt(0) = 1.-pt(0)
  print ("MK trend and prob ave speed = " + pt(1)+ " " + pt(0) )

; calculate the regression coefficient (slope)    
    rc    = regline(x,aveSpeed)          ; slope           
    rc@units = " "           
    ;df   = rc@nptxy-2
    sigr = 0.05                        ; critical sig lvl for r
    df = equiv_sample_size (aveSpeed, sigr,0)
    prob = betainc(df/(df+rc@tval^2), df/2.0, 0.5)
    print("rc trend and prob = " + rc + " " + prob + " df = " + df)

  
  
  opt  = False
  pt   = trend_manken(medSpeed, opt, 0) 
  pt(0) = 1.-pt(0)
  print ("MK trend and prob med speed = " + pt(1)+ " " + pt(0) )  

;===========================================================================================
; plotting parameters
; This illustrates one approach. Overlays could also be used.
;************************************************
   wks  = gsn_open_wks("pdf","speed")             ; send graphics to PNG file
   
   res                     = True                   ; plot mods desired
   res@xyMarkLineModes     = (/"Lines","Lines"/)  ; choose which have markers
   res@xyMarkers           = 16                     ; choose type of marker 
   res@xyMarkerColor       = "red"                  ; Marker color
   res@xyMarkerSizeF       = 0.005                  ; Marker size (default 0.01)
   res@xyDashPatterns      = 1                      ; solid line 
   res@xyLineThicknesses   = (/1,3/)                ; set second line to 2
   res@tmYLFormat          = "f"                    ; not necessary but nicer labels 
   res@tiMainString        = " "  ; title



   plot  = gsn_csm_xy (wks,x,aveSpeed,res)           ; create plot


   delete(wks)
   delete(plot)
   
;************************************************
; plotting parameters
; This illustrates one approach. Overlays could also be used.
;************************************************
  wks  = gsn_open_wks("pdf","nature")             ; send graphics to PNG file
  
  res                     = True                   ; plot mods desired
  res@tmYLFormat          = "f"                    ; not necessary but nicer labels 
  res@gsnDraw             = False       ; Don't draw plots
  res@gsnFrame            = False       ; Don't advance frame
  res@gsnXYBarChart         = True            ; create bar chart 
  res@gsnXYBarChartBarWidth = 0.2
  res@gsnAboveYRefLineColor = "gray"           ; above ref line fill red
  
  
  plot = new(6,"graphic")
  
  
  
  do i = 0,5
    res@tiMainString        = type(i)
    plot(i)  = gsn_csm_xy (wks,x,yearlyType(:,i),res)           ; create plot
  end do
  
  
  
  resP                     = True                ; modify the panel plot    
  resP@lbLabelFontHeightF  = 0.007               ; make labels smaller
  resP@gsnPanelYWhiteSpacePercent = 5
  resP@gsnPanelXWhiteSpacePercent = 5
  
  gsn_panel(wks,plot,(/3,2/),resP) 
  
  

end


