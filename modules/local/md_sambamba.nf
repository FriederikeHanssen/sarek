// Import generic module functions
include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
def options    = initOptions(params.options)

process MD_SAMBAMBA{
    label 'process_high'
    publishDir "${params.outdir}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:'mark_duplicates', publish_id:'') }
    
    conda (params.enable_conda ? "bioconda::sambamba=0.7.1--h984e79f_3" : null)
    if (workflow.containerEngine == 'singularity' && !params.pull_docker_container) {
        container "https://depot.galaxyproject.org/singularity/sambamba:0.7.1--h984e79f_3"
    } else {
        container "quay.io/biocontainers/sambamba:0.7.1--h984e79f_3"
    }

    input:
        tuple val(name), path(bam)

    output:
        tuple val(name), path('*sambamba.md.bam')

    script:
    def software = getSoftwareName(task.process)
   
    """
    sambamba markdup --nthreads ${task.cpus} --tmpdir . ${bam} ${bam.simpleName}.sambamba.md.bam
    """
    //hashtablesize: > (average coverage) * (insert size) How to compute this
    //remove duplicates??? 
}