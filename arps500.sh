#!/bin/bash
cat << arps500.py | sed -e 's/ *$//' > /home/admoore/scripts/arps500.py


import numpy as np
from netCDF4 import Dataset
import matplotlib.pyplot as plt
from matplotlib.cm import get_cmap
from mpl_toolkits.basemap import Basemap
from wrf import interplevel, to_np, getvar, smooth2d, get_basemap, latlon_coords

hh = "${Hour}"
mm = "${Minute}"
title = '${Title}'

# File path
#filename = '${WRFdir}/wrfout_d01_2013-05-20_'+hh+':'+mm+':00'
#filename = '/scratch/admoore/wrfout/wrfout_d01_2013-05-20_'+hh+':'+mm+':00_AAA'
filename = '${WRFdir}/arps_'+hh+mm
print(filename)
# Outdirectory
outdir = '${WRFdir}'

# Open the NetCDF file
ncfile = Dataset(filename)

# Extract the pressure, geopotential height, and wind variables
p = getvar(ncfile, "pressure")
z = getvar(ncfile, "z", units="dm")
ua = getvar(ncfile, "ua", units="m s-1")
va = getvar(ncfile, "va", units="m s-1")
wspd = getvar(ncfile, "wspd_wdir", units="m s-1")[0,:]

# Interpolate geopotential height, u, and v winds to 500 hPa
ht_500 = smooth2d(interplevel(z, p, 500),25)
u_500 = smooth2d(interplevel(ua, p, 500),10)
v_500 = smooth2d(interplevel(va, p, 500),10)
wspd_500 = smooth2d(interplevel(wspd, p, 500),10)

# Get the lat/lon coordinates
lats, lons = latlon_coords(ht_500)

# Get the basemap object
bm = get_basemap(ht_500)

# Create the figure
fig = plt.figure(figsize=(12,9))
ax = plt.axes()

# Convert the lat/lon coordinates to x/y coordinates in the projection space
x, y = bm(to_np(lons), to_np(lats))

# Add the 500 hPa geopotential height contours
levels = np.arange(520., 580., 6.)
contours = bm.contour(x, y, to_np(ht_500), levels=levels, colors="black")
plt.clabel(contours, inline=1, fontsize=10, fmt="%i")

# Add the wind speed contours
levels = [25, 30, 35, 40, 50, 60, 70, 80, 90, 100, 110, 120]
wspd_contours = bm.contourf(x, y, to_np(wspd_500), levels=levels,
                            cmap=get_cmap("rainbow"))
plt.colorbar(wspd_contours, ax=ax, orientation="horizontal", pad=.05)

# Add the geographic boundaries
bm.drawcoastlines(linewidth=0.25)
bm.drawstates(linewidth=0.25)
bm.drawcountries(linewidth=0.25)

# Add the 500 hPa wind barbs, only plotting every 125th data point.
bm.barbs(x[::125,::125], y[::125,::125], to_np(u_500[::125, ::125]),
         to_np(v_500[::125, ::125]), length=6)

plt.title(title+" 500 MB Height (dm), Wind Speed (m/s), Barbs (m/s)")

plt.savefig(outdir+'500'+hh+mm)

arps500.py
