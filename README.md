Grape-NF
========

Yet another Grape pipeline implementation



Quick start 
-----------

Clone the git repository on your computer with the following command:

    $ git clone git@github.com:cbcrg/grape-nf.git
    

Make sure you have installed the required dependencies listed below, or just 
use the self-configured Vagrant VM. 


When done, move in the project root folder just created `grape-nf`, 
it contains an example dataset in the `tutorial` folder. 

Launch the pipeline execution by entering the following command 
on your shell terminal:

    $ ./nextflow grape.nf
    

Run into the Vagrant VM
-----------------------

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

    
Dependencies 
------------

 * Java 6+ 
 * SAMtools - http://samtools.sourceforge.net/ 
 * Cufflinks - http://cufflinks.cbcb.umd.edu/
 * GEM library - http://algorithms.cnag.cat/wiki/The_GEM_library
 * Flux capacitor - http://flux.sammeth.net/



