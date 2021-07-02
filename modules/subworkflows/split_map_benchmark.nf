params.seqkit_options                   = [:]
params.dict_options                     = [:]
params.fai_options                      = [:]
params.bwamem2_options                  = [:]
params.bwamem2_index_options            = [:]
params.bqsr_options                     = [:]
params.md_options                  = [:]
params.estimate_lib_complexity_options  = [:]
params.tabix_dbsnp_options             = [:]
params.tabix_germline_resource_options = [:]
params.tabix_known_indels_options      = [:]

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
include { MD_GATK_SPARK_BAM_TO_CRAM }       from '../local/md_gatk_bamtocram_spark.nf'                      addParams( options: params.md_options  )
include { MD_ADAM_BAM }                     from '../local/md_adam_bam.nf'                      addParams( options: params.md_options  )
//include { MD_ADAM_CRAM }                     from '../local/md_adam_cram.nf'                      addParams( options: params.md_options  )

include { MD_SAMBAMBA }                     from '../local/md_sambamba.nf'                      addParams( options: params.md_options  )

include { ESTIMATE_LIBRARY_COMPLEXITY_CRAM } from '../local/estimatelibrarycomplexity_cram'       addParams( options: params.estimate_lib_complexity_options  )
include { ESTIMATE_LIBRARY_COMPLEXITY_BAM } from '../local/estimatelibrarycomplexity_bam'       addParams( options: params.estimate_lib_complexity_options  )

include { QUALIMAP_BAMQC } from '../../modules/nf-core/bamqc/main.nf'
include { QUALIMAP_BAMQC_CRAM } from '../../modules/nf-core/bamqc_cram/main.nf'

include {INDEX_CRAM }                   from '../local/samtools_index_cram'

include { BASERECALIBRATION_BAM }                     from '../local/bqsr_bam.nf'                  addParams( options: params.bqsr_options )
include { BASERECALIBRATION_CRAM }                     from '../local/bqsr_cram.nf'                  addParams( options: params.bqsr_options  )
include { BASERECALIBRATION_BAM_SPARK }                     from '../local/bqsr_bam_spark.nf'                  addParams( options: params.bqsr_options )
include { BASERECALIBRATION_CRAM_SPARK }                     from '../local/bqsr_cram_spark.nf'                  addParams( options: params.bqsr_options  )

include { CREATE_INTERVALS_BED }           from '../local/bedIntervals.nf'                //addParams ( options: params.intervals_options )

include { TABIX_TABIX as TABIX_DBSNP }                   from '../../modules/nf-core/software/tabix/tabix/main'                    addParams(options: params.tabix_dbsnp_options)
include { TABIX_TABIX as TABIX_GERMLINE_RESOURCE }       from '../../modules/nf-core/software/tabix/tabix/main'                    addParams(options: params.tabix_germline_resource_options)
include { TABIX_TABIX as TABIX_KNOWN_INDELS }            from '../../modules/nf-core/software/tabix/tabix/main'                    addParams(options: params.tabix_known_indels_options)

include { GATHER_BQSR_REPORTS as GATHER_BQSR_REPORTS_BAM }                          from '../../modules/local/gatherbqsrreport.nf'
include { GATHER_BQSR_REPORTS as GATHER_BQSR_REPORTS_CRAM }                          from '../../modules/local/gatherbqsrreport.nf'
include { GATHER_BQSR_REPORTS as GATHER_BQSR_REPORTS_BAM_SPARK }                          from '../../modules/local/gatherbqsrreport.nf'
include { GATHER_BQSR_REPORTS as GATHER_BQSR_REPORTS_CRAM_SPARK }                          from '../../modules/local/gatherbqsrreport.nf'

include { APPLYBQSR_BAM }           from '../local/applybqsr_bam.nf'
include { APPLYBQSR_SPARK_BAM }     from '../local/applybqsrSpark_bam.nf'
include { APPLYBQSR_CRAM }          from '../local/applybqsr_cram.nf'
include { APPLYBQSR_SPARK_CRAM }    from '../local/applybqsrSpark_cram.nf'

include { BQSRSPARKPIPELINE_SPARK_BAM } from '../../modules/local/bqsrsparkpipeline_bam.nf'
include { BQSRSPARKPIPELINE_SPARK_CRAM } from '../../modules/local/bqsrsparkpipeline_cram.nf'

include {SAMTOOLS_MERGE_INDEX_CRAM as SAMTOOLS_MERGE_INDEX_CRAM_SPARK } from '../../modules/local/merge_index_samtools_cram.nf'
include {SAMTOOLS_MERGE_INDEX_BAM as SAMTOOLS_MERGE_INDEX_BAM_SPARK}    from '../../modules/local/merge_index_samtools_bam.nf'
include {SAMTOOLS_MERGE_INDEX_CRAM}                                     from '../../modules/local/merge_index_samtools_cram.nf'
include {SAMTOOLS_MERGE_INDEX_BAM}                                      from '../../modules/local/merge_index_samtools_bam.nf'

include { HAPLOTYPECALLER_BAM }     from '../../modules/local/haplotypeCaller_Bam.nf'
include { HAPLOTYPECALLER_SPARK_BAM }   from '../../modules/local/HaplotypeCallerSpark_Bam.nf'
include { HAPLOTYPECALLER_CRAM }        from '../../modules/local/haplotypeCaller_Cram.nf'
include { HAPLOTYPECALLER_SPARK_CRAM }  from '../../modules/local/HaplotypeCallerSpark_Cram.nf'

include { STRELKA_GERMLINE_BAM }        from '../../modules/local/strelka_bam.nf'
include { STRELKA_GERMLINE_CRAM }       from '../../modules/local/strelka_cram.nf'

include { FREEBAYES_BAM }        from '../../modules/local/freebayes_bam.nf'
include { FREEBAYES_CRAM }       from '../../modules/local/freebayes_cram.nf'

include { SAMTOOLS_MPILEUP_BAM } from '../../modules/nf-core/software/samtools/mpileup/main.nf'
include { SAMTOOLS_MPILEUP_BAM as SAMTOOLS_MPILEUP_CRAM} from '../../modules/nf-core/software/samtools/mpileup/main.nf'

include { TIDDIT_BAM } from '../../modules/local/tiddit_bam.nf'
//include { TIDDIT_CRAM } from '../../modules/local/tiddit_cram.nf'

include { MANTA_SINGLE_BAM } from '../../modules/local/manta_bam_normal.nf'
include { MANTA_SINGLE_CRAM } from '../../modules/local/manta_cram_normal.nf'

workflow MAP_BENCHMARK {

    take:
        reads   // channel: [ val(name), reads ]
        fasta
        intervals
        dbsnp
        dbsnpIndex
        knownIndels
        knownIndelsIndex

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

        MAP_CRAM(split_reads, fasta, index) // only necessary once adam works
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
        MD_GATK_SPARK_BAM_TO_CRAM(mapped_spark_bam, fasta, dict, faidx)

        ESTIMATE_LIBRARY_COMPLEXITY_BAM(mapped_spark_bam, dict, faidx)
        ESTIMATE_LIBRARY_COMPLEXITY_CRAM(mapped_spark_cram, fasta, dict, faidx)

        //Coordinate sorted reads
        MD_GATK_BAM(mapped_bam,dict, faidx)

        if(params.parts > 1){
            cram_merged = SAMTOOLS_MERGE_CRAM(mapped_cram, fasta)
            bam_merged = MERGE_BAM(mapped_bam)
        }else{
            //cram_merged = mapped_cram
            bam_merged = mapped_bam
        }
        MD_ADAM_BAM(bam_merged)
        //MD_ADAM_CRAM(mapped_spark_cram, fasta)
        MD_SAMBAMBA(bam_merged)
        //TODO: MD SAMTOOLS



        INDEX_CRAM(MD_GATK_SPARK_BAM_TO_CRAM.out)

        QUALIMAP_BAMQC(MD_GATK_BAM.out)
        QUALIMAP_BAMQC_CRAM(INDEX_CRAM.out, fasta, faidx)

        CREATE_INTERVALS_BED(intervals)
        result_intervals = CREATE_INTERVALS_BED.out.flatten()
            .map { intervalFile ->
                def duration = 0.0
                for (line in intervalFile.readLines()) {
                    final fields = line.split('\t')
                    if (fields.size() >= 5) duration += fields[4].toFloat()
                    else {
                        start = fields[1].toInteger()
                        end = fields[2].toInteger()
                        duration += (end - start) / params.nucleotides_per_second
                    }
                }
                [duration, intervalFile]
            }.toSortedList({ a, b -> b[0] <=> a[0] })
            .flatten().collate(2)
            .map{duration, intervalFile -> intervalFile}

        //result_intervals.dump()
        cram_baserecalibrator = INDEX_CRAM.out.combine(result_intervals) //TODO: this cram is maybe not correctly sorted, actually with samtools view -H SO:coordinate is set, so we are golden here
        bam_baserecalibrator = MD_GATK_BAM.out.combine(result_intervals)

        //TABIX_DBSNP([[id:"${dbsnp.fileName}"], dbsnp])
        //TABIX_KNOWN_INDELS([[id:"${knownIndels.fileName}"], knownIndels])
        //TABIX_KNOWN_INDELS.dump()

        // TODO requires reads to be coordinate sorted, this is ok here as long as we use the onces from w/o spark MAPPING, since they are coordinate sorted
        BASERECALIBRATION_CRAM(cram_baserecalibrator,
                                fasta,
                                dict,
                                faidx,
                                dbsnp,
                                dbsnpIndex,
                                knownIndels,
                                knownIndelsIndex)

        BASERECALIBRATION_BAM(bam_baserecalibrator,
                                fasta,
                                dict,
                                faidx,
                                dbsnp,
                                dbsnpIndex,
                                knownIndels,
                                knownIndelsIndex)

        BASERECALIBRATION_CRAM_SPARK(cram_baserecalibrator,
                                fasta,
                                dict,
                                faidx,
                                dbsnp,
                                dbsnpIndex,
                                knownIndels,
                                knownIndelsIndex)

        BASERECALIBRATION_BAM_SPARK(bam_baserecalibrator,
                                fasta,
                                dict,
                                faidx,
                                dbsnp,
                                dbsnpIndex,
                                knownIndels,
                                knownIndelsIndex)

        GATHER_BQSR_REPORTS_BAM(BASERECALIBRATION_BAM.out.table.groupTuple())
        GATHER_BQSR_REPORTS_CRAM(BASERECALIBRATION_CRAM.out.table.groupTuple())


        bqsr_bam = bam_baserecalibrator.combine(GATHER_BQSR_REPORTS_BAM.out, by: 0)
        bqsr_cram = cram_baserecalibrator.combine(GATHER_BQSR_REPORTS_CRAM.out, by: 0)

        bqsr_bam.dump()

        APPLYBQSR_BAM(bqsr_bam, fasta, faidx, dict )
        APPLYBQSR_SPARK_BAM(bqsr_bam, fasta, faidx, dict)
        APPLYBQSR_CRAM(bqsr_cram, fasta, faidx, dict)
        APPLYBQSR_SPARK_CRAM(bqsr_cram, fasta, faidx, dict)

        BQSRSPARKPIPELINE_SPARK_BAM(bam_baserecalibrator, fasta, faidx, dict, dbsnp, dbsnpIndex, knownIndels, knownIndelsIndex )
        BQSRSPARKPIPELINE_SPARK_CRAM(cram_baserecalibrator, fasta, faidx, dict, dbsnp, dbsnpIndex, knownIndels, knownIndelsIndex )

        // //TODO BAMQC: samtools view, samtools sort, qualimap

        // //
        //applybqsr_spark_bam = APPLYBQSR_SPARK_BAM.out.groupTuple()
        //applybqsr_spark_cram = APPLYBQSR_SPARK_CRAM.out.groupTuple()
        applybqsr_bam = APPLYBQSR_BAM.out.groupTuple()
        applybqsr_cram = APPLYBQSR_CRAM.out.groupTuple()

        // // //ONly needed when no intervals are used
        // //SAMTOOLS_MERGE_INDEX_CRAM_SPARK(applybqsr_spark_cram,fasta)
        SAMTOOLS_MERGE_INDEX_CRAM(applybqsr_cram, fasta)
        SAMTOOLS_MERGE_INDEX_BAM(applybqsr_bam)
        // //SAMTOOLS_MERGE_INDEX_BAM_SPARK (applybqsr_spark_bam)

        //Germline variant calling

        haplotypeCaller_Bam = SAMTOOLS_MERGE_INDEX_BAM.out.combine(result_intervals)
        //haplotypeCaller_Bam_spark = SAMTOOLS_MERGE_INDEX_BAM_SPARK.combine(intervals)
        haplotypeCaller_cram = SAMTOOLS_MERGE_INDEX_CRAM.out.combine(result_intervals)
        // haplotypeCaller_cram_spark = SAMTOOLS_MERGE_INDEX_CRAM_SPARK.combine(intervals)

        // TODO requires reads to be coordinate sorted, this is ok here as long as we use the onces from w/o spark MAPPING, since they are coordinate sorted
        HAPLOTYPECALLER_BAM(haplotypeCaller_Bam, fasta, faidx, dict, dbsnp, dbsnpIndex)
        //HAPLOTYPECALLER_SPARK_BAM(haplotypeCaller_Bam, fasta, faidx, dict, dbsnp, dbsnpIndex)
        HAPLOTYPECALLER_CRAM(haplotypeCaller_cram, fasta, faidx, dict, dbsnp, dbsnpIndex)
        // HAPLOTYPECALLER_SPARK_CRAM(haplotypeCaller_cram, fasta, faidx, dict, dbsnp, dbsnpIndex)

        // TODO no sorting requiremnts in docs
        STRELKA_GERMLINE_BAM(SAMTOOLS_MERGE_INDEX_BAM.out, fasta, faidx)
        STRELKA_GERMLINE_CRAM(SAMTOOLS_MERGE_INDEX_CRAM.out, fasta, faidx)

        //FREEBAYES BAM + CRAM //TODO sorted by reference position
        FREEBAYES_BAM(haplotypeCaller_Bam, fasta, faidx)
        FREEBAYES_CRAM(haplotypeCaller_cram, fasta, faidx)

        //TIDDIT BAM + CRAM
        TIDDIT_BAM(SAMTOOLS_MERGE_INDEX_BAM.out,fasta)
        //TIDDIT_CRAM(SAMTOOLS_MERGE_INDEX_CRAM.out,fasta)

        //SAMTOOLS MPILEUP: only bam :(
        SAMTOOLS_MPILEUP_BAM(SAMTOOLS_MERGE_INDEX_BAM.out, fasta)
        SAMTOOLS_MPILEUP_CRAM(SAMTOOLS_MERGE_INDEX_CRAM.out, fasta)

        MANTA_SINGLE_BAM(SAMTOOLS_MERGE_INDEX_BAM.out, fasta, faidx)
        MANTA_SINGLE_CRAM(SAMTOOLS_MERGE_INDEX_CRAM.out, fasta, faidx)
        ////////
        //SOMATIC VARIANT CALLING, first the others, this is more or less covered
        //////

        //STRELKA SOMATIC

        //MANTA BAM + CRAM

        //MUTECT BAM + CRAM

        //CNVkit BAM + CRAM (according to github)

        //ASCAT  BAM + CRAM (at least with ascatNGS)

        //CONTROLFREEC BAM + CRAM (or rather pileup)

        //MSISensor Bam + CRAM Supported

    emit:
        MAP_BAM_SPARK.out

}