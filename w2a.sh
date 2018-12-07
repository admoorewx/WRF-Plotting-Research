#!/bin/sh

declare -a hours=( 12 14 15 16 17 18 19 20 21 22 23 00 01 02 03 04 05 06 )
declare -a minutes=( 00 ) 

#declare -a hours=( 00 01 02 03 04 05 12 13 14 15 16 17 18 19 20 21 22 23 )
#declare -a minutes=( 05 10 15 20 25 30 35 40 45 50 55 )

# !!! Make sure that you have already linked over the necessary met_em files into WRF/run directory !!!


for fus in ${hours[@]}; do

    for rho in ${minutes[@]}; do 
 
        export hour="$fus" 
        export minute="$rho"
        export day=20

        #Checking to see which day and time we're at
        if [ "$fus" -lt "12" ]
        then
            export day=21
        fi
        
        echo "Processing time:"
        echo "${day}_${hour}:${minute}"

        # Copy the arps file to a wrfout file
        cp /scratch/admoore/WRF/5min/arps_${hour}${minute} /scratch/admoore/WRF/5min/wrfout_d01_2013-05-${day}_${hour}:${minute}:00  

        # Give it a few minutes to do its thing.
        sleep 2m
        echo ""


        # Check to make sure the previous real.exe is finished running
#        while [ ! -e '/home/admoore/WRF/convert/wrfinput_d01' ]
#        do
#            echo "waiting..."
#            sleep 3m
#        done

     

    done # With minute loop
done # With hour loop

echo "!!!! Success !!!!"

