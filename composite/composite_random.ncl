
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
; a program to:
;
; create 1000 different composites for N random days
; within a day/month range over
; years Year1 and Year2
;
;
;
;---------------------------------------------------------------------------
; Aiyyer 
; NCSU Tropical Dynamics Group
;
;
;
; Updates
;
; Dec 3 2019
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
; 


;load "../../ncl/aiyyer_string_routines.ncl"

begin



  compVar = "Z"  ; variable to composite
  
  NumComps = 1000
  year1 = 1980
  year2 = 2016
  units  = "days since 1858-11-17 00:00:00"


; first create a list of all dates for all years within the
; required date range
  ic = 0
  do iy = year1,year2
    startTime =   cd_inv_calendar(iy,7,1,0,0,0,units,  0)
    endTime   =   cd_inv_calendar(iy,10,31,24,0,0,units, 0)
    ndays = tointeger(endTime - startTime)
    x=ispan(0,ndays*4,1)*.25
    
    date := x
    date  = tofloat(x) +  tofloat(startTime)
    date@units = units
    
    if (ic .eq. 0 ) then
      dateAppend = date
    else
      dtemp := array_append_record(dateAppend, date,0)
      dateAppend := dtemp
    end if
    ic = ic + 1
  end do
  
 
;  dateAppend has the list of all dates over all years
;  now we will select N dates from this array randomly
;  we will compoiste over N samples
;  We will repeat that NumComps times

  Ndates = dimsizes(dateAppend)
  
  N = 350 ; composite for N times
  
; Generate N random indices 
  random_setallseed(36484749, 9494848)               ; Set seeds (suggested, NOT required)
  low   = 0
  high  = Ndates
  unf   = tointeger( random_uniform(low, high, (/N,NumComps/)) )
  
  
  print ("Num of date/times = " + Ndates + " " + ic)




;================================================================================================


  

  firstTime = 1
  
  do imain = 0,NumComps-1
    print (imain + " " +  min(unf(:,imain)) + " " + max(unf(:,imain))  )



    dcount = 0
    do i = 0, N-1
      jj = unf(i,imain)
      print ( imain + " " +  i + " " + " " + jj + " " + cd_calendar(dateAppend(jj),-3) )
      
      date_decoded  = tointeger(cd_calendar (dateAppend,0))
      erafile =  ymd_string (date_decoded(0,0),date_decoded(0,1),date_decoded(0,2))   + ".nc"
      print (erafile)
      filename = "/tamrind/era/3D/" + erafile
      f = addfile (filename, "r")
      units = f->time@units
      eradate = ymdhdate(tointeger(dateAppend),units)
      Dat := f->$varComp$({eradate},{1000:50},{-10.:80.},:)   ; hght fields
      Dat!0 = "level"
      Dat!1 = "lat"
      Dat!2 = "lon"
      print (eradate + " " + cd_calendar(eradate,-3) )
      exit
      
      
      if ( firstTime .eq. 1 ) then
        dims = dimsizes(Dat)
        nz = dims(0)
        ny = dims(1)
        nx = dims(2)
        DatCompArray    := new( (/NumComps,nz,ny,nx/) , "float" )


        DatCompArray!0 = "count"
        DatCompArray!1 = "level"
        DatCompArray!2 = "lat"
        DatCompArray!3 = "lon"
        
        DatCompArray&level = Dat&level
        DatCompArray&lat   = Dat&lat
        DatCompArray&lon   = Dat&lon
        
        
        firstTime = 0
      end if
      
      dcount = dcount + 1
      DatCompArray(imain,:,:,:) = DatCompArray(imain,:,:,:)*(dcount-1)/dcount + Dat/dcount
    end do
    
  end do
  
  outFile = varComp+"_out.nc"
  system( "rm " + outFile )
  setfileoption("nc", "format", "NETCDF4") 
  ncdf = addfile(outFile ,"c")  ; open output netCDF file
  
  
  ncdf->N=N
  ncdf->DatCompArray=DatCompArray



  
 
end