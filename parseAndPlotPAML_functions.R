############## sitewise PAML functions

##### parseRSTfile: a function to take the rst file output of site-wise PAML (e.g. model 8)
## parses the rst file and returns a data.frame of the BEB results for each site
parseRSTfile <- function(rstFile) {
    if(!file.exists(rstFile)) {
        stop("\n\nERROR - the rst file you specified does not exist:",rstFile,"\n\n")
    }
    
    ########## process the rst file
    
    ## read in whole rst file:
    rst <- scan(rstFile, what="character", sep="\n", quiet=TRUE)
    
    ## check it looks about right:
    if (!grepl("^Supplemental results for CODEML", rst[1])) {
        stop("\n\nERROR - the rst file you specified does not look right - the first line usually begins with 'Supplemental results for CODEML'\n\n")
    }
    
    ### for rst files that are output of paml run on >1 model at a time, we first extract the model 8 results
    # this is for paml v 4.8 output
    if(length(grep("^Model 8: beta\\&w>1$", rst))>0) {
        cat(" Found results for >1 NSsites model - taking only model 8 results\n")
        rst <- rst[ grep("^Model 8: beta&w>1$", rst)[1] : length(rst) ]
    }
    # this is for paml v 4.10.6 output
    if(length(grep("^NSsites Model 8: beta&w>1$", rst))>0) {
        cat(" Found results for >1 NSsites model - taking only model 8 results\n")
        rst <- rst[ grep("^NSsites Model 8: beta&w>1$", rst)[1] : length(rst) ]
    }
    
    
    # the inverse grep on 'for 3 classes' gets rid of M2 BEB output
    lineWhereBEBsectionStarts <- 
        grepl("^Bayes Empirical Bayes \\(BEB\\) probabilities", rst) &
        !grepl("for 3 classes", rst)
    
    if(sum(lineWhereBEBsectionStarts) != 1) {
        stop("\n\nERROR - the rst file you specified does not look right - there is usually a line near the bottom that contains 'Bayes Empirical Bayes (BEB) probabilities'. Is this really SITE-wise PAML output, from a model that allows positive selection (e.g. model 8)?\n\n")
    }
    
    ## get the line near the top that tell us the omegas for each class
    lineWithOmegas <- grep("dN/dS \\(w\\) for site classes", rst) + 2
    omegas <- rst[lineWithOmegas]
    omegas <- strsplit(omegas, "\\s+", perl=TRUE)[[1]]
    omegas <- as.numeric(omegas[ !grepl ("w:", omegas)])
    
    ## get the BEB table
    lineWhereBEBsectionStarts <- which(lineWhereBEBsectionStarts)
    lineWhereBEBsectionEnds <- grep("^Positively selected sites", rst)[2] - 1
    
    ## process the two header lines to extract some useful info
    BEBheader1 <- rst[lineWhereBEBsectionStarts]
    BEBheader2 <- rst[(lineWhereBEBsectionStarts+1)]
    numClasses <- gsub("Bayes Empirical Bayes \\(BEB\\) probabilities for ","",BEBheader1)
    numClasses <- as.integer(gsub(" classes \\(class\\) & postmean_w","",numClasses))
    firstSequence <- gsub("\\(amino acids refer to 1st sequence: ","",BEBheader2)
    firstSequence <- gsub("\\)","",firstSequence)
    
    ## process the table
    BEBtable_prelim <- rst[(lineWhereBEBsectionStarts+2):lineWhereBEBsectionEnds]
    BEBtable_prelim <- gsub("( ","(",BEBtable_prelim,fixed=TRUE)
    BEBtable_prelim <- paste(" ", BEBtable_prelim, sep="")
    BEBtable_prelim <- strsplit(BEBtable_prelim, "\\s+", perl=TRUE)
    
    BEBtable <- data.frame(pos=as.integer(sapply(BEBtable_prelim, "[[", 2)))
    BEBtable[,firstSequence] <- sapply(BEBtable_prelim, "[[", 3)
    BEBtable[,"bestClass"] <- as.integer(gsub("[()]","",sapply(BEBtable_prelim, "[[", numClasses+4)))
    BEBtable[,"meanOmega"] <- as.numeric(sapply(BEBtable_prelim, "[[", numClasses+5))
    
    for(classIndex in 1:numClasses) {
        valueToTake <- classIndex+3
        colName <- paste("prob_class",classIndex,"_omega_",omegas[classIndex],sep="")
        BEBtable[,colName] <- as.numeric(sapply(BEBtable_prelim, "[[", valueToTake))
    }
    return(BEBtable)
}



##### parsedRSTtoTbl - works on data.frame output of parseRSTfile, makes
# 1. a tibble with 1 row per site with clean_names style colnames
# 2. a metadata tibble that captures some of the data that was in the colnames
parsedRSTtoTbl <- function(rst_df) {
    require(tidyverse)
    require(janitor)
    ## I don't need the omegas of each class but parse colnames(rst_df) further to get them if needed
    rst_colnames <- colnames(rst_df)
    
    rst_tbl <- rst_df %>% 
        as_tibble()  %>% 
        clean_names() %>% 
        dplyr::rename(
            aln_pos=pos,
            aa_refseq=2
        ) %>% 
        rename_with(.cols=starts_with("prob_class"),
                    .fn= ~ gsub("_omega_.+?$", "", .x) )
    
    output <- list(sites=rst_tbl,
                   metadata=rst_colnames)
    return(output)
}

###### plotProbs: a function to plot the BEB probabilities at each site, with an option to color sites with high BEB probability
## uses the output of parseRSTfile
plotProbs <- function(BEBtable, title=NULL, barCol="grey",
                      xlab="alignment position (codon)",
                      ylab="probability of positive selection (BEB)",
                      addThresholdLine=FALSE, threshold=0.9,
                      thresholdLineColor="red", 
                      highlightHighBEB=FALSE, highBEBthreshold=0.9,
                      highBEBcolor="red", 
                      ...) {
    if("tbl_df" %in% class(BEBtable)) {
        BEBtable <- as.data.frame(BEBtable)
    }
    probsColumn <- colnames(BEBtable)[ dim(BEBtable)[2] ]
    plot(BEBtable[,"pos"], BEBtable[,probsColumn], type="h", bty="n", 
         col=barCol, xlab=xlab, ylab=ylab, las=1, mgp=c(2,0.75,0), ...)
    if(addThresholdLine) {
        abline(h=threshold, lty=2, col=thresholdLineColor)
    }
    BEBprobsPosSel <- BEBtable[,dim(BEBtable)[2]]
    if(sum(is.na(BEBprobsPosSel))>0) {
        warnText <- "WARNING - there are 'nan' values in your rst file. That's weird"
        # cat(warnText)
        mtext(warnText, side=3, adj=1, col="red", outer=FALSE, line=-1, cex=1)
    }
    # highlight sites with BEB >= a threshold
    if(highlightHighBEB) {
        if (sum(BEBprobsPosSel >= highBEBthreshold, na.rm=TRUE) > 0) {
            BEBtable_justPosSelSites <- BEBtable[which(BEBprobsPosSel >= highBEBthreshold),]
            segments(x0=BEBtable_justPosSelSites[,"pos"], y0=0,
                     x1=BEBtable_justPosSelSites[,"pos"], 
                     y1=BEBtable_justPosSelSites[,probsColumn], col=highBEBcolor)
            
            myLegend <- paste("Color=sites where BEB probability >=",highBEBthreshold)
            mtext(myLegend, side=1, adj=1, col=highBEBcolor, outer=TRUE)
        }
    }
    if(!is.null(title)) { title(main=title, line=0) }
}


###### plotProbs_new: a ggplot-based function to plot the BEB probabilities at each site, with an option to color sites with high BEB probability
## uses the output of parseRSTfile
plotProbs_new <- function(
        BEBtbl, title=NULL, barCol="grey",
        xlab="alignment position (codon)",
        ylab="probability of positive selection (BEB)",
        addThresholdLine=FALSE, threshold=0.9,
        thresholdLineColor="red", 
        highlightHighBEB=FALSE, highBEBthreshold=0.9,
        highBEBcolor="red", 
        ...) {
    if(sum(is.na(BEBtbl$prob_class11))>0) {
        warning("WARNING - there are 'nan' values in your rst file. That's weird")
    }
    
    BEBtbl_to_plot <- BEBtbl %>% 
        dplyr::select(aln_pos, prob_class11) 
    
    if(highlightHighBEB) {
        BEBtbl_to_plot <- BEBtbl_to_plot %>% 
            mutate(my_color= case_when( 
                prob_class11>=highBEBthreshold ~ highBEBcolor,
                TRUE ~ barCol)) 
        myLegend <- paste("Color=sites where BEB probability >=",highBEBthreshold)
        my_plot <- BEBtbl_to_plot %>% 
            ggplot(aes(x=aln_pos, y=prob_class11, 
                       color=my_color, fill=my_color)) +
            scale_fill_identity(guide = "legend") +
            scale_color_identity(guide = "legend") +
            labs(subtitle=myLegend)
    } else {
        my_plot <- BEBtbl_to_plot %>% 
            ggplot(aes(x=aln_pos, y=prob_class11))
    }
    my_plot <- my_plot + 
        labs(x=xlab, y=ylab, title=title) +
        theme_classic() +
        coord_cartesian(ylim=c(0,1)) +
        guides(color="none", fill="none")  
    
    if(addThresholdLine) {
        my_plot <- my_plot +
            geom_hline(yintercept=highBEBthreshold, 
                       lty=2, color=thresholdLineColor)
    }
    my_plot <- my_plot +  
        geom_col(linewidth=0)
    return(my_plot)
    
}

###### plotOmegas: a function to plot the BEB mean dN/dS estimates at each site, with an option to color sites with high BEB probability
## uses the output of parseRSTfile
plotOmegas <- function(BEBtable, title=NULL, barCol="grey", 
                       yAxisCenterAtNeutral=FALSE,
                       xlab="alignment position (codon)",
                       ylab="dN/dS estimate (BEB mean)",
                       highlightHighBEB=FALSE, highBEBthreshold=0.9,
                       highBEBcolor="red", 
                       ... ) {
    if("tbl_df" %in% class(BEBtable)) {
        BEBtable <- as.data.frame(BEBtable)
    }
    omegas <- BEBtable[,"meanOmega"]
    maxOmegaForPlot <- ceiling(max(omegas))
    myYlim <- c(0, maxOmegaForPlot)
    omegasToPlot <- omegas
    axisTicks <- 0:maxOmegaForPlot
    axisLabels <- axisTicks
    ## change things if we're plotting the weird way:
    ## to get the weird-looking up and down bars, we subtract 1 from the omegas before plotting, and suppress the y-axis. We later add a y-axis with labels where we add the 1 back again
    if(yAxisCenterAtNeutral) { 
        omegasToPlot <- omegas - 1 
        myYlim <- c(-1, maxOmegaForPlot - 1)
        axisTicks <- -1:(maxOmegaForPlot-1)
        axisLabels <- axisTicks + 1
    }
    
    alnLen <- BEBtable[ dim(BEBtable)[1], "pos" ]
    plot(BEBtable[,"pos"], omegasToPlot, "h", col=barCol,
         #xlim=c(0,alnLen*1.2), 
         ylim=myYlim, 
         xlab=xlab, ylab=ylab, yaxt="n", 
         bty="n", las=1, mgp=c(2,0.75,0), ... )
    if(!is.null(title)) { title(main=title, line=0) }
    # add the y-axis:
    axis(side=2, at=axisTicks, labels=axisLabels, las=1, mgp=c(1.5,0.75,0)) 
    
    BEBprobsPosSel <- BEBtable[,dim(BEBtable)[2]]
    if(sum(is.na(BEBprobsPosSel))>0) {
        warnText <- "WARNING - there are 'nan' values in your rst file. That's weird"
        # cat(warnText)
        mtext(warnText, side=3, adj=1, col="red", outer=FALSE, line=-1, cex=1)
    }
    
    # highlight sites with BEB >= a threshold
    if(highlightHighBEB) {
        if (sum(BEBprobsPosSel >= highBEBthreshold, na.rm=TRUE) > 0) {
            BEBtable_justPosSelSites <- BEBtable[which(BEBprobsPosSel >= highBEBthreshold),]
            omegasToPlot_justPosSelSites <- omegasToPlot[which(BEBprobsPosSel >= highBEBthreshold)]
            segments(x0=BEBtable_justPosSelSites[,"pos"], y0=0,
                     x1=BEBtable_justPosSelSites[,"pos"], 
                     y1=omegasToPlot_justPosSelSites, col=highBEBcolor)
            myLegend <- paste("Color=sites where BEB probability >=",highBEBthreshold)
            mtext(myLegend, side=1, adj=1, col=highBEBcolor, outer=TRUE)
        }
    }
}

###### plotOmegas_new: a ggplot-based function to plot the BEB mean dN/dS estimates at each site, with an option to color sites with high BEB probability
## uses the output of parseRSTfile
plotOmegas_new <- function(BEBtbl, title=NULL, barCol="grey", 
                           xlab="alignment position (codon)",
                           ylab="dN/dS estimate (BEB mean)",
                           highlightHighBEB=FALSE, highBEBthreshold=0.9,
                           highBEBcolor="red", 
                           ... ) {
    
    if(sum(is.na(BEBtbl$prob_class11))>0) {
        warning("WARNING - there are 'nan' values in your rst file. That's weird")
    }
    
    BEBtbl_to_plot <- BEBtbl %>% 
        dplyr::select(aln_pos, mean_omega, prob_class11) 
    if(highlightHighBEB) {
        BEBtbl_to_plot <- BEBtbl_to_plot %>% 
            mutate(my_color= case_when( 
                prob_class11>=highBEBthreshold ~ highBEBcolor,
                TRUE ~ barCol)) 
        myLegend <- paste("Color=sites where BEB probability >=",highBEBthreshold)
        my_plot <- BEBtbl_to_plot %>% 
            ggplot(aes(x=aln_pos, y=mean_omega, 
                       color=my_color, fill=my_color)) +
            scale_color_identity(guide = "legend") +
            scale_fill_identity(guide = "legend")
    } else {
        my_plot <- BEBtbl_to_plot %>% 
            ggplot(aes(x=aln_pos, y=mean_omega))
    }
    
    my_plot <- my_plot +
        geom_col(linewidth=0) +
        labs(x=xlab, y=ylab, title = title) +
        theme_classic() +
        guides(color="none", fill="none") +
        expand_limits(y = 0)
    
    if(highlightHighBEB) {
        my_plot <- my_plot + labs(subtitle=myLegend)
    }
    return(my_plot)
}



############## branch PAML functions

### parseMLCbranches: a function to parse the mlc file output of BRANCH paml
# output: a list of two objects:
# - the tree (read from the 'w ratios as labels' section)
# - the table of estimates for each branch
## if tidyverseStyle=TRUE, the table will be a tibble with clean_names
parseMLCbranches <- function(mlcFile,
                             tidyverseStyle=FALSE) {
    require(ape)
    message("reading file ",mlcFile,"\n")
    
    ### some checks on the inputs
    if(!file.exists(mlcFile)) {
        stop("\n\nERROR - the mlc file you specified does not exist:",mlcFile,"\n\n")
    }
    
    ########## process the mlc file
    
    ## read in whole mlc file:
    mlc <- scan(mlcFile, what="character", sep="\n", quiet=TRUE)
    
    ## check it looks about right:
    headerStringToSearchFor <- "^CODONML \\(in paml version"
    if (!grepl(headerStringToSearchFor, mlc[1])) {
        ## try to find that expected first line elsewhere in the file:
        expectedFirstLineLocations <- grep(headerStringToSearchFor, mlc)
        ## if we found it just once, we ignore any lines before that:
        if(length(expectedFirstLineLocations)==1) {
            mlc <- mlc[expectedFirstLineLocations:length(mlc)]
        }
        ## if we didn't find it, we have a problem
        if(length(expectedFirstLineLocations)==0) {
            stop("\n\nERROR - the mlc file you specified does not look right - there should be a single line somewhere, probably near the top, that begins with", headerStringToSearchFor, ". I did not see any lines that look like that\n\n")
        }
        if(length(expectedFirstLineLocations)>1) {
            stop("\n\nERROR - the mlc file you specified does not look right - there should be a single line somewhere, probably near the top, that begins with ", headerStringToSearchFor, ". I see multiple lines that look like that\n\n")
        }
        ## check again - don't think this will ever fail: the above if statements should have caught all possible situations before we get to this line
        if (!grepl(headerStringToSearchFor, mlc[1])) {
            stop("\n\nERROR - the mlc file you specified does not look right - there should be a single line somewhere, probably near the top, that first line usually begins with ", headerStringToSearchFor, "\n\n")
        }
    }
    
    ### extract the labelled tree - this should be able to handle output from at least a couple of PAML versions (4.8 and 4.10.6)
    headersForTreePortionOfMLCfile <- c("^w ratios as labels for TreeView:", 
                                        "^w ratios as node labels:")
    
    findTreeHeaderLines <- lapply(headersForTreePortionOfMLCfile, function(x) {
        grep(x, mlc)
    } )
    findTreeHeaderLines <- unique(unlist(findTreeHeaderLines))
    if(length(findTreeHeaderLines) != 1) {
        errorString <- paste(
            "\n\n",
            "ERROR - is this really BRANCH-wise PAML output?  ", 
            "The mlc file you specified does not look right - there is usually a line near the bottom that contains one of these strings:\n",
            headersForTreePortionOfMLCfile,
            "\n\n",sep="\n")
        stop(errorString)
    }
    
    ## get the tree
    lineContainingWratioTree <- findTreeHeaderLines + 1
    tree <- mlc[lineContainingWratioTree]
    # strip out w ratio labels
    tree <- gsub(" #\\d+.\\d+ ","",tree, perl=TRUE)
    # make into an object the ape package understands
    tree <- read.tree(text=tree)
    
    ## get the table of branch values:
    firstLineOfTable <- grep ("^ branch   ", mlc) 
    lastLineOfTable <- grep ("^tree length for dN:  ", mlc) - 1
    headerLine <- strsplit(mlc[firstLineOfTable], "\\s+")[[1]]
    tableLines <- mlc[(firstLineOfTable+1):lastLineOfTable]
    tableLines <- strsplit(tableLines, "\\s+")
    myTable <- do.call(rbind.data.frame, tableLines)
    colnames(myTable) <- headerLine
    myTable <- myTable[2:dim(myTable)[2]]
    
    ## get terminal node labels:
    nodeLabelsTemp <- gsub(" ","", mlc[grep ("^#", mlc) ])
    nodeLabelsTemp <- gsub("#","", nodeLabelsTemp)
    nodeLabelsTemp <- strsplit( nodeLabelsTemp, "\\:") 
    nodeLabels <- sapply( nodeLabelsTemp, "[[", 2)
    names(nodeLabels) <- sapply( nodeLabelsTemp, "[[", 1)
    rm(nodeLabelsTemp)
    
    ## relabel terminal branches with names not numbers
    myTable[,"branchEnd1"] <- sapply(strsplit( as.character(myTable[,"branch"]), "\\.\\."), "[[", 1)
    myTable[,"branchEnd2"] <- sapply(strsplit( as.character(myTable[,"branch"]), "\\.\\."), "[[", 2)
    myTable[,"branchEnd2name"] <- myTable[,"branchEnd2"] 
    myTable[match( names(nodeLabels), myTable[,"branchEnd2name"] ) ,"branchEnd2name"] <- nodeLabels
    
    myTable[,"newBranchLabel"] <- paste( myTable[,"branchEnd1"], "..", myTable[,"branchEnd2name"], sep="")
    
    ## make some nice edge labels for the tree, to reflect the omega, etc
    myTable[,"omega_NS"] <- paste( 
        round(as.numeric(as.character(myTable[,"dN/dS"])),2), "\n(", 
        myTable[,"N*dN"], ",", myTable[,"S*dS"], ")", sep="" )
    
    myTable[,"omega_dNdS"] <- paste( round(as.numeric(as.character(myTable[,"dN/dS"])),2), "\n(", 
                                     round(as.numeric(as.character(myTable[,"dN"])),2), ",", 
                                     round(as.numeric(as.character(myTable[,"dS"])),2), ")", sep="" )
    
    myTable[,"myOmegas"] <- as.character(myTable[,"dN/dS"])
    
    ### make some columns numeric
    numericColnames <- c("t", "N", "S", 
                         "dN/dS", "dN", "dS", 
                         "N*dN", "S*dS", "branchEnd1", "branchEnd2",
                         "myOmegas")
    for (eachColname in numericColnames) {
        myTable[,eachColname] <- as.numeric(as.character(myTable[,eachColname]))
    }
    
    ## maybe convert to tibble
    if(tidyverseStyle) {
        require(tidyr)
        require(janitor)
        myTable <- clean_names(as_tibble(myTable))
    }
    
    return(list(tree=tree, table=myTable))
}

#### plotTree: a function to plot branch PAML output. 
# input = the output of parseMLCbranches and creates a plot of the tree, with branch labels showing dN/dS, D and S
plotTree <- function(phymlTree, mlcTable, myTitle=NULL, 
                     labelType="omega_NS", 
                     addScaleBar=FALSE, myScaleBarLength=0.5,
                     myScaleBarPosition="topleft", scaleBarFontSize=0.5,
                     branchLabelFontSize=0.5, taxonLabelFontSize=0.75,
                     colorHighOmega=TRUE, 
                     colorHighOmegaThreshold=1,
                     colorHighOmegaThresholdNxN=0,
                     highOmegaColor="red",
                     stripOffTaxonNames=NULL) {
    require(ape)
    ######### some checks on the inputs
    acceptableLabelTypes <- c("omega_NS", "omega_dNdS")
    if (!labelType %in% acceptableLabelTypes) {
        stop("\n\nERROR - label type is not recognized: ", labelType, 
             "\nShould be one of these: ",paste(acceptableLabelTypes,collapse=" "),"\n\n")
    }
    
    ######### now get those N/S values onto the tree
    ## figure out how to match up edge labels with phymlTree$edge
    treeFileEdgeOrder <-  phymlTree$edge[,2]
    treeFileEdgeOrder[match(1:length(phymlTree$tip), treeFileEdgeOrder )] <- phymlTree$tip
    treeFileEdgeOrder <- paste( phymlTree$edge[,1], "..", 
                                treeFileEdgeOrder, 
                                sep="")
    
    if (!identical( treeFileEdgeOrder, mlcTable[,"newBranchLabel"] )) {
        #if (!identical( treeFileEdgeOrder, names(mlcTable[,"newBranchLabel"] ))) {
        #if (sum( treeFileEdgeOrder != mlcTable[,"newBranchLabel"] )>0) {
        cat ("\n\nERROR  - cannot match up the branches in the tree and the mlc table. Tree nodes probably received different numerical labels in the mlc file and when the read.tree function read the tree file in to R\n\n")
        return(treeFileEdgeOrder)
    }
    myLabels <- mlcTable[,labelType]
    myOmegas <- mlcTable[,"myOmegas"]
    myNdNs <- mlcTable[,"N*dN"]
    
    ## set up scale bar position
    scaleBarX <- NA
    scaleBarY <- NA
    if (grepl("left", myScaleBarPosition)) { scaleBarX <- 0 }
    if (grepl("right", myScaleBarPosition)) { scaleBarX <- max(node.depth(phymlTree)) }
    if (grepl("bottom", myScaleBarPosition)) { scaleBarY <- 0 }
    if (grepl("top", myScaleBarPosition)) { scaleBarY <- length(phymlTree$tip) }
    
    ## get label colors
    myLabelColors <- rep("black", length(myLabels))
    if (colorHighOmega) { 
        myLabelColors[which(
            (myOmegas > colorHighOmegaThreshold) & 
                (myNdNs >= colorHighOmegaThresholdNxN) )] <- highOmegaColor 
    }
    
    if(!is.null(stripOffTaxonNames)) {
        phymlTree$tip.label <- sapply(
            strsplit(phymlTree$tip.label, stripOffTaxonNames), "[[", 1)
    }
    
    #### plot
    ### if I am plotting a tree that does NOT have branchlengths, "node.depth=2" makes sense
    if (is.null(phymlTree$edge.length)) {
        plot(phymlTree, font=1, cex=taxonLabelFontSize, node.depth=2)
    } else {
        plot(phymlTree, font=1, cex=taxonLabelFontSize)
    }
    edgelabels(myLabels, frame="none", cex=branchLabelFontSize, col=myLabelColors)
    if (addScaleBar) {
        add.scale.bar(scaleBarX,scaleBarY, cex=0.7, font=scaleBarFontSize, length=myScaleBarLength )
    }
    if(!is.null(myTitle)) { title(main=myTitle) }
}


########### some functions for when I use ggtree



###### getTreeInfoJY - a utility function, as I'll never remember the name of that hidden function that gets info from the phylo and from the extraInfo table and combines them. Intended for treedata objects. 
getTreeInfoJY <- function(treedata_object, fullInfo=FALSE) {
    info <- tidytree:::.extract_annotda.treedata(treedata_object)
    
    ## some checking - node column is the only one I can check, I think. I don't know whether that .extract_annotda.treedata is guaranteed to give me info in the correct order
    if(!identical(info$node, treedata_object@extraInfo$node)) {
        warn("\n\nWARNING - the nodes are not in the same order in this new table as they are in the extraInfo portion of your treedata object\n\n")
    }
    
    if(fullInfo) {
        ## there are sometimes extra columns in the phylo object that we might want
        info2 <- as_tibble(treedata_object@phylo)
        newColumns <- setdiff(colnames(info2), colnames(info))
        info <- left_join(info, info2[,c("node",newColumns)], by="node")
        info <- info %>% 
            relocate(parent)
    }
    return(info)
}



###### addInfoToTree - make a treedata object (ggtree) by combining a phylo object with a tibble that has info on the tips
addInfoToTree <- function(tree, info, colnameForTaxonLabels="taxon") {
    require(ggtree)
    ##### get info in same order as taxa in the tree:
    if (! colnameForTaxonLabels %in% colnames(info)) {
        stop("\n\nERROR - there should be a ",colnameForTaxonLabels," column in the info table\n\n")
    }
    ## check all taxa are in the info table
    tipLabelsInInfoTable <- info %>% 
        dplyr::select(all_of(colnameForTaxonLabels)) %>% 
        deframe()
    if(length(setdiff(tree$tip.label, tipLabelsInInfoTable))>0) {
        stop("\n\nERROR - there are taxon labels in the tree that are not in the info table\n\n")
    }
    # now get info
    desiredRows <- match(tree$tip.label, tipLabelsInInfoTable)
    info_treeorder <- info[desiredRows,] 
    # add info to tree
    tree_withInfo <-  left_join(
        tree, 
        info_treeorder ,
        by=c("label"=colnameForTaxonLabels))
    return(tree_withInfo)
}

##### parseMLCbranches_new - a wrapper around treeio::read.codeml_mlc where we just add a few convenience columns
parseMLCbranches_new <- function(mlc_file, omega_digits=2) {
    require(treeio)
    read.codeml_mlc(mlc_file) %>% 
        mutate(branch_label=case_when(
            is.na(dN_vs_dS) ~ "",
            TRUE ~ paste(round(dN_vs_dS, digits=omega_digits), "\n(", 
                         N_x_dN, ",", S_x_dS, ")", sep=""))) %>% 
        ## add labelAgain because the tip labels get lost when I reroot, and this helps me keep them
        mutate(tip_label=label)
}


#### plotTree_new: a function to plot branch PAML output that I read in using parseMLCbranches_new (a wrapper around treeio::read.codeml_mlc)
# input = treedata object (output of parseMLCbranches)
# output = ggplot of the tree, with branch labels showing dN/dS, N and S
plotTree_new <- function(tree, 
                         removeBranchLengths=TRUE,
                         adjustBranchLabPos=0,
                         myTitle=NULL, 
                         addScaleBar=FALSE, 
                         myScaleBarLength=0.1,
                         branchLabelFontSize=3, taxonLabelFontSize=4,
                         colorHighOmega=TRUE, 
                         colorHighOmegaThreshold=1,
                         colorHighOmegaThresholdNxN=0,
                         highOmegaColor="red",
                         stripOffTaxonNames=NULL) {
    require(ggtree)
    if(removeBranchLengths) {
        tree@phylo$edge.length <- NULL
        addScaleBar <- FALSE
        adjustBranchLabPos <- -0.5
    }

    ## get label colors
    tree <- tree %>% 
        mutate(category = case_when(
            (dN_vs_dS > colorHighOmegaThreshold) &
                (N_x_dN >= colorHighOmegaThresholdNxN) ~ "interesting",
            TRUE ~ "not_interesting"
        )  ) 
    #### set color scheme
    colorScheme <- character()
    colorScheme["interesting"] <- "red"
    colorScheme["not_interesting"] <- "black"
    if(!colorHighOmega) { colorScheme["interesting"] <- "black"}
    
    ## plot tree
    myPlot <- ggtree(tree)  + 
            geom_tiplab(aes(label=tip_label),
                        size=taxonLabelFontSize) +     
        geom_nodelab(aes(label=branch_label,color=category),
                     node="all", 
                     size=branchLabelFontSize, 
                     hjust=0.5, nudge_x=adjustBranchLabPos ) +
        hexpand(0.5) +
        scale_color_manual(values=colorScheme) + 
        guides(color="none") 
    

    if(!is.null(myTitle)) { myPlot <- myPlot + labs(title=myTitle) }
    if (addScaleBar) {
        myPlot <- myPlot + geom_treescale(width=myScaleBarLength)
    }
    return(myPlot)
}


###### some utility functions for manipulating phylo/treedata objects. 
### xxx Maybe these should go in a different repo, as they're for more than just PAML stuff.

### getAncestor - I am sure there's a function to do this, but I don't know where I would find it
getAncestor <- function(tree, nodeID) {
    if(class(tree) != "phylo") {
        stop("\n\nERROR - the getAncestor function is intended for phylo class objects\n\n")
    }
    edge_mat <- tree$edge
    if(!nodeID %in% edge_mat[,2]) {
        stop("\n\nERROR - the node you specified does not have an ancestor\n\n")
    }
    anc <- edge_mat[which(edge_mat[,2]==nodeID),1]
    return(anc)
}
## example:
# my_node <- getMRCA(tree, c("taxon1", "taxon2"))
# my_anc <- getAncestor(tree, my_node)


###### getTreeInfoJY - a utility function, as I'll never remember the name of that hidden function that gets info from the phylo and from the extraInfo table and combines them. Intended for treedata objects. 
getTreeInfoJY <- function(treedata_object, fullInfo=FALSE) {
    info <- tidytree:::.extract_annotda.treedata(treedata_object)
    
    ## some checking - node column is the only one I can check, I think. I don't know whether that .extract_annotda.treedata is guaranteed to give me info in the correct order
    if(!identical(info$node, treedata_object@extraInfo$node)) {
        warn("\n\nWARNING - the nodes are not in the same order in this new table as they are in the extraInfo portion of your treedata object\n\n")
    }
    
    if(fullInfo) {
        ## there are sometimes extra columns in the phylo object that we might want
        info2 <- as_tibble(treedata_object@phylo)
        newColumns <- setdiff(colnames(info2), colnames(info))
        info <- left_join(info, info2[,c("node",newColumns)], by="node")
        info <- info %>% 
            relocate(parent)
    }
    return(info)
}

###### addInfoToTree - make a treedata object by combining a phylo object with a tibble that has info on the tips
addInfoToTree <- function(tree, info, colnameForTaxonLabels="taxon") {
    ##### get info in same order as taxa in the tree:
    if (! colnameForTaxonLabels %in% colnames(info)) {
        stop("\n\nERROR - there should be a ",colnameForTaxonLabels," column in the info table\n\n")
    }
    ## check all taxa are in the info table
    tipLabelsInInfoTable <- info %>% 
        dplyr::select(all_of(colnameForTaxonLabels)) %>% 
        deframe()
    if(length(setdiff(tree$tip.label, tipLabelsInInfoTable))>0) {
        stop("\n\nERROR - there are taxon labels in the tree that are not in the info table\n\n")
    }
    # now get info
    desiredRows <- match(tree$tip.label, tipLabelsInInfoTable)
    info_treeorder <- info[desiredRows,] 
    # add info to tree
    tree_withInfo <-  left_join(
        tree, 
        info_treeorder ,
        by=c("label"=colnameForTaxonLabels))
    return(tree_withInfo)
}


#### reroot_treedata_JY - reroots a treedata object and tries to restore the tip labels, which get lost along the way.   xxx there's room for improvement here and I'm not sure it'll always get it righ! more work needed
## but I need a function, because simply using root loses the tip labels. I think I submitted a github issue about this?
## rerooting a treedata object is tricky. If possible, do it BEFORE creating a treedata object. But that might not always be possible, e.g. if I've read tree using parseMLCbranches_new, which uses treeio::read.codeml_mlc
reroot_treedata_JY <- function(tree,
                               nodeID) {
    if(class(tree) != "treedata") {
        stop("\n\nERROR - this function is meant for treedata class objects\n\n")
    }
    ## this will let me get the tip labels back again
    tree_tbl <- getTreeInfoJY(tree)
    tip_info <- tree_tbl %>% 
        filter(isTip) %>% 
        dplyr::select(node,label) %>% 
        mutate(node=as.character(node))
    # return(tip_info)
    tree_rerooted <- root(tree, node=nodeID)
    
    tiplabs_after_reroot <- tree_rerooted@phylo$tip.label
    
    tiplabs_should_be <- tip_info[match(tiplabs_after_reroot, tip_info$node), "label"] %>% 
        deframe()
    tree_rerooted@phylo$tip.label <- tiplabs_should_be
    return(tree_rerooted)
}

