
# Regenie WDL Workflow

This WDL workflow runs [regenie](https://rgcgithub.github.io/regenie/) for GWAS/RVAS. This has been tested on the UKB RAP, but not elsewhere. 

This WDL parallelizes step 1 using the instructions [here](https://github.com/rgcgithub/regenie/wiki/Further-parallelization-for-level-0-models-in-Step-1). It calls 
regenie v4.0 via a docker container provided by the RGC developers. 

## Workflow Inputs

- `File step1_pvar`: The pvar file for step 1. Presumably, based on array genotypes have been filtered for MAF, HWE, missingness and LD pruned. 
- `File step1_psam`: The psam file for step 1.
- `File step1_pgen`: The pgen file for step 1.
- `String step1_prefix`: The prefix for step 1 output files.
- `Array[File] pvar`: An array of pvar files for step 2.
- `Array[File] psam`: An array of psam files for step 2.
- `Array[File] pgen`: An array of pgen files for step 2.
- `Array[String] step2_prefix`: An array of prefixes for step 2 output files.
- `String covariate_string`: A string of covariate column names.
- `String categorical_covariate_string`: A string of categorical covariate column names.
- `File covariates`: The covariates file.
- `File phenotypes`: The phenotypes file.
- `Int n_step1`: The number of "l0" jobs in step 1 to parallelize over. 
 
## Workflow Outputs

- `File loco_list`: The list of LOCO predictions from step 1.
- `Array[File] locos`: The array of LOCO files from step 1.
- `Array[Array[File]] summary_stats`: The summary statistics files from step 2.
- `File parquet`: The concatenated files from step2 into a single parquet file.

## Contact
Contact Josh Weinstock for details on the WDL. 
Note, this repo has no affiliation with the Regenie developers. 

If you use this, please credit the regenie developers. 
