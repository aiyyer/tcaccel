;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
; a program to:
;
;  calculate the storm centered composite of seleted variable 
;  given a list of storm dates and center location
;
;
;
;---------------------------------------------------------------------------
; Aiyyer 
; NCSU Tropical Dynamics Group
;
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
; 

load "../../ncl/aiyyer_string_routines.ncl"
load "../../ncl/grid_rotate.ncl"

begin


;------------------------------------------------------
  LatS = 30 ;20
  LatN = 40 ;30
  LonW = -120 
  LonE =  0
  basinAnalysis = "NA"  ;WP
;------------------------------------------------------

; height climo file
  climFil = "/tamrind/climo/era/synoptic_climo.nc"
  inClim = addfile(climFil, "r" )
  climTimUnits = inClim->time@units
  print (climTimUnits)

; this recurv files already has subset of tcs that we need
;-----------------------------------------------------------------------
  

  fileName = "tcAcc_TS_thresh" + LonW + "_" + LonE + "_" + LatN + "_" + LatS+"_"+ basinAnalysis + ".nc"

  inFile = addfile( fileName, "r" )



  type = "Low"


  
  if ( type .eq. "Zero" ) then
    RecLat    = inFile->LatZero
    RecLon    = inFile->LonZero
    RecDate   = inFile->timeZero
    iStormZero=inFile->iStormZero
    jStormZero=inFile->jStormZero
  end if
  
  if ( type .eq. "High" ) then
    RecLat  = inFile->LatHigh
    RecLon  = inFile->LonHigh
    RecDate = inFile->timeHigh
    iStorm=inFile->iStormHigh
    jStorm=inFile->jStormHigh
  end if
  
  if (type .eq. "Low" ) then
    RecLat  = inFile->LatLow
    RecLon  = inFile->LonLow
    RecDate = inFile->timeLow
    iStorm=inFile->iStormLow
    jStorm=inFile->jStormLow
  end if
  
  


  printVarSummary(RecDate)
  DateUnits = RecDate@units
;-------------------------------------------------------------------------

; iBTracs date has units of days since...
; Ensure that we have that.
  if (DateUnits .ne. "days since 1858-11-17 00:00:00") then
    print ("Expecting days since 1858-11-17 00:00:00")
    print ("found " + DateUnits)
    print ("Terminating code")
    exit
  end if 
  
;  print (cd_calendar(RecDate,-3) + " " + RecLat + " " + RecLon)

;----------------------------------------------------------------
; Subset the TC locations for user specified bounds  
  NR = dimsizes(RecLat)
  print ( "NR = " + NR)
  RecLat2  = RecLat 
  RecLon2  = RecLon
  RecDate2 = RecDate
  ic = 0
  do i=0,NR-1
    if ( RecLat(i) .ge. LatS .and. RecLat(i) .le. LatN) then
      if ( RecLon(i) .ge. LonW .and. RecLon(i) .le. LonE) then
                                ;print (ic + " " + iStorm(i) + " " +  jStorm(i))
        RecLat2(ic)  =   RecLat(i)
        RecLon2(ic)  =   RecLon(i)
        RecDate2(ic) =  RecDate(i)
        ic = ic + 1
      end if
    end if
  end do


  RecLat := RecLat2(0:ic-1)
  RecLon := RecLon2(0:ic-1)

  RecLon = RecLon + 360.
  RecDate := RecDate2(0:ic-1)
; print (cd_calendar(RecDate,-3) + " " + RecLat + " " + RecLon)
  NR = ic
  print ( "NR = " + NR)
;----------------------------------------------------------------
  LatMedian = dim_median(RecLat)
  LonMedian = dim_median(RecLon)  
  LatMean = dim_avg(RecLat)
  LonMean = dim_avg(RecLon)
  print ("Median " + LatMedian + "  " + LonMedian)
  print ("Mean   " + LatMean + "  " + LonMean)
;
;---------------------------------------------------------------
; currently hard coded for erai data.
; needs updates
  dlat = 0.7031252
  cenLat = toint( (LatMean+89.463)/dlat) * dlat -89.463
  cenLon = toint( LonMean/dlat ) * dlat
  print ("Era: " + cenLat + " " + cenLon)
;---------------------------------------------------------------
; loop over  cases

  count  = 0.
  firstTime = 1

  lagN = -12
  lagP =  12
  dt   =   6
  nlag = (lagP-lagN)/6 + 1
  
  do i = 0,NR-1
    
    dateTemp = tointeger(cd_calendar(RecDate(i),0))
    month = dateTemp(0,1)
    year  = dateTemp(0,0)

    if ( month .ge. 7 .and. month .le. 11 .and. year .lt. 2016) then
      LA = RecLat(i)
      LL = RecLon(i)       
      print ( "processing storm num: " + count + " " + cd_calendar(RecDate(i),-3))

;--------------------------------------------------------------------------------------------------- 
      lagCount = 0
      do ilag = lagN,lagP,dt

; the coded lag Date
        lagDate := RecDate(i)
        lagDate  = RecDate(i) + ilag/24.        

; decode the lagDate to determine name of the era file
; some times the hour is not one of the 4 synoptic ones. so we use the nearest previou hour
; 
        lagDateD = tointeger(cd_calendar (lagDate,0))
        ih = lagDateD(0,3)
        ih = tointeger(ih/6.)*6  ; this ensures that ih is one of: 0,6,12,18

; now assemble the date again:
        lagDateI := ymdh_string (lagDateD(0,0),lagDateD(0,1),lagDateD(0,2),ih)        
        print (  cd_calendar(RecDate(i),-3) + " " + cd_calendar(lagDate,-3) + " " + lagDateI)
      

; Read the ERA data
; daily fields
        erafile =  ymd_string (lagDateD(0,0),lagDateD(0,1),lagDateD(0,2))   + ".nc"
        filename = "/tamrind/era/3D/" + erafile
        f = addfile (filename, "r")
        units = f->time@units
        eradate = ymdhdate(tointeger(lagDateI),units)
        Dat = f->U({eradate},{1000:50},{-10.:80.},:)   ; hght fields
        Dat!0 = "level"
        Dat!1 = "lat"
        Dat!2 = "lon"
 
        ;print (eradate + " " + cd_calendar(eradate,-3) )
       
        lagDateI := ymd_string (1979,lagDateD(0,1),lagDateD(0,2)) 
        ;print ("lagDateI = " + lagDateI)

        climdate := ymddate(tointeger(lagDateI),climTimUnits)
        ;printVarSummary(climdate)
        ;print("looking for " + climdate + " " + cd_calendar(climdate,-3))
        Clim := inClim->U({climdate},{1000:50},{-10.:80.},:)
    


        if (lagCount.eq. 0 ) then
          dims = dimsizes(Dat)
          nz = dims(0)
          ny = dims(1)
          nx = dims(2)
          DatArray    = new( (/nlag,nz,ny,nx/) , "float" )
          AnomArray  = DatArray	
          DatSqArray = DatArray
        end if


;
; rotated                        
        DatR   = grid_rotate_3d(Dat,cenLat,cenLon,LA,LL)	   
        Anom = Dat
        Anom = Anom - Clim
        AnomR   = grid_rotate_3d(Anom,cenLat,cenLon,LA,LL)
        
        delete(Dat)
        delete(Anom)

        DatArray(lagCount,:,:,:)  = DatR
        AnomArray(lagCount,:,:,:) = AnomR
        DatSqArray(lagCount,:,:,:)  = DatR*DatR
        lagCount = lagCount + 1        
      end do
;---------------------------------------------------------------------------------------------------           
      print (i + " " + count + " " +  "read for all lags: " + lagCount )
      if (count.eq. 0 ) then   
        DatClimArray = DatArray
        AnomClimArray= AnomArray
        DatSqClimArray = DatArray
      end if
      count = count + 1
      DatClimArray = DatClimArray*(count-1.)/count + DatArray/count
      AnomClimArray = AnomClimArray*(count-1.)/count + AnomArray/count
      DatSqClimArray = DatSqClimArray*(count-1.)/count + DatSqArray/count    
      delete( DatArray )
      delete( AnomArray )
      delete( DatSqArray )
    end if  
  end do
  
  print (count )
    
  outFile = "laggedComp_" + LonW + "_" + LonE + "_" + LatN + "_" + LatS+"_"+ basinAnalysis + "_"+ type+ ".nc"
  ncdf = addfile(outFile ,"c")  ; open output netCDF file
  filedimdef(ncdf,"time",-1,True)  
  ncdf->compU      = DatClimArray
  ncdf->compUSq   = DatSqClimArray
  ncdf->compUAnom = AnomClimArray
  ncdf->cenLat=cenLat
  ncdf->cenLon=cenLon	
  ncdf->count=count
  delete(ncdf)
  
    
    

end
