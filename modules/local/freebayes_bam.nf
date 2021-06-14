include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
def options    = initOptions(params.options)

process FREEBAYES_BAM {
     label 'process_medium'

    publishDir params.outdir, mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:getSoftwareName(task.process), publish_id:'') }

    conda (params.enable_conda ? "bioconda::freebayes==1.3.5" : null)
    if (workflow.containerEngine == 'singularity' && !params.pull_docker_container) {
        container "https://depot.galaxyproject.org/singularity/freebayes:1.3.5--py39hd2e4403_0"
    } else {
        container "quay.io/biocontainers/freebayes:1.3.5--py39hd2e4403_0"
    }

    input:
        tuple val(name), path(bam), path(bai), path(intervalBed)
        path(fasta)
        path(fastaFai)

    output:
        tuple val(name), path("*.vcf")

    script:
    intervalsOptions = params.no_intervals ? "" : "-t ${intervalBed}"
    """
    freebayes \
        -f ${fasta} \
        --min-alternate-fraction 0.1 \
        --min-mapping-quality 1 \
        ${intervalsOptions} \
        ${bam} > ${intervalBed.baseName}_${name}.vcf
    """
}