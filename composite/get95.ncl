;----------------------------------------------------------------------------
; a program to:
;
; Read the data file with 1000 composites derived from randomly sampled 
; data and then determine the value for 95th% significance using a two
; tailed method
;
;----------------------------------------------------------------------------
; Aiyyer 
; NCSU Tropical Dynamics Group
;
;----------------------------------------------------------------------------
; Oct 14, 2020
;----------------------------------------------------------------------------

begin

; read the data with 300 composites made with random samples
  fili = "/home/anant/data50/data/tcaccel/composite/Zsig_out.nc"
  f      = addfile (fili, "r")

  level = 300
  compSig := f->DatComp(:,{level},:,:)
  printVarSummary(compSig)
  dims = dimsizes(compSig)
  nt = dims(0)
  ny = dims(1)
  nx = dims(2)

  outFile = "comp95.nc"
  
  ;system( "rm " + outFile )
  setfileoption("nc", "format", "NETCDF4") 
  ncdf = addfile(outFile ,"w")  ; open output netCDF file


  N95  = tointeger(.975*nt)
  N05  = tointeger(.025*nt) 
  print (N95 + " " + N05)
  
  
  do j=0,ny-1
    do i = 0,nx-1
      top = max (  compSig(:,j,i) )
      bot = min (  compSig(:,j,i) )
      qsort( compSig(:,j,i) )
      difA = compSig(0,j,i) - bot
      difB = compSig(999,j,i) - top 

      if ( difA .ne. 0 .or. difB .ne. 0 ) then
        print ( i + " " + j + " " + compSig(0,j,i)+ " " + compSig(nt-1,j,i) + " " + difA + " " + difB)
        print ("Exit code: error ")
        exit
      end if
      
    end do
  end do

;


  

  Z300Sig95  = compSig(N95,:,:)
  Z300Sig05  = compSig(N05,:,:)

  printVarSummary(Z300Sig95)
  printVarSummary(Z300Sig05)
  print (N95 + " " + N05)


  ncdf->Z300Sig95 = Z300Sig95
  ncdf->Z300Sig05 = Z300Sig05

  
end

