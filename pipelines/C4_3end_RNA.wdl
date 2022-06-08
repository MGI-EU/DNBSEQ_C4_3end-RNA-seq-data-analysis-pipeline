workflow main {
  String root
  String fastq1
  String fastq2
  String outdir
  String refdir
  String Rscript
  String Python3
  String ID
  String gtf
  String ?runID
  String config
  String ?lib
  String ?species
  String ?original
  String ?SampleTime
  String ?ExperimentalTime
  call makedir {
    input:
    Dir=outdir,
  }
  call parseFastq {
    input:
    lib=lib,
    config=config,
    fastq1=fastq1,
    fastq2=fastq2,
    outdir=makedir.Outdir,
    runID=runID,
    root=root,
  }
  call fastq2bam {
    input:
    lib=lib,
    fastq=parseFastq.fastq,
    outdir=outdir,
    refdir=refdir,
    root=root
  }
  call sortBam {
    input:
    lib=lib,
    bam=fastq2bam.bam,
    gtf=gtf,
    root=root,
    outdir=outdir
  }
  call sampleCount {
    input:
    lib=lib,
    bam=sortBam.anno,
    outdir=outdir,
    root=root,
    rawlist=parseFastq.rawlist
  }

  call countMatrix {
    input:
    lib=lib,
    root=root,
    rawlist=parseFastq.rawlist,
    outdir=outdir,
    anno=sortBam.anno,
  }
}

task makedir {
  String Dir
  command {
    if [ -f ${Dir}/symbol/makedir_sigh.txt ];then
      echo "makedir node success"
    else
      mkdir -p ${Dir}
      mkdir -p ${Dir}/outs
      mkdir -p ${Dir}/temp
      mkdir -p ${Dir}/report
      mkdir -p ${Dir}/symbol
      echo "[`date +%F` `date +%T`] workflow start" > ${Dir}/workflowtime.log
      echo "[`date +%F` `date +%T`] Nothing is True. Everything is permitted." > ${Dir}/symbol/makedir_sigh.txt
    fi
  }
  output {
    String Outdir="${Dir}"
  }
}

task parseFastq {
  String config
  String fastq1
  String fastq2
  String outdir
  String ?runID
  String root
  String ?lib
  Int cpp=64
  command {
    if [ -f ${outdir}/symbol/parseFastq_sigh.txt ];then
      echo "parseFastq node success"
    else
      if [ -f ${default=abjdbashj lib} ]; then
      source ${lib}
      fi
      ${root}/bin/PISA parse -t ${cpp} -f -q 20 -dropN -config ${config} -cbdis ${outdir}/temp/barcode_counts_raw.txt -run ${default=1 runID} -report ${outdir}/report/sequencing_report.csv ${fastq1} ${fastq2} |gzip -c  > ${outdir}/temp/reads.fq.gz &&\
      head -n 50000 ${outdir}/temp/barcode_counts_raw.txt |cut -f1 > ${outdir}/temp/barcode_raw_list.txt &&\
      echo "[`date +%F` `date +%T`] Nothing is True. Everything is permitted." > ${outdir}/symbol/parseFastq_sigh.txt
    fi
  }
  output {
    String count="${outdir}/temp/barcode_counts_raw.txt"
    String fastq="${outdir}/temp/reads.fq.gz"
    String sequencingReport="${outdir}/report/sequencing_report.csv"
    String rawlist="${outdir}/temp/barcode_raw_list.txt"
  }
}

task fastq2bam {
  String fastq
  String outdir
  String refdir
  String root
  String ?lib
  Int cpp=64
  command {
    if [ -f ${outdir}/symbol/fastq2bam_sigh.txt ];then
      echo "fastq2bam node success"
    else
      if [ -f ${default=abjdbashj lib} ]; then
        source ${lib}
      fi
      ${root}/bin/STAR --outSAMmultNmax 1 --outStd SAM --outSAMunmapped Within --runThreadN ${cpp} --genomeDir ${refdir} --readFilesCommand gzip -dc --readFilesIn ${fastq} --outFileNamePrefix ${outdir}/temp/ 1> ${outdir}/temp/aln.sam &&\
      ${root}/bin/PISA sam2bam -@ ${cpp} -k -o ${outdir}/temp/aln.bam -report ${outdir}/report/alignment_report.csv ${outdir}/temp/aln.sam && rm -f ${outdir}/temp/aln.sam &&\
      echo "[`date +%F` `date +%T`] Nothing is True. Everything is permitted." > ${outdir}/symbol/fastq2bam_sigh.txt
    fi
  }
  output {
    String bam="${outdir}/temp/aln.bam"
    String alnReport="${outdir}/report/alignment_report.csv"
  }
}

task sortBam {
  String bam
  String root
  String outdir
  String gtf
  String ?lib
  Int cpp=64
  command {
    if [ -f ${outdir}/symbol/sortBam_sigh.txt ];then
      echo "sortBam node success"
    else
      if [ -f ${default=abjdbashj lib} ]; then
        source ${lib}
      fi
      ${root}/bin/sambamba sort -t ${cpp} --tmpdir ${outdir}/temp -o ${outdir}/temp/sorted.bam ${outdir}/temp/aln.bam &&\
      ${root}/bin/PISA anno -gtf ${gtf} -o ${outdir}/temp/annotated.bam -report ${outdir}/report/annotated_report.csv ${outdir}/temp/sorted.bam &&\
      ${root}/bin/PISA corr -tag UB -tags-block CB,GN -new-tag UR -@ ${cpp} -t ${cpp} -o ${outdir}/outs/final.bam ${outdir}/temp/annotated.bam &&\
      echo "[`date +%F` `date +%T`] Nothing is True. Everything is permitted." > ${outdir}/symbol/sortBam_sigh.txt
    fi
  }
  output {
    String anno="${outdir}/outs/final.bam"
  }
}

task sampleCount {
  String bam
  String outdir
  String root
  String rawlist
  String ?lib
  Int cpp=64
  command {
    if [ -f ${outdir}/symbol/sampleCount_sigh.txt ];then
      echo "sampleCount node success"
    else
      if [ -f ${default=abjdbashj lib} ]; then
        source ${lib}
      fi
      ${root}/bin/PISA attrcnt -cb CB -tags UR,GN -@ ${cpp} -dedup -o ${outdir}/temp/sample_stat.txt -list ${rawlist} ${bam} &&\
      echo "[`date +%F` `date +%T`] Nothing is True. Everything is permitted." > ${outdir}/symbol/sampleCount_sigh.txt
    fi
  }
  output {
    String count="${outdir}/temp/sample_stat.txt"
  }
}


task countMatrix {
  String root
  String rawlist
  String outdir
  String anno
  String ?lib
  Int cpp=64
  command {
      if [ -f ${default=abjdbashj lib} ]; then
        source ${lib}
      fi
      ${root}/bin/PISA count -@ ${cpp} -tag CB -anno-tag GN -umi UR -o ${outdir}/outs/raw_count_mtx.tsv -list ${rawlist} ${anno} &&\
      gzip -f ${outdir}/outs/raw_count_mtx.tsv &&\
      echo "[`date +%F` `date +%T`] workflow end" >> ${outdir}/workflowtime.log
  }
  output {
    String matrix = "${outdir}/outs/count_mtx.tsv.gz"
  }
}

