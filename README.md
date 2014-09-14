Grape-NF
========

Yet another Grape pipeline implementation



Quick start 
-----------

Make sure you have all the required dependencies listed in the last section.

Install the Nextflow runtime by running the following command:

    $ curl -fsSL get.nextflow.io | bash


When done, you can launch the pipeline execution by entering the command shown below:

    $ nextflow run cbcrg/grape-nf
    

By default the pipeline is executed against the provided example dataset. 
Check the *Pipeline parameters*  section below to see how enter your data on the program 
command line.     
    


Pipeline parameters
-------------------

**--genome**  
   
* The location of the genome multi-fasta file. 
* It should end in '.fa' 
* Involved in the task: index.
  * By default is set to the Grape-NF's localization: './tutorial/data/genome_1Mbp.fa'
  `  $ nextflow run cbcrg/grape-nf --genome /home/user/my_fastas/example.fa  `
    
  

**--annotation** 
   
* Specifies the location of the genome annotation file.  
* The file must end in '.gtf'  
* Involved in the task: transcriptome-index, rna-pipeline, flux.
  * By default is set to the Grape-NF'localization: './tutorial/data/annotation.gtf' 
  `  $ nextflow run cbcrg/grape-nf --annotation /users/bm/notes.gtf  `

  
**--primary** 
   
* Specifies the location of the primary reads *fastq* file.
* Multiple files can be specified using the usual wildcards (*, ?), in this case make sure to surround the parameter string
  value by single quote characters (see the example below)
* It must end in '_1.fastq'.
* Involved in the task: rna-pipeline.
  * By default is set to the Grape-NF's location: './tutorial/data/test_1.fastq' 
  `  $ nextflow run cbcrg/grape-nf --primary '/home/dataset/*_1.fastq'`
  
  
**--secondary** 
   
* Specifies the location of the secondary reads *fastq* file.
* Multiple files can be specified using the usual wildcards (*, ?), in this case make sure to surround the parameter string
   value by single quote characters (see the example below)
* It must end in '_2.fastq'.  
* Involved in the task: rna-pipeline.  
  * By default is set to the Grape-NF's location: './tutorial/data/test_2.fastq' 
  `  $ nextflow run cbcrg/grape-nf --secondary '/home/dataset/*_2.fastq'`


**--quality** 
   
* Sets the quality offset.  
* It can be either 33 or 64  
* Involved in the task: rna-pipeline.
  * By default is set to: 33.  
  `  $ nextflow run cbcrg/grape-nf --quality 64  `


**--cpus** 
   
* Sets the number of CPUs used in every tasks (default 1).  
* Involved in the task: index, transcriptome-index, rna-pipeline, cufflinks, flux.
  * By default is set to the number of the available cores.  
  `  $ nextflow run cbcrg/grape-nf --cpus 10  `
  
  
**--output** 
   
* Specifies the folder where the results will be stored for the user.  
* It does not matter if the folder does not exist.
  * By default is set to Grape-NF's folder: './results' 
  `  $ nextflow run cbcrg/grape-nf --output /home/user/my_results  `
  
  
**--mapper** 
   
* Which mapper have to be used, you may choose between: `gem` and `tophat2`.
  * Default value: `gem`  
  `  $ nextflow run cbcrg/grape-nf --mapper tophat2  `
  
  

Run with Docker 
---------------- 

Grape-NF dependecies are also distributed by using a [Docker](http://www.docker.com) container 
which frees you from the installation and configuration of all the pieces of software required 
by Grape-NF. 

The Grape-NF Docker image is published at this address https://registry.hub.docker.com/u/cbcrg/grape-nf/

If you have Docker installed in your computer pull this image by entering the following command: 

    $ docker pull cbcrg/grape-nf
  
  
After that you will be able to run Grape-NF using the following command line: 

    $ nextflow run cbcrg/grape-nf -with-docker --mapper tophat2
  
  
Note: currently Docker based installation only support Tophat.   


Cluster support
---------------

Grape-NF execution relies on [Nextflow](http://www.nextflow.io) framework which provides an 
abstraction between the pipeline functional logic and the underlying processing system.

Thus it is possible to execute it on your computer or any cluster resource
manager without modifying it.

Currently the following clusters are supported:

  + Oracle/Univa/Open Grid Engine (SGE)
  + Platform LSF
  + SLURM
  + PBS/Torque


By default the pipeline is parallelized by spanning multiple threads in the machine where the script is launched.

To submit the execution to a SGE cluster create a file named `nextflow.config`, in the directory
where the pipeline is going to be launched, with the following content:

    task {
      processor='sge'
      queue='<your queue name>'
    }

In doing that, tasks will be executed through the `qsub` SGE command, and so your pipeline will behave like any
other SGE job script, with the benefit that *Nextflow* will automatically and transparently manage the tasks
synchronisation, file(s) staging/un-staging, etc.

Alternatively the same declaration can be defined in the file `$HOME/.nextflow/config`.

To lean more about the avaible settings and the configuration file read the Nextflow documentation 
 http://www.nextflow.io/docs/latest/config.html
  
  
Dependencies 
------------

 * Java 7+ 
 * SAMtools - http://samtools.sourceforge.net/ 
 * Cufflinks - http://cufflinks.cbcb.umd.edu/
 * GEMtools 1.7.1 - https://github.com/gemtools/gemtools
 * Flux capacitor - http://flux.sammeth.net/
 
When using *Tophat* as mapper 
  
  * Tophat2 - http://tophat.cbcb.umd.edu/
  * Bowtie2 - http://bowtie-bio.sourceforge.net/bowtie2/index.shtml


