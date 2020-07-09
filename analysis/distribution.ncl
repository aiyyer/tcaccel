;-----------------------------------------------------------------------------
; a program to:
;              plot the distributions (boxplots) of TC speed/accel
;              for chosen lat ranges
;
; 5 Dec 2019
; Aiyyer 
; NCSU Tropical Dynamics Group
;
;----------------------------------------------------------------------------

begin

  variable = (/"speed","accelSpeed","accelCurve"/)
  
  
  
; user inputs
  startYear = 1979
  endYear   = 2018
  basinAnalysis = "NA"
;
;  
; choose the latitude bands
  latS =   5.
  latN =  55.
  dlat =  10.

  nBin = tointeger( (latN-latS)/dlat ) + 1
  x = fspan(latS,latN,nBin) + .5*dlat
  nmax = 12000
  histoDat   = new ((/nBin,nmax/), "double" )
  histoCount = new (nBin, "integer" )
  
;--------------------------------------------------------------------------  
  wks = gsn_open_wks("pdf","box")               ; send graphics to PNG file
  res            = True                         ; plot mods desired
  plot = new(3,graphic)                          ; create a plot array
  dum  = new(3,graphic)                          ; create a plot array

  fileName = "../tcSpeed.nc"
  fileIn = addfile( fileName, "r" )
    
  time = fileIn->time

  
  Lat  = fileIn->lat
  Lon  = fileIn->lon
  numobs      = fileIn->numobs
  nature      = fileIn->nature
  ;basin       = fileIn->basin
  dims        = dimsizes(time)
  nStorms     = dims(0)
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


;...................................................
  do ivar = 0,2

; initialize arrays
    histoCount = 0
    histoDat = histoDat@_FillValue
    
    var = variable(ivar)    
    dat := fileIn->$var$


    printVarSummary(dat)
    
    
    if ( var .eq. "speed" ) then
      Amax = 30.*3.6
      if ( dat@units .eq. "m/s" ) then
        dat := dat*3.6 ; now km/hr per day
        dat@units = "km/hr per day" 
      else
        print ("Units unexpected! Terminating code!")
        exit
      end if
      yTitle = "Speed (km/hr)"
    end if  
    if ( var .eq. "accelSpeed" .or. var .eq.  "accelCurve" ) then
      Amax = 30.*3.6
      if ( dat@units .eq. "m/s per day" ) then
        dat := dat*3.6 ; now km/hr per day
        dat@units = "km/hr per day" 
      else
        print ("Units unexpected! Terminating code!")
        exit
      end if
    end if
    
    title = basinAnalysis  
    
;..................................................................
    do i = 0,nStorms-1
        
      if ( numobs(i) .gt. 0 ) then
        
; apply the relevant checks
        
        if ( time(i,0) .ge. startTime .and. time(i,0) .le. endTime ) then
          numDays = tofloat(time(i,numobs(i)-1) - time(i,0))
;   storm must live at least 1 days
          if (  numDays .ge. 1 ) then
            
            
            do j = 0, numobs(i)-1
              A= dat(i,j)


              if ( chartostring(nature(i,j,:)) .eq. "TS") then
                ;if ( chartostring(basin(i,j,:)) .eq. basinAnalysis) then
                  if ( (Lat(i,j) .ge. latS) .and. (Lat(i,j) .le. latN) ) 

; ignore spuriously large values of accel
; this is controlled by the xmax value
                    if (.not.ismissing(A) .and. abs(A) .le. Amax ) then


                      iBin  = tointeger ((Lat(i,j)-latS)/dlat)
                      ;print ( i + " " + j + " " + A  + " " + iBin + " " +   histoCount(iBin))               
                      histoDat(iBin,histoCount(iBin)) = A
                      histoCount(iBin) =  histoCount(iBin) + 1                     
                    end if   
                  ;end if  
                end if
              end if
              
            end do ;j
            
            
          end if ;numdays
        end if ;time

      end if ;numobs
      
    end do ;i
;..................................................................
;
;
    print ( histoCount )
    
    
    hist =  new((/nBin,5/),double) ; fill with minimum, 25th percentile, median, 
    ave  =  new((/nBin/),double) 
    
    print (var)

    do i = 0,nBin-2
      dat := histoDat(i,0:histoCount(i)-1)
      qsort(dat)
      dimt = dimsizes(dat)
      x25  = round(.25*dimt,3)-1     ; -1 to account for NCL indexing starting
      x75  = round(.75*dimt,3)-1     ; at 0
      x10  = round(.1*dimt,3)-1     ; -1 to account for NCL indexing starting
      x90  = round(.9*dimt,3)-1     ; at 0
      xmed = dim_median(dat)
      ave(i) = avg(dat)
      sdev =     stddev(dat) 
      outString := (sprinti("%5i",histoCount(i) )  + " & " + sprintf("%5.2f",x(i)) + " & " +  sprintf("%5.2f",ave(i)) + " & " +  sprintf("%5.1f",xmed)  + " & " +  sprintf("%5.1f",sdev) + " \\")
      print  ( " " + outString ) 
      hist(i,:) = (/dat(x10),dat(x25),xmed,dat(x75),dat(x90)/)
      
    end do
    
;.............................................................................
    
    
    
    if ( var .eq. "accelSpeed" ) then
      res@tiMainString = "(b)"
      
      yTitle = "Tangential Acceleration (km/hr/day)"
      res@trYMinF =  -50.
      res@trYMaxF =   65.
    end if
    if ( var .eq. "accelCurve" ) then
      res@tiMainString = "(c)"     
      yTitle = "Curvature Acceleration (km/hr/day)"
      res@trYMinF =   0.
      res@trYMaxF =  90.
    end if
    
    if ( var .eq. "speed" ) then
      res@tiMainString = "(a)"
      res@trYMinF =   0.
      res@trYMaxF =  90.
      yTitle = "Speed (km/hr)"
    end if
    
    
    res@tiYAxisString =  yTitle
    res@tiXAxisString = "Center Latitude of Each Bin" 
    
    plot(ivar) = boxplot(wks,x(0:nBin-2),hist(0:nBin-2,:),False,res,False)
    mres               = True                     ; marker mods desired
    mres@gsMarkerIndex = 16                        ; polymarker style
    mres@gsMarkerSizeF = 4.                      ; polymarker size
    mres@gsMarkerColor = "gray"                    ; polymarker color
    dum(ivar) = gsn_add_polymarker(wks,plot(ivar),x(0:nBin-2),ave(0:nBin-2),mres) 
    
    
  end do ;ivar
; 
  resP                    = True                 ; modify the panel plot
  resP@gsnPanelMainString = ""     ; set main title
  resP@gsnPanelYWhiteSpacePercent = 5
  resP@gsnPanelXWhiteSpacePercent = 5
  gsn_panel(wks,plot,(/3,1/),resP)               ; now draw as one plot

   

  
end


