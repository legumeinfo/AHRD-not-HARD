# AHRD-not-HARD
a bit of wrapper for running the [AHRD](https://github.com/groupschoof/AHRD) analysis from [tripal_funnotate](https://github.com/legumeinfo/tripal_funnotate) in "standalone" mode (ie not via the web interface)


## Installation/Usage (Docker Container)

1. (optional) Modify the Dockerfile to download/build BLAST databases for the desired reference proteins, and the AHRD YAML configuration file generated in annot.pl to utilize the desired reference proteins.

2. Build the Docker image:

```sh
docker build -t ahrd-not-hard .
```

3. Run the workflow in a container:

e.g., given the input protein FASTA file prot.fa:

```sh
$ mkdir output
$ docker run -it --rm -v $PWD:/mnt -w /mnt ahrd-not-hard output/myprot prot.fa
...
Result: output/myprot.results.tbl
```

Optionally, specify a GFF file to annotate.
A "Note" attribute will be added to the 9th column of gene features in the output GFF.

```sh
$ mkdir output
$ docker run -it --rm -v $PWD:/mnt -w /mnt ahrd-not-hard output/myprot prot.fa genes.gff
...
Result: output/myprot.results.tbl
Annotated GFF: output/myprot.gff
```

*Note that the gene feature ID values in the GFF must match the seqids in the protein FASTA file.*

## Installation/Usage (Singularity Container)

1. Follow the instructions to build a Docker container image

2. Generate a Singularity container image using [docker2singularity](https://github.com/singularityhub/docker2singularity):

```sh
$ docker run -v /var/run/docker.sock:/var/run/docker.sock -v /tmp/singularity:/output --privileged -t --rm quay.io/singularity/docker2singularity:v3.7.0 ahrd-not-hard
```

The resulting SIF file can be moved from /tmp/singularity/ahrd-not-hard-YYYY-MM-DD-HASH.sif to the desired location.

3. Execute the Singularity image:

```sh
$ mkdir output
$ singularity run --cleanenv ahrd-not-hard-2020-12-31-3fc4eeb9aa0e.sif output/myprot prot.fa genes.gff
```

## Environment Variables

* **ANNOT_BLAST_THREADS**: `blastp -num_threads` value
* **ANNOT_BLAST_EVALUE**: `blastp -evalue` value (default 1E-3)

Examples:

```sh
docker run -e ANNOT_BLAST_EVALUE=1E-5 ...
```

```sh
singularity run --cleanenv --env ANNOT_BLAST_THREADS=8 ...
```
