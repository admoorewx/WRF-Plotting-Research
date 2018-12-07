#!/bin/sh

cat << alter | sed -e 's/ *$//' > ${CURR_DIR}/sat.input
&grid_dims
nx   = ${nx},
ny   = ${ny},
nz   = ${nz},
/

&message_passing
nproc_x = 1,
nproc_y = 1,

max_fopen = 1,
/


&jobname
runname = '${type}_${hour}${minute}',
/

&grid
dx       =  ${dx},
dy       =  ${dy},
dz       =   400.000,
strhopt  = 2,
dzmin    =   20.000,
zrefsfc  =     0.0,
dlayer1  =     10,
dlayer2  =     100000,
strhtune =     0.8,
zflat    =     100000,
ctrlat   =  ${ctrlat},
ctrlon   =  ${ctrlon},

crdorgnopt = 0,

/

&projection
mapproj = 2,
trulat1 =  32.0,
trulat2 =  34.0,
trulon  = -97,
sclfct  =  1.0,

mpfctopt = 1,
mptrmopt = 1,
maptest  = 0,
/

alter
