
from netCDF4 import Dataset
import matplotlib.pyplot as plt
from matplotlib.cm import get_cmap
from mpl_toolkits.basemap import Basemap
from wrf import to_np, getvar, smooth2d, get_basemap, latlon_coords
import numpy as np

# This line is here so that this script can work on my Mac (?)
plt.switch_backend('agg')



yy = "2013"
mo = "05"
dd = "20"
hh = "20"
mm = "00"
title = 'NR'

NatureRun = True

# File path
#filename = '/scratch/admoore/WRFrun3/april_exps/uav1/wrfout_d01_'+yy+'-'+mo+'-'+dd+'_'+hh+':'+mm+':00'

#filename = '/scratch/admoore/WRFrun2/50stations/wrfout_d01_'+yy+'-'+mo+'-'+dd+'_'+hh+':'+mm+':00'

filename = '/scratch/admoore/oldNR/arps_'+hh+mm

# Outdirectory
outdir = '/home/admoore/'



# Open the NetCDF file
ncfile = Dataset(filename)

# Get the WRF variables
slp = getvar(ncfile, "slp")
Tk  = getvar(ncfile, "temp",units="K")
#Qv  = getvar(ncfile, "QV")
CAPE,CIN,lcl,lfc = to_np(getvar(ncfile, "cape_2d"))





# Smooth the sea level pressure since it tends to be noisy near the mountains
if (NatureRun):
    smooth_cape = smooth2d(CAPE, 8)
    smooth_cin  = smooth2d(CIN, 8)
else:
    smooth_cape = smooth2d(CAPE, 3)
    smooth_cin  = smooth2d(CIN, 3)

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
CapeLevs = np.arange(0,5000.,250.)
CinLevs  = np.arange(0,300,50.) 

# Draw the contours and filled contours
bm.contourf(x, y, smooth_cape, CapeLevs, cmap=get_cmap("jet"))

# Color bar
plt.colorbar(shrink=.62)

cinContour = bm.contour(x, y, smooth_cin, CinLevs, colors="black")
plt.clabel(cinContour,fontsize=8,inline=1,linewidth=1)




plt.title(title+" MUCAPE (fill) MUCIN (contour) (J/kg)",fontsize=20)

plt.savefig(outdir+title+hh+mm+"Cape.png")

