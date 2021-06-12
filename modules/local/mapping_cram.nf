// Import generic module functions
include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
def options    = initOptions(params.options)

process MAP_CRAM{
    label 'process_high'
    publishDir "${params.outdir}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:'mapping_cram', publish_id:'') }

    conda (params.enable_conda ? "bioconda::bwa-mem2=2.2.1 bioconda::samtools=1.12" : null)
    if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
        container "https://depot.galaxyproject.org/singularity/mulled-v2-e5d375990341c5aef3c9aff74f96f66f65375ef6:cf603b12db30ec91daa04ba45a8ee0f35bbcd1e2-0"
    } else {
        container "quay.io/biocontainers/mulled-v2-e5d375990341c5aef3c9aff74f96f66f65375ef6:cf603b12db30ec91daa04ba45a8ee0f35bbcd1e2-0"
    }
    //TODO: double check the mulled container now is correct
    input:
        tuple val(name), path(reads)
        path(fasta)
        path (reference)

    output:
        tuple val(name), path ("*.cram")


    script:
    def software = getSoftwareName(task.process)
    //extra = meta.status == 1 ? "-B 3" : "" when tumor than allow for a smaller mismatch penalty...why? will leave by default for now
    def name = reads.get(0).simpleName   //TODO: Set name better
    def part = params.parts > 1 ? reads.get(0).name.findAll(/part_([0-9]+)?/).last().concat('.') : ""
    //TODO hard coded, needs fix eventually
    def CN = ""
    def readGroup = "@RG\\tID:1\\t${CN}PU:1\\tSM:${name}\\tLB:${name}\\tPL:ILLUMINA"

    """
    bwa-mem2 mem ${options.args} -R \"${readGroup}\" -t ${task.cpus} ${fasta} ${reads} | samtools sort -@ ${task.cpus} -m 6G - | samtools view -T ${fasta} -C -o ${name}.${part}cram -
    echo \$(bwa-mem2 version 2>&1) > bwa-mem2.version.txt
    """
    //samtools may need different memory setting -m 2G why not use task.memory: .GB ending throws error, only K/M/G are recognized. harcoding taks.memory = 84G also did not work
    // '  samtools sort: couldn't allocate memory for bam_mem', knocking of 20GB appears to (not) work. Setting it to 64G was a completely arbitrary
    // TODO: Do I need -T here? Where are tmo files written to?
}