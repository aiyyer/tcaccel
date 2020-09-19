; This program reads era data to extract the 
; create eke hovmoller 
;
;
;---------------------------------------------------------------------------------------------
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"   
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"   
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
;load "grid_rotate.ncl"
;load "../nclsubs/codeTime_sub.ncl"

begin

  flag = 1 ; for tang
  ;flag = 2 ; for curv

  imain = 2
  itype = 2
  
  LatS =  30
  LatN =  40
  basinAnalysis = "NA" 


  if (flag .eq. 1 ) then
    accelType     = "tang"
    dir = "~/data50/data/tcaccel/one/tang/" 
    plot = new(9,"graphic")
    types = (/"High","Zero","Low"/)
    titles = (/"Rapid Tangential Acceleration","Near Zero Tangential Acceleration","Rapid Tangential Deceleration"/)    
    nmain = 3
  else
    accelType     = "curv"
    dir = "~/data50/data/tcaccel/one/curv/" 
    plot = new(6,"graphic")
    types = (/"High","Zero"/)  
    titles = (/"Rapid Curvature Acceleration","Near Zero Curvature Acceleration"/)
    nmain = 2
  end if


  levels = (/300,500,750/)

  var = "compAnomZ"


  

  type = types(imain)
  fili = "laggedComp_" + accelType + "_"  + type  + "_" + LatN + "_" + LatS+"_"+ basinAnalysis + ".nc"

  level =  300
  hovLat1 = 36.
  hovLat2 = 46.

  inFile = addfile( dir+fili, "r" )
  comp  = lonFlip(inFile->$var$(:,{level},:,:))
  comp=comp*.01 ; dam
  comp@units = "dam"
  printVarSummary(comp)
  varTemp = "cenLon"+types(itype)
  cenLon =  inFile->$varTemp$


  lagN = -24*2
  lagP =  24*2
  dt  = 24
  nlag = (lagP-lagN)/dt + 1
  lagHour = new(nlag,float)    ; Array to hold y-axis labels
  il = 0
  do lag = lagN,lagP,dt
    lagHour(il) = lag
    il = il + 1
  end do
  
  Hov   = dim_avg_n_Wrap( comp(:,{hovLat1:hovLat2},:),1)
  Hov!0 = "days"
  Hov!1 = "lon"
  Hov&days = lagHour/24.  

 ; Hov&lon = Hov&lon - cenLon  ; shift the long to make it tc-relative

  
  printVarSummary(Hov)
  print( min(Hov) + " " + max(Hov) )

;---------------------------------------------------------------------
  hovFile = "hov" + type +  level
  wks = gsn_open_wks("pdf",hovFile)                 ; open a ps file
  Anomres = True
  Anomres@gsnDraw      =  False                   ; do not draw the plot
  Anomres@gsnFrame     =  False                   ; do not advance the frame  
  Anomres@trYReverse   = True                   ; reverse y axis
  Anomres@gsnDraw      =  False                   ; do not draw the plot
  Anomres@gsnFrame     =  False                   ; do not advance the frame
  Anomres@cnFillOn        = False                  ; color fill
  Anomres@cnLinesOn       = True                 ; do not draw contour lines
  Anomres@gsnCenterString      = " "             ; plot center string
  Anomres@gsnContourZeroLineThicknessF = 0.            ; doubles thickness of zero contour
  Anomres@gsnContourNegLineDashPattern = 1       ; sets negative contours to dash pattern 1
  Anomres@cnInfoLabelOn = False
  Anomres@cnLevelSelectionMode = "ManualLevels"     ; set manual contour levels
  Anomres@cnMinLevelValF       =   -8.               ; set min contour level
  Anomres@cnMaxLevelValF       =    8.               ; set max contour level
  Anomres@cnLevelSpacingF      =    1.
  
;-----------------------------------------------------------------------------------------------------
 


 ; plot2 = gsn_csm_hov(wks, Hov(:,{200.:360}), Anomres)
 ; plot2 = gsn_csm_hov(wks, Hov, Anomres)
 ; plot2 = gsn_csm_hov(wks, Hov(:,{-60.:220}), Anomres)
  
  plot2 = gsn_csm_hov(wks, Hov(:,{-180.:60.}), Anomres)

  txres               = True     
  txres@txFontHeightF = .045   
  yhur = 0.

  xhur = 0.
  xhur = cenLon - 360.
  
  hurri = gsn_add_text( wks, plot2, "~F37~p~F",xhur,yhur, txres ) 
  draw(plot2)  
  frame(wks)
  
  
end







