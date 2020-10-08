begin


; read the data with 1000 composites made with random samples
  fili = "Zsig_out.nc"
  f      = addfile (fili, "r")

 

  level = 500
  compSig := f->DatComp(:,{level},:,:)
  printVarSummary(compSig)
  dims = dimsizes(compSig)
  nt = dims(0)
  ny = dims(1)
  nx = dims(2)

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

  N95  = tointeger(.95*nt) - 1
  N05  = tointeger(.05*nt) - 1

  print (N95 + " " + N05)

  N95 = 975
  N05 =  25
  print (N95 + " " + N05)
  

  Z500Sig95  = compSig(N95,:,:)
  Z500Sig05  = compSig(N05,:,:)

  printVarSummary(Z500Sig95)
  printVarSummary(Z500Sig05)
  print (N95 + " " + N05)

  outFile = "/lotus/projects/data/tcaccel/comp95.nc"
  
  ;system( "rm " + outFile )
  setfileoption("nc", "format", "NETCDF4") 
  ncdf = addfile(outFile ,"w")  ; open output netCDF file

  ncdf->Z500Sig95 = Z500Sig95
  ncdf->Z500Sig05 = Z500Sig05

  
end

