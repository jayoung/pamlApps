pamlApps demo code
================
Janet Young

2024-09-06

# sitewise PAML

Read a model 8 rst file:

## look at table for sites where BEB \>= 0.90

    ##     pos human_ACE2_ORF bestClass meanOmega prob_class1_omega_0
    ## 78   78              T        11     3.477               0e+00
    ## 218 218              S        11     3.519               0e+00
    ## 653 653              Q        11     3.563               0e+00
    ## 658 658              V        11     3.573               0e+00
    ## 706 706              M        11     3.549               0e+00
    ## 716 716              R        11     3.488               1e-05
    ## 728 728              Q        11     3.354               7e-05
    ## 729 729              P        11     3.290               9e-05
    ## 732 732              G        11     3.502               0e+00
    ##     prob_class2_omega_0 prob_class3_omega_0 prob_class4_omega_0
    ## 78              0.00004             0.00018             0.00052
    ## 218             0.00002             0.00011             0.00031
    ## 653             0.00000             0.00001             0.00006
    ## 658             0.00000             0.00001             0.00004
    ## 706             0.00000             0.00002             0.00009
    ## 716             0.00007             0.00025             0.00061
    ## 728             0.00033             0.00102             0.00212
    ## 729             0.00043             0.00132             0.00274
    ## 732             0.00003             0.00014             0.00039
    ##     prob_class5_omega_0 prob_class6_omega_8e-05 prob_class7_omega_0.36634
    ## 78              0.00110                 0.00198                   0.00320
    ## 218             0.00067                 0.00123                   0.00201
    ## 653             0.00016                 0.00035                   0.00066
    ## 658             0.00010                 0.00022                   0.00042
    ## 706             0.00024                 0.00052                   0.00097
    ## 716             0.00117                 0.00198                   0.00304
    ## 728             0.00362                 0.00548                   0.00768
    ## 729             0.00465                 0.00698                   0.00972
    ## 732             0.00084                 0.00153                   0.00249
    ##     prob_class8_omega_0.99986 prob_class9_omega_1 prob_class10_omega_1
    ## 78                    0.00483             0.00721              0.01968
    ## 218                   0.00308             0.00466              0.01289
    ## 653                   0.00113             0.00190              0.00571
    ## 658                   0.00073             0.00124              0.00375
    ## 706                   0.00166             0.00276              0.00825
    ## 716                   0.00444             0.00647              0.01734
    ## 728                   0.01031             0.01394              0.03484
    ## 729                   0.01295             0.01737              0.04302
    ## 732                   0.00378             0.00569              0.01566
    ##     prob_class11_omega_4.69678
    ## 78                     0.96127
    ## 218                    0.97502
    ## 653                    0.99001
    ## 658                    0.99350
    ## 706                    0.98547
    ## 716                    0.96461
    ## 728                    0.92060
    ## 729                    0.90073
    ## 732                    0.96945

## plot BEB mean dN/dS estimate

![](demo_code_files/figure-gfm/unnamed-chunk-3-1.png)<!-- -->

plot BEB mean dN/dS estimate in a visually unusual way, where bars all
start at dN/dS=1. Our tetherin collaborators liked seeing the results
this way but it is not intuitive: makes it look like most sites have
dN/dS=1.

![](demo_code_files/figure-gfm/unnamed-chunk-4-1.png)<!-- -->

plot BEB probabilities of being in the positively selected class

![](demo_code_files/figure-gfm/unnamed-chunk-5-1.png)<!-- -->

# Finished

show R version used, and package versions

    ## R version 4.4.0 (2024-04-24)
    ## Platform: x86_64-apple-darwin20
    ## Running under: macOS Ventura 13.6.9
    ## 
    ## Matrix products: default
    ## BLAS:   /Library/Frameworks/R.framework/Versions/4.4-x86_64/Resources/lib/libRblas.0.dylib 
    ## LAPACK: /Library/Frameworks/R.framework/Versions/4.4-x86_64/Resources/lib/libRlapack.dylib;  LAPACK version 3.12.0
    ## 
    ## locale:
    ## [1] en_US.UTF-8/en_US.UTF-8/en_US.UTF-8/C/en_US.UTF-8/en_US.UTF-8
    ## 
    ## time zone: America/Los_Angeles
    ## tzcode source: internal
    ## 
    ## attached base packages:
    ## [1] stats     graphics  grDevices utils     datasets  methods   base     
    ## 
    ## other attached packages:
    ##  [1] kableExtra_1.4.0 patchwork_1.2.0  janitor_2.2.0    lubridate_1.9.3 
    ##  [5] forcats_1.0.0    stringr_1.5.1    dplyr_1.1.4      purrr_1.0.2     
    ##  [9] readr_2.1.5      tidyr_1.3.1      tibble_3.2.1     ggplot2_3.5.1   
    ## [13] tidyverse_2.0.0  here_1.0.1      
    ## 
    ## loaded via a namespace (and not attached):
    ##  [1] gtable_0.3.5      highr_0.11        compiler_4.4.0    tidyselect_1.2.1 
    ##  [5] xml2_1.3.6        snakecase_0.11.1  systemfonts_1.1.0 scales_1.3.0     
    ##  [9] yaml_2.3.8        fastmap_1.2.0     R6_2.5.1          generics_0.1.3   
    ## [13] knitr_1.47        munsell_0.5.1     rprojroot_2.0.4   svglite_2.1.3    
    ## [17] pillar_1.9.0      tzdb_0.4.0        rlang_1.1.4       utf8_1.2.4       
    ## [21] stringi_1.8.4     xfun_0.45         viridisLite_0.4.2 timechange_0.3.0 
    ## [25] cli_3.6.3         withr_3.0.0       magrittr_2.0.3    digest_0.6.36    
    ## [29] grid_4.4.0        rstudioapi_0.16.0 hms_1.1.3         lifecycle_1.0.4  
    ## [33] vctrs_0.6.5       evaluate_0.24.0   glue_1.7.0        fansi_1.0.6      
    ## [37] colorspace_2.1-0  rmarkdown_2.27    tools_4.4.0       pkgconfig_2.0.3  
    ## [41] htmltools_0.5.8.1
