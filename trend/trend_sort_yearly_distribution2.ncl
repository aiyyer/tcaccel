; a program to:
;


begin

  basinAnalysis = "NA"
  fileName = "../tcMotion.nc"
  startYear = 1966 
  endYear   = 2019
  variable = (/"speed","accelSpeed","accelCurve"/)
  
  ivar       =  1

  var = variable(ivar)
    
; choose the latitude band
  latS = 20. 
  latN = 40.
  
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
  ;printVarSummary(dat)

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
                   
                   if (.not.ismissing(A) .and. abs(A) .le. Amax ) then
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

; lets sort the data:

 sfac = .9
 yearlyThresh = yearly
 yearlyThresh = yearlyThresh@_FillValue
 
 datSorted := datA(0:icount-1)
 qsort(datSorted)
 print ( "Lat range " + latS + " " + latN + " Mean = " + avg(datSorted) )
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
                                ;print ( iy + " " + N )
   
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
                                ;print ( x(iy) + " " +   datY(iy) + " " + N )
 end do
 print ( "mean = " + avg(datY)  + " " + dim_avg_n_Wrap (dim_avg_n_Wrap(yearlyThresh,1),0) )
 
;=================================================================================    
 opt  = False
 pt   = trend_manken(datY, opt, 0) 
 pt(0) = 1.-pt(0)
 
 if(any(ismissing(datY))) then
   print("Your data contains some missing values. Beware.")
 end if
 print ("MK trend and prob dat = " + pt(1) + " " + pt(0) )    
 
 
;=======================================================================================

 delete(opt)

 
 nbins = 30
 opt               = True
 opt@bin_min = -60.
 opt@bin_max =  60.
 opt@nbins         = nbins
 

 nY = nYears
 dat2D = new( (/nbins,nY/), typeof(yearly) )
 dat2D@_FillValue = yearly@_FillValue
 dat2D = dat2D@_FillValue
 
 ii = 0
  do iy = 0,nYears-1
    dat := yearly(iy,0:ycount(iy)-1)
    dpdf       := pdfx(dat,nbins, opt)
    dat2D(:,ii) = dpdf * dimsizes(dat) *.01
    ii=ii+1
  end do
  
  years = ispan (startYear,endYear,1)
  datTS = new ( (/2,nbins/), typeof(dat2D) )
  datTS(0,:) = dat2D(:,0)
  datTS(1,:) = dat2D(:,ii-1)
  
  dat2D!0    = "bins"
  dat2D&bins = dpdf@bin_center

  dat2D!1     = "years"
  dat2D&years = years

  
  wks  = gsn_open_wks ("png","pdf")             ; send graphics to PNG file
  res  = True
  res@xyLineThicknessF       = 2
  res@tiYAxisString          = "PDF (%)"
  plot = gsn_csm_xy (wks, dpdf@bin_center, datTS, res)


 

  

  
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
  res@cnMinLevelValF  = -100.                       ; set the minimum contour level
  res@cnMaxLevelValF  =  100.                       ; set the maximum contour level
  res@cnLevelSpacingF =  10.                 ; set the interval between contours
  res@gsnContourNegLineDashPattern   = 1       ; sets negative contours to dash pattern 1
  res@gsnContourZeroLineThicknessF = 2.	       ; doubles thickness of zero contour

  dat2DAve = dim_avg_n_Wrap(dat2D,1)
  dat2D    = dat2D - conform(dat2D,dat2DAve,0)
  plot = gsn_csm_contour(wks,dat2D,res)
  draw(plot)
  frame(wks)
end

