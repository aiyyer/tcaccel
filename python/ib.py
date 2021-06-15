from netCDF4 import Dataset
from matplotlib.dates import num2date,date2num
import xarray as xr
import numpy as np
import datetime as dt
import cftime as cf
from mpl_toolkits.basemap import Basemap
import matplotlib.pyplot as plt



dataDir  = "/home/anant/data50/data/ibtracs/"
filename = "IBTrACS.since1980.v04r00.nc"
file = dataDir + filename

try:
    ds = xr.open_dataset(file,decode_cf=False)
except:
    print ("file not found. quitting code")
    quit()

print ("Ibtracs file found and opened")
time   = ds.time
lat    = ds.lat
lon    = ds.lon
numobs = ds.numobs
speed  = ds.storm_speed


# we get indices of only the synoptic hours
timeFirst = time[:,0]

print (timeFirst.values)
