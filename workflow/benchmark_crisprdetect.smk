configfile: Path("config/parameters.yaml")


DATASETS = ["positive", "negative", "single", "2c", "campy"]


rule all:
    input:
        expand(
            "results/crisprdetect_benchmark/{dataset}/output",
            dataset=DATASETS,
        ),


rule crisprdetect:
    input:
        fasta="resources/concatenated_input/{dataset}.fasta",
        script="git/CRISPRDetect_3.0/CRISPRDetect3",
    output:
        multiext(
            "results/crisprdetect_benchmark/{dataset}/output",
            "",
            ".fp",
            ".gff",
            ".spacers.fa",
            ".CAS_DOMAIN.tab",
            ".CAS_GENE.tab",
        ),
    conda:
        "../envs/crisprdetect.yaml"
    params:
        work_dir=subpath(output[0], ancestor=2),
    threads: config["crisprdetect"]["threads"]
    resources:
        mem_mb=int(config["crisprdetect"]["memory"]),
        walltime=int(config["crisprdetect"]["time"]),
        runtime=int(config["crisprdetect"]["time"]),
    log:
        "log/crisprdetect_benchmark/{dataset}.txt",
    benchmark:
        "log/benchmark/crisprdetect_benchmark/{dataset}.txt"
    shell:
        r"""
perl git/CRISPRDetect_3.0/CRISPRDetect3 -f {input.fasta} -o {output}\
 -array_quality_score_cutoff 3 -check_direction 1 -annotate_cas_genes 1\
 -T 16 -wgs 0 -check_plasmid 0 > {log} 2>&1
        """
