#!/bin/sh

#declare -a exp=(casaonly no88d nocasa nocwop noCWOPWXBUG nogst nonewradar nonewsfc noradar notdwr nounderstory nowxbug tdwronly CTLdouble nocasavr notestbed)
#declare -a exp=(nocwop noCWOPWXBUG nogst)
#declare -a exp=(noCWOPWXBUG nonewsfc nowxbug nocwop)
declare -a exp=(twocycles_redo DMtwocycles TMtwocycles)
declare -a sec=(3000 3600) # 4200 4800 5400 6000 6600 7200 7800 8400 9000 9600) 

for i in ${exp[@]}; do
    export experiment="$i"
    echo $experiment

    if [ "$experiment" == "twocycles_redo" ]; then
        opt=8
    elif [ "$experiment" == "DMtwocycles" ]; then
        opt=9
    else
        opt=11
    fi

    export rfopt="$opt"
    echo $rfopt

    mkdir -p /scratch/mtmorris/reflectivity/${experiment}

    for j in ${sec[@]}; do
	export seconds="$j"
	echo $seconds

	./arpsplt_refl.sh
	/home/mtmorris/arps5.4.1/bin/arpspltpost < arpsplt.arpsin
	mv ${experiment}_fcstrefl_${seconds}.ps /scratch/mtmorris/reflectivity/${experiment}/
	convert /scratch/mtmorris/reflectivity/${experiment}/${experiment}_fcstrefl_${seconds}.ps /scratch/mtmorris/reflectivity/${experiment}/${experiment}_fcstrefl_${seconds}.png

	#scp ${experiment}*${seconds}_neighvrf.csv mtmorris@stratus.caps.ou.edu:/non/mtmorris/runs_20160411/small_grid_1km_sfc88d_${experiment}/

    done 
done

