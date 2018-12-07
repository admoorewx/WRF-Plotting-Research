#!/bin/bash

# ---------------------------------------------------------------------
# 
# Use meso2lso code in ARPS directory to create OKLAHOMA MESONET 
# .lso files.  
#
# ---------------------------------------------------------------------

dateStr=20130520
# MESODATA = directory where the Oklahoma mesonet files are located
export MESODATA="/scratch/admoore/simulatedObs"

# This will make 5-minute lso files for a full 24 hour period.
# Change loop limits if you don't need that much data processed
for hh in {12..12}; do
	mm=0
	while [ $mm -le 0 ]; do
		hh=`printf "%02d" ${hh}`
 		mm=`printf "%02d" ${mm}`
		
		/home/admoore/meso2lso -t ${dateStr}${hh}${mm}

		cp ${dateStr}${hh}${mm}.lso /scratch/admoore/meso${dateStr}${hh}${mm}.lso
		rm ${dateStr}${hh}${mm}.lso
                rm lsoname.last
                mm=$((mm + 5))
	done
done


