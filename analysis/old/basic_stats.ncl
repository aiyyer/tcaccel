; a program to:
;
;
; NCSU Tropical Dynamics Group
;
;----------------------------------------------------------------------------


begin

; user input
  
startYear = 1965
endYear   = 2019
nYears    = endYear - startYear + 1

print ( "Start Year = " + startYear + " end year = " + endYear)

basinAnalysis = "NA"
;--------------------------------------------------------------------------      

fileName = "../tcSpeed_" + basinAnalysis + "_" + startYear + "_" +  endYear+".nc"

fileName = "../tcSpeed_NA_1965_2019.nc"

fileIn = addfile( fileName, "r" )



numobs      = fileIn->numobs
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
nature      = fileIn->nature
dims        = dimsizes(time)
nStorms     = dims(0)
dat         = fileIn->accelSpeed


iTot=0
iET =0
iTS =0
iNR =0
iMX =0
; loop over storms  


iST = 0
iz = 0
print ( "N storms in data = " + nStorms)

do i = 0,nStorms-1

  flag_f = 0

  if ( numobs(i) .gt. 1 ) then

    numDays = tofloat(time(i,numobs(i)-1) - time(i,0))

;   storm must live at least 2 days    

    if (  numDays .ge. 2 ) then
      
      do j = 0, numobs(i)-1
        A = dat(i,j)
; apply the relevant checks
        
        if ( time(i,0) .ge. startTime .and. time(i,numobs(i)-1) .le. endTime ) then

          if ( flag_f .eq. 0 ) then
            iST = iST + 1
            flag_f=1
          end if
          if (.not.ismissing(A) ) then                                     

            iTot = iTot + 1
            
            if ( chartostring(nature(i,j,:)) .eq. "TS" ) then
              iTS = iTS + 1
            end if

            if ( chartostring(nature(i,j,:)) .eq. "ET" ) then
              iET = iET + 1
            end if

            if ( chartostring(nature(i,j,:)) .eq. "NR" ) then
              iNR = iNR + 1
            end if
            
            if ( chartostring(nature(i,j,:)) .eq. "MX" ) then
              iMX = iMX + 1
            end if
            
          end if
        end if

      end do
    end if
  end if
end do


print ( "Total track points  = " +  iTot )

pNR = 100*tofloat(iNR)/tofloat(iTot)
print ( "NR    track points  = " +  iNR + " " + pNR )


pTS = 100*tofloat(iTS)/tofloat(iTot)
print ( "TS    track points  = " +  iTS + " " + pTS )



pET = 100*tofloat(iET)/tofloat(iTot)
print ( "ET    track points  = " +  iET + " " + pET )

pMX = 100*tofloat(iMX)/tofloat(iTot)
print ( "MX    track points  = " +  iMX + " " + pMX )


print ("Num of Qualifying Storms = " + iST)
end