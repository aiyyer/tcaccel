;============================================================================================
; a program to: read the acceleration data and plot Cumulative distribution 
;
;============================================================================================


begin

  basinAnalysis = "NA"
  fileName = "../tcMotion.nc"
  startYear = 1966 
  endYear   = 2019

  mon1 = 8
  mon2 = 8
  rightTitle = "August"
  label  = (/"(a)","(b)","(c)"/)
  mon1 = 9
  mon2 = 9
  rightTitle = "September"
  label  = (/"(d)","(e)","(f)"/)
  mon1 = 10
  mon2 = 10
  rightTitle = "October"
  label  = (/"(g)","(h)","(i)"/)


  mon1 = 1
  mon2 = 12
  rightTitle = "ALL Months"
  label  = (/"(a)","(b)","(c)"/)
  mon1 = 8
  mon2 = 8
  rightTitle = "Aug"
  label  = (/"(a)","(b)","(c)"/)

  mon1 = 9
  mon2 = 9
  rightTitle = "Sep"
  label  = (/"(a)","(b)","(c)"/)

  mon1 = 10
  mon2 = 10
  rightTitle = "Oct"
  label  = (/"(a)","(b)","(c)"/)

  mon1 = 7
  mon2 = 7
  rightTitle = "Jul"
  label  = (/"(a)","(b)","(c)"/)

  
  mon1 = 7 
  mon2 = 10
  rightTitle = "JASO"
  label  = (/"(a)","(b)","(c)"/)


  
  variable = (/"speed","accelSpeed","accelCurve"/)
  sfac = .9
  titleString = " " 
  ivar       =  2
  
  var = variable(ivar)

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
;
  
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
  
  basin = fileIn->basin  
  time  = fileIn->time
  Lat   = fileIn->lat
  Lon   = fileIn->lon
  numobs      = fileIn->numobs
  nature      = fileIn->nature
  dims        = dimsizes(time)
  nStorms     = dims(0)

;===================================================================================
  wks  = gsn_open_wks ("png","pdf")             ; send graphics to PNG file
  res  = True
  res@tiMainString           = titleString
  res@tiXAxisString          = accTitle
  res@pmLegendDisplayMode    = "Always"            ; turn on legend
  res@pmLegendSide           = "Top"               ; Change location of
  
  res@pmLegendParallelPosF   = LegParPos                  ; move units right
  res@pmLegendOrthogonalPosF = LegOrtPos               ; move units down
  res@pmLegendWidthF         = 0.12                ; Change width and
  res@pmLegendHeightF        = 0.10                ; height of legend.
  res@lgPerimOn              = False               ; turn off box around
  res@lgLabelFontHeightF     = .013                 ; label font height
  res@xyLineColors= (/"purple", "orange","black"/)        ; set polymarker color
  res@xyLineThicknessF = 3.0                       ; thickness of lines
  
  res@trXMinF  = minX                  ; min value on y-axis
  res@trXMaxF  = maxX                   ; max value on y-axis
  
  
  res@gsnDraw             =  False       ; Don't draw plots
  res@gsnFrame            =  False       ; Don't advance frame
  

  plot = new(3,"graphic")

;===================================================================================
  do iPlot = 0,2


    
    yaxisTitle = " " 
    
    if ( iPlot .eq. 0 ) then
; choose the latitude band
      latS = 0. 
      latN = 90.
      leftTitle   = label(iPlot) + " Entire Atlantic"
       yaxisTitle = "Cumulative Probability"
    end if


    if ( iPlot .eq. 1 ) then
; choose the latitude band
      latS = 0. 
      latN = 20.
      leftTitle   =  label(iPlot) +  " 0-20N"
    end if
    
    if ( iPlot .eq. 2 ) then
; choose the latitude band
      latS = 20. 
      latN = 50.
      sfac = .9
      leftTitle   =  label(iPlot) +  " 20-50N"
    end if

    print ("---------------------------------------------------------------")
    print ( "Processing " + leftTitle)
    
;======================================================================================
; first establish some basic stats for this lat-bin
; create array to store all accel data for some more stats
    datA     := new (700000,"double")
    datA@_FillValue = dat@_FillValue
    icount    = 0
    nrCount   = 0
    totCount  = 0
    tsCount   = 0
    etCount   = 0
    datA      = datA@_FillValue
    yearly   := new((/nYears,20000/),"double")
    ycount   := new((/nYears/),"integer")
    yearly@_FillValue = dat@_FillValue
    ycount    = 0
    yearly    = yearly@_FillValue    
    ic        = 0
    count     = 0.
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
                    
                    if (.not.ismissing(A) ) ;.and. abs(A) .le. Amax ) then
                                ;print ( i + " " + j + icount + " " + A(icount) )
                      tsCount        = tsCount + 1
                      datA(icount)   = A
                      icount = icount + 1
                     
                      iy = date(0,0)-startYear                   
                      ii = ycount(iy)
                      yearly(iy,ii) = A
                      ycount(iy) =  ycount(iy) + 1
                 
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
;
;=======================================================================================
;
; lets sort the data and calculate trend - this is just a repeat of trend_sort.ncl
; the code here is just to make sure we can replicate the results from that code
;
    
    yearlyThresh = yearly
    yearlyThresh = yearlyThresh@_FillValue
    datSorted := datA(0:icount-1)
    qsort(datSorted)
    
    npts = tofloat(dimsizes(datSorted))
    nF  = tointeger(sfac*npts)
    thresh =  datSorted(nF)
    print ("sfac = " + sfac + " " +  npts + " " + nF + " thresh =  "+ thresh)
    yearlyThresh =  yearlyThresh@_FillValue
    yearlyThresh = where ( yearly .gt. thresh, yearly, yearly@_FillValue)
    datY := new(nYears,"double")  
    datY@_FillValue = yearlyThresh@_FillValue
    datC = datY 
    x    := fspan(0,nYears-1,nYears) + startYear
    do iy=0,nYears-1
      N = num(.not.ismissing(yearlyThresh(iy,:)))
      med     =   yearlyThresh@_FillValue
      datY(iy) =  yearlyThresh@_FillValue
      icc =  ycount(iy)
      if ( icc .gt. 0 ) then
        med     =    dim_median(yearlyThresh(iy,:))
        ave     =    avg(yearlyThresh(iy,:))
        datY(iy) =   ave
      else
        med     =   yearlyThresh@_FillValue
        datY(iy) =  yearlyThresh@_FillValue
      end if
    end do
    opt  = False
    pt   = trend_manken(datY, opt, 0) 
    pt(0) = 1.-pt(0)
    
    if(any(ismissing(datY))) then
      print("Your data contains some missing values. Beware.")
    end if
    print ("MK trend and prob dat = " + pt(1) + " " + pt(0) )    
;=======================================================================================
    
    
    print ( "Lat range " + latS + " " + latN )
    print ( " Mean = " + avg(datSorted) )
    print ( " Min/max = " + min(datSorted) + " " + max(datSorted) )
    print ( "10th, 50th, 80th, 90th = " +  datSorted(tointeger(.1*npts)) + " " +  datSorted(tointeger(.5*npts))  + " " +  datSorted(tointeger(.8*npts))  + " " +  datSorted(tointeger(.9*npts)) )
    
;=======================================================================================
    
    delete(opt)
    
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
    
    
    
    opt@nbins   = nbins
    firstTime = True
    do j = 0,nYears-1
      if ( ycount(j) .ne. 0 ) then
        if (firstTime) then
          tempDat := yearly(j,0:ycount(j)-1)
          firstTime = False
        else
          temDat :=   array_append_record(tempDat,yearly(j,0:ycount(j)-1),1)
        end if
      end if
    end do
    dpdf       := pdfx(tempDat,nbins,opt)
    
    
; a new array to hold all of the pdfs
    datTS = new ( (/4,nbins/), typeof(tempDat) )
    datTS = datTS@_FillValue
; The pdf of the entire period   
    datTS(3,:) = dpdf
    
    
    
    
;=================================================================================
; NOw pdf of selected epochs
    
    dY = 9
    yearToConsider = (/1966,1988,2010/)
    yearToConsider = yearToConsider - 1966
    labels = (startYear + yearToConsider) + "-" +  (startYear + yearToConsider + dY)
    
    do imain = 0,2      
      ii = 0
      iy1 = yearToConsider(imain)
      iy2 = iy1 + dY
      firstTime = True

      do j = iy1,iy2
        if ( ycount(j) .ne. 0 ) then
          if (firstTime) then
            tempdat := yearly(j,0:ycount(j)-1)
            firstTime = False
          else
            tempdat :=   array_append_record(tempdat,yearly(j,0:ycount(j)-1),1)
          end if
        end if
        ic = ic + 1
      end do
      print ( "******i" + ic + " " + avg(tempdat) + " " +dimsizes(tempdat) + " " + min(tempdat) + " " + max(tempdat) )     
      print ( iy + " " + iy1 + " " + iy2 + " " + ii)
      dpdf       := pdfx(tempdat,nbins, opt)
      
      ii = ii + 1
      datTS(imain,:) = dpdf
    end do
    
;=================================================================================
    
; convert to cdf
    
    datCU = datTS
    datCU = datC@_FillValue
    do k = 0,2
      datCU(k,0) = datTS(k,0)    
      do ibin = 1,nbins-1
        datCU(k,ibin) = sum( datTS(k,0:ibin) )
      end do
    end do
    datCU = datCU/100.
    datTS = datTS/100.


    res@xyExplicitLegendLabels = labels  
    res@tiYAxisString    =  yaxisTitle
    res@gsnLeftString    =  leftTitle             ; add the gsn titles
    res@gsnRightString   =  rightTitle            ; add the gsn titles

    ;histogram
    ;plot(iPlot)  = gsn_csm_xy (wks, dpdf@bin_center, datTS(0:2,:), res)

    ; CDF
    plot(iPlot) = gsn_csm_xy (wks, dpdf@bin_center, datCU(0:2,:), res)
end do

;=================================================================================
  
  



resP                     = True                ; modify the panel plot    
resP@gsnPanelYWhiteSpacePercent = 0
resP@gsnPanelXWhiteSpacePercent = 0

gsn_panel(wks,plot,(/1,3/),resP) 








  
end

