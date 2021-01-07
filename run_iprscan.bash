#!/bin/bash
#$ -V                      #Inherit the submission environment
#$ -cwd                    # Start job in submission directory#$ -cwd
#does this need to be an export? is throwing an error when submitted as
#qsub -pe smp 4 /home/analysis/adf/LIS/run_iprscan.bash /home/analysis/adf/LIS/AHRD_testing/testing/adf_writeable/BGI/Aradu_chunks/$f
#export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/sw/gcc/4.8.2/lib64/
export PATH=/erdos/adf/sw/jdk1.7.0/bin:$PATH
/erdos/adf/sw/interproscan-5.3-46.0/interproscan.sh --disable-precalc -i $1 -b `basename $1`.iprscan
