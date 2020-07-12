begin

;rapid accel
lat1= 13.6842  ;  14.3859
lon1= 7.73441   ; -0.703125
lat2=18.5965   ; 17.1929
lon2=-9.84375  ; -4.21875


distance =  gc_latlon(lat1,lon1,lat2,lon2,2,4)
print ("dist highrapid accel = " + distance)


;zero
lat1=13.6842  ;14.3859
lon1=8.43753  ;4.21878
lat2=19.2982  ;17.1929
lon2=-7.03125 ;-4.21875


distance =  gc_latlon(lat1,lon1,lat2,lon2,2,4)
print ("dist zero accel = " + distance)


; rapid dec
lat1=13.6842   ;14.3859
lon1=9.84378   ;4.92188
lat2=18.5965   ;16.4912
lon2=-7.03125  ;-3.51562




distance =  gc_latlon(lat1,lon1,lat2,lon2,2,4)
print ("dist rapid decel = " + distance)


end
