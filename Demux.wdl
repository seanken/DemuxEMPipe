version 1.0

workflow Demux {
    input {
        String inDir
        File inRNA = inDir + "/raw_feature_bc_matrix.h5"
        Boolean runCleanInput = false
    }

    call GetCrisprCSV {
        input:
            inRNA = inRNA
    }

    if (runCleanInput) {
        call CleanInput {
            input:
                inRNA = inRNA
        }
    }

    call RunDemuxEM {
        input:
            inRNA = select_first([CleanInput.cleaned_h5, inRNA]),
            crispCSV = GetCrisprCSV.crispCSV
    }

    call CleanDeMuxOutput {
        input:
            demuxZarr = RunDemuxEM.demuxZarr
    }

    output {
        File results = CleanDeMuxOutput.results
    }
}

task GetCrisprCSV {
    input {
        File inRNA
    }

    command <<<
        gsutil cp gs://fc-secure-b42fb9b0-04ed-4260-9c28-aa1274233114/Scripts/GetCSV.py .
        python GetCSV.py ~{inRNA} Crisp.csv
    >>>

    output {
        File crispCSV = "Crisp.csv"
    }

    runtime {
        docker: "cumulusprod/cumulus:1.0.0"
        zones: "us-central1-b"
        memory: "90G"
        disks: "local-disk 100 HDD"
    }
}

task CleanInput {
    input {
        File inRNA
    }

    command <<<
        gsutil cp gs://fc-secure-b42fb9b0-04ed-4260-9c28-aa1274233114/Scripts/CovertH5.py .
        pip install --upgrade pegasusio
        python CovertH5.py ~{inRNA} cleaned.h5
    >>>

    output {
        File cleaned_h5 = "cleaned.h5"
    }

    runtime {
        docker: "cumulusprod/cumulus:1.4.3"
        zones: "us-central1-b"
        memory: "90G"
        disks: "local-disk 100 HDD"
    }
}

task RunDemuxEM {
    input {
        File inRNA
        File crispCSV
    }

    command <<<
        pip install --upgrade demuxEM
        demuxEM ~{inRNA} ~{crispCSV} output
    >>>

    output {
        File demuxZarr = "output_demux.zarr.zip"
    }

    runtime {
        docker: "cumulusprod/cumulus:1.0.0"
        zones: "us-central1-b"
        memory: "90G"
        disks: "local-disk 100 HDD"
    }
}

task CleanDeMuxOutput {
    input {
        File demuxZarr
    }

    command <<<
        gsutil cp gs://fc-secure-b42fb9b0-04ed-4260-9c28-aa1274233114/Scripts/CleanOutput.py .
        python CleanOutput.py ~{demuxZarr} Results.txt
    >>>

    output {
        File results = "Results.txt"
    }

    runtime {
        docker: "cumulusprod/cumulus:1.0.0"
        zones: "us-central1-b"
        memory: "90G"
        disks: "local-disk 100 HDD"
    }
}
