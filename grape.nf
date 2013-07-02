#!/usr/bin/env nextflow

=======
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


params.input       = './tutorial/data/genome_1Mbp.fa'
params.name        = 'genome'
params.annotation  = './tutorial/data/annotation.gtf'
params.primary     = './tutorial/data/test_1.fastq'
params.secondary   = './tutorial/data/test_2.fastq'
params.quality     = 33
params.threads     = 8
params.output      = './tutorial/results'


/* 
 * Enable/disable tasks stdout print 
 */
params.echo = true
echo params.echo



/* 
 * Since the GEM index is going to be provided as input of both tasks 'transcriptom-index' and 'rna-pipeline'
 * it is declared like a 'broadcast' list instead of a plain channel 
 */ 


index_gem = list()

task('index'){
	output 'index.gem': index_gem

	"""
	gemtools index -i ${file(params.input)} -o index.gem -t ${params.threads} 
	"""        
}


t_gem  = channel()
t_keys = channel()

task('transcriptome-index'){
	input index_gem
        output '*.junctions.gem': t_gem
        output '*.junctions.keys': t_keys

	"""	
	gemtools t-index -i ${index_gem} -a ${file(params.annotation)} -m 150 -t ${params.threads}  
	"""
}


map       = channel()
bam       = list()
bam_index = channel()

task('rna-pipeline'){
	input  index_gem
        input  t_gem
        input  t_keys
        output "*.map.gz": map
        output "*.bam": bam
        output "*.bam.bai": bam_index 

	"""	
	gemtools rna-pipeline -i ${index_gem} -a ${file(params.annotation)} -f ${file(params.primary)} ${file(params.secondary)} -r ${t_gem} -k ${t_keys} -t ${params.threads}  -q ${params.quality} --name ${params.name}
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
	cufflinks -p ${params.threads} ${bam} 
	"""
}


quantification = channel()

task('flux'){
	input bam
        output 'quantification.gtf': quantification

	"""
	flux-capacitor -i ${bam} -a ${file(params.annotation)} -o quantification.gtf --threads ${params.threads}
	"""
}


transcripts.val.copyTo(new File(params.output, 'transcripts.gtf'))

quantification.val.copyTo(new File(params.output, 'quantification.gtf'))

