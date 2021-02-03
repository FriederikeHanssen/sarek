// Import generic module functions
include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
def options    = initOptions(params.options)

process MD_ADAM{
    label 'process_high'
    scratch='/sfs/7/workspace/ws/iizha01-test_splitting-0/babysarek/tmp'

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
        tuple val(name), path(cram)
        path(reference)
        path(dict) //need to be present in the path
        path(fai)  //need to be present in the path

    output:
        tuple val(name), path('*adam.md.cram')


    script:
    def software = getSoftwareName(task.process)
   
    """
    export SPARK_LOCAL_IP=127.0.0.1
    export SPARK_PUBLIC_DNS=127.0.0.1
    adam-submit \
       --master local[*] \
       --conf spark.local.dir=. \
       --driver-memory ${task.memory.toGiga()}g \
       -- \
       transformAlignments \
       -mark_duplicate_reads \
       -single \
       -stringency LENIENT \
       -reference ${reference} \
       -sort_by_reference_position \
       ${cram} \
       ${cram.simpleName}.adam.md.cram
    """
    //--master <mysparkmaster> 
    //\ --deploy-mode cluster \ --d river-memory 20g \ --executor-memory 20g \ --conf spark.driver.cores=16 \ --conf spark.executor.cores=16 \ --conf spark.yarn.executor.memoryOverhead=2048 \ --conf spark.executor.instances=3 \
    //  touch ${idSample}.bam.metrics
    //  samtools index ${idSample}.md.bam

    //       --driver-memory ${task.memory.toGiga()}g \

}