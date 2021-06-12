params.seqkit_options                   = [:]
params.dict_options                     = [:]
params.fai_options                      = [:]
params.bwamem2_options                  = [:]
params.bwamem2_index_options            = [:]
params.md_options                  = [:]
params.estimate_lib_complexity_options  = [:]

include { DICT }                        from '../local/gatk_createsequencedictionary'   addParams( options: params.dict_options  )
include { SAMTOOLS_FAIDX }              from '../local/create_fai.nf'                   addParams( options: params.fai_options  )
include { MERGE_BAM}                    from '../local/merge_samtools_bam.nf'
include { SAMTOOLS_MERGE_CRAM}                    from '../local/merge_samtools_cram.nf'

include { SPLIT_FASTQ }                 from '../local/splitfastq.nf'                   addParams( options: params.seqkit_options  )
include { MAP_BAM }                     from '../local/mapping_bam.nf'                  addParams( options: params.bwamem2_options  )
include { MAP_CRAM }                     from '../local/mapping_cram.nf'                  addParams( options: params.bwamem2_options  )
include { BWAMEM2_INDEX }               from '../local/index.nf'                        addParams ( options: params.bwamem2_index_options )

include { MAP_BAM_SPARK }                     from '../local/mapping_bam_spark.nf'                  addParams( options: params.bwamem2_options  )
include { MAP_CRAM_SPARK }                     from '../local/mapping_cram_spark.nf'                  addParams( options: params.bwamem2_options  )

include { MD_GATK_BAM }                     from '../local/md_gatk_bam.nf'                      addParams( options: params.md_options  )
include { MD_GATK_SPARK_BAM }                     from '../local/md_gatk_bam_spark.nf'                      addParams( options: params.md_options  )
include { MD_GATK_SPARK_CRAM }                     from '../local/md_gatk_cram_spark.nf'                      addParams( options: params.md_options  )

include { MD_ADAM_BAM }                     from '../local/md_adam_bam.nf'                      addParams( options: params.md_options  )
include { MD_ADAM_CRAM }                     from '../local/md_adam_cram.nf'                      addParams( options: params.md_options  )

include { MD_SAMBAMBA }                     from '../local/md_sambamba.nf'                      addParams( options: params.md_options  )

include { MD_SAMBLASTER }                     from '../local/md_samblaster.nf'                      addParams( options: params.md_options  )

include { ESTIMATE_LIBRARY_COMPLEXITY_CRAM } from '../local/estimatelibrarycomplexity_cram'       addParams( options: params.estimate_lib_complexity_options  )
include { ESTIMATE_LIBRARY_COMPLEXITY_BAM } from '../local/estimatelibrarycomplexity_bam'       addParams( options: params.estimate_lib_complexity_options  )


workflow MAP_BENCHMARK {

    take:
        reads   // channel: [ val(name), reads ]
        fasta

    main:

        if(params.parts > 1){
            //STEP 1: Split input
            SPLIT_FASTQ(reads)
            split_reads = SPLIT_FASTQ.out.map{
                key, reads ->
                    //TODO maybe this can be replaced by a regex to include part_001 etc.

                    //sorts list of split fq files by :
                    //[R1.part_001, R2.part_001, R1.part_002, R2.part_002,R1.part_003, R2.part_003,...]
                    //TODO: determine whether it is possible to have an uneven number of parts, so remainder: true woud need to be used, I guess this could be possible for unfiltered reads, reads that don't have pairs etc.
                    return [key, reads.sort{ a,b -> a.getName().tokenize('.')[ a.getName().tokenize('.').size() - 3] <=> b.getName().tokenize('.')[ b.getName().tokenize('.').size() - 3]}
                                            .collate(2)]
            }.transpose()
        }else {
            split_reads = reads.map{
                key, read1, read2 -> return [key, [read1,read2]]
            }
        }
        split_reads.dump()
        // Step 2: Mapping
        if(!params.index){
            index = BWAMEM2_INDEX(fasta)
        }else {
            index = file(params.index)
        }

        split_reads.dump()

        MAP_CRAM(split_reads, fasta, index)
        MAP_CRAM_SPARK(split_reads, fasta, index)
        MAP_BAM(split_reads, fasta, index)
        MAP_BAM_SPARK(split_reads, fasta, index)

        dict = params.dict ? file(params.dict) : DICT(fasta)
        faidx = params.faidx ? file(params.faidx) : SAMTOOLS_FAIDX(fasta)

        mapped_spark_bam = MAP_BAM_SPARK.out.groupTuple()
        mapped_spark_cram = MAP_CRAM_SPARK.out.groupTuple()
        mapped_bam = MAP_BAM.out.groupTuple()
        mapped_cram = MAP_CRAM.out.groupTuple()

        //Name sorted reads (for MD Spark)
        MD_GATK_SPARK_CRAM(mapped_spark_cram, fasta, dict, faidx)
        MD_GATK_SPARK_BAM(mapped_spark_bam, dict, faidx)
        ESTIMATE_LIBRARY_COMPLEXITY_BAM(mapped_spark_bam, dict, faidx)
        ESTIMATE_LIBRARY_COMPLEXITY_CRAM(mapped_spark_cram, fasta, dict, faidx)

        //Coordinate sorted reads
        MD_GATK_BAM(mapped_bam,dict, faidx)

        if(params.parts > 1){
            cram_merged = SAMTOOLS_MERGE_CRAM(mapped_cram, fasta)
            bam_merged = MERGE_BAM(mapped_bam)
        }else{
            cram_merged = mapped_cram
            bam_merged = mapped_bam
        }
        MD_ADAM_BAM(bam_merged)
        MD_ADAM_CRAM(mapped_spark_cram, fasta)




    emit:
        MAP_BAM_SPARK.out

}