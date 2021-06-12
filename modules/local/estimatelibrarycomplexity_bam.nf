include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
def options    = initOptions(params.options)

process ESTIMATE_LIBRARY_COMPLEXITY_BAM {
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
        tuple val(name), path(bam)
        path(dict) //need to be present in the path
        path(fai)  //need to be present in the path

    output:
        path('*.md.metrics'), emit: report

    script:
    def software = getSoftwareName(task.process)
    def bams = bam.collect(){ x -> "-I ".concat(x.toString()) }.join(" ")
    def output = options.suffix ? "${name}.${options.suffix}" : "${name}"
    """
    gatk EstimateLibraryComplexity \
        ${bams} \
        -O ${output}.md.metrics \
        --VALIDATION_STRINGENCY SILENT \
        --TMP_DIR .
    """
}