;============================================================================================
; a program to: read the acceleration data and plot Cumulative distribution 
;
;============================================================================================


begin

  basinAnalysis = "NA"
  fileName = "../tcMotion.nc"
  startYear = 1966 
  endYear   = 2019
  variable = (/"speed","accelSpeed","accelCurve"/)
  ivar       =  0
  var = variable(ivar)
    
; choose the latitude band
  latS = 0. 
  latN = 90.
  sfac = 0 ;.9

  
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

   datA = datA@_FillValue
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
         
;   storm must live at least 3 days
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
                   
                   if (.not.ismissing(A) ) ;.and. abs(A) .le. Amax ) then
                                ;print ( i + " " + j + icount + " " + A(icount) )
                     tsCount        = tsCount + 1
                     datA(icount)   = A
                     icount = icount + 1
                     date=cd_calendar(time(i,j),-5)
                     iy = date(0,0)-startYear                   
                     ii = ycount(iy)
                     yearly(iy,ii) = A
                     ycount(iy) =  ycount(iy) + 1
                   else
                     date=cd_calendar(time(i,j),-5)
                     print ( i + " " + j + " " +  A + " " + date(0,0))
                     
                   end if ;Amax
                                     
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
  else        
    opt@bin_min = -120.
    opt@bin_max =  120.
  end if
  
  opt@nbins   = nbins
  


  ic = 0
  do j = 0,nYears-1
    if ( ic .eq. 0 )
      dat := yearly(j,0:ycount(j)-1)
    else
      dat :=   array_append_record(dat,yearly(j,0:ycount(j)-1),1)
    end if
    ic = ic + 1
  end do

  dpdf       := pdfx(dat,nbins,opt)


; a new array to hold all of the pdfs
  datTS = new ( (/4,nbins/), typeof(dat) )
  datTS = datTS@_FillValue


; The pdf of the entire period   
  datTS(0,:) = dpdf




;=================================================================================
; NOw pdf of selected epochs
  dY = 4
  nY = nYears - dY
  print ("nY = " + nY)
  dat2D = new( (/nbins,nY/), typeof(yearly) )
  dat2D@_FillValue = yearly@_FillValue
  dat2D = dat2D@_FillValue
  ii = 0
  do iy = dY/2,nYears-dY/2-1
    iy1 = iy-dY/2
    iy2 = iy+dY/2
    ic = 0
    do j = iy1,iy2
      if ( ic .eq. 0 )
        dat := yearly(j,0:ycount(j)-1)
      else
        dat :=   array_append_record(dat,yearly(j,0:ycount(j)-1),1)
      end if
      ic = ic + 1
    end do
    ;print ( "******i" + ic + " " + avg(dat) + " " +dimsizes(dat) + " " + min(dat) + " " + max(dat) )     
    ;print ( iy + " " + iy1 + " " + iy2 + " " + ii)
    dpdf       := pdfx(dat,nbins, opt)
    dat2D(:,ii) = dpdf ;* dimsizes(dat) *.01
    ii = ii+1
  end do
  years = ispan (startYear+dY/2,endYear-dY/2,1)  
  datTS(1,:) = dat2D(:,0)
  datTS(2,:) = dat2D(:,ii/2)
  datTS(3,:) = dat2D(:,ii-1)

;=================================================================================

; convert to cdf

  datCU = datTS
  datCU = datC@_FillValue
  
  do k = 0,3
    datCU(k,0) = datTS(k,0)    
    do ibin = 1,nbins-1
      datCU(k,ibin) = sum( datTS(k,0:ibin) )
    end do
  end do



  
  dat2D!0    = "bins"
  dat2D&bins = dpdf@bin_center
  dat2D!1     = "years"
  dat2D&years = years

  
  wks  = gsn_open_wks ("png","pdf")             ; send graphics to PNG file
  res  = True
  res@xyLineThicknessF       = 2
  res@tiYAxisString          = "PDF (%)"
  res@xyExplicitLegendLabels = (/"0","1","2","3","4"/)         ; create explicit labels
  res@pmLegendDisplayMode    = "Always"            ; turn on legend
  res@pmLegendSide           = "Top"               ; Change location of 
  res@pmLegendParallelPosF   = .22                  ; move units right
  res@pmLegendOrthogonalPosF = -0.18                ; move units down
  res@pmLegendWidthF         = 0.12                ; Change width and
  res@pmLegendHeightF        = 0.10                ; height of legend.
  res@lgPerimOn              = False               ; turn off box around
  res@lgLabelFontHeightF     = .013                 ; label font height



  
  ;plot = gsn_csm_xy (wks, dpdf@bin_center, datTS, res)
  plot = gsn_csm_xy (wks, dpdf@bin_center, datCU(1:3,:), res)


;=================================================================================
  
  
  delete(res)
  delete(wks)
  
  wks  = gsn_open_wks("png","conwomap")    ; send graphics to PNG file
  gsn_define_colormap(wks,"MPL_PRGn") ;

  
;---Set some resources for color contour lines
  res                  = True
  
  
  res@gsnDraw          = False   ; don't draw yet
  res@gsnFrame         = False   ; don't advance frame yet

  res@cnFillOn            = True          ; turn on color
  res@vpWidthF            = 0.5           ; change aspect ratio of plot
  res@vpHeightF           = 0.3

  res@gsnMaximize         = True          ; maximize plot size

  res@cnLinesOn            =  True 
  res@cnMinLevelValF  = 0.                       ; set the minimum contour level
  res@cnMaxLevelValF  = 40.                       ; set the maximum contour level
  res@cnLevelSpacingF =  2.                 ; set the interval between contours
  res@gsnContourNegLineDashPattern   = 1       ; sets negative contours to dash pattern 1
  res@gsnContourZeroLineThicknessF = 2.	       ; doubles thickness of zero contour

;  dat2DAve = dim_avg_n_Wrap(dat2D,1)
;  dat2D    = dat2D - conform(dat2D,dat2DAve,0)

  dat2D=dat2D*1.e-3
  
  plot = gsn_csm_contour(wks,dat2D,res)
  draw(plot)
  frame(wks)












  
end

