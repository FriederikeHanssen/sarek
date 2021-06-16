include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
def options    = initOptions(params.options)

process HAPLOTYPECALLER_CRAM {
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
        tuple val(name), path(cram), path(crai), path(intervalBed)
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
    dbsnpOptions = params.dbsnp ? "--D ${dbsnp}" : ""
    """
    gatk HaplotypeCaller \
       -R ${reference} \
       -I ${cram} \
       -O ${prefix}.g.vcf.gz \
       ${intervalsOptions} \
        ${dbsnpOptions} \
        -ERC GVCF \
        --tmp-dir .
    """
}
