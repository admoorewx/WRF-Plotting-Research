
from netCDF4 import Dataset
import matplotlib.pyplot as plt
from matplotlib.cm import get_cmap
from mpl_toolkits.basemap import Basemap
from wrf import to_np, getvar, smooth2d, get_basemap, latlon_coords
import numpy as np

# This line is here so that this script can work on my Mac (?)
plt.switch_backend('agg')


yy = "2018"
mo = "04"
dd = "29"
hh = "20"
mm = "00"
title = 'N.P. WRF'

NatureRun = False

# File path
filename = '/scratch/admoore/WRFGF/GrandForks/wrfout_d01_'+yy+'-'+mo+'-'+dd+'_'+hh+':'+mm+':00'
# Outdirectory
outdir = '/home/admoore/GF/'


# Open the NetCDF file
ncfile = Dataset(filename)

# Get the WRF variables
slp = getvar(ncfile, "slp")
Tk  = getvar(ncfile, "temp",units="K")
#Qv  = getvar(ncfile, "QV")
#CAPE,CIN,lcl,lfc = to_np(getvar(ncfile, "cape_2d"))
helicity = to_np(getvar(ncfile, "mdbz"))




# Smooth the sea level pressure since it tends to be noisy near the mountains
if (NatureRun):
    smooth_cape = smooth2d(helicity, 8)
    
else:
    smooth_cape = smooth2d(helicity, 3)
    

# Get the latitude and longitude points
lats, lons = latlon_coords(slp)

# Get the basemap object
bm = get_basemap(slp)

# Create a figure
fig = plt.figure(figsize=(12,9))

# Add geographic outlines
bm.drawcoastlines(linewidth=0.25)
bm.drawstates(linewidth=0.25)
bm.drawcountries(linewidth=0.25)
bm.drawcounties(linewidth=0.25)

# Convert the lats and lons to x and y.  Make sure you convert the lats and lons to
# numpy arrays via to_np, or basemap crashes with an undefined RuntimeError.
x, y = bm(to_np(lons), to_np(lats))

#clevs = [996., 998., 1000., 1002., 1004., 1006., 1008., 1010., 1012., 1014., 1016., 1018.]
#CapeLevs = np.arange(0,8000.,250.)

# Draw the contours and filled contours
bm.contourf(x, y, smooth_cape, cmap=get_cmap("jet"))

# Color bar
plt.colorbar(shrink=.62)


plt.title(title+" Comp Refl (dBz)")

plt.savefig(outdir+title+hh+mm+"Refl.png")

