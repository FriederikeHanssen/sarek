include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
def options    = initOptions(params.options)

process DICT {

     publishDir "${params.outdir}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:'reference/DICT/', publish_id:'') }
    
    conda (params.enable_conda ? "bioconda::gatk4-spark=4.1.9.0" : null)
    if (workflow.containerEngine == 'singularity' && !params.pull_docker_container) {
        container "https://depot.galaxyproject.org/singularity/gatk4-spark:4.1.9.0--0"
    } else {
        container "quay.io/biocontainers/gatk4-spark:4.1.9.0--0"
    }


    input:
        path fasta

    output:
        path "${fasta.baseName}.dict"

    script:
    def software = getSoftwareName(task.process)
    def ioptions = initOptions(options)
    """
    gatk --java-options "-Xmx${task.memory.toGiga()}g" \
        CreateSequenceDictionary \
        --REFERENCE ${fasta} \
        --OUTPUT ${fasta.baseName}.dict

    echo \$(gatk CreateSequenceDictionary --version 2>&1) | sed 's/^.*(GATK) v//; s/ HTSJDK.*\$//' > ${software}.version.txt
    """
}