params.seqkit_options                   = [:]
params.bwamem2_options                  = [:]
params.bwamem2_index_options            = [:]

include { MD_GATK_BAM }                     from '../local/md_gatk.nf'                      // addParams( options: params.md_gatk_options  )
include { MD_GATK_SPARK_BAM }                     from '../local/md_gatk.nf'                   //   addParams( options: params.md_gatk_options  )
include { MD_GATK_CRAM }                     from '../local/md_gatk.nf'                      //addParams( options: params.md_gatk_options  )
include { MD_GATK_SPARK_CRAM }                     from '../local/md_gatk.nf'                 //     addParams( options: params.md_gatk_options  )

include { MD_ADAM_BAM }                     from '../local/md_gatk.nf'                      //addParams( options: params.md_gatk_options  )
include { MD_ADAM_CRAM }                     from '../local/md_gatk.nf'                    //  addParams( options: params.md_gatk_options  )

include { MD_SAMBAMBA }                     from '../local/md_gatk.nf'                     // addParams( options: params.md_gatk_options  )

include { MD_SAMTOOLS }                     from '../local/md_gatk.nf'                   //   addParams( options: params.md_gatk_options  )

include { ESTIMATE_LIBRARY_COMPLEXITY } from '../local/estimatelibrarycomplexity'      // addParams( options: params.estimate_lib_complexity_options  )


workflow MD_BENCHMARK {

    take:

    main:


    emit:


}