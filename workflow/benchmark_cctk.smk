configfile: Path("config/parameters.yaml")

DATASETS = [ "positive", "negative", "single", "2c", "campy" ]

rule all:
    input:
        expand(
            "results/cctk_benchmark/{dataset}/PROCESSED/CRISPR_summary_table.txt",
            dataset=DATASETS,
        ),


rule cctk:
    input:
        "resources/{dataset}",
    output:
        minced=directory("results/cctk_benchmark/{dataset}/MINCED_OUT"),
        summary="results/cctk_benchmark/{dataset}/PROCESSED/CRISPR_summary_table.txt",
    params:
        out_dir=subpath(output[0], parent=True),
    conda:
        "../envs/cctk.yaml"
    threads: config["cctk"]["threads"]
    log:
        "log/cctk_benchmark/{dataset}.txt",
    benchmark:
        "log/benchmark/cctk_benchmark/{dataset}.txt"
    shell:
        r"""
cctk minced -i {input} -o {params.out_dir} -m > {log} 2>&1
cctk minced -i {input} -o {params.out_dir} -p >> {log} 2>&1
        """
