dir=hmmsearch_legfed_v1_0
mkdir -p $dir
/usr/bin/time -o ${dir}/hmmsearch.time /erdos/adf/sw/hmmer-3.1b2-linux-intel-x86_64/binaries/hmmsearch --cpu 16 --tblout ${dir}/proteins.hmmsearch.tbl $DATA/public/Gene_families/legume.genefam.fam1.M65K/legfed_v1_0.hmm $1 2> ${dir}/hmmsearch.err | gzip -c > ${dir}/proteins.hmmsearch.tbl.gz
