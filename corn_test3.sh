#!/bin/sh

#################################################################################
# Times you want to process
declare -a hours=( 12 13 14 15 16 17 )
declare -a minutes=( 00 ) 

# Beginning time of DA
DAstartHour=12
DAstartMin=00
# Ending time of DA
DAendHour=17
DAendMin=30
# GFS FNL assimilation frequency (hours)
# set to 999 to turn off GFS FNL assimilation
GFSassimFreq=3

# UAV assimilation frequency (minutes) 
UAVassimFreq=60

# Mesonet assimilation frequency (hours)
# Set to 999 to turn off.
MESOassimFreq=1

#Arps directory
arps=/scratch/admoore/arps5.4.23

#WRF directory
WRFdir=/scratch/admoore/WRFrun

# WRF background directory
WRFback=/scratch/admoore/Control_Long_Alt_3hr

# WRF2ARPS directory
wrf2arps=/scratch/admoore/wrf2arps

# ARPS2WRF directory
arps2wrf=/scratch/admoore/arps2wrf

# ARPS4WRF directory
arps4wrf=${arps}/arps4wrf/wrf

# WRFOUT directory
wrfout=/scratch/admoore/wrfout

# GFS met_em files directory
GFSmetem=/scratch/admoore/gfs_metem_051500_halfhourly/alternate_domain


#################################################################################

# Start by deleting old met_em, wrfinput, wrfout files from directory

cd ${WRFdir}
echo "${WRFdir}"

rm met_em* 2> /dev/null
rm wrfinput* 2> /dev/null
rm wrfout* 2> /dev/null
rm rsl* 2> /dev/null

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



	if [ ${hh} -eq ${DAendHour} ] && [ ${mm} -eq ${DAendMin} ] 
	then
            echo "Cleaning up files:"
            rm ${wrf2arps}/wrfassim*
            rm ${arps2wrf}/WRFASSIM*
            rm ${WRFdir}/rsl*
            rm ${WRFdir}/bin*

            echo "!!!!!!!!!!!!!!!!!"
            echo "!!!! Success !!!!"
            echo "!!!!!!!!!!!!!!!!!"

            exit
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
        


        if [ ${hh} -eq ${DAstartHour} ] && [ ${mm} -eq ${DAstartMin} ]
        then
            echo "This is the first DA cycle."
            # Taking the WRF Control file as the initial background field
            cp ${WRFback}/wrfout_d01_2013-05-20_${DAstartHour}:${DAstartMin}:00 ${wrfout}


        else
            echo ""
            echo "This is NOT the first DA cycle. Taking previous WRF output as background."
            # Just take the WRF output from the forecast and copy that over for WRF2ARPS
            cp ${WRFdir}/wrfout_d01_2013-05-20_${hh}:${mm}:00 ${wrfout}/wrfout_d01_2013-05-20_${hh}:${mm}:00
            cp ${WRFdir}/wrfout_d01_2013-05-20_${hh}:${mm}:00 ${wrfout}/wrfout_d01_2013-05-20_${hh}:${mm}:00_FFF
            # Remove old output files
            rm ${WRFdir}/wrfout*


        fi

        # Now we can submit the WRF2ARPS program to run
        # But first remove old files if they're there.
        rm /scratch/admoore/wrf2arps/wrfassim_${hh}${mm}.hdfgrdbas 2> /dev/null
        rm /scratch/admoore/wrf2arps/wrfassim_${hh}${mm}.hdf000000 2> /dev/null


        ################### WRF2ARPS ####################

        echo ""
        echo "Performing WRF2ARPS"
        echo ""

        export starthour=${hh}
        export startmin=${mm}
        export startday=20
        ${arps}/run/input/wrf2arps_input_uav.sh
        #sbatch ${arps}/wrf2arps.sh
        ${arps}/bin/wrf2arps < ${arps}/run/input/wrf2arps.input > wrf2arps.out

        # In this implementation the counter should really not even be 
        # needed, however, I'm leaving this in case WRF2ARPS needs to 
        # be run through the queue again in the future. 

        counter=0 # Resetting the counter.
        while [ ! -e /scratch/admoore/wrf2arps/wrfassim_${hh}${mm}.hdfgrdbas ]
        do
            echo "Waiting..."
            counter=$((${counter}+1))
            sleep 2m
            if [ ${counter} -ge 1 ]
            then
                echo "WRF2ARPS Failure. Check output."
                exit
            fi
        done
        echo "Successful run of WRF2ARPS"


        ################### ADAS ####################

        echo ""
        echo "Performing ADAS."
        echo ""

        # First need to remove old files
        rm /scratch/admoore/arps2wrf/WRFASSIM_${hh}${mm}.hdf000000 2> /dev/null
        rm /scratch/admoore/arps2wrf/WRFASSIM_${hh}${mm}.hdfgrdbas 2> /dev/null

        # Once WRF2ARPS is done we can send it through ADAS
        # Need to export the previous hour to get data
        export previoushour=$(($hh-1))

       
        # Logic for assimilating Surface data
        if [ $(( ${hh} % MESOassimFreq )) -eq 0 ] && [ ${mm} -eq 00 ]
	then 
            if [ ${hh} -eq 12 ] # Can't use Mesonet at 12z
            then 
                export mesoNum=0
                echo "NOT using Mesonet Data."
            else
                export mesoNum=1
                echo "Assimilating Mesonet Data."
            fi 
        else 
            export mesoNum=0
            echo "Not using Mesonet Data."
        fi

        
        # Logic for assimilating upper air data
        # Outer if
        if [ ${UAVassimFreq} -le 60 ]
        then 
 
            # Inner If #1
            if [ $(( ${hh} % ${GFSassimFreq} )) -eq 0 ] && [ ${mm} -eq 00 ]
            then 
                
                export uaNum=2
                echo "Assimilating both GFS FNL and UAV data."  

            else
                export uaNum=1
                echo "Assimilating UAV data."

            fi # End outer if #1

        # This else if takes into account instances when we're assimilating UAV 
        # Data at intervals greater than one hour.
        # Need to get hourly assim freq. 
        UAVassimFreqHour=$((${UAVassimFreq}/60))
        elif [ $(( ${hh} % ${UAVassimFreqHour} )) -eq 0 ] && [ ${mm} -eq 00 ]
        then 

            # Inner if #2
            if [ $(( ${hh} % ${GFSassimFreq} )) -eq 0 ] && [ ${mm} -eq 00 ]
            then

                export uaNum=2
                echo "Assimilating both GFS FNL and UAV data."

            else
                export uaNum=1
                echo "Assimilating UAV data."

            fi # End inner if #2
        
        else
            export uaNum=0
            echo "       !!!Warning!!!"
            echo "Not using GFS FNL or UAV data!"
            echo "    Was this intentional?"

        fi # End outer if

        #cd ${arps}
        ${arps}/run/input/adas_wrf_uav.sh
	sbatch ${arps}/adas_para.sh
        #sbatch ${arps}/3dvar_serial.sh
        #echo "Submitted 3DVAR....This may take a while..."
        
        #cd ${arps}
	#bin/arps3dvar < run/input/adas_wrf.input > 3dvar.out
        #bin/adas < run/input/adas_wrf.input > adas.out
        #cd ${WRFdir}

        # Need to check to make sure ADAS ran correctly
        counter=0 # Resetting the counter
        while [ ! -e /scratch/admoore/arps2wrf/WRFASSIM_${hh}${mm}.hdf000000 ]
        do
            echo "Waiting..." 
            sleep 3m  
            echo "Waited for $(( $((${counter}+1)) * 5 )) minutes"
           
            counter=$((${counter}+1))
            if [ ${counter} -ge 12 ]
            then
                echo "Possible ERROR with ADAS. Likely timed out."
                exit
            fi
        done

        echo "Successful run of ADAS."
        # Remove all of the bin files that were produced
        rm ${WRFdir}/bin_2d_out* 2> /dev/null
        #rm ${arps}/bin_2d_out*



        #################### ARPS4WRF ###################

        echo ""
        echo "Performing ARPS4WRF."
        echo ""


        # Remove the old files
        rm ${arps}/arps4wrf/wrf/met_em.d01.2013-05-20_${hh}:${mm}:00.nc 2> /dev/null
        rm ${arps}/arps4wrf/wrf/met_em.d02.2013-05-20_${hh}:${mm}:00.nc 2> /dev/null

        # Now we're done with ADAS, time to convert back to WRF format
        ${arps}/run/input/arps4wrf_wrf_uav.sh
        cd ${arps}
        #sbatch ${arps}/a4w.sh
        bin/arps4wrf < run/input/arps4wrf_wrf.input > arps4wrf.out
        cd ${WRFdir}        


        # Need to make sure that ARPS4WRF ran correctly
        counter=0 # Resetting the counter
        while [ ! -e ${arps}/arps4wrf/wrf/met_em.d01.2013-05-20_${hh}:${mm}:00.nc ]
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

        # If the hour is less than 17 then we only need to process one LBC.
        # If the hour is 17 then we need to process all LBCs.
        if [ ${hh} = 17 ]
        then
            declare -a LBC=( 20 23 02 05 )
          
            echo "Passing LBC hour ${lbc} through."

            for lbc in ${LBC[@]}; do



            ################### REAL ####################


                echo ""
                echo "Performing real.exe for lbc ${lbc}."
                echo ""


                export metgrid_levels=27
                export max_dom=1
                export starthour=${lbc}
                export endhour=$((${lbc}+3))
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
                #ln -sf /scratch/admoore/05202013_gfs_metgrid/met_em.d01.2013-05-${startday}_${lbc}:00:00.nc ${WRFdir}
                #ln -sf /scratch/admoore/05202013_gfs_metgrid/met_em.d01.2013-05-${endday}_${endhour}:00:00.nc ${WRFdir}

                ln -sf ${GFSmetem}/met* ${WRFdir}

                # Remove old files
                rm ${WRFdir}/wrfinput_d01 2> /dev/null

                ${WRFdir}/namelist_DA.sh
                #sbatch ${WRFdir}/real.sh
                
                ${WRFdir}/real.exe

                # In this implementation the counter should really not even be
                # needed, however, I'm leaving this in case real.exe needs to
                # be run through the queue again in the future.

                # Check to make sure that real.exe is finished running
                counter=0 # This will track how many times we have to wait
                while [ ! -e ${WRFdir}/wrfinput_d01 ]
                do
                    echo "Waiting..."
                    counter=$((${counter}+1))
                    sleep 1m
                    if [ ${counter} -ge 1 ]
                    then
                        echo "Possible error creating wrfinput. Check rsl.error file."
                        exit
                    fi

                done
                # Now copy this wrfinput file onto scratch and remove from /home to save space

                cp ${WRFdir}/wrfinput_d01 ${wrfout}/wrfout_d01_2013-05-${startday}_${lbc}:00:00
                rm ${WRFdir}/wrfinput_d01 2> /dev/null
                echo "Successful run of real.exe."


                ################### WRF2ARPS ####################


                echo ""
                echo "Performing WRF2ARPS for LBC ${lbc}."
                echo ""

                # Now we're going to pass this wrf file through WRF2ARPS

                # But first remove old file if it's there.
                rm /scratch/admoore/wrf2arps/wrfassim_${lbc}.hdfgrdbas 2> /dev/null
                rm /scratch/admoore/wrf2arps/wrfassim_${lbc}.hdf000000 2> /dev/null

                export starthour=${lbc}

                ${arps}/run/input/wrf2arps_input.sh
                #sbatch ${arps}/wrf2arps.sh
                
                ${arps}/bin/wrf2arps < ${arps}/run/input/wrf2arps.input > wrf2arps.out

                # In this implementation the counter should really not even be
                # needed, however, I'm leaving this in case WRF2ARPS needs to
                # be run through the queue again in the future.


                counter=0 # Resetting the counter.
                while [ ! -e /scratch/admoore/wrf2arps/wrfassim_${lbc}.hdfgrdbas ]
                do

                    echo "Waiting..."
                    counter=$((${counter}+1))
                    sleep 1m
                    if [ ${counter} -ge 1 ]
                    then
                        echo "WRF2ARPS Failure. Check output."
                        exit
                    fi
                done
                echo "Successful run of WRF2ARPS"



            ################### ARPS4WRF ####################

                echo ""
                echo "Performing ARPS4WRF for LBC ${lbc}."
	        echo ""


                # First remove old files
                rm ${arps}/arps4wrf/wrf/met_em.d01.2013-05-${startday}_${lbc}:00:00.nc 2> /dev/null

                # Now we can pass this through ARPS4WRF
                ${arps}/run/input/arps4wrf_wrf_lbc.sh
                #sbatch ${arps}/a4w.sh

                cd ${arps}
        
                bin/arps4wrf < run/input/arps4wrf_wrf.input > arps4wrf.out
                cd ${WRFdir}


                echo "Submitted ARPS4WRF"

                # Need to make sure that ARPS4WRF ran correctly
                counter=0 # Resetting the counter
                while [ ! -e ${arps}/arps4wrf/wrf/met_em.d01.2013-05-${startday}_${lbc}:00:00.nc ]
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

                # Need to remove that fake wrfout file in wrfout directory
                rm ${wrfout}/wrfout_d01_2013-05-${startday}_${lbc}:00:00

            done #Done with LBC loop when hh = 17

################################## More LBCs ########################################

        else # This handles everything when hh < 17
	# NOTE: Currently the following section is set up to perform hourly DA
        # You will need to make appropriate adjustments to change it back to half hourly!        
            if [ ${mm} -eq 30 ] 
            then 
                export starthour=$((${hh}+1))
                export startmin=00
                export endhour=$((${hh}+1))
                export endmin=30
            else
                export starthour=$((${hh}+1))
                export startmin=00
                export endhour=$((${hh}+2))
                export endmin=00
            fi
               

            ################### REAL ####################


            echo ""
            echo "Performing real.exe for LBC ${starthour}:${startmin}."
            echo "" 


            export startday=20
            export endday=20
            export metgrid_levels=27
            export max_dom=1
  
            # Link in new LBC met_em files
            ln -sf ${GFSmetem}/met_em.d01.2013-05-20_${starthour}:${startmin}:00.nc ${WRFdir}
            ln -sf ${GFSmetem}/met_em.d01.2013-05-20_${endhour}:${endmin}:00.nc ${WRFdir}

            # Remove old files
            rm ${WRFdir}/wrfinput_d01 2> /dev/null
            ${WRFdir}/namelist_DA_uav.sh
            #sbatch ${WRFdir}/real.sh

            ${WRFdir}/real.exe

            # Check to make sure that real.exe is finished running
            counter=0 # This will track how many times we have to wait
            while [ ! -e ${WRFdir}/wrfinput_d01 ]
            do
                echo "Waiting..."
                counter=$((${counter}+1))
                sleep 1m
                if [ ${counter} -ge 1 ]
                then
                    echo "Possible error creating wrfinput. Check rsl.error file."
                    exit
                fi
            done
            # Now copy this wrfinput file onto scratch and remove from /home to save space

            cp ${WRFdir}/wrfinput_d01 ${wrfout}/wrfout_d01_2013-05-20_${starthour}:${startmin}:00
            rm ${WRFdir}/wrfinput_d01 2> /dev/null
            echo "Successful run of real.exe."


         ################### WRF2ARPS ####################

            echo ""
            echo "Performing WRF2ARPS for LBC ${starthour}:${startmin}."
            echo ""


            # Now we're going to pass this wrf file through WRF2ARPS

            # But first remove old file if it's there.
            rm /scratch/admoore/wrf2arps/wrfassim_${starthour}${startmin}.hdfgrdbas 2> /dev/null
            rm /scratch/admoore/wrf2arps/wrfassim_${starthour}${startmin}.hdf000000 2> /dev/null

            export startday=20

            ${arps}/run/input/wrf2arps_input_uav.sh
            #sbatch ${arps}/wrf2arps.sh
            echo "Submitted WRF2ARPS for time ${starthour}${startmin}."

            ${arps}/bin/wrf2arps < ${arps}/run/input/wrf2arps.input > wrf2arps.out

            counter=0 # Resetting the counter.
            while [ ! -e /scratch/admoore/wrf2arps/wrfassim_${starthour}${startmin}.hdfgrdbas ]
            do

                echo "Waiting..."
                counter=$((${counter}+1))
                sleep 30s
                if [ ${counter} -ge 1 ]
                then
                    echo "WRF2ARPS Failure. Check output."
                    exit
                fi
            done
            echo "Successful run of WRF2ARPS"


            ################### ARPS4WRF ####################

            echo ""
            echo "Performing ARPS4WRF for LBC ${starthour}:${startmin}."
            echo ""


            # First remove old files
            rm ${arps4wrf}/met_em.d01.2013-05-20_${starthour}:${startmin}:00.nc 2> /dev/null

            # Now we can pass this through ARPS4WRF
            ${arps}/run/input/arps4wrf_wrf_lbc_uav.sh
            #sbatch ${arps}/a4w.sh
            echo "Submitted ARPS4WRF"


            cd ${arps}
        
            bin/arps4wrf < run/input/arps4wrf_wrf.input > arps4wrf.out
            cd ${WRFdir}



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
            
            # Need to clean out that fake wrfout file
            rm ${wrfout}/wrfout_d01_2013-05-20_${starthour}:${startmin}:00

    
        fi #Done with LBC loops
        echo "Done with passing through LBCs."






################################### WRF Forecast #########################################################
        # Only do a WRF half hour forecast iff hour != 17

        if [ ${hh} -lt 17 ]
        then
        ################### WRF Forecast ####################

            # Now we can launch an hour forecast
            # First need to remove old met_em files and replace with the
            # met_em files from ARPS
            rm ${WRFdir}/wrfinput_d01 2> /dev/null
            rm ${WRFdir}/wrfinput_d02 2> /dev/null
            rm ${WRFdir}/met_em* 2> /dev/null
            ln -sf ${arps4wrf}/met_em* ${WRFdir}

            # Setting forecast variables
            export starthour=${hh}

            export startmin=${mm}
            if [ ${mm} -eq 00 ]
            then 
                export endhour=$((${hh}+1))
                export endmin=00
            else
                export endhour=$((${hh}+1))
                export endmin=00
            fi

            export startday=20
            export endday=20
            export metgrid_levels=47
            export max_dom=2


            echo "Performing Real for hour forecast."
            ${WRFdir}/namelist_DA_uav.sh
            #sbatch ${WRFdir}/realpara.sh

            ${WRFdir}/real.exe

            # Check for Real output
            counter=0
            while [ ! -e ${WRFdir}/wrfinput_d01 ]
            do
                echo "waiting..."
                sleep 2m
                counter=$((${counter}+1))
                if [ ${counter} -ge 1 ]
                then
                    echo "real.exe Failure. May have timed out."
                    exit
                fi
            done
            echo "Real success. Submitting WRF hour forecast."

            # But first remove old wrfout files
            rm ${WRFdir}/wrfout* 2> /dev/null

            sbatch ${WRFdir}/wrfp.sh
            # Check for WRF output
            counter=0
            while [ ! -e ${WRFdir}/wrfout_d01_2013-05-20_${endhour}:${endmin}:00 ]
            do
                echo "waiting..."
                sleep 3m
                counter=$((${counter}+1))
                if [ ${counter} -gt 12 ]
                then
                    echo "Possible ERROR with WRF. May have timed out.."
                    exit
                fi
            done
            cp ${WRFdir}/wrfout_d01_2013-05-20_${starthour}:${startmin}:00 ${wrfout}/wrfout_d01_2013-05-20_${starthour}:${startmin}:00_AAA
            echo "Successful completion of WRF hour forecast."
            ###################################################
        fi # End with the WRF forecast portion





    done # With minute loop
done # With hour loop

echo "Cleaning up files:"
rm ${wrf2arps}/wrfassim* 2> /dev/null
rm ${arps2wrf}/WRFASSIM* 2> /dev/null
rm ${WRFdir}/rsl* 2> /dev/null
rm ${WRFdir}/bin* 2> /dev/null

echo "!!!!!!!!!!!!!!!!!"
echo "!!!! Success !!!!"
echo "!!!!!!!!!!!!!!!!!"
