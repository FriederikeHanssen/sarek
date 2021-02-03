// Import generic module functions
include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
def options    = initOptions(params.options)

process MD_SAMBLASTER{
    label 'process_high'
    publishDir "${params.outdir}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:'mark_duplicates', publish_id:'') }
    
    conda (params.enable_conda ? "bioconda::samblaster=0.1.26--hc9558a2_0" : null)
    if (workflow.containerEngine == 'singularity' && !params.pull_docker_container) {
        container "https://depot.galaxyproject.org/singularity/samblaster:0.1.26--hc9558a2_0"
    } else {
        container "quay.io/biocontainers/samblaster:0.1.26--hc9558a2_0"
    }

    input:
        tuple val(name), path(bam)

    output:
        tuple val(name), path('*samblaster.md.bam')

    script:
    def software = getSoftwareName(task.process)
   
    """
    samblaster --ignoreUnmated
    """
    //TODO: apparently this tools needs sam?
}