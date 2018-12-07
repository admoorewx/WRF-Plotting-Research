#!/bin/bash
cat << wrfmlsp.py | sed -e 's/ *$//' > /home/admoore/scripts/wrfmlsp.py

from netCDF4 import Dataset
import matplotlib.pyplot as plt
from matplotlib.cm import get_cmap
from mpl_toolkits.basemap import Basemap
from wrf import to_np, getvar, smooth2d, get_basemap, latlon_coords

dd = "${Day}"
hh = "${Hour}"
mm = "${Minute}"
title = '${Title}'

# File path
#filename = '${WRFdir}/wrfout_d01_2013-05-'+dd+'_'+hh+':'+mm+':00'
#filename = '/scratch/admoore/wrfout/wrfout_d01_2013-05-20_'+hh+':'+mm+':00_AAA'
filename = '${WRFdir}/arps_'+hh+mm
print(filename)
# Outdirectory
outdir = '${outdir}'

smoother = 50

# Open the NetCDF file
ncfile = Dataset(filename)

# Get the sea level pressure
slp = getvar(ncfile, "slp")

# Smooth the sea level pressure since it tends to be noisy near the mountains
smooth_slp = smooth2d(slp, smoother)

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

# Convert the lats and lons to x and y.  Make sure you convert the lats and lons to
# numpy arrays via to_np, or basemap crashes with an undefined RuntimeError.
x, y = bm(to_np(lons), to_np(lats))

clevs = [996., 998., 1000., 1002., 1004., 1006., 1008., 1010., 1012., 1014., 1016., 1018.]

# Draw the contours and filled contours
bm.contour(x, y, to_np(smooth_slp), clevs, colors="black")
bm.contourf(x, y, to_np(smooth_slp), clevs, cmap=get_cmap("jet"))

# Add a color bar
plt.colorbar(shrink=.62)

plt.title(title+" Sea Level Pressure (hPa)")

plt.savefig(outdir+title+hh+mm)

wrfmlsp.py
