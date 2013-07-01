input='./data/chr21.fa'
annotation='./data/chr21.gtf'
output_dir='./results'
name='chr21.gtf'
#index="${output_dir}/chr21.gem"
index="./data/chr21.gem"
#tt_index="${output_dir}/chr21.gtf"
tt_index="./data/chr21.gtf"


primary="./data/chr21.fa"
secondary="./data/chr21.fa"
quality=33
name="chr21"

`mkdir -p ${output_dir}`


#
# GEM index
# 
#  outputs = {
#        "gem": "${output_dir}/${name}.gem",
#    }
#
#  gemtools index -i ${input} -o ${index} -t 1
#
gemtools index -i ${input} -o ${index} -t 1

#
# GEM t-index
#
#   outputs = {
#        "gem": "${output_dir}/${name}.junctions.gem",
#        "keys": "${output_dir}/${name}.junctions.keys"
#    }
#
#    gemtools t-index -i ${index} -a ${annotation} -m 150 -t 1 -o ${output_dir}/${name}
#
gemtools t-index -i ${index} -a ${annotation} -m 150 -t 1 -o ${tt_index}


#
# GEM
#
#     outputs = {
#        "map": "${output_dir}/${name}.map.gz",
#        "bam": "${output_dir}/${name}.bam",
#        "bamindex": "${output_dir}/${name}.bam.bai",
#	}
# 
gemtools rna-pipeline -i ${index} -a ${annotation} -f ${primary} ${secondary} -t 1 -q ${quality} -o ${output_dir} --name ${name}

# 
# Flux
#
#    outputs = {
#        "gtf": "${output_dir}/${name}.gtf",
#    }
#
# 
#flux-capacitor -i ${input} -o ${output_dir}/${name}.gtf -a ${annotation} \
