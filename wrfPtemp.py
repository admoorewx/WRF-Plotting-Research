
import numpy as np
from netCDF4 import Dataset
import matplotlib.pyplot as plt
from matplotlib.cm import get_cmap
from mpl_toolkits.basemap import Basemap
from wrf import interplevel, to_np, getvar, smooth2d, get_basemap, latlon_coords

dd = "20"
hh = "17"
mm = "30"
title = 'NR'

Plevel = 850

# File path
#filename = '/scratch/admoore/WRFrun3/april_exps/uav1/wrfout_d01_2013-05-'+dd+'_'+hh+':'+mm+':00'
#filename = '/scratch/admoore/wrfout/wrfout_d01_2013-05-20_'+hh+':'+mm+':00_AAA'
filename = '/scratch/admoore/oldNR/arps_'+hh+mm
print(filename)
# Outdirectory
outdir = '/home/admoore/'

smoother = 0

# Open the NetCDF file
ncfile = Dataset(filename)

# Extract the pressure, geopotential height, and wind variables
p = getvar(ncfile, "pressure")
z = getvar(ncfile, "z", units="dm")
ua = getvar(ncfile, "ua", units="m s-1")
va = getvar(ncfile, "va", units="m s-1")
wspd = getvar(ncfile, "wspd_wdir", units="m s-1")[0,:]
temp = getvar(ncfile, "temp", units="K")


# Interpolate geopotential height, u, and v winds to 500 hPa
ht_850 = smooth2d((interplevel(z, p, Plevel)),smoother)
u_850 = interplevel(ua, p, Plevel)
v_850 = interplevel(va, p, Plevel)
wspd_850 = smooth2d((interplevel(wspd, p, Plevel)),0)
temp_850 = smooth2d(interplevel(temp,p,Plevel),smoother)

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
#levels = np.arange(140., 150., 2.)
contours = bm.contour(x, y, to_np(ht_850), colors="black")
plt.clabel(contours, inline=1, fontsize=10, fmt="%i")


# Add the wind speed contours
levels = [284, 286, 288, 290, 292, 294, 296, 298, 300, 302]
temp_contours = bm.contourf(x, y, to_np(temp_850), levels=levels, 
                            cmap=get_cmap("gnuplot2"))
cbar = plt.colorbar(temp_contours, ax=ax, orientation="vertical", pad=.05)
cbar.set_label('K',rotation=90,fontsize=15)

# Add the geographic boundaries
bm.drawcoastlines(linewidth=0.25)
bm.drawstates(linewidth=0.25)
bm.drawcountries(linewidth=0.25)

plt.title(title+' '+str(Plevel)+' hPa Heights (dm), Temperature (K)')

plt.savefig(outdir+title+'_'+str(Plevel)+'_Temp_'+hh+mm)

