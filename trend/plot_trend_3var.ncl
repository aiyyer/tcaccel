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






  file1 = dir + "tang_NA_B_one.nc"
  file2 = dir + "tang_NA_B_two.nc"
  file3 = dir + "tang_NA_B_three.nc"
  mainTitle = "(b) Atlantic [all storms]"


  file1 = dir + "tang_NA_A_one.nc"
  file2 = dir + "tang_NA_A_two.nc"
  file3 = dir + "tang_NA_A_three.nc"
  mainTitle = "Atlantic [ET, NR Excluded]"

  
  file1 = dir + "tang_NA_20_40_A_one.nc"
  file2 = dir + "tang_NA_20_40_A_two.nc"
  file3 = dir + "tang_NA_20_40_A_three.nc"
  mainTitle = "Atlantic (20-40N) [ET, NR Excluded]"

  legendLabs = (/"90th %", "80th %", "60th %"/) 


  
  vari = "Speed"
  vari = "Tangential Acceleration"


  ncdf = addfile(file1 ,"r")  ; open output netCDF file
  startYear1 = ncdf->startYear
  endYear1   = ncdf->endYear
  ave1   = ncdf->ave

 ; 
  ncdf = addfile(file2 ,"r")  ; open output netCDF file
  startYear2 = ncdf->startYear
  endYear2   = ncdf->endYear
  ave2       = ncdf->ave
  
  ncdf = addfile(file3 ,"r")  ; open output netCDF file
  startYear3 = ncdf->startYear
  endYear3   = ncdf->endYear
  ave3       = ncdf->ave


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
  dat = new( (/6,N/), typeof(ave1) )
  dat = dat@_FillValue
  dat(0,:) = ave1(0,:)
  dat(1,:) = ave2(0,:)
  dat(2,:) = ave3(0,:)



; calculate trends  
  y =  ave1(0,:)
  rc :=  regline_stats(x,y) ; linear regression coef
  print( "trend = " + rc@b(1) + " pval = " + rc@pval(1))
  print( "2.5% and 97.5%  conf intervals " + rc@b95(0) + " "  +  rc@b95(1) )
  dat(3,:) = rc@Yest
  print (" " )

; calculate trends  
  y =  ave2(0,:)
  rc :=  regline_stats(x,y) ; linear regression coef
  print( "trend = " + rc@b(1) + " pval = " + rc@pval(1))
  print( "2.5% and 97.5%  conf intervals " + rc@b95(0) + " "  +  rc@b95(1) )
  dat(4,:) = rc@Yest
  print (" " )

; calculate trends  
  y =  ave3(0,:)
  rc :=  regline_stats(x,y) ; linear regression coef
  print( "trend = " + rc@b(1) + " pval = " + rc@pval(1))
  print( "2.5% and 97.5%  conf intervals " + rc@b95(0) + " "  +  rc@b95(1) )
  dat(5,:) = rc@Yest



  
;************************************************
; plotting parameters
; This illustrates one approach. Overlays could also be used.
;************************************************
   wks  = gsn_open_wks("png","trend")             ; send graphics to PNG file
   
   res                     = True                   ; plot mods desired
   res@xyMarkLineModes     = (/"Lines","Lines","Lines","Lines"/)  ; choose which have markers
   res@xyMarkerColor       = "red"                  ; Marker color
   res@xyMarkerSizeF       = 0.005                  ; Marker size (default 0.01)
   res@tmYLFormat          = "f"                    ; not necessary but nicer labels 
   res@tiMainString        = " "  ; title
   res@xyLineColors= (/"purple", "green","black","red"/)        ; set polymarker color
   res@xyExplicitLegendLabels = legendLabs
   res@pmLegendDisplayMode    = "Always"            ; turn on legend
   res@pmLegendSide           = "Top"               ; Change location of 
 
   res@pmLegendDisplayMode    = "Always"            ; turn on legend
   res@pmLegendSide           = "Top"               ; Change location of 
   res@pmLegendParallelPosF   = .8                  ; move units right
   res@pmLegendOrthogonalPosF = -0.3                ; move units down
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
   res@trYMinF  = 10.0                   ; min value on y-axis
   res@trYMaxF  = 60.0
   res@xyDashPatterns      =     (/2,2,2,2,2,2/)                    ; solid line 
   res@xyLineThicknesses   = (/6,6,6,6,6,6/)                ; set second line to 2

   plot1  = gsn_csm_xy(wks,x,dat(0:2,:),res)           ; create plot

   res@xyLineThicknesses   = (/2,2,2,2,2,2/)                ; set second line to 2
   res@xyDashPatterns      =     (/0,0,0,0,0,0/)                    ; solid line 

   res@pmLegendDisplayMode    = "Never"            ; turn on legend
   plot2  = gsn_csm_xy(wks,x,dat(3:5,:),res)           ; create plot
   overlay(plot1,plot2)
   draw(plot1)
   frame(wks)
end


