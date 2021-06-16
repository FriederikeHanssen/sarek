include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
def options    = initOptions(params.options)

//TODO: not recommended for production work
process HAPLOTYPECALLER_SPARK_BAM {
    label 'process_high'
    scratch '/sfs/7/workspace/ws/iizha01-test_splitting-0/sarek/tmp'
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
        path(fai)
        path(dict)
         path(dbsnp)
        path(dbsnpIndex)


    output:
        tuple val(name), path('*.g.vcf.gz'), emit: cram

    script:
    def output = options.suffix ? "${name}.${options.suffix}" : "${name}"
    intervalsOptions = params.no_intervals ? "" : "-L ${intervalBed}"
    prefix = params.no_intervals ? "" : "${intervalBed.baseName}_"

    """
    export SPARK_LOCAL_IP=127.0.0.1
    export SPARK_PUBLIC_DNS=127.0.0.1
    gatk HaplotypeCallerSpark \
       -R ${reference} \
       -I ${bam} \
       -O ${prefix}.g.vcf.gz \
       ${intervalsOptions} \
        -ERC GVCF \
                --tmp-dir . \

    """
}
