


LatM = 10.
LonM = 179.5
Lat0 = 10.
Lon0 = -179.5+360.
distance =  gc_latlon(LatM,LonM,Lat0,Lon0,2,3)
distance = distance*1.e-3

print ( "distance = " + distance)