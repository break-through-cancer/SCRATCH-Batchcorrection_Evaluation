process BATCHCORRECTION {

    tag "Performing Barch Correction"
    label 'process_medium'
    container 'syedsazaidi/scratch-batchcor:V1'

    publishDir "${params.outdir}",
            mode: 'copy',
            overwrite: true

    cpus 4
    memory '16 GB'
    errorStrategy 'terminate'

    input:
    path seurat_object
    path notebook
    path config

    output:
    path "report/${notebook.baseName}.html", emit: report,  optional: true
    path "figures/**",                     emit: figures, optional: true
    path "data/**",                        emit: data,    optional: true

    when:
    task.ext.when == null || task.ext.when

    /*
    * Build Quarto -P params safely (quote values!).
    */
    script:

    // helper 
    def q = { v -> "'${v.toString().replace("'", "'\\''")}'" }

    // build flat "-P key:value" list with safe quoting for things containing commas/semicolons
    def parts = []
    parts << "-P seurat_object:${seurat_object}"
    parts << "-P project_name:${params.project_name}"
    parts << "-P input_integration_method:${params.input_integration_method}"
    parts << "-P input_target_variables:${params.input_target_variables.replaceAll(',', ';')}"
    parts << "-P input_batch_step:${params.input_batch_step}"
    parts << "-P exclude_labels:${params.exclude_labels.replaceAll(',', ';')}"
    // for label_candidates, include quotes because of semicolons
    parts << "-P label_candidates:'${params.label_candidates.replaceAll(',', ';')}'"
    parts << "-P n_hvgs:${params.n_hvgs}"
    parts << "-P n_pcs:${params.n_pcs}"
    parts << "-P n_threads:${params.n_threads}"
    parts << "-P n_memory:${params.n_memory}"
    // IMPORTANT: do NOT quote $PWD so the shell expands it
    parts << "-P work_directory:$PWD"

    def param_file = parts.join(' ')

    """
    set -euo pipefail

    # ensure these roots exist so the globs always match
    mkdir -p report figures data

    # render (options first, then params)
    quarto render --execute ${notebook} ${param_file}
    """
}


