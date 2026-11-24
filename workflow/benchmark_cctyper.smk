configfile: Path("config/parameters.yaml")


DATASETS = ["negative", "single", "2c", "campy"]
SPLITS = ["positive"]


rule all:
    input:
        "results/cctyper_crisprs.tsv",


rule cctyper:
    input:
        "resources/concatenated_input/{dataset}.fasta",
    output:
        crispr_cas="results/cctyper_benchmark/{dataset}/CRISPR_Cas.tab",
        cas="results/cctyper_benchmark/{dataset}/cas_operons_putative.tab",
        hmmer="results/cctyper_benchmark/{dataset}/hmmer.tab",
        crispr="results/cctyper_benchmark/{dataset}/crisprs_all.tab",
        orphan="results/cctyper_benchmark/{dataset}/crisprs_orphan.tab",
        spacers=directory("results/cctyper_benchmark/{dataset}/spacers/"),
    params:
        out_dir=subpath(output[1], parent=True),
    conda:
        "../envs/cctyper-1.8.yaml"
    threads: config["cctyper"]["threads"]
    log:
        "log/cctyper_benchmark/{dataset}.txt",
    benchmark:
        "log/benchmark/cctyper_benchmark/{dataset}.txt"
    shell:
        r"""
rm -rf {params.out_dir}

cctyper -t {threads} {input} --prodigal meta\
 {params.out_dir} --simplelog > {log} 2>&1
        """


rule cctyper_split:
    input:
        directory="resources/{split}-split/",
        script="scripts/collapse_cctyper_output.sh",
    output:
        crispr_cas="results/cctyper_benchmark/{split}-split/CRISPR_Cas.tab",
        cas="results/cctyper_benchmark/{split}-split/cas_operons_putative.tab",
        hmmer="results/cctyper_benchmark/{split}-split/hmmer.tab",
        crispr="results/cctyper_benchmark/{split}-split/crisprs_all.tab",
        orphan="results/cctyper_benchmark/{split}-split/crisprs_orphan.tab",
        spacers=directory("results/cctyper_benchmark/{split}-split/spacers/"),
    params:
        out_dir=subpath(output[1], parent=True),
    conda:
        "../envs/cctyper-1.8.yaml"
    threads: config["cctyper"]["threads"]
    log:
        "log/cctyper_benchmark/{split}-split.txt",
    benchmark:
        "log/benchmark/cctyper_benchmark/{split}-split.txt"
    shell:
        r"""
rm -rf {params.out_dir}
mkdir {params.out_dir}

for split in {input.directory}/*
do
    number=$(basename -s .fasta ${{split}} | sed 's/[A-Za-z_-]*//g')
    cctyper -t {threads} ${{split}} --prodigal meta\
     "{params.out_dir}/part${{number}}" --simplelog >> {log} 2>&1
done

bash {input.script} {params.out_dir} >> {log} 2>&1
        """


rule parse_cctyper:
    input:
        crispr_cas="results/cctyper_benchmark/{dataset}/CRISPR_Cas.tab",
        cas="results/cctyper_benchmark/{dataset}/cas_operons_putative.tab",
        hmmer="results/cctyper_benchmark/{dataset}/hmmer.tab",
        crispr="results/cctyper_benchmark/{dataset}/crisprs_all.tab",
    output:
        table="results/cctyper_benchmark/parsed/{dataset}/CRISPR-Cas.tsv",
        locus_bed="results/cctyper_benchmark/parsed/{dataset}/CRISPR-Cas.bed",
        array_bed="results/cctyper_benchmark/parsed/{dataset}/CRISPR_arrays.bed",
        orphan_bed="results/cctyper_benchmark/parsed/{dataset}/Orphan_CRISPRs.bed",
        operon_bed="results/cctyper_benchmark/parsed/{dataset}/Cas_operons.bed",
    params:
        input_dir=subpath(input.crispr_cas, parent=True),
    conda:
        "envs/pyfaidx_pandas.yaml"
    threads: config["default_job"]["threads"]
    resources:
        mem_mb=int(config["default_job"]["memory"]),
        walltime=int(config["default_job"]["time"]),
        runtime=int(config["default_job"]["time"]),
    log:
        "log/cctyper_benchmark/parse_cctyper/{dataset}.txt",
    benchmark:
        "log/benchmark/cctyper_benchmark/parse_cctyper/{dataset}.txt"
    script:
        "scripts/cctyper_extender.py"


rule create_cctyper_crispr_table:
    input:
        table=expand(
            "results/cctyper_benchmark/parsed/{dataset}/CRISPR-Cas.tsv",
            dataset=DATASETS
        ),
    output:
        "results/cctyper_crisprs.tsv",
    conda:
        "envs/R_tidyverse.yaml"
    threads: 1
    resources:
        mem_mb=int(config["default_job"]["memory"]),
        walltime=int(config["default_job"]["time"]),
        runtime=int(config["default_job"]["time"]),
    log:
        "log/cctyper_benchmark/create_cctyper_crispr_table.txt",
    benchmark:
        "log/benchmark/cctyper_benchmark/create_cctyper_crispr_table.txt"
    script:
        "scripts/summarise_crisprs.R"
