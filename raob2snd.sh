#!/bin/sh


declare -a times=(1600)

cd /scratch/admoore

for t in ${times[@]}; do
	export soundingtime="$t"
	./cdfraob /scratch/admoore/obs/raob/raob.20160509_${soundingtime} 20160509${soundingtime}

done

