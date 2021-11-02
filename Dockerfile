FROM continuumio/miniconda3

RUN conda install python=3.6 && \
    conda install -c conda-forge tbb=2020.2 && \
    conda install -c bioconda samtools=1.12 && \
    conda install -c bioconda cutadapt=1.18 && \
    conda install -c bioconda fastqc=0.11.9 && \
    conda install -c bioconda trim-galore=0.6.7 && \
    conda install -c bioconda bowtie2=2.3.5.1 && \
    conda install -c bioconda bismark=0.22.3 && \
    apt-get install git && \
    git clone https://github.com/jadonwagstaff/rrems

RUN mv rrems/rrems.sh usr/bin && \
    mv rrems/barcode.awk usr/bin && \
    mv rrems/countz.sh usr/bin && \
    mv rrems/colorbed.awk usr/bin

RUN chmod +rx usr/bin/rrems.sh && \
    chmod +rx usr/bin/barcode.awk && \
    chmod +rx usr/bin/countz.sh && \
    chmod +rx usr/bin/colorbed.awk