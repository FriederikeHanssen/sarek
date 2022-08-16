//
// MARKDUPLICATES
//
// For all modules here:
// A when clause condition is defined in the conf/modules.config to determine if the module should be run

include { SAMBAMBA_MARKDUP                       } from '../../../../modules/local/sambamba'
include { BAM_TO_CRAM                            } from '../../bam_to_cram'
//include { BIOBAMBAM_BAMSORMADUP                  } from '../../../../modules/nf-core/modules/biobambam/bamsormadup/main'

workflow MARKDUPLICATES {
    take:
        bam                           // channel: [mandatory] meta, bam
        fasta                         // channel: [mandatory] fasta
        fasta_fai                     // channel: [mandatory] fasta_fai
        intervals_bed_combined        // channel: [optional]  intervals_bed

    main:
    ch_versions = Channel.empty()
    qc_reports  = Channel.empty()

    // Run Markupduplicates
    SAMBAMBA_MARKDUP(bam)
    //BIOBAMBAM_BAMSORMADUP(bam, fasta)

    // Convert output to cram
    BAM_TO_CRAM(SAMBAMBA_MARKDUP.out.bam.join(SAMBAMBA_MARKDUP.out.bai), Channel.empty(), fasta, fasta_fai, intervals_bed_combined)

    // Gather all reports generated
    qc_reports = qc_reports.mix(SAMBAMBA_MARKDUP.out.metrics,
                                //BIOBAMBAM_BAMSORMADUP.out.metrics,
                                BAM_TO_CRAM.out.qc)

    // Gather versions of all tools used
    ch_versions = ch_versions.mix(SAMBAMBA_MARKDUP.out.versions.first())
    ch_versions = ch_versions.mix(BAM_TO_CRAM.out.versions)

    emit:
        cram     = BAM_TO_CRAM.out.cram_converted
        qc       = qc_reports

        versions = ch_versions // channel: [ versions.yml ]
}
