
;------------------------------------------------------------------------
; NCSU Tropical Dynamics Group
; A. Aiyyer 
;------------------------------------------------------------------------
;------------------------------------------------------------------------
;------------------------------------------------------------------------
; 
; procedure to calculate the radius of curvature and center point of the
; fitted circle to each point along a TC track
;
; Returns radius of curvature in m
;
; Based on Terrell Wade's formula
;
; In this version we retain the arcsin() while calculating Rad of curvature
; This means that the radius of curvature is a curved line on the surface of
; The sphere
;
; Reference:
;           
;-------------------------------------------------------------------------
;-------------------------------------------------------------------------
undef ("rad_curv")

function rad_curv(Lat,Lon,N)

begin

  Rearth = todouble(6.3781e6)  ;in m
  pi     = 4.0*atan(todouble(1.))
  pideg = todouble(180.0)
  circC= new(N,"double")
  circC@_FillValue = Lat@_FillValue
  circC=circC@_FillValue
  
  R = todouble(0.)
  R@_FillValue =Lat@_FillValue
  
  do j = 1,N-2

    N3 = Lon(j+1)*pi/pideg
    N2 = Lon(j)  *pi/pideg
    N1 = Lon(j-1)*pi/pideg
    T3 = Lat(j+1)*pi/pideg
    T2 =   Lat(j)*pi/pideg
    T1 = Lat(j-1)*pi/pideg

    
; check if three points are along a line
    lineFlag = 0
    tolerance = 1.e-2*pi/pideg
    
    delta1 = T2-T1
    delta2 = T3-T2
    if ( abs(delta2) .le. tolerance .and. abs(delta1) .le. tolerance  )then
      lineFlag = 1
    end if
    delta1 = N2-N1
    if (abs(delta1) .gt. pi ) then
      sgndelta =delta1/abs(delta1)
      delta1 = delta1 - sgndelta*2*pi
    end if
    delta2 = N3-N2
    if (abs(delta2) .gt. pi ) then
      sgndelta =delta2/abs(delta2)
      delta2 = delta2 - sgndelta*2*pi
    end if
    if ( abs(delta2) .le. tolerance .and. abs(delta1) .le. tolerance  )then
      lineFlag = 1
    end if
    
;---------------------------------------------------------------------------    
    if ( lineFlag .eq. 1 ) then
      circC(j) = circC@_FillValue
      ;print ( j + " lineflag =1 " )
    else
    
      D12 = 1. - cos(T1)*cos(T2)*cos(N2-N1) - sin(T1)*sin(T2)
      D13 = 1. - cos(T1)*cos(T3)*cos(N3-N1) - sin(T1)*sin(T3)
      D23 = 1. - cos(T2)*cos(T3)*cos(N3-N2) - sin(T2)*sin(T3)
      
      Term1 = 2.*D12*D13*D23
      Term2A = (D12 + D13 + D23)^2
      Term2B = 2.*(D12^2 + D13^2 + D23^2)
      Term2  = Term2A - Term2B
      
      R = R@_FillValue
      
      if ( Term2 .ne. 0. ) then
        temp = sqrt(Term1/Term2)
        
        if ( abs(temp) .le. 1.0) then
           R = Rearth*asin(temp)
         end if
      end if
      
      
; if radius is too large or too small, set to missing
   ; print (j + " -- " + R + " " + sqrt(temp))

;----------------------------------------------------------------------------------------      
      if ( .not.ismissing(R) ) then
        if ( R .gt. 20.e6 .or. R .lt. 1.e3 ) then
          print ("R is too small or big (km): " + tointeger(R*1.e-3) )       
        else
          circC(j)  = R
        end if
      end if
;----------------------------------------------------------------------------------------

    end if
  end do

; the first and last values are assigned now
  circC(0)   = circC(1)
  circC(N-1) = circC(N-2)

  return(circC)

end

;****************************************************************************************
;****************************************************************************************
;****************************************************************************************
; this function returns the radius of curvature and the center of the
; fitted circle
;
;Returns radius of curvature in m and center of circle in degrees
;
;-------------------------------------------------------------------------
;-------------------------------------------------------------------------
undef ("rad_curv_circle")
function rad_curv_circle(Lat,Lon,N)


begin 
  Rearth = todouble(6.3781e6)  ;in m
  pi     = 4.0*atan(todouble(1.))
  pideg = todouble(180.0)
  circC= new( (/3,N/),"double")
  circC@_FillValue = Lat@_FillValue
  circC=circC@_FillValue
  R = todouble(0.)
  R@_FillValue =Lat@_FillValue
  
  do j = 1,N-2

    N3 = Lon(j+1)*pi/pideg
    N2 = Lon(j)  *pi/pideg
    N1 = Lon(j-1)*pi/pideg
    T3 = Lat(j+1)*pi/pideg
    T2 =   Lat(j)*pi/pideg
    T1 = Lat(j-1)*pi/pideg

    
; check if three points are along a line
    lineFlag = 0
    tolerance = 1.e-2*pi/pideg
    
    delta1 = T2-T1
    delta2 = T3-T2
    if ( abs(delta2) .le. tolerance .and. abs(delta1) .le. tolerance  )then
      lineFlag = 1
    end if
    delta1 = N2-N1
    if (abs(delta1) .gt. pi ) then
      sgndelta =delta1/abs(delta1)
      delta1 = delta1 - sgndelta*2*pi
    end if
    delta2 = N3-N2
    if (abs(delta2) .gt. pi ) then
      sgndelta =delta2/abs(delta2)
      delta2 = delta2 - sgndelta*2*pi
    end if
    if ( abs(delta2) .le. tolerance .and. abs(delta1) .le. tolerance  )then
      lineFlag = 1
    end if
    
;---------------------------------------------------------------------------    
    if ( lineFlag .eq. 1 ) then

      circC(:,j) = circC@_FillValue
      print ( j + " lineflag =1 " )
    else
    
      D12 = 1. - cos(T1)*cos(T2)*cos(N2-N1) - sin(T1)*sin(T2)
      D13 = 1. - cos(T1)*cos(T3)*cos(N3-N1) - sin(T1)*sin(T3)
      D23 = 1. - cos(T2)*cos(T3)*cos(N3-N2) - sin(T2)*sin(T3)
      
      Term1 = 2.*D12*D13*D23
      Term2A = (D12 + D13 + D23)^2
      Term2B = 2.*(D12^2 + D13^2 + D23^2)
      Term2  = Term2A - Term2B
      
      R = R@_FillValue
      
      if ( Term2 .ne. 0. ) then
        temp = sqrt(Term1/Term2)
        if ( abs(temp) .le. 1.0) then

; version 1 that was first submitted in the paper has the arcsin          
          R = Rearth*asin(temp)
          
        end if
      end if
      
      
; if radius is too large or too small, set to missing
   ; print (j + " -- " + R + " " + sqrt(temp))
;----------------------------------------------------------------------------------------      
      if ( .not.ismissing(R) ) then
        if ( R .gt. 20.e6 .or. R .lt. 1.e3 ) then
          print ("R is too small or big (km): " + tointeger(R*1.e-3) )       
        else
          alpha = cos(T1)*cos(N1)*(sin(T2) - sin(T3)) + cos(T2)*cos(N2)*(sin(T3) - sin(T1)) + cos(T3)*cos(N3)*(sin(T1) - sin(T2))  
          beta  = cos(T1)*sin(N1)*(sin(T2) - sin(T3)) + cos(T2)*sin(N2)*(sin(T3) - sin(T1)) + cos(T3)*sin(N3)*(sin(T1) - sin(T2))  
          
; now lets get the center locations
          LT = new(2,"double")
          LN = new(2,"double")
          Numer = cos(T1)*cos(T2)*sin(N2-N1) + cos(T1)*cos(T3)*sin(N1-N3) + cos(T2)*cos(T3)*sin(N3-N2)
          Denom = sqrt(alpha*alpha + beta*beta)
          
          
          if ( Denom .ne. 0. ) then
            LT(0) = atan(-Numer/Denom) 
            LT(1) = atan(Numer/Denom) 
            LN(0) = atan(-alpha/beta)
            LN(1) = atan(-alpha/beta) + pi
          else
            print ( "Denom = 0.")
            print ( "R = " + R )
          end if
          
          Rkm = R*1.e-3
          minDiff = todouble(1.e9)
          ichoose = 0
          jchoose = 0
          rchoose = Rkm
          do ii=0,1
            latp  =  LT(ii)*pideg/pi
            do jj=0,1
              lonp  =  LN(jj)*pideg/pi
;        print ("Possible center Lat,Lon (degrees): " + latp + " " + lonp ) 
              do kk=1,1
                kk2 = kk+1
                dist = gc_latlon(LT(ii)*pideg/pi,LN(jj)*pideg/pi,Lat(j-1+kk),Lon(j-1+kk),2,4)
                diff = abs(Rkm-dist)
                if (diff .le. minDiff ) then
                  ichoose = ii
                  jchoose = jj
                  minDiff = diff
                  rchoose = dist
                end if
              end do
            end do
          end do
          
          circC(0,j)  = LN(jchoose)
          circC(1,j)  = LT(ichoose)
          circC(2,j)  = R
          
          dist = gc_latlon(LT(ichoose)*pideg/pi,LN(jchoose)*pideg/pi,Lat(j),Lon(j),2,4)
          diff = abs(Rkm-dist)
          if ( diff .gt. 20.) then
            print ("too much!" + " " + diff)
            print ( j + " " + N1*pideg/pi + " " + N2*pideg/pi + " " + N3*pideg/pi)
            print ( j + " " + T1*pideg/pi + " " + T2*pideg/pi + " " + T3*pideg/pi)
            circC(:,j) = circC@_FillValue
          end if
        end if
      end if
;----------------------------------------------------------------------------------------

    end if
  end do

; the first and last values are assigned now
  circC(:,0)   = circC(:,1)
  circC(:,N-1) = circC(:,N-2)
;
  
  return(circC)

end

