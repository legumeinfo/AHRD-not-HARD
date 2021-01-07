#!/usr/bin/env sh
# NAME
#     clean_AHRD.sh  - do post-processing on AHRD hash file to generate two-column 
#                      output with ID and definition
#
# SYNOPSIS
#     clean_AHRD.sh < AHRD_FILE > AHRD.slim
#
# DESCRIPTION
#     Removes some AHRD descriptive info that would not typically be in fasta definition
#     lines, and removes some information that applies to the specifically but unusefully
#     to the data sources used in this project, e.g. Medicago genomic coordinates
#
# ENVIRONMENT VARIABLES
#     none
#
# OPERANDS
#     none
#
# EXAMPLES
#        
#     $ ./clean_AHRD.sh Aradu.V14167.a1.G1.AHRD.csv > Aradu.V14167.a1.G1.AHRD.slim
#
# NOTES
#
#    Used in the peanut (Arachis duranensis and Arachis ipaensis) project.
#    Probably not applicable outside this context.
#
# SEE ALSO
#     

set -o errexit
set -o nounset

cat $1 | perl -pe 's/ \w+ \| \w+\d+:\d+-\d+ \| \d+//; s/\|\t*$//' \
     | awk -v FS="\t" -v OFS=";" 'NF>1 {print $1, "\t", $4, $5, $6}' \
     | perl -pe 's/\| //' \
     | perl -pe 's/ LENGTH=\d+//' \
     | perl -pe 's/; BEST Arabidopsis thaliana protein match is: unknown protein \.//' \
     | sed '/Human-Readable-Description/d' \
     | perl -pe 's/PREDICTED: //' \
     | perl -pe 's/ \.$//' \
     | perl -pe 's/;\t;/\t/' \
     | perl -pe 's/;;+/ ; /g' \
     | perl -pe 's/;(\w)/; $1/g' \
     | perl -pe 's/ +; *$//' \
     | perl -pe 's/[;,] *$//' \
     | perl -pe 's/ *\|;/;/g' \
     | perl -pe 's/^(\S+)\t([^\t]+)\t/$1\t$2/' \
     | perl -pe 's/^(\S+)\t([^\t]+)\t/$1\t$2/' \
     | perl -pe 's/^(\S+)\t([^\t]+)\t/$1\t$2/' \
     | perl -pe 's/^(\S+)\t([^\t]+)\t/$1\t$2/' \
     | perl -pe 's/^(\S+)\t([^\t]+)\t/$1\t$2/' \
     | perl -pe 's/^(\S+)\t([^\t]+)\t/$1\t$2/' 

