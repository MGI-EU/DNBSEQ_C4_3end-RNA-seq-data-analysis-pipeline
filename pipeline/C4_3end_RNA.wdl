workflow main {
  String root
  String fastq1
  String fastq2
  String outdir
  String refdir
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
  String Sample_barcode_list
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
    Python3=Python3
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
    whitelist=parseFastq.whitelist
  }

  call countMatrix {
    input:
    lib=lib,
    root=root,
    whitelist=parseFastq.whitelist,
    outdir=outdir,
    anno=sortBam.anno,
    Python3=Python3
  }
  
  call barcode2Sample {
    input:
    root=root,
    Python3=Python3,
    sample_barcode_list=Sample_barcode_list,
    matrix=countMatrix.matrix,
    outdir=outdir
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
  String Python3
  command {
    if [ -f ${outdir}/symbol/parseFastq_sigh.txt ];then
      echo "parseFastq node success"
    else
      if [ -f ${default=abjdbashj lib} ]; then
      source ${lib}
      fi
      ${root}/bin/PISA parse -t ${cpp} -f -q 20 -dropN -config ${config} -cbdis ${outdir}/temp/barcode_counts_raw.txt -run ${default=1 runID} -report ${outdir}/report/sequencing_report.csv ${fastq1} ${fastq2} |gzip -c  > ${outdir}/temp/reads.fq.gz &&\
      ${Python3} ${root}/bin/get_sampleBarcode.py ${config} ${outdir}/temp &&\
      echo "[`date +%F` `date +%T`] Nothing is True. Everything is permitted." > ${outdir}/symbol/parseFastq_sigh.txt
    fi
  }
  output {
    String count="${outdir}/temp/barcode_counts_raw.txt"
    String fastq="${outdir}/temp/reads.fq.gz"
    String sequencingReport="${outdir}/report/sequencing_report.csv"
    String whitelist="${outdir}/temp/barcode_white_list.txt"
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
      ${root}/bin/PISA corr -tag UB -tags-block SB,GN -new-tag UR -@ ${cpp} -t ${cpp} -o ${outdir}/outs/final.bam ${outdir}/temp/annotated.bam &&\
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
  String whitelist
  String ?lib
  Int cpp=64
  command {
    if [ -f ${outdir}/symbol/sampleCount_sigh.txt ];then
      echo "sampleCount node success"
    else
      if [ -f ${default=abjdbashj lib} ]; then
        source ${lib}
      fi
      ${root}/bin/PISA attrcnt -cb SB -tags UR,GN -@ ${cpp} -dedup -o ${outdir}/temp/sample_stat.txt -list ${whitelist} ${bam} &&\
      echo "[`date +%F` `date +%T`] Nothing is True. Everything is permitted." > ${outdir}/symbol/sampleCount_sigh.txt
    fi
  }
  output {
    String count="${outdir}/temp/sample_stat.txt"
  }
}


task countMatrix {
  String root
  String whitelist
  String outdir
  String anno
  String Python3
  String ?lib
  Int cpp=64
  command {
    if [ -f ${outdir}/symbol/countMatrix_sigh.txt];then
      echo "countMatrix node success"
    else
      if [ -f ${default=abjdbashj lib} ]; then
        source ${lib}
      fi
      mkdir -p ${outdir}/outs/count_matrix &&\
      ${root}/bin/PISA count -@ ${cpp} -tags SB -anno-tag GN -umi UR -outdir ${outdir}/outs/count_matrix -list ${whitelist} ${anno} &&\
      ${Python3} ${root}/bin/mtx2table.py ${outdir}/outs/count_matrix ${outdir}/outs/raw_count_mtx&&\
      echo "[`date +%F` `date +%T`] Nothing is True. Everything is permitted." > ${outdir}/symbol/countMatrix_sigh.txt
    fi
  }
  output {
    String matrix="${outdir}/outs/raw_count_mtx.tsv"
  }
}

task barcode2Sample {
  String root
  String Python3
  String outdir
  String sample_barcode_list
  String matrix
  String ?lib
  command{
      if [ -f ${default=abjdbashj lib} ]; then
        source ${lib}
      fi
      ${Python3} ${root}/bin/barcode2sample.py ${matrix} ${sample_barcode_list} ${outdir}/outs/raw_count_mtx_sampleID&&\
      gzip -f ${outdir}/outs/raw_count_mtx_sampleID.tsv&&\
      rm -rf ${outdir}/outs/count_matrix&&\
      rm -rf ${matrix}&&\
      echo "[`date +%F` `date +%T`] workflow end" >> ${outdir}/workflowtime.log
  }
  output {
    String final_matrix="${outdir}/outs/raw_count_mtx_sampleID.tsv"
  }
}
