
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
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
; 


load "../../ncl/aiyyer_string_routines.ncl"

begin

  varComp = "Z"  ; variable to composite

  NumComps = 1000
  year1 = 1980
  year2 = 2015
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

;=========================================================================



  

  firstTime = 1
  
  do imain = 0,NumComps-1
    print (imain + " " +  min(unf(:,imain)) + " " + max(unf(:,imain))  )

    dcount = 0
    do i = 0, N-1
      jj = unf(i,imain)
      
      date_decoded  = tointeger(cd_calendar (dateAppend(jj),0))
      erafile =  ymd_string (date_decoded(0,0),date_decoded(0,1),date_decoded(0,2))   + ".nc"

      filename = "/tamrind/era/3D/" + erafile
      f = addfile (filename, "r")
      units = f->time@units
     
      eradate = ymdhdate(tointeger(cd_calendar(dateAppend(jj),-3)),units)
     
      Dat := f->$varComp$({eradate},{(/1000,850,500,300/)},{-10.:80.},:)   ; hght fields
      Dat!0 = "level"
      Dat!1 = "lat"
      Dat!2 = "lon"


      if ( firstTime .eq. 1 ) then
        dims = dimsizes(Dat)
        nz = dims(0)
        ny = dims(1)
        nx = dims(2)
        DatComp    := new( (/NumComps,nz,ny,nx/) , "float" )
        DatComp     = 0.0
        DatComp!0 = "count"
        DatComp!1 = "level"
        DatComp!2 = "lat"
        DatComp!3 = "lon"
        DatComp&level = Dat&level
        DatComp&lat   = Dat&lat
        DatComp&lon   = Dat&lon        
        firstTime = 0
      end if
      
      dcount = dcount + 1
      Dat = Dat 
;      print (cd_calendar(dateClimo,-3 ) + " " + cd_calendar(eradate,-3) + " " + Dat({500},{40},{310}) + " " + Zclim({500},{40},{310}) )
         
      DatComp(imain,:,:,:) = DatComp(imain,:,:,:)*(dcount-1)/dcount + Dat/dcount

;   print ( imain + " " +  i + " " + " " + dcount + " " + Dat({500},{40.},{310.}) + " " + DatComp(imain,{500},{40.},{310.}) )

;    print ( imain + " " +  i + " " + " " + jj + " " + cd_calendar(dateAppend(jj),-3)  + " " +  eradate + " " + cd_calendar(eradate,-3) + " " + dcount + " " +DatComp(imain,{500},{40.},{310.}) )
;    print ( " " )

    end do
    
  end do
  
  outFile = "/lotus/projects/data/tcaccel/" + varComp+"sig_out.nc"
  system( "rm " + outFile )
  setfileoption("nc", "format", "NETCDF4") 
  ncdf = addfile(outFile ,"c")  ; open output netCDF file
  
  ncdf->N=N
  ncdf->DatComp=DatComp



  
 
end
