#!/usr/bin/env nextflow

// This is needed for activating the new DLS2
nextflow.enable.dsl=2


println """\
      LIST OF PARAMETERS
================================
            GENERAL
Reads            : $params.reads
Results-folder   : $params.outdir/
Threads          : $params.threads
================================
          TRIMMOMATIC
Sliding window   : $params.slidingwindow
Average quality  : $params.avgqual
================================
             STAR
Reference genome : $params.dirgenome
Genome directory : $params.genome 
GTF-file         : $params.gtf
Length-reads     : $params.lengthreads
SAindexNbases    : $params.genomeSAindexNbases
================================
"""


// Also channels are being created. 
read_pairs_ch = Channel
        .fromFilePairs(params.reads, checkIfExists:true)

genome = file(params.genome)
gtf = file(params.gtf)

include { QC as fastqc_raw; QC as fastqc_trim } from "${launchDir}/modules/fastqc" //addParams(OUTPUT: fastqcOutputFolder)
include { IDX; MAP } from "${launchDir}/modules/star"
include { TRIM } from "${launchDir}/modules/trimmomatic"

// Running a workflow with the defined processes here.  
workflow {
	// QC on raw reads
  fastqc_raw_out = fastqc_raw(read_pairs_ch) 
	
  // Trimming & QC
  trim_fq = TRIM(read_pairs_ch)
	fastqc_trim_out = fastqc_trim(trim_fq)
	
  // Mapping
  index_dir = IDX(genome, gtf)
  MAP(trim_fq, index_dir, gtf)
  
  // Multi QC on all results
  MULTIQC(fastqc_raw_out.mix(fastqc_trim_out).collect())
}
