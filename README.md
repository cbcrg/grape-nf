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
See the section *pipeline parameters* below to see how enter your data on the program command line.     
    

Run using Vagrant
-----------------

To avoid having to install all the pipeline dependencies, you may test the pipeline using 
the provided Vagrant VM, which downloads and configures all the required pieces 
of software for you. See http://www.vagrantup.com for more details about Vagrant.

The Vagrant environment uses the Ubuntu Precise 64 virtual machine, if you don't have it 
in your Vagrant boxes list, just add it with the following command: 

    $ vagrant box add precise64 http://files.vagrantup.com/precise64.box 
    

When done, move in the pipeline root folder `grape-nf` and enter the following command
to launch the VM:
  
    $ vagrant up 


When it boots up and the configuration steps are terminated, login into the VM instance 
and move to the Grape pipeline folder 

    $ vagrant ssh 
    $ cd grape-nf
    
Now you can launch the pipeline as shown: 

	 $ ./nextflow grape.nf



When finished, stop the VM using the command `vagrant halt` or `vagrant destroy`, depending if you
want temporary stop the execution or remove completely remove the VM. 


Pipeline parameters
-------------------

**--genome**  
   
* The location of the genome multi-fasta file. 
* It should end in '.fa' 
* Involved in the task: index.
  * By default is set to the Grape-NF's localization: './tutorial/data/genome_1Mbp.fa'
  `  $ ./nextflow grape.nf --genome=/home/user/my_fastas/example.fa  `  
    
  

**--annotation** 
   
* Specifies the location of the genome annotation file.  
* The file must end in '.gtf'  
* Involved in the task: transcriptome-index, rna-pipeline, flux.
  * By default is set to the Grape-NF'localization: './tutorial/data/annotation.gtf' 
  `  $ ./nextflow grape.nf --annotation=/users/bm/notes.gtf  `  

  
**--primary** 
   
* Specifies the location of the primary reads *fastq* file.  
* It must end in '_1.fastq'.  
* Involved in the task: rna-pipeline.
  * By default is set to the Grape-NF's location: './tutorial/data/test_1.fastq' 
  `  $ ./nextflow grape.nf --primary=/home/ignacio/genome_1.fastq  `  
  
  
**--secondary** 
   
* Specifies the situation of the secondary reads *fastq* file.  
* It must end in '_2.fastq'.  
* Involved in the task: rna-pipeline.  
  * By default is set to the Grape-NF's location: './tutorial/data/test_2.fastq' 
  `  $ ./nextflow grape.nf --secondary=./example_2.fastq  `  


**--quality** 
   
* Sets the quality offset.  
* It can be either 33 or 64  
* Involved in the task: rna-pipeline.
  * By default is set to: 33.  
  `  $ ./nextflow grape.nf --quality=64  `  


**--cpus** 
   
* Sets the number of CPUs used in every tasks. All of them will handle the same number.  
* It depends on the number of processors of your computer.  
* Involved in the task: index, transcriptome-index, rna-pipeline, cufflinks, flux.
  * By default is set to the number of the available cores.  
  `  $ ./nextflow grape.nf --cpus=2  `  
  
  
**--output** 
   
* Specifies the folder where the results will be stored for the user.  
* It does not matter if the folder does not exist.
  * By default is set to Grape-NF's folder: './results' 
  `  $ ./nextflow grape.nf --output=/home/user/my_results  `  
  
  
**--echo** 
   
* Enables or disables the tasks stdout print.
  * By default is set to true.  
  `  $ ./nextflow grape.nf --echo=false  `  
  
  
Dependencies 
------------

 * Java 6+ 
 * SAMtools - http://samtools.sourceforge.net/ 
 * Cufflinks - http://cufflinks.cbcb.umd.edu/
 * GEM library - http://algorithms.cnag.cat/wiki/The_GEM_library
 * Flux capacitor - http://flux.sammeth.net/



