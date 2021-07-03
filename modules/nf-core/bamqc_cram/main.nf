// Import generic module functions
include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
options        = initOptions(params.options)

process QUALIMAP_BAMQC_CRAM{ // Import generic module functions {
    tag "$name"
    label 'process_medium'
    publishDir "${params.outdir}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:'mapping_cram', publish_id:'') }

    conda (params.enable_conda ? "bioconda::qualimap=2.2.2d bioconda::samtools=1.12" : null)
    if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
        container "https://depot.galaxyproject.org/singularity/mulled-v2-d3934ca6bb4e61334891ffa2e9a4c87a530e3188:4bf11d12f2c3eccf1eb585097c0b6fd31c18c418-0"
    } else {
        container "quay.io/biocontainers/mulled-v2-d3934ca6bb4e61334891ffa2e9a4c87a530e3188:4bf11d12f2c3eccf1eb585097c0b6fd31c18c418-0"
    }

    input:
    tuple val(name), path(cram), path(crai)
    path reference
    path fai

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

    samtools view -hb -T ${reference} ${cram} |
    qualimap \\
        --java-mem-size=$memory \\
        bamqc \\
        $options.args \\
        -bam /dev/stdin \\
        $collect_pairs \\
        -outdir $prefix \\
        -nt $task.cpus

    echo \$(qualimap 2>&1) | sed 's/^.*QualiMap v.//; s/Built.*\$//' > ${software}.version.txt
    """
}
