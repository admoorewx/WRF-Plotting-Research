#!/bin/sh
### General Variables ###


### Begin WRF DA Cycling at this hour: ###
hh=12 ####################################
##########################################

DA=true
FirstCycle=true
arps=/scratch/admoore/arps5.4.23

##########################################

# Begin by removing any met_em files from the WRF run directory
# This step only has to be done for the first DA cycle. 
# After this we'll use the output from the hourly WRF forecast.

find /scratch/admoore/WRFrun -name 'met_em*' -exec rm {} \;
rm /scratch/admoore/WRFrun/wrfinput_d01
echo "Removed met_em and wrfinput files."

# Replace these with the saved met_em files from scratch

ln -sf /scratch/admoore/05202013_gfs_metgrid/met_em* /scratch/admoore/WRFrun

# Check to make sure that the files were correctly linked

if [ -e "/scratch/admoore/WRFrun/met_em.d01.2013-05-20_12:00:00.nc" ] 
then
    echo "Met_em files were successfully linked."
else
    echo "Failure: met_em files not linked!"
    exit
fi 

while [ "$DA" = true ] 
do
    if [ ${hh} -lt 19 ]
    then
        echo "Processing time: ${hh}"
        echo "Performing D.A. procedures."
        


        # Need to create the input file for wrf2arps
        # This will be done by running real.exe to create an wrfinput file
     

        if [ "$FirstCycle" = true ] 
        then
            echo "This is the first DA cycle."
            export starthour=${hh}
            export endhour=$((${hh}+1))
            export startday=20
            export endday=20
            export metgrid_levels=27
            export max_dom=1
            /scratch/admoore/WRFrun/namelist_DA.sh
            sbatch /scratch/admoore/WRFrun/real.sh
            echo "Submitted real.exe for hour ${hh}."
            # Check to make sure that real.exe is finished running
            counter=0 # This will track how many times we have to wait
            while [ ! -e '/scratch/admoore/WRFrun/wrfinput_d01' ] 
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
            
            cp /scratch/admoore/WRFrun/wrfinput_d01 /scratch/admoore/wrfout/wrfout_d01_2013-05-20_${hh}:00:00
            #rm /home/admoore/WRF/run/wrfinput_d01
            echo "Successful run of real.exe."
        
        else
            echo ""
            echo "This is NOT the first DA cycle. Taking previous WRF output as background."
            # Just take the WRF output from the hour forecast and copy that over for WRF2ARPS
            cp /scratch/admoore/WRFrun/wrfout_d01_2013-05-20_${hh}:00:00 /scratch/admoore/wrfout/wrfout_d01_2013-05-20_${hh}:00:00
            # Remove old output files
            rm /scratch/admoore/WRFrun/wrfout*


        fi 




        # Now we can submit the WRF2ARPS program to run
        # But first remove old files if they're there.
        rm /scratch/admoore/wrf2arps/wrfassim_${hh}.hdfgrdbas
        rm /scratch/admoore/wrf2arps/wrfassim_${hh}.hdf000000


        ################### WRF2ARPS ####################
        export starthour=${hh}
        export startday=20       
        ${arps}/run/input/wrf2arps_input.sh
        sbatch ${arps}/wrf2arps.sh
        echo "Submitted WRF2ARPS."

        counter=0 # Resetting the counter.
        while [ ! -e /scratch/admoore/wrf2arps/wrfassim_${hh}.hdfgrdbas ]
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
        rm /scratch/admoore/arps2wrf/WRFASSIM_${hh}.hdf000000
        rm /scratch/admoore/arps2wrf/WRFASSIM_${hh}.hdfgrdbas

        # Once WRF2ASRPS is done we can send it through ADAS
        # Need to export the previous hour to get data
        export previoushour=$(($hh-1)) 

        # if this is 12z then we can only use the GFS and UAV soundings
        if [ ${hh} -eq 12 ] 
        then 
            export mesoNum=0
        else
            export mesoNum=0 
            #export mesoNum=1 to use mesonet data
            #echo "Using Mesonet Data."
        fi 


        ${arps}/run/input/adas_wrf.sh
        sbatch ${arps}/adas_serial.sh
        echo "Submitted ADAS"
        # Need to check to make sure ADAS ran correctly
        counter=0 # Resetting the counter
        while [ ! -e /scratch/admoore/arps2wrf/WRFASSIM_${hh}.hdf000000 ] 
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
        rm /scratch/admoore/arps5.4.23/bin_2d_out*
        rm ${arps}/bin_2d_out*



        #################### ARPS4WRF ###################

        # Remove the old files 
        rm ${arps}/arps4wrf/wrf/met_em.d01.2013-05-20_${hh}:00:00.nc
        rm ${arps}/arps4wrf/wrf/met_em.d02.2013-05-20_${hh}:00:00.nc

        # Now we're done with ADAS, time to convert back to WRF format
        ${arps}/run/input/arps4wrf_wrf.sh
        sbatch ${arps}/a4w.sh
        echo "Submitted ARPS4WRF"   
     
        # Need to make sure that ARPS4WRF ran correctly
        counter=0 # Resetting the counter
        while [ ! -e ${arps}/arps4wrf/wrf/met_em.d01.2013-05-20_${hh}:00:00.nc ] 
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
        else 
            declare -a LBC=( $((${hh}+1)) ) 
        fi
        # If the time is greater than the analysis time pass it through
        for lbc in ${LBC[@]}; do 
 
            echo "Passing LBC hour ${lbc} through."
                
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

            # Link in new LBC met_em files if it is not the first cycle
            if [ "$FirstCycle" = false ] 
            then 
                echo "First cycle is false."
                # Removing old met_em files so they don't get mixed up with finding the LBCs.
                #rm /scratch/admoore/WRFrun/met*

                
                ln -sf /scratch/admoore/05202013_gfs_metgrid/met_em.d01.2013-05-${startday}_${lbc}:00:00.nc /scratch/admoore/WRFrun/
                ln -sf /scratch/admoore/05202013_gfs_metgrid/met_em.d01.2013-05-${endday}_${endhour}:00:00.nc /scratch/admoore/WRFrun/
            fi


            # Remove old files
            rm /scratch/admoore/WRFrun/wrfinput_d01

            /scratch/admoore/WRFrun/namelist_DA.sh
            sbatch /scratch/admoore/WRFrun/real.sh
            echo "Submitted real.exe for lbc ${lbc}."

            # Check to make sure that real.exe is finished running
            counter=0 # This will track how many times we have to wait
            while [ ! -e /scratch/admoore/WRFrun/wrfinput_d01 ]
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
            
            cp /scratch/admoore/WRFrun/wrfinput_d01 /scratch/admoore/wrfout/wrfout_d01_2013-05-${endday}_${lbc}:00:00
            rm /scratch/admoore/WRFrun/wrfinput_d01
            echo "Successful run of real.exe."
               
             
            ################### WRF2ARPS ####################

            # Now we're going to pass this wrf file through WRF2ARPS
             
            # But first remove old file if it's there.
            rm /scratch/admoore/wrf2arps/wrfassim_${lbc}.hdfgrdbas
            rm /scratch/admoore/wrf2arps/wrfassim_${lbc}.hdf000000

            export starthour=${lbc}

            ${arps}/run/input/wrf2arps_input.sh
            sbatch ${arps}/wrf2arps.sh
            echo "Submitted WRF2ARPS for hour ${hh}."

            counter=0 # Resetting the counter.
            while [ ! -e /scratch/admoore/wrf2arps/wrfassim_${lbc}.hdfgrdbas ]
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
            rm ${arps}/arps4wrf/wrf/met_em.d01.2013-05-${startday}_${lbc}:00:00.nc

            # Now we can pass this through ARPS4WRF            
            ${arps}/run/input/arps4wrf_wrf_lbc.sh
            sbatch ${arps}/a4w.sh
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

        
        done ####### Done with passing through LBCs  #######
        echo "Done with passing through LBCs."
	# Only do a WRF one hour forecast iff hour != 19
        
	if [ ${hh} -lt 18 ] 
        then 
        ################### WRF Forecast ####################

            # Now we can launch an hour forecast
            # First need to remove old met_em files and replace with the
            # met_em files from ARPS
            rm /scratch/admoore/WRFrun/wrfinput_d01
            rm /scratch/admoore/WRFrun/wrfinput_d02
            rm /scratch/admoore/WRFrun/met_em*
            ln -sf ${arps}/arps4wrf/wrf/met_em* /scratch/admoore/WRFrun

            # Setting forecast variables
            export starthour=${hh}
            export endhour=$((${hh}+1))
            export startday=20
            export endday=20
            export metgrid_levels=48
            export max_dom=2

            # Need to remove old files
            rm /scratch/admoore/WRFrun/wrfinput_d01

            echo "Performing Real for hour forecast."
            /scratch/admoore/WRFrun/namelist_DA.sh
            sbatch /scratch/admoore/WRFrun/realpara.sh
 
            # Check for Real output
            counter=0
            while [ ! -e /scratch/admoore/WRFrun/wrfinput_d01 ] 
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
            rm /scratch/admoore/WRFrun/wrfout*
          
            sbatch /scratch/admoore/WRFrun/wrfpara.sh
            # Check for WRF output
            counter=0
            while [ ! -e /scratch/admoore/WRFrun/wrfout_d01_2013-05-20_${endhour}:00:00 ] 
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
	fi 
    else # IF hh > 19 
        DA=false


    fi # END OF "IF DA=TRUE"
    hh=$((${hh}+1))
    FirstCycle=false


done #### Done with Doing DA ###
echo "!!!!! SUCCESS !!!!"
echo "WRF Cycling Complete."
echo "Ready to launch forecast."

# If we're doing free forecast then launch the free forecast
# If we're doing free forecast then output WRF data every five or ten minutes
# Once the free forecast is complete copy the output to scratch and clean the run directory
# Celebrate that we're done




