# pamlApps
utilities to parse and plot PAML output

Janet Young, August 2021

Malik lab
Division of Basic Sciences
Fred Hutchinson Cancer Research Center


Code: https://github.com/jayoung/pamlApps

Web utility: https://jyoungfhcrc.shinyapps.io/pamlApps/

Two types of analysis (one app for each):
- for sitewise PAML results (e.g. model 8), display dN/dS for each site, or BEB probabilities for each site.
- for branch PAML results, display tree with labels showing dN/dS and N\*dN and S\*dS


To run code within R, see `demo_code.R`.  To run on the web, go to https://jyoungfhcrc.shinyapps.io/pamlApps/



Files in this repository: 
- `parseAndPlotPAML_functions.R` contains code for relevant functions.

- `demo_code.R` shows how to run code within R (using files in the `data` directory)

- `app.R` is a shiny app to run this code


Note - looks like the ggtree package has some useful functions that my code duplicates. Functions from ggtree to explore: `read.codeml read.codeml_mlc read.paml_rst`
I could also make fancier tree plots for branch PAML this way.

## App 1 - sitewise PAML

Input = an rst file (output of site-wise PAML, e.g. model 8).

Output options:  
- 1. a comma-separated version of the BEB results table that's easier to read into Excel than the original rst file, in case you want to play around with making plots yourself.
- 2. a plot of the BEB mean dN/dS estimate at each site
- 3. a plot of the BEB probabilities of each site being in the positively selected class

For an example of how this sort of analysis is used, see Fig 6C of a paper on tetherin evolution: https://pubmed.ncbi.nlm.nih.gov/32238588/


R functions:
- `parseRSTfile` : reads in the rst file, yields a data.frame of the parsed BEB table
- `plotProbs` : plot BEB probabilities by site
- `plotOmegas` : plot dN/dS by site, highlighting sites with high BEB probability of being under positive selection


## App 2 - branch PAML

Input = an mlc file (output of branch-wise PAML).

Output = a plot showing the tree with branch labels showing dN/dS (above the branch) and N and S (the number of non-synonymous and synonymous changes) shown in parentheses below the branch. 

For an example of how this sort of analysis is used, see Fig 1a of Nels Elde's 2009 paper on PKR evolution: https://pubmed.ncbi.nlm.nih.gov/19043403/


R functions:
- `parseMLCbranches` reads in the mlc file, and parses it to obtain the tree and the table of numbers of non-synonymous and synonymous changes for each branch
- `plotTree` takes a tree and table, and makes a plot with branch labels showing the dN/dS etc 


## to do
- maybe, for branch PAML, make small legend to show labelType
- for sites plot, add ability to make a protein domain cartoon, if user uploads coordinates
- sites:  Ching-Ho and Risa both had alignments that gave WEIRD BEB results that contain `nan' values and therefore cannot be plotted


# fixing sites NAN issue:

Sites:  Ching-Ho and Risa both had alignments that gave WEIRD BEB results that contain `nan' values and could not be plotted by the shiny app. I have now fixed the shiny app to be able to handle that

```
cd ~/FH_fast_storage/paml_screen/pamlApps/data/other_tests
runPAML.pl CG31882_sim.fa
```

another example:
```
cd ~/FH_fast_storage/paml_screen/pamlWrapperTestAlignments/testUserTree/Dmel_22_aln.fasta_phymlAndPAML
```


But I still don't know WHY the 'nan' values appear. 

look at rst file. figure out what's going on (maybe)

the docker image uses a different version of paml than I get when I use command line.
command line: 4.8 (?) installed Jul 30  2014.
this does NOT give me the nan values

docker:  
RUN conda install paml --channel bioconda
CODONML in paml version 4.9, March 2015
this DOES give me the nan values.

xxx try installing 4.9j locally and seeing how that behaves
CODONML in paml version 4.9j, February 2020
this DOES NOT give me the nan values.

Turns out there was a weird bug in PAML for a while
https://groups.google.com/g/pamlsoftware/c/HXxqYBHYbRU/m/lLwe1V4CAwAJ
that has now been solved. But I think the version of PAML that is in my docker container suffers from this bug.

Next:  update our gizmo version of PAML
update the version of PAML I'm using within Docker. Probably need to build from source rather than use the bioconda version. I do this for phyml and it works fine.

