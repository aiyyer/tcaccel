; aproximate phase speed of the extratropical waves in the composites
; estimated from the TC/ridge track images

begin


  pi = 4.*atan(1.)
  piRad = pi/180.
  
  print (pi)
  Rearth = 6.4e6


  dt = 24.*3600.*4. ; 4 days
; rapid tang acceleration

  dLon = 30.
  lat  = 44.
  cp = (Rearth*cos(lat*piRad)*dLon*piRad)/ dt

  print ("Phase speed rapid accel  = " + cp)
  
; rapid tang acceleration

  dLon = 17
  lat  = 46.0
  cp = (Rearth*cos(lat*piRad)*dLon*piRad)/ dt

  print ("Phase speed rapid decel  = " + cp)
end