export PATH=/erdos/adf/sw/jdk1.7.0/bin:$PATH
if [[ ! -n $JOB_LIMIT ]]; then JOB_LIMIT=20; fi
for f in *xml; do 
	while (( `jobs | wc -l` >= $JOB_LIMIT )); do sleep 1; done
	/erdos/adf/sw//interproscan-5.3-46.0/interproscan.sh -i $f -mode convert -f RAW &
done
