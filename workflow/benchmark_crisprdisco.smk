configfile: Path("config-noconda/parameters.yaml")


DATASETS = ["negative", "single", "2c", "campy"]
SPLITS = ["positive"]


rule all:
    input:
        expand(
            "results/crisprdisco_benchmark/{dataset}/Master_CRISPR_summary_table_current.csv",
            dataset=DATASETS,
        ),
        expand(
            "results/crisprdisco_benchmark/{split}-split/Master_CRISPR_summary_table_current.csv",
            split=SPLITS,
        ),


rule prepare_crisprdisco_faa:
    input:
        "resources/concatenated_input/{dataset}.fasta",
    output:
        fna="results/crisprdisco_input/{dataset}/crisprdisco.fna",
        faa="results/crisprdisco_input/{dataset}/crisprdisco.faa",
    params:
        out_dir=subpath(output.fna, parent=True),
    threads: config["prodigal"]["threads"]
    resources:
        mem_mb=int(config["prodigal"]["memory"]),
        walltime=int(config["prodigal"]["time"]),
        runtime=int(config["prodigal"]["time"]),
    log:
        "log/prepare_crisprdisco_faa/{dataset}.txt",
    benchmark:
        "log/benchmark/prepare_crisprdisco_faa/{dataset}.txt"
    shell:
        r"""
mkdir -p {params.out_dir}

prodigal -a {output.faa} -i {input} -p meta > /dev/null 2> {log}

cd {params.out_dir}
ln -s ../../../{input} $(basename {output.fna})
        """


rule prepare_crisprdisco_csv:
    input:
        fna="results/crisprdisco_input/{dataset}/crisprdisco.fna",
        faa="results/crisprdisco_input/{dataset}/crisprdisco.faa",
    output:
        "results/crisprdisco_input/{dataset}/input.csv",
    params:
        out_dir=subpath(output[0], parent=True),
    threads: config["default_job"]["threads"]
    resources:
        mem_mb=int(config["default_job"]["memory"]),
        walltime=int(config["default_job"]["time"]),
        runtime=int(config["default_job"]["time"]),
    log:
        "log/prepare_crisprdisco_csv/{dataset}.txt",
    benchmark:
        "log/benchmark/prepare_crisprdisco_csv/{dataset}.txt"
    shell:
        r"""
echo "Path" > {output} 2> {log}
echo {input.faa} | sed 's/.faa//g' >> {output} 2>> {log}
        """


rule run_crisprdisco:
    input:
        genomes="results/crisprdisco_input/{dataset}/crisprdisco.fna",
        genes="results/crisprdisco_input/{dataset}/crisprdisco.faa",
        csv="results/crisprdisco_input/{dataset}/input.csv",
    output:
        subtype="results/crisprdisco_benchmark/{dataset}/CRISPR-Cas_Subtype_summary.csv",
        castype="results/crisprdisco_benchmark/{dataset}/CRISPR-Cas_Type_summary.csv",
        repeats="results/crisprdisco_benchmark/{dataset}/CRISPR_repeat_seqs_current.csv",
        without="results/crisprdisco_benchmark/{dataset}/Genomes_without_CRISPR_current.csv",
        summary="results/crisprdisco_benchmark/{dataset}/Master_CRISPR_summary_table_current.csv",
        repeat_table="results/crisprdisco_benchmark/{dataset}/repeat_summary_table_current.csv",
    params:
        tmp_dir=subpath(input.csv, parent=True),
        out_dir=subpath(output.subtype, parent=True),
    threads: config["default_job"]["threads"]
    resources:
        mem_mb=int(config["default_job"]["memory"]),
        walltime=int(config["default_job"]["time"]),
        runtime=int(config["default_job"]["time"]),
    log:
        "log/run_crisprdisco/{dataset}.txt",
    benchmark:
        "log/benchmark/run_crisprdisco/{dataset}.txt"
    shell:
        r"""
disco --workingdir {params.tmp_dir} --outdir {params.out_dir}\
 --cas T --repeats T --summary T --date current {input.csv} > {log} 2>&1
        """


rule prepare_split_faa:
    input:
        "resources/{split}-split/",
    output:
        dummy="results/crisprdisco_input/{split}-split/prodigal.done",
    params:
        out_dir=directory("results/crisprdisco_input/{split}-split"),
    threads: config["prodigal"]["threads"]
    resources:
        mem_mb=int(config["prodigal"]["memory"]),
        walltime=int(config["prodigal"]["time"]),
        runtime=int(config["prodigal"]["time"]),
    log:
        "log/prepare_split_faa/{split}.txt",
    benchmark:
        "log/benchmark/prepare_split_faa/{split}.txt"
    shell:
        r"""
mkdir -p {params.out_dir}

for split in {input}/*; do
    number=$(basename -s .fasta ${{split}} | sed 's/[A-Za-z_-]*//g')

    prodigal -a "{params.out_dir}/part${{number}}.faa" -i ${{split}} -p meta > /dev/null 2> {log}
    ( cd {params.out_dir} && ln -s ../../../${{split}} part${{number}}.fna )
done

touch {output.dummy}
        """


rule prepare_split_csv:
    input:
        "results/crisprdisco_input/{split}-split/prodigal.done",
    output:
        csv="results/crisprdisco_input/{split}-split/input.csv",
    params:
        out_dir=subpath(output[0], parent=True),
    threads: config["default_job"]["threads"]
    resources:
        mem_mb=int(config["default_job"]["memory"]),
        walltime=int(config["default_job"]["time"]),
        runtime=int(config["default_job"]["time"]),
    log:
        "log/prepare_split_csv/{split}.txt",
    benchmark:
        "log/benchmark/prepare_split_csv/{split}.txt"
    shell:
        r"""
echo "Path" > {output.csv} 2> {log}
for inputfile in $(dirname {input})/*.faa; do
    echo ${{inputfile/.faa/}} >> {output.csv}
done 2>> {log}
        """

rule run_crisprdisco_split:
    input:
        csv="results/crisprdisco_input/{spit}-split/input.csv",
    output:
        subtype="results/crisprdisco_benchmark/{spit}-split/CRISPR-Cas_Subtype_summary.csv",
        castype="results/crisprdisco_benchmark/{spit}-split/CRISPR-Cas_Type_summary.csv",
        repeats="results/crisprdisco_benchmark/{spit}-split/CRISPR_repeat_seqs_current.csv",
        without="results/crisprdisco_benchmark/{spit}-split/Genomes_without_CRISPR_current.csv",
        summary="results/crisprdisco_benchmark/{spit}-split/Master_CRISPR_summary_table_current.csv",
        repeat_table="results/crisprdisco_benchmark/{spit}-split/repeat_summary_table_current.csv",
    params:
        tmp_dir=subpath(input.csv, parent=True),
        out_dir=subpath(output.subtype, parent=True),
    threads: config["default_job"]["threads"]
    resources:
        mem_mb=int(config["default_job"]["memory"]),
        walltime=int(config["default_job"]["time"]),
        runtime=int(config["default_job"]["time"]),
    log:
        "log/run_crisprdisco/{spit}-split.txt",
    benchmark:
        "log/benchmark/run_crisprdisco/{spit}-split.txt"
    shell:
        r"""
disco --workingdir {params.tmp_dir} --outdir {params.out_dir}\
 --cas T --repeats T --summary T --date current {input.csv} > {log} 2>&1
        """