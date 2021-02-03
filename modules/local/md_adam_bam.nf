// Import generic module functions
include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
def options    = initOptions(params.options)

process MD_ADAM_BAM{
    label 'process_high'
    publishDir "${params.outdir}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:'mark_duplicates', publish_id:'') }
    
    conda (params.enable_conda ? "bioconda::adam=0.33.0--0" : null)
    if (workflow.containerEngine == 'singularity' && !params.pull_docker_container) {
        container "https://depot.galaxyproject.org/singularity/adam:0.33.0--0"
    } else {
        container "quay.io/biocontainers/adam:0.33.0--0"
    }

    input:
        tuple val(name), path(bam)

    output:
        tuple val(name), path('*adam.md.bam')


    script:
    def software = getSoftwareName(task.process)
   
    """
    export SPARK_LOCAL_IP=127.0.0.1
    export SPARK_PUBLIC_DNS=127.0.0.1
    adam-submit \
       --master local[${task.cpus}] \
       --driver-memory ${task.memory.toGiga()}g \
       --conf spark.local.dir=. \
       -- \
       transformAlignments \
       -mark_duplicate_reads \
       -single \
       -stringency LENIENT \
       ${bam}\
       ${bam.simpleName}.adam.md.bam
    """
    //--master <mysparkmaster> 
    //\ --deploy-mode cluster \ --d river-memory 20g \ --executor-memory 20g \ --conf spark.driver.cores=16 \ --conf spark.executor.cores=16 \ --conf spark.yarn.executor.memoryOverhead=2048 \ --conf spark.executor.instances=3 \
    //  touch ${idSample}.bam.metrics
    //  samtools index ${idSample}.md.bam

    //       --driver-memory ${task.memory.toGiga()}g \

   

}