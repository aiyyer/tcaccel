;============================================================================================
; a program to: read the speed acceleration data and plot Cumulative distributions
; in a multipanel format
;
;
;
; NCSU Large Scale Dynamics Group
; A. Aiyyer
; Nov 20, 2020
;============================================================================================


begin

  basinAnalysis = "NA"
  fileName = "../tcMotion.nc"
  startYear = 1966 
  endYear   = 2019
  latS = 0. 
  latN = 90.
  titleString = " " 


  mon1 = 1
  mon2 = 12
  rightTitle = "Full Year"
  label  = (/"(a)","(b)","(c)"/)
  variable = (/"speed","accelSpeed","accelCurve"/)
  accTitle = (/"Speed","Tangential Acceleration","Curvature Acceleration"/)
  yaxisTitle = "Cumulative Probability"
  
  nYears    = endYear - startYear + 1
  print ( "Start Year = " + startYear + " end year = " + endYear + " " + nYears)
 
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


  basin = fileIn->basin  
  time  = fileIn->time
  Lat   = fileIn->lat
  Lon   = fileIn->lon
  numobs      = fileIn->numobs
  nature      = fileIn->nature
  dims        = dimsizes(time)
  nStorms     = dims(0)
  


;----------------------------------------------------------------------------------

;===================================================================================
  wks  = gsn_open_wks ("png","cdf")             ; send graphics to PNG file
  res  = True
  res@tiMainString           = titleString
  
  res@pmLegendDisplayMode    = "Always"            ; turn on legend
  res@pmLegendSide           = "Top"               ; Change location of
  
 
  res@pmLegendWidthF         = 0.12                ; Change width and
  res@pmLegendHeightF        = 0.10                ; height of legend.
  res@lgPerimOn              = False               ; turn off box around
  res@lgLabelFontHeightF     = .013                 ; label font height
  res@xyLineColors= (/"purple", "orange","black"/)        ; set polymarker color
  res@xyLineThicknessF = 3.0                       ; thickness of lines
  
  ;res@trXMinF  = minX                  ; min value on y-axis
  ;res@trXMaxF  = maxX                   ; max value on y-axis
  
  
  res@gsnDraw             =  False       ; Don't draw plots
  res@gsnFrame            =  False       ; Don't advance frame
  

  plot = new(3,"graphic")

;===================================================================================



;----------------------------------------------------------------------------------







  yaxisTitle = "Cumulative Probability"

  do ivar = 0,2
    var = variable(ivar)
    res@tiXAxisString          = accTitle(ivar)
    leftTitle   = label(ivar) + " Entire Atlantic"
    
    
    
    print ( "ivar = " + ivar + " " + var) 
    
    if ( ivar .eq. 0 ) then
      accTitle = "Translation Speed"
      minX =  0.
      maxX =  80.
      LegParPos =  0.22
      LegOrtPos = -0.30
    end if
    if ( ivar .eq. 1 ) then
      accTitle = "Tangential Acceleration"
      minX = -80.
      maxX =  80.
      LegParPos =  0.22
      LegOrtPos = -0.30
    end if
    
    if ( ivar .eq. 2 ) then
      accTitle = "Curvature Acceleration"
      minX = 0.
      maxX = 80.
      LegParPos = 0.80  
      LegOrtPos = -1.1
    end if
    
    dat := fileIn->$var$
    dat@name = var
    if ( var .eq. "speed"  .or. var .eq. "speedIB" ) then
      Amax = 30.*3.6
      if ( dat@units .eq. "m/s" ) then
        dat := dat*3.6 ; now km/hr per day
        dat@units = "km/hr" 
      else
        print ("Units unexpected! Terminating code!")
        exit
      end if
    end if  
    if ( var .eq. "accelSpeed" .or. var .eq.  "accelCurve" ) then
      Amax = 120.*3.6
      if ( dat@units .eq. "m/s per day" ) then
        dat := dat*3.6 ; now km/hr per day
        dat@units = "km/hr per day" 
      else
        print ("Units unexpected! Terminating code!")
        exit
      end if
    end if
    

; first establish some basic stats for this lat-bin
; create array to store all accel data for some more stats
    datA     := new (40000,"double")
    datA@_FillValue = dat@_FillValue
    icount    = 0
    nrCount   = 0
    totCount  = 0
    tsCount   = 0
    etCount   = 0
    datA      = datA@_FillValue
    stormCount= 0

; loop over storms  
    do i = 0,nStorms-1
      if ( numobs(i) .gt. 0 ) then
        if ( time(i,0) .ge. startTime .and. time(i,numobs(i)-1) .le. endTime ) then
          numDays = todouble(time(i,numobs(i)-1) - time(i,0))        
;   storm must live at least 3 days
          if (  numDays .ge. 3 ) then          
            stormCount = stormCount + 1
            do j = 0, numobs(i)-1
              date=cd_calendar(time(i,j),-5)
              month = date(0,1)
              if (month .ge. mon1 .and. month .le. mon2 ) then
              if ( basin(i,j) .eq. basinAnalysis ) then
                A = dat(i,j)              
; apply the relevant checks
                
                if ( Lat(i,j) .ge. latS .and. Lat(i,j) .le. latN ) then  
                  totCount = totCount+1
                  
                  if ( chartostring(nature(i,j,:)) .eq. "NR" .or. chartostring(nature(i,j,:)) .eq. "MX") then
                    nrCount = nrCount + 1
                  end if
                  if ( chartostring(nature(i,j,:)) .eq. "ET" ) then
                    etCount = etCount + 1
                  end if

;-------------------------------------------------------------------------                
                  if ( chartostring(nature(i,j,:)) .ne. "ET" .and.  chartostring(nature(i,j,:)) .ne. "NR" ) then
                    
                    if (.not.ismissing(A) )
                      tsCount        = tsCount + 1
                      datA(icount)   = A
                      icount = icount + 1
                 
                    end if ;Amax
                    
                  end if ; nature
;-------------------------------------------------------------------------
                  
                end if ; lat
                
              end if  ;basin
              end if
              
            end do ; j
          end if ;numdays
        end if ;time
        
      end if ;numobs 
    end do ;i
    
    
    print ( "icount = " + icount)
    ave =    avg(datA(0:icount-1) )
    std = stddev(datA(0:icount-1) )
    med = dim_median( datA(0:icount-1) )
    
    print ("pre sorting")
    print ( "Lat range " + latS + " " + latN + " Mean Median Sdev = " + ave + " " + med + " " +  std)
    
    NRper = tofloat(nrCount*100)/tofloat(totCount)
    TSper = tofloat(tsCount*100)/tofloat(totCount)
    ETper = tofloat(etCount*100)/tofloat(totCount)
    
    print ( "tot count=" + totCount + " NR count="+nrCount + " NR per="+ NRper)
    print ( "tot count=" + totCount + " TS count="+tsCount + " ts per="+ TSper)
    print ( "tot count=" + totCount + " ET count="+etCount + " ET per="+ ETper)
    sumP = TSper+NRper+ETper
    print ( "Sum should be 100 " +sumP ) 



    datSorted := datA(0:icount-1)
    qsort(datSorted)
    print ( "Lat range " + latS + " " + latN )
    print ( " Mean = " + avg(datSorted) )
    print ( " Min/max = " + min(datSorted) + " " + max(datSorted) )
    npts = icount
    print ( "10th, 50th, 80th, 90th = " +  datSorted(tointeger(.1*npts)) + " " +  datSorted(tointeger(.5*npts))  + " " +  datSorted(tointeger(.8*npts))  + " " +  datSorted(tointeger(.9*npts)) )
    
; CDF 
    nbins       = 40
    opt         = True
    if ( ivar .eq. 0 ) then    
      opt@bin_min = 0.
      opt@bin_max = 80.
    end if
    
    if ( ivar .eq. 1 ) then    
      opt@bin_min = -120.
      opt@bin_max =  120.
    end if
    
    if ( ivar .eq. 2 ) then    
      opt@bin_min =  0.
      opt@bin_max =  80.
    end if
    
    
    pdf       := pdfx(datSorted,nbins,opt)

    ; convert to cdf
    
    cdf = pdf
    cdf(0) = pdf(0)    
    do ibin = 1,nbins-1
      cdf(ibin) = sum(pdf(0:ibin) )
    end do
    cdf = cdf/100.

 
    labels = startYear + "-" + endYear
    
    res@xyExplicitLegendLabels = labels
    res@tiYAxisString    =  yaxisTitle
    res@gsnLeftString    =  leftTitle             ; add the gsn titles
    res@gsnRightString   =  rightTitle            ; add the gsn titles
    res@pmLegendParallelPosF   = LegParPos                  ; move units right
     res@pmLegendOrthogonalPosF = LegOrtPos               ; move units down
     plot(ivar) = gsn_csm_xy (wks,cdf@bin_center,cdf, res)

end do ; ivar





resP                     = True                ; modify the panel plot    
resP@gsnPanelYWhiteSpacePercent = 0
resP@gsnPanelXWhiteSpacePercent = 0

gsn_panel(wks,plot,(/1,3/),resP) 






end