#!/usr/bin/env nextflow
/*
========================================================================================
                         FriederikeHanssen/babysarek
========================================================================================
 FriederikeHanssen/babysarek Analysis Pipeline.
 #### Homepage / Documentation
 https://github.com/FriederikeHanssen/babysarek
----------------------------------------------------------------------------------------
*/

nextflow.enable.dsl=2

// Print help message if required

// if (params.help) {
//     def command = "nextflow run FriederikeHanssen/babysarek -profile docker --input sample.tsv"
//     log.info Schema.params_help("$baseDir/nextflow_schema.json", command)
//     exit 0
// }

/*
================================================================================
                        INCLUDE SAREK FUNCTIONS
================================================================================
*/

/*
================================================================================
                        INCLUDE SAREK FUNCTIONS
================================================================================
*/

include {
    extract_fastq;
    has_extension;
} from './modules/local/functions'

/*
================================================================================
                         SET UP CONFIGURATION VARIABLES
================================================================================
*/

// Check parameters

//Checks.aws_batch(workflow, params)     // Check AWS batch settings
//Checks.hostname(workflow, params, log) // Check the hostnames against configured profiles

/*
================================================================================
                         INCLUDE MODULES - Generic things
================================================================================
*/

def modules = params.modules.clone()

/*
================================================================================
                         INCLUDE LOCAL PIPELINE MODULES
================================================================================
*/


/*
================================================================================
                       INCLUDE LOCAL PIPELINE SUBWORKFLOWS
================================================================================
*/
include { PREPROCESSING } from './modules/subworkflows/preprocessing.nf' addParams( seqkit_options: modules['seqkit'],
                                                                                    dict_options: modules['dict'], 
                                                                                    fai_options: modules['samtools_faidx'], 
                                                                                    bwamem2_options: modules['bwamem2'], 
                                                                                    bwamem2_index_options: modules['bwamem2_index'], 
                                                                                    md_gatk_options: modules['md_gatk'],
                                                                                    md_adam_options: modules['md_adam'],
                                                                                    md_sambamba_options: modules['md_sambamba'])
/*
================================================================================
                        INCLUDE nf-core PIPELINE MODULES
================================================================================
*/

/*
================================================================================
                      INCLUDE nf-core PIPELINE SUBWORKFLOWS
================================================================================
*/

//include { PREPROCESSING } from './modules/subworkflows/preprocessing.nf'

/*
================================================================================
                        RUN THE WORKFLOW
================================================================================
*/

if (params.input && (has_extension(params.input, "tsv"))) { 
    ch_input = extract_fastq(params.input)
} else {
    if (params.input){ 
        Channel.from(params.input)
           .map { row -> [ row[0], file(row[1][0], checkIfExists: true), file(row[1][1], checkIfExists: true) ] }
           .ifEmpty { exit 1, "params.input was empty - no input files supplied" }
           .set { ch_input }
    }  else{
        exit 1, "Input  not specified!" 
    }
}

// Check if genome exists in the config file
if (params.genomes && !params.genomes.containsKey(params.genome) && !params.igenomes_ignore) {
    exit 1, "The provided genome '${params.genome}' is not available in the iGenomes file. Currently the available genomes are ${params.genomes.keySet().join(", ")}"
} else if (params.genomes && !params.genomes.containsKey(params.genome) && params.igenomes_ignore) {
    exit 1, "The provided genome '${params.genome}' is not available in the genomes file. Currently the available genomes are ${params.genomes.keySet().join(", ")}"
}

params.fasta      = params.genome ? params.genomes[params.genome].fasta                   ?: false : false
fasta             = params.fasta  ? file(params.fasta)             : file("${params.outdir}/no_file")


workflow {

    /*
    ================================================================================
                                    PREPROCESSING
    ================================================================================
    */

    // CHECK_SAMPLESHEET(ch_input)
    //     .splitCsv(header:true, sep:',')
    //     .map { check_samplesheet_paths(it) }
    //     .set { ch_raw_reads }
    ch_input.dump(tag:'Input')
    if (params.nf){
        //OPTION 1: Use nextflow build in
        ch_input.splitFastq( by: 100000 , file:true, pe: true, compress: true).set{split_read_pairs}
    }else{
        //OPTION 2 Use seqkit
        PREPROCESSING(ch_input, fasta)
    }




    
    /*
    ================================================================================
                                BASERECALIBRATION
    ================================================================================
    */

    /*
    ================================================================================
                                GERMLINE VARIANT CALLING
    ================================================================================
    */
 
    /*
    ================================================================================
                                SOMATIC VARIANT CALLING
    ================================================================================
    */

    /*
    ================================================================================
                                    ANNOTATION
    ================================================================================
    */

    //these steps we should probably completely omit (for time comparison at least), this is what big sarek is for 

    /*
    ================================================================================
                                        MultiQC
    ================================================================================
    */
    // OUTPUT_DOCUMENTATION(
    //     output_docs,
    //     output_docs_images)

    // GET_SOFTWARE_VERSIONS()

    // MULTIQC(
    //     GET_SOFTWARE_VERSIONS.out.yml,
    //     multiqc_config,
    //     multiqc_custom_config.ifEmpty([]),
    //     report_markduplicates.collect().ifEmpty([]),
    //     workflow_summary)
}

/*
================================================================================
                        SEND COMPLETION EMAIL
================================================================================
 */

// workflow.onComplete {
//     def multiqc_report = []
//     Completion.email(workflow, params, summary, run_name, baseDir, multiqc_report, log)
//     Completion.summary(workflow, params, log)
// }
