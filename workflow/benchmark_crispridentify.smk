configfile: Path("config/parameters.yaml")


DATASETS = ["negative", "single", "2c"]
SPLITS = ["positive", "campy"]


rule all:
    input:
        expand(
            "results/crispridentify_benchmark-new/{dataset}/{filename}",
            dataset=DATASETS,
            filename=[
                "Complete_spacer_dataset.fasta",
                "Complete_summary.csv",
            ],
        ),
        expand(
            "results/crispridentify_benchmark-split/{split}/{filename}",
            split=SPLITS,
            filename=[
                "Complete_spacer_dataset.fasta",
                "Complete_summary.csv",
            ],
        ),


rule crispridentify:
    input:
        fasta="resources/concatenated_input/{dataset}.fasta",
        script="git/CRISPRidentify/CRISPRidentify.py",
    output:
        spacers="results/crispridentify_benchmark-new/{dataset}/Complete_spacer_dataset.fasta",
        summary="results/crispridentify_benchmark-new/{dataset}/Complete_summary.csv",
    params:
        work_dir=subpath(input.script, parent=True),
        in_dir=subpath(input.fasta, parent=True),
        out_dir=subpath(output.spacers, parent=True),
    conda:
        "../envs/crispridentify.yaml"
    threads: config["crispridentify"]["threads"]
    resources:
        mem_mb=int(config["crispridentify"]["memory"]),
        walltime=int(config["crispridentify"]["time"]),
        runtime=int(config["crispridentify"]["time"]),
    log:
        "log/crispridentify_benchmark-new/{dataset}.txt",
    benchmark:
        "log/benchmark/crispridentify_benchmark-new/{dataset}.txt"
    shell:
        r"""
rm -f "{params.in_dir}/.snakemake_timestamp"
rm -rf "{params.out_dir}"
cd {params.work_dir}

python CRISPRidentify.py --cpu {threads} --file "../../{input.fasta}"\
 --result_folder "../../{params.out_dir}" --fasta_report True\
 --strand False > "../../{log}" 2>&1
        """


rule crispridentify_split:
    input:
        directory="resources/{split}-split/",
        script="git/CRISPRidentify/CRISPRidentify.py",
    output:
        spacers="results/crispridentify_benchmark-split/{split}/Complete_spacer_dataset.fasta",
        summary="results/crispridentify_benchmark-split/{split}/Complete_summary.csv",
    params:
        work_dir=subpath(input.script, parent=True),
        out_dir=subpath(output.spacers, parent=True),
    conda:
        "../envs/crispridentify.yaml"
    threads: config["crispridentify"]["threads"]
    resources:
        mem_mb=int(config["crispridentify"]["memory"]),
        walltime=int(config["crispridentify"]["time"]),
        runtime=int(config["crispridentify"]["time"]),
    log:
        "log/crispridentify_benchmark-new/{split}-split.txt",
    benchmark:
        "log/benchmark/crispridentify_benchmark-new/{split}-split.txt"
    shell:
        r"""
rm -f "{input.directory}/.snakemake_timestamp"
rm -rf "{params.out_dir}"
cd {params.work_dir}

for split in ../../{input.directory}/*; do
    number=$(basename -s .fasta ${{split}} | sed 's/[A-Za-z_-]*//g')

    python CRISPRidentify.py --cpu {threads} --file ${{split}}\
    --result_folder "../../{params.out_dir}/part${{number}}"\
    --fasta_report True --strand False > "../../{log}" 2>&1
done

cd ../..

csv_files=( $(find {params.out_dir} -mindepth 2 -maxdepth 2 -type f -name "Complete_summary.csv") )
head -1 ${{csv_files[0]}} > {output.summary}
for csv_file in ${{csv_files[*]}}; do
    sed 1d ${{csv_file}} >> {output.summary}
done

fasta_files= ( $(find {params.out_dir} -mindepth 2 -maxdepth 2 -type f -name "Complete_spacer_dataset.fasta") )
cat ${{fasta_files[*]}} > {output.spacers}
        """
