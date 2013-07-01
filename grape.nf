#!/usr/bin/env nextflow

params.inputFolder='./tutorial/data'
params.input='./tutorial/data/genome_1Mbp.fa'
params.annotation='./tutorial/data/annotation.gtf'
params.output_dir='./tutorial/results'
params.name='annotation'
params.tt_index='./tutorial/data/annotation.gtf'

params.primary='./tutorial/data/test_1.fastq'
params.secondary='./tutorial/data/test_2.fastq'
params.quality=33


inputFile      = file(params.input)
annotationFile = file(params.annotation)
primaryFile    = file(params.primary)
secondaryFile  = file(params.secondary)
quality        = params.quality


index_gem = list()

echo true

task('index'){
	input  inputFile
	output 'index.gem': index_gem

	"""
	gemtools index -i ${inputFile} -o index.gem -t 8 
	"""        
}

t_gem = channel()
t_keys = channel()

task('t-index'){
	input index_gem
	input annotationFile
        output '*.junctions.gem': t_gem
        output '*.junctions.keys': t_keys

	"""	
	gemtools t-index -i ${index_gem} -a ${annotationFile} -m 150 -t 8 
	"""
}

map = channel()
bam = list()
bam_index = channel()

task('rna-pipeline'){
	input  index_gem
        input  t_gem
        input  t_keys
	input  annotationFile
	input  primaryFile
	input  secondaryFile
	input  quality
        output "*.map.gz": map
        output "*.bam": bam
        output "*.bam.bai": bam_index 
	
	"""	
	gemtools rna-pipeline -i ${index_gem} -a ${annotationFile} -f ${primaryFile} ${secondaryFile} -r ${t_gem} -k ${t_keys} -t 8 -q ${quality} --name ${params.name}
	"""
}

transcripts = channel()
isoforms = channel()
genes = channel()

task('cufflinks'){
	input bam
	output 'transcripts.gtf': transcripts
	output 'isoforms.fpkm_tracking': isoforms
	output 'genes.fpkm_tracking': genes

	"""
	cufflinks -p 8 ${bam} 
	"""
}

quantification = channel()

task('flux'){
	input bam
	input transcripts
	input annotationFile
        output 'quantification.gtf': quantification

	"""
	flux-capacitor -i ${bam} -a ${annotationFile} -o quantification.gtf --threads 8
	"""
}
