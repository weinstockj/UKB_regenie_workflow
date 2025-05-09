
# Regenie WDL Workflow

This WDL workflow runs [regenie](https://rgcgithub.github.io/regenie/) for GWAS/RVAS. This has been tested on the UKB RAP, but not elsewhere.

This WDL parallelizes step 1 using the instructions [here](https://github.com/rgcgithub/regenie/wiki/Further-parallelization-for-level-0-models-in-Step-1). It calls 
regenie v4.1 via a docker container provided by the RGC developers.

## Available Workflows

- `regenie_qt.WDL`: Workflow for quantitative traits
- `regenie_bt.WDL`: Workflow for binary traits

Both workflows share the same structure and inputs, using a manifest file for step 2 chunks and plink2 filtering.

## Workflow Inputs

Both workflows (regenie_qt.WDL and regenie_bt.WDL) share the same input parameters:

- `File step1_pvar`: The pvar file for step 1. Presumably, based on array genotypes have been filtered for MAF, HWE, missingness and LD pruned. 
- `File step1_psam`: The psam file for step 1.
- `File step1_pgen`: The pgen file for step 1.
- `String step1_prefix`: The prefix for step 1 output files.
- `File step2_chunk_manifest`: The manifest file for step 2. This is a TSV listing chromosome regions and their corresponding pvar, psam, and pgen files. See below for details.
- `String covariate_string`: A string of covariate column names.
- `String categorical_covariate_string`: A string of categorical covariate column names.
- `File plink2_binary`: The plink2 binary file (zip archive). This is used to filter variants in step2 for improved performance.
- `File covariates`: The covariates file.
- `File phenotypes`: The phenotypes file.
- `Boolean concatenate_into_parquet`: Whether to concatenate the summary statistics into a single parquet file.
- `Int n_step1`: The number of "l0" jobs in step 1 to parallelize over.
- `Boolean fix_step2_header_for_rap`: The plink2 psam files from UKB RAP may have formatting issues. Setting this to true applies a workaround to fix the header.
- `Int minMAC`: The minimum minor allele count for variants in step 2 (default: 10).
- `Int threads`: Number of threads to use for computation (default: 8).
- `Int step1_block_size`: Block size for step 1 (default: 500).
- `Int step2_block_size`: Block size for step 2 (default: 250).


### Step2 chunk manifest

```
> glimpse(manifest)
Rows: 316
Columns: 10
$ chrom                  <chr> "chr1", "chr1", "chr1", "chr1", "chr1", "chr1", "chr1", "chr1", "chr1", "chr1", "chr1", "chr1", "chr1", "chr1", "chr1", "chr1", "chr1"…
$ start                  <dbl> 1, 10000001, 20000001, 30000001, 40000001, 50000001, 60000001, 70000001, 80000001, 90000001, 100000001, 110000001, 120000001, 13000000…
$ end                    <dbl> 10000000, 20000000, 30000000, 40000000, 50000000, 60000000, 70000000, 80000000, 90000000, 100000000, 110000000, 120000000, 130000000, …
$ range                  <glue> "1:1-10000000", "1:10000001-20000000", "1:20000001-30000000", "1:30000001-40000000", "1:40000001-50000000", "1:50000001-60000000", "1…
$ plink2_chrom_pvar_name <glue> "/Bulk/DRAGEN WGS/DRAGEN population level WGS variants, PLINK format [500k release]/ukb24308_c1_b0_v1.pvar", "/Bulk/DRAGEN WGS/DRAGEN…
$ plink2_chrom_psam_name <glue> "/Bulk/DRAGEN WGS/DRAGEN population level WGS variants, PLINK format [500k release]/ukb24308_c1_b0_v1.psam", "/Bulk/DRAGEN WGS/DRAGEN…
$ plink2_chrom_pgen_name <glue> "/Bulk/DRAGEN WGS/DRAGEN population level WGS variants, PLINK format [500k release]/ukb24308_c1_b0_v1.pgen", "/Bulk/DRAGEN WGS/DRAGEN…
$ plink2_chrom_pvar      <chr> "file-Gjx9g7jJ8yxYff6BB47xf8f1", "file-Gjx9g7jJ8yxYff6BB47xf8f1", "file-Gjx9g7jJ8yxYff6BB47xf8f1", "file-Gjx9g7jJ8yxYff6BB47xf8f1", "f…
$ plink2_chrom_psam      <chr> "file-GzbyjvQJBx1VF1BGV57PGy64", "file-GzbyjvQJBx1VF1BGV57PGy64", "file-GzbyjvQJBx1VF1BGV57PGy64", "file-GzbyjvQJBx1VF1BGV57PGy64", "f…
$ plink2_chrom_pgen      <chr> "file-Gjx8kF0J8yxpF75qxKgg261X", "file-Gjx8kF0J8yxpF75qxKgg261X", "file-Gjx8kF0J8yxpF75qxKgg261X", "file-Gjx8kF0J8yxpF75qxKgg261X", "f…
```

## Workflow Outputs

- `File loco_list`: The list of LOCO predictions from step 1.
- `Array[File] locos`: The array of LOCO files from step 1.
- `Array[Array[File]] summary_stats`: The summary statistics files from step 2.
- `File parquet`: The concatenated files from step2 into a single parquet file.

## Dependencies

This project uses [uv](https://github.com/rgcgithub/regenie/wiki/Further-parallelization-for-level-0-models-in-Step-1) for python dependencies (e.g,. `dxpy`), 
though this not essential. 

## Contact
Contact Josh Weinstock for details on the WDL. 
Note, this repo has no affiliation with the REGENIE developers; please contact them for questions about REGENIE itself.

If you use this, please credit the regenie developers. 
