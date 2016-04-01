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
s = data.frame(lapply(df, as.character))

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
        'subject' = c('source','sampleName'), 
        'sample_references' = c('sampleName', 'sampleN'),
        'sample_fastq1' = c('sampleName', 'read1'),
        'sample_fastq2' = c('sampleName', 'read2'),
        'sample_captures' = c('sampleName', 'capture'),
        'subject_captures' = c('source', 'capture'),
        'sample_RNASeq' = c('sampleName', 'sampleName'),
        'RNASeq' = c('source', 'sampleName'),
        'Diagnosis' = c('sampleName', 'Diagnosis')    
)

source("/home/zhujack/bin/R_functions/col2list.R")

objList <- list()
for (L in names(objL) ) {
    print(L)
    m <- unique(s[, c(objL[[L]]) ])
    # m <- m[ !m[,2] == "", ] ## need empty entries
    if( L == "subject" ) {
        m <- m[ !grepl('RNASeq', m[,2]), ]
    } else if ( L == "RNASeq" ){
          m <- m[ grepl('RNASeq', m[,2]), ]
    } else if ( L == "sample_RNASeq" ){
        m1 <- m[ ! (grepl('RNASeq', m[,1]) | grepl('Normal', m[,1]) ), ]
        m1[,2] <- sub('\\..*$', '\\.RNASeq', m1[,1], perl=TRUE)
        m <- m1[ m1[,2] %in% m[,2],]
    } 
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



