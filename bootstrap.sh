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
  sudo apt-get install -y openjdk-7-jre-headless wget
  sudo apt-get install -y samtools cufflinks

  #
  # Install GEM 
  # 
  wget -q http://barnaserver.com/gemtools/releases/GEMTools-static-core2-1.6.1.tar.gz
  tar xf GEMTools-static-core2-1.6.1.tar.gz
  printf '\n\nexport PATH=$HOME/gemtools-1.6.1-core2/bin:$PATH\n' >> ~/.profile

  #
  # Install FLUX 
  #
  wget -q http://sammeth.net/artifactory/barna/barna/barna.capacitor/1.2.3/flux-capacitor-1.2.3.tgz
  tar xf flux-capacitor-1.2.3.tgz
  printf 'export PATH=$HOME/flux-capacitor-1.2.3/bin/:$PATH\n' >> ~/.profile

  #
  # Symlink Grape files
  # 
  mkdir -p ~/grape-nf
  cd grape-nf/
  ln -s /vagrant/nextflow 
  ln -s /vagrant/nextflow.config 
  ln -s /vagrant/tutorial/
  ln -s /vagrant/grape.nf 

} 

# Exit if already bootstrapped.
test -f /etc/bootstrapped && exit

export -f install
su vagrant -c 'install'

# Mark as bootstrapped 
date > /etc/bootstrapped
