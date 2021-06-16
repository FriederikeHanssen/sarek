include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
def options    = initOptions(params.options)

//TODO: still in beta bt doesn't state that it shouldn't be used
process APPLYBQSR_SPARK_BAM {
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
        tuple val(name), path(bam), path(bai), path(intervalBed), path(recalibrationReport)
        path(reference)
        path(fai)
        path(dict)

    output:
        tuple val(name), path('*.recal.bam')

    script:
    def output = options.suffix ? "${name}.${options.suffix}" : "${name}"
    intervalsOptions = params.no_intervals ? "" : "-L ${intervalBed}"
    prefix = params.no_intervals ? "" : "${intervalBed.baseName}_"

    """
    export SPARK_LOCAL_IP=127.0.0.1
    export SPARK_PUBLIC_DNS=127.0.0.1

    gatk ApplyBQSRSpark \
       -R ${reference} \
       -I ${bam} \
       --bqsr-recal-file ${recalibrationReport} \
       -O ${prefix}.recal.bam \
       ${intervalsOptions} \
        --tmp-dir .

    """
}
