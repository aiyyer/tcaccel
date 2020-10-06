;==================================================================================================
;==================================================================================================
;==================================================================================================
;
;NCSU Tropical Dynamics
;A. Aiyyer 06/19/2019
;
;
;==================================================================================================
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


  sigFile  = "/home/anant/data50/data/tcaccel/composite/comp95.nc"
  sigIn    = addfile(sigFile ,"r")  ; open output netCDF file

  

  if (flag .eq. 1 ) then
    accelType     = "tang"
    dir = "/home/anant/data50/data/tcaccel/composite/one/"
    ;plot = new(9,"graphic")
    ;types = (/"High","Zero","Low"/)
    ;titles = (/"Rapid Tangential Acceleration","Near Zero Tangential Acceleration","Rapid Tangential Deceleration"/)

    types = (/"High","Zero"/)  
    titles = (/"Rapid Tangential Acceleration","Rapid Tangential Deceleration"/)
    plot = new(6,"graphic")
    nmain = 2
  else
    accelType     = "curv"
    dir = "/home/anant/data50/data/tcaccel/composite/one/"
    plot = new(6,"graphic")
    types = (/"High","Zero"/)  
    titles = (/"Rapid Curvature Acceleration","Near Zero Curvature Acceleration"/)
    nmain = 2
  end if

  plot = new(6,"graphic")

  labels = (/"a)","b)","c)","d)","e)","f)","g)","h)","i)"/)
  labels = (/"a)","d)","b)","e)","c)","f)","g)","h)","i)"/)

  pltName = "composite_" + accelType  + "_" + LatN + "_" + LatS+"_"+ basinAnalysis
  pltType = "png"                       ; send graphics to PNG file

  wks    = gsn_open_wks(pltType,pltName)
  resAnom                      = True     ; plot mods desired



  ;gsn_define_colormap(wks,"UKM_hadcrut") ;temp_diff_18lev")
 gsn_define_colormap(wks,"MPL_PRGn") ;

; retrieve the colors and white the near zero values
;      colors = gsn_retrieve_colormap(wks)     ; retrieve color map for editing. dimensioned (103,3)
;      colors(12,:) = 1.0
;      colors(10,:) = 1.0
;      gsn_define_colormap(wks,colors)         ; redefine colormap to workstation, color map now includes a gray

  
  ;gsn_reverse_colormap(wks)

  
  resAnom@cnFillOn            =  True    ; turn on color fill
  resAnom@cnLinesOn           =  False       ; Turn off contour lines
  resAnom@cnLineLabelsOn      =  False       ; Turn off contour lines   
  resAnom@gsnDraw             = False       ; Don't draw plots
  resAnom@gsnFrame            = False       ; Don't advance frame
  
  resC = resAnom
  resC@cnFillOn             =  False    ; turn on color fill
  resC@cnLinesOn            =  True     ; Turn off contour lines
  resC@cnLineLabelsOn       =  False    ; Turn off contour lines   
  
  
  resAnom@cnLevelSelectionMode = "ManualLevels"	; manually set the contour levels with the following 3 resources
  

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
  resAnom@lbLabelBarOn = False
  
                                ; resAnom@lbOrientation        = "vertical"   ; vertical label barb's
                                ; resAnom@lbLabelFontHeightF   = 0.012        ; change font size
                                ; resAnom@pmLabelBarWidthF     =  0.1     
                                ; resAnom@pmLabelBarOrthogonalPosF = -0.01    ; move a bit to left
  
  
  resC@cnLevelSelectionMode = "ManualLevels"	; manually set the contour levels with the following 3 resources
  
  resAnom@cnInfoLabelOn     = False                ; turn off info label
  resC@cnInfoLabelOn     = False                ; turn off info label  
  
  gsres               = True
  gsres@gsMarkerIndex = 16          ; Use filled dots for markers.
                                ;gsres@gsMarkerThicknessF = 0.1
  gsres@gsMarkerSizeF = 0.015
  resC@gsnContourLineThicknessesScale = 4
  

  res1000=resC
  res1000@gsnContourNegLineDashPattern   = 1       ; sets negative contours to dash pattern 1
  res1000@gsnContourZeroLineThicknessF   = 0.     ; sets negative contours to dash pattern 1
  res1000@gsnContourLineThicknessesScale = 1
  
  
  resAnom@tiMainString         = " "
; resAnom@gsnCenterString      = cd_calendar(time,-3)  
;resAnom@lbLabelBarOn = False  




  levels = (/300,500,850/)
  ic = 0    


; record the center of the TC 

  compLon = new( (/3,3/),"float")
  compLat = new( (/3,3/),"float")


  ilag = 2   ;lag over days 0=-2d,1=-1d,2=0d,3=+1d,4=+2d

  do iLevel = 0,2



    hour = -48 + ilag*24 ;hard coded
    day  = -2 + ilag     ;hard coded
    
    level = levels(iLevel)
    
    var = "Z"+level+"Sig95"
    compSig95=sigIn->$var$
    var = "Z"+level+"Sig05"
    compSig05=sigIn->$var$


    if (level .eq. 300 ) then
      resAnom@cnMinLevelValF  = -10.			; set the minimum contour level
      resAnom@cnMaxLevelValF  =  10.			; set the maximum contour level
      resAnom@cnLevelSpacingF =  2.			; set the interval between contours
      resC@cnMinLevelValF  = 640.			; set the minimum contour level
      resC@cnMaxLevelValF  = 1600.			; set the maximum contour level
      resC@cnLevelSpacingF = 12.			; set the interval between contours
    end if



    if (level .eq. 500 ) then
      resAnom@cnMinLevelValF  = -5			; set the minimum contour level
      resAnom@cnMaxLevelValF  =  5.			; set the maximum contour level
      resAnom@cnLevelSpacingF =  1.			; set the interval between contours
      
      resC@cnMinLevelValF  = 460.			; set the minimum contour level
      resC@cnMaxLevelValF  = 600.			; set the maximum contour level
      resC@cnLevelSpacingF = 6.			; set the interval between contours
    end if



    if (level .eq. 700 ) then
      resAnom@cnMinLevelValF  = -6			; set the minimum contour level
      resAnom@cnMaxLevelValF  =  6.			; set the maximum contour level
      resAnom@cnLevelSpacingF =  1.			; set the interval between contours
      resC@cnMinLevelValF  = 270.			; set the minimum contour level
      resC@cnMaxLevelValF  = 330.			; set the maximum contour level
      resC@cnLevelSpacingF = 3.			; set the interval between contours
    end if


    if (level .eq. 850 ) then
      resAnom@cnMinLevelValF  = -5			; set the minimum contour level
      resAnom@cnMaxLevelValF  =  5.			; set the maximum contour level
      resAnom@cnLevelSpacingF =  1.			; set the interval between contours
      resC@cnMinLevelValF  = 120.			; set the minimum contour level
      resC@cnMaxLevelValF  = 180.			; set the maximum contour level
      resC@cnLevelSpacingF = 3.			; set the interval between contours
    end if



    res1000@cnMinLevelValF  = -10.			; set the minimum contour level
    res1000@cnMaxLevelValF  =  10.			; set the maximum contour level
    res1000@cnLevelSpacingF =  1.			; set the interval between contours
    
    

; loop over types
    do imain =  0,nmain-1

      type = types(imain)
      fili = "laggedComp_" + accelType + "_"  + type  + "_" + LatN + "_" + LatS+"_"+ basinAnalysis + ".nc"

      print ("--------------------------------")
      print (imain + " " + type + " day = " + day )

      f      = addfile (dir+fili, "r")
      
                                ; read the location of the composite storm

      cenVar = "cenLon"+type
      cenLon=f->$cenVar$
      cenVar = "cenLat"+type
      cenLat=f->$cenVar$
      
      if ( ic .eq. 0 .or. ic .eq. 1 .or. ic .eq. 2 ) then
        resAnom@tiMainString         = titles(imain)
      else
        resAnom@tiMainString         = " "
      end if
      
      if ( ic .eq. 0 .or. ic .eq. 1  ) then
        resAnom@tiMainString         = titles(imain)
      else
        resAnom@tiMainString         = " "
      end if
     
;---------------------------------------------------------
      comp     =    f->compZ(ilag,{level},:,:)
      compAnom =    f->compAnomZ(ilag,{level},:,:)


      compAnom =    where( (comp .lt. compSig95) .and.  (comp .gt. compSig05), compAnom@_FillValue, compAnom)
      ;comp       =    where( (comp .ge. compSig95) .and.  (comp .gt. compSig05),     comp@_FillValue, comp)
      compAnom = compAnom*.01 ;in dam 
      comp = comp*.01 ;in dam 
      compAnom@long_name = " " 
      compAnom@units  = ""
      comp@long_name = " "      
      comp@units  = ""
      resAnom@gsnRightString       =  level + "hPa"
      resAnom@gsnLeftString        = labels(ic)
      resAnom@gsnCenterString        = " " ;+ " Day = " + day

      resAnom@gsnStringFontHeightF = 0.02

      
      lonArray = compAnom&lon
      lonArray = lonArray - cenLon
      compAnom&lon = lonArray
      comp&lon = lonArray
      cenLon = 0.0
; create filled plot for anomalies


; create filled plot for composite anomalies


      plot1    = gsn_csm_contour_map(wks,compAnom, resAnom)


      resC@cnLineColor = "darkorange1"
      resC@cnMonoLineColor = "True"

      plot2    = gsn_csm_contour(wks,comp, resC)
      
;---------------------------------------------------------
; now add the 1000 hPa contours

      comp := f->compAnomZ(ilag,{1000.},:,:)
      comp  = comp*.01 ;in dam 
      comp@long_name = " "      
      comp@units  = ""
      comp&lon = lonArray
; locate the minimum (that is the composite storm center)
      dtemp = comp({cenLat-10:cenLat+10}, {cenLon-10:cenLon+10} )
      a1D      = ndtooned(dtemp)
      dsizes_a = dimsizes(dtemp)
      inds  = ind_resolve(minind(a1D),dsizes_a)
      ilat = inds(0,0)        ; select the latitude index where the X array is at its' minimum  
      ilon = inds(0,1)  
      latMin = dtemp&lat(ilat)
      lonMin = dtemp&lon(ilon)

      ; write out the 1000 hPa anomalies in dam
      print ( latMin + " " + lonMin  +   " " + comp({cenLat},{0.}) + " " + comp({latMin},{lonMin}) )    


; change color of contours
      
      res1000@cnLineColor = "black"
      res1000@cnMonoLineColor = "True"
      plot3    = gsn_csm_contour(wks,comp, res1000)
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
      hurri = gsn_add_text( wks, plot1, "+",lonMin,latMin,txres ) 


      add_lc_labels(wks,plot1,minlat,maxlat,minlon,maxlon,lat_spacing,lon_spacing)
      
      
      plot(ic) = plot1
      
      ic = ic + 1
    end do
  end do

  resP                     = True                ; modify the panel plot    
  ;resP@gsnPanelLabelBar    = True                ; add common colorbar
  resP@lbLabelFontHeightF  = 0.007               ; make labels smaller
  resP@gsnPanelYWhiteSpacePercent = 5
  resP@gsnPanelXWhiteSpacePercent = 5
  
  gsn_panel(wks,plot,(/3,2/),resP) 


 
  end
;==================================================================================================
;==================================================================================================
;==================================================================================================
