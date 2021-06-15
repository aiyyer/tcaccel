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
  txres@txFontHeightF = 0.015
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
;  flag = 2 ; for curv
  LatS =  30
  LatN =  40
  basinAnalysis = "NA" 


  levels   = (/300,500,700,850/)
  iLevel   = 1
  level    = levels(iLevel)
  varSig95 = "Z"+level+"Sig95"
  varSig05 = "Z"+level+"Sig05"

  
  sigFile  = "/home/anant/data50/data/tcaccel/composite/comp95.nc"
  ncdf = addfile(sigFile ,"r")  ; open output netCDF file

  
  compSig95=ncdf->$varSig95$
  compSig05=ncdf->$varSig05$

; also get the 1000 hPa anomalies since this is plotted on every panel


  level2 = 1000  
  varSig95 = "Z"+level2+"Sig95"
  varSig05 = "Z"+level2+"Sig05"

  comp1000Sig95=ncdf->$varSig95$
  comp1000Sig05=ncdf->$varSig05$

  
  

  if (flag .eq. 1 ) then
    accelType     = "tang"
    dir = "/home/anant/data50/data/tcaccel/composite/one/"

;    plot = new(9,"graphic")
;    types = (/"High","Zero","Low"/)
;    nmain = 3
;    titles = (/"Rapid Tangential Acceleration","Near Zero Tangential Acceleration","Rapid Tangential Deceleration"/)

    types = (/"High","Low"/)
    titles = (/"Rapid Tangential Acceleration","Rapid Tangential Deceleration"/)    
    plot = new(9,"graphic")
    nmain = 2

  else
    accelType     = "curv"
    dir = "/home/anant/data50/data/tcaccel/composite/one/"
    plot = new(9,"graphic")
    types = (/"High","Low"/)  
    titles = (/"Rapid Curvature Acceleration","Near Zero Curvature Acceleration"/)
    nmain = 2
  end if



  pltName = "composite_" + accelType  + "_" + LatN + "_" + LatS+"_alllags_"+ basinAnalysis
  pltType = "png"                       ; send graphics to PNG file







;---------------------------------------------------------------------------------------------
;---------------------------------------------------------------------------------------------
; ---------------------------------------------------------------------------------------------
  wks    = gsn_open_wks(pltType,pltName)
  resAnom                      = True     ; plot mods desired
  
 gsn_define_colormap(wks,"MPL_PRGn") ;
 ;gsn_reverse_colormap(wks)

; retrieve the colors and white the near zero values
;  colors = gsn_retrieve_colormap(wks)     ; retrieve color map for editing. dimensioned (103,3)
;  print (colors(:,0) + " " + colors(:,1) + " " +  colors(:,2) )
;  colors(6,:) = 1.0
;  colors(8,:) = 1.0
;
;  gsn_define_colormap(wks,colors)         ; redefine colormap to workstation, color map now includes a gray




  resAnom@cnFillOn            =  True    ; turn on color fill
  resAnom@cnLinesOn           =  False       ; Turn off contour lines
  resAnom@cnLineLabelsOn      =  False       ; Turn off contour lines   
  resAnom@gsnDraw             = False       ; Don't draw plots
  resAnom@gsnFrame            = False       ; Don't advance frame
  resAnom@cnInfoLabelOn     = False                ; turn off info label



  resC = resAnom
  resC@cnFillOn             =  False    ; turn on color fill
  resC@cnInfoLabelOn        = False                ; turn off info label  
  resC@cnLinesOn            =  True     ; Turn off contour lines
  resC@cnLineLabelsOn       =  False    ; Turn off contour lines   

  minlat             =  20.                ; min lat to mask
  maxlat             =  60.                ; max lat to mask
  minlon             = -20.                ; min lon to mask
  maxlon             =  30.                ; max lon to mask

  resAnom@mpProjection          = "LambertConformal"; choose projection
  resAnom@gsnMaskLambertConformal = True            ; turn on lc masking
  resAnom@mpMinLatF             = minlat
  resAnom@mpMaxLatF             = maxlat
  resAnom@mpMinLonF             = minlon
  resAnom@mpMaxLonF             = maxlon
  resAnom@mpOutlineOn           = False 
  resAnom@mpFillOn              = False
  resAnom@lbLabelBarOn = False
  resAnom@mpGridSpacingF         = 10.

  
                                ; resAnom@lbOrientation        = "vertical"   ; vertical label barb's
                                ; resAnom@lbLabelFontHeightF   = 0.012        ; change font size
                                ; resAnom@pmLabelBarWidthF     =  0.1     
                                ; resAnom@pmLabelBarOrthogonalPosF = -0.01    ; move a bit to left
  
  
  resC@cnLevelSelectionMode = "ManualLevels"	; manually set the contour levels with the following 3 resources
  resC@gsnContourLineThicknessesScale = 4

  
  gsres               = True
  gsres@gsMarkerIndex = 16          ; Use filled dots for markers.
  gsres@gsMarkerThicknessF = 0.1
  gsres@gsMarkerSizeF = 0.01

  res1000=resC
  res1000@gsnContourNegLineDashPattern   = 1       ; sets negative contours to dash pattern 1
  res1000@gsnContourZeroLineThicknessF   = 0.     ; sets negative contours to dash pattern 1
  res1000@gsnContourLineThicknessesScale = 1
  
  
  resAnom@tiMainString         = " "
; resAnom@gsnCenterString      = cd_calendar(time,-3)  
;resAnom@lbLabelBarOn = False  



; Arrays to store the TC and EC positions

  latTC = new (5,float)
  latEC = new (5,float)
  lonTC = new (5,float)
  lonEC = new (5,float)

  
  
  ic = 0    
; record the center of the TC 

  compLon = new( (/3,3/),"float")
  compLat = new( (/3,3/),"float")

  labels = (/"a)","b)","c)","d)","e)","f)","g)","h)","i)"/)
  
  ;do ilag = 1,3,1  ;lag over days 0=-2d,1=-1d,2=0d,3=+1d,4=+2d
  do ilag = 0,4
    
    hour = -48 + ilag*24 ;hard coded
    day  = -2 + ilag     ;hard coded
    



    resAnom@cnLevelSelectionMode = "ManualLevels"	; manually set the contour levels with the following 3 resources
       resC@cnLevelSelectionMode = "ManualLevels"	; manually set the contour levels with the following 3 resources

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
      resC@cnLevelSpacingF = 6.			        ; set the interval between contours
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
      resAnom@cnMinLevelValF  = -6			; set the minimum contour level
      resAnom@cnMaxLevelValF  =  6.			; set the maximum contour level
      resAnom@cnLevelSpacingF =  1.			; set the interval between contours
      resC@cnMinLevelValF  = 120.			; set the minimum contour level
      resC@cnMaxLevelValF  = 180.			; set the maximum contour level
      resC@cnLevelSpacingF = 3.			; set the interval between contours
    end if
    res1000@cnMinLevelValF  = -10.			; set the minimum contour level
    res1000@cnMaxLevelValF  =  10.			; set the maximum contour level
    res1000@cnLevelSpacingF =  .5			; set the interval between contours
    
    
; loop over types
    do imain = 1,1
      type = types(imain)
      fili = "laggedComp_" + accelType + "_"  + type  + "_" + LatN + "_" + LatS+"_"+ basinAnalysis + ".nc"

      print (fili)

      print ("--------------------------------")
      print (imain + " " + type + " day = " + day )

      f      = addfile (dir + fili, "r")
      
                                ; read the location of the composite storm

      varTemp = "cenLon"+types(imain)
      cenLon=f->$varTemp$
      varTemp = "cenLat"+types(imain)
      cenLat=f->$varTemp$
      delete(varTemp)


     
      if ( flag .eq. 1 ) then      
        if ( ic .eq. 0 .or. ic .eq. 1 .or. ic .eq. 2 ) then
          resAnom@tiMainString         = titles(imain)
        else
          resAnom@tiMainString         = " "
        end if
      else
        if ( ic .eq. 0 .or. ic .eq. 1 ) then
          resAnom@tiMainString         = titles(imain)
        else
          resAnom@tiMainString         = " "
        end if
      end if
      
;---------------------------------------------------------
      composite = f->compZ(ilag,{level},:,:)
      anomaly   = f->compAnomZ(ilag,{level},:,:)

      anomaly@long_name = " " 
      anomaly@units  = ""
      composite@long_name = " "      
      composite@units  = ""


      

      if ( composite@level .ne. compSig95@level) then
        print ("Oh oh! incompatible leves, EXIT")
        print (  composite@level  + " " +  compSig95@level )
        exit
      end if
      
      if ( composite@level .ne. compSig05@level) then
        print ("Oh oh! incompatible leves, EXIT")
        exit
      end if

      ;print ( anomaly( {20:60},{-30:30}) + " "  + compSig95( {20:60},{-30:30}) + " "  + compSig05( {20:60},{-30:30}) )
      
      
      anomaly = where( (anomaly .ge. compSig95).or.(anomaly .le. compSig05), anomaly, anomaly@_FillValue)

      anomaly   = anomaly*.01 ;in dam 
      composite = composite*.01 ;in dam 
      
      
; now change the size of the left and center string labels
      resAnom@gsnStringFontHeightF = 0.017
      resAnom@gsnRightString       = " " ;level + "hPa"
      resAnom@gsnLeftString        = labels(ic)
      resAnom@gsnCenterString        =  " Day = " + day

      print ( "cenLon = " + cenLon)
      
      lonArray = anomaly&lon
      lonArray = lonArray - cenLon
      anomaly&lon = lonArray
      composite&lon = lonArray
      cenLon = 0.0
      
      plot1    = gsn_csm_contour_map(wks,anomaly, resAnom)

; now contours for the composite
      resC@cnLineColor = "darkorange1"
      resC@cnMonoLineColor = "True"

      plot2    = gsn_csm_contour(wks,composite, resC)
      
;---------------------------------------------------------
; now add the 1000 hPa anomaly contours
      composite := f->compAnomZ(ilag,{1000.},:,:)
      ;composite= where( (composite .ge. comp1000Sig95).or.(composite .le. comp1000Sig05), composite, composite@_FillValue)

      
      composite  = composite*.01 ;in dam 
      composite@long_name = " "      
      composite@units  = ""
      composite&lon = lonArray

      printVarSummary(composite)

; locate the minimum (that is the composite storm center)
      dtemp := composite({cenLat-10:cenLat+10}, {cenLon-10:cenLon+20} )
      a1D      := ndtooned(dtemp)
      dsizes_a := dimsizes(dtemp)
      inds  := ind_resolve(minind(a1D),dsizes_a)
      ilat := inds(0,0)        ; select the latitude index where the X array is at its' minimum  
      ilon := inds(0,1)  
      latMin = dtemp&lat(ilat)
      lonMin = dtemp&lon(ilon)


      latTC(ic) = latMin
      lonTC(ic) = lonMin

; locate the maximum (that is the composite EC high)

      

      
      dtemp := anomaly({latMin-10.:latMin+20.}, {lonMin-30.:lonMin+30.} )
      a1D   := ndtooned(dtemp)
      dsizes_a := dimsizes(dtemp)
      inds  := ind_resolve(maxind(a1D),dsizes_a)
      ilat := inds(0,0)        ; select the latitude index where the X array is at its' minimum  
      ilon := inds(0,1)  
      latMax = dtemp&lat(ilat)
      lonMax = dtemp&lon(ilon)

      latEC(ic) = latMax
      lonEC(ic) = lonMax

      
      

; change color of contours
      res1000@cnLineColor      = "black"
      res1000@cnMonoLineColor = "True"

      plot3    = gsn_csm_contour(wks,composite, res1000)
      overlay(plot1,plot2)
      overlay(plot1,plot3)


;---Attach latitude labels
      lat_spacing = 10   ; use integers here
      lon_spacing = 10
  
 ;    gsn_polymarker(wks,plot1,cenLon,cenLat,gsres)
      
      txres               = True                            
      txres@txFontHeightF = .020             ; Set the font height
      

; plot the composite TC location
; 
;      cenLon = 0.
;      hurri = gsn_add_text( wks, plot1, "~F37~p~F",cenLon,cenLat,txres )

; use the hurricane symbol
      hurri = gsn_add_text( wks, plot1, "~F37~p~F",lonMin,latMin,txres )

      ECHigh = gsn_add_text( wks, plot1, "H",lonMax,latMax,txres ) 


;      hurri = gsn_add_text( wks, plot1, "+",lonMin,latMin,txres ) 

; mark the reference position by +

       txres@txFontHeightF = .040             ; Set the font height
       hurri = gsn_add_text( wks, plot1, "+",cenLon,cenLat,txres )
       txres@txFontHeightF = .020             ; Set the font height
       


       print ( latMin + " " + lonMin  +  " " + cenLat+ " " + cenLon +  " " + composite({cenLat},{0.}) + " " + composite({latMin},{lonMin}) )    
       
       add_lc_labels(wks,plot1,minlat,maxlat,minlon,maxlon,lat_spacing,lon_spacing)
       plot(ic) = plot1
       
       ic = ic + 1
     end do
   end do
   
  resP                     = True                ; modify the panel plot    
  resP@gsnPanelLabelBar    = True                ; add common colorbar
  resP@cnLabelBarEndStyle   = "ExcludeOuterBoxes" ; remove the two end boxes from the labelbar
  resP@lbLabelFontHeightF  = 0.007               ; make labels smaller
  resP@gsnPanelYWhiteSpacePercent = 5
  resP@gsnPanelXWhiteSpacePercent = 5

  
  gsn_panel(wks,plot,(/3,2/),resP) 
  




;=========================================================================================



  
  resAnom@gsnLeftString          = "(b)"

  resAnom@mpGridAndLimbOn        = True               ; turn on grid lines

  resAnom@gsnCenterString        = " " ; "(a)" +  titles(imain-1)
  resAnom@cnFillOn    = False
  plot1    = gsn_csm_contour_map(wks,anomaly, resAnom)
  add_lc_labels(wks,plot1,minlat,maxlat,minlon,maxlon,lat_spacing,lon_spacing)

 

 


  gsres               = True
  gsres@gsMarkerIndex = 16          ; Use filled dots for markers
  gsres@gsMarkerSizeF     = .007          ; polymarker size
  gsres@gsLineThicknessF = 3.0
  


  gsres@gsLineColor    =  "blue"
  gsres@gsMarkerColor  =  "blue"


  dumG1 = gsn_add_polyline(wks,plot1,lonTC,latTC,gsres)
  gsres@gsMarkerIndex = 16          ; Use filled dots for markers
  txres@txFontHeightF = .010             ; Set the font height
  txres@txFontColor  =  "blue"




  hurri2    = new(40,"graphic")
  ECHigh2    = new(40,"graphic")

  iik = 0
  do i = 0,4
    print (latTC(i) + " " + latEC(i) + " " + lonTC(i) + " " + lonEC(i) )
    gsres@gsMarkerSizeF     = .007          ; polymarker size
    txres@txFontHeightF = .010             ; Set the font height
    ;hurri2(iik) = gsn_add_polymarker( wks, plot1,lonTC(i),latTC(i),gsres )
    gsres@gsMarkerColor  =  "darkorange"
    if ( i.eq. 0 ) then
      gsres@gsMarkerSizeF     = .012          ; polymarker size
      txres@txFontHeightF    = .012             ; Set the font height
    end if
    hurri = gsn_add_text( wks, plot1, "~F37~p~F",lonTC(i),latTC(i),txres )
    ECHigh2(iik) = gsn_add_polymarker( wks, plot1,lonEC(i),latEC(i),gsres )
    iik = iik+1
  end do
 
  gsres@gsLineColor    =  "darkorange"

  dumG2 = gsn_add_polyline(wks,plot1,lonEC,latEC,gsres)

  draw(plot1)
  frame(wks)


;==================================================================================================
; phase speeds

  
  pi = 4.*atan(1.)
  piRad = pi/180.
  Rearth = 6.4e6
  dt = 24.*3600.*4. ; 4 days



  latAve = avg(latEC(2:4))
  lon2 =  lonEC(4)
  lon1 =  lonEC(0)
  dLon =  lon2-lon1
  print ( "dLon, aveLat= " + dLon + " " + latAve)
  cp = (Rearth*cos(latAve*piRad)*dLon*piRad)/ dt
  print ("Phase speed of EC High  = " + cp)


  latAve = avg(latTC(2:4))
  lon2 =  lonTC(4)
  lon1 =  lonTC(0)
  dLon =  lon2-lon1
  print ( "dLon, aveLat= " + dLon + " " + latAve)
  cp = (Rearth*cos(latAve*piRad)*dLon*piRad)/ dt
  print ("speed of TC  = " + cp)

  


  end
;==================================================================================================
;==================================================================================================
;==================================================================================================
