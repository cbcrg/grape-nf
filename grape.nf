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
import org.apache.commons.lang.StringUtils

/* 
 * Main Grape-NF pipeline script
 *
 * @authors
 * Beatriz M. San Juan <bmsanjuan@gmail.com> 
 * Paolo Di Tommaso <paolo.ditommaso@gmail.com>
 * Pablo Prieto <poena.funesta@gmail.com> 
 * Miquel Orobitg <miquel.orobitg@crg.es> 
 * Emilio Palumbo <emiliopalumbo@gmail.com> 
 */


params.genome      = "$baseDir/tutorial/ggal/ggal_1_48850000_49020000.Ggal71.500bpflank.fa"
params.name        = "genome"
params.annotation  = "$baseDir/tutorial/ggal/ggal_1_48850000_49020000.bed.gff"
params.primary     = "$baseDir/tutorial/ggal/ggal_test_1.fq"
params.secondary   = "$baseDir/tutorial/ggal/ggal_test_2.fq"
params.mapper      = "gem"
params.quality     = 33
params.cpus        = 1
params.output      = "results/"


log.info "G R A P E - N F  ~  version 1.5.1"
log.info "================================="
log.info "name               : ${params.name}"
log.info "genome             : ${params.genome}"
log.info "annotation         : ${params.annotation}"
log.info "primary            : ${params.primary}"
log.info "secondary          : ${params.secondary}"
log.info "quality            : ${params.quality}"
log.info "output             : ${params.output}"
log.info "mapper             : ${params.mapper}"
log.info "cpus               : ${params.cpus}"
log.info "poolSize           : ${config.poolSize}"
log.info "\n"


/*
 * Input parameters validation
 */

if( !(params.mapper in ['gem','tophat2'])) { exit 1, "Invalid mapper tool: '${params.mapper}'" }

genome_file = file(params.genome)
annotation_file = file(params.annotation)
primary_reads = files(params.primary).sort()
secondary_reads = files(params.secondary).sort()
result_path = file(params.output)

/*
 * validate input files
 */
if( !genome_file.exists() ) exit 1, "Missing genome file: ${genome_file}"
if( !annotation_file.exists() ) exit 2, "Missing annotatio file: ${annotation_file}"

if( !result_path.exists() && !result_path.mkdirs() ) {
    exit 3, "Cannot create output folder: $result_path -- Check file system access permission"
}

/*
 * validate read pairs
 */

read_names = []

len = primary_reads.size()
if ( len == 0 ) exit 4, "You have specified an empty read pairs sets -- primary ${params.primary} ~ secodary: ${params.secondary} "
if ( len != secondary_reads.size() ) exit 5, "Primary and secondary read pairs do not match"

if( len == 1 ) {
    if ( !primary_reads[0].exists() ) exit 6, "Primary read file do not exist: ${params.primary}"
    if ( !secondary_reads[0].exists() ) exit 6, "Secondary read file do not exist: ${params.secondary}"

    def (name, err) = bestMatch( primary_reads[0], secondary_reads[0] )
    if ( err ) exit 7, err
    read_names << name

}
else {
    primary_reads.sort()
    secondary_reads.sort()
    for( int i=0; i<len; i++ ) {
        def (name, err) = bestMatch( primary_reads[i], secondary_reads[i], false )
        if ( err ) { exit 8, err }
        if ( read_names.contains(name) ) exit 9, "Duplicate read pair name in you dataset: '$name'"
        read_names << name
    }
}

log.info "Read pairs: $read_names"
log.debug "Primary reads: ${primary_reads *. name }"
log.debug "Secondary reads: ${secondary_reads *. name }"


process index {
    input:
    file genome_file
    
    output:
    file 'genome.index*' into genome_index
      
    script:
    //
    // GEM tools mapper
    //
    if( params.mapper=='gem' )
        """
        gemtools index -i ${genome_file} -o index.gem -t ${params.cpus}
        mv index.gem genome.index
        """

    //
    // Bowtie + Tophat 2
    //
    else if( params.mapper == 'tophat2' )
        """
        bowtie2-build ${genome_file} genome.index
        """

}


process mapping {
    scratch false
    
    input:
    file genome_file
    file annotation_file 
    file genome_index from genome_index.first()
    file primary_reads
    file secondary_reads
    val read_names

    output:
    file "*.bam" into bam

    
    script:
    bam_name = "${params.name}_${read_names}"

    //
    // GEM tools mapper
    //

    if( params.mapper == 'gem' )
        """
        # note: it requires the index file name ending with '.gem' suffix
        ln -s genome.index index.gem
        gemtools t-index -i index.gem -a ${annotation_file} -m 150 -t ${params.cpus}
        gemtools rna-pipeline -i index.gem -a ${annotation_file} -f ${primary_reads} ${secondary_reads} -t ${params.cpus} -q ${params.quality} --name ${bam_name} -r *.junctions.gem -k *.junctions.keys
        rm *.filtered.bam
        """

    //
    // Bowtie + Tophat 2
    //
    else if( params.mapper == 'tophat2' ) {
        qual = params.quality == '64' ? '--phred64-quals' : ''
        """
        tophat2 -p ${params.cpus} --splice-mismatches 1 ${qual} --GTF ${annotation_file} genome.index ${primary_reads} ${secondary_reads}
        mv tophat_out/accepted_hits.bam ${bam_name}.bam
        """
    }
}


/*
 * fork the 'bam' channel into three channels
 */
(bam1, bam2, bam3) = bam.into(3)

/*
 * Execute cufflinks against the BAMs provided by the channel 'bam1'
 */
process cufflinks {
    input:
    file bam1
    
    output:
    file '*.transcripts.gtf' into transcripts

    """
    # Extract the file name w/o the extension
    fileName=\$(basename "${bam1}")
    baseName="\${fileName%.*}"

     cufflinks -p ${params.cpus} ${bam1}

    # rename to target name including the 'bam' name
    mv transcripts.gtf \$baseName.transcripts.gtf
    """
}


process flux {
    input:
    file bam2
    file annotation_file
    
    output:
    file '*.quantification.gtf' into quantification

    """
    # Extract the file name w/o the extension
    fileName=\$(basename "${bam2}")
    baseName="\${fileName%.*}"

    flux-capacitor -i ${bam2} -a ${annotation_file} -o \$baseName.quantification.gtf --threads ${params.cpus}
    """
}


/*
 * producing output files
 */
bam3.subscribe { it ->
    log.info "Copying BAM file to results: ${result_path}/${it.name}"
    it.copyTo(result_path)
    }

quantification.subscribe { it ->
    log.info "Copying quantification file (flux) to results: ${result_path}/${it.name}"
    it.copyTo(result_path)
    }

transcripts.subscribe { it ->
    log.info "Copying transcripts file (cufflinks) to results folder: ${result_path}/${it.name}"
    it.copyTo(result_path)
    }

// ===================== UTILITY FUNCTIONS ============================


/*
 * Given a path returns a sorted list files matching it.
 * The path can contains wildcards characters '*' and '?'
 */
def List<Path> findReads( String fileName ) {
    def result = []
    if( fileName.contains('*') || fileName.contains('?') ) {
        def path = file(fileName)
        def parent = path.parent
        def filePattern = path.getName().replace("?", ".?").replace("*", ".*")
        parent.eachFileMatch(~/$filePattern/) { result << it }
        result = result.sort()
    }
    else {
        result << file(fileName)
    }

    return result
}

def bestMatch( Path file1, Path file2, boolean singlePair = true) {
    bestMatch( file1.baseName, file2.baseName, singlePair )
}

def bestMatch( String n1, String n2, boolean singlePair = true) {

    def index = StringUtils.indexOfDifference(n1, n2)

    if( !singlePair ) {
        if( index == -1 ) {
            // this mean the two file names are identical, something is wrong
            return [null, "Missing entry for read pair: '$n1'"]
        }
        else if( index == 0 ) {
            // this mean the two file names are completely different
            return [null, "Not a valid read pair -- primary: $n1 ~ secondary: $n2"]
        }
    }

    String match = index ? n1.subSequence(0,index) : n1
    match = trimReadName(match)
    if( !match ) {
        return [null, "Missing common name for read pair -- primary: $n1 ~ secondary: $n2 "]
    }

    return [match, null]

}

def trimReadName( String name ) {
    name.replaceAll(/^[^a-zA-Z]*/,'').replaceAll(/[^a-zA-Z]*$/,'')
}


// ===================== UNIT TESTS ============================

def testFindReads() {

    def path = File.createTempDir().toPath()
    try {
        def file1 = path.resolve('alpha_1.fastq'); file1.text = 'file1'
        def file2 = path.resolve('alpha_2.fastq'); file2.text = 'file2'
        def file3 = path.resolve('gamma_1.fastq'); file3.text = 'file3'
        def file4 = path.resolve('gamma_2.fastq'); file4.text = 'file4'

        assert files("$path/alpha_1.fastq") == [file1]
        assert files("$path/*_1.fastq") == [file1, file3]
        assert files("$path/*_2.fastq") == [file2, file4]
    }
    finally {
        path.deleteDir()
    }

}

def testTrimReadName() {
    assert trimReadName('abc') == 'abc'
    assert trimReadName('a_b_c__') == 'a_b_c'
    assert trimReadName('__a_b_c__') == 'a_b_c'
}

def testBestMach() {

    assert bestMatch('abc_1', 'abc_2') == ['abc', null]
    assert bestMatch('aaa', 'bbb') == ['aaa', null]
    assert bestMatch('_', 'bbb') == [null, "Missing common name for read pair -- primary: _ ~ secondary: bbb "]

    assert bestMatch('abc_1', 'abc_2', false) == ['abc', null]
    assert bestMatch('aaa', 'bbb', false) == [null, 'Not a valid read pair -- primary: aaa ~ secondary: bbb' ]

}
