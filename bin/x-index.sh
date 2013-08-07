#!/bin/bash

#
# A generic wrapper for genetating the index file
#
# It takes as input a genome file and generates the index file
#
# CLI Parameters:
# - $1: The genome FASTA file to format
# - $2: The number of threads
# - $3: The loglevel

set -e
set -u

GENOME=${2}
CPUS=${3}
LOGLEVEL=${4}

case "$1" in
'gem')
gemtools --loglevel ${LOGLEVEL} index -i ${GENOME} -o index.gem -t ${CPUS} --no-hash
;;

'tophat2')
bowtie2-build ${GENOME} index.gem
touch index.gem
;;

*) echo "Not a valid indexer strategy: $1"; exit 1
;;

esac 
