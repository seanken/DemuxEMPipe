import sys
import pegasusio as io

if __name__=="__main__":
    args=sys.argv
    inFil=args[1]
    outFil=args[2]


    data=io.read_input(inFil,genome="GRCh38", modality="rna")
    data.subset_data(modality_subset=['rna'])
    data.subset_data(genome_subset=['GRCh38'])

    io.write_output(data,"cleanData.h5","h5")
