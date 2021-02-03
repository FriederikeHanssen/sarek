include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
def options    = initOptions(params.options)

process CONVERT_TO_CRAM {
    label 'process_high'

    publishDir params.outdir, mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:getSoftwareName(task.process), publish_id:'') }

    conda (params.enable_conda ? "bioconda::samtools=1.11--h6270b1f_0" : null)
    if (workflow.containerEngine == 'singularity' && !params.pull_docker_container) {
        container "https://depot.galaxyproject.org/singularity/samtools:1.11--h6270b1f_0"
    } else {
        container "quay.io/biocontainers/samtools:1.11--h6270b1f_0"
    }

    input:
        tuple val(name), path(bam)
        path(fasta)

    output:
        tuple val(name), path("*.cram")

    script:
    def name_2 = options.suffix ? "${name}.${options.suffix}" : "${name}"
    """
    samtools view -T ${fasta} -C -o ${name_2}.cram ${bam}
    """

}
