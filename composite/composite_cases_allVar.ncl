;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
; a program to:
;
;  calculate the storm centered composite of seleted variable 
;  given a list of storm dates and center location
;
;  NEEDS UPDATE TO INCLUDE CLIM and CLIMSQ values for stat sig.
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

load "../../ncl/aiyyer_string_routines.ncl"
load "../../ncl/grid_rotate.ncl"

begin


;=================================================
  LatS =  30
  LatN =  40
  basinAnalysis = "NA" 
  accelType     = "curv" ;"tang"
 
;  iA = 0
;  iB = 2
;  if ( accelType .eq. "curv" ) then
;    iA = 1
;    iB = 2
;  end if

iA = 0
iB = 2

  dir = "./" 

  fileName = dir + "tcAcc_dates_" + accelType + "_" + LatN + "_" + LatS+"_"+ basinAnalysis + ".nc"

  inFile = addfile( fileName, "r" )
 

; height climo file
  climFil = "/tamrind/climo/era/synoptic_climo.nc"
  inClim = addfile(climFil, "r" )
  climTimUnits = inClim->time@units
  print (climTimUnits)

  types = (/"Zero","Low","High"/)

  sfac    := inFile->sfac

  do itype = iA,iB

    type = types(itype)
    
    if ( type .eq. "Zero" ) then
      RecLat    := inFile->LatZero
      RecLon    := inFile->LonZero
      RecDate   := inFile->timeZero
      ;iStormZero:=inFile->iStormZero
      ;jStormZero:=inFile->jStormZero
    end if
    
    if ( type .eq. "High" ) then
      RecLat  := inFile->LatHigh
      RecLon  := inFile->LonHigh
      RecDate := inFile->timeHigh
      ;iStorm  := inFile->iStormHigh
      ;jStorm  := inFile->jStormHigh
    ;print (cd_calendar(RecDate,-3) + " " + RecLat + " " + RecLon)

    end if
    
    if (type .eq. "Low" ) then
      RecLat  := inFile->LatLow
      RecLon  := inFile->LonLow
      RecDate := inFile->timeLow
      ;iStorm:=inFile->iStormLow
      ;jStorm:=inFile->jStormLow
    end if
   
    outFile = "/lotus/projects/data/tcaccel/dat/one/laggedComp_" + accelType + "_"  + type  + "_" + LatN + "_" + LatS+"_"+ basinAnalysis + ".nc"
    system( "rm " + outFile )
    setfileoption("nc", "format", "NETCDF4") 
    ncdf = addfile(outFile ,"c")  ; open output netCDF file
    
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
    
;----------------------------------------------------------------
; Subset the TC locations for user specified bounds  
    NR = dimsizes(RecLat)
    print ( "Num Storms = " + NR)
    RecLat2  := RecLat 
    RecLon2  := RecLon
    RecDate2 := RecDate
    
                                ;print ( RecLat2 + " " + RecLon2 + " " + cd_calendar(RecDate,-3) )
    
    ic = 0
    
    do i=0,NR-1
      if ( RecLat(i) .ge. LatS .and. RecLat(i) .le. LatN) then
        RecLat2(ic)  =   RecLat(i) 
        RecLon2(ic)  =   RecLon(i)
        RecDate2(ic) =  RecDate(i)
        ic = ic + 1
      end if
    end do 
    
    RecLat := RecLat2(0:ic-1)
    RecLon := RecLon2(0:ic-1)
    
    
    if ( basinAnalysis .eq. "NA" ) then
      RecLon = RecLon + 360.
    end if
    
    RecDate := RecDate2(0:ic-1)
    print (cd_calendar(RecDate,-3) + " " + RecLat + " " + RecLon)
    NR = ic
    print ( "Num within the lat range = " + NR)
    
;----------------------------------------------------------------
    LatMedian = dim_median(RecLat)
    LonMedian = dim_median(RecLon)  
    LatMean   = dim_avg(RecLat)
    LonMean   = dim_avg(RecLon)
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
    
    
    
    vars := (/"Z", "U", "V", "T","Q"/)
    do imain = 0,0
      print ( "*****" + vars(imain) + " " + type )
      count  = 0.
      firstTime = 1
      
      lagN = -48 ;-12
      lagP =  48 ; 12
      dt   =  24 ;  6
      nlag = (lagP-lagN)/dt + 1
      
      do i = 0,NR-1
        ;printVarSummary(RecDate)
        dateTemp = tointeger(cd_calendar(RecDate(i),0))
        month = dateTemp(0,1)
        year  = dateTemp(0,0)
        
        ;print (i + " " + dateTemp + " "  +  month + " " + year + " " )
        if ( month .ge. 6 .and. month .le. 11 .and. year .lt. 2016) then
          LA := RecLat(i)
          LL := RecLon(i)       
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
                                ;print (  cd_calendar(RecDate(i),-3) + " " + cd_calendar(lagDate,-3) + " " + lagDateI)
            
            
; Read the ERA data for the particular storm hour/day
            erafile =  ymd_string (lagDateD(0,0),lagDateD(0,1),lagDateD(0,2))   + ".nc"
            filename = "/tamrind/era/3D/" + erafile
            f = addfile (filename, "r")
            units = f->time@units
            eradate = ymdhdate(tointeger(lagDateI),units)
            Dat := f->$vars(imain)$({eradate},{1000:50},{-10.:80.},:)   ; hght fields
            Dat!0 = "level"
            Dat!1 = "lat"
            Dat!2 = "lon"
            
                                ;print (eradate + " " + cd_calendar(eradate,-3) )
            
            
; Now read the synoptic climo data for that day         
            lagDateI := ymd_string (1979,lagDateD(0,1),lagDateD(0,2)) 
                                ;print ("lagDateI = " + lagDateI)
            
            climdate := ymddate(tointeger(lagDateI),climTimUnits)
                                ;printVarSummary(climdate)
                                ; print("looking for " + climdate + " " + cd_calendar(climdate,-3))
            Clim := inClim->$vars(imain)$({climdate},{1000:50},{-10.:80.},:)

            if (lagCount.eq. 0 ) then
              dims = dimsizes(Dat)
              nz = dims(0)
              ny = dims(1)
              nx = dims(2)
              DatArray    := new( (/nlag,nz,ny,nx/) , "float" )
              AnomArray   := DatArray	
              DatSqArray  := DatArray
              ;climArray   := DatArray
              ;climSqArray := DatArray
            end if
            
            
;
; rotated                        
            DatR   = grid_rotate_3d(Dat,tofloat(cenLat),tofloat(cenLon),tofloat(LA),tofloat(LL))	   
            Anom   = Dat
            Anom   = Anom - Clim
            AnomR  = grid_rotate_3d(Anom,tofloat(cenLat),tofloat(cenLon),tofloat(LA),tofloat(LL))
            
                
            
            
            delete(Dat)
            delete(Anom)
            
            DatArray(lagCount,:,:,:)     = DatR
            AnomArray(lagCount,:,:,:)     = AnomR
            DatSqArray(lagCount,:,:,:)     = DatR*DatR
            
            
            
            
            lagCount = lagCount + 1        
          end do
;---------------------------------------------------------------------------------------------------           
;        print (i + " " + count + " " +  "read for all lags: " + lagCount )
          
          
          if (count.eq. 0 ) then   
            datCompArray = DatArray
            AnomCompArray  = AnomArray
            datSqCompArray = DatArray
          end if
          
          count = count + 1
          datCompArray = datCompArray*(count-1.)/count + DatArray/count
          AnomCompArray = AnomCompArray*(count-1.)/count + AnomArray/count
          datSqCompArray = datSqCompArray*(count-1.)/count + DatSqArray/count    
          delete( DatArray )
          delete( AnomArray )
          delete( DatSqArray )
        end if  
      end do
      
      print (count )
      
      
      
      outvar = "comp"+vars(imain)
      ncdf->$outvar$     = datCompArray
      outvar = "compSq"+vars(imain)
      ncdf->$outvar$   = datSqCompArray
      outvar="compAnom"+vars(imain)
      ncdf->$outvar$ = AnomCompArray
      
      
    end do
    
    
    ncdf->count     =count
    ncdf->LatN=LatN
    ncdf->LatS=LatS   
    ncdf->sfac=(/sfac/)
    outvar="cenLat"+types(itype)
    ncdf->$outvar$=cenLat
    outvar="cenLon"+types(itype)
    ncdf->$outvar$=cenLon
    
    
    
  end do    ; itype
    

end
