// Import generic module functions
include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
options        = initOptions(params.options)

process QUALIMAP_BAMQC {
    tag "$name"
    label 'process_medium'
    publishDir "${params.outdir}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:'mapping_cram', publish_id:'') }

    conda (params.enable_conda ? "bioconda::qualimap=2.2.2d" : null)
    if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
        container "https://depot.galaxyproject.org/singularity/qualimap:2.2.2d--1"
    } else {
        container "quay.io/biocontainers/qualimap:2.2.2d--1"
    }

    input:
    tuple val(name), path(bam), path(bai)


    output:
    tuple val(name), path("${prefix}"), emit: results
    path  "*.version.txt"             , emit: version

    script:
    def software   = getSoftwareName(task.process)
    prefix         = options.suffix ? "${name}${options.suffix}" : "${name}"

    def collect_pairs = '--collect-overlap-pairs'
    def memory     = task.memory.toGiga() + "G"

    """
    unset DISPLAY
    mkdir tmp
    export _JAVA_OPTIONS=-Djava.io.tmpdir=./tmp
    qualimap \\
        --java-mem-size=$memory \\
        bamqc \\
        $options.args \\
        -bam $bam \\
        $collect_pairs \\
        -outdir $prefix \\
        -nt $task.cpus

    echo \$(qualimap 2>&1) | sed 's/^.*QualiMap v.//; s/Built.*\$//' > ${software}.version.txt
    """
}
