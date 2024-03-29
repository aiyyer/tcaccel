;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
; et_stats.ncl
;
;----------------------------------------------------------------------------
; a program to:
;
; determine: (a) ET count; (b) ET fraction; (c) latitude of ET
;
; reads ibtracs data file and uses the nature designation in it for storms
;
;----------------------------------------------------------------------------
;
; Aiyyer 
; NCSU Tropical Dynamics Group
;
; Nov 28, 2019
; Oct 04, 2020: Now we demand that each storm lives at least 3 days
;
;
;

;----------------------------------------------------------------------------
; Does a storm undergo ET? This is a tricky question. The numbers can be
; slightly different if:
;
;
; (a) We just identify storms that were designated as ET      = greatest ET fraction
; (b) we demand (a) and that the storm had to live > n days  for n<3, not much sensitivity
; (c) we also demand that the storm was classified as TS before ET
; (d) we include or exclued SS->ET 
;
;
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
;
begin
;
; user inputs
  startYear = 1966
  endYear   = 2019
  nYears    = endYear - startYear + 1
  basinAnalysis ="NA"
  print ( "Start Year = " + startYear + " end year = " + endYear)

;--------------------------------------------------------------------------      

; the ibtracs file  
  fileName = "../IBTrACS.ALL.v04r00.nc"
  fileIn = addfile( fileName, "r" )
;
  time        = fileIn->time
  lat         = fileIn->lat
  lon         = fileIn->lon  
  numobs      = toint(short2flt(fileIn->numobs))
  basin       = fileIn->basin
  nature      = fileIn->nature
  wmo_wind    = fileIn->usa_wind ;use usa instead of wmo for ATL
;--------------------------------------------------------------------------        
  if ( wmo_wind@units .eq. "kts" ) then
    WindThresh = 33.  ; threshold for TC
  else
    print ("Units of wmo_wind not kts. Unexpected error! Terminating Code")
    exit
  end if
  
; set the start and end times to consider  
  startTime = cd_inv_calendar(startYear,1,1,0,0,0,time@units,  0)
  endTime   = cd_inv_calendar(endYear,12,31,24,0,0,time@units, 0)
  dims        = dimsizes(time)
  nStorms     = dims(0)

;--------------------------------------------------------------------------
; define some arrays to hold TC/ET info
;--------------------------------------------------------------------------
; how many TCs per year?  
  yearlyStormCount := new((/nYears/),"integer")
  yearlyStormCount = 0   ; how many storms per year in the domain chosen

; how many ETs per year?  
  yearlyETCount    = yearlyStormCount
  yearlyETCount = 0   ; how many storms per year in the domain chosen became ET?

; Array to hold latitudes of all ETs identified here
  N = 2000
  
  ETLat = new(N,"float") ;keep track of latitudes of each ET event
; a counter to keep track of ETs for filling the ETLat array
  iET =0
  ires = 0
;--------------------------------------------------------------------------

  print ( "nStorms  " + nStorms)
  
; loop over each storm in ibtracs
  do i = 0, nStorms-1
      
; storm must fall within the user defined date range    
    if ( time(i,0) .ge. startTime .and. time(i,numobs(i)-1) .le. endTime ) then
      basinId =  chartostring(basin(i,0,:))

      if ( basinId .eq. basinAnalysis) then

; optional filter based on peak wind speed
        flag = 1
        maxSpeed = max(wmo_wind(i,:))
        if ( ismissing(maxSpeed) ) then
          flag = 0
          print ("missing max speed  " + i )
        else
          if ( maxSpeed .lt. WindThresh ) then
            flag = 0
          end if
        end if
        
; override max wind threshold. comment this line if you wish to exclude depressions
        flag = 1
; storm must live at least N days
        
        numDays = tofloat(time(i,numobs(i)-1) - time(i,0))
        if ( flag .eq. 1 .and.  numDays .ge. 3 ) then 
          
          stormFlag = 1  ; this storm is good to go for our stats

          j=3 ;use j=3 to get just one point along the track
          date=cd_calendar(time(i,j),-5)
; define the year by the first data in the track
          iy = date(0,0)
          k  = iy-startYear
          
          ETFlag = 0 ; a flag that keeps track of whether a storm became ET or not
          TSFlag = 0 ; a flag that keeps track of whether a storm was a named TS
          SSFlag = 0 ; a flag that keeps track of whether a storm was a named Subtropical          
          TSj = -9
          ETj = -9
          SSj = -9
          
;.........................................................................
; loop over each track point      
          do j = 0, numobs(i)-1          
            
            date=cd_calendar(time(i,j),-5)
            iy = date(0,0)
            
            StypeA = chartostring(nature(i,j,:))
            if ( StypeA .eq. "ET" .and. ETFlag .eq. 0) then
              ETFlag = 1
              ETj    = j
            end if

;---------------------------------------------------------------------------
;  strict restriction
;
;           
;           if ( StypeA .eq. "TS" .and. TSFlag .eq. 0) then
;             TSFlag = 1
;             TSj    = j
;           end if
;            
; if the TS was classified as a sub-tropical storm any time
;            if ( StypeA .eq. "SS" ) then
;              SSFlag = 1
;              SSj    = j
;            end if
; Now first we check whether a storm was classified as SS but never as TS
; If so, we will omit this storm from our stats       
          
          ;if ( SSFlag .eq. 1 .and. TSFlag .eq. 0 ) then
          ;  stormFlag = 0
          ;  ETFlag    = 0
          ;end if      
; Include this storm as a legit TS->ET case only if it was designated as a TS
; prior to being classified as ET. This happens for i=9092, 13207 for example.
; at least 15-20 such cases found.
          
;          if ( ETFlag .eq. 1 ) then
;            if (  TSj .lt. ETj ) then
;              yearlyETCount(k) = yearlyETCount(k) + 1
;              ETLat(iET) =  lat(i,ETj)
;              iET = iET + 1
;            else
;              print ("ET before TS? " + i )
;              ires  = ires + 1
;            end if
;          end if
;----------------------------------------------------------------------------------------

; looser restricion. 
;             
            if ( StypeA .ne. "ET" .and. TSFlag .eq. 0) then
              TSFlag = 1
              TSj    = j
            end if
          end do ;j`end loop over each track
            
; Include this storm as a legit TS->ET case only if it was designated as a TS
; prior to being classified as ET. 
; at least 15-20 such cases found.
          
          if ( ETFlag .eq. 1 ) then
            if (  TSj .lt. ETj ) then
              yearlyETCount(k) = yearlyETCount(k) + 1
              ETLat(iET) =  lat(i,ETj)
              iET = iET + 1
            else
              print ("ET before TS? " + i )
              ires  = ires + 1
            end if
          end if
          
; update the storm count if this storm met our specs for a valid storm      
          if (stormFlag .eq. 1 ) then
            yearlyStormCount(k) = yearlyStormCount(k) + 1
          end if
          
        end if
;===================================================================================    
      end if
    end if
  end do ; i


;.........................................................................
; The total number of ET cases found = iET
  N = iET

  print ("total number of ET cases found= " + iET)
  exit
  
; print ( ETLat(0:N-1) )

; quick histogram showing latitude distribution of ET
  histo =new(15, "integer" )
  xlat  =fspan(0.,14.,15)
  dlat = 5.0
  histo = 0

  xlat = xlat*dlat

  do i = 0,N-1
    j = tointeger( (ETLat(i)-2.5)/dlat )
    histo(j) =  histo(j)+1
    ;print ( ETLat(i) + " " + j ) 
  end do
  print ("..........................................")
  print ("Distribution of Latitues of ET: Lat, Count")
  print (  xlat + " " + histo )
  print ("..........................................")

;.........................................................................

 
  
  TCNUM = sum (yearlyStormCount)
  ETNUM = sum (yearlyETCount)
  print (  " " )
  print (  " " )
  print ( "Num of TCs in the period = " + TCNUM)
  print ( "Num of ETs in the period = " + ETNUM)
  print ( "ires = " + ires )
  
;  do k=0,nYears-1
;    iy = k + startYear
;    print ( iy + " " + yearlyStormCount(k) + " " + yearlyETCount(k) ) ;+ " " + ETfraction(k))
;  end do

  
  ETfraction := new((/nYears/),"float")
  ETfraction = tofloat(yearlyETCount)/tofloat( yearlyStormCount )*100.

  
;..........................................................................

  print (  " " )
;..........................................................................

  print ( "Avg ET count per year  = " + avg(tofloat(yearlyETCount)) )
  y := tofloat(yearlyETCount)
  opt  = False
  pt   = trend_manken(y, opt, 0) 
  pt(0) = 1.-pt(0)
  print ("MK trend and prob dat = " + pt(1) + " " + pt(0) )
  
  x    := fspan(0,nYears-1,nYears) + startYear
; calculate the regression coefficient (slope)    
  rc    = regline(x, y)          ; slope           
  rc@units = " "           
  df   = rc@nptxy-2
  prob = betainc(df/(df+rc@tval^2), df/2.0, 0.5)
  print("rc trend and prob =      " + rc + " " + prob)
  pltarry   := new ( (/2,nYears/), typeof(y), y@_FillValue)
  pltarry(0,:) = y                                 ; use markers
  pltarry(1,:) = rc*x + rc@yintercept              ; use solid line
  perChange = 100.*(pltarry(1,nYears-1)-pltarry(1,0))/pltarry(1,0)
  ave = avg(y)
  print ("ave = " + ave + "  change % = " + perChange)
  print (  " " )
;..........................................................................

  
  print ( "Avg TC count per year  = " + avg(tofloat(yearlyStormCount)) )
  y := tofloat( yearlyStormCount )
  opt  = False
  pt   = trend_manken(y, opt, 0) 
  pt(0) = 1.-pt(0)
  print ("MK trend and prob dat = " + pt(1) + " " + pt(0) )

  
  x    := fspan(0,nYears-1,nYears) + startYear
; calculate the regression coefficient (slope)    
  rc    = regline(x, y)          ; slope           
  rc@units = " "           
  df   = rc@nptxy-2
  prob = betainc(df/(df+rc@tval^2), df/2.0, 0.5)
  print("rc trend and prob =      " + rc + " " + prob)
  pltarry   := new ( (/2,nYears/), typeof(y), y@_FillValue)
  pltarry(0,:) = y                                 ; use markers
  pltarry(1,:) = rc*x + rc@yintercept              ; use solid line
  perChange = 100.*(pltarry(1,nYears-1)-pltarry(1,0))/pltarry(1,0)
  ave = avg(y)
  print ("ave = " + ave + "  change % = " + perChange)

  ;print ( x + " " + y)
  print (  " " )


;..................................................................
  print (  " " )
  print ( "Avg ET fraction        = " + avg(ETfraction) )
  y = ETfraction
  opt  = False
  pt   = trend_manken(y, opt, 0) 
  pt(0) = 1.-pt(0)
  print ("MK trend and prob dat = " + pt(1) + " " + pt(0) ) 
  x    := fspan(0,nYears-1,nYears) + startYear
  
; calculate the regression coefficient (slope)    
  rc    = regline(x, y)          ; slope           
  rc@units = " "           
  df   = rc@nptxy-2
  prob = betainc(df/(df+rc@tval^2), df/2.0, 0.5)
  print("rc trend and prob =      " + rc + " " + prob)
 
  pltarry   := new ( (/2,nYears/), typeof(y), y@_FillValue)
  pltarry(0,:) = y                                 ; use markers
  pltarry(1,:) = rc*x + rc@yintercept              ; use solid line
  perChange = 100.*(pltarry(1,nYears-1)-pltarry(1,0))/pltarry(1,0)
  ave = avg(y)
  print ("ave = " + ave + "  change % = " + perChange)

;..................................................................



  print (  " " )
  print (  " " )

  print ("Number of ET cases found = " + iET)
  N = iET
  LatAve = avg(ETLat(0:N-1))
  LatMed = dim_median(  ETLat(0:N-1) )
  std = stddev(ETLat(0:N-1) )
  print ( "Avg, Median and Sdev Lat of ET = " + LatAve + " " + LatMed + " " + std )
  
  
;************************************************
; plotting parameters
; This illustrates one approach. Overlays could also be used.
;************************************************
    wks  = gsn_open_wks("pdf","trend")             ; send graphics to PNG file
    
    res                     = True                   ; plot mods desired
    res@xyMarkLineModes     = (/"Lines","Lines"/)  ; choose which have markers
    res@xyMarkers           = 16                     ; choose type of marker 
    res@xyMarkerColor       = "red"                  ; Marker color
    res@xyMarkerSizeF       = 0.005                  ; Marker size (default 0.01)
    res@xyDashPatterns      = 1                      ; solid line 
    res@xyLineThicknesses   = (/1,3/)                ; set second line to 2
    res@tmYLFormat          = "f"                    ; not necessary but nicer labels 
    res@tiMainString        = " "  ; title
    
    plot  = gsn_csm_xy (wks,x,pltarry,res)           ; create plot
    


;===========================================================================================  
  print ( "*************************************************" )
  print ( "*****   Normal Code Termination  ****************" )
  print ( "*************************************************" )
;===========================================================================================
  
end


