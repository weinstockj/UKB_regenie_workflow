import sys
import yaml

input_file=sys.argv[1]

with open("config.yaml") as f:
    cfg = yaml.load(f, Loader=yaml.FullLoader)

cost_limit                   = cfg["cost_limit"]
project                      = cfg["project"]
priority                     = cfg["priority"]
step1_pvar                   = cfg["step1_pvar"]
step1_psam                   = cfg["step1_psam"]
step1_pgen                   = cfg["step1_pgen"]
step1_prefix                 = cfg["step1_prefix"]
covariates                   = cfg["covariates"]
phenotypes                   = cfg["phenotypes"]
covariate_string             = cfg["covariate_string"]
categorical_covariate_string = cfg["categorical_covariate_string"]
final_folder                 = cfg["final_folder"]
concatenate                  = cfg["concatenate"]

def _parse_dx_delim(delim_line):

    chrom = delim_line[0]
    pvar = delim_line[2]
    psam = delim_line[4]
    pgen = delim_line[6]
    return chrom, pvar, psam, pgen

if __name__ == '__main__':

    fd=open(input_file)
    lines=fd.readlines()
    chr_number=len(lines)
    batch_input_files=''
    for i in range(chr_number):
        delim_line = lines[i].strip().split('\t')
        chrom, pvar, psam, pgen = _parse_dx_delim(delim_line)
        batch_input_files += '-istage-common.pvar={pvar} -istage-common.psam={psam} -istage-common.pgen={pgen} -istage-common.step2_prefix={chrom} '.format(
                pvar = pvar, 
                psam = psam, 
                pgen = pgen, 
                chrom = chrom
            )


    print('uv run dx run /workflows/regenie {batch_input_files} \
     -istage-common.step1_pvar={step1_pvar} \
     -istage-common.step1_pgen={step1_pgen} \
     -istage-common.step1_psam={step1_psam} \
     -istage-common.step1_prefix={step1_prefix} \
     -istage-common.covariate_string="{covariate_string}" \
     -istage-common.covariates="{covariates}" \
     -istage-common.categorical_covariate_string="{categorical_covariate_string}" \
     -istage-common.phenotypes="{phenotypes}" \
     -istage-common.concatenate_into_parquet="{concatenate}" \
     --folder="{final_folder}" \
     --tag "regenie" \
     --priority {priority} \
     --cost-limit {cost} \
     -y \
     --brief'.format(
                 batch_input_files=batch_input_files,
                 step1_pvar=step1_pvar,
                 step1_pgen=step1_pgen,
                 step1_psam=step1_psam,
                 step1_prefix=step1_prefix,
                 covariate_string=covariate_string,
                 categorical_covariate_string=categorical_covariate_string,
                 covariates=covariates,
                 phenotypes=phenotypes,
                 concatenate=concatenate,
                 final_folder= final_folder,
                 priority = priority,
                 cost = cost_limit,
                 )
    )
