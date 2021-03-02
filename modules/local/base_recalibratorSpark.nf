include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
def options    = initOptions(params.options)

process BASERECALIBRATIONSPARK {
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
        tuple val(name), path(cram), path(recalibrationReport), path(intervalBed
        path(reference)
        path(dict)
        path(fai)
        path(dbsnp)
        path(dbsnpIndex)

    output:
        tuple val(name), path('*.table'), emit: table

    script:
    def output = options.suffix ? "${name}.${options.suffix}" : "${name}"

    """
    export SPARK_LOCAL_IP=127.0.0.1
    export SPARK_PUBLIC_DNS=127.0.0.1
    
    gatk  BaseRecalibratorSpark \
        -I ${cram} \
        -O ${prefix}${idSample}.recal.table \
        --tmp-dir . \
        -R ${fasta} \
        ${intervalsOptions} \
        ${dbsnpOptions} \
        ${knownOptions} \
        --verbosity INFO
    """
}
