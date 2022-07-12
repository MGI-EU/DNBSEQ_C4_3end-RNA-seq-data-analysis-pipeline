import pandas as pd
import scipy.io 
import anndata 
from scipy.sparse import csr_matrix 
import sys

def ReadPISA(path):
    mat = scipy.io.mmread(path+"/"+"matrix.mtx.gz").astype("float32")
    mat = mat.transpose()
    mat = csr_matrix(mat)
    adata = anndata.AnnData(mat,dtype="float32")
    genes = pd.read_csv(path+"/"+"features.tsv.gz", header=None, sep="\t")
    var_names = genes[0].values
    var_names = anndata.utils.make_index_unique(pd.Index(var_names))
    adata.var_names = var_names
    adata.var["gene_symbols"] = genes[0].values
    adata.obs_names = pd.read_csv(path+"/"+"barcodes.tsv.gz", header=None)[0].values
    adata.var_names_make_unique()
    return adata


def main(path, output_name):
    adata = ReadPISA(path)
    matrix_df = adata.to_df()
    matrix_df = matrix_df.T.astype(int)
    matrix_df.sort_values(by=list(matrix_df)[0],ascending=False,inplace=True)
    matrix_df.reset_index(inplace=True)
    matrix_df.rename(columns={"index":"Gene"}, inplace=True)
    matrix_df.to_csv("%s.tsv"%output_name, sep="\t", header=True, index=False)

main(path=sys.argv[1], output_name=sys.argv[2])
