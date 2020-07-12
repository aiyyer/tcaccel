;***************************************************************
;NCSU Tropical Dynamics
;A. Aiyyer 06/19/2019
;
;A basic code for plotting
;
;
;***************************************************************
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
  

  
  res@mpMinLatF            = 10.     ; CMORPH limits [approx]
  res@mpMaxLatF            = 60.
  res@mpMinLonF            = -180.     ; CMORPH limits [approx]
  res@mpMaxLonF            =  180.   
  res@mpFillOn             = False
  
  
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

  resC@gsnContourLineThicknessesScale = 0.0
  
  plot = new(9,"graphic")

  resC2=resC
  
  
  resC2@gsnContourNegLineDashPattern = 1       ; sets negative contours to dash pattern 1
  resC2@gsnContourZeroLineThicknessF=0.     ; sets negative contours to dash pattern 1
  resC2@gsnContourLineThicknessesScale = 1.0
  
  
  res@tiMainString         = " "
;  res@gsnCenterString      = cd_calendar(time,-3)
  
  
  ;res@lbLabelBarOn = False  
  
  diri   = "./"                             ; input directory     
  
  types = (/"High","Zero","Low"/)
 
  titles = (/"Strong Acceleration","Near Zero Acceleration","Strong Deceleration"/)



  levels = (/200,500,800/)

  ic = 0
  do iuber = 0,2
  level = levels(iuber)



  if (level .eq. 200 ) then
    res@cnMinLevelValF  = -12			; set the minimum contour level
    res@cnMaxLevelValF  =  12.			; set the maximum contour level
    res@cnLevelSpacingF =  2.			; set the interval between contours
    
    resC@cnMinLevelValF  = 680			; set the minimum contour level
    resC@cnMaxLevelValF  = 1300.			; set the maximum contour level
    resC@cnLevelSpacingF = 12.			; set the interval between contours
    
    resC2@cnMinLevelValF  = -10			; set the minimum contour level
    resC2@cnMaxLevelValF  =  0.			; set the maximum contour level
    resC2@cnLevelSpacingF =  2.			; set the interval between contours
  end if
  
  if (level .eq. 500 ) then
    res@cnMinLevelValF  = -6			; set the minimum contour level
    res@cnMaxLevelValF  =  6.			; set the maximum contour level
    res@cnLevelSpacingF =  1.			; set the interval between contours
    
    resC@cnMinLevelValF  = 380			; set the minimum contour level
    resC@cnMaxLevelValF  = 580.			; set the maximum contour level
    resC@cnLevelSpacingF = 6.			; set the interval between contours
    
    resC2@cnMinLevelValF  = -10			; set the minimum contour level
    resC2@cnMaxLevelValF  =  0.			; set the maximum contour level
    resC2@cnLevelSpacingF =  2.			; set the interval between contours
  end if
  
  
  if (level .eq. 800 ) then
    res@cnMinLevelValF  = -6			; set the minimum contour level
    res@cnMaxLevelValF  =  6.			; set the maximum contour level
    res@cnLevelSpacingF =  1.			; set the interval between contours
    
    resC@cnMinLevelValF  = 160			; set the minimum contour level
    resC@cnMaxLevelValF  = 210.			; set the maximum contour level
    resC@cnLevelSpacingF = 4.			; set the interval between contours
    
    resC2@cnMinLevelValF  = -10			; set the minimum contour level
    resC2@cnMaxLevelValF  =  0.			; set the maximum contour level
    resC2@cnLevelSpacingF =  2.			; set the interval between contours
  end if
  

  do imain = 0,2
    
    type = types(imain)
    
     
     fili   = "laggedComp_30_40_"+type +".nc"
     
     pltDir  = "./"                        ; directory for plot output
     
     f      = addfile (diri+fili, "r")
     
     cenLon=f->cenLon
     cenLat=f->cenLat
     
     ilag=0
     
     hour = -12 + ilag*6

     res@tiMainString         = titles(imain) + " Composite for " + level + " hPa"

     dat2 = f->compZ(ilag,{level},:,:)
     dat1 = f->compAnomZ(ilag,{level},:,:)
     dat1 = dat1*.01 ;in dam 
     dat2 = dat2*.01 ;in dam 

     dat1@long_name = " " 
     dat1@units  = ""
     dat2@units  = ""


; create filled plot for anomalies
     plot1    = gsn_csm_contour_map(wks,dat1, res)



     plot2    = gsn_csm_contour(wks,dat2, resC)

     
     dat2 = f->compAnomZ(ilag,{1000.},:,:)
     dat2 = dat2*.01 ;in dam 
     dat2@units  = ""

     print (dat2({cenLat},{cenLon}))
     

     plot3    = gsn_csm_contour(wks,dat2, resC2)
     overlay(plot1,plot2)
     overlay(plot1,plot3)


     print (cenLon + " " + cenLat)
     
  

  
 ;    gsn_polymarker(wks,plot1,cenLon,cenLat,gsres)

     txres               = True                            
     txres@txFontHeightF = .015             ; Set the font height

     hurri = gsn_add_text( wks, plot1, "~F37~p~F",cenLon,cenLat,txres ) 

     plot(ic) = plot1

     ic = ic + 1
   end do
 end do

   resP                     = True                ; modify the panel plot    
   resP@gsnPanelLabelBar    = False                ; add common colorbar
   resP@lbLabelFontHeightF  = 0.007               ; make labels smaller
 

   gsn_panel(wks,plot,(/3,3/),resP) 

  end
