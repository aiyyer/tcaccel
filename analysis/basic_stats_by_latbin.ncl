; a program to:
; Calculate mean, median and sdev of TC motion variable (accel/speed)
; by latitude bin
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
xmax = 30.*3.6
xmin =-30.*3.6

latS = 5. ; 5.0
dlat = 10. ;10.0
latN = latS + dlat    
nn   = 4
clat  = new(nn,"double")



variable = (/"speed","accelSpeed","accelCurve"/)
var = variable(0)


wks = gsn_open_wks("pdf","box")               ; send graphics to PNG file
res            = True                         ; plot mods desired

;--------------------------------------------------------------------------      

fileName = "../tcSpeed_" + basinAnalysis + "_1950_2019.nc"


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

Lat   = fileIn->lat
Lon   = fileIn->lon


if ( var .eq. "accel" ) then
  dat   = fileIn->accel
  dh = 4.0 
  minDat = -40.0
  maxDat =  40.0
  titleString = "Acceleration (km/hr per day)" 

 if ( dat@units .eq. "m/s per day" ) then
    dat = dat*3.6 ; now km/hr per day
    dat@units = "km/hr per day" 
  else
    print ("Units unexpected! Terminating code!")
    exit
  end if

else
  dat = fileIn->speed
  dh  = 2.0
  minDat =   0.0
  maxDat =  60.0
  titleString = "Speed (km/h)" 


 if ( dat@units .eq. "m/s" ) then
    dat = dat*3.6 ; now km/hr
    dat@units = "km/hr" 
  else
    print ("Units unexpected! Terminating code!")
    exit
  end if

end if

int = tointeger((maxDat-minDat)/dh) + 1
xdat = fspan(minDat,maxDat,int) 
histo = new( (/nn,int/),"integer")
legend = new(nn,"string")
histo=0


numobs      = fileIn->numobs
nature      = fileIn->nature
;basin       = fileIn->basin
dims        = dimsizes(time)
nStorms     = dims(0)




do imain = 0,nn-1


  ic = 0
  
; create array to store all accel data for some more stats
  datA   := new (100000,"double")
  icount = 0
  count  = 0.
  
; loop over storms  
  do i = 0,nStorms-1

    if ( numobs(i) .gt.0 ) then
      numDays = tofloat(time(i,numobs(i)-1) - time(i,0))
;   storm must live at least 2 days
;    
      if (  numDays .ge. 2 ) then      
        do j = 1, numobs(i)-2
          A = dat(i,j)      
; apply the relevant checks
          
                                ;if ( chartostring(basin(i,j,:)) .eq. basinAnalysis) then
          if ( time(i,0) .ge. startTime .and. time(i,numobs(i)-2) .le. endTime ) then
            if ( Lat(i,j) .ge. latS .and. Lat(i,j) .le. latN ) then                
              if ( chartostring(nature(i,j,:)) .eq. "TS" ) then
                
; ignore spuriously large values of accel
; this is controlled by the xmax value                  
                if (.not.ismissing(A) .and. abs(A) .le. xmax ) then                                     
                  datA(icount) = A
                  icount = icount + 1
                  
                end if
              end if
            end if
                                ;end if
          end if
        end do
      end if
      
    end if
  end do

  print ( icount)
  ave = avg( datA(0:icount-1) )
  std = stddev(datA(0:icount-1) )
  med = dim_median( datA(0:icount-1) )

; histogram of accel as a function of lat
  
  print ( "Lat range " + latS + " " + latN + " Mean Median Sdev = " + ave + " " + med + " " +  std)



  
 
  do is = 0,icount-1
    if (datA(is) .gt. minDat .and. datA(is) .lt. maxDat ) then
      j = tointeger((datA(is) - minDat - .5*dh)/dh) + 1
      histo(nn-imain-1,j) =  histo(nn-imain-1,j) + 1
    end if
  end do


  legend(nn-imain-1) = latS+"--"+latN           ; reverse the order to match curves
  latS = latS + dlat ;dlat*.5
  latN = latN + dlat ;dlat*.5


  
  
end do




; add a legend
 res@pmLegendDisplayMode    = "Always"              ; turn on legend
 
 res@pmLegendSide           = "Top"                 ; Change location of 
 res@pmLegendParallelPosF   = .80                   ; move units right
 res@pmLegendOrthogonalPosF = -0.5                   ; more neg = down
 
 res@pmLegendWidthF         = 0.12                  ; Change width and
 res@pmLegendHeightF        = 0.25                  ; height of legend.
 res@lgLabelFontHeightF     = .02                   ; change font height
 res@lgPerimOn              = False                 ; no box around

; labels for the legend
 res@xyExplicitLegendLabels =legend

 res@xyLineThicknesses = (/  1.0,   3.0, 1., 3.0 /)          ; make second line thicker
 res@xyLineColors      = (/"green", "blue", "black", "red"/)          ; change line color
 res@tiYAxisString = "Count"
 res@tiXAxisString = titleString
 res@tiMainString  = " " ;"North Atlantic Tropical Storms (1979-2018)"
 plot  = gsn_csm_xy (wks,xdat,histo,res)            ; create plot



 
end