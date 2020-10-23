; aproximate phase speed of the extratropical waves in the composites
; estimated from the TC/ridge track images

begin


  pi = 4.*atan(1.)
  piRad = pi/180.
  
  print (pi)
  Rearth = 6.4e6


  dt = 24.*3600.*4. ; 4 days

  
; rapid tang acceleration
; Motion of the High
  lon2 = 28.8282
  lon1 = 3.05176e-05
  dLon = lon2-lon1
 
  lat  = 44.
  cp = (Rearth*cos(lat*piRad)*dLon*piRad)/ dt

  print ("Phase speed rapid accel  = " + cp)
  
; rapid tang deceleration

  lon2 = 
  lon1 = 
  dLon = lon2-lon1
  lat  = 46.0
  cp = (Rearth*cos(lat*piRad)*dLon*piRad)/ dt

  print ("Phase speed rapid decel  = " + cp)
end