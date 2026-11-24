configfile: Path("config-noconda/parameters.yaml")


DATASETS = ["negative", "single", "2c", "campy"]
SPLITS = ["positive"]


rule all:
    input:
        expand(
            "results/defensefinder_benchmark/{dataset}/{dataset}_defense_finder_{file}.tsv",
            dataset=DATASETS,
            file=["genes", "hmmer", "systems"],
        ),
        expand(
            "results/defensefinder_benchmark/{split}-split/defense_finder_{file}.tsv",
            split= SPLITS, file = ["genes", "hmmer", "systems"]
        )


rule defensefinder:
    input:
        fasta="resources/concatenated_input/{dataset}.fasta",
    output:
        expand(
            "results/defensefinder_benchmark/{{dataset}}/{{dataset}}_defense_finder_{file}.tsv",
            file=["genes", "hmmer", "systems"],
        ),
    params:
        out_dir=subpath(output[0], parent=True),
    threads: config["defensefinder"]["threads"]
    resources:
        mem_mb=int(config["defensefinder"]["memory"]),
        walltime=int(config["defensefinder"]["time"]),
        runtime=int(config["defensefinder"]["time"]),
    log:
        "log/defensefinder_benchmark/{dataset}.txt",
    benchmark:
        "log/benchmark/defensefinder_benchmark/{dataset}.txt"
    shell:
        r"""
defense-finder run -o {params.out_dir} -w {threads} {input} > {log} 2>&1
        """

rule defensefinder_split:
    input:
        directory="resources/{split}-split/",
    output:
        expand(
            "results/defensefinder_benchmark/{{split}}-split/defense_finder_{file}.tsv",
            file=["genes", "hmmer", "systems"],
        ),
    params:
        out_dir=subpath(output[0], parent=True),
    threads: config["defensefinder"]["threads"]
    resources:
        mem_mb=int(config["defensefinder"]["memory"]),
        walltime=int(config["defensefinder"]["time"]),
        runtime=int(config["defensefinder"]["time"]),
    log:
        "log/defensefinder_benchmark/{split}.txt",
    benchmark:
        "log/benchmark/defensefinder_benchmark/{split}.txt"
    shell:
        r"""
for split in {input.directory}/*
do
    number=$(basename -s .fasta ${{split}} | sed 's/[A-Za-z_-]*//g')
    defense-finder run -o {params.out_dir}/part${{number}}\
     -w {threads} ${{split}} >> {log} 2>&1
done

for result in genes hmmer systems
do
    output_file="{params.out_dir}/defense_finder_${{result}}.tsv"
    all_files=( $(find {params.out_dir} -mindepth 2 -maxdepth 2 -type f -name "*_defense_finder_${{result}}.tsv") )
    head -n 1 ${{all_files[0]}} > ${{output_file}}
    for tab_file in ${{all_files[*]}}
    do
        sed 1d ${{tab_file}} >> ${{output_file}}
    done
done
        """
