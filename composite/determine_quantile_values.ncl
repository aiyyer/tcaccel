;----------------------------------------------------------------------------
; a program to:
;
; read the TC acceleration data and extract dates that match
; user specified threshold for rapid accel, decel and zero accel cases
; The output file will be used to calculate storm centered composites
; of various variables from gridded reanlysis data
;
;
;----------------------------------------------------------------------------
; Aiyyer 
; NCSU Tropical Dynamics Group
;
;----------------------------------------------------------------------------
; Oct 15, 2019
; Oct 02, 2020 Now uses sorted data and percentiles
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------


begin

;---------------------------------------------------------------------------  
; user inputs

  accelType = 2; 1 = tang 2 = curv

  startYear = 1966
  endYear   = 2016

  nYears    = endYear - startYear + 1

  LatS =  30
  LatN =  40 
  basinAnalysis = "NA"  ;WP

  

; the sfac is used to determine the threshold accel, decel values.
; thresh = mean +/- sfac*sdev  
;--------------------------------------------------------------------------  
  fileName = "../tcMotion.nc"
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
  endTime = cd_inv_calendar(endYear,12,31,24,0,0,time@units, 0)
;


  if ( accelType .eq. 1 ) then
    dat = fileIn->accelSpeed
    fileName = "tcAcc_dates_tang"  + "_" + LatN + "_" + LatS+"_"+ basinAnalysis + ".nc"
  end if
  if ( accelType .eq. 2 ) then
    dat = fileIn->accelCurve
    fileName = "tcAcc_dates_curv"  + "_" + LatN + "_" + LatS+"_"+ basinAnalysis + ".nc"
end if

  if ( dat@units .eq. "m/s per day" ) then
    dat = dat*3.6 ; now km/hr per day
    dat@units = "km/hr per day" 
  else
    print (" dat Units unexpected! Terminating code!")
    exit
  end if
  basin = fileIn->basin

;
; read some other variables to be saved in output files
;  
  speed=fileIn->speed
  time= fileIn->time
  Lat = fileIn->lat
  Lon = fileIn->lon
  origJ = fileIn->origJ
  
  numobs      = fileIn->numobs
  nature      = fileIn->nature
;
  dims  = dimsizes(time)
  nStorms  = dims(0)
;
  xmax   =  120.*3.6
; create array to store all accel data for some more stats
  datA   = new (60000,typeof(dat))
  icount = 0



;===================================================================================
;===================================================================================  
;===================================================================================
    STcount  = 0

; loop over storms  
    do i = 0,nStorms-1
      if ( numobs(i) .gt. 0 ) then
        do j = 0, numobs(i)-1
          if ( basin(i,j) .eq. basinAnalysis ) then
            A = dat(i,j)
            if ( time(i,0) .ge. startTime .and. time(i,numobs(i)-1) .le. endTime ) then


              curTime = cd_calendar(time(i,j),-5)
              hour    = curTime(0,3)      

              if ( mod(hour,6) .eq. 0 ) then
                
                numDays = todouble(time(i,numobs(i)-1) - time(i,0))        
                
                if (  numDays .ge. 3 ) then          
                  
                  if ( Lat(i,j) .ge. LatS .and. Lat(i,j) .le. LatN ) then
                    
                    if ( chartostring(nature(i,j,:)) .ne. "ET" .and.  chartostring(nature(i,j,:)) .ne. "NR" ) then
                      if (.not.ismissing(A) ) then
                        datA(icount) = A
                        icount = icount + 1
                      end if ; missing
                      
                    end if ; lat
                  end if ;nat         
                end if ;numdays
                
              end if
            end if ;time
          end if ;basin
        end do ;j
        
      end if ;numobs
    end do ;i
    
    print ( "icount = " + icount )
    ave = avg( datA(0:icount-1) )
    std = stddev(datA(0:icount-1) )
    med = dim_median( datA(0:icount-1) )
    print ("Mean Median and Sdev = " + ave + " " + med + " " +  std)
                                ; lets sort the data:

    datSorted =  datA(0:icount-1) 
    qsort(datSorted )

    print (min( datA(0:icount-1)  ) +  " " + max( datA(0:icount-1) ) )
    print( datSorted(0) + " " + datSorted(icount-1) )



    sfac = (/.9,.8,.7,.3,.2,.1/)

    NTHU = tointeger(sfac*icount)
    
    
    print (sfac + " " + NTHU + " " + datSorted(NTHU) ) 
  
;===================================================================================
;===================================================================================  
;===================================================================================
  
end


