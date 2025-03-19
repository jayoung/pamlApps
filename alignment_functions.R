####### translateGappedAln:  translate() does not deal with gap characters yet (should later - see https://github.com/Bioconductor/Biostrings/issues/30). So I made my own translateGappedAln function

getCodons <- function(myAln) {
    seqs <- as.character(myAln)
    len <- width(myAln)[1]
    starts <- seq(from=1, to=len, by=3)
    ends <- starts + 2
    myViews <- lapply(myAln, function(x) { 
        Views(x, starts, ends)
    })
    myCodons <- lapply(myViews, function(x) {
        as.character(DNAStringSet(x))
    })
    myCodons
}

## translateCodons - takes a character vector of codons as input, outputs the corresponding amino acids
translateCodons <- function(myCodons, 
                            unknownCodonTranslatesTo="-", 
                            quiet=FALSE) {
    ## make new genetic code
    gapCodon <- "-"
    names(gapCodon) <- "---"
    my_GENETIC_CODE <- c(GENETIC_CODE, gapCodon)
    
    ## translate the codons
    pep <- my_GENETIC_CODE[myCodons]
    
    ## check for codons that were not possible to translate, e.g. frameshift codons
    if (sum(is.na(pep))>0) {
        if(!quiet) {
            message("\nWarning - there were codons I could not translate. Using this character: ", unknownCodonTranslatesTo, "\n")
            unknownCodons <- unique(myCodons[ which(is.na(pep))])
            message("The codons in question were: ",
                    paste(unknownCodons, collapse=","),
                    "\n\n")
        }
        pep[ which(is.na(pep)) ] <- unknownCodonTranslatesTo
    }
    
    ## prep for output
    pep <- paste(pep, collapse="")
    return(pep)
}

## wrap the getCodons and translateCodons functions together into one:
translateGappedAln <- function(myAln, 
                               unknownCodonTranslatesTo="-", 
                               quiet=FALSE) {
    myCodons <- getCodons(myAln)
    myAAaln <- AAStringSet(unlist(lapply(
        myCodons, 
        translateCodons, 
        unknownCodonTranslatesTo=unknownCodonTranslatesTo, 
        quiet=quiet)))
    return(myAAaln)
}

########### alnToTibble - converts an alignment into a tibble, one row per alignment position, one column per aligned seq
## if we supply refSeqName, it'll also get the ungapped position in that refseq
alnToTibble <- function(aln, refSeqName=NULL) {
    names(aln) <- sapply(strsplit(names(aln), " "), "[[", 1)
    output <- as.matrix(aln) %>% 
        t() %>% 
        as_tibble() 
    output$aln_pos <- 1:width(aln)[1]
    output <- output %>% 
        relocate(aln_pos)
    if(!is.null(refSeqName)) {
        if(!refSeqName %in% colnames(output)) {
            stop("\n\nERROR - the refSeqName you supplied is not in the alignment")
        }
        ref_seq <- output[,refSeqName] %>% 
            deframe()
        output$ref_pos <- cumsum(ref_seq != "-")
        output[which(ref_seq=="-"),"ref_pos"] <- NA
        output <- output %>% 
            relocate(ref_pos, .after=aln_pos)
    }
    return(output)
}



########### getAlnPosLookupTable - uses an alignment to get a lookup table of alignment position versus ungapped position in each sequence. Gap positions get an NA

getAlnPosLookupTable <- function(myAln) {
    if(length(unique(width(myAln)))>1) {
        stop("\n\nERROR - the seqs in the alignment are not all the same length\n\n")
    }
    output <- tibble(aln_pos = 1:width(myAln)[1])
    myAln_chars <- strsplit(as.character(myAln),"")
    each_seq_pos <- sapply(myAln_chars, function(eachSeq_chars) {
        countNonGap <- cumsum(eachSeq_chars != "-")
        countNonGap[which(eachSeq_chars=="-")] <- NA
        return(countNonGap)
    })
    output <- cbind(output, each_seq_pos)
    return(output)
}
