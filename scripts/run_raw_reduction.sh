#!/usr/bin/bash

usage () { cat <<EOF
NAME
       rreduce    Generate hamreds and Run Raw Reduction
SYNOPSIS
       cps rreduce
NOTES  
       Feed with a logsheet name.   
       IDL Path control belongs in the IDL bash scripts.
EOF
}

# Verify number of arguments
if [ "$1" == "-h" ]
then
    usage
    exit 1
elif [ "$1" == "--help" ]
then
    usage
    exit 1
elif [ "$1" == "" ]
then
    usage
    exit 1
fi

#Notes to Howard:  NO SPACES. Quotes only for variables with spaces.
#Extract run and night number. Todo: Allow j11 or j111.
log=$1
run=${log:0:8}
export IDL_PATH_IN=$IDL_PATH

### Middle chip
echo $'\n CPS-PIPELINE-RREDUCE Running Middle Chip Raw reduction for ' $1 $'\n'
export IDL_PATH=${RAW_MID}:${RAW_MID}/create_hamred/:${IDL_PATH_IN}
idl -e endofnight_hires -arg $1
idl -e @${RAW_HAMRED_OUTDIR}/hamred-${run}-mid-1

### Blue chip
# echo $'\n CPS-PIPELINE-RREDUCE Running blue Chip Raw reduction for ' $1 $'\n'
# export IDL_PATH=${RAW_BLU}:${RAW_BLU}/create_hamred/:${IDL_PATH_IN}
# idl -e endofnight_hires -arg $1
# idl -e @${RAW_HAMRED_OUTDIR}/hamred-${run}-blue-1

### Red chip
# echo $'\n CPS-PIPELINE-RREDUCE Running Red Chip Raw reduction for ' $1 $'\n'
# export IDL_PATH=${RAW_RED}:${RAW_RED}/create_hamred/:${IDL_PATH_IN}
# idl -e endofnight_hires -arg $1
# idl -e @${RAW_HAMRED_OUTDIR}/hamred-${run}-red-1
#
# echo 'Raw Reduction completed successfully'
#cd $HOME
export IDL_PATH=$PATH_IN
