
include { initOptions; saveFiles; getSoftwareName } from './functions'

process BWAMEM2_INDEX {
    tag "${fasta}"
    label 'process_high'
     publishDir "${params.outdir}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:'reference/BWAIndex/', publish_id:'') }
     
    conda (params.enable_conda ? "bioconda::bwa-mem2=2.1--he513fc3_0" : null)
    if (workflow.containerEngine == 'singularity' && !params.pull_docker_container) {
        container "https://depot.galaxyproject.org/singularity/bwa-mem2:2.1--he513fc3_0"
    } else {
        container "quay.io/biocontainers/bwa-mem2:2.1--he513fc3_0"
    }

    input:
        path fasta

    output:
        path "${fasta}.*"

    script:
    """
    bwa-mem2 index ${fasta}
    """
}