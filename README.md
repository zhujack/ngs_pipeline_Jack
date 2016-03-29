## Introduction
This is the implimentation of KhanLab NGS Pipeline using Snakemake.
## Installation

The easiest way to get this pipeline is to clone the repository.

```
git clone https://github.com/patidarr/ngs_pipeline.git
```
## Conventions

- Sample names cannot have "/" or "." in them
- Fastq files end in ".fastq.gz"
- Fastq files are stored in DATA_DIR (Set as Environment Variable) 

### DNASeq:
- QC
- BWA, Novoalign
- Broad Standard Practices on bwa bam
- Haplotype Caller, Platypus, Bam2MPG, MuTect, Strelka
- snpEff, Annovar, SIFT, pph2, Custom Annotation
- Coverage Plot, Circos Plot, Hotspot Coverage Box Plot
- Create input format for oncogenomics database (Patient Level)
- Make Actionable Classification for Germline and Somatic Mutations 
- Copy number based on the simple T/N LogRatio (N cov >=30), Corrected for Total # Reads
- LRR adjusted to center. 
- Patient/subject level data:
    BWA -> Haplotype Caller, Platypus, Hotspot BoxPlot, Coverage Plot, Sample Matching, Circos Plot, Annotations.coding.rare.txt, IGV session,  
    Novoalign -> MPG
- Sample level data:
    fastqc, flagstat, hotspot coverage, Coverage, bamQC, Reads Counts, Somatic Copy Number, 

### RNASeq:
- QC
- Tophat, STAR
- Broad Standard Practices on STAR bam
- fusion-catcher, tophat-fusion, deFuse
- Cufflinks (ENS and UCSC)
- In-house Exon Expression (ENS and UCSC)
- Haplotype Caller
- snpEff, Annovar, SIFT, pph2, Custom Annotation
- Actionable Fusion classification
- General workflows:
    STAR -> Haplotype Caller
    tophat -> cufflinks, exon_exp and tophat_fusion
    fusioncatcher
    deFuse

### Patient:
- Genotyping On Patient. 
	1000g sites are evaluated for every library and then compared (all vs all)
	If two libraries come from a patient the match shuld be pretty good >80%
- Still to develop:
	If the match is below a certain threshold, break the pipeline for patient.

Rulegraph


![alt tag](rulegraph.png)





DAG for example Sample
![alt tag](dag.png)
