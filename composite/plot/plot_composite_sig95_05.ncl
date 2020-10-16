;================================================================
;
;NCSU Tropical Dynamics
;A. Aiyyer 06/19/2019
;
;updated 07/15/2020
;
;================================================================
;================================================================
;================================================================
;
;
;
;***************************************************************
; code adapted from ncl examples
;***************************************************************
;
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
;wp
  
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
; Main code
;===========================================================================
;===========================================================================



begin


;***************************************************************
; User Input
;***************************************************************

  flag = 1 ; for tang
  flag = 2 ; for curv
  LatS =  30
  LatN =  40
  basinAnalysis = "NA" 

   
  plot = new(2,"graphic")
  
  pltName = "sig_map"
  pltType = "png"                       ; send graphics to PNG file
  sigFile  = "/home/anant/data50/data/tcaccel/composite/comp95.nc"
  ncdf = addfile(sigFile ,"r")  ; open output netCDF file


  
  comp500Sig95=ncdf->Z500Sig95
  comp500Sig05=ncdf->Z500Sig05

  
  

  
  comp300Sig95=ncdf->Z300Sig95
  comp300Sig05=ncdf->Z300Sig05

  


  
  comp850Sig95=ncdf->Z300Sig95
  comp850Sig05=ncdf->Z300Sig05

  
  cenLon = 296.719
  
  lonArray =comp500Sig95&lon
  lonArray = lonArray - cenLon


  comp300Sig95&lon = lonArray
  comp300Sig05&lon = lonArray
  comp500Sig95&lon = lonArray
  comp500Sig05&lon = lonArray
  comp850Sig95&lon = lonArray
  comp850Sig05&lon = lonArray




  cenLon = 0.0

;---------------------------------------------------------------------------------------------
;---------------------------------------------------------------------------------------------
; ---------------------------------------------------------------------------------------------
  wks    = gsn_open_wks(pltType,pltName)
  resAnom                      = True     ; plot mods desired
  
 gsn_define_colormap(wks,"MPL_PRGn") ;
 resAnom@cnFillOn            =  True    ; turn on color fill
 resAnom@cnLinesOn           =  False       ; Turn off contour lines
 resAnom@cnLineLabelsOn      =  False       ; Turn off contour lines   
 resAnom@gsnDraw             = False       ; Don't draw plots
 resAnom@gsnFrame            = False       ; Don't advance frame
 resAnom@cnInfoLabelOn     = False                ; turn off info label

 minlat             =  20.                ; min lat to mask
 maxlat             =  70.                ; max lat to mask
 minlon             = -130.                ; min lon to mask
 maxlon             =  10.                ; max lon to mask
 minlon             = -60.                ; min lon to mask
 maxlon             =  60.                ; max lon to mask
 
 resAnom@mpProjection          = "LambertConformal"; choose projection
 resAnom@gsnMaskLambertConformal = True            ; turn on lc masking
 resAnom@mpMinLatF             = minlat
 resAnom@mpMaxLatF             = maxlat
 resAnom@mpMinLonF             = minlon
 resAnom@mpMaxLonF             = maxlon
 resAnom@mpOutlineOn           = False 
 resAnom@mpFillOn              = False
 resAnom@lbLabelBarOn =  True
 
   

  
  
  resAnom@tiMainString         = " "
; resAnom@gsnCenterString      = cd_calendar(time,-3)  
;resAnom@lbLabelBarOn = False  


  levels = (/300,500,850/)
  iLevel = 1
  level = levels(iLevel)

  plot(0)    = gsn_csm_contour_map(wks,comp500Sig95,resAnom)
  plot(1)    = gsn_csm_contour_map(wks,comp500Sig05,resAnom)

  
;---Attach latitude labels
  lat_spacing = 20   ; use integers here
  lon_spacing = 20
  
  add_lc_labels(wks,plot(0),minlat,maxlat,minlon,maxlon,lat_spacing,lon_spacing)
  add_lc_labels(wks,plot(1),minlat,maxlat,minlon,maxlon,lat_spacing,lon_spacing)


   
  resP                     = True                ; modify the panel plot    
  resP@gsnPanelLabelBar    = False                ; add common colorbar
  resP@cnLabelBarEndStyle   = "ExcludeOuterBoxes" ; remove the two end boxes from the labelbar
  resP@lbLabelFontHeightF  = 0.007               ; make labels smaller
  resP@gsnPanelYWhiteSpacePercent = 5
  resP@gsnPanelXWhiteSpacePercent = 5

  
  gsn_panel(wks,plot,(/2,1/),resP) 


 
  end
;==================================================================================================
;==================================================================================================
;==================================================================================================
