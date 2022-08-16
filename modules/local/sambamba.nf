process SAMBAMBA_MARKDUP {
    tag "$meta.id"
    label 'process_low'

    conda (params.enable_conda ? "bioconda::sambamba=0.8.2" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/sambamba:0.8.2--h98b6b92_2':
        'quay.io/biocontainers/sambamba:0.8.2--h98b6b92_2' }"

    input:
    tuple val(meta), path(bam)

    output:
    tuple val(meta), path("*.bam")    , emit: bam
    tuple val(meta), path("*.bai")    , emit: bai
    tuple val(meta), path("*.metrics"), emit: metrics
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    sambamba \\
        markdup \\
        $args \\
        --nthreads $task.cpus \\
        --tmpdir . \\
        $bam \\
        ${prefix}.bam \\
        > ${prefix}.metrics 2>&1

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        sambamba: \$(echo \$(sambamba --version 2>&1) | sed 's/^.*sambamba //; s/Using.*\$//' ))
    END_VERSIONS
    """
}
