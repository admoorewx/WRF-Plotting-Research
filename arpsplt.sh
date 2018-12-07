#!/bin/sh


#declare -a times=(00000 03600 07200 10800 14400 18000 21600 25200 28800 32400 36000 39600 43200)

declare -a times=(00000)

for fus in ${times[@]}; do
    export seconds="$fus" 
    echo $fus

    ./arpsplt_refl.sh
    /scratch/admoore/arps5.4.23/bin/arpspltpost r< arpsplt.arpsin
    convert /scratch/admoore/arps5.4.23/images/NR${seconds}.ps /scratch/admoore/arps5.4.23/images/NR${seconds}.jpg
    rm /scratch/admoore/arps5.4.23/images/NR${seconds}.ps
done


