version 1.0
workflow regenie_bt {

    input {

        File step1_pvar
        File step1_psam
        File step1_pgen
        String step1_prefix
        Array[File] pvar
        Array[File] psam
        Array[File] pgen
        Array[String] step2_prefix
        String covariate_string
        String categorical_covariate_string
        File covariates
        File phenotypes
        Int n_step1 = 16
        Int n_step2 = 22
        Int minMAC = 10
        Int threads = 8 
        Int step1_block_size = 500
        Int step2_block_size = 250
        Boolean concatenate_into_parquet = false
    }

    call step1_split_l0 {

        input:
            pvar = step1_pvar,
            psam = step1_psam,
            pgen = step1_pgen,
            plink2_prefix = step1_prefix,
            covariates = covariates,
            covariate_string = covariate_string,
            categorical_covariate_string = categorical_covariate_string,
            phenotypes = phenotypes,
            bsize = step1_block_size,
            njobs = n_step1,
            threads = 4
    }

    scatter(j in range(n_step1)) {
        call step1_run_l0 {

            input:
                pvar = step1_pvar,
                psam = step1_psam,
                pgen = step1_pgen,
                plink2_prefix = step1_prefix,
                covariates = covariates,
                covariate_string = covariate_string,
                categorical_covariate_string = categorical_covariate_string,
                phenotypes = phenotypes,
                job = j + 1, # idx is 0-based
                master = step1_split_l0.master,
                snplist = step1_split_l0.snplist,
                bsize = step1_block_size,
                threads = threads
        }
    }

    call step1_run_l1 {
        input:
                pvar = step1_pvar,
                psam = step1_psam,
                pgen = step1_pgen,
                plink2_prefix = step1_prefix,
                covariates = covariates,
                covariate_string = covariate_string,
                categorical_covariate_string = categorical_covariate_string,
                phenotypes = phenotypes,
                master = step1_split_l0.master,
                snplist = step1_split_l0.snplist,
                level_0_list = flatten(step1_run_l0.level_0_list),
                bsize = step1_block_size,
                threads = threads
    }

    
    scatter(i in range(n_step2)) {

        call step2 {

            input:
                psam = psam[i],
                pvar = pvar[i],
                pgen = pgen[i],
                plink2_prefix = step2_prefix[i],
                out_prefix = "chunk_~{i + 1}",
                locos = step1_run_l1.locos,
                loco_list = step1_run_l1.loco_list,
                covariates = covariates,
                covariate_string = covariate_string,
                categorical_covariate_string = categorical_covariate_string,
                bsize = step2_block_size,
                minMAC = minMAC,
                threads = threads,
                phenotypes = phenotypes
        }
    }

    if(concatenate_into_parquet) {
        call concatenate {
            input: 
                summary_stats = flatten(step2.rg_output)
        }
    }


    output {

        File loco_list                   = step1_run_l1.loco_list
        Array[File] locos                = step1_run_l1.locos
        Array[Array[File]] summary_stats = step2.rg_output
        Array[File] step2_log            = step2.log
        File? parquet                     = concatenate.parquet
        File step1_log                   = step1_run_l1.log

    }

}

task step1_split_l0 {

    input {

        File psam
        File pvar
        File pgen
        String plink2_prefix
        File covariates
        String covariate_string
        String categorical_covariate_string
        File phenotypes
        Int bsize 
        Int threads 
        Int njobs
    }

    command <<<

        echo "$(date -u) start now"

        ln -s ~{psam} ~{plink2_prefix}.psam
        ln -s ~{pvar} ~{plink2_prefix}.pvar
        ln -s ~{pgen} ~{plink2_prefix}.pgen

        regenie --step 1 \
          --bt \
          --loocv \
          --covarFile ~{covariates} \
          --covarColList ~{covariate_string} \
          --catCovarList ~{categorical_covariate_string} \
          --phenoFile ~{phenotypes} \
          --bsize ~{bsize} \
          --gz \
          --pgen ~{plink2_prefix} \
          --threads ~{threads} \
          --out fit_bin_l0 \
          --split-l0 fit_bin_parallel,~{njobs}
            
        ls -alh fit_bin_l0
        echo "$(date -u) done now"
    >>>

    runtime {
        docker: "ghcr.io/rgcgithub/regenie/regenie:v4.0.gz"
        dx_instance_type: "mem2_ssd1_v2_x4"
    }

    output {
        File master = "fit_bin_parallel.master"
        Array[File] snplist = glob("fit_bin_parallel_job*.snplist")
    }

}

task step1_run_l0 {

    input {

        File psam
        File pvar
        File pgen
        String plink2_prefix
        File covariates
        String covariate_string
        String categorical_covariate_string
        File phenotypes
        File master
        Array[File] snplist 
        Int job
        Int bsize 
        Int threads 
    }

    command <<<

        echo "$(date -u) start now"

        ln -s ~{psam} ~{plink2_prefix}.psam
        ln -s ~{pvar} ~{plink2_prefix}.pvar
        ln -s ~{pgen} ~{plink2_prefix}.pgen
        ln -s ~{master} fit_bin_parallel.master

        for list in ~{sep=' ' snplist}; do 
            ln -s ${list} .
        done

        ls -alh

        regenie --step 1 \
          --bt \
          --loocv \
          --covarFile ~{covariates} \
          --covarColList ~{covariate_string} \
          --catCovarList ~{categorical_covariate_string} \
          --phenoFile ~{phenotypes} \
          --bsize ~{bsize} \
          --gz \
          --pgen ~{plink2_prefix} \
          --threads ~{threads} \
          --run-l0 fit_bin_parallel.master,~{job} \
          --out fit_bin_l0_~{job}
            
        ls -alh fit_bin_l0_~{job}
        echo "$(date -u) done now"
    >>>

    runtime {
        docker: "ghcr.io/rgcgithub/regenie/regenie:v4.0.gz"
        dx_instance_type: "mem2_ssd1_v2_x8"
    }

    output {
        Array[File] level_0_list = glob("fit_bin_parallel_job~{job}_l0_Y*")
    }

}

task step1_run_l1 {

    input {

        File psam
        File pvar
        File pgen
        String plink2_prefix
        File covariates
        String covariate_string
        String categorical_covariate_string
        File phenotypes
        File master
        Array[File] snplist 
        Array[File] level_0_list
        Int bsize 
        Int threads 
    }

    command <<<

        echo "$(date -u) start now"

        ln -s ~{psam} ~{plink2_prefix}.psam
        ln -s ~{pvar} ~{plink2_prefix}.pvar
        ln -s ~{pgen} ~{plink2_prefix}.pgen
        ln -s ~{master} fit_bin_parallel.master

        for list in ~{sep=' ' snplist}; do 
            ln -s ${list} .
        done

        for list in ~{sep=' ' level_0_list}; do 
            echo $list
            ln -s ${list} .
        done

        regenie --step 1 \
          --bt \
          --loocv \
          --covarFile ~{covariates} \
          --covarColList ~{covariate_string} \
          --catCovarList ~{categorical_covariate_string} \
          --phenoFile ~{phenotypes} \
          --bsize ~{bsize} \
          --gz \
          --pgen ~{plink2_prefix} \
          --threads ~{threads} \
          --run-l1 fit_bin_parallel.master \
          --out fit_bin_l1
            
        # remove /home/dnanexus/work from path
        sed -i 's|/home/dnanexus/work/||g' fit_bin_l1_pred.list

        mv ~/work/*loco.gz . 

        ls -alh

        echo "$(date -u) done now"
    >>>

    runtime {
        docker: "ghcr.io/rgcgithub/regenie/regenie:v4.0.gz"
        dx_instance_type: "mem2_ssd1_v2_x8"
    }

    output {
        Array[File] locos = glob("*loco.gz")
        File loco_list    = "fit_bin_l1_pred.list"
        File log          = "fit_bin_l1.log"
    }

}

task step2 {

    input {
        File psam
        File pvar
        File pgen
        String plink2_prefix
        String covariate_string
        String categorical_covariate_string
        File covariates
        File phenotypes
        Array[File] locos
        File loco_list
        String out_prefix
        Int bsize
        Int minMAC
        Int threads
    }

    command <<<

        echo "$(date -u) Starting now"

        ln -s ~{psam} ~{plink2_prefix}.psam
        ln -s ~{pvar} ~{plink2_prefix}.pvar
        ln -s ~{pgen} ~{plink2_prefix}.pgen

        echo "$(date -u) Fixing psam header now"
        head  ~{plink2_prefix}.psam

        awk 'NR==1 {print "#FID IID sex"; next} {print $1, $1, $2}' ~{plink2_prefix}.psam > tmp.psam

        mv ~{plink2_prefix}.psam ~{plink2_prefix}.psam.old
        mv tmp.psam ~{plink2_prefix}.psam

        head  ~{plink2_prefix}.psam
        echo "$(date -u) Done fixing psam header now"

        for loco in ~{sep=' ' locos}; do 
            echo $loco
            ln -s ${loco} .
        done

        regenie \
          --step 2 \
          --pgen ~{plink2_prefix} \
          --covarFile ~{covariates} \
          --covarColList ~{covariate_string} \
          --catCovarList ~{categorical_covariate_string} \
          --phenoFile ~{phenotypes} \
          --bsize ~{bsize} \
          --bt \
          --firth --approx \
          --pThresh 0.05 \
          --threads ~{threads} \
          --pred ~{loco_list} \
          --af-cc \
          --gz \
          --threads ~{threads} \
          --minMAC ~{minMAC} \
          --out ~{out_prefix}

        ls -alh out/
        ls -alh

        echo "$(date -u) Done now"
    >>>

    runtime {
        docker: "ghcr.io/rgcgithub/regenie/regenie:v4.0.gz"
        dx_instance_type: "mem2_ssd1_v2_x8"
    }

    output {
        Array[File] rg_output = glob("*.regenie.gz")
        File log = "~{out_prefix}.log"
    }

}

task concatenate {
    
    input {
        Array[File] summary_stats
    }

    command <<<

        for l in ~{sep=' ' summary_stats}; do 
            ln -s ${l} . 
        done

        duckdb -c "COPY
         (SELECT
             concat('chr', CHROM) AS CHROM,
             GENPOS AS POS,
             concat_ws('-', concat('chr', CHROM), GENPOS, ALLELE0, ALLELE1) AS ID,
             ALLELE0,
             ALLELE1,
             A1FREQ,
             A1FREQ_CASES,
             A1FREQ_CONTROLS,
             N,
             N_CASES,
             N_CONTROLS,
             BETA,
             SE,
             CHISQ,
             LOG10P,
             replace(split_part(filename, '_', 3), '.regenie.gz', '') AS phenotype
         FROM read_csv('*.gz', sep = ' ', filename = true))
         TO 'concatenated_results.parquet' (FORMAT PARQUET) "
    >>>

    runtime {
        docker: "jweinstk/duckdb:master"
        dx_instance_type: "mem2_ssd1_v2_x2"
    }

    output {
        File parquet = "concatenated_results.parquet"
    }

}
