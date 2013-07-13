#!/usr/bin/env nextflow

/*
 * Copyright (c) 2013, Centre for Genomic Regulation (CRG) and the authors.
 *
 *   This file is part of 'Grape-NF'.
 *
 *   Grape-NF is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU General Public License as published by
 *   the Free Software Foundation, either version 3 of the License, or
 *   (at your option) any later version.
 *
 *   Grape-NF is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details.
 *
 *   You should have received a copy of the GNU General Public License
 *   along with Grape-NF.  If not, see <http://www.gnu.org/licenses/>.
 */


/* 
 * Main Grape-NF pipeline script
 *
 * @authors
 * Beatriz M. San Juan <bmsanjuan@gmail.com> 
 * Paolo Di Tommaso <paolo.ditommaso@gmail.com>
 * Pablo Prieto <poena.funesta@gmail.com> 
 * Emilio Palumbo <emiliopalumbo@gmail.com> 
 */


params.genome      = './tutorial/data/genome_1Mbp.fa'
params.name        = 'genome'
params.annotation  = './tutorial/data/annotation.gtf'
params.primary     = './tutorial/data/test_1.fastq'
params.secondary   = './tutorial/data/test_2.fastq'
params.quality     = 33
params.cpus        = 1
params.output      = './results'

/* 
 * Enable/disable GEM debugging information. Valid values: error, warn, info, debug 
 */ 
params.loglevel = 'warn'

/* 
 * Enable/disable tasks stdout print 
 */
params.echo = true
echo params.echo


/*
 * Input parameters validation
 */

File genome_file = file(params.genome)
File annotation_file = file(params.annotation)
File primary_reads_file = file(params.primary)
File secondary_reads_file = file(params.secondary)
File resultPath = file(params.output)

if( !genome_file.exists() ) exit 1, "Missing genome file: ${genome_file}"
if( !annotation_file.exists() ) exit 2, "Missing annotatio file: ${annotation_file}"
if( !primary_reads_file.exists() ) exit 3, "Missing primary reads file: ${primary_reads_file}"
if( !secondary_reads_file.exists() ) exit 4, "Missing secondary file: ${secondary_reads_file}"

if( resultPath.isNotEmpty() ) resultPath.deleteDir()
if( !resultPath.exists() ) resultPath.mkdirs()
if( !resultPath.exists() ) exit 5, "Cannot create output folder: $resultPath -- Check file system access permission"



/* 
 * Since the GEM index is going to be provided as input of both tasks 'transcriptome-index' and 'rna-pipeline'
 * it is declared like a 'broadcast' list instead of a plain channel 
 */ 


index_gem = list()

task('index'){
    input genome_file
    output 'index.gem': index_gem

    """
    gemtools --loglevel ${params.loglevel} index -i ${genome_file} -o index.gem -t ${params.cpus}
    """
}


t_gem  = channel()
t_keys = channel()

task('transcriptome-index'){
    input index_gem
    output '*.junctions.gem': t_gem
    output '*.junctions.keys': t_keys

    """
    gemtools --loglevel ${params.loglevel} t-index -i ${index_gem} -a ${annotation_file} -m 150 -t ${params.cpus}
    """
}


bam       = list()
map       = channel()
bam_index = channel()

task('rna-pipeline'){
    input index_gem
    input annotation_file
    input primary_reads_file
    input secondary_reads_file
    input  t_gem
    input  t_keys
    output "*.map.gz": map
    output "*.bam": bam
    output "*.bam.bai": bam_index

    """
    gemtools --loglevel ${params.loglevel} rna-pipeline -i ${index_gem} -a ${annotation_file} -f ${primary_reads_file} ${secondary_reads_file} -r ${t_gem} -k ${t_keys} -t ${params.cpus}  -q ${params.quality} --name ${params.name}
    """
}


transcripts = channel()
isoforms    = channel()
genes       = channel()

task('cufflinks'){
    input bam
    output 'transcripts.gtf': transcripts
    output 'isoforms.fpkm_tracking': isoforms
    output 'genes.fpkm_tracking': genes

    """
    cufflinks -p ${params.cpus} ${bam}
    """
}


quantification = channel()

task('flux'){
    input bam
    input annotation_file
    output 'quantification.gtf': quantification

    """
    flux-capacitor -i ${bam} -a ${annotation_file} -o quantification.gtf --threads ${params.cpus}
    """
}

/*
 * producing output files
 */
out_transcripts = new File(resultPath, 'transcripts.gtf')
out_quantification = new File(resultPath, 'quantification.gtf')

transcripts.val.copyTo(out_transcripts)
quantification.val.copyTo(out_quantification)


log.info "* Flux quantification file: ${out_quantification}"
log.info "* Cufflink transcripts file: ${out_transcripts}"

