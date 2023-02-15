# AHRD-not-HARD
a bit of wrapper for running the [AHRD](https://github.com/groupschoof/AHRD) analysis from [tripal_funnotate](https://github.com/legumeinfo/tripal_funnotate) in "standalone" mode (ie not via the web interface)


## Installation/Usage (Singularity Container)

1. Clone this git repository.

2. (optional) Modify the Singularity definition file (singularity.def) to download/build BLAST databases for the desired reference proteins, and the AHRD YAML configuration file generated in annot.pl to utilize the desired reference proteins.

3. Build the Singularity image:

```sh
singularity build [--remote] ahrd-not-hard_<MY_VERSION>.sif singularity.def
```

4. Run the workflow in a Singularity container.

e.g., given the input protein FASTA file prot.fa:

```sh
$ mkdir output
$ singularity run --cleanenv ahrd-not-hard_<MY_VERSION>.sif output/myprot prot.fa
...
Result: output/myprot.results.tbl
```

## Environment Variables

* **ANNOT_BLAST_THREADS**: `blastp -num_threads` value
* **ANNOT_BLAST_EVALUE**: `blastp -evalue` value (default 1E-3)

Examples:

```sh
singularity run --cleanenv --env ANNOT_BLAST_THREADS=8 ...
```
