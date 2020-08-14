;----------------------------------------------------------------------------
; a program to:
; 
; output: pdf plot
;
;
; NCSU Tropical Dynamics Group
;
;----------------------------------------------------------------------------
----------------------------------------------------------------------------
begin



  
  ncdf = addfile("dat.nc" ,"r")  ; open output netCDF file

  startYear = ncdf->startYear
  endYear  = ncdf->endYear
    
  ave   = ncdf->ave
  x = ispan(startYear,endYear,1)

  printVarSummary(ave)

;************************************************
; plotting parameters
; This illustrates one approach. Overlays could also be used.
;************************************************
   wks  = gsn_open_wks("pdf","trend")             ; send graphics to PNG file
   
   res                     = True                   ; plot mods desired
   res@xyMarkLineModes     = (/"Lines","Lines"/)  ; choose which have markers
   res@xyMarkers           = 16                     ; choose type of marker 
   res@xyMarkerColor       = "red"                  ; Marker color
   res@xyMarkerSizeF       = 0.005                  ; Marker size (default 0.01)
   res@xyDashPatterns      = 1                      ; solid line 
   res@xyLineThicknesses   = (/1,3/)                ; set second line to 2
   res@tmYLFormat          = "f"                    ; not necessary but nicer labels 
   res@tiMainString        = " "  ; title


  
;   plotDat = new ( (/2,nn/),"float")
;   plotDat(0,:) = trend
;   plotDat(1,:) = signi


   do i = 0,2
   plot  = gsn_csm_xy (wks,x,ave(i,:),res)           ; create plot
   end do



end


