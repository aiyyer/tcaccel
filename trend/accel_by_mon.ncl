; a program to:
;
;=====================================================================
; extract the acceleration data and create a file with yearly
; values
;======================================================================
; Nov 9, 2020
;----------------------------------------------------------------------

begin

  basinAnalysis = "NA" 
  fileName = "../tcMotion.nc"
  startYear = 1966
  endYear   = 2019
  variable = (/"speed","accelSpeed","accelCurve"/)


;=============================================================================    
  ivar       =   2
  latS = 20.
  latN = 40.
;=============================================================================  

  var = variable(ivar)  
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



  monthly_ave       = new( (/2,12/),typeof(dat))
  monthly_count = new( (/2,12/) ,"float")
  monthly_count = 0.0
  monthly_ave   = 0.0

;===================================================================== 
; first establish some basic stats for this lat-bin
; create array to store all accel data for some more stats
  datA     := new (25000,"double")
  datA@_FillValue = dat@_FillValue
  
  icount    = 0
  nrCount   = 0
  totCount  = 0
  tsCount   = 0
  etCount   = 0
  
  datA   = datA@_FillValue
  dateA  = datA


  yearly := new((/nYears,20000/),"double")
  ycount := new((/nYears/),"integer")
  yearly@_FillValue = dat@_FillValue
  ycount = 0
  yearly = yearly@_FillValue
  

  
  ic     = 0
  count  = 0.
  stormCount = 0
  
; loop over storms  
    do i = 0,nStorms-1
      
      if ( numobs(i) .gt. 0 ) then
        if ( time(i,0) .ge. startTime .and. time(i,numobs(i)-1) .le. endTime ) then
          numDays = todouble(time(i,numobs(i)-1) - time(i,0))        
          
;   storm must live at least 1 days
          if (  numDays .ge. 3 ) then          
            stormCount = stormCount + 1            
            do j = 0, numobs(i)-1
              
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
                    
                    if (.not.ismissing(A)) 
                      tsCount        = tsCount + 1
                      datA(icount)   = A
                      dateA(icount)  = time(i,j)
                      icount = icount + 1
                      date=cd_calendar(time(i,j),-5)
                      iy = date(0,0)-startYear

                      im =  date(0,1)   - 1


                      if ( im .eq. 0 ) then
                        ;print ( im + " " + cd_calendar(time(i,j),-3) )
                      end if
                      if ( A .lt. 0. ) then
                        monthly_count(0,im) = monthly_count(0,im) + 1.0
                        aa = monthly_count(0,im)
                        monthly_ave(0,im) = monthly_ave(0,im)*(aa-1.)/aa +  A/aa
                      end if
                      if ( A .ge. 0. ) then
                        monthly_count(1,im) = monthly_count(1,im) + 1.0
                        aa = monthly_count(1,im)
                        monthly_ave(1,im) = monthly_ave(1,im)*(aa-1.)/aa +  A/aa
                      end if
                      
                      ii = ycount(iy)
                      yearly(iy,ii) = A
                      ycount(iy) =  ycount(iy) + 1
                      
                    end if ;A
                  
                  
                end if ; nature
;-------------------------------------------------------------------------
                
              end if ; lat
              
            end if  ;basin
            
            
          end do ; j
        end if ;numdays
      end if ;time
      
    end if ;numobs 
  end do ;i
  

  print ( "icount = " + icount)
  ave =    avg(datA(0:icount-1) )
  std = stddev(datA(0:icount-1) )
  med = dim_median( datA(0:icount-1) )
  print ( "Lat range " + latS + " " + latN + " Mean Median Sdev = " + ave + " " + med + " " +  std)
  
  NRper = tofloat(nrCount*100)/tofloat(totCount)
  TSper = tofloat(tsCount*100)/tofloat(totCount)
  ETper = tofloat(etCount*100)/tofloat(totCount)
  
  print ( "tot count=" + totCount + " NR count="+nrCount + " NR per="+ NRper)
  print ( "tot count=" + totCount + " TS count="+tsCount + " ts per="+ TSper)
  print ( "tot count=" + totCount + " ET count="+etCount + " ET per="+ ETper)
  sumP = TSper+NRper+ETper
  print ( "Sum should be 100 " +sumP ) 


;=======================================================================================



  month = fspan(1,12,12) 
  print ("---------------------------------------------------------------------------------------------------")
  print ( month + " " + monthly_count(0,:) + " " + monthly_ave(0,:)  + " " +  monthly_count(1,:) + " " + monthly_ave(1,:))
  print ("---------------------------------------------------------------------------------------------------")

 
  
  sumN = sum(monthly_count(0,:))
  monthly_count(0,:) =  monthly_count(0,:)*100./sumN
  sumP = sum(monthly_count(1,:))
  monthly_count(1,:) =  monthly_count(1,:)*100./sumP


  
;=======================================================================================
     wks = gsn_open_wks("png","monthly")          ; send graphics to PNG file
     sres = True
     sres@vpWidthF = 0.7
     sres@vpHeightF = 0.5
     sres@vpXF = .15
     sres@gsnFrame = False
     sres@trXMinF = 3.5
     sres@trXMaxF = 11.5
     sres@trYMinF = -25.
     sres@trYMaxF =  25.
     sres@gsnYRefLine           = 0.              ; reference line   


     sres@gsnXYBarChartBarWidth = 0.55           ; change bar widths
     sres@tmXBValues        = (/1,2,3,4,5,6,7,8,9,10,11,12/)
     sres@tmXBLabels = (/" "," ","  ","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov"," "/)
     sres@tmXBMode          = "Explicit"         ; explicit labels

     sres@tmXBLabelFontHeightF = 0.0205
     sres@tmXTLabelFontHeightF = 0.0205
     sres@tmYLLabelFontHeightF = 0.0225
     sres@tiMainFontHeightF = 0.025
     sres@tiYAxisString       = "Tangential Acceleration"

     sres@tiYAxisString       = "Curvature Acceleration"


     xyres   = sres 
     xyres@gsnXYBarChart = False
     xyres@trYMinF = 0.
     xyres@trYMaxF = 40.
;---Set a title on right Y axis.
     xyres@tiYAxisString       = "N (%)"
     xyres@tiYAxisSide         = "Right"
     
;     xyres@gsnYRefLine           = 0               ; Draw horiz line at y=20
;     xyres@gsnYRefLineColor      = "orange"
;     xyres@gsnYRefLineThicknessF = 4.0
     ;---Turn off bottom, top, and left tickmarks
     xyres@tmXBOn              = False
     xyres@tmXTOn              = False
     xyres@tmYLOn              = False
     xyres@tmYROn              = True
     xyres@tmYRLabelsOn        = True
     xyres@xyLineThicknessF    = 4.0               ; default is 1.0
     xyres@xyMarkLineModes   = "Markers"                ; choose which have markers
     xyres@xyMarkers         =  16                      ; choose type of marker  
     xyres@xyMarkerColor     =   "orange"                   ; Marker color


     sres@gsnXYBarChart = True
     sres@gsnXYBarChartColors = (/"red"/)	
     plot1 = gsn_csm_xy(wks,month(3:10),monthly_ave(1,3:10),sres)		; draw each time series
     sres@gsnXYBarChartColors = (/"lightblue"/)					; seperately, not     
     plot2 = gsn_csm_xy(wks,month(3:10),monthly_ave(0,3:10),sres)		; draw each time series



;---Add some text strings to indicate the N values.
     txres = True
     txres@txFontHeightF = 0.012
     ;txres@txPerimOn     = True
     ;txres@txBackgroundFillColor = "white"


     do id = 3,10       
       labelStr = sprintf( "%3.1f",monthly_count(1,id) )
       print ( labelStr + " " + tofloat(month(id)) + " " + tofloat(monthly_ave(1,id)))
       idA = gsn_add_text(wks,plot1,labelStr,tofloat(month(id)),tofloat(monthly_ave(1,id)+2.0), txres)

       labelStr = sprintf( "%3.1f",monthly_count(0,id) )
       print ( labelStr + " " + tofloat(month(id)) + " " + tofloat(monthly_ave(0,id)))
       idA = gsn_add_text(wks,plot1,labelStr,tofloat(month(id)),tofloat(monthly_ave(0,id)-2.0), txres)


       
     end do
     

     getvalues plot1
     "vpXF"      : vpx
     "vpYF"      : vpy
     "vpWidthF"  : vpw
     "vpHeightF" : vph
     end getvalues
;
; Make sure XY curve is drawn in same viewport space as bar plot
; Note there is no attempt to mathematically map the left and 
; right Y axis to each other. 
;
     xyres@vpXF      = vpx
     xyres@vpYF      = vpy
     xyres@vpWidthF  = vpw
     xyres@vpHeightF = vph
     



     ;;xy_plot = gsn_csm_xy (wks,month(3:10),monthly_count(1,3:10),xyres)


     xyres@xyMarkerColor     =   "black"                   ; Marker color

     ;;xy_plot = gsn_csm_xy (wks,month(3:10),monthly_count(0,3:10),xyres)

;
; The default behavior of gsn_add_annotation is is to add one 
; plot to the dead center of the other. We don't need to 
; set any "annotation" resources here.
;
;     anno_id  = gsn_add_annotation(bar_plot, xy_plot, False)
     
;
; "maximize_output" will resize graphics to maximize them
; on the page. This is necessary so that right Y axis
; labels don't run off the page.
;
  pres             = True
  pres@gsnMaximize = True
  maximize_output(wks,pres)
  
     

;=======================================================================================

  
  print (" " )
  print (" " )
  

end

