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
run=${log:0:4}
nt=${log:13:1}
export IDL_PATH_IN=$IDL_PATH

## Generate the Raw Reduction Scripts
echo $'\n CPS-PIPELINE-RREDUCE Running Raw reduction for ' $1  $'\n'
export IDL_PATH=/mir3/reduce/create_hamred/:$IDL_PATH_IN
cd /mir3/reduce/create_hamred/
idl -e endofnight_hires -arg $1

## Run the Raw Reduction
echo $'\n CPS-PIPELINE-RREDUCE Running Middle Chip Raw reduction for ' $1 $'\n'
cd /mir3/reduce/
export IDL_PATH=/mir3/reduce/:$IDL_PATH
idl -e @hamred-$run-$nt
mv hamred-$run-$nt /mir3/reduce/old_hamreds/ #Clean up repo

## Run the Raw Reduction
echo $'\n CPS-PIPELINE-RREDUCE Running blue Chip Raw reduction for ' $1 $'\n'
cd /mir3/reduce_blue/
export IDL_PATH=/mir3/reduce_blue/:$IDL_PATH
idl -e @hamred-$run-$nt

## Run the Raw Reduction
echo $'\n CPS-PIPELINE-RREDUCE Running Red Chip Raw reduction for ' $1 $'\n'
cd /mir3/reduce_red/
export IDL_PATH=/mir3/reduce_red/:$IDL_PATH
idl -e @hamred-$run-$nt

echo 'Raw Reduction complete'
cd $HOME
export IDL_PATH=$PATH_IN