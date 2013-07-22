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
import org.apache.commons.lang.StringUtils

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
params.loglevel = 'warn'


/*
 * Input parameters validation
 */

File genome_file = file(params.genome)
File annotation_file = file(params.annotation)
File result_path = file(params.output)
primary_reads = findReads(params.primary?.toString())
secondary_reads = findReads(params.secondary?.toString())

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

/* 
 * Since the GEM index is going to be provided as input of both tasks 'transcript-index' and 'rna-pipeline'
 * it is declared like a 'broadcast' list instead of a plain channel 
 */ 


index_gem = channel()

task('index'){
    input genome_file
    output 'index.gem': index_gem

    """
    gemtools --loglevel ${params.loglevel} index -i ${genome_file} -o index.gem -t ${params.cpus} --no-hash
    """
}

index_gem_file = read(index_gem)

t_gem  = channel()
t_keys = channel()

task('transcript-index'){
    input index_gem_file
    output '*.junctions.gem': t_gem
    output '*.junctions.keys': t_keys

    """
    gemtools --loglevel ${params.loglevel} t-index -i ${index_gem_file} -a ${annotation_file} -m 150 -t ${params.cpus}
    """
}


bam       = channel()
map       = channel()
t_gem_file = read(t_gem)
t_keys_file = read(t_keys)

task('rna-pipeline'){
    input annotation_file
    input read_names
    input primary_reads
    input secondary_reads
    input index_gem_file
    input t_gem_file
    input t_keys_file
    
    output "*.map.gz": map
    output "*.bam": bam

    """
    gemtools --loglevel ${params.loglevel} rna-pipeline \\
        -i ${index_gem_file} \\
        -a ${annotation_file} \\
        -f ${primary_reads} ${secondary_reads} \\
        -r ${t_gem_file} \\
        -k ${t_keys_file} \\
        -t ${params.cpus} \\
        -q ${params.quality} \\
        --name ${params.name}_${read_names}

    # Create a link to the created BAM files into the result folder
    BAM=${params.name}_${read_names}.bam
    BAI=${params.name}_${read_names}.bam.bai
    cd ${result_path}
    rm -f \$BAM && ln -s \$OLDPWD/\$BAM
    rm -f \$BAI && ln -s \$OLDPWD/\$BAI
    cd -
    """
}


transcripts = channel()
bam1 = channel()
bam2 = channel()
splitter ( bam, [bam2, bam1] )

task('cufflinks'){
    input bam1
    output '*.transcripts.gtf': transcripts

    """
    # Extract the file name w/o the extension
    fileName=\$(basename "${bam1}")
    baseName="\${fileName%.*}"

    cufflinks -p ${params.cpus} ${bam1}

    # rename to target name including the 'bam' name
    mv transcripts.gtf \$baseName.transcripts.gtf
    """
}


quantification = channel()

task('flux'){
    input bam2
    input annotation_file
    output '*.quantification.gtf': quantification

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
quantification.each { File it -> copyToResults(it, result_path) }
transcripts.each { File it -> copyToResults(it, result_path) }


// ===================== UTILITY FUNCTIONS ============================


/*
 * Copy the 'source' file to the result folder.
 * Note: when a file with the same name as the target already exists, it will be deleted
 */
def copyToResults( File source, File resultPath )  {
    def target = new File(resultPath, source.name);
    log.info "Copying file to results: ${target}"

    if(target.exists()) { target.delete()  }
    source.copyTo(target)
}


/*
 * Given a path returns a sorted list files matching it.
 * The path can contains wildcards characters '*' and '?'
 */
def List<File> findReads( String fileName ) {
    def result = []
    if( fileName.contains('*') || fileName.contains('?') ) {
        def path = new File(fileName).absoluteFile
        def parent = path.parentFile
        def filePattern = path.name.replace("?", ".?").replace("*", ".*?")
        parent.eachFileMatch(~/$filePattern/) { result << it }
        result = result.sort()
    }
    else {
        result << new File(fileName).absoluteFile
    }

    return result
}

def bestMatch( File file1, File file2, boolean singlePair = true) {
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

    def path = File.createTempDir()
    try {
        def file1 = new File(path, 'alpha_1.fastq'); file1.text = 'file1'
        def file2 = new File(path, 'alpha_2.fastq'); file2.text = 'file2'
        def file3 = new File(path, 'gamma_1.fastq'); file3.text = 'file3'
        def file4 = new File(path, 'gamma_2.fastq'); file4.text = 'file4'

        assert findReads("$path/alpha_1.fastq") == [file1]
        assert findReads("$path/*_1.fastq") == [file1, file3]
        assert findReads("$path/*_2.fastq") == [file2, file4]
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
