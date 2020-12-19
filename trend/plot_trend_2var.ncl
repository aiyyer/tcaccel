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

  dir = "1966/"

  vari = "Speed (km/hr)"
  
 
 
  file1 = dir + "speed_NA_20_50_B.nc"
  file2 = dir + "speed_NA_20_50_A.nc"
  mainTitle      = "(b) [20-50 N] North Atlantic"
   
 file1 = dir + "speed_NA_0_90_B.nc"
  file2 = dir + "speed_NA_0_90_A.nc"
  mainTitle      = "(a) Entire North Atlantic"


;vari = "Tangential Acceleration ( [km/hr]/day )"


  ; ALL 
  ncdf = addfile(file1 ,"r")  ; open output netCDF file
  startYear1 = ncdf->startYear
  endYear1   = ncdf->endYear
  ave1   = ncdf->ave

  ; Exclude NR, ET
  ncdf = addfile(file2 ,"r")  ; open output netCDF file
  startYear2 = ncdf->startYear
  endYear2   = ncdf->endYear
  ave2       = ncdf->ave


  if ( startYear1 .ne. startYear2 ) then
    print ("start year mismatch! terminating!!")
    exit
  end if
  if ( endYear1 .ne. endYear2 ) then
    print ("end year mismatch! terminating!!")
    exit
  end if
  x = ispan(startYear1,endYear1,1)


  N = dimsizes(x)
  dat = new( (/4,N/), typeof(ave1) )
  dat = dat@_FillValue
  dat(0,:) = ave1(0,:)
  dat(1,:) = ave2(0,:)
  


; calculate trends  
  y =  ave1(0,:)
  rc :=  regline_stats(x,y) ; linear regression coef
  print( "trend = " + rc@b(1) + " pval = " + rc@pval(1))
  print( "2.5% and 97.5%  conf intervals " + rc@b95(0) + " "  +  rc@b95(1) )
  dat(2,:) = rc@Yest
  print (" " )

; calculate trends  
  y =  ave2(0,:)
  rc :=  regline_stats(x,y) ; linear regression coef
  print( "trend = " + rc@b(1) + " pval = " + rc@pval(1))
  print( "2.5% and 97.5%  conf intervals " + rc@b95(0) + " "  +  rc@b95(1) )
  dat(3,:) = rc@Yest



  
;************************************************
; plotting parameters
; This illustrates one approach. Overlays could also be used.
;************************************************
   wks  = gsn_open_wks("png","trend")             ; send graphics to PNG file
   
   res                     = True                   ; plot mods desired
   res@xyMarkers           = 16                     ; choose type of marker 
   res@xyMarkerColor       = "red"                  ; Marker color
   res@xyMarkerSizeF       = 0.005                  ; Marker size (default 0.01)
   res@tmYLFormat          = "f"                    ; not necessary but nicer labels 
   res@tiMainString        = " "  ; title
   res@xyLineColors= (/"magenta", "orange","black","red"/)        ; set polymarker color
   res@xyExplicitLegendLabels = (/"ALL","NO ET,NR","Trend ALL", "Trend NO ET,NR"/)
   
   res@pmLegendDisplayMode    = "Always"            ; turn on legend
   res@pmLegendSide           = "Top"               ; Change location of 
 
   res@pmLegendDisplayMode    = "Always"            ; turn on legend
   res@pmLegendSide           = "Top"               ; Change location of 
   res@pmLegendParallelPosF   = .2                  ; move units right
   res@pmLegendOrthogonalPosF = -0.26                ; move units down
   res@pmLegendWidthF         = 0.12                ; Change width and
   res@pmLegendHeightF        = 0.10                ; height of legend.
   res@lgPerimOn              = False               ; turn off box around
   res@lgLabelFontHeightF     = .013                 ; label font height
   res@lgItemOrder  = (/3,2,1,0/)   ; Reorder the legends


   res@gsnDraw             = False       ; Don't draw plots
   res@gsnFrame            = False       ; Don't advance frame
   
   res@tiYAxisString = vari
   res@tiXAxisString = "Year"





   res@tiMainString      = mainTitle
   
   ;res@tiMainString      = "Western North Pacific"

   res@trYMinF  = 14.0                   ; min value on y-axis
   res@trYMaxF  = 34.0
   res@xyDashPatterns      = (/0,0,0,0/)                    ; solid line
   res@xyDashPatterns      = (/2,2,2,2/)                    ; solid line
      
   res@xyLineThicknesses   = (/6,6,6,6/)                ; set second line to 2
   plot1  = gsn_csm_xy(wks,x,dat(0:1,:),res)           ; create plot
   ;plot1  = gsn_csm_xy(wks,x,dat(0:0,:),res)           ; create plot

   res@xyDashPatterns      = (/0,0,0,0/)                    ; solid line

   res@xyLineThicknesses   = (/2,2,2,2/)                ; set second line to 2
   res@pmLegendDisplayMode    = "Never"            ; turn on legend
   ;plot2  = gsn_csm_xy(wks,x,dat(2:2,:),res)           ; create plot
   plot2  = gsn_csm_xy(wks,x,dat(2:3,:),res)           ; create plot

   overlay(plot1,plot2)
   draw(plot1)
   frame(wks)
end


