import pandas as pd
import sys

def main(target_matrix, sample_barcode_table, outputname):
    sample_barcode_df = pd.read_csv(sample_barcode_table, header=None)
    sample_barcode_df.columns = ["barcode", "sampleID"]
    sample_barcode_dict = sample_barcode_df.set_index(['barcode'])["sampleID"].to_dict()
    matrix_df = pd.read_csv(target_matrix, header=[0], sep="\t")
    matrix_df.rename(columns=sample_barcode_dict, inplace=True)
    matrix_df.to_csv("%s.tsv"%outputname, header=True, index=False, sep="\t")

main(target_matrix=sys.argv[1], sample_barcode_table=sys.argv[2], outputname=sys.argv[3])
