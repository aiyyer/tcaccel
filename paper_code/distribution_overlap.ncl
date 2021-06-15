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
;
; updated Sep 19 to use the single file for all basins/times
;----------------------------------------------------------------------------

begin


  fileName = "../tcMotion.nc"
  fileIn = addfile( fileName, "r" )
  
  variable = (/"speed","accelSpeed","accelCurve"/)
  basinAnalysis = "NA" 
  startYear = 1966
  endYear   = 2019
;  
; choose the latitude bands
;
;========================================================================
  latS     =  5.
  latN     =  55.
  binWidth =  10.
  dlat     =  5.0
  nBin     =  9

;========================================================================
;=======================================================================
  
  nmax     = 80000
  histoDat   = new ((/nBin,nmax/), "double" )
  histoCount = new (nBin, "integer" )
;
  lat1 = new ((/nBin/), "double" )
  lat2 = new ((/nBin/), "double" )
  x    = new ((/nBin/), "double" )
;
  do i=0,nBin-1
    lat1(i) = latS    + i*dlat
    lat2(i) = lat1(i) + binWidth
    cen = .5*(lat1(i) + lat2(i) )
  end do
  x =  .5*(lat1 + lat2)
;  
;--------------------------------------------------------------------------  
;
  wks = gsn_open_wks("png","distribution")       ; send graphics to PNG file
  res            = True                          ; plot mods desired
  plot = new(3,graphic)                          ; create a plot array
  dum  = new(3,graphic)                          ; create a plot array
;

;    
  time = fileIn->time
  Lat  = fileIn->lat
  Lon  = fileIn->lon
  basin = fileIn->basin
  numobs      = fileIn->numobs
  nature      = fileIn->nature
  dims        = dimsizes(time)
  nStorms     = dims(0) 
  print ("Number of Storms = " + nStorms)
  
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
  endTime   = cd_inv_calendar(endYear,12,31,23,0,0,time@units, 0)

  print ( cd_calendar(startTime,-3) + " " +  cd_calendar(endTime,-3) )

  
;
;...................................................
;

 outputText = new ((/nBin,3/), "string" )
  
  do ivar = 0,2
    print ( "IVAR = " + ivar)
; initialize arrays

    histoCount = 0
    histoDat   = histoDat@_FillValue
    var = variable(ivar)    
    dat := fileIn->$var$
    print ("Processing " + var )

    
    if ( var .eq. "speed" .or. var .eq. "speedIB") then
      Amax = 60.*3.6
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
      Amax = 60.*3.6
      if ( dat@units .eq. "m/s per day" ) then
        dat := dat*3.6 ; now km/hr per day
        dat@units = "km/hr per day" 
      else
        print ("Units unexpected! Terminating code!")
        exit
      end if
    end if
    
    title = " " 

    Ave   = todouble(0.)
    icc =   todouble(0.)

    stormCount = 0

;..................................................................
    do i = 0,nStorms-1
      sflag = 0
      
      if ( numobs(i) .ne. 0 ) then
        numDays = todouble(time(i,numobs(i)-1) - time(i,0))
        
;storm must live at least 3 days
        if (  numDays .ge. 3 ) then
          if ( time(i,0) .ge. startTime .and. time(i, numobs(i)-1) .le. endTime ) then
            
            do j = 0, numobs(i)-1

              if ( basin(i,j) .eq. basinAnalysis ) then

                if ( sflag .eq. 0 ) then
                  stormCount=stormCount+1
                  sflag = 1
                end if
                
                A= dat(i,j)
                
                if ( chartostring(nature(i,j,:)) .ne. "ET" .and. chartostring(nature(i,j,:)) .ne. "NR" ) then
                  
                  if ( (Lat(i,j) .ge. latS) .and. (Lat(i,j) .le. latN) ) 
                    
                    
; ignore spuriously large values of accel
; this is controlled by the xmax value
                    
                    if (.not.ismissing(A)) ;   .and. abs(A) .le. Amax ) then                      
                      
                      iBin=-9
                      do binJ = 0,nBin-1
                        if ( Lat(i,j) .ge. lat1(binJ) .and. Lat(i,j) .le. lat2(binJ) ) then
                                ;print ( Lat(i,j) + " found " + binJ + " " + lat1(binJ)  + " " +  lat2(binJ))
                          iBin =binJ
                          histoDat(iBin,histoCount(iBin)) = A
                          histoCount(iBin) =  histoCount(iBin) + 1
                        end if                          
                      end do ;binj
                      
                      Ave = Ave*icc/(icc+1.) + A/(icc+1.)
                      icc = icc + 1.
                      
                    end if ; A
                    
                  end if ;lat
                  
                end if ; nat

              end if ;basin
            
          end do ;j
          end if ;numdays
        end if ;time
      end if ;numobs
    end do ;i

;..................................................................
;
;
    print ("StormCount, Average = " + stormCount + " " + Ave + " " + icc)
    ;print ( histoCount )
    
    
    hist =  new((/nBin,5/),double) ; fill with minimum, 25th percentile, median, 
    ave  =  new((/nBin/),double) 
    
    ;print (var)

    do i = 0,nBin-1
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
                                ;outString := (sprintf("%5.2f",lat1(i)) +"--" + sprintf("%5.2f",lat2(i))  + " & " +     sprinti("%5i",histoCount(i) ) + " & " +  sprintf("%5.2f",ave(i)) + " & " +  sprintf("%5.1f",xmed)  + " & " +  sprintf("%5.1f",sdev) + " \\")
      outString := (sprintf("%2.0f",lat1(i)) +"--" + sprintf("%2.0f",lat2(i))  + " & " +     sprinti("%5i",histoCount(i) ) + " & " +  sprintf("%5.2f",ave(i)) + " & " +  sprintf("%5.1f",xmed)  + " & " +  sprintf("%5.1f",sdev) )
      
      
      print  ( " " + outString  + " \\" )

      if ( ivar .eq. 0 ) then
        outputText(i,ivar) = outString
      else
        outputText(i,ivar) = sprintf("%5.2f",ave(i)) + " & " +  sprintf("%5.1f",xmed)  + " & " +  sprintf("%5.1f",sdev)
      end if
      hist(i,:) = (/dat(x10),dat(x25),xmed,dat(x75),dat(x90)/)      
    end do
    
;.............................................................................
    
        
    if ( var .eq. "speed" ) then
      res@tiMainString = "(a) Speed"
      res@trYMinF =   0.
      res@trYMaxF =  90.
      yTitle = "(km/hr)"
    end if
    
    
    if ( var .eq. "accelSpeed" ) then
      res@tiMainString = "(b) Tangential Acceleration"
      yTitle = "Acceleration (km/hr/day)"
      res@trYMinF =  -50.
      res@trYMaxF =   65.
    end if

    
    if ( var .eq. "accelCurve" ) then
      res@tiMainString = "(c) Curvature Acceleration"     
      yTitle = "Acceleration (km/hr/day)"
      res@trYMinF =   0.
      res@trYMaxF =  90.
    end if

    
    res@tiYAxisString =  yTitle
    res@tiXAxisString = "Center Latitude of Each Bin" 
    
    ; plot the box and whisker plot
    plot(ivar) = boxplot(wks,tofloat(x(0:nBin-2)),tofloat(hist(0:nBin-2,:)),False,res,False)
    mres               = True                     ; marker mods desired
    mres@gsMarkerIndex = 16                        ; polymarker style
    mres@gsMarkerSizeF = 4.                      ; polymarker size
    mres@gsMarkerColor = "gray"                    ; polymarker color


;   add a dot to indicate the mean    
    dum(ivar) = gsn_add_polymarker(wks,plot(ivar),x(0:nBin-2),ave(0:nBin-2),mres) 
    
    
  end do ;ivar
; 
  resP                    = True                 ; modify the panel plot
  resP@gsnPanelMainString = ""     ; set main title
  resP@gsnPanelYWhiteSpacePercent = 5
  resP@gsnPanelXWhiteSpacePercent = 5
  gsn_panel(wks,plot,(/1,3/),resP)               ; now draw as one plot

   




  print ("====================================================================================")
  print ( " " + outputText(:,0) + " & " + outputText(:,1) + " & " + outputText(:,2) + " \\" )
end


