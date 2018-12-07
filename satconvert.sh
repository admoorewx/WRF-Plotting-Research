#!/bin/sh


export CURR_DIR=/scratch/admoore/arps5.4.23/sat

export nx=1003
export ny=1003
export nz=63

export dx=1000
export dy=1000
export ctrlat=$((34.0))
export ctrlon=$((-96.4))

export type="vis"

declare -a times=( 1200 1400 1600 )


for hh in ${times[@]}; do
    export hour=$hh
    /scratch/admoore/arps5.4.23/sat/sat_input.sh
    /scratch/admoore/arps5.4.23/bin/mci2arps /scratch/admoore/obs/goes15$type/goes15"$type"_20160509_$hour -hdf < sat.input



