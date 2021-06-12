
params.seqkit_options                   = [:]
params.dict_options                     = [:]
params.fai_options                      = [:]
params.bwamem2_options                  = [:]
params.bwamem2_index_options            = [:]
params.md_gatk_options                  = [:]
params.estimate_lib_complexity_options  = [:] 
params.bqsr_options                     = [:]
params.intervals_options                = [:]

include { SPLIT_FASTQ }                 from '../local/splitfastq.nf'                   addParams( options: params.seqkit_options  )
include { DICT }                        from '../local/gatk_createsequencedictionary'   addParams( options: params.dict_options  )
include { SAMTOOLS_FAIDX }              from '../local/create_fai.nf'                   addParams( options: params.fai_options  )

include { MAP_BAM }                     from '../local/mapping_bam.nf'                  addParams( options: params.bwamem2_options  )
include { BWAMEM2_INDEX }               from '../local/index.nf'                        addParams ( options: params.bwamem2_index_options )

include { MD_GATK }                     from '../local/md_gatk.nf'                      addParams( options: params.md_gatk_options  )
include { ESTIMATE_LIBRARY_COMPLEXITY } from '../local/estimatelibrarycomplexity'       addParams( options: params.estimate_lib_complexity_options  )

include { BASERECALIBRATION }           from '../local/bqsr.nf'                         //addParams ( options: params.bqsr_options )
include { BASERECALIBRATION_SPARK }           from '../local/base_recalibratorSpark.nf'                         //addParams ( options: params.bqsr_options )
include {GATHER_BQSR_REPORTS}               from '../local/gatherbqsrreport.nf'
include {GATHER_BQSR_REPORTS as GATHER_BQSR_REPORTS_SPARK }               from '../local/gatherbqsrreport.nf'
include { APPLYBQSR }                         from '../local/applybqsr.nf'
include { APPLYBQSR_SPARK }                from '../local/applybqsrSpark.nf'
include {BQSRSPARKPIPELINE_SPARK }          from '../local/bqsrsparkpipeline.nf'
include { CREATEINTERVALBEDS }           from '../local/bedIntervals.nf'                //addParams ( options: params.intervals_options )

include { INDEX_CRAM}                   from '../local/samtools_index_cram.nf'

include { INDEX_CRAM as INDEX_CRAM_RECAL}                   from '../local/samtools_index_cram.nf'
include { HAPLOTYPECALLER }          from '../local/haplotypeCaller.nf'

include {HAPLOTYPECALLER_SPARK}     from '../local/HaplotypeCallerSpark.nf'

include {SAMTOOLS_MERGE_CRAM}       from '../local/merge_samtools_standalone.nf'


workflow BEST_WF {

    take:
        reads   // channel: [ val(name), [ reads ] ]
        fasta
        intervals
        dbsnp
        dbsnpIndex
        knownIndels
        knownIndelsIndex

    main:

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
        
        // Step 2: Mapping
        if(!params.index){
            index = BWAMEM2_INDEX(fasta)
        }else {
            index = file(params.index)
        }

        MAP_BAM(split_reads, fasta, index)
        mapped_grouped = MAP_BAM.out.groupTuple()

        // Step 3: MarkDuplicates
        duplicate_marked_cram = Channel.empty()

        dict = params.dict ? file(params.dict) : DICT(fasta)
        faidx = params.faidx ? file(params.faidx) : SAMTOOLS_FAIDX(fasta) 

        MD_GATK(mapped_grouped, fasta, dict, faidx)
        ESTIMATE_LIBRARY_COMPLEXITY(mapped_grouped, fasta, dict, faidx)

        // tuple val(name), path(cram), path(recalibrationReport), path(intervalBed)
        CREATEINTERVALBEDS(intervals)
        result_intervals = CREATEINTERVALBEDS.out.flatten()
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

        //MD_GATK.cram.out.dump()
        INDEX_CRAM(MD_GATK.out)
        //INDEX_CRAM.out.dump()


        bamBaseRecalibrator = MD_GATK.out.join(INDEX_CRAM.out).combine(result_intervals)

        BASERECALIBRATION(bamBaseRecalibrator, fasta, dict, faidx, dbsnp, dbsnpIndex, knownIndels, knownIndelsIndex)
        BASERECALIBRATION_SPARK(bamBaseRecalibrator, fasta, dict, faidx, dbsnp, dbsnpIndex, knownIndels, knownIndelsIndex)

        BASERECALIBRATION.out.map{ name, table ->
                name = name
                [name, table]
            }.groupTuple(by: [0]).set{ recaltable }
        
        BASERECALIBRATION_SPARK.out.map{ name, table ->
                name = name
                [name, table]
            }.groupTuple(by: [0]).set{ recaltable_spark }

        GATHER_BQSR_REPORTS(recaltable)
        GATHER_BQSR_REPORTS_SPARK(recaltable_spark)

        applybqsr_in = bamBaseRecalibrator.combine(GATHER_BQSR_REPORTS.out, by:[0])
        applybqsr_in_spark = bamBaseRecalibrator.combine(GATHER_BQSR_REPORTS_SPARK.out, by:[0])
        //bamBaseRecalibrator.dump()
        //GATHER_BQSR_REPORTS.out.dump()
        //applybqsr_in.dump()
        APPLYBQSR(applybqsr_in, fasta, faidx, dict)
        //APPLYBQSR_SPARK(applybqsr_in_spark, fasta, faidx, dict)

        BQSRSPARKPIPELINE_SPARK(MD_GATK.out.join(INDEX_CRAM.out), result_intervals, fasta, faidx, dict, dbsnp, dbsnpIndex, knownIndels, knownIndelsIndex)

        mergable = APPLYBQSR.out.groupTuple(by:[0])
        //mergable.dump()
        SAMTOOLS_MERGE_CRAM(mergable, fasta)

        INDEX_CRAM_RECAL(SAMTOOLS_MERGE_CRAM.out)

        caller = SAMTOOLS_MERGE_CRAM.out.join(INDEX_CRAM_RECAL.out).combine(result_intervals)
        //caller.dump()
        HAPLOTYPECALLER(caller, fasta, faidx, dict, dbsnp, dbsnpIndex)

    emit:
        md_cram = MD_GATK
        md_report= ESTIMATE_LIBRARY_COMPLEXITY
}