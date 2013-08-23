#!/bin/bash
#
#  Copyright (c) 2013, Centre for Genomic Regulation (CRG) and the authors 
#
#  This file is part of Grape-NF.
#
#  Grape-NF is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  Grape-NF is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with Grape-NF.  If not, see <http://www.gnu.org/licenses/>.
#

install() {

  #
  # Install missing packages 
  # 
  sudo apt-get update --fix-missing
  sudo apt-get install -y openjdk-7-jre-headless wget curl unzip
  sudo apt-get install -y samtools cufflinks

  #
  # Install GEM 
  # 
  wget -q http://barnaserver.com/gemtools/releases/GEMTools-static-core2-1.6.2.tar.gz
  tar xf GEMTools-static-core2-1.6.2.tar.gz
  printf '\n\nexport PATH=$HOME/gemtools-1.6.2-core2/bin:$PATH\n' >> ~/.profile

  #
  # Install FLUX 
  #
  wget -q http://sammeth.net/artifactory/barna/barna/barna.capacitor/1.2.4/flux-capacitor-1.2.4.tgz
  tar xf flux-capacitor-1.2.4.tgz
  printf 'export PATH=$HOME/flux-capacitor-1.2.4/bin/:$PATH\n' >> ~/.profile
  
  #
  # Install Bowtie2
  # 
  wget -q -O bowtie2-2.1.0-linux-x86_64.zip 'http://downloads.sourceforge.net/project/bowtie-bio/bowtie2/2.1.0/bowtie2-2.1.0-linux-x86_64.zip?r=http%3A%2F%2Fsourceforge.net%2Fprojects%2Fbowtie-bio%2Ffiles%2Fbowtie2%2F2.1.0%2F&ts=1375884688&use_mirror=garr'
  unzip -q bowtie2-2.1.0-linux-x86_64.zip
  printf 'export PATH=$HOME/bowtie2-2.1.0:$PATH\n' >> ~/.profile
  
  #
  # Install tophat2
  # 
  wget -q http://tophat.cbcb.umd.edu/downloads/tophat-2.0.9.Linux_x86_64.tar.gz
  tar xf tophat-2.0.9.Linux_x86_64.tar.gz 
  printf 'export PATH=$HOME/tophat-2.0.9.Linux_x86_64:$PATH\n' >> ~/.profile

  #
  # Symlink Grape files
  # 
  mkdir -p ~/grape-nf
  cd grape-nf/
  ln -s /vagrant/nextflow 
  ln -s /vagrant/tutorial/
  ln -s /vagrant/bin 
  ln -s /vagrant/grape.nf 

} 

# Exit if already bootstrapped.
test -f /etc/bootstrapped && exit

export -f install
su vagrant -c 'install'

# Mark as bootstrapped 
date > /etc/bootstrapped
