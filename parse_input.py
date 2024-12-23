import os 
import pandas as pd
import sys
args = sys.argv
pvar_file=args[1]
psam_file=args[2]
pgen_file=args[3]
output_file=args[4]

col_names = ["status", "date", "size", "path", "file", "extra"]
pvars = pd.read_table(pvar_file, names = col_names)
psams = pd.read_table(psam_file, names = col_names)
pgens = pd.read_table(pgen_file, names = col_names)

pvars["chr"] = [os.path.basename(pvars["path"][i]).split(".")[0] for i in range(len(pvars))]
psams["chr"] = [os.path.basename(psams["path"][i]).split(".")[0] for i in range(len(psams))]
pgens["chr"] = [os.path.basename(pgens["path"][i]).split(".")[0] for i in range(len(pgens))]

pvars = pvars[["chr", "path", "file"]].rename(
        columns={"file": "pvar_file", "path": "pvar_path"}
    )
psams = psams[["chr", "path", "file"]].rename(
        columns={"file": "psam_file", "path": "psam_path"}
    )
pgens = pgens[["chr", "path", "file"]].rename(
        columns={"file": "pgen_file", "path": "pgen_path"}
    )


dfm = pd.merge(pvars, psams, on="chr", how="inner"). \
        merge(pgens, on="chr", how="inner")

dfm.to_csv(output_file, sep="\t", index=False, header=False)
