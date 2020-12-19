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
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------


begin

;---------------------------------------------------------------------------  
; user inputs
  startYear = 1980
  endYear   = 2016
  nYears    = endYear - startYear + 1
  LatS = 30
  LatN = 40 
  LonW = -120 
  LonE =  0
  basinAnalysis = "NA"  ;WP

; sdev threshold factor
  sfacA = .75
  sfacB = 1.0


; the sfac is used to determine the threshold accel, decel values.
; thresh = mean +/- sfac*sdev  
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
  endTime = cd_inv_calendar(endYear,12,31,24,0,0,time@units, 0)
;
  dat = fileIn->accel
  speed=fileIn->speed
  time= fileIn->time
  Lat = fileIn->lat
  Lon = fileIn->lon
  numobs      = fileIn->numobs
  nature      = fileIn->nature
  basin       = fileIn->basin
;
  dims  = dimsizes(time)
  nStorms  = dims(0)

  xmax   =  30.
; create array to store all accel data for some more stats
  datA   = new (60000,"float")
  icount = 0

; define output arrays  
  N = 2000


       iZero = 0
   speedZero   = new (N, "float")
   accelZero   = new (N, "float")
     LatZero  = new (N, typeof(Lat))
     LonZero  = new (N, typeof(Lon))
    timeZero = new (N, typeof(time))
  iStormZero  = new (N, "integer")
  jStormZero  = new (N, "integer")



  accelZero@units = "m/s per day"
  accelZero@long_name = "acceleration"

;===================================================================================
;===================================================================================  
;===================================================================================
  
; loop over storms  
  do i = 0,nStorms-1
    do j = 1, numobs(i)-2
      A = dat(i,j)
; apply the relevant checks
      if ( time(i,0) .ge. startTime .and. time(i,0) .le. endTime ) then
        if ( chartostring(basin(i,j,:)) .eq. basinAnalysis) then
          if ( Lat(i,j) .ge. LatS .and. Lat(i,j) .le. LatN ) then
            if ( Lon(i,j) .ge. LonW .and. Lon(i,j) .le. LonE ) then              
              Nat = chartostring(nature(i,j,:))


              if ( Nat .eq. "TS" ) then                     
; ignore spuriously large values of accel
; this is controlled by the xmax value
                if (.not.ismissing(A)) then                
                  if ( abs(A) .le. xmax ) then 
                    datA(icount) = A
                    date=cd_calendar(time(i,j),-3)
;                  print ( icount + " " + date + " " +  A )
                    icount = icount + 1
                  end if
                end if
              end if

            end if
          end if         
        end if
      end if
    end do
  end do

  print ( "icount = " + icount )
  ave = avg( datA(0:icount-1) )
  std = stddev(datA(0:icount-1) )
  med = dim_median( datA(0:icount-1) )
  print ("Mean Median and Sdev = " + ave + " " + med + " " +  std)
  
;===================================================================================
; now repeat and extract the high and low accel cases per user specifications

; loop over storms  
  do i = 0,nStorms-1
    do j = 1, numobs(i)-2
      A = dat(i,j)
; apply the relevant checks
      if ( time(i,0) .ge. startTime .and. time(i,0) .le. endTime ) then
        if ( chartostring(basin(i,j,:)) .eq. basinAnalysis) then
          if ( Lat(i,j) .ge. LatS .and. Lat(i,j) .le. LatN ) then
            if ( Lon(i,j) .ge. LonW .and. Lon(i,j) .le. LonE ) then              
              Nat = chartostring(nature(i,j,:))

              if ( Nat .eq. "TS" ) then       
; ignore spuriously large values of accel
; this is controlled by the xmax value
                if (.not.ismissing(A)) then                
                  if ( abs(A) .le. xmax ) then 




                    if ( A .ge. (ave+(std*sfacA)) .and.  A .le. (ave+(std*sfacB)) ) then                  
                      speedZero(iZero)   = speed(i,j)
                      accelZero(iZero)   = A
                      LatZero(iZero)  = Lat(i,j)
                      LonZero(iZero)  = Lon(i,j)
                      timeZero(iZero) = time(i,j)
                      iStormZero(iZero)  = i
                      jStormZero(iZero)  = j
                      iZero = iZero + 1  
                    end if


                  end if
                end if
              end if
            end if
          end if
        end if
      end if
    end do
  end do
;
;  

;
  speedZero!0 = "ZeroCount"
  accelZero!0 = "ZeroCount"
  LatZero!0 = "ZeroCount"
  LonZero!0 = "ZeroCount"
  timeZero!0 = "ZeroCount"
  iStormZero!0 = "ZeroCount"
  jStormZero!0 = "ZeroCount"
;
;
  fileName = "tcAcc_dates" + LonW + "_" + LonE + "_" + LatN + "_" + LatS+"_"+ basinAnalysis + ".nc"
  system( "rm " + fileName )
  outFile = addfile( fileName, "c" )
  outFile->ave=ave
  outFile->std=std
  outFile->sfacA=sfacA
  outFile->sfacB=sfacB

  outFile->LatS=LatS
  outFile->LatN=LatN
  outFile->LonW=LonW
  outFile->LonE=LonE



  N=iZero-1
  speedZero2 :=speedZero(0:N)
  accelZero2 :=accelZero(0:N)
  LatZero2   :=LatZero(0:N)
  LonZero2   :=LonZero(0:N)
  iStormZero2:=iStormZero(0:N)
  jStormZero2:=jStormZero(0:N)
  timeZero2  :=timeZero(0:N)
  outFile->speedZero=speedZero2
  outFile->accelZero=accelZero2
  outFile->LatZero=LatZero2
  outFile->LonZero=LonZero2
  outFile->iStormZero=iStormZero2
  outFile->jStormZero=jStormZero2
  outFile->timeZero=timeZero2
  outFile->ZeroCount=N

;
  print ( "iZero = "  + iZero)
;===================================================================================
;===================================================================================  
;===================================================================================


  
end

