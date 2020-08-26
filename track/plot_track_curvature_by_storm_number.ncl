; A program to:
;
; Plot the track of a selected TC from the ibtracs database and also to
; calculate the approximate Radius of Curvature 
; 
; Uses Terrel Wade's formula
;
; Output: two pdf files and numbers on screen
;
;
; Aiyyer 
; NCSU Tropical Dynamics Group
; 2020
;
;----------------------------------------------------------------------------

load "../rad_curv.ncl"

begin

; Set basic parameters
  Rearth = todouble(6.3781e6)  ;in m
  pi     = 4.0*atan(todouble(1.))
  pideg = todouble(180.0)

  
; user inputs
;   
; choose the stormNumber to plot
; KATRINA 11886 HUGO 10135 IRMA 13087

  ;StormNum=  11895
  StormNum=  11887 ; 13099


; the ibtracs file
  fileName = "../IBTrACS.ALL.v04r00.nc"
;
;
; 
  fileIn = addfile( fileName, "r" )
  time        = fileIn->time(StormNum,:)  
  Lat         = flt2dble(fileIn->lat(StormNum,:))
  Lon         = flt2dble(fileIn->lon(StormNum,:))
  N           = toint(short2flt(fileIn->numobs(StormNum)))
  name        =  chartostring(fileIn->name(StormNum,:))


  timeDecode = cd_calendar(time,-5)
  year = timeDecode(0,0)
  print ( "Storm = " + name + " " + year)

  
  if ( N .lt. 24 ) then
    print ( "Too few track points: I quit!")
    exit
  end if
  
; first extract only 3 hourly reports at synoptic hours 0,3,6...21    
  time2 = time
  lat2  = Lat
  lon2  = Lon
  
  is = 0
  do j = 0,N-1
    curTime = cd_calendar(time(j),-5)
    hour    = curTime(0,3)  
; only consider the three hourly reports
    if ( mod(hour,3) .eq. 0 ) then
      time2(is)     = (/time(j)/)
      lat2(is)      = (/Lat(j)/)
      lon2(is)      = (/Lon(j)/)
      is = is + 1
    end if
  end do
  
  time := time2(0:is-1)
  Lat  := lat2(0:is-1)
  Lon  := lon2(0:is-1)


  Lon := where(Lon.lt.0.,Lon+360.,Lon)

  

  N=is
;
;-----------------------------------------------------------------------
;-----------------------------------------------------------------------  
;

  print (N)

  circC= new( (/3,N/),"double")  
  circC = rad_curv_circle(Lat,Lon,N)
  LatC= circC(1,:)
  LonC= circC(0,:)  
  RadC= circC(2,:)  
  
   print ( "Date/Lat/Lon/R = " + cd_calendar(time(0:N-1),-3) + " " + Lat(0:N-1) + " " + Lon(0:N-1) + " " + tointeger(1.e-3*RadC(0:N-1)))
  
;-------------------------------------------------------------------------------  
;-------------------------------------------------------------------------------  
  
  LonR= avg(Lon)
  LatR= avg(Lat)
  
  wks  = gsn_open_wks("png","track_map_ce")      ; open an ncgm file  
  res = True

  res@tiMainString         = name + "(" + year + ")"

  
  res@mpProjection = "Mercator"
  res@mpLimitMode  = "LatLon"
  
  res@mpOutlineOn         =  True
  res@mpMaxLatF           =  LatR+15.
  res@mpMinLatF           =  LatR-25.
  res@mpMinLonF           =  LonR-20.
  res@mpMaxLonF           =  LonR+20.

;  res@mpMaxLatF           =  LatR+30.
;  res@mpMinLatF           =  LatR-20.
;  res@mpMinLonF           =  LonR-40.
;  res@mpMaxLonF           =  LonR+40.



  res@mpMaxLatF           =  40.
  res@mpMinLatF           = -10.
  res@mpMinLonF           = -120.
  res@mpMaxLonF           =  -40.


  
  res@mpCenterLonF = .5*( res@mpMinLonF +  res@mpMaxLonF)
  res@mpGeophysicalLineThicknessF = 0.   
  res@mpFillOn                  = True  
  res@mpOutlineOn = False 

   
  res@gsnDraw          = False                   
  res@gsnFrame         = False
  plot = gsn_csm_map(wks,res)        ; draw global map



; resource for markers  
  gsres               = True
  gsres@gsMarkerIndex = 16          ; Use filled dots for markers
  gsres@gsMarkerSizeF     = .007          ; polymarker size
  gsres@gsLineThicknessF = 6.0



  gsres@gsLineDashPattern = 0
  dum1=gsn_add_polyline(wks,plot,Lon,Lat,gsres)
  colors  = (/"violet","navy blue","red","orange","black"/)

  np=720
  circLat  = new(np,"double")
  circLon  = circLat
  dtheta = circLon(0)


  dumG  = new(20,"graphic")
  jj    = 0
  imain = 0


  jindex = (/10,24,34,43/)
 ; jindex = (/10,77,78,79/)

  do jjj = 0,3

    j = jindex(jjj)



    if ( j .lt. (N-1) ) then
    if ( .not.ismissing(LatC(j)) .and. j .lt. (N-1) ) then
    

      gsres@gsMarkerColor  =  colors(imain)
      imain = imain + 1
      print ( "j Track Date/Lat/Lon = " + j + " " + cd_calendar(time(j),-3) + " " + Lat(j) + " " + Lon(j) )
      print ("circle rad(km)/Lat/Lon:  " +  toint(1.e-3*RadC(j)) + " " + LatC(j)*pideg/pi + " " + LonC(j)*pideg/pi )
      
      print (" " )
      
      d = RadC(j)/Rearth
      
      minLatC = todouble(LatC(j)) - d
      maxLatC = todouble(LatC(j)) + d

      dtheta = (maxLatC - minLatC)/todouble(np)  
      
      
      do i = 0,np-2
        
        theta = minLatC + (i+1)*dtheta*2.
        
        factor = -1.
        if (theta .gt. maxLatC) then
          theta  = 2.*maxLatC - theta
          factor = 1.
        end if
        
        temp = (sin(.5*d)*sin(.5*d) - sin( .5*(theta-LatC(j))) * sin( .5*(theta-LatC(j))))
        temp = temp/(cos(theta)*cos(LatC(j)))
        
        if ( abs(temp) .le. 1.e-18) then
          temp = 0.
        end if
        
        phi = 2.*asin(sqrt(temp))
        
        circLat(i)  = theta
        circLon(i) = LonC(j) + factor*phi
        
        ;print ( theta + " " + circLon(i)*pideg/pi + " " + circLat(i)*pideg/pi + " " + temp)
        
      end do  
      ;print ("min ,max " + minLatC + " " + maxLatC )
      
      
      circLat(np-1)  = circLat(0)
      circLon(np-1) = circLon(0)
      
      
      
      gsres@gsLineColor= gsres@gsMarkerColor          ; set polymarker color
      gsres@gsLineThicknessF = 1.0
      
      dumG(jj) = gsn_add_polyline(wks,plot,circLon*pideg/pi,circLat*pideg/pi,gsres)
      jj=jj+1
      
      
      dumG(jj) = gsn_add_polymarker(wks,plot,LonC(j)*pideg/pi,LatC(j)*pideg/pi,gsres)
      jj=jj+1
      llat = Lat(j-1:j+1)
      llon = Lon(j-1:j+1)
      dumG(jj)=gsn_add_polymarker(wks,plot,llon,llat,gsres)
      jj=jj+1
      
      rlat = Lat(0:1)
      rlon = Lon(0:1)
      
      rlat  = (/LatC(j)*pideg/pi,Lat(j)/)
      rlon =  (/LonC(j)*pideg/pi,Lon(j)/)
      
      ;print (rlat + " " + rlon)
      gsres@gsLineDashPattern = 1
      dumG(jj)=gsn_add_polyline(wks,plot,rlon,rlat,gsres)
      gsres@gsLineDashPattern = 0
      
      jj=jj+1
 

    end if
    end if
  end do
  
  draw(plot)
  frame(wks)


        
end
 
