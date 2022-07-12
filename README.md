# DNBSEQ_C4_3end-RNA-seq-data-analysis-pipeline
## 1. Introduction

This is an open source pipeline used for the QC and analysis of 3end RNA-seq data. It is adjusted from the original version of DNBelab C Series Single-Cell RNA Analysis pipeline released by MGI-tech-bioinformatics (https://github.com/MGI-tech-bioinformatics/DNBelab_C_Series_scRNA-analysis-software) and the docker/singularity version is released by MGI-EU(https://github.com/MGI-EU/Docker-image-of-DNBelabC4_scRNA-analysis).

### 1.1 Purpose

- An open source and flexible pipeline to analyze the raw fastq files generated using 3'end RNA-seq platforms;
- One-step execution with or without docker. 

### 1.2 Workflow

![workflow](https://github.com/MGI-EU/DNBSEQ_C4_3end-RNA-seq-data-analysis-pipeline/blob/main/3end-RNA-seq_workflow.jpg)

## 2. Overview

### 2.1 Demo

#### 2.1.1 Demo data

Here we will provide a demo data for testing, the demo data is not avaliable now, but will be uploaded soon. 

#### 2.1.2 Demo execution

run with docker:

step1: check config.json files

```shell
cat config.json
{
    "main.fastq1": "/tmp/C4_3endRNAseq/rawfq/Demo_1.fq.gz",
    "main.fastq2": "/tmp/C4_3endRNAseq/rawfq/Demo_2.fq.gz",
    "main.root": "/Path/to/working/C4_3endRNAseq",
    "main.gtf": "/Path/to/database/gtf/genes.gtf",
    "main.ID": "Demo",
    "main.outdir": "/Path/to/output/directory",
    "main.config": "/path/to/C4_3endRNAseq/barcode_config/DNBelabC4_3RNA_barcodeStructer.json",
    "main.refdir": "/path/to/star_index",
    "main.Python3": "/path/to/python3",
    "main.species":"Danio_rerio",
    "main.original":"Embryo cell",
    "main.Sample_barcode_list": "/tmp/C4_3endRNAseq/data_config/sample_barcode.csv",
    "main.SampleTime":"2022-05-20",
    "main.ExperimentalTime":"2022-05-20"                    
}

```
step 2, run the command line:

```shell
docker run --rm --cpus=64 --memory=64g \
-v ${DATA_LOCAL}:/tmp/C4_3endRNAseq/rawfq \
-v ${DATA_CONFIG_LOCAL}:/tmp/C4_3endRNAseq/data_config \
-v ${BARCODE_CONFIG_LOCAL}:/tmp/C4_3endRNAseq/barcode_config \
-v ${DB_LOCAL}:/tmp/C4_3endRNAseq/database \
-v ${RESULT_DIR}:/opt \
dingrp/c4_3end_rnaseq:latest \
sh -c "cd /tmp/ && /bin/bash /tmp/C4_3endRNAseq/script/run.sh"

```

```txt
${DB_LOCAL}: Directory on your local machine that has the database files. Make sure that the directory must contains two subdirectories, "gtf" and "star_index". The gene annotation file named "genes.gtf" must be included under "gtf"; the genome index file for STAR under the "star_index". If you build the database youself, make sure the format of the directory path is correct;

${DATA_LOCAL}: Directory on your local machine that has the fastq file;

${DATA_CONFIG_LOCAL}: Directory on your local machine that has the config file shown in 4.2.1;

${BARCODE_CONFIG_LOCAL}: Directory on your local machine that has the barcode config file shown in 4.2.2;

${RESULT_DIR}:Directory for output results
```
Then in the output file you will get following results:

```shell
outs:
final.bam  raw_count_mtx_sampleID.tsv.gz

report:
alignment_report.csv  annotated_report.csv  sequencing_report.csv

symbol:
fastq2bam_sigh.txt  makedir_sigh.txt  parseFastq_sigh.txt  sampleCount_sigh.txt  sortBam_sigh.txt   countMatrix_sigh.txt

temp:
aln.bam                 barcode_raw_list.txt  Log.progress.out  sambamba-pid538-pntk/  sorted.bam
annotated.bam           Log.final.out         Log.std.out       sample_stat.txt        sorted.bam.bai
barcode_counts_raw.txt  Log.out               reads.fq.gz       SJ.out.tab             _STARtmp/

````


## 2.2 Latest update

## 3. Hardware/Software requirement

### 3.1 Hardware

- x86-64 compatible processors
- 64 bit Linux
- At least 36GB of RAM and 10 CPUs

### 3.2 Software

#### User need to install manually

- [Java](https://www.oracle.com/java/)
- [Cromwell-35](https://github.com/broadinstitute/cromwell/releases)
- [python3](https://www.python.org/downloads/) (3.6+) # with following Python3 packages installed
  - numpy
  - pandas

#### Pre-compiled executables within binary releases

- PISA (v0.12)
- sambada(v0.7.0)
- STAR(v2.7.9a)

## 4. Database and files requirements

### 4.1 DataBase


#### Download Ready-made datasets
A database containing the STAR index for reference genome and its annotation files is needed.

you can build the database accodring to the follwoing steps:


```shell
# Create the database directory
cd database
mdkir gtf && cp path/to/gtf/example_genes.gtf gtf/genes.gtf
mkdir star_index
mkdir fasta
# Copy or download the prepared fasta file and gene gtf file to the corresponding directory
cp path/to/gtf/example_genes.gtf gtf/genes.gtf
cp path/to/gtf/example.fa fasta/example.fa
# Create star index
cd star_index
PATH/TO/STAR --runThreadN 8 --runMode genomeGenerate --genomeDir star_index --genomeFastaFiles ../fasta/example_genome.fa --sjdbGTFfile ../gtf/genes.gtf
```
**Notes:**

It takes about 1 hour to build the index file for a 3G genome with 8 threads;
The STAR version for index-building needs to be consistent with the STAR version used for mapping. In this docker image we use V2.7.9 STAR. It is recommended to download the executable STAR file we provided, thus ensuring the consistency of STAR version.


### 4.2 Configure files

#### 4.2.1 Configure file for sample information

An config.json file containing all the input parameters is needed for running the pipeline. Mandatory parameters must be specified in the documentation, and the pipleline will use default values if the optional parameters are not specified in the config file. A simple example is as follows:

```json
cat config.json
{
    "main.fastq1": "/path/to/Demo_1.fq.gz",
    "main.fastq2": "/path/to/Demo_2.fq.gz",
    "main.root": "/Path/to/working/C4_3endRNAseq",
    "main.gtf": "/Path/to/database/gtf/genes.gtf",
    "main.ID": "Demo",
    "main.outdir": "/Path/to/output/directory",
    "main.config": "/path/to/C4_3endRNAseq/barcode_config/DNBelabC4_3RNA_barcodeStructer.json",
    "main.refdir": "/path/to/star_index",
    "main.Python3": "/path/to/python3",
    "main.species":"Danio_rerio",
    "main.original":"Embryo cell",
    "main.Sample_barcode_list": "/path/to/data_config/sample_barcode.csv",
    "main.SampleTime":"2022-05-20",
    "main.ExperimentalTime":"2022-05-20"                    
}
```
**Note:** If you use docker version (for which we highly recommend), the path to root directory is fixed, and you shall not change any of the "/tmp/C4_3endRNAseq/XXX(rawfq, database,barcode_config,etc)" in the the config file (As shown here).

```json
{
    "main.fastq1": "/tmp/C4_3endRNAseq/rawfq/demo_1.fq.gz",
    "main.fastq2": "/tmp/C4_3endRNAseq/rawfq/demo_2.fq.gz",
    "main.root": "/tmp/C4_3endRNAseq",
    "main.gtf": "/tmp/C4_3endRNAseq/database/gtf/genes.gtf",
    "main.ID": "demo",
    "main.outdir": "/opt",
    "main.config": "/tmp/C4_3endRNAseq/barcode_config/DNBelabC4_3RNA_barcodeStructer.json",
    "main.Sample_barcode_list": "/tmp/C4_3endRNAseq/data_config/sample_barcode.csv",
    "main.refdir": "/tmp/C4_3endRNAseq/database/star_index",
    "main.Python3": "/usr/bin/python3",
    "main.species":"Danio_rerio",
    "main.original":"None",
    "main.SampleTime":"2022-06-05",
    "main.ExperimentalTime":"2022-06-05"
}
```
You may find the specific meaning of each parameters in config files in the following table.

| Parameter | Type | Description |
| :-----| :-----|:-----|
| main.ID | String| MANDATORY. Sample id. |
| main.fastq1 | Fastq(.gz) | MANDATORY. Read 1 in fastq format. Can be gzipped. Fastqs from different lanes can be separated with comma. For example, "L01_read_1.fq.gz, L02_read_1.fq.gz,...".|
| main.fastq2 | Fastq(.gz) | MANDATORY. Read 2 in fastq format. Can be gzipped. Fastqs from different lanes can be separated with comma. For example, "L01_read_2.fq.gz, L02_read_2.fq.gz,...". |
| main.root | Directory | MANDATORY. Directory of this pipeline. |
| main.outdir | string | MANDATORY. The file path you want to output data. | 
| main.config | JSON file | MANDATORY. config file illustrating the structer of UMI and sample barcode. | 
| main.Sample_barcode_list | csv file | MANDATORY. The file illustrating the correspondence between samples and labels. |
| main.refdir | PATH | MANDATORY. STAR index directory of genome reference. | 
| main.gtf | PATH | MANDATORY. gtf file of genome reference. | 
| main.Python3 | PATH | MANDATORY. Path to Python3.|
| main.species| String| Optional, default: Null. Species. |
| main.original | String | Optional, default: Null. original. |
| main.SampleTime | String| Optional, default: Null. original. |
| main.SampleTime| string | Optional, default: Null. Experimental time. |



#### 4.2.2 Configure file for barcode structure

This pipeline need an extra configure file in JSON format, containing the information of the sample barcode as well as Unique Molecular Barcode(UMI) in read1 fastq file.

A simple demo list below. The name field "cell barcode tag", "cell barcode" and "read 1" are required. **Noted that this pipeline is adjusted from the single cell RNA seq pipeline, so the "cell barcode" heer is actually refering to the sampple barcode.** In the value fieled, CB is the tag name for sample barcode and UR is the tag name for UMI. In the location field, R1 is short for read 1, R2 is for read 2. For MGI barocde, the sample barcode is 1-10 bases in read1, and the UMI barcode is the 11-20 bases in read1.And the program will export barcodes and UMI in the name filed of fastq, and base 1 to 100 of read 2 (R2:1-100) will be kept in the sequence field.

Predefined white-list is useful to correct barcodes and improve the number of reads per cell barcode. The "distance" and "white list" key in the config file is used to specify the cutoff distance and white-list barcodes

```json
{
    "cell barcode tag":"SB",
    "cell barcode":[
        {
            "location":"R1:1-10",
            "distance":"0",
            "white list":[
        "TAGGTCCGAT",
        "GGACGGAATC",
        "CTTACTGCCG",
        "ACCTAATTGA"
            ]
    }
    ],
    "UMI tag":"UB",
    "UMI":{
        "location":"R1:11-20"
    },
    "read 1":{
        "location":"R2:1-100"
    }
}
```

### 4.3 Raw Fastq

Raw fastq files containing 3'end RNA sequence can be taken as input fastq.

### 4.4 Sample_barcode_list
This is a csv file illustrating the correspondence between samples and labels. the barcode and sample name should be sperated with ",". Following is an example:
This file need be put under the data_config directory.
```txt
TAGGTCCGAT-1,sample1
GGACGGAATC-1,sample2
CTTACTGCCG-1,sample3
ACCTAATTGA-1,sample4
CGGCAATCCG-1,sample5
ATCAGGATTC-1,sample6
TCATTCCAGA-1,sample7
GATGCTGGAT-1,sample8
```

## 5. Installation

### 5.1 Without Docker 

```shell
wget https://github.com/MGI-EU/DNBSEQ_C4_3end-RNA-seq-data-analysis-pipeline/archive/refs/tags/v1.0.0.tar.gz
tar -xzvf v1.0.0.tar.gz
```
### 5.2 With Docker

```shell
docker pull dingrp/c4_3end_rnaseq:latest

```
## 6. Usage

### 6.1 Run without docker
#### 1) Prepare fastq files
Here we provide some demo data for testing. 

#### 2) Set up configure file.
Go to the directory of this pipeline, and check the configure file(as shown in 4.2.1)

#### 3) Run the pipeline
```shell
java -jar /path/to/C4_3endRNAseq/bin/cromwell-35.jar run -i /path/to/config.json /path/to/C4_3endRNAseq/pipelines/C4_3end_RNA.wdl
```

### 6.2 Run with docker

#### 1) Data preparation
Make sure the needed files illustraed in 4. Database and files requirements are prepared. And set the following variables in your machine:

```txt
${DB_LOCAL}: Directory on your local machine that has the database files. Make sure that the directory must contains two subdirectories, "gtf" and "star_index". The gene annotation file named "genes.gtf" must be included under "gtf"; the genome index file for STAR under the "star_index". If you build the database youself, make sure the format of the directory path is correct;

${DATA_LOCAL}: Directory on your local machine that has the fastq file;

${DATA_CONFIG_LOCAL}: Directory on your local machine that has the config file shown in 4.2.1;

${BARCODE_CONFIG_LOCAL}: Directory on your local machine that has the barcode config file shown in 4.2.2;

${RESULT_DIR}:Directory for output results
```
**Please make sure to use absolute path for above variables**


#### 2） Run the pipeline

```shell
docker run --rm --cpus=64 --memory=64g \
-v ${DATA_LOCAL}:/tmp/C4_3endRNAseq/rawfq \
-v ${DATA_CONFIG_LOCAL}:/tmp/C4_3endRNAseq/data_config \
-v ${BARCODE_CONFIG_LOCAL}:/tmp/C4_3endRNAseq/barcode_config \
-v ${DB_LOCAL}:/tmp/C4_3endRNAseq/database \
-v ${RESULT_DIR}:/opt \
dingrp/c4_3end_rnaseq:latest \
sh -c "cd /tmp/ && /bin/bash /tmp/C4_3endRNAseq/script/run.sh"
```

## 7. FAQ
Q1: What kind of data is suitable for this pipeline?

A1: Currently this pipeline is best suitable for the data gererated by the MGI 3endRNAseq kits,if you want to use it to analysis data from other 3end RNAseq data(like Lexogen), it is also possible, but you need to adjusted the barcode config file accorrding to the kits.

## 8. To be updated

#### 1) Upload demo data;
#### 2) Generate a html report.
#### 3) An internal script to directly run the Lexogen data.
