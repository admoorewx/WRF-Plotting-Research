#!/bin/sh

export Test="True"

if [ Test ] 
then 
    echo "True."
fi

export Test="False"

if [ ${Test} == "True" ] 
then 
    echo "True again."
else
    echo "False."
fi
