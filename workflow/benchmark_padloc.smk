configfile: Path("config/parameters.yaml")

DATASETS = [ "positive", "negative", "single-100kb", "2c-100kb", "campy" ]

rule all:
    input:
        "results/padloc_benchmark/padloc_table.csv"


rule download_padloc_database:
    output:
        directory=directory("resources/padloc_db"),
        cm=directory("resources/padloc_db/cm"),
        cm_meta="resources/padloc_db/cm_meta.txt",
        hmm=directory("resources/padloc_db/hmm"),
        hmm_meta="resources/padloc_db/hmm_meta.txt",
        sys=directory("resources/padloc_db/sys"),
        sys_meta="resources/padloc_db/sys_meta.txt",
        system_info="resources/padloc_db/system_info.md",
    conda:
        "../envs/padloc.yaml"
    threads: 1
    resources:
        mem_mb=int(config["default_job"]["memory"]),
        walltime=int(config["default_job"]["time"]),
        runtime=int(config["default_job"]["time"]),
    log:
        "log/padloc_benchmark/download_padloc_database.txt",
    benchmark:
        "log/benchmark/padloc_benchmark/download_padloc_database.txt"
    shell:
        r"""
padloc --data resources/padloc_db --db-install v2.0.0 > {log} 2>&1
        """


rule padloc:
    input:
        dataset="resources/{dataset}/",
        db="resources/padloc_db",
    output:
        "results/padloc_benchmark/{dataset}/complete",
    conda:
        "../envs/padloc.yaml"
    threads: config["padloc"]["threads"]
    resources:
        mem_mb=int(config["padloc"]["memory"]),
        walltime=int(config["padloc"]["time"]),
        runtime=int(config["padloc"]["time"]),
    log:
        "log/padloc_benchmark/{dataset}.txt",
    benchmark:
        "log/benchmark/padloc_benchmark/{dataset}.txt"
    shell:
        r"""
find -L {input.dataset} -mindepth 1 -maxdepth 1 -type f -name "*.f*a" -print0 |\
 parallel -0 --jobs {threads} --retry-failed --halt='now,fail=1'\
 'mkdir -p "$(dirname {output})/{{/.}}" && padloc --data {input.db}\
  --cpu 1 --fna {{}} --outdir "$(dirname {output})/{{/.}}"' > {log} 2>&1

touch {output}
        """


rule concatenate_padloc_datasetes:
    input:
        "results/padloc_benchmark/{dataset}/complete",
    output:
        "results/padloc_benchmark/{dataset}-concatenated.csv",
    conda:
        "../envs/bash.yaml"
    threads: config["padloc"]["threads"]
    resources:
        mem_mb=int(config["default_job"]["memory"]),
        walltime=int(config["default_job"]["time"]),
        runtime=int(config["default_job"]["time"]),
    log:
        "log/padloc_benchmark/concatenate_padloc/{dataset}.txt",
    benchmark:
        "log/benchmark/padloc_benchmark/concatenate_padloc/{dataset}.txt"
    shell:
        r"""
file_array=( $(find $(dirname {input}) -mindepth 2 -maxdepth 2 -type f -name "*_padloc.csv") )
head -1 ${{file_array[0]}} > {output}
parallel --jobs {threads} --retry-failed --halt='now,fail=1'\
 'tail -n +2 {{}} >> {output}' ::: ${{file_array[@]}}
        """


rule concatenate_padloc_all:
    input:
        expand("results/padloc_benchmark/{dataset}-concatenated.csv", dataset=DATASETS),
    output:
        "results/padloc_benchmark/padloc_table.csv",
    conda:
        "../envs/bash.yaml"
    threads: 1
    resources:
        mem_mb=int(config["default_job"]["memory"]),
        walltime=int(config["default_job"]["time"]),
        runtime=int(config["default_job"]["time"]),
    log:
        "log/padloc_benchmark/concatenate_padloc_all.txt",
    benchmark:
        "log/benchmark/padloc_benchmark/concatenate_padloc_all.txt"
    shell:
        r"""
datasetes=( {input} )
echo "System_number,Contig,System,Protein" > {output}
for dataset in ${{datasetes[@]}}
do
    grep -e "^[0-9]*," ${{dataset}} | cut -f 1-3,4 -d ',' >> {output}
done
        """
