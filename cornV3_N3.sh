#!/bin/sh

#################################################################
# Times you want to perform Data Assimilation
declare -a hours=( 12 13 14 15 16 17 18 )

# Beginning time of DA
DAstart=12

# Ending time of DA
DAend=18

# GFS FNL assimilation frequency (hours)
# set to 999 to turn of GFS FNL assimilation
GFSassimFreq=3

#Arps directory
arps=/scratch/admoore/arps5.4.23

#WRF directory
WRFdir=/scratch/admoore/WRFrun3

# WRF background directory
WRFback=/scratch/admoore/WRFrun/Control_Long_Alt_3hr

# WRF2ARPS directory
wrf2arps=/scratch/admoore/wrf2arps3

# ARPS2WRF directory
arps2wrf=/scratch/admoore/arps2wrf3

# ARPS4WRF directory
arps4wrf=${arps}/arps4wrf/wrf3

# WRFOUT directory
wrfout=/scratch/admoore/wrfout3

# GFS met_em files directory
GFSmetem=/scratch/admoore/gfs_metem_051500_halfhourly/alternate_domain



#################################################################


####################### Beginning D.A. Procedure #################



# Start by deleting old met_em, wrfinput, wrfout files from directory

cd ${WRFdir}
echo "${WRFdir}"

rm met_em* 2> /dev/null
rm wrfinput* 2> /dev/null
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

    export starthour="$hh" 
    export startday=20
      
    echo ""  
    echo "Processing time ${startday} - ${starthour}:00"
    echo ""

   
    if [ ${hh} -eq ${DAstart} ]
    then
        echo "This is the first DA cycle."
        export starthour=12
        export endhour=13
        export startday=20
        export endday=20

        # Copy over the background WRF output file from the WRFback directory 
        # into the wrfout directory

        cp ${WRFback}/wrfout_d01_2013-05-20_${hh}:00:00 ${wrfout}



    else
        echo ""
        echo "This is NOT the first DA cycle. Taking previous WRF output as background."
        # Just take the WRF output from the forecast and copy that over for WRF2ARPS
        cp ${WRFdir}/wrfout_d01_2013-05-20_${hh}:00:00 ${wrfout}/wrfout_d01_2013-05-20_${hh}:00:00
        cp ${WRFdir}/wrfout_d01_2013-05-20_${hh}:00:00 ${wrfout}/wrfout_d01_2013-05-20_${hh}:00:00_FFF
        # Remove old output files
        rm ${WRFdir}/wrfout* 2> /dev/null


    fi

    # Now we can submit the WRF2ARPS program to run
    # But first remove old files if they're there.
    rm ${wrf2arps}/wrfassim_${hh}.hdfgrdbas 2> /dev/null
    rm ${wrf2arps}/wrfassim_${hh}.hdf000000 2> /dev/null


    ################### WRF2ARPS ####################
    echo ""
    echo "Performing WRF2ARPS"
    echo ""


    export starthour=${hh}
    export startday=20
    ${arps}/run/input/wrf2arps_input3.sh
    ${arps}/bin/wrf2arps < ${arps}/run/input/wrf2arps3.input > wrf2arps3.out
    #sbatch ${arps}/wrf2arps.sh
    
    # In this implementation the counter should really not even be 
    # needed, however, I'm leaving this in case WRF2ARPS needs to 
    # be run through the queue again in the future. 

    counter=0 # Resetting the counter.
    while [ ! -e ${wrf2arps}/wrfassim_${hh}.hdfgrdbas ]
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

    ################### ADAS ####################

    echo ""
    echo "Performing ADAS."
    echo ""

    # First need to remove old files
    rm ${arps2wrf}/WRFASSIM_${hh}.hdf000000 2> /dev/null
    rm ${arps2wrf}/WRFASSIM_${hh}.hdfgrdbas 2> /dev/null

    # Once WRF2ASRPS is done we can send it through ADAS
    # Need to export the previous hour to get data
    export previoushour=$(($hh-1))

    # if this is 12z then we can only use the GFS and UAV soundings
    if [ ${hh} -eq 12 ]
    then
        export mesoNum=0
        echo ""
        echo "NOT using Mesonet Data."
        echo ""
    else
        export mesoNum=1 to use mesonet data
        echo ""
        echo "Assimilating Mesonet Data."
        echo ""
    fi

    # Export uaNum = 1 in order to just use the GFS data
    # Use the GFS FNL data based on assim frequency.
   
    if [ $(( ${hh} % GFSassimFreq )) -eq 0 ]
    then
        echo "Assimilating GFS FNL Data."
        export uaNum=1
    else
        echo "NOT using GFS FNL Data."
        export uaNum=0
    fi


    ${arps}/run/input/adas_wrf3.sh
    #sbatch ${arps}/adas_serial3.sh
    
    cd ${arps}
    ${arps}/bin/adas < ${arps}/run/input/adas_wrf3.input > adas3.out
    cd ${WRFdir}

    #echo "Submitted ADAS"
    # Need to check to make sure ADAS ran correctly
    counter=0 # Resetting the counter
    while [ ! -e ${arps2wrf}/WRFASSIM_${hh}.hdf000000 ]
    do
        echo "Waiting..."
        sleep 1m
        counter=$((${counter}+1))
        if [ ${counter} -ge 32 ]
        then
            echo "Possible ERROR with ADAS. Check output."
            exit
        fi
    done

    echo "Successful run of ADAS."
    # Remove all of the bin files that were produced
    rm ${WRFdir}/bin_* 2> /dev/null
    #rm ${arps}/bin_*



    #################### ARPS4WRF ###################

    echo ""
    echo "Performing ARPS4WRF."
    echo ""


    # Remove the old files
    rm ${arps4wrf}/met_em.d01.2013-05-20_${hh}:00:00.nc 2> /dev/null
    rm ${arps4wrf}/met_em.d02.2013-05-20_${hh}:00:00.nc 2> /dev/null

    # Now we're done with ADAS, time to convert back to WRF format
    ${arps}/run/input/arps4wrf_wrf3.sh
    #sbatch ${arps}/a4w.sh

    cd ${arps}
    bin/arps4wrf < run/input/arps4wrf_wrf3.input > arps4wrf3.out
    #echo "Submitted ARPS4WRF"

    cd ${WRFdir}
    # Need to make sure that ARPS4WRF ran correctly
    counter=0 # Resetting the counter
    while [ ! -e ${arps4wrf}/met_em.d01.2013-05-20_${hh}:00:00.nc ]
    do
        echo "Waiting..."
        sleep 1m
        counter=$((${counter}+1))
        if [ ${counter} -ge 32 ]
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
    if [ ${hh} -eq ${DAend} ]
    then
        declare -a LBC=( 21 00 03 06 )

        echo ""  
        echo "Passing LBC hour ${lbc} through."

        for lbc in ${LBC[@]}; do


            ################### REAL ####################

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

            echo ""
            echo "Performing real.exe for lbc ${lbc}."
            echo ""

            ${WRFdir}/namelist_DA.sh
            ${WRFdir}/real.exe
            #sbatch ${WRFdir}/real.sh
            

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
            rm ${wrf2arps}/wrfassim_${lbc}.hdfgrdbas 2> /dev/null
            rm ${wrf2arps}/wrfassim_${lbc}.hdf000000 2> /dev/null

            export starthour=${lbc}

            ${arps}/run/input/wrf2arps_input3.sh
            ${arps}/bin/wrf2arps < ${arps}/run/input/wrf2arps3.input > wrf2arps3.out
            #sbatch ${arps}/wrf2arps3.sh
            
            # In this implementation the counter should really not even be
            # needed, however, I'm leaving this in case WRF2ARPS needs to
            # be run through the queue again in the future.

            counter=0 # Resetting the counter.
            while [ ! -e ${wrf2arps}/wrfassim_${lbc}.hdfgrdbas ]
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
            rm ${arps4wrf}/met_em.d01.2013-05-${startday}_${lbc}:00:00.nc 2> /dev/null

            # Now we can pass this through ARPS4WRF
            ${arps}/run/input/arps4wrf_wrf_lbc3.sh
            
            cd ${arps}      
    
            ${arps}/bin/arps4wrf < ${arps}/run/input/arps4wrf_wrf3.input > arps4wrf3.out
            #sbatch ${arps}/a4w.sh
       
            cd ${WRFdir}

            # Need to make sure that ARPS4WRF ran correctly
            counter=0 # Resetting the counter
            while [ ! -e ${arps4wrf}/met_em.d01.2013-05-${startday}_${lbc}:00:00.nc ]
            do
                echo "Waiting..."
                sleep 1m
                counter=$((${counter}+1))
                if [ ${counter} -ge 32 ]
                then
                    echo "Possible ERROR with ARPS4WRF. Check output."
                    exit
                fi
            done
            echo "Successful run of ARPS4WRF."
            rm ${wrfout}/wrfout_d01_2013-05-${startday}_${lbc}:00:00
            done #Done with LBC loop when hh = 18

    ################################# More LBCs ########################################

    else # This handles everything when hh < 18
	        
        export starthour=$((${hh}+1))
        export endhour=$((${hh}+2))
     
               

        ################### REAL ####################

        echo ""
        echo "Performing real.exe for LBC ${starthour}."
        echo ""      
 
        export metgrid_levels=27
        export max_dom=1
  
        # Link in new LBC met_em files
        ln -sf ${GFSmetem}/met_em.d01.2013-05-20_${starthour}:00:00.nc ${WRFdir}
        ln -sf ${GFSmetem}/met_em.d01.2013-05-20_${endhour}:00:00.nc ${WRFdir}

        # Remove old files
        rm ${WRFdir}/wrfinput_d01 2> /dev/null
        ${WRFdir}/namelist_DA.sh
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
        cp ${WRFdir}/wrfinput_d01 ${wrfout}/wrfout_d01_2013-05-20_${starthour}:00:00
        rm ${WRFdir}/wrfinput_d01 2> /dev/null
        echo "Successful run of real.exe."


        ################### WRF2ARPS ####################
 
        echo ""
        echo "Performing WRF2ARPS for LBC ${starthour}."
        echo ""

        # Now we're going to pass this wrf file through WRF2ARPS

        # But first remove old file if it's there.
        rm ${wrf2arps}/wrfassim_${starthour}.hdfgrdbas 2> /dev/null
        rm ${wrf2arps}/wrfassim_${starthour}.hdf000000 2> /dev/null

        export startday=20

        ${arps}/run/input/wrf2arps_input3.sh
        #sbatch ${arps}/wrf2arps.sh

	${arps}/bin/wrf2arps < ${arps}/run/input/wrf2arps3.input > wrf2arps3.out
        
        # In this implementation the counter should really not even be
        # needed, however, I'm leaving this in case WRF2ARPS needs to
        # be run through the queue again in the future.


        counter=0 # Resetting the counter.
        while [ ! -e ${wrf2arps}/wrfassim_${starthour}.hdfgrdbas ]
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
        echo "Performing ARPS4WRF for LBC ${starthour}."
        echo ""

        # First remove old files
        rm ${arps4wrf}/met_em.d01.2013-05-20_${starthour}:00:00.nc 2> /dev/null
        # Now we can pass this through ARPS4WRF
        ${arps}/run/input/arps4wrf_wrf_lbc3.sh
        #sbatch ${arps}/a4w.sh

        cd ${arps}
        bin/arps4wrf < run/input/arps4wrf_wrf3.input > arps4wrf3.out
        cd ${WRFdir}


        # Need to make sure that ARPS4WRF ran correctly
        counter=0 # Resetting the counter
        while [ ! -e ${arps4wrf}/met_em.d01.2013-05-20_${starthour}:00:00.nc ]
        do
            echo "Waiting..."
            sleep 1m
            counter=$((${counter}+1))
            if [ ${counter} -ge 32 ]
            then
                echo "Possible ERROR with ARPS4WRF. Check output."
                exit
            fi
        done
        echo "Successful run of ARPS4WRF."
        rm ${wrfout}/wrfout_d01_2013-05-20_${starthour}:${startmin}:00                


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
        rm ${WRFdir}/wrfinput_d01 2> /dev/null
        rm ${WRFdir}/wrfinput_d02 2> /dev/null
        rm ${WRFdir}/met_em* 2> /dev/null
        ln -sf ${arps4wrf}/met_em* ${WRFdir}

        # Setting forecast variables
        export starthour=${hh} 
        export endhour=$((${hh}+1))
          
        export startday=20
        export endday=20
        export metgrid_levels=48
        export max_dom=2

        echo ""
        echo "Performing Real for hour forecast."
        ${WRFdir}/namelist_DA.sh
        #sbatch ${WRFdir}/realpara.sh

        ${WRFdir}/real.exe

        # Check for Real output
        counter=0
        while [ ! -e ${WRFdir}/wrfinput_d01 ]
        do
            echo "waiting..."
            sleep 1m
            counter=$((${counter}+1))
            if [ ${counter} -ge 32 ]
            then
                echo "real.exe Failure. May have timed out."
                exit
            fi
        done
        echo ""
        echo "Real success. Submitting WRF hour forecast."

        # But first remove old wrfout files
        rm ${WRFdir}/wrfout* 2> /dev/null
        sbatch ${WRFdir}/wrfp.sh
        # Check for WRF output
        counter=0
        while [ ! -e ${WRFdir}/wrfout_d01_2013-05-20_${endhour}:00:00 ]
        do
            
            sleep 3m
            counter=$((${counter}+1))
            if [ ${counter} -gt 30 ]
            then
                echo "Possible ERROR with WRF. May have timed out.."
                echo "Damn debug hogs!!!"
                exit
            fi
        done
        cp ${WRFdir}/wrfout_d01_2013-05-20_${starthour}:00:00 ${wrfout}/wrfout_d01_2013-05-20_${starthour}:00:00_AAA
        echo "Successful completion of WRF hour forecast."
        ###################################################
    fi # End with the WRF forecast portion


done # With hour loop

echo "Cleaning up files:"
rm ${wrf2arps}/wrfassim* 2> /dev/null
rm ${arps2wrf}/WRFASSIM* 2> /dev/null
rm ${WRFdir}/rsl* 2> /dev/null
rm ${WRFdir}/bin* 2> /dev/null
rm ${WRFdir}/met* 2> /dev/null

echo "!!!!!!!!!!!!!!!!!"
echo "!!!! Success !!!!"
echo "!!!!!!!!!!!!!!!!!" 

