import matplotlib
from netCDF4 import Dataset
import matplotlib.pyplot as plt
from matplotlib.cm import get_cmap
from mpl_toolkits.basemap import Basemap
from wrf import to_np, getvar, smooth2d, get_basemap, latlon_coords
import csv

# This line is here so that this script can work on my Mac (?)
plt.switch_backend('agg')

dd = "20"
hh = "18"
mm = "00"
title = 'UAV'


# File path
filename = '/scratch/admoore/WRFrun3/wrfout_d01_2013-05-'+dd+'_'+hh+':'+mm+':00'
#filename = '/scratch/admoore/wrfout/wrfout_d01_2013-05-20_'+hh+':'+mm+':00_AAA'
#filename = '/scratch/admoore/wrfout2/wrfout_d01_2013-05-20_'+hh+':'+mm+':00_FFF'
#filename = '/scratch/admoore/WRF/5min/arps_'+hh+mm
print(filename)
# Outdirectory
outdir = '/home/admoore/'



def mesonetGrid():
#### Retrieving Lat/Lon from Geomeso #########
    lat = []
    lon = []
    stid = []
    flag = []
    stnm = []

    geomeso = ('/home/admoore/scripts/geodrone.csv')

    with open(geomeso,'rU') as csvfile:
        reader = csv.reader(csvfile,delimiter=',', quotechar='|')
        for row in reader:
            stid.append(row[0])
            lat.append(float(row[1]))
            lon.append(float(row[2]))
            flag.append(int(row[3]))
            stnm.append(int(row[4]))
        return stid,lat,lon,flag,stnm

##############################################


# Open the NetCDF file
ncfile = Dataset(filename)

# Get the sea level pressure
slp = getvar(ncfile, "slp")

# Smooth the sea level pressure since it tends to be noisy near the mountains
smooth_slp = smooth2d(slp, 3)

# Get the latitude and longitude points
lats, lons = latlon_coords(slp)

# Get the basemap object
bm = get_basemap(slp)

# Create a figure
#fig = plt.figure(figsize=(12,9))
plt.figure(figsize=(12,9))

# Add geographic outlines
bm.drawcoastlines(linewidth=0.25)
bm.drawstates(linewidth=0.25)
bm.drawcountries(linewidth=0.25)
bm.drawcounties(linewidth=0.25)

# Convert the lats and lons to x and y.  Make sure you convert the lats and lons to
# numpy arrays via to_np, or basemap crashes with an undefined RuntimeError.
x, y = bm(to_np(lons), to_np(lats))

clevs = [996., 998., 1000., 1002., 1004., 1006., 1008., 1010., 1012., 1014., 1016., 1018.]

# Draw the contours and filled contours
bm.contour(x, y, to_np(smooth_slp), clevs, colors="black")
bm.contourf(x, y, to_np(smooth_slp), clevs, cmap=get_cmap("jet"))

# Add a color bar
plt.colorbar(shrink=.62)

stid,lat,lon,flag,stnm = mesonetGrid()
okx,oky = bm(lon,lat)
bm.plot(okx,oky,marker='.',color='k',linestyle='')


plt.title(title+" Sea Level Pressure (hPa)")

plt.savefig(outdir+title+hh+mm)

