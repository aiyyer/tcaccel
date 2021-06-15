#=======================================================================
#
#
#=======================================================================
import pandas as pd
from netCDF4 import Dataset
import numpy as np
from numpy import dtype
import matplotlib.pyplot as plt
import pymannkendall as mk




# open the annual average speeds that excludes NR and ET points
filename = "dat_atl_noET_noNR.nc"
ncin = Dataset(filename, 'r', format='NETCDF4')
speedAveA = ncin.variables['ave']
print(speedAveA)

result = mk.original_test(speedAveA[0,:])
print(result)

result = mk.sens_slope(speedAveA[0,:])
print(result)


result = mk.hamed_rao_modification_test(speedAveA[0,:])
print(result)


filename = "dat_atl_all.nc"
ncin = Dataset(filename, 'r', format='NETCDF4')
speedAveB = ncin.variables['ave']



yearS = ncin.variables['startYear']
yearE = ncin.variables['endYear']

years = np.arange ( yearS[0] , yearE[0]+1 )
df = pd.DataFrame(data=[years,speedAveA,speedAveB])


speed =  np.column_stack( (speedAveA[0,:],speedAveB[0,:]) )

plt.plot(years,speedAveA[0,:],label='NO ET')
plt.plot(years,speedAveB[0,:],label='ALL')
plt.legend()    

plt.show()
