#!/bin/bash

#
# A generic wrapper for choosing the mapper
#
# It takes as input an index file, an annotation file, the reads files and generates the genome bam file
#
# CLI Parameters:
# - $1: The index file
# - $2: The annotation file
# - $3: The first reads file
# - $4: The second reads file
# - $5: The t_gem file
# - $6: The t_keys file
# - $7: The quality number
# - $8: The name file
# - $9: The number of threads
# - $10: The loglevel

set -e
set -u

INDEX=${2}
ANNOTATION=${3}
READS1=${4}
READS2=${5}
BAMNAME=${6}
QUALITY=${7}
CPUS=${8}
LOGLEVEL=${9}


ALLNAME="${INDEX##*/}"
LENGTH_PATH="${#INDEX} - ${#ALLNAME}"
INDEX_PATH="${INDEX:0:$LENGTH_PATH}"
NAMEFILE="${ALLNAME%.[^.]*}"
EXTENSION="${ALLNAME:${#NAMEFILE} + 1}"



case "$1" in
'gem')
mv $INDEX $INDEX_PATH/index.gem
gemtools --loglevel ${LOGLEVEL} t-index -i $INDEX_PATH/index.gem -a ${ANNOTATION} -m 150 -t ${CPUS}
TGEM=`ls | grep '.junctions.gem'` 
TKEYS=`ls | grep '.junctions.keys'`
gemtools --loglevel ${LOGLEVEL} rna-pipeline -i $INDEX_PATH/index.gem -a ${ANNOTATION} -f ${READS1} ${READS2} -t ${CPUS} -q ${QUALITY} --name ${BAMNAME} -r ${TGEM} -k ${TKEYS}
;;

'tophat2')
tophat2 --splice-mismatches 1 -p ${CPUS} --GTF ${ANNOTATION} ${INDEX_PATH}/index.gem ${READS1} ${READS2}
ln -s tophat_out/accepted_hits.bam ${BAMNAME}.bam
;;

*) echo "Not a valid indexer strategy: $1"; exit 1
;;

esac 
