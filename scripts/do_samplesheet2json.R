#!/usr/bin/env Rscript
# This script is to convert Meltzerlab NGS samplesheet to a json file and merge to config_common.json
# Author: Jack Zhu
# Date: 04/16/2015
# verstion: 0.01
# example: $ do_samplesheet2json.R -s samplesheet.txt
# opt=NULL
# opt$sampleSheetFile = 'samplesheet.txt'
# opt$outDir = getwd()

suppressPackageStartupMessages(library("optparse"))
option_list <- list( 
    make_option(c("-s", "--sampleSheetFile"), 
            help="This samplesheet should be generated from Meltzer solexaDB." ),    
    make_option(c("-o", "--outDir"), default=getwd(), 
            help="Directory for saving output files. [default: %default]"),
    make_option(c("-v", "--verbose"), action="store_true", default=TRUE,
            help="to output some information about a job.  [default: %default]")        
)

opt <- parse_args(OptionParser(option_list=option_list))

if( ! is.element('sampleSheetFile', names(opt)) ) stop("Options for sampleSheetFile is required. ")
    
if ( opt$verbose ) { 
    write("The fun gets started...\n", stderr()) 
}

print(opt)

df = read.delim(opt$sampleSheetFile, as.is=TRUE, strip.white=TRUE, comment.char = "#")
## remove all padded leading spaces when doing matrix conversion
s = data.frame(lapply(df, as.character), stringsAsFactors=F)

# colnames(s)
#  [1] "result_id"    "run_id"       "run_date"     "sample"   "source"
#  [6] "sample"       "normal.tumor" "sampleN"      "library"      "library_id"
# [11] "lane_id"      "partitioning" "sample_type"  "read1"        "read2"
# [16] "study_id"     "note"

# > colnames(s)
#  [1] "result_id"    "source"       "sample"       "library"      "library_id"
#  [6] "lane_id"      "capture"      "partitioning" "normal.tumor" "sample_type"
# [11] "read1"        "read2"        "note"

objL <- list(
        'subject' = c('source','SampleName','sample_type'), 
        'sample_references' = c('SampleName', 'sampleN','sample_type', 'source', 'normal.tumor'),
        'sample_fastq1' = c('SampleName', 'read1'),
        'sample_fastq2' = c('SampleName', 'read2'),
        'sample_captures' = c('SampleName', 'partitioning'),
        'subject_captures' = c('source', 'partitioning'),
        'sample_RNASeq' = c('SampleName', 'SampleName','sample_type', 'source', 'normal.tumor'),
        'RNASeq' = c('source', 'SampleName','sample_type'),
        'Diagnosis' = c('SampleName', 'Diagnosis')    
)

source("/home/zhujack/bin/R_functions/col2list.R")

objList <- list()
for (L in names(objL) ) {
    print(L)
    m <- unique(s[, c(objL[[L]]) ])
    if( L == "subject" ) {
        m <- m[ m$sample_type != 'mRNA', ]
    } else if ( L == "RNASeq" ){
      m <- m[ m$sample_type == 'mRNA', ]
    } else if ( L == "sample_references" ){
        if( all(is.na(m$sampleN)) ) {
            m1 <- m[ m$normal.tumor == "Tumor" & m$sample_type != "mRNA", ]
            for ( i in rownames(m1) ) {
              m_s = m[ m$source == m1[i, 4],]
              Normal1 = m_s$SampleName[ m_s$normal.tumor != "Tumor" & m_s$sample_type != "mRNA" ]
              if( length(Normal1) > 0 ) {
                  m1[i, 2] <- Normal1[1]
              } else {
                  m1[i, 2] <- ""
              }
            }
            m = m1
        }
    } else if ( L == "sample_RNASeq" ){
        m1 <- m[ m$normal.tumor == "Tumor" & m$sample_type != "mRNA", ]
        for ( i in rownames(m1) ) {
            m_s = m[ m$source == m1[i, 4],]
            RNASeq1 = m_s$SampleName[m_s$sample_type == "mRNA"]
            if( length(RNASeq1) > 0 ) {
                m1[i, 2] <- RNASeq1[1]
            } else {
                m1[i, 2] <- ""
            }
        }
        m = m1
    } 
    # m <- m[, 1:2]
    m <- m[ m[,2] != "", 1:2] ## need empty entries

    ##some don't convert to list - not working
    # if( is.element( L, c('Diagnosis', 'sample_captures') ) ) {
    #     objList_1 <- list(t(m))
    # } else {
    #     objList_1 <- col2list( m )
    # }
    objList_1 <- col2list( m )
    names(objList_1) <- L
    objList <- c(objList, objList_1)
}

library("jsonlite")
outSample <- file.path(opt$outDir, "samplesheet.json")
if( file.exists(outSample) ) {
    timestamp <- format(Sys.time(), "_%Y%m%d_%H%M%S")
    file.rename(outSample, sub('.json', paste(timestamp, '.json', sep=''), outSample))
}
jsonS <- toJSON( objList, pretty=T )
writeLines(jsonS, outSample)



