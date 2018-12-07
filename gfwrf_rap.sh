#!/bin/bash

echo "Beginning WPS."
echo ""
########## Universal Variables #########

fcstLength=2
export fcstLength=2

########## Date and Time Section ##########

# This section will determine what the latest run of the NAM is. 
now=$(date -u +"%Y%m%d")
currentHour=$(date -u +"%H")
getTime=$now$getHour


# From NAM script - needed to get NAM soil data
if [ ${currentHour} -lt 06 ]
then
    namhour=00

elif [ ${currentHour} -lt 12 ]
then 
    namhour=06

elif [ ${currentHour} -lt 18 ]
then 
    namhour=12

else
    namhour=18
fi

gethour=$((${currentHour}-2))

# This section checks that if it is 00z or 01z then we use data from 
# 23z the previous day. This is because the new day's data isn't likely in 
# from NCEP yet. 
if [ ${currentHour} -lt 2 ] 
then
    namhour=18
    now=$((${now}-1))
    gethour=$(((${currentHour}+24)-2))
fi 



#This section will begin to export variables for the namelists. 
export yy=$(date -u +"%Y")

export mm=$(date -u +"%m")

export dd=$(date -u +"%d")

export hour=$(date -u +"%H")

export endhh=$((${hour}+${fcstLength}))

# Fixing for the end of the UTC day. WARNING: Does not account for end of month/year yet!!!
if [ ${hour} = 00 ] 
then
    hour=23
    dd=$((${dd}-1))
fi

# This section will take care of switching over the days, months, and years. 
if [ ${endhh} = 24 ] 
then
    export enddd=$((${dd}+1))
    export endhh=00 
    export endyy=${yy}
    export endmm=${mm}


    if  [ ${mm} = 01 ] || [ ${mm} = 03 ] || [ ${mm} = 05 ] || [ ${mm} = 07 ] || [ ${mm} = 08 ] || [ ${mm} = 10 ] && [ ${enddd} = 31 ]; 
    then 
        export endmm=$((${mm}+1))
        export enddd=01
    fi 

    if  [ ${mm} = 04 ] || [ ${mm} = 06 ] || [ ${mm} = 09 ] || [ ${mm} = 11 ] && [ ${enddd} = 30 ];
    then
        export endmm=$((${mm}+1))
        export enddd=01
    fi

    if  [ ${mm} = 02 ] && [ ${enddd} = 28 ];
    then
        export endmm=03
        export enddd=01
    fi


    if  [ ${mm} = 12 ] && [ ${enddd} = 31 ];
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

# This section makes sure that the endhh = 01,02,03,etc..
# instead of endhh = 1,2,3,etc...

if [ ${endhh} -lt 10 ] 
then
    export endhh=0${endhh}
    echo "${endhh}"
fi



echo "It is currently: ${yy}-${mm}-${dd}_${currentHour}"
echo "Model Start: ${yy}-${mm}-${dd}_${hour}:00:00"
echo "Model End: ${endyy}-${endmm}-${enddd}_${endhh}:00:00"
echo ""

########## Grab Data Section ##########

echo "Trying to grab RAP data from NCEP..."

# using files of the form:
# rap.txxz.awp130pgrbfhh.grib2
# This is the 13 km CONUS grid


declare -a fh=( 00 01 02 03 04 05 06 07 08 09)

for hh in ${fh[@]}; do
    
    echo "Getting hour ${hh}"  
    curl -s --disable-epsv --connect-timeout "30" -m "60" -o "rap.t${gethour}z.awp130pgrbf${hh}.grib2" ftp://ftpprd.ncep.noaa.gov/pub/data/nccf/com/rap/prod/rap.${now}/rap.t${gethour}z.awp130pgrbf${hh}.grib2

    if [ ! -e rap.t${gethour}z.awp130pgrbf${hh}.grib2 ]
    then
        echo "Background files may not yet be available from NCEP: Try again later."
        exit
    fi

    echo "Retrieved file: ftp://ftpprd.ncep.noaa.gov/pub/data/nccf/com/rap/prod/rap.${now}/rap.t${gethour}z.awp130pgrbf${hh}.grib2"
    cp rap.t${gethour}z.awp130pgrbf${hh}.grib2 /scratch/admoore/wrfRAP/rap.t${gethour}z.awp130pgrbf${hh}.grib2    
    rm rap.t${gethour}z.awp130pgrbf${hh}.grib2


done
echo ""

echo "Getting NAM soil data from NCEP."
declare -a fh=( 00 01 02 03 04 05 06 )

for hh in ${fh[@]}; do

    echo "Getting hour ${hh}"
    curl -s --disable-epsv --connect-timeout "30" -m "60" -o "nam.t${namhour}z.awphys${hh}.tm00.grib2" ftp://ftpprd.ncep.noaa.gov/pub/data/nccf/com/nam/prod/nam.${now}/nam.t${namhour}z.awphys${hh}.tm00.grib2

    if [ ! -e nam.t${namhour}z.awphys${hh}.tm00.grib2 ]
    then
        echo "Background files may not yet be available from NCEP: Try again later."
        exit
    fi

    echo "Retrieved file: ftp://ftpprd.ncep.noaa.gov/pub/data/nccf/com/nam/prod/nam.${now}/nam.t${namhour}z.awphys${hh}.tm00.grib2"
    cp nam.t${namhour}z.awphys${hh}.tm00.grib2 /scratch/admoore/wrfNAM/nam.t${namhour}z.awphys${hh}.tm00.grib2
    rm nam.t${namhour}z.awphys${hh}.tm00.grib2


done
echo ""
echo "Done getting files."

########### WPS Section #############

# This section assumes the correct Vtable and METGRID.TBL 
# have already been set up.
cd /home/admoore/WPS/GrandForks

# Remove old GRIBFILEs
rm GRIBFILE*

# Link the new grib files to WPS Directory
./link_grib.csh /scratch/admoore/wrfRAP/rap.*

# Produce the file namelist.wps
./namelistRAP.sh


# First check to see if the geogrid files are already there. 
# No need to recreate if so!

if [ ! -e '/home/admoore/WPS/GrandForks/geo_em.d01.nc' ]
then 
    # Perform Geogrid
    echo "Executing geogrid.exe"
    sbatch geogrid.sh

    counter=0 # This will track how many times we have to wait
    while [ ! -e '/home/admoore/WPS/GrandForks/geo_em.d01.nc' ]
    do
        echo "Waiting..."
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
rm /scratch/admoore/ungrib_nam/RAP*

# Then need to perform ungrib for RAP data. Link Vtable first
ln -sf ./ungrib/Variable_Tables/Vtable.RAP.pressure.ncep ./Vtable

echo ""
echo "Executing ungrib.exe"
sbatch ungrib.sh
echo "Looking for: RAP:${yy}-${mm}-${dd}_${hour}"
counter=0 # This will track how many times we have to wait
while [ ! -e /scratch/admoore/ungrib_nam/RAP:${yy}-${mm}-${dd}_${hour} ]
do
    echo "Waiting..."
    counter=$((${counter}+1))
    sleep 2m
    if [ ${counter} -ge 15 ]
    then
        echo "Possible error creating ungrib files. Check error file."
        exit
    fi
done


# Then need to perform ungrib for NAMsoil data. Link Vtable first
ln -sf ./Vtable.NAMsoil ./Vtable

# Then link in the correct grib files
rm GRIBFILE*
./link_grib.csh /scratch/admoore/wrfNAM/nam*

# Produce the correct namelist.wps file
./namelistNAM.sh

# Remove old files
rm /scratch/admoore/ungrib_nam/NAMsoil*

echo ""
echo "Executing ungrib.exe"
sbatch ungrib.sh
echo "Looking for: NAMsoil:${yy}-${mm}-${dd}_${hour}"
counter=0 # This will track how many times we have to wait
while [ ! -e /scratch/admoore/ungrib_nam/NAMsoil:${yy}-${mm}-${dd}_${hour} ]
do
    echo "Waiting..."
    counter=$((${counter}+1))
    sleep 2m
    if [ ${counter} -ge 15 ]
    then
        echo "Possible error creating ungrib files. Check error file."
        exit
    fi
done


# Perform Metgrid - this will have to be done each time.
# First need to remove old met_em files
rm /scratch/admoore/GFmetgrid/met_em*

echo ""
echo "Executing metgrid.exe"
sbatch metgrid.sh

counter=0 # This will track how many times we have to wait
while [ ! -e /scratch/admoore/GFmetgrid/met_em.d02.${yy}-${mm}-${dd}_${hour}:00:00.nc ]
do
    echo "Waiting..."
    counter=$((${counter}+1))
    sleep 2m
    if [ ${counter} -ge 15 ]
    then
        echo "Possible error creating metgrid files. Check error file."
        exit
    fi
done

echo ""
echo "Successful completion of WPS."
echo ""


########### WRF Section #############

# Switch over to WRF/GrandForks directory
cd /scratch/admoore/WRFgf

# remove old metgrid files
rm met_em* 

# Link over new metgrid files
ln -sf /scratch/admoore/GFmetgrid/met_em* . 

# Create new namelist.input file
./namelist.sh

# Remove old wrfinput files
rm wrfinput*

# Execute real.exe
echo "Executing real.exe."
sbatch realpara.sh


counter=0 # This will track how many times we have to wait
while [ ! -e /scratch/admoore/WRFgf/wrfinput_d01 ]
do
    echo "Waiting..."
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
rm wrfout*

# Execute real.exe
echo "Executing wrf.exe."
sbatch wrfpara.sh


counter=0 # This will track how many times we have to wait
while [ ! -e /scratch/admoore/WRFgf/wrfout_d02_${yy}-${mm}-${dd}_${hh}%3A00%3A00 ]
do
    echo "Waiting..."
    counter=$((${counter}+1))
    sleep 5m
    if [ ${counter} -ge 7 ]
    then
        echo "Possible error running WRF. Check rsl.error file."
        exit
    fi
done

echo "Successful completion of WRF!"
echo ""


echo "Beginning plotting."

# Move into to plotting directory
cd /scratch/admoore/wrfout
# Call the python plotting script
# If you want to change the fields that are plotted go to
# /home/admoore/scripts/plotGF.py

python /home/admoore/scripts/plotGF.py


counter=0 # This will track how many times we have to wait
while [ ! -e /scratch/admoore/wrfout/d01_cref_f08.gif ]
do
    echo "Waiting..."
    counter=$((${counter}+1))
    sleep 5m
    if [ ${counter} -ge 7 ]
    then
        echo "Plotting Error."
        exit
    fi
done

echo ""
echo ""
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo "Successful completion of the WRF model!"
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo ""
echo "Total time for completion:"



