
import numpy as np
from netCDF4 import Dataset
import matplotlib.pyplot as plt
from matplotlib.cm import get_cmap
from mpl_toolkits.basemap import Basemap
from wrf import interplevel, to_np, getvar, smooth2d, get_basemap, latlon_coords

dd = "20"
hh = "20"
mm = "00"
title = 'NR'

# File path
#filename = '/scratch/admoore/WRFrun3/april_exps/uav1/wrfout_d01_2013-05-'+dd+'_'+hh+':'+mm+':00'
#filename = '/scratch/admoore/wrfout/wrfout_d01_2013-05-20_'+hh+':'+mm+':00_AAA'
filename = '/scratch/admoore/WRF/5min/arps_'+hh+mm
print(filename)
# Outdirectory
outdir = '/home/admoore/April_exps/NR/'

smoother = 15

# Open the NetCDF file
ncfile = Dataset(filename)

# Extract the pressure, geopotential height, and wind variables
p = getvar(ncfile, "pressure")
z = getvar(ncfile, "z", units="dm")
ua = getvar(ncfile, "ua", units="m s-1")
va = getvar(ncfile, "va", units="m s-1")
wspd = getvar(ncfile, "wspd_wdir", units="m s-1")[0,:]

# Interpolate geopotential height, u, and v winds to 500 hPa
ht_850 = smooth2d((interplevel(z, p, 850)),smoother+10)
u_850 = interplevel(ua, p, 850)
v_850 = interplevel(va, p, 850)
wspd_850 = smooth2d((interplevel(wspd, p, 850)),smoother-7)

# Get the lat/lon coordinates
lats, lons = latlon_coords(ht_850)

# Get the basemap object
bm = get_basemap(ht_850)

# Create the figure
fig = plt.figure(figsize=(12,9))
ax = plt.axes()

# Convert the lat/lon coordinates to x/y coordinates in the projection space
x, y = bm(to_np(lons), to_np(lats))

# Add the 500 hPa geopotential height contours
levels = np.arange(140., 150., 2.)
contours = bm.contour(x, y, to_np(ht_850), levels=levels, colors="black")
plt.clabel(contours, inline=1, fontsize=10, fmt="%i")

# Add the wind speed contours
levels = [10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60, 65]
wspd_contours = bm.contourf(x, y, to_np(wspd_850), levels=levels,
                            cmap=get_cmap("rainbow"))
plt.colorbar(wspd_contours, ax=ax, orientation="horizontal", pad=.05)

# Add the geographic boundaries
bm.drawcoastlines(linewidth=0.25)
bm.drawstates(linewidth=0.25)
bm.drawcountries(linewidth=0.25)

# Add the 500 hPa wind barbs, only plotting every 125th data point.
bm.barbs(x[::125,::125], y[::125,::125], to_np(u_850[::125, ::125]),
         to_np(v_850[::125, ::125]), length=6)

plt.title(title+" 850 MB Height (dm), Wind Speed (m/s), Barbs (m/s)")

plt.savefig(outdir+'850'+hh+mm)

