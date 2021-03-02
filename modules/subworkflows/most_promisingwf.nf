
params.seqkit_options                   = [:]
params.dict_options                     = [:]
params.fai_options                      = [:]
params.bwamem2_options                  = [:]
params.bwamem2_index_options            = [:]
params.md_gatk_options                  = [:]
params.estimate_lib_complexity_options  = [:] 
params.bqsr_options                     = [:]

include { SPLIT_FASTQ }                 from '../local/splitfastq.nf'                   addParams( options: params.seqkit_options  )
include { DICT }                        from '../local/gatk_createsequencedictionary'   addParams( options: params.dict_options  )
include { SAMTOOLS_FAIDX }              from '../local/create_fai.nf'                   addParams( options: params.fai_options  )

include { MAP_BAM }                     from '../local/mapping_bam.nf'                  addParams( options: params.bwamem2_options  )
include { BWAMEM2_INDEX }               from '../local/index.nf'                        addParams ( options: params.bwamem2_index_options )

include { MD_GATK }                     from '../local/md_gatk.nf'                      addParams( options: params.md_gatk_options  )
include { ESTIMATE_LIBRARY_COMPLEXITY } from '../local/estimatelibrarycomplexity'       addParams( options: params.estimate_lib_complexity_options  )

//INCLUDE { BASERECALIBRATION }           from '../local/bqsr.nf'                         addParams ( options: params.bqsr_options )
//INCLUDE { CREATEINTERVALBEDS }           from '../local/bedIntervals.nf'
workflow BEST_WF {

    take:
        reads   // channel: [ val(name), [ reads ] ]
        fasta

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
        //CREATEINTERVALBEDS(intervals)
        // bedIntervals = CREATEINTERVALBEDS.out
        //     .map { intervalFile ->
        //         def duration = 0.0
        //         for (line in intervalFile.readLines()) {
        //             final fields = line.split('\t')
        //             if (fields.size() >= 5) duration += fields[4].toFloat()
        //             else {
        //                 start = fields[1].toInteger()
        //                 end = fields[2].toInteger()
        //                 duration += (end - start) / params.nucleotides_per_second
        //             }
        //     }
        //     [duration, intervalFile]
        // }.toSortedList({ a, b -> b[0] <=> a[0] })
        // .flatten().collate(2)
        // .map{duration, intervalFile -> intervalFile}
        // bamBaseRecalibrator = MD_GATK.out.combine(bedIntervals)

        // MD_GATK.out.join()
        // BASERECALIBRATION(, fasta, dict, faidx, dbsnp, dbsnpIndex, knownIndels, knownIndelsIndex)
    emit:
        md_cram = MD_GATK
        md_report= ESTIMATE_LIBRARY_COMPLEXITY
}