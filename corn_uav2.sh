#!/bin/sh

# Times you want to process
declare -a hours=( 12 13 14 15 16 17 18 )
declare -a minutes=( 00 30 ) 

#Arps directory
arps=/scratch/admoore/arps5.4.23

#WRF directory
WRFdir=/scratch/admoore/WRFrun3

# WRF2ARPS directory
wrf2arps=/scratch/admoore/wrf2arps

# ARPS2WRF directory
arps2wrf=/scratch/admoore/arps2wrf

# ARPS4WRF directory
arps4wrf=${arps}/arps4wrf/wrf

# WRFOUT directory
wrfout=/scratch/admoore/wrfout

# GFS met_em files directory
GFSmetem=/scratch/admoore/gfs_metem_051500_hourly



# Start by deleting old met_em, wrfinput, wrfout files from directory

cd ${WRFdir}
echo "${WRFdir}"

rm met_em*
rm wrfinput*
rm wrfout*
rm rsl*

# Copy over the met_em files
ln -sf ${GFSmetem}/met_em* ${WRFdir}

# Check to make sure that the files were correctly linked

if [ -e "${WRFdir}/met_em.d01.2013-05-20_12:00:00.nc" ]
then
    echo "Met_em files were successfully linked."
else
    echo "Failure: met_em files not linked!"
    exit
fi


echo "Beginning DA procedures."
# Now begin processing through
for hh in ${hours[@]}; do

    for mm in ${minutes[@]}; do 



	if [ ${hh} -eq 18 ] && [ ${mm} -eq 30 ] 
	then
            echo ""
	    echo "!!!! Completion of UAV DA Procedures !!!!"
            echo ""
        fi 

        export starthour="$hh" 
        export startmin="$mm"
        export startday=20
      
        echo ""  
        echo "Processing time ${startday} - ${starthour}:${startmin}"
        echo ""

        #export endhour=$((${hh}+1))
        #export endday=20

        #export metgrid_levels=27
        #export max_dom=1

        #Checking to see which minute we're at
        if [ "$mm" -eq "30" ]
        then
            export endmin=00
        else
            export endmin=30
        fi
        


        if [ ${hh} -eq 12 ] && [ ${mm} -eq 00 ]
        then
            echo "This is the first DA cycle."
            export starthour=${hh}
            export endhour=${hh}
            export startday=20
            export endday=20
            export startmin=00
            export endmin=30
            export metgrid_levels=27
            export max_dom=1
            ${WRFdir}/namelist_DA_uav.sh
            #sbatch ${WRFdir}/real.sh
            echo "Submitted real.exe for time 1200."
            ${WRFdir}/real.exe

            # Check to make sure that real.exe is finished running
            counter=0 # This will track how many times we have to wait
            while [ ! -e ${WRFdir}/wrfinput_d01 ]
            do
                echo "Waiting..."
                counter=$((${counter}+1))
                sleep 2m
                if [ ${counter} -ge 15 ]
                then
                    echo "Possible error creating wrfinput. Check rsl.error file."
                    exit
                fi

            done
            # Now copy this wrfinput file onto scratch and remove from /home to save space

            cp ${WRFdir}/wrfinput_d01 /scratch/admoore/wrfout/wrfout_d01_2013-05-20_${hh}:${mm}:00
            #rm /home/admoore/WRF/run/wrfinput_d01
            echo "Successful run of real.exe."

        else
            echo ""
            echo "This is NOT the first DA cycle. Taking previous WRF output as background."
            # Just take the WRF output from the forecast and copy that over for WRF2ARPS
            cp ${WRFdir}/wrfout_d01_2013-05-20_${hh}:${mm}:00 ${wrfout}/wrfout_d01_2013-05-20_${hh}:${mm}:00
            # Remove old output files
            rm ${WRFdir}/wrfout*


        fi

        # Now we can submit the WRF2ARPS program to run
        # But first remove old files if they're there.
        rm ${wrf2arps}/wrfassim_${hh}${mm}.hdfgrdbas
        rm ${wrf2arps}/wrfassim_${hh}${mm}.hdf000000


        ################### WRF2ARPS ####################
        export starthour=${hh}
        export startmin=${mm}
        export startday=20
        ${arps}/run/input/wrf2arps_input_uav.sh
        #sbatch ${arps}/wrf2arps.sh
        echo "Submitted WRF2ARPS."

        ${arps}/bin/wrf2arps < ${arps}/run/input/wrf2arps.input > wrf2arps.out

        counter=0 # Resetting the counter.
        while [ ! -e ${wrf2arps}/wrfassim_${hh}${mm}.hdfgrdbas ]
        do
            echo "Waiting..."
            counter=$((${counter}+1))
            sleep 2m
            if [ ${counter} -ge 15 ]
            then
                echo "WRF2ARPS Failure. Check output."
                exit
            fi
        done
        echo "Successful run of WRF2ARPS"


        ################### ADAS ####################

        # First need to remove old files
        rm ${arps2wrf}/WRFASSIM_${hh}${mm}.hdf000000
        rm ${arps2wrf}/WRFASSIM_${hh}${mm}.hdfgrdbas

        # Once WRF2ASRPS is done we can send it through ADAS
        # Need to export the previous hour to get data
        export previoushour=$(($hh-1))

        # if this is 12z then we can only use the GFS and UAV soundings
        if [ ${hh} -eq 12 ]
        then
            export mesoNum=0
        else
            export mesoNum=1
            #export mesoNum=1 to use mesonet data
            echo "Using Mesonet Data."
        fi

	# This handles the case when it is half past the hour and we only assimilate the UAV obs.
	if [ ${mm} -eq 30 ]
        then 
            export mesoNum=0
            export uaNum=1
        else
            export mesoNum=1
            export uaNum=2
	fi

        ${arps}/run/input/adas_wrf.sh
        sbatch ${arps}/adas_serial.sh
        echo "Submitted ADAS"
        # Need to check to make sure ADAS ran correctly
        counter=0 # Resetting the counter
        while [ ! -e ${arps2wrf}/WRFASSIM_${hh}${mm}.hdf000000 ]
        do
            echo "Waiting..."
            sleep 2m
            counter=$((${counter}+1))
            if [ ${counter} -ge 15 ]
            then
                echo "Possible ERROR with ADAS. Check output."
                exit
            fi
        done

        echo "Successful run of ADAS."
        # Remove all of the bin files that were produced
        rm ${WRFdir}/bin_2d_out*
        rm ${arps}/bin_2d_out*



        #################### ARPS4WRF ###################

        # Remove the old files
        rm ${arps4wrf}/met_em.d01.2013-05-20_${hh}:${mm}:00.nc
        rm ${arps4wrf}/met_em.d02.2013-05-20_${hh}:${mm}:00.nc

        # Now we're done with ADAS, time to convert back to WRF format
        ${arps}/run/input/arps4wrf_wrf_uav.sh
        sbatch ${arps}/a4w.sh
        echo "Submitted ARPS4WRF"

        # Need to make sure that ARPS4WRF ran correctly
        counter=0 # Resetting the counter
        while [ ! -e ${arps4wrf}/met_em.d01.2013-05-20_${hh}:${mm}:00.nc ]
        do
            echo "Waiting..."
            sleep 2m
            counter=$((${counter}+1))
            if [ ${counter} -ge 15 ]
            then
                echo "Possible ERROR with ARPS4WRF. Check output."
                exit
            fi
        done
        echo "Successful run of ARPS4WRF."


        

        #################### LBC Procedures ####################

        # Now we need to pass the LBCs through WRF2ARPS and ARPS4WRF so that they
        # Will have the same shape and undergo the same interpolation as the analysis files.

        # If the hour is less than 18 then we only need to process one LBC.
        # If the hour is 18 then we need to process all LBCs.
        if [ ${hh} = 18 ]
        then
            declare -a LBC=( 19 20 21 22 23 00 01 02 03 04 05 06 )
          
            echo "Passing LBC hour ${lbc} through."

            for lbc in ${LBC[@]}; do



            ################### REAL ####################


                export metgrid_levels=27
                export max_dom=1
                export starthour=${lbc}
                export endhour=$((${lbc}+1))
                export startday=20
                if [ ${lbc} -eq 23 ]
                then
                    export endday=21
                    export endhour=00
                elif [ ${lbc} -ge 00 ] && [ ${lbc} -le 06 ]
                then
                    export startday=21
                    export endday=21
                else
                    export endday=20
                fi

                # Link in new LBC met_em files
#                ln -sf ${GFSmetme}/met_em.d01.2013-05-${startday}_${lbc}:00:00.nc ${WRFdir}
#                ln -sf ${GFSmetem}/met_em.d01.2013-05-${endday}_${endhour}:00:00.nc ${WRFdir}

		ln -sf ${GFSmetem}/met* ${WRFdir}


                # Remove old files
                rm ${WRFdir}/wrfinput_d01

                ${WRFdir}/namelist_DA.sh
                #sbatch ${WRFdir}/real.sh
                echo "Submitted real.exe for lbc ${lbc}."
                ${WRFdir}/real.exe

                # Check to make sure that real.exe is finished running
                counter=0 # This will track how many times we have to wait
                while [ ! -e ${WRFdir}/wrfinput_d01 ]
                do
                    echo "Waiting..."
                    counter=$((${counter}+1))
                    sleep 2m
                    if [ ${counter} -ge 10 ]
                    then
                        echo "Possible error creating wrfinput. Check rsl.error file."
                        exit
                    fi

                done
                # Now copy this wrfinput file onto scratch and remove from /home to save space

                cp ${WRFdir}/wrfinput_d01 ${wrfout}/wrfout_d01_2013-05-${endday}_${lbc}:00:00
                rm ${WRFdir}/wrfinput_d01
                echo "Successful run of real.exe."


                ################### WRF2ARPS ####################

                # Now we're going to pass this wrf file through WRF2ARPS

                # But first remove old file if it's there.
                rm ${wrf2arps}/wrfassim_${lbc}.hdfgrdbas
                rm ${wrf2arps}/wrfassim_${lbc}.hdf000000

                export starthour=${lbc}

                ${arps}/run/input/wrf2arps_input.sh
                #sbatch ${arps}/wrf2arps.sh
                echo "Submitted WRF2ARPS for hour ${lbc}."

                ${arps}/bin/wrf2arps < ${arps}/run/input/wrf2arps.input > wrf2arps.out

                counter=0 # Resetting the counter.
                while [ ! -e ${wrf2arps}/wrfassim_${lbc}.hdfgrdbas ]
                do

                    echo "Waiting..."
                    counter=$((${counter}+1))
                    sleep 2m
                    if [ ${counter} -ge 15 ]
                    then
                        echo "WRF2ARPS Failure. Check output."
                        exit
                    fi
                done
                echo "Successful run of WRF2ARPS"



            ################### ARPS4WRF ####################

                # First remove old files
                rm ${arps4wrf}/met_em.d01.2013-05-${startday}_${lbc}:00:00.nc

                # Now we can pass this through ARPS4WRF
                ${arps}/run/input/arps4wrf_wrf_lbc.sh
                sbatch ${arps}/a4w.sh
                echo "Submitted ARPS4WRF"

                # Need to make sure that ARPS4WRF ran correctly
                counter=0 # Resetting the counter
                while [ ! -e ${arps4wrf}/met_em.d01.2013-05-${startday}_${lbc}:00:00.nc ]
                do
                    echo "Waiting..."
                    sleep 2m
                    counter=$((${counter}+1))
                    if [ ${counter} -ge 15 ]
                    then
                        echo "Possible ERROR with ARPS4WRF. Check output."
                        exit
                    fi
                done
                echo "Successful run of ARPS4WRF."
                done #Done with LBC loop when hh = 18

################################## More LBCs ########################################

        else # This handles everything when hh < 18
	        
            if [ ${mm} -eq 30 ] 
            then 
                export starthour=$((${hh}+1))
                export startmin=00
                export endhour=$((${hh}+1))
                export endmin=30
            else
                export starthour=${hh}
                export startmin=30
                export endhour=$((${hh}+1))
                export endmin=00
            fi
               

            ################### REAL ####################

            export metgrid_levels=27
            export max_dom=1
  
            # Link in new LBC met_em files
            ln -sf ${GFSmetem}/met_em.d01.2013-05-20_${starthour}:${startmin}:00.nc ${WRFdir}
            ln -sf ${GFSmetem}/met_em.d01.2013-05-20_${endhour}:${endmin}:00.nc ${WRFdir}

            # Remove old files
            rm ${WRFdir}/wrfinput_d01
            ${WRFdir}/namelist_DA_uav.sh
            #sbatch ${WRFdir}/real.sh
            echo "Submitted real.exe for lbc ${starthour}${startmin}."

            ${WRFdir}/real.exe

            # Check to make sure that real.exe is finished running
            counter=0 # This will track how many times we have to wait
            while [ ! -e ${WRFdir}/wrfinput_d01 ]
            do
                echo "Waiting..."
                counter=$((${counter}+1))
                sleep 2m
                if [ ${counter} -ge 10 ]
                then
                    echo "Possible error creating wrfinput. Check rsl.error file."
                    exit
                fi
            done
            # Now copy this wrfinput file onto scratch and remove from /home to save space

            cp ${WRFdir}/wrfinput_d01 ${wrfout}/wrfout_d01_2013-05-20_${starthour}:${startmin}:00
            rm ${WRFdir}/wrfinput_d01
            echo "Successful run of real.exe."


         ################### WRF2ARPS ####################

            # Now we're going to pass this wrf file through WRF2ARPS

            # But first remove old file if it's there.
            rm ${wrf2arps}/wrfassim_${starthour}${startmin}.hdfgrdbas
            rm ${wrf2arps}/wrfassim_${starthour}${startmin}.hdf000000

            export startday=20

            ${arps}/run/input/wrf2arps_input_uav.sh
            #sbatch ${arps}/wrf2arps.sh
            echo "Submitted WRF2ARPS for time ${starthour}${startmin}."

            ${arps}/bin/wrf2arps < ${arps}/run/input/wrf2arps.input > wrf2arps.out

            counter=0 # Resetting the counter.
            while [ ! -e ${wrf2arps}/wrfassim_${starthour}${startmin}.hdfgrdbas ]
            do

                echo "Waiting..."
                counter=$((${counter}+1))
                sleep 2m
                if [ ${counter} -ge 15 ]
                then
                    echo "WRF2ARPS Failure. Check output."
                    exit
                fi
            done
            echo "Successful run of WRF2ARPS"


            ################### ARPS4WRF ####################

            # First remove old files
            rm ${arps4wrf}/met_em.d01.2013-05-20_${starthour}:${startmin}:00.nc

            # Now we can pass this through ARPS4WRF
            ${arps}/run/input/arps4wrf_wrf_lbc_uav.sh
            sbatch ${arps}/a4w.sh
            echo "Submitted ARPS4WRF"

            # Need to make sure that ARPS4WRF ran correctly
            counter=0 # Resetting the counter
            while [ ! -e ${arps4wrf}/met_em.d01.2013-05-20_${starthour}:${startmin}:00.nc ]
            do
                echo "Waiting..."
                sleep 2m
                counter=$((${counter}+1))
                if [ ${counter} -ge 15 ]
                then
                    echo "Possible ERROR with ARPS4WRF. Check output."
                    exit
                fi
            done
            echo "Successful run of ARPS4WRF."
                
        fi #Done with LBC loops
        echo "Done with passing through LBCs."






################################### WRF Forecast #########################################################
        # Only do a WRF half hour forecast iff hour != 18

        if [ ${hh} -lt 18 ]
        then
        ################### WRF Forecast ####################

            # Now we can launch an hour forecast
            # First need to remove old met_em files and replace with the
            # met_em files from ARPS
            rm ${WRFdir}/wrfinput_d01
            rm ${WRFdir}/wrfinput_d02
            rm ${WRFdir}/met_em*
            ln -sf ${arps4wrf}/met_em* ${WRFdir}

            # Setting forecast variables
            export starthour=${hh}

            export startmin=${mm}
            if [ ${mm} -eq 00 ]
            then 
                export endhour=${hh}
                export endmin=30
            else
                export endhour=$((${hh}+1))
                export endmin=00
            fi

            export startday=20
            export endday=20
            export metgrid_levels=48
            export max_dom=2


            echo "Performing Real for hour forecast."
            ${WRFdir}/namelist_DA_uav.sh
            sbatch ${WRFdir}/realpara.sh

            # Check for Real output
            counter=0
            while [ ! -e ${WRFdir}/wrfinput_d01 ]
            do
                echo "waiting..."
                sleep 2m
                counter=$((${counter}+1))
                if [ ${counter} -ge 12 ]
                then
                    echo "real.exe Failure. May have timed out."
                    exit
                fi
            done
            echo "Real success. Submitting WRF hour forecast."

            # But first remove old wrfout files
            rm ${WRFdir}/wrfout*

            sbatch ${WRFdir}/wrfp.sh
            # Check for WRF output
            counter=0
            while [ ! -e ${WRFdir}/wrfout_d01_2013-05-20_${endhour}:${endmin}:00 ]
            do
                echo "waiting..."
                sleep 10m
                counter=$((${counter}+1))
                if [ ${counter} -gt 12 ]
                then
                    echo "Possible ERROR with WRF. May have timed out.."
                    exit
                fi
            done
            echo "Successful completion of WRF hour forecast."
            ###################################################
        fi # End with the WRF forecast portion





    done # With minute loop
done # With hour loop

echo "!!!! Success !!!!"

