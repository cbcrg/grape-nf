#!/usr/bin/env nextflow

params.genome='./tutorial/data/genome_1Mbp.fa'
params.annotation='./tutorial/data/annotation.gtf'
params.name='genname'
params.primary='./tutorial/data/test_1.fastq'
params.secondary='./tutorial/data/test_2.fastq'
params.quality=33

/* 
 * Enable/disable tasks stdout print 
 */
params.echo = true
echo params.echo


inputFile      = file(params.genome)
annotationFile = file(params.annotation)
primaryFile    = file(params.primary)
secondaryFile  = file(params.secondary)

/* 
 * Since the GEM index is going to be provided as input of both tasks 'transcriptom-index' and 'rna-pipeline'
 * it is declared like a 'broadcast' list instead of a plain channel 
 */ 
index_gem = list()

task('index'){
	input  inputFile
	output 'index.gem': index_gem

	"""
	gemtools index -i ${inputFile} -o index.gem -t 1 
	"""        
}

t_gem = channel()
t_keys = channel()

task('transcriptome-index'){
	input index_gem
	input annotationFile
        output '*.junctions.gem': t_gem
        output '*.junctions.keys': t_keys

	"""	
	gemtools t-index -i ${index_gem} -a ${annotationFile} -m 150 -t 1 
	"""
}

map = channel()
bam = list()
bam_index = channel()

task('rna-pipeline'){
	input  index_gem
	input  annotationFile
	input  primaryFile
	input  secondaryFile
        input  t_gem
        input  t_keys

        output "*.map.gz": map
        output "*.bam": bam
        output "*.bam.bai": bam_index 
	
	"""	
	gemtools rna-pipeline -i ${index_gem} -a ${annotationFile} -f ${primaryFile} ${secondaryFile} -r ${t_gem} -k ${t_keys} -t 1 -q ${params.quality} --name ${params.name}
	"""
}


quantification = channel()

task('flux'){
	input bam
	input annotationFile
        output 'quantification.gtf': quantification

	"""
	flux-capacitor -i ${bam} -a ${annotationFile} -o quantification.gtf
	"""
}
