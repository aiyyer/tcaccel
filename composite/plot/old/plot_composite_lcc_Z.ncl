;***************************************************************
;NCSU Tropical Dynamics
;A. Aiyyer 06/19/2019
;
;A basic code for plotting
;
;
;***************************************************************
; code adapted from ncl examples
;
;
;***************************************************************

;; This procedure attaches lat/lon labels to a masked lambert plot
;
; You will likely need to change lat_values and/or lon_values to
; contain the locations where you want lat/lon labels.
;----------------------------------------------------------------------
procedure add_lc_labels(wks,map,minlat,maxlat,minlon,maxlon,\
                        lat_spacing[1]:integer,lon_spacing[1]:integer)
local lat_values, nlat, lat1_ndc, lat2_ndc, lon1_ndc, lon2_ndc,slope,txres, \
lon_values, PI, RAD_TO_DEG, dum_lft, dum_rgt, dum_bot
begin
  PI         = 3.14159
  RAD_TO_DEG = 180./PI

;---Pick some "nice" values for the latitude labels.
  lat_values = ispan(toint(minlat),toint(maxlat),lat_spacing) * 1.
  nlat       = dimsizes(lat_values)
;
; We need to get the slope of the left and right min/max longitude lines.
; Use NDC coordinates to do this.
;
  lat1_ndc = new(1,float)
  lon1_ndc = new(1,float)
  lat2_ndc = new(1,float)
  lon2_ndc = new(1,float)
  datatondc(map,minlon,lat_values(0),lon1_ndc,lat1_ndc)
  datatondc(map,minlon,lat_values(nlat-1),lon2_ndc,lat2_ndc)
  if(lon2_ndc.eq.lon1_ndc) then
      print("add_lc_labels: error: not enough valid latitude values to generate labels")
      print("    You may need to decrease the lat_spacing")
      exit
  end if
  slope_lft = (lat2_ndc-lat1_ndc)/(lon2_ndc-lon1_ndc)

  datatondc(map,maxlon,lat_values(0),lon1_ndc,lat1_ndc)
  datatondc(map,maxlon,lat_values(nlat-1),lon2_ndc,lat2_ndc)
  if(lat2_ndc.eq.lat1_ndc) then
      print("add_lc_labels: error: not enough valid longitude values to generate labels")
      print("    You may need to decrease the lon_spacing")
      exit
  end if
  slope_rgt = (lat2_ndc-lat1_ndc)/(lon2_ndc-lon1_ndc)

;---Set some text resources
  txres               = True
  txres@txFontHeightF = 0.01
  txres@txPosXF       = 0.1
;
; Loop through lat values, and attach labels to the left and
; right edges of the masked LC plot.  The labels will be 
; rotated to fit the line better.
;
  dum_lft = new(nlat,graphic)    ; Dummy array to hold attached strings.
  dum_rgt = new(nlat,graphic)    ; Dummy array to hold attached strings.
  do n=0,nlat-1
; Add extra white space to labels.
    lat_label_rgt = "          "  + lat_values(n) + "~S~o~N~"

;---Check if North, South, or Zero
    if(lat_values(n).lt.0) then
      lat_label_lft = lat_values(n) + "~S~o~N~S          "
      lat_label_rgt = lat_label_rgt + "S"
    end if
    if(lat_values(n).gt.0) then
      lat_label_lft = lat_values(n) + "~S~o~N~N          "
      lat_label_rgt = lat_label_rgt + "N"
    end if
    if(lat_values(n).eq.0) then
      lat_label_lft = lat_values(n) + "~S~o~N~           "
    end if

;---Left label
    txres@txAngleF = RAD_TO_DEG * atan(slope_lft) - 90
    dum_lft(n) = gsn_add_text(wks,map,lat_label_lft,minlon,lat_values(n),txres)

;---Right label
    txres@txAngleF = RAD_TO_DEG * atan(slope_rgt) + 90
    dum_rgt(n) = gsn_add_text(wks,map,lat_label_rgt,maxlon,lat_values(n),txres)
  end do

;----------------------------------------------------------------------
; Now do longitude labels. These are harder because we're not
; adding them to a straight line.
;
; Loop through lon values, and attach labels to the bottom edge of the
; masked LC plot.
;
  delete(txres@txPosXF)
  txres@txPosYF = -5.0

;---Pick some "nice" values for the longitude labels.
  lon_values = ispan(toint(minlon+10),toint(maxlon-10),lon_spacing) * 1.
  nlon       = dimsizes(lon_values)

  dum_bot = new(nlon,graphic)    ; Dummy array to hold attached strings.

  do n=0,nlon-1
;
; For each longitude label, we need to figure out how much to rotate
; it, so get the approximate slope at that point.
;
    datatondc(map,lon_values(n)-0.25,minlat,lon1_ndc,lat1_ndc)
    datatondc(map,lon_values(n)+0.25,minlat,lon2_ndc,lat2_ndc)
    slope_bot = (lat1_ndc-lat2_ndc)/(lon1_ndc-lon2_ndc)
    txres@txAngleF  = atan(slope_bot) * RAD_TO_DEG
;
; Create longitude label. Add extra carriage returns to
; move label away from plot.
;
;---Check if East, West, or Zero
;    lon_label_bot = "  ~C~  ~C~" + abs(lon_values(n)) + "~S~o~N~"
    
;Aiyyer: Omit E and W and instead use - for West of center of composite TC
; i.e. use storm relative long coods
    lon_label_bot = "  ~C~  ~C~" + lon_values(n) + "~S~o~N~"
    
; Aiyyer
;    if(lon_values(n).lt.0) then
;     lon_label_bot = lon_label_bot + "W"
;  
;    end if
;    if(lon_values(n).gt.0) then
;      lon_label_bot = lon_label_bot + "E"
;    end if

;---Attach to map.
    dum_bot(n) = gsn_add_text(wks,map,lon_label_bot,lon_values(n),minlat,txres)
  end do
end


;===========================================================================
;===========================================================================
;
; MAIN PROGRAM
;
;
; 
;
;
begin
;***************************************************************
; User Input
;***************************************************************

  

  pltName = "composite"                    ; netCDF name output
  pltType = "pdf"                       ; send graphics to PNG file
  
  wks    = gsn_open_wks(pltType,pltName)
  res                      = True     ; plot mods desired
  gsn_define_colormap(wks,"BlueWhiteOrangeRed")
  
  res@cnFillOn             =  True    ; turn on color fill
  res@cnLinesOn            =  False       ; Turn off contour lines
  res@cnLineLabelsOn       =  False       ; Turn off contour lines   
  res@gsnDraw             = False       ; Don't draw plots
  res@gsnFrame            = False       ; Don't advance frame
  
  resC = res
  resC@cnFillOn             =  False    ; turn on color fill
  resC@cnLinesOn            =  True       ; Turn off contour lines
  resC@cnLineLabelsOn       =  False       ; Turn off contour lines   
  
  
  res@cnLevelSelectionMode = "ManualLevels"	; manually set the contour levels with the following 3 resources
  

  minlat             =  20.                ; min lat to mask
  maxlat             =  80.                ; max lat to mask
  minlon             = -130.                ; min lon to mask
  maxlon             =  10.                ; max lon to mask


  minlon             = -60.                ; min lon to mask
  maxlon             =  60.                ; max lon to mask



  
  res@mpProjection          = "LambertConformal"; choose projection
  res@gsnMaskLambertConformal = True            ; turn on lc masking
  res@mpMinLatF             = minlat
  res@mpMaxLatF             = maxlat
  res@mpMinLonF             = minlon
  res@mpMaxLonF             = maxlon
  res@mpOutlineOn           = False 
  res@mpFillOn              = False
  res@lbLabelBarOn = False
  
                                ; res@lbOrientation        = "vertical"   ; vertical label barb's
                                ; res@lbLabelFontHeightF   = 0.012        ; change font size
                                ; res@pmLabelBarWidthF     =  0.1     
                                ; res@pmLabelBarOrthogonalPosF = -0.01    ; move a bit to left
  
  
  resC@cnLevelSelectionMode = "ManualLevels"	; manually set the contour levels with the following 3 resources
  
  res@cnInfoLabelOn     = False                ; turn off info label
  resC@cnInfoLabelOn     = False                ; turn off info label  
  
  gsres               = True
  gsres@gsMarkerIndex = 16          ; Use filled dots for markers.
                                ;gsres@gsMarkerThicknessF = 0.1
  gsres@gsMarkerSizeF = 0.01

  resC@gsnContourLineThicknessesScale = 2
  
  plot = new(9,"graphic")

  resC2=resC
  
  
 resC2@gsnContourNegLineDashPattern   = 1       ; sets negative contours to dash pattern 1
  resC2@gsnContourZeroLineThicknessF   = 0.     ; sets negative contours to dash pattern 1
  resC2@gsnContourLineThicknessesScale = 1
  
  
  res@tiMainString         = " "
; res@gsnCenterString      = cd_calendar(time,-3)
  
  
  ;res@lbLabelBarOn = False  
  

  diri = "~/data50/data/tcaccel/one/tang/" ;  "../../dat/one/tang/"
  ;diri = "~/data50/data/tcaccel/one/curv/" ;  "../../dat/one/tang/"

  
  types = (/"High","Zero","Low"/)
 
  titles = (/"Rapid Acceleration","Near Zero Acceleration","Rapid Deceleration"/)



  levels = (/300,500,750/)
  do ilag = 2,2
  ic = 0
  do iuber = 0,2
  level = levels(iuber)
  if (level .eq. 300 ) then
    res@cnMinLevelValF  = -12.			; set the minimum contour level
    res@cnMaxLevelValF  =  12.			; set the maximum contour level
    res@cnLevelSpacingF =   2.			; set the interval between contours
    
    resC@cnMinLevelValF  = 680.			; set the minimum contour level
    resC@cnMaxLevelValF  = 1400.			; set the maximum contour level
    resC@cnLevelSpacingF = 12.			; set the interval between contours
    
    resC2@cnMinLevelValF  = -10.			; set the minimum contour level
    resC2@cnMaxLevelValF  =  0.			; set the maximum contour level
    resC2@cnLevelSpacingF =  2.			; set the interval between contours
  end if
  
  if (level .eq. 500 ) then
    res@cnMinLevelValF  = -6			; set the minimum contour level
    res@cnMaxLevelValF  =  6.			; set the maximum contour level
    res@cnLevelSpacingF =  1.			; set the interval between contours
    
    resC@cnMinLevelValF  = 380.			; set the minimum contour level
    resC@cnMaxLevelValF  = 620.			; set the maximum contour level
    resC@cnLevelSpacingF = 6.			; set the interval between contours
    
    resC2@cnMinLevelValF  = -10.			; set the minimum contour level
    resC2@cnMaxLevelValF  =  0.			; set the maximum contour level
    resC2@cnLevelSpacingF =  2.			; set the interval between contours
  end if
  
  
  if (level .eq. 750 ) then
    res@cnMinLevelValF  = -6.			; set the minimum contour level
    res@cnMaxLevelValF  =  6.			; set the maximum contour level
    res@cnLevelSpacingF =  1.			; set the interval between contours

    res@cnMinLevelValF  = -6			; set the minimum contour level
    res@cnMaxLevelValF  =  6.			; set the maximum contour level
    res@cnLevelSpacingF =  1.			; set the interval between contours

    
    resC@cnMinLevelValF  = 202.			; set the minimum contour level
    resC@cnMaxLevelValF  = 300.			; set the maximum contour level
    resC@cnLevelSpacingF = 4.			; set the interval between contours
    
    resC2@cnMinLevelValF  = -10.			; set the minimum contour level
    resC2@cnMaxLevelValF  =  0.			; set the maximum contour level
    resC2@cnLevelSpacingF =  2.			; set the interval between contours
  end if
  
     
  pltDir  = "../"                        ; directory for plot output

  do imain = 0,2
    type = types(imain)
    fili   = "laggedComp_"+type+"_-180_180_40_30_NA.nc"

     f      = addfile (diri+fili, "r")

     ; read the location of the composite storm
     varTemp = "cenLon"+types(imain)
     cenLon=f->$varTemp$
     varTemp = "cenLat"+types(imain)
     cenLat=f->$varTemp$
     delete(varTemp)
     
;     ilag=2
     hour = -12 + ilag*6
     

     if ( iuber.eq.0 ) then
       res@tiMainString         = titles(imain)
     else
       res@tiMainString         = " "
     end if
     
     dat2 = f->compZ(ilag,{level},:,:)
     dat1 = f->compAnomZ(ilag,{level},:,:)
     dat1 = dat1*.01 ;in dam 
     dat2 = dat2*.01 ;in dam 

     dat1@long_name = " " 
     dat1@units  = ""
     dat2@long_name = " "      
     dat2@units  = ""
     res@gsnRightString       = level + "hPa"

     
     lonArray = dat1&lon
     lonArray = lonArray - cenLon
     dat1&lon = lonArray
     dat2&lon = lonArray

; create filled plot for anomalies
     plot1    = gsn_csm_contour_map(wks,dat1, res)
     plot2    = gsn_csm_contour(wks,dat2, resC)

     dat2 := f->compAnomZ(ilag,{1000.},:,:)
     dat2  = dat2*.01 ;in dam 

     dat2@long_name = " "      
     dat2@units  = ""
     dat2&lon = lonArray

     print (dat2({cenLat},{0.}))
     

     plot3    = gsn_csm_contour(wks,dat2, resC2)
     overlay(plot1,plot2)
     overlay(plot1,plot3)
;---Attach latitude labels
     lat_spacing = 20   ; use integers here
     lon_spacing = 20

     

     
  

  
 ;    gsn_polymarker(wks,plot1,cenLon,cenLat,gsres)

     txres               = True                            
     txres@txFontHeightF = .015             ; Set the font height

     cenLon = 0.
     hurri = gsn_add_text( wks, plot1, "~F37~p~F",cenLon,cenLat,txres ) 
     add_lc_labels(wks,plot1,minlat,maxlat,minlon,maxlon,lat_spacing,lon_spacing)

     
     plot(ic) = plot1

     ic = ic + 1
   end do
 end do
 resP                     = True                ; modify the panel plot    
 resP@gsnPanelLabelBar    = False                ; add common colorbar
 resP@lbLabelFontHeightF  = 0.007               ; make labels smaller
  resP@gsnPanelYWhiteSpacePercent = 5
 resP@gsnPanelXWhiteSpacePercent = 5

   gsn_panel(wks,plot,(/3,3/),resP) 
 end do

 
  end
