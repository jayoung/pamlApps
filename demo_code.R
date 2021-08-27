setwd("/Volumes/malik_h/user/jayoung/paml_screen/pamlApps")


######### sitewise PAML
ACE2_sitePAML_rstFile <- "data/example_ACE2/M8_initOmega0.4_codonModel2/rst"

## get the BEB table as a data.frame
ACE2siteResults <- parseRSTfile(ACE2_sitePAML_rstFile)

## look at table for sites where BEBE >= 0.90
ACE2siteResults[which(ACE2siteResults[,"prob_class11_omega_4.6967"] >= 0.90),]

## plot BEB mean dN/dS estimate
plotOmegas(ACE2siteResults, 
           title="ACE2 model 8 BEB mean dN/dS estimates", 
           highlightHighBEB=TRUE, 
           highBEBthreshold=0.90, 
           highBEBcolor="red")

## plot BEB mean dN/dS estimate in a visually unusual way, where bars all start at dN/dS=1. Our tetherin collaborators liked seeing the results this way but it is not intuitive: makes it look like most sites have dN/dS=1.
plotOmegas(ACE2siteResults, 
           title="ACE2 primates: model 8 BEB mean dN/dS estimates", 
           highlightHighBEB=TRUE, 
           highBEBthreshold=0.90, 
           highBEBcolor="red", 
           yAxisCenterAtNeutral=TRUE)

## plot BEB probabilities of being in the positively selected class
plotProbs(ACE2siteResults, 
          title="ACE2 primates: M8 BEB probabilities of positive selection",
          addThresholdLine=TRUE, 
          threshold=0.90, 
          thresholdLineColor="red",
          highlightHighBEB=TRUE, 
          highBEBthreshold=0.90, 
          highBEBcolor="blue")



########## branch PAML
ACE2_branchPAML_mlcFile <- "data/example_ACE2/BRANCHpaml_initOmega0.4_codonModel2/mlc"

## read in the mlc file from branch PAML. Returns a list with two named elements: 
# 1. 'tree' - the 'w labels' tree
# 2. 'table' - a data.frame containing the table of estimates for each branch. I also do some parsing to help me figure out which nodes/branches are which, and to generate labels for each branch
ACE2branchResults <- parseMLCbranches(ACE2_branchPAML_mlcFile)

## plot the tree, color any label where dN/dS > 1
plotTree(phymlTree=ACE2branchResults[["tree"]], 
         mlcTable=ACE2branchResults[["table"]], 
         labelType="omega_NS",
         myTitle="ACE2 primates: branch PAML", 
         colorHighOmega=TRUE, 
         colorHighOmegaThreshold=1, 
         highOmegaColor="red")

