#!/bin/sh

#declare -a hours=( 12 13 14 15 16 17 18 )
#declare -a minutes=( 00 )

declare -a hours=( 21 22 23 00 01 02 03 04 05 06 )
declare -a minutes=( 00 30 )

export WRFdir=/scratch/admoore/oldNR
export outdir=/home/admoore/April_exps/NR/
export Title="ARPS Nature Run"
export plotdir=/home/admoore/scripts
export model="arps"

for hh in ${hours[@]}; do
# Setting the day and time. Make adjustment to day if hour is 23z. 
    export Hour=${hh} 
    
    echo "${Hour}"

    #Checking to see which day and time we're at
    if [ ${hh} -ge "12" ] 
    then 
       
	export Day=20
    fi 

    if [ ${hh} -lt "12" ] 
    then
	export Day=21
    fi

    for mm in ${minutes[@]}; do

        export Minute=${mm}
        echo "Plotting Time: ${hh}:${mm}"
        ${plotdir}/wrfmlsp.sh
        python ${plotdir}/wrfmlsp.py > wrfmlsp.out

        ${plotdir}/${model}850.sh
        python ${plotdir}/${model}850.py > ${model}850.out
        
        ${plotdir}/${model}500.sh
        python ${plotdir}/${model}500.py > ${model}500.out

        ${plotdir}/plot_${model}_maps.sh
        python ${plotdir}/plot_${model}_maps.py > WRFplot.out
 
        counter=0
        while [ ! -e ${outdir}/Flag.png ]
        do
            
            counter=$((${counter}+1))
            sleep 5s 
            if [ ${counter} -ge 10 ]
            then
                echo "Error Creating Image."
                exit
            fi
        done #While done
        
        rm ${outdir}/Flag.png

    done # minute for done



    
done # hour for done

echo "!!!! Success !!!!" 

