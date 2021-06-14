include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
def options    = initOptions(params.options)

process BQSRSPARKPIPELINE_SPARK_BAM {
    label 'process_high'

    publishDir params.outdir, mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:getSoftwareName(task.process), publish_id:'') }

    conda (params.enable_conda ? "bioconda::gatk4==4.2.0.0" : null)
    if (workflow.containerEngine == 'singularity' && !params.pull_docker_container) {
        container "https://depot.galaxyproject.org/singularity/gatk4:4.2.0.0--0"
    } else {
        container "quay.io/biocontainers/gatk4:4.2.0.0--0"
    }

    input:
        tuple val(name), path(bam), path(bai), path(intervals)
        path(reference)
        path(fai)
        path(dict)
        path(dbsnp)
        path(dbsnpIndex)
        path(knownIndels)
        path(knownIndelsIndex)

    output:
        tuple val(name), path('*.recal.bam')

    script:
    def output = options.suffix ? "${name}.${options.suffix}" : "${name}"
    knownOptions = params.known_indels ? knownIndels.collect{"--known-sites ${it}"}.join(' ') : ""
    intervalsOptions = params.no_intervals ? "" : intervals.collect{ x -> "-L ".concat(x.toString()) }.join(" ")
    """
    export SPARK_LOCAL_IP=127.0.0.1
    export SPARK_PUBLIC_DNS=127.0.0.1

    gatk  BQSRPipelineSpark \
        -I ${bam} \
        -O ${name}.recal.bam \
        --tmp-dir . \
        -R ${reference} \
        ${intervalsOptions} \
        --known-sites ${dbsnp} \
        ${knownOptions} \
        --verbosity INFO
    """
}
