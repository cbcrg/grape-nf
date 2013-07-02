#!/usr/bin/env nextflow

params.input       = './tutorial/data/genome_1Mbp.fa'
params.name        = 'genome'
params.annotation  = './tutorial/data/annotation.gtf'
params.primary     = './tutorial/data/test_1.fastq'
params.secondary   = './tutorial/data/test_2.fastq'
params.quality     = 33
params.threads     = 8
params.output      = './tutorial/results'

echo true


index_gem = list()

task('index'){
	output 'index.gem': index_gem

	"""
	gemtools index -i ${file(params.input)} -o index.gem -t ${params.threads} 
	"""        
}


t_gem  = list()
t_keys = list()

task('t-index'){
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

