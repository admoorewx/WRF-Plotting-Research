#!/bin/sh

#declare -a hours=( 20 21 22 23 00 01 02 03 04 05 )
#declare -a minutes=( 00 ) 

declare -a hours=( 12 13 14 15 16 17 18 )
declare -a minutes=( 00 05 10 15 20 25 30 35 40 45 50 55 )



for fus in ${hours[@]}; do

    for rho in ${minutes[@]}; do 


        # Establish the time  
        export hour="$fus" 
        export minute="$rho"
        export time=${hour}${minute}
        
        # Getting the number of seconds
        export seconds=$((${hour}-12))
        export seconds=$((${seconds}*3600))
	export msec=$((${minute}*60))
	export seconds=$((${seconds}+${msec}))


	# Going to have to format the time correctly
	# The minimum time will be 5 min * 60 sec = 300 seconds
	if [ ${seconds} -eq 0 ] 
	then
	    export seconds=000000
	
	elif [ ${seconds} -lt 1000 ] 
	then
	    export seconds=000${seconds}
	
	elif [ ${seconds} -lt 10000 ] 
	then
	    export seconds=00${seconds}

	elif [ ${seconds} -lt 100000 ] 
	then 
	    export seconds=0${seconds}

	fi



        echo "${time} == ${seconds}"
        echo ""
    

        export nexthour="$fus"
        export nextminute=$(($rho+10))
        #export nextminute=05
        export startday=20
        export endday=20


        # Check to make sure the top of the hour switches correctly
        if [ "$rho" -eq "55" ] 
        then 
            nextminute=00
            nexthour=$(($fus+01))
        fi


        #Checking to see which day and time we're at
        if [ "$fus" -eq "23" ] && [ "$rho" -eq "55" ] 
        then
            echo "Switching to May 10th"
            export nexthour=00
            export endday=21
            export nextminute=00
        fi

        if [ "$fus" -lt "12" ]
        then
            export startday=21
            export endday=21
        fi
        
        echo "Processing time:"
        echo "${startday}${hour}${minute}"
        echo "Ending at:"
        echo "${endday}${nexthour}${nextminute}"
    

	# Creating the met_em files with arps4wrf
	cd /scratch/admoore/arps5.4.23/runMay20/input
	./arps4wrf.sh
	cd /scratch/admoore/arps5.4.23
	bin/arps4wrf < runMay20/input/arps4wrf.input > arps4wrf.out

	# Copy over the met_em files
	cd /home/admoore/WRF/convert
	ln -sf /scratch/admoore/May20_metem/met* .


        # Remove old wrfinput
        rm /home/admoore/WRF/convert/rsl.*
        rm /home/admoore/WRF/convert/wrfinput_d01


        # Create the namelist file and submit real.exe
        /home/admoore/WRF/convert/namelist_convert.sh
        sbatch /home/admoore/WRF/convert/realpara.sh


        # Check to make sure the previous real.exe is finished running
	counter=0
        while [ ! -e '/home/admoore/WRF/convert/wrfinput_d01' ]
        do
            echo "waiting..."
            sleep 2m
	    if [ ${counter} -eq 4 ]
	    then
		echo "Error: Problem with real.exe."
		exit
	    fi
	    counter=$((${counter}+1))

        done

	sleep 15s
        # copy and delete some shit
        cp /home/admoore/WRF/convert/wrfinput_d01 /scratch/admoore/WRF3/arps_${time}
                
        # Issuing a wait command to hopefully give it a chance to completely write the file 
        # over instead of being stopped as the next file begins. 
        sleep 15s
      

    done # With minute loop
done # With hour loop

echo "!!!! Success !!!!"

