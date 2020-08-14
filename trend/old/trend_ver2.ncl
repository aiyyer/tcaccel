; a program to:
;
;
; Calculate the trend in TC acceleration/speed in latitude bands
; user specifies the width of the band and overlap
;
;
; NCSU Tropical Dynamics Group
;
;----------------------------------------------------------------------------

begin
  
; user inputs


  startYear = 1970
  endYear   = 2017
  nYears    = endYear - startYear + 1
  basinAnalysis = "NA"
  title = basinAnalysis  
  ytitle = "TC motion (Acceleration)"

;
; set some thresholds for defining spuriously large values
; values in m/s per day
;

  xmax   =  30.
  xmin   = -1.*xmax

;----------Change this number to test the sensitivity
  sfac   =  1.5

  print ( "Start Year = " + startYear + " end year = " + endYear)
  print ( "sfac = " + sfac)

; choose the latitude band
  latS = 10. ; 5.0
  dlat = 10. ;10.0
  latN = latS + dlat    
  nn   = 7
  clat  = new(nn,"float")
  trend = new(nn,"float")
  signi = new(nn,"float")

;--------------------------------------------------------------------------      
  fileName = "../dat/tcAccel.nc"
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
  dat   = fileIn->accel
  time  = fileIn->time
  Lat   = fileIn->lat
  Lon   = fileIn->lon
  numobs      = fileIn->numobs
  nature      = fileIn->nature
  basin       = fileIn->basin
  dims        = dimsizes(time)
  nStorms     = dims(0)


  
;======================================================================================  
  do imain = 0,nn-1
    print ("---------------------------------------------")
    

; first establish some basic stats for this lat-bin
; create array to store all accel data for some more stats
    datA   := new (100000,"float")
    icount = 0
    
; loop over storms  
    do i = 0,nStorms-1
      numDays = tofloat(time(i,numobs(i)-1) - time(i,0))
;   storm must live at least 3 days
;    
      if (  numDays .ge. 3 ) then      
        do j = 1, numobs(i)-2
          A = dat(i,j)      
; apply the relevant checks
          
          if ( chartostring(basin(i,j,:)) .eq. basinAnalysis) then
            if ( time(i,0) .ge. startTime .and. time(i,0) .le. endTime ) then
              if ( Lat(i,j) .ge. latS .and. Lat(i,j) .le. latN ) then                
                if ( chartostring(nature(i,j,:)) .eq. "TS" ) then ; .or. chartostring(nature(i,j,:)) .eq. "NR") then
                  
; ignore spuriously large values of accel
; this is controlled by the xmax value                  
                  if (.not.ismissing(A) .and. abs(A) .le. xmax ) then                                     
                    datA(icount) = A
                    icount = icount + 1
                  end if
                end if
              end if
            end if
          end if
        end do
      end if
    end do
    ave = avg( datA(0:icount-1) )
    std = stddev(datA(0:icount-1) )
    med = dim_median( datA(0:icount-1) )
    print ( "Lat range " + latS + " " + latN + " Mean Median Sdev = " + ave + " " + med + " " +  std + " count = " + icount)
;
;=======================================================================================
;
    
; define the thresh    
    thresh =  sfac*std
    
    yearly := new((/nYears,40/),"float")
    ycount := new((/nYears/),"integer")
    ycount = 0
    yearly = yearly@_FillValue    
    ic = 0
    count  = 0.
    
; loop over storms  
    do i = 0,nStorms-1
      numDays = tofloat(time(i,numobs(i)-1) - time(i,0))
; storm must live at least 3 days
      
      if (  numDays .ge. 3 ) then
        
        amax = -99999.
        jmax = -9      
        
        
        do j = 1, numobs(i)-2
          A = dat(i,j)      
; apply the relevant checks
          
          if ( chartostring(basin(i,j,:)) .eq. basinAnalysis) then
            if ( time(i,0) .ge. startTime .and. time(i,0) .le. endTime ) then
              if ( Lat(i,j) .ge. latS .and. Lat(i,j) .le. latN ) then                
                if ( chartostring(nature(i,j,:)) .eq. "TS" ) then ; .or. chartostring(nature(i,j,:)) .eq. "NR") then
                  
; ignore spuriously large values of accel
; this is controlled by the xmax value                  
                  if (.not.ismissing(A) .and. abs(A) .le. xmax ) then
                    if (A .ge. thresh) then 

                      if ( A .gt. amax ) then

                        amax = A
                        jmax = j
                        dateMax = time(i,j)
                        date=cd_calendar(time(i,j),-5)
                        iy = date(0,0)
 
                        ;print ( iy + " " + i + " " + j + " " +  A + "  " + amax)
                
                      end if
                    end if
                    
                  end if
                end if
              end if
            end if
          end if
        end do ;end loop over track for this storm

        if (jmax .ne. -9 ) then
          count   = count + 1.
          date=cd_calendar(dateMax,-5)
          iy = date(0,0)-startYear
          ii = ycount(iy)
          yearly(iy,ii) = amax
          ycount(iy) =  ycount(iy) + 1
        end if
        
        
        
      end if
    end do
;
    datY := new(nYears,"float") 
    datC := new(nYears,"float") 
    x    := fspan(0,nYears-1,nYears) + startYear
;
    do iy=0,nYears-1
      icc = ycount(iy)
      if ( icc .gt. 0 ) then
           ave =  dim_avg_n(yearly(iy,0:icc-1),0)
           med = dim_median(yearly(iy,0:icc-1))
      else
        ave = datY@_FillValue   ;should be missing
        med = datY@_FillValue   ;should be missing
      end if
      datY(iy) = ave
      datC(iy) = icc*1.0
      print ( iy + " "  + datY(iy) + " "  + icc )
    end do

    
;=================================================================================    
    opt  = False
    pt   = trend_manken(datY, opt, 0) 
    
    if(any(ismissing(datY))) then
      print("Your data contains some missing values. Beware.")
    end if

    ;pt(1) = pt(1)*3600./1.e3 ; convert from m/s/day to km/hour/day
    print ("MK trend and prob dat = " + pt(1) + " " + pt(0) )    

    clat(imain)  = .5*(latS + latN)
    trend(imain) = pt(1)
    signi(imain) = pt(0)

    pt   = trend_manken(datC, opt, 0)
    print ("MK trend and prob cnt = " + pt(1) + " " + pt(0) )    

; calculate the regression coefficient (slope)    
    y = datY
    rc    = regline(x, y)          ; slope           
    rc@units = " "           
    df   = rc@nptxy-2
    prob = (1 - betainc(df/(df+rc@tval^2), df/2.0, 0.5) )
    print("rc trend and prob = " + rc + " " + prob)

    y = datC
    rc    = regline(x, y)          ; slope           
    rc@units = " "           
    df   = rc@nptxy-2
    prob = (1 - betainc(df/(df+rc@tval^2), df/2.0, 0.5) )
    print("rc trend and prob cnt = " + rc + " " + prob)
;-------------------------------------------------------------------------------------------




    
    latS = latS + dlat*.5
    latN = latN + dlat*.5

    
  end do

  exit

  
;************************************************
; plotting parameters
; This illustrates one approach. Overlays could also be used.
;************************************************
   wks  = gsn_open_wks("pdf","trend")             ; send graphics to PNG file
   
   res                     = True                   ; plot mods desired
   res@xyMarkLineModes     = (/"Lines","Lines"/)  ; choose which have markers
   res@xyMarkers           = 16                     ; choose type of marker 
   res@xyMarkerColor       = "red"                  ; Marker color
   res@xyMarkerSizeF       = 0.005                  ; Marker size (default 0.01)
   res@xyDashPatterns      = 1                      ; solid line 
   res@xyLineThicknesses   = (/1,3/)                ; set second line to 2
   res@tmYLFormat          = "f"                    ; not necessary but nicer labels 
   res@tiMainString        = "Output from regline"  ; title


   


   plotDat = new ( (/2,nn/),"float")
   plotDat(0,:) = trend
   plotDat(1,:) = signi



   plotDat(1,:) = where( (plotDat(1,:).lt.0.95), plotDat@_FillValue,plotDat(1,:))
   print (clat + " " + trend + " " + signi ) ; plotDat(0,:) + " " +   plotDat(1,:) )
   plot  = gsn_csm_xy (wks,clat,trend,res)           ; create plot




end

