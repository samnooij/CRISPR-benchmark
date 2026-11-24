configfile: Path("config-noconda/parameters.yaml")


DATASETS = ["negative", "single", "2c"]
SPLITS = ["positive", "campy"]

rule all:
    input:
        expand(
            "results/crisprcasfinder_benchmark/{dataset}/TSV/CRISPR-Cas_summary.tsv",
            dataset=DATASETS,
        ),
        expand(
            "results/crisprcasfinder_benchmark-split/{split}/TSV/CRISPR-Cas_summary.tsv",
            split=SPLITS,
        ),


rule crisprcasfinder:
    input:
        fasta="resources/concatenated_input/{dataset}.fasta",
        script="git/CRISPRCasFinder/CRISPRCasFinder.pl",
        so="git/CRISPRCasFinder/sel392v2.so",
    output:
        tables=multiext(
            "results/crisprcasfinder_benchmark/{dataset}/TSV/",
            summary="CRISPR-Cas_summary.tsv",
            summary_xls="CRISPR-Cas_summary.xls",
            cas="Cas_REPORT.tsv",
            cas_xls="Cas_REPORT.xls",
            vicinity="CRISPR-Cas_systems_vicinity.tsv",
            crispr="Crisprs_REPORT.tsv",
            crispr_xls="Crisprs_REPORT.xls",
        ),
        json="results/crisprcasfinder_benchmark/{dataset}/result.json",
        crisprs="results/crisprcasfinder_benchmark/{dataset}/rawCRISPRs.fna",
        gff=directory("results/crisprcasfinder_benchmark/{dataset}/GFF"),
        logs=directory("results/crisprcasfinder_benchmark/{dataset}/LOGs"),
    params:
        work_dir=subpath(output.json, ancestor=2),
    threads: config["crisprcasfinder"]["threads"]
    resources:
        crisprcasfinder=1,
        mem_mb=int(config["crisprcasfinder"]["memory"]),
        walltime=int(config["crisprcasfinder"]["time"]),
        runtime=int(config["crisprcasfinder"]["time"]),
    log:
        "log/crisprcasfinder_benchmark/{dataset}.txt",
    benchmark:
        "log/benchmark/crisprcasfinder_benchmark/{dataset}.txt"
    shell:
        r"""
cd {params.work_dir}
rm -rf {wildcards.dataset}

perl ../../{input.script} -i ../../{input.fasta} -outdir {wildcards.dataset}/\
 -log -cas -cpuM {threads} -ccvRep -getSummaryCasfinder -meta -cpuProkka {threads}\
 -so ../../{input.so} > ../../{log} 2>&1
        """


rule crisprcasfinder_split:
    input:
        directory="resources/{split}-underscored/",
        script="git/CRISPRCasFinder/CRISPRCasFinder.pl",
        so="git/CRISPRCasFinder/sel392v2.so",
    output:
        summary="results/crisprcasfinder_benchmark-split/{split}/TSV/CRISPR-Cas_summary.tsv",
        cas_report="results/crisprcasfinder_benchmark-split/{split}/TSV/Cas_REPORT.tsv",
        crispr_report="results/crisprcasfinder_benchmark-split/{split}/TSV/Crisprs_REPORT.tsv",
    params:
        work_dir=subpath(output.summary, ancestor=2),
    threads: config["crisprcasfinder"]["threads"]
    resources:
        crisprcasfinder=1,
        mem_mb=int(config["crisprcasfinder"]["memory"]),
        walltime=int(config["crisprcasfinder"]["time"]),
        runtime=int(config["crisprcasfinder"]["time"]),
    log:
        "log/crisprcasfinder_benchmark/{split}-split.txt",
    benchmark:
        "log/benchmark/crisprcasfinder_benchmark/{split}-split.txt"
    shell:
        r"""
cd {params.work_dir}
rm -rf ./* > ../../../{log} 2>&1

for split in ../../../{input.directory}/*; do
    number=$(basename -s .fasta ${{split}} | sed 's/[A-Za-z_-]*//g')

    perl ../../../{input.script} -i ${{split}} -outdir part${{number}}\
    -log -cas -cpuM {threads} -ccvRep -getSummaryCasfinder -meta -cpuProkka {threads}\
    -so ../../../{input.so} >> ../../../{log} 2>&1
done

cd ../../..

summaries=( $(find {params.work_dir} -mindepth 3 -maxdepth 3 -type f -name "CRISPR-Cas_summary.tsv") )
head -1 ${{summaries[0]}} > {output.summary}
for summary in ${{summaries[*]}}; do
    sed 1d ${{summary}} >> {output.summary}
done

cas_reports=( $(find {params.work_dir} -mindepth 3 -maxdepth 3 -type f -name "Cas_REPORT.tsv") )
head -1 ${{cas_reports[0]}} > {output.cas_report}
for cas_report in ${{cas_reports[*]}}; do
    sed 1d ${{cas_report}} >> {output.cas_report}
done

crispr_reports=( $(find {params.work_dir} -mindepth 3 -maxdepth 3 -type f -name "Crisprs_REPORT.tsv") )
head -1 ${{crispr_reports[0]}} > {output.crispr_report}
for crispr_report in ${{crispr_reports[*]}}; do
    sed 1d ${{crispr_report}} >> {output.crispr_report}
done
        """
