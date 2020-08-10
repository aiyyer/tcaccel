;-----------------------------------------------------------------------------
; a program to:
;              plot the distributions (boxplots) of TC speed/accel
;              for chosen lat ranges
;
; 5 Dec 2019
; Aiyyer 
; NCSU Tropical Dynamics Group
;
;----------------------------------------------------------------------------

begin

  variable = (/"speed","accelSpeed","accelCurve"/)

;  
; choose the latitude bands
  latS =   5.
  latN =  55.
  dlat =  10.

 fileName = "../tcSpeed.nc"
  fileIn = addfile( fileName, "r" )
    
  time = fileIn->time

  
  Lat  = fileIn->lat
  Lon  = fileIn->lon
  numobs      = fileIn->numobs
  nature      = fileIn->nature
  dims        = dimsizes(time)
  nStorms     = dims(0)
; we expect time units to be in days
  unitsExpected  = "days since 1858-11-17 00:00:00"
  
  if (time@units .ne. unitsExpected ) then
    print ("Read from file: " + time@units)
    print ("Expected      : " + unitsExpected)
    print ("Error in timeunits. Unexpected units. Terminating code!!!")
    exit
  end if
  
  speed := ndtooned(fileIn->speed)
  printVarSummary(speed)
  accelSpeed := ndtooned(fileIn->accelSpeed) 
  printVarSummary(accelSpeed)
  accelCurve := ndtooned(fileIn->accelCurve)
  printVarSummary(accelCurve)

  accelSpeed = sqrt(accelSpeed*accelSpeed)
  accelCurve = sqrt(accelCurve*accelCurve)
  
  rc    = regline(accelSpeed,accelCurve)

  print (rc)
  data      = new ( (/2,dimsizes(accelSpeed)/), typeof(accelSpeed))
  data(0,:) = accelCurve
  data(1,:) = rc*(accelSpeed-rc@xave) + rc@yave
  
;************************************************
; plotting parameters
;************************************************
 wks  = gsn_open_wks("png","scatter")             ; send graphics to PNG file
 
 res                     = True                   ; plot mods desired
 res@gsnMaximize         = True                   ; maximize plot in frame
 res@xyMarkLineModes     = (/"Markers","Lines"/)  ; choose which have markers
 res@xyMarkers           = 16                     ; choose type of marker 
 res@xyMarkerColor       = "red"                  ; Marker color
 res@xyMarkerSizeF       = 0.005                  ; Marker size (default 0.01)
 res@xyDashPatterns      = 1                      ; solid line 
 res@xyLineThicknesses   = (/1,2/)                ; set second line to 2

 res@tiMainString        = "Output from regline"  ; title

 plot  = gsn_csm_xy (wks,accelSpeed,data,res)        ; create plot

end

