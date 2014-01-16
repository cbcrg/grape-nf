#!/bin/bash

#
# A generic RNA-mapper tool wrapper
#
# It takes as input an index file, an annotation file, the reads files and generates the genome bam file
#
# CLI Parameters:
# - $1: The mapper tool to be used
# - $2: The index file
# - $3: The annotation file
# - $4: The first reads file
# - $5: The second reads file
# - $6: The output bam file
# - $7: The quality number
# - $8: The cpu to be used

[ ! -z $NF_DEBUG_SCRIPT ] && set -x
set -e
set -u

GENOME=${2}
INDEX=${3}
ANNOTATION=${4}
READS1=${5}
READS2=${6}
OUTFILE=${7}
QUALITY=${8}
CPUS=${9}

BAMNAME=$(basename ${OUTFILE})

case "$1" in
#
# GEMtools mapper
# See https://github.com/gemtools/gemtools
#
'gem')

# note: it requires the index file name ending with '.gem' suffix
ln -s ${INDEX} index.gem

gemtools t-index -i index.gem -a ${ANNOTATION} -m 150 -t ${CPUS}
gemtools rna-pipeline -i index.gem -a ${ANNOTATION} -f ${READS1} ${READS2} -t ${CPUS} -q ${QUALITY} --name ${BAMNAME} -r *.junctions.gem -k *.junctions.keys

;;

#
# Use 'tophat2' mapper
# Seee http://tophat.cbcb.umd.edu/
#
'tophat2')
[ "$QUALITY" -eq "33" ] && qual=''
[ "$QUALITY" -eq "64" ] && qual='--phred64-quals'

tophat2 -p ${CPUS} --splice-mismatches 1 ${qual} --GTF ${ANNOTATION} ${INDEX} ${READS1} ${READS2}
mv tophat_out/accepted_hits.bam ${BAMNAME}.bam
;;

#
# HPG aligner
# See https://github.com/opencb-hpg/hpg-aligner
#
'hpg')
hpg-aligner rna --fq $READS1 --fq2 $READS2 -i $INDEX -o mapped --cpu-threads $CPUS
mv mapped/alignments.bam ${BAMNAME}.bam
;;

*)
echo "Not a valid indexer strategy: $1"; exit 1
;;

esac 

	    
