Grape-NF
========

Yet another Grape pipeline implementation



Quick start 
-----------

Clone the git repository on your computer with the following command:

    $ git clone git@github.com:cbcrg/grape-nf.git
    

Make sure you have installed the required dependencies listed below, or just 
use the self-configured Vagrant VM. 


When done, move in the project root folder named `grape-nf`, 
which contains an example dataset in the `tutorial` folder. 

Launch the pipeline by entering the following command 
on your shell terminal:

    $ ./nextflow grape.nf
    

By default the pipeline is executed against the provided tutorial dataset. 
Check the *Pipeline parameters*  section below to see how enter your data on the program command line.     
    

Run using Vagrant
-----------------

To avoid having to install all the pipeline dependencies, you may test the pipeline using 
the provided Vagrant VM, which downloads and configures all the required pieces 
of software for you. See http://www.vagrantup.com for more details about Vagrant.

The Vagrant environment uses the Ubuntu Precise 64 virtual machine, if you don't have it 
in your Vagrant boxes list, it will be downloaded automatically. 

To launch the VM move to the pipeline root folder `grape-nf` and enter the following command:
  
    $ vagrant up 


When it boots up and the configuration steps are terminated, login into the VM instance 
and move to the Grape pipeline folder 

    $ vagrant ssh 
    $ cd grape-nf
    
Now you can launch the pipeline as shown: 

	 $ ./nextflow grape.nf



When finished, stop the VM using the command `vagrant halt` or `vagrant destroy`, depending if you
want to temporary stop the execution or delete permanently the VM with all its files. 


Pipeline parameters
-------------------

**--genome**  
   
* The location of the genome multi-fasta file. 
* It should end in '.fa' 
* Involved in the task: index.
  * By default is set to the Grape-NF's localization: './tutorial/data/genome_1Mbp.fa'
  `  $ ./nextflow grape.nf --genome /home/user/my_fastas/example.fa  `
    
  

**--annotation** 
   
* Specifies the location of the genome annotation file.  
* The file must end in '.gtf'  
* Involved in the task: transcriptome-index, rna-pipeline, flux.
  * By default is set to the Grape-NF'localization: './tutorial/data/annotation.gtf' 
  `  $ ./nextflow grape.nf --annotation /users/bm/notes.gtf  `

  
**--primary** 
   
* Specifies the location of the primary reads *fastq* file.
* Multiple files can be specified using the usual wildcards (*, ?), in this case make sure to surround the parameter string
  value by single quote characters (see the example below)
* It must end in '_1.fastq'.
* Involved in the task: rna-pipeline.
  * By default is set to the Grape-NF's location: './tutorial/data/test_1.fastq' 
  `  $ ./nextflow grape.nf --primary '/home/dataset/*_1.fastq'`
  
  
**--secondary** 
   
* Specifies the location of the secondary reads *fastq* file.
* Multiple files can be specified using the usual wildcards (*, ?), in this case make sure to surround the parameter string
   value by single quote characters (see the example below)
* It must end in '_2.fastq'.  
* Involved in the task: rna-pipeline.  
  * By default is set to the Grape-NF's location: './tutorial/data/test_2.fastq' 
  `  $ ./nextflow grape.nf --secondary '/home/dataset/*_2.fastq'`


**--quality** 
   
* Sets the quality offset.  
* It can be either 33 or 64  
* Involved in the task: rna-pipeline.
  * By default is set to: 33.  
  `  $ ./nextflow grape.nf --quality 64  `


**--cpus** 
   
* Sets the number of CPUs used in every tasks (default 1).  
* Involved in the task: index, transcriptome-index, rna-pipeline, cufflinks, flux.
  * By default is set to the number of the available cores.  
  `  $ ./nextflow grape.nf --cpus 10  `
  
  
**--output** 
   
* Specifies the folder where the results will be stored for the user.  
* It does not matter if the folder does not exist.
  * By default is set to Grape-NF's folder: './results' 
  `  $ ./nextflow grape.nf --output /home/user/my_results  `
  
  
**--mapper** 
   
* Which mapper have to be used, you may choose between: `gem` and `tophat2`.
  * Default value: `gem`  
  `  $ ./nextflow grape.nf --mapper tophat2  `
  
Dependencies 
------------

 * Java 6+ 
 * SAMtools - http://samtools.sourceforge.net/ 
 * Cufflinks - http://cufflinks.cbcb.umd.edu/
 * GEM library - http://algorithms.cnag.cat/wiki/The_GEM_library
 * Flux capacitor - http://flux.sammeth.net/
 
When using *Tophat* as mapper 
  
  * Tophat2 - http://tophat.cbcb.umd.edu/
  * Bowtie2 - http://bowtie-bio.sourceforge.net/bowtie2/index.shtml


