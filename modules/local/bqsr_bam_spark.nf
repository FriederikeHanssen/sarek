include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
def options    = initOptions(params.options)

process BASERECALIBRATION_BAM_SPARK {
    label 'process_medium'

    publishDir params.outdir, mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:getSoftwareName(task.process), publish_id:'') }

    conda (params.enable_conda ? "bioconda::gatk4==4.2.0.0" : null)
    if (workflow.containerEngine == 'singularity' && !params.pull_docker_container) {
        container "https://depot.galaxyproject.org/singularity/gatk4:4.2.0.0--0"
    } else {
        container "quay.io/biocontainers/gatk4:4.2.0.0--0"
    }

    input:
        tuple val(name), path(bam), path(bai), path(intervalBed)
        path(reference)
        path(dict)
        path(fastaFai)
        path(dbsnp)
        path(dbsnpIndex)
        path(knownIndels)
        path(knownIndelsIndex)

    output:
        tuple val(name), path('*.table'), emit: table

    script:
    def output = options.suffix ? "${name}.${options.suffix}" : "${name}"
    knownOptions = params.known_indels ? knownIndels.collect{"--known-sites ${it}"}.join(' ') : ""
    prefix = params.no_intervals ? "" : "${intervalBed.baseName}_"
    intervalsOptions = params.no_intervals ? "" : "-L ${intervalBed}"
    """
    export SPARK_LOCAL_IP=127.0.0.1
    export SPARK_PUBLIC_DNS=127.0.0.1

    gatk  BaseRecalibratorSpark \
        -I ${bam} \
        -O ${prefix}${output}.recal.table \
        --tmp-dir . \
        -R ${reference} \
        ${intervalsOptions} \
        --known-sites ${dbsnp} \
        ${knownOptions} \
        --verbosity INFO
    """
}
