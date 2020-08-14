; A program to:
;
; Calculate the trend in TC acceleration/speed in latitude bands
; user specifies the width of the band and overlap
;
;
; calculates and outputs the linear trend and p-value 
; calculates and outputs the Thiel-Sen trend and Mann Kendall p-value
;
; Reads speed data from the file tcSpeed.nc
; That file was created by the code: tc_speed.ncl/tc_speed_accel_terrell.ncl
;
;
; code hierarchy:
;
; tc_speed.ncl ->reads ibtracs data and calculates speed along TC tracks
;     |          outputs tcSpeed.nc
;     |
;     trend_speed_ver1.ncl -> reads tcSpeed.nc and outputs trends
;
;     Units of trend: km/hr per year
;
;
;----------------------------------------------------------------------------
; NCSU Tropical Dynamics Group
;
; A. Aiyyer
; Oct 30, 2019
;----------------------------------------------------------------------------

begin
  
;=============================================================================
;=============================================================================  
; user inputs
  startYear = 1980
  endYear   = 2019
  nYears    = endYear - startYear + 1

; options  
  ;global = 1 ; 1 = global
  ;global = 2 ; 2 = nh
  ;global = 3 ; 3 = sh

  
  global = 0
  basinAnalysis = "NA" ;"WP" ;"NA"

;=============================================================================
;  end user inputs
;=============================================================================

  
  if (global .eq. 1 ) then
    checkBasin = 0
    basinAnalysis ="--"
    latS = -90.
    latN =  90.
    print ("global TC speed trend requested")
  end if
  
  if (global .eq. 2 ) then
    checkBasin = 0
    basinAnalysis ="--"
    latS =   0.
    latN =  90.
    print ("nh TC speed trend requested")
  end if

  
  if (global .eq. 3 ) then
    checkBasin = 0
    basinAnalysis ="--"
    latS =  -90.
    latN =    0.
    print ("sh TC speed trend requested")
  end if
  
  if (global .eq. 0 ) then
    checkBasin = 1 ;check for a specific basin 0 = NO 1 = Yes
    latS = -90.
    latN =  90.
    print ( "CheckBasin = " + checkBasin + " " + basinAnalysis)
  end if
  
;
  print ( "Start Year = " + startYear + " end year = " + endYear + " " + nYears)
; choose the latitude band


;--------------------------------------------------------------------------      
  fileName = "../tcSpeed.nc"
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
  dat   = fileIn->speed
  if ( dat@units .eq. "m/s" ) then
    dat = dat*3.6  ; km/hr
    dat@units = "km/hr"
  else
    print ("check units of speed! terminating code")
    exit
  end if
  

  time  = fileIn->time
  Lat   = fileIn->lat
  Lon   = fileIn->lon
  numobs      = fileIn->numobs
  nature      = fileIn->nature
  ;basin       = fileIn->basin
  dims        = dimsizes(time)
  nStorms     = dims(0)

  system ( "rm dat.nc")

  inr = 0
  print ("---------------------------------------------")
  datA   := new (800000,"double")
  icount = 0    
  yearly := new((/nYears,12000/),"double")
  ycount := new((/nYears/),"integer")
  ycount = 0
  yearly = yearly@_FillValue    
  ic = 0

  nrCount = 0
  totCount  = 0
  tsCount  = 0

; loop over storms  
  do i = 0,nStorms-1

    if ( numobs(i) .ge. 3 ) then
    
    numDays = todouble(time(i,numobs(i)-1) - time(i,0))
; storm must live at least 3 days
    
    if (  numDays .ge. 3 ) then      

      do j = 1, numobs(i)-2
        A = dat(i,j)      
; apply the relevant checks
;        basinId =  chartostring(basin(i,j,:))
               
; now see if we need to include this basin or not
               
        flag=1
        
        if ( flag .eq. 1 ) then ; proceed only if flag  = 1

          if ( time(i,0) .ge. startTime .and. time(i,numobs(i)-1) .le. endTime ) then
            if ( Lat(i,j) .ge. latS .and. Lat(i,j) .le. latN ) then
              
              if (.not.ismissing(A) ) then                                       

                totCount = totCount+1
                
                if ( chartostring(nature(i,j,:)) .eq. "NR" ) then
                  nrCount = nrCount + 1
                  date=cd_calendar(time(i,j),-5)
                  iy = date(0,0)
                                ;print ( "NR " + iy + " " + i + " " + j + " " + A )
                end if
                if ( chartostring(nature(i,j,:)) .eq. "TS" ) then
                  tsCount = tsCount + 1
                end if
                
                ;;if ( chartostring(nature(i,j,:)) .eq. "TS" ) ;.or. chartostring(nature(i,j,:)) .eq. "NR") then
                  datA(icount) = A
                  icount = icount + 1
                  date=cd_calendar(time(i,j),-5)
                  iy = date(0,0)-startYear
                  yy = date(0,0)
                  ii = ycount(iy)
                  yearly(iy,ii) = A
                  ycount(iy) =  ycount(iy) + 1
                ;;end if ; nature
                
              end if  
            end if
          end if
          
        end if ; iflag
        
      end do ; loop over j
    end if  ;numObs

  end if
  
  end do
  
  ave = avg( datA(0:icount-1) )
  std = stddev(datA(0:icount-1) )
  med = dim_median( datA(0:icount-1) )
  
  ave = ave ;km/hr
  std = std ;km/hr
  med = med ;km/hr
  print ( "Lat range " + latS + " " + latN + " Mean Median Sdev = " + ave + " " + med + " " +  std)
  print ( "tot count=" + totCount + " NR count ="+nrCount + " TS count ="+ tsCount + " icount = " + icount )

    
    
  datY := new(nYears,"double") 
  datC := new(nYears,"double") 
  x    := ispan(startYear,endYear,1) * 1.0

;
  do iy=0,nYears-1
    icc = ycount(iy)
    if ( icc .gt. 0 ) then
           ave :=  dim_avg_n(yearly(iy,0:icc-1),0)
           med := dim_median(yearly(iy,0:icc-1))
           datY(iy) = ave ; km/hr 
         else
           ave := datY@_FillValue   ;should be missing
           med := datY@_FillValue   ;should be missing
         end if
         datC(iy) = icc*1.0
       end do

       
       ;print ( datY + " " + datC )
       ;printVarSummary(datY)
       
; write out the yearly data       
       ncdf = addfile("dat.nc" ,"c")  ; open output netCDF file
       ncdf->ave=datY
       ncdf->count=datC
       ncdf->startYear=startYear
         ncdf->endYear=endYear

;=================================================================================    
       sigr = 0.05                        ; critical sig lvl for r
       df = equiv_sample_size (datY, sigr,0)
       

       if(any(ismissing(datY))) then
         print("Your data contains some missing values. Beware.")
       end if
       print ( "df = " + df )
       opt  = False
       pt   = trend_manken(datY, opt, 0) 

       pt(0) = 1. - pt(0)

       trend =  pt(1)
       signi =  pt(0)
       print ("MK trend and prob dat = " + pt(1) + " " + pt(0) )    


       
; calculate the regression coefficient (slope)    
       y = datY
       rc    = regline(x, y)          ; slope           
       rc@units = " "           
       ;df   = rc@nptxy-2
       prob =      betainc(df/(df+rc@tval^2), df/2.0, 0.5)
       print("rc trend and prob = " + rc + " " + prob)
       trendL =  rc
       signiL =  prob


;
; formatted output that we can insert into the latex document
;
       
outString := ( sprinti("%2i",tointeger(latS))  + "--" + sprinti("%2i",tointeger(latN))  + " & " +  sprintf("%6.3f",trendL) + " & " +  sprintf("%4.2f",signiL)  + " & " +  sprintf("%6.3f",trend) + " & " +  sprintf("%4.2f",signi) + "\\")

print  ( " " + outString ) 


print ("Normal code termination")    
;-------------------------------------------------------------------------------------------

    
end

