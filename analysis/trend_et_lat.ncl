; a program to:
;              calculate the trend in the latitude of ET completion
;              uses the tcMotion.nc file 
;
;
;-----------------------------------------------------------------------------
; NCSU Tropical Dynamics Group
; A. Aiyyer
; Oct 31, 2020
;.............................................................................
;   Input  -> tcMotion.nc 
;   Output ->
;-----------------------------------------------------------------------------
;
;-----------------------------------------------------------------------------
;
;



begin
;  
; user inputs
  startYear = 1966
  endYear   = 2019


  
  nYears    = endYear - startYear + 1
  basinAnalysis = "NA"   ;WP, NA...
;--------------------------------------------------------------------------      
  fileName = "../tcMotion.nc"
 
  nYears    = endYear - startYear + 1
  print ( "Start Year = " + startYear + " end year = " + endYear + " " + nYears)
  
; choose the latitude band
  latS = 0. 
  latN = 90.
;--------------------------------------------------------------------------      

  
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
; read the speeds  
  basin = fileIn->basin
  time  = fileIn->time
  Lat   = fileIn->lat
  Lon   = fileIn->lon
  numobs      = fileIn->numobs
  nature      = fileIn->nature
  dims        = dimsizes(time)
  nStorms     = dims(0)

  print ( "Num Storms in file process = " + nStorms)



  
  nn = 20
  latET = new( (/nYears,nn/), typeof(Lat) )
  lonET = new( (/nYears,nn/), typeof(Lon) )
  latET@_FillValue = -9999.0
  lonET@_FillValue = -9999.0
  latET = latET@_FillValue
  lonET = lonET@_FillValue

  ycount := new((/nYears/),"integer")
  ycount = 0
  

  
;  
;======================================================================================
; some counters
  
  icount    = 0
  nrCount   = 0
  totCount  = 0
  tsCount   = 0
  ETCount   = 0
  
    
;loop over storms  
    do i = 0,nStorms-1

;
;-----discard non TS storms and storms that form in basins other than what was requested.
;     
      TSFlag       = 0
      BasinFlag    = 0
      
      if (  basin(i,0) .eq. basinAnalysis ) then
        ;print ( i + " matches basin requested = " + basinAnalysis )
        BasinFlag = 1
      end if
      
      do j = 0, numobs(i)-1
        if ( chartostring(nature(i,j,:)) .eq. "TS" ) then
          TSFlag    = 1
        end if
      end do

; Now move forward with this storm
     
      if ( TSFlag .eq. 1 .and. BasinFlag .eq. 1 ) then

        numDays = todouble(0)
        if ( numobs(i) .ne. 0 ) then
          numDays = todouble(time(i,numobs(i)-1) - time(i,0))
        end if

;storm must live at least 3 days
        if (  numDays .ge. 3 ) then          
          if ( time(i,0) .ge. startTime .and. time(i,  numobs(i)-1) .le. endTime ) then
            
            totCount = totCount + 1                      
            ETflag = 0
            
            
            do j = 0, numobs(i)-1
              
; apply the relevant checks
              if ( ETflag .eq. 0 ) then
                if ( chartostring(nature(i,j,:)) .eq. "ET" ) then
                  date=cd_calendar(time(i,j),-5)
                  iy = date(0,0)-startYear                   
                  ii = ycount(iy)
                  
                  latET(iy,ii) = Lat(i,j)
                  lonET(iy,ii) = Lon(i,j)
                  ycount(iy) =  ycount(iy) + 1
                  
                  ETflag = 1
                   
                   
                 end if
               end if
                              
             end do ;j
             
             
           end if ;time
         end if ; numdays
       end if ; TSflag
       
       
     end do ;i
     
     print ("Qual Storm numbers = " + totCount)
     print ("ET Storm numbers = " + ETCount)
     perET = 100.*tofloat(ETCount)/tofloat(totCount)
     print ("Percent ET = " + perET)
     print ("Storm numbers for composit= " + icount)


     print ("Mean lat of ET = " + avg(latET) )
     ;print ("Median lat of ET = " +dim_median(latET) )
     
     
;====================================================================================================
     x = fspan(0,nYears-1,nYears) + startYear

     print ("------------Mean----------------------------------")

     
     yearlyLat = dim_avg_n(latET,1)
     opt  = False
     pt   = trend_manken(yearlyLat, opt, 0) 
     pt(0) = 1.-pt(0)
     
     if(any(ismissing(yearlyLat))) then
       print("Your data contains some missing values. Beware.")
     end if
     print ("MK trend and prob dat = " + pt(1) + " " + pt(0) )    
     
     
     
; calculate the regression coefficient (slope)
     rc    = regline(x, yearlyLat)          ; slope           
     rc@units = " "           
     
     
     sigr = 0.05                        ; critical sig lvl for r
     df = equiv_sample_size (yearlyLat, sigr,0)
     
     prob = betainc(df/(df+rc@tval^2), df/2.0, 0.5)    
     print("rc trend and prob = " + rc + " " + prob + " df = " + df)

;====================================================================================================
     print ("------------Median----------------------------------")

     yearlyLat = dim_median_n(latET,1)
     opt  = False
     pt   = trend_manken(yearlyLat, opt, 0) 
     pt(0) = 1.-pt(0)
     
     if(any(ismissing(yearlyLat))) then
       print("Your data contains some missing values. Beware.")
     end if
     print ("MK trend and prob dat = " + pt(1) + " " + pt(0) )    
     
     
     
; calculate the regression coefficient (slope)
     rc    = regline(x, yearlyLat)          ; slope           
     rc@units = " "           
     
     
     sigr = 0.05                        ; critical sig lvl for r
     df = equiv_sample_size (yearlyLat, sigr,0)
     
     prob = betainc(df/(df+rc@tval^2), df/2.0, 0.5)    
     print("rc trend and prob = " + rc + " " + prob + " df = " + df)

;====================================================================================================


     
    print ( "Normal code end")
    
end

