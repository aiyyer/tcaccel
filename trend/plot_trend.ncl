;----------------------------------------------------------------------------
; a program to:
; 
; output: pdf plot
;
;
; NCSU Tropical Dynamics Group
;
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
begin
  

  ncdf = addfile("dat.nc","r")
  
  startYear = ncdf->startYear
  endYear   = ncdf->endYear
  ave       = ncdf->ave
  latSouth  = ncdf->latSouth
  latNorth  = ncdf->latNorth
  vari = "Speed"
  vari = "Tangential Acceleration"

  
  x = ispan(startYear,endYear,1)


  N = dimsizes(x)
  dat = new( (/2,N/), typeof(ave) )
  dat = dat@_FillValue
  dat(0,:) = ave(0,:)
  

; calculate trends  
  y =  ave(0,:)
  rc :=  regline_stats(x,y) ; linear regression coef
  print( "trend = " + rc@b(1) + " pval = " + rc@pval(1))
  print( "2.5% and 97.5%  conf intervals " + rc@b95(0) + " "  +  rc@b95(1) )
  dat(1,:) = rc@Yest
  print (" " )







  
  printVarSummary(ave)

;************************************************
; plotting parameters
; This illustrates one approach. Overlays could also be used.
;************************************************
   wks  = gsn_open_wks("png","trend")             ; send graphics to PNG file
   
   res                     = True                   ; plot mods desired
   res@xyMarkLineModes     = (/"Lines","Lines"/)  ; choose which have markers
   res@xyMarkers           = 16                     ; choose type of marker 
   res@xyMarkerColor       = "red"                  ; Marker color
   res@xyMarkerSizeF       = 0.005                  ; Marker size (default 0.01)
   res@xyDashPatterns      = 1                      ; solid line 
   res@xyLineThicknesses   = (/1,3/)                ; set second line to 2
   res@tmYLFormat          = "f"                    ; not necessary but nicer labels 
   res@tiMainString        = " "  ; title

   res@xyLineColors= (/"purple", "purple","black","red"/)        ; set polymarker color
   res@xyExplicitLegendLabels = (/"ALL","NO ET,NR","Trend ALL", "Trend NO ET,NR"/)  

   res@pmLegendDisplayMode    = "Always"            ; turn on legend
   res@pmLegendSide           = "Top"               ; Change location of 
   res@pmLegendParallelPosF   = .8                  ; move units right
   res@pmLegendOrthogonalPosF = -0.26                ; move units down
   res@pmLegendWidthF         = 0.12                ; Change width and
   res@pmLegendHeightF        = 0.10                ; height of legend.
   res@lgPerimOn              = False               ; turn off box around
   res@lgLabelFontHeightF     = .013                 ; label font height

;   plotDat = new ( (/2,nn/),"float")
;   plotDat(0,:) = trend
;   plotDat(1,:) = signi

   res@tiYAxisString = vari
   res@tiXAxisString = "Year"

   res@gsnDraw             = False       ; Don't draw plots
   res@gsnFrame            = False       ; Don't advance frame
   res@xyLineThicknesses   = (/4,1/)                ; set second line to 2
 
 
;   do i = 0,0
;   plot  = gsn_csm_xy (wks,x,ave(i,:),res)           ; create plot
;   end do
;

  res@tiMainString      =" " ; "(b) Western North Pacific"



   res@trYMinF  = 10.0                   ; min value on y-axis
   res@trYMaxF  = 60.0                   ; max value on y-axis
   
   ;plot1  = gsn_csm_xy (wks,x,dat(0,:),res)           ; create plot
   ;plot2  = gsn_csm_xy (wks,x,dat(1,:),res)           ; create plot



   plot  = gsn_csm_xy (wks,x,ave,res)           ; create plot

   ;overlay(plot1,plot2)
   draw(plot)
   frame(wks)

end


