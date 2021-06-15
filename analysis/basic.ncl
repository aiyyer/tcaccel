; a program :
;           Basic bookkeeping  
;
;
;-----------------------------------------------------------------------------
; NCSU Tropical Dynamics Group
; A. Aiyyer
; Aug 30, 2020
;.............................................................................
;   Input  -> tcMotion.nc
;
;-----------------------------------------------------------------------------

;
begin
;  
; user inputs
  startYear = 1966
  endYear   = 2019
  nYears    = endYear - startYear + 1
  basinAnalysis = "NA" 

; full basin
  latS =  0.
  latN =  90.

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
  endTime   = cd_inv_calendar(endYear,12,31,24,0,0,time@units, 0)
;

; read the two acceleration date  
  accelS   = fileIn->accelSpeed  ;tangential
  accelC   = fileIn->accelCurve  ;curvature/normal
; read the speeds  
  speed   = fileIn->speed
  basin = fileIn->basin

  time      = fileIn->time
  Lat       = fileIn->lat
  Lon       = fileIn->lon
  numobs    = fileIn->numobs
  nature    = fileIn->nature
  dims      = dimsizes(time)
  nStorms   = dims(0)
  print ( "Num Storms in file process = " + nStorms)
  if ( speed@units .eq. "m/s" ) then
    speed = speed*3.6 ; now km/hr per day
    speed@units = "km/hr per day" 
  else
    print ("Units unexpected! Terminating code!")
    exit
  end if
  if ( accelC@units .eq. "m/s per day" ) then
    accelC = accelC*3.6 ; now km/hr per day
    accelC@units = "km/hr per day" 
  else
    print ("Units unexpected! Terminating code!")
    exit
  end if
  if ( accelS@units .eq. "m/s per day" ) then
    accelS = accelS*3.6 ; now km/hr per day
    accelS@units = "km/hr per day" 
  else
    print ("Units unexpected! Terminating code!")
    exit
  end if


;============================================================================================
 
   icount    = 0
   nrCount   = 0
   totCount  = 0
   tsCount   = 0
   etCount   = 0
   dsCount   = 0
   ssCount   = 0

  
   ist = 0
   do i = 0,nStorms-1

     sflag = 0
     
     if ( numobs(i) .ne. 0 ) then


       numDays = todouble(time(i,numobs(i)-1) - time(i,0))
       
;storm must live at least 3 days
       if (  numDays .ge. 3 ) then
         if ( time(i,0) .ge. startTime .and. time(i, numobs(i)-1) .le. endTime ) then
           
           
; now lets see how many NR, TS, MX and ET records are there           
           
           do j = 0, numobs(i)-1    
             if ( basin(i,j) .eq. basinAnalysis ) then
               
      
                          if ( sflag .eq. 0 ) then
                 ist = ist + 1
                 sflag = 1
               end if
               
               if ( Lat(i,j) .ge. latS .and. Lat(i,j) .le. latN ) then  
                 totCount = totCount+1
                 if ( chartostring(nature(i,j,:)) .eq. "NR" .or. chartostring(nature(i,j,:)) .eq. "MX") then
                   nrCount = nrCount + 1
                 end if             
                 if ( chartostring(nature(i,j,:)) .eq. "ET" ) then
                   etCount = etCount + 1
                 end if
                 if ( chartostring(nature(i,j,:)) .eq. "TS" )
                   tsCount        = tsCount + 1
                 end if
                 if ( chartostring(nature(i,j,:)) .eq. "DS" )
                   dsCount        = dsCount + 1
                                ;print ( "DS = " + i )
                 end if
                 if ( chartostring(nature(i,j,:)) .eq. "SS" )
                   ssCount        = ssCount + 1
                 end if
               end if
             
               
             end if ;basin
           end do ;j
           
         end if
       end if
     end if
     
   end do ;i
   

   
  print ( "nStorms = " + nStorms + " " + "qual storms = " + ist )
  
;============================================================================================
    NRper = tofloat(nrCount*100)/tofloat(totCount)
    TSper = tofloat(tsCount*100)/tofloat(totCount)
    ETper = tofloat(etCount*100)/tofloat(totCount)
    DSper = tofloat(dsCount*100)/tofloat(totCount)
    SSper = tofloat(ssCount*100)/tofloat(totCount)

    print ( "tot count=" + totCount + " NR count="+nrCount + " NR per="+ NRper)
    print ( "tot count=" + totCount + " TS count="+tsCount + " ts per="+ TSper)
    print ( "tot count=" + totCount + " ET count="+etCount + " ET per="+ ETper)
    print ( "tot count=" + totCount + " DS count="+dsCount + " DS per="+ DSper)
    print ( "tot count=" + totCount + " SS count="+dsCount + " SS per="+ SSper)

    sumC = etCount+nrCount+tsCount+dsCount+ssCount
    
    print ("following two numbers should be the same")
    print ( "tot count=" + totCount + " Sum count=" +sumC) 
;============================================================================================

 ;   i=898
 ;   N = numobs(i)-1
 ;   print ( chartostring(nature(i,0:N,:)) + " " + Lat(i,0:N) )
    
end