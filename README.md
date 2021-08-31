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
