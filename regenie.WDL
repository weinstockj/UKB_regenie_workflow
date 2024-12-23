version 1.0
workflow regenie {

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

    }

    Array[Int] idx = [
        1,2,3,4,5,6,7,8,9,10,11,12,13,
        14,15,16,17,18,19,20,21,22,23
    ]

    call step1 {

        input:
            pvar = step1_pvar,
            psam = step1_psam,
            pgen = step1_pgen,
            plink2_prefix = step1_prefix,
            covariates = covariates,
            covariate_string = covariate_string,
            categorical_covariate_string = categorical_covariate_string,
            phenotypes = phenotypes
    }

    
    scatter(i in idx) {

        call step2 {

            input:
                psam = psam[i],
                pvar = pvar[i],
                pgen = pgen[i],
                plink2_prefix = step2_prefix[i],
                locos = step1.locos,
                loco_list = step1.loco_list,
                covariates = covariates,
                covariate_string = covariate_string,
                categorical_covariate_string = categorical_covariate_string,
                phenotypes = phenotypes
        }
    }


    output {

        File loco_list            = step1.loco_list
        Array[File] locos         = step1.locos
        Array[Array[File]] summary_stats = step2.rg_output

    }

}

task step1 {

    input {

        File psam
        File pvar
        File pgen
        String plink2_prefix
        File covariates
        String covariate_string
        String categorical_covariate_string
        File phenotypes
        Int bsize = 200
        Int threads = 16
    }

    command <<<

        echo "$(date -u) start now"

        ln -s ~{psam} ~{plink2_prefix}.psam
        ln -s ~{pvar} ~{plink2_prefix}.pvar
        ln -s ~{pgen} ~{plink2_prefix}.pgen

        regenie --step 1 \
          --pgen ~{plink2_prefix} \
          --covarFile ~{covariates} \
          --covarColList ~{covariate_string} \
          --catCovarList ~{categorical_covariate_string} \
          --phenoFile ~{phenotypes} \
          --bsize ~{bsize} \
          --bt --lowmem \
          --threads ~{threads} \
          --lowmem-prefix tmp_rg \
          --out out

        ls -alh out
        echo "$(date -u) done now"
    >>>

    runtime {
        docker: "ghcr.io/rgcgithub/regenie/regenie:v4.0.gz"
        dx_instance_type: "mem2_ssd1_v2_x16"
    }

    output {
        File loco_list = "out_pred.list"
        Array[File] locos = glob("*.loco")
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
        Int bsize = 200
        Int minMAC = 5
        Int threads = 8
    }

    command <<<

        echo "$(date -u) Starting now"

        ln -s ~{psam} ~{plink2_prefix}.psam
        ln -s ~{pvar} ~{plink2_prefix}.pvar
        ln -s ~{pgen} ~{plink2_prefix}.pgen

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
          --pThresh 0.01 \
          --threads ~{threads} \
          --pred ~{loco_list} \
          --af-cc \
          --gz \
          --threads ~{threads} \
          --minMAC ~{minMAC} \
          --out out

        ls -alh
        echo "$(date -u) Done now"
    >>>

    runtime {
        docker: "ghcr.io/rgcgithub/regenie/regenie:v4.0.gz"
        dx_instance_type: "mem2_ssd1_v2_x8"
    }

    output {
        Array[File] rg_output = glob("*.regenie.gz")
    }

}

