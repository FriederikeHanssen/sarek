include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
def options    = initOptions(params.options)

process MERGE_SAMBAMBA_BAM {
    label 'process_high'

    publishDir params.outdir, mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:getSoftwareName(task.process), publish_id:'') }

    conda (params.enable_conda ? "bioconda::sambamba=0.7.1--h984e79f_3" : null)
    if (workflow.containerEngine == 'singularity' && !params.pull_docker_container) {
        container "https://depot.galaxyproject.org/singularity/sambamba:0.7.1--h984e79f_3" //version does not match with conda, but conda version is more up to date
    } else {
        container "quay.io/biocontainers/sambamba:0.7.1--h984e79f_3"//version does not match with conda, but conda version is more up to date
    }

    input:
        tuple val(name), path(bam)

    output:
        tuple val(name), path("*.bam")

    script:
    def name_2 = options.suffix ? "${name}.${options.suffix}" : "${name}"
    """
    sambamba merge --nthreads ${task.cpus} ${name_2}.bam ${bam} 
    """
}
