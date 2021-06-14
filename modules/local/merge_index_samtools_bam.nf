include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
def options    = initOptions(params.options)

process SAMTOOLS_MERGE_INDEX_BAM {
    label 'process_high'

    publishDir params.outdir, mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:getSoftwareName(task.process), publish_id:'') }

conda (params.enable_conda ? "bioconda::samtools=1.12" : null)
    if (workflow.containerEngine == 'singularity' && !params.pull_docker_container) {
        container "https://depot.galaxyproject.org/singularity/samtools:1.12--hd5e65b6_0 "
    } else {
        container "quay.io/biocontainers/samtools:1.12--hd5e65b6_0 "
    }

    input:
        tuple val(name), path(bams)

    output:
        tuple val(name), path("*.bam"), path("*.bai")

    script:
    def name_2 = options.suffix ? "${name}.${options.suffix}" : "${name}"
    """
    samtools merge --threads ${task.cpus} ${name_2}.bam ${bams}
    samtools index -@ ${task.cpus} ${name_2}.bam
    """
    //    samtools merge --threads ${task.cpus} - ${bam} | samtools view -T ${fasta} -C -o ${name_2}.cram -
        //--> add back in after cram array test
    //TODO this could also be done with sambamba, which is apaprently much faster, all this tool replacement would require quiet a bit of benchmarking etc.
    // | samtools view -T ${fasta} -C -o ${name}.${part}.cram -
}
