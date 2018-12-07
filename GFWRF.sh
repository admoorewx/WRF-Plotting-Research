#!/bin/bash



echo ""
echo ""
echo "!!!!!!!!!!!!!!!!"
echo "!!! G.F. WRF !!!"
echo "!!!!!!!!!!!!!!!!"
echo ""

# Directory Section #######
WRFdir=/scratch/admoore/WRFGF/GrandForks
MetgridDir=/scratch/admoore/GFmetgrid
ungribDir=/scratch/admoore/ungrib_nam
WPSdir=/home/admoore/WPS/GrandForks/
RawModelDir=/scratch/admoore/wrfNAM
imageDir=/home/admoore/GF
plotDir=/home/admoore/scripts

echo ""
echo "Checking Directory Paths..."
echo "WRFdir = ${WRFdir}"
echo "MetgridDir = ${MetgridDir}"
echo "ungribDir = ${ungribDir}"
echo "WPSdir = ${WPSdir}"
echo "RawModelDir = ${RawModelDir}"
echo "imageDir = ${imageDir}"
echo ""


echo "Beginning WPS."
echo ""
########## Universal Variables #########

fcstLength=6
export fcstLength=6

########## Date and Time Section ##########

# This section will determine what the latest run of the NAM is. 
now=$(date -u +"%Y%m%d")
currentHour=$(date -u +"%H")
getTime=$now$getHour

if [ ${currentHour} -lt 06 ]
then
    gethour=00

elif [ ${currentHour} -lt 12 ]
then 
    gethour=06

elif [ ${currentHour} -lt 18 ]
then 
    gethour=12

else
    gethour=18
fi


#This section will begin to export variables for the namelists. 
export yy=$(date -u +"%Y")

export mm=$(date -u +"%m")

export dd=$(date -u +"%d")

export hour=$(date -u +"%H")

export endhh=$((${hour}+${fcstLength}))


# Fix for the end of the UTC day. WARNING: Does not account for end of month/year yet!!!
#if [ ${hour} = 00 ] 
#then
#    hour=23
#    dd=$((${dd}-1))
#fi

# This section will take care of switching over the days, months, and years. 
if [ ${endhh} -ge 24 ] 
then
    export enddd=$((${dd}+1))
    export endhh=$((${endhh}-24)) 
    export endyy=${yy}
    export endmm=${mm}


    if  [ ${mm} = 01 ] || [ ${mm} = 03 ] || [ ${mm} = 05 ] || [ ${mm} = 07 ] || [ ${mm} = 08 ] || [ ${mm} = 10 ] && [ ${dd} = 31 ]; 
    then 
        export endmm=$((${mm}+1))
        export enddd=01
    fi 

    if  [ ${mm} = 04 ] || [ ${mm} = 06 ] || [ ${mm} = 09 ] || [ ${mm} = 11 ] && [ ${dd} = 30 ];
    then
        export endmm=$((${mm}+1))
        export enddd=01
    fi

    if  [ ${mm} = 02 ] && [ ${endd} = 28 ];
    then
        export endmm=03
        export enddd=01
    fi


    if  [ ${mm} = 12 ] && [ ${endd} = 31 ];
    then
        export endmm=01
        export enddd=01
        export endyy=$((${yy}+1))
    fi

else 

    export enddd=${dd}
    export endmm=${mm}
    export endyy=${yy}

fi

if [ ${endhh} -lt 10 ] 
then 
    export endhh=0${endhh}
fi

echo "It is currently: ${yy}-${mm}-${dd} Hour: ${currentHour}"
echo "Model Start: ${yy}-${mm}-${dd} Hour: ${hour}"
echo "Model End: ${endyy}-${endmm}-${enddd} Hour: ${endhh}"
echo ""

########## Grab Data Section ##########

echo "Trying to grab NAM data from NCEP..."

rm ${RawModelDir}/nam.* 2> /dev/null

declare -a fh=( 00 01 02 03 04 05 06 07 08 09 10 11 12 )

for hh in ${fh[@]}; do
    
    echo "Getting hour ${hh}"  
    curl -s --disable-epsv --connect-timeout "45" -m "60" -o "nam.t${gethour}z.awphys${hh}.tm00.grib2" ftp://ftpprd.ncep.noaa.gov/pub/data/nccf/com/nam/prod/nam.${now}/nam.t${gethour}z.awphys${hh}.tm00.grib2

    if [ ! -e nam.t${gethour}z.awphys${hh}.tm00.grib2 ]
    then
        echo "Background files may not yet be available from NCEP: Try again later."
        exit
    fi

    echo "Retrieved file: ftp://ftpprd.ncep.noaa.gov/pub/data/nccf/com/nam/prod/nam.${now}/nam.t${gethour}z.awphys${hh}.tm00.grib2"
    cp nam.t${gethour}z.awphys${hh}.tm00.grib2 ${RawModelDir}/nam.t${gethour}z.awphys${hh}.tm00.grib2    
    rm nam.t${gethour}z.awphys${hh}.tm00.grib2


done
echo ""

########### WPS Section #############

# This section assumes the correct Vtable and METGRID.TBL 
# have already been set up.
cd ${WPSdir}

# Remove old GRIBFILEs
rm GRIBFILE* 2> /dev/null

# Link the new grib files to WPS Directory
./link_grib.csh ${RawModelDir}/nam.*

# Produce the file namelist.wps
./namelist.sh


# First check to see if the geogrid files are already there. 
# No need to recreate if so!

if [ ! -e "${WPSdir}/geo_em.d01.nc" ]
then 
    # Perform Geogrid
    echo "Executing geogrid.exe"
    sbatch geogrid.sh

    counter=0 # This will track how many times we have to wait
    while [ ! -e "${WPSdir}/geo_em.d01.nc" ]
    do
        echo "Waiting for Geogrid..."
        counter=$((${counter}+1))
        sleep 2m
        if [ ${counter} -ge 15 ]
        then
            echo "Possible error creating geo_em files. Check error file."
            exit
        fi
    done
fi

# Perform Ungrib - this will have to be done each time.
# First need to remove old ungrib files
rm ${ungribDir}/NAM* 2> /dev/null

echo ""
echo "Executing ungrib.exe"
#sbatch ungrib.sh

cd ${WPSdir}
./ungrib.exe > ungribout.txt
sleep 10s

echo "Looking for: NAM:${yy}-${mm}-${dd}_${hour}"
counter=0 # This will track how many times we have to wait
while [ ! -e ${ungribDir}/NAM:${yy}-${mm}-${dd}_${hour} ]
do
    echo "Waiting for Ungrib..."
    counter=$((${counter}+1))
    sleep 1m
    if [ ${counter} -ge 1 ]
    then
        echo "Possible error creating ungrib files. Check error file."
        exit
    fi
done


# Perform Metgrid - this will have to be done each time.
# First need to remove old met_em files
rm ${MetgridDir}/met_em*

echo ""
echo "Executing metgrid.exe"
#sbatch metgrid.sh
cd ${WPSdir}
./metgrid.exe 
sleep 10s

#counter=0 # This will track how many times we have to wait
#while [ ! -e ${MetgridDir}/met_em.d01.${endyy}-${endmm}-${enddd}_${endhour}:00:00.nc ]
#do
#    echo "Waiting for Metgrid..."
#    counter=$((${counter}+1))
#    sleep 2m
#    if [ ${counter} -ge 15 ]
#    then
#        echo "Possible error creating metgrid files. Check error file."
#        exit
#    fi
#done

echo ""
echo "Successful completion of WPS."
echo ""
########### WRF Section #############

# Switch over to WRF/GrandForks directory
cd ${WRFdir}

# remove old metgrid files
rm met_em* 2> /dev/null

# Link over new metgrid files
ln -sf ${MetgridDir}/met_em* . 

# Create new namelist.input file
./namelist.sh

# Remove old wrfinput files
rm wrfinput* 2> /dev/null

# Execute real.exe
echo "Executing real.exe."
#sbatch realpara.sh
./real.exe

counter=0 # This will track how many times we have to wait
while [ ! -e ${WRFdir}/wrfinput_d01 ]
do
    echo "Waiting on Real..."
    counter=$((${counter}+1))
    sleep 2m
    if [ ${counter} -ge 15 ]
    then
        echo "Possible error creating wrfinputfiles. Check rsl.error file."
        exit
    fi
done

echo "Done with real.exe."
echo ""


# Remove old wrfout files
rm wrfout* 2> /dev/null

# Execute real.exe
echo "Executing wrf.exe."
sbatch wrfpara.sh


counter=0 # This will track how many times we have to wait
while [ ! -e ${WRFdir}/wrfout_d01_${endyy}-${endmm}-${enddd}_${endhh}:00:00 ]
do
    echo "Waiting on WRF..."
    counter=$((${counter}+1))
    sleep 2m
    if [ ${counter} -ge 16 ]
    then
        echo "Possible error running WRF. Check rsl.error file."
        exit
    fi
done

echo "Successful completion of WRF!"
echo ""

# Plot the Data
# Right now this is just Comp. Refl., dewpoint, and temp/press

#Remove old images:
rm ${imageDir}/d01* 2> /dev/null
rm ${imageDir}/d02* 2> /dev/null

# Turn on Plotting
source activate plotting

# Change to plotting directory
cd ${plotDir}

export Year=${yy}
export Month=${mm}
export Day=${dd}
export countHour=${currentHour}

declare -a minutes=( 00 30 )

# Check to see if the end hour is in the next day
if [ ${dd} -eq ${enddd} ] 
then
    endHour=${endhh}
else
    endHour=$((${endhh}+24))
fi


while [ ${countHour} -le ${endHour} ]
do 

    for min in ${minutes[@]}; do

        if [ ${countHour} -ge 24 ] 
        then
            export Hour=0$((${countHour}-24))
            export Day=${enddd}
            export Month=${endmm}

        else
            export Hour=${countHour}
        fi

        echo "${Hour}${min}"
        export Minute=${min}

        ./plot_wrf_gf.sh
        python plot_wrf_gf.py

        # Check to see if plotting is done:
        counter=0
        while [ ! -e ${imageDir}/Flag.png ] 
        do 
            sleep 3s
            counter=$((${counter}+1))
            if [ ${counter} -ge 20 ] 
            then
                echo "Error Creating Image"
                exit
            fi # exit if 
        done # exit check for Flag.png
    done #with for loop

    countHour=$((${countHour}+1))

done #exit plotting

echo "!!!!!!!!!!!!!!!"
echo "!!! Success !!!"
echo "!!!!!!!!!!!!!!!"

