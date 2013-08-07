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
# - $5: The quality number
# - $6: The name file
# - $7: The number of threads
# - $8: The results folder
# - $9: The loglevel

set -e
set -u

INDEX=${2}
ANNOTATION=${3}
READS1=${4}
READS2=${5}
BAMNAME=${6}
QUALITY=${7}
CPUS=${8}
OUT=${9}
LOGLEVEL=${10}


case "$1" in
'gem')
#mv ${INDEX} ${INDEX_PATH}/index.gem
gemtools --loglevel ${LOGLEVEL} t-index -i ${INDEX} -a ${ANNOTATION} -m 150 -t ${CPUS}
TGEM=`ls | grep '.junctions.gem'` 
TKEYS=`ls | grep '.junctions.keys'`

gemtools --loglevel ${LOGLEVEL} rna-pipeline -i ${INDEX} -a ${ANNOTATION} -f ${READS1} ${READS2} -t ${CPUS} -q ${QUALITY} --name ${BAMNAME} -r ${TGEM} -k ${TKEYS}

# Move the BAi files to the result folder
BAI=${BAMNAME}.bam.bai
rm -f ${OUT}/${BAI}
mv ${BAI} ${OUT}/${BAI}
ln -s ${OUT}/$BAI
;;

'tophat2')
tophat2 --splice-mismatches 1 -p ${CPUS} --GTF ${ANNOTATION} ${INDEX} ${READS1} ${READS2}
mv tophat_out/accepted_hits.bam ${BAMNAME}.bam
;;

*) echo "Not a valid indexer strategy: $1"; exit 1
;;

esac 

 # Move the BAM files to the result folder
BAM=${BAMNAME}.bam
rm -f ${OUT}/${BAM}
mv ${BAM} ${OUT}/${BAM}
ln -s ${OUT}/${BAM}
	    
