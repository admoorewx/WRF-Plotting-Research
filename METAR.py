# -*- coding: utf-8 -*-
"""
METAR.py 
Reads in Metar data and displays it.
"""
import csv
import requests
from datetime import datetime
import time
import os


#################### USER SELECTABLE PARAMETERS #################################
# This is where to find the Metar CSV file. Change only as necessary!
CSV_URL = 'https://www.aviationweather.gov/adds/dataserver_current/current/metars.cache.csv'

# If you want this to automatically update then set this to "True"
autoUpdate = False

# This sets how frequently (in minutes) you want to automatically check for updates. 
UpdateFrequency = 10

# Number of lines to skip. This should not be changed unless the format of the downloaded CSV
# file changes. 
skip = 5

# This is a list of all stations that you want displayed and updated. You must know the 
# station's four letter identifier (for example, the Grand Forks, ND airport is KGFK). 
Station_List = ["KGFK","KRDR","KFAR","KDVL","KBJI","KHCO","KPKD","KROX","KBDE"]

#################################################################################

def trunc(f, n):
###############################################################################
    '''Truncates/pads a float f to n decimal places without rounding'''
    s = '{}'.format(f)
    if 'e' in s or 'E' in s:
        return '{0:.{1}f}'.format(f, n)
    i, p, d = s.partition('.')
    return '.'.join([i, (d+'0'*n)[:n]])
###############################################################################

def C2F(tempC):
###############################################################################
# Converts degrees C to degrees F
    return (tempC * (9./5.) + 32.)
###############################################################################

def knts2mph(wspd):
###############################################################################
# Converts wind speed in knots to mph
    return (wspd * 1.1507794)
###############################################################################

def windChill(tempC,wspd):
###############################################################################
# Finds Wind Chill in degrees F
    if wspd != 0.0:
        A = 35.74 + (0.6215 * C2F(tempC))
        B = 35.75 * knts2mph(wspd)**0.16
        C = 0.4275 * C2F(tempC) * knts2mph(wspd)**0.16
        return trunc((A - B + C),2)
    else:
        return trunc(C2F(tempC),2)
###############################################################################
        

# This is an arbitrarily named variable used to keep the while loop going.
GetMETAR = True

while (GetMETAR):

    os.system('cls' if os.name == 'nt' else 'clear')
    print("Press Control+C to exit this program at any time.")
    print("")
    print("The Current Time Is:"+'\n')
    print("  "+str(datetime.now())[0:17])
    print("")

    with requests.Session() as s:
        download = s.get(CSV_URL)
        decoded_content = download.content.decode('utf-8')

        datafile = csv.reader(decoded_content.splitlines(), delimiter=',')
        data = list(datafile)
        data = data[skip:]
    
        for row in data:
            for stid in Station_List:
                if row[1] == stid:
                    print(row[0])
                    print("Temperature F: "+str(C2F(float(row[5]))))
                    print("Dewpoint F: "+str(C2F(float(row[6]))))
                    print("Wind Chill in F: "+str(windChill(float(row[5]),float(row[8]))))
                    print("")
        


        if (autoUpdate):

	        # Wait for the next update.
        	time.sleep(60.*UpdateFrequency)
        	GetMETAR = True
	else:
		GetMETAR = False
# End of while loop        
        
        
        



        
