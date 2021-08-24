FROM debian:bullseye AS ahrd

RUN apt update && apt install -y --no-install-recommends \
  ant \
  default-jdk \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src/
ARG AHRD_VERSION=3.3.3
ADD https://github.com/groupschoof/AHRD/archive/v${AHRD_VERSION}.tar.gz .
RUN tar -xzf v${AHRD_VERSION}.tar.gz \
  && cd AHRD-${AHRD_VERSION} \
  && ant dist \
  && mv dist/ahrd.jar /usr/src \
  && cd .. \
  && rm -rf AHRD-${AHRD_VERSION}

FROM debian:bullseye

RUN apt update && apt install -y --no-install-recommends \
  default-jre-headless \
  hmmer \
  ncbi-blast+ \
  libxml-simple-perl \
  libyaml-libyaml-perl \
  wget \
  && rm -rf /var/lib/apt/lists/*

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# not using WORKDIR /data, as when it is set, docker2singularity creates an image with "cd WORKDIR" in the runscript
RUN mkdir /data
RUN cd /data && wget -O - https://www.arabidopsis.org/download_files/Proteins/Araport11_protein_lists/Araport11_genes.201606.pep.fasta.gz | gzip -dc > Araport11_genes.201606.pep.fasta
RUN cd /data && makeblastdb -parse_seqids -dbtype prot -taxid 3702 -in Araport11_genes.201606.pep.fasta

RUN cd /data && wget https://de.cyverse.org/anon-files/iplant/home/mtruncatula/public/Mt4.0/Annotation/Mt4.0v2/Mt4.0v2_GenesProteinSeq_20140818_1100.fasta 
RUN cd /data && makeblastdb -parse_seqids -dbtype prot -taxid 3880 -in Mt4.0v2_GenesProteinSeq_20140818_1100.fasta

RUN cd /data && wget -O - https://ftp.ncbi.nlm.nih.gov/genomes/all/annotation_releases/3847/103/GCF_000004515.5_Glycine_max_v2.1/GCF_000004515.5_Glycine_max_v2.1_protein.faa.gz | gzip -dc > GCF_000004515.5_Glycine_max_v2.1_protein.faa
RUN cd /data && makeblastdb -parse_seqids -dbtype prot -taxid 3847 -in GCF_000004515.5_Glycine_max_v2.1_protein.faa

COPY --from=ahrd /usr/src/ahrd.jar /app/
COPY add_note_attr_inGFF.pl annot.pl clean_AHRD.sh /app/
COPY conf/ /app/conf/

ENV PATH=/app/:${PATH}

ENTRYPOINT ["perl", "/app/annot.pl"]
