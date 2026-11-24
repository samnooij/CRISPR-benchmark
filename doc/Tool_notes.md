# Tools notes

## CRISPRCasFinder

### Warnings for end-users

- CRISPRCasFinder was installed using pixi and run through the Perl script
present in the GitHub repository.
- CRISPRCasFinder writes intermediate files to its working directory,
so to prevent mixing up of files it is easier to run it from the intended
output directory.
- CRISPRCasFinder allows the user to set the number of CPU threads for
subcommands Prokka and MacSyFinder. It also runs MUSCLE, which may not
be limited by the tool and use all the CPU threads and RAM it detects
on the machine.
- CRISPRCasFinder may not like to run in parallel using the same script
and working directory: run one process at at time(?)

### Recommended parameters, cut-offs

By default, CRISPRCasFinder detects arrays with one or more spacers
(`-minNbSpacer 1`), where the length of repeats is between 23-55
(`-minDR 23 -maxDR 55`), and the length of spacers is between 25-60
(`-minSP 25 -maxSP 60`).

CRISPRCasFinder reports CRISPR-Cas systems with evidence levels 1-4.

- level 1: "short candidate arrays: 1-3 spacers (...) may in fact be real CRISPRs"
- level 2-4: "based on combined degrees of similarity of repeats and spacers"
- levels 3-4: "highly likely candidates"

(Quotes from [2018 CRISPRCasFinder publication](https://doi.org/10.1093/nar/gky425))

No strict cut-offs are mentioned, so we will include all evidence levels.

## PADLOC

- PADLOC depends on predicted ORFs by Prodigal, which requires input sequences
of at least 100kb in length. Therefore, subsets were made of each dataset that
contain shorter sequences, so that the tool may successfully finish.
- PADLOC did not run well on concatenated input files, so it was run using
separate FASTA files for each input contig/genome.

## CRISPRClassify

### Warnings for end-users

- Installation of CRISPRclassify requires a particular combination of R, R
packages and Java. I managed to install it with pixi using
`r==4.1 r-devtools = ">=2.4.4,<3" r-xgboost = ">=1.6.2,<2"`.
- Then, I started an interactive R session to install `dplyr` and `rlang`,
while _not_ updating all other packages.
- Next, I needed to restart my R session to load newer versions of `rlang` and `dplyr`.
- Finally, I installed CRISPRclassify using `github_install("CRISPRlab/CRISPRclassify")`
- For Java, I used 'openjdk 25.0.5 2026-10-20', installed system-wide using Fedora's `dnf`

### Recommended parameters, cut-offs

Only classifications with probability >=0.85 are taken into account,
like the authors describe in their paper and is written on GitHub.
("Predictions are considered optimal when the probability is 0.85 or higher.")

## CRISPRidentify

### Recommended parameters, cut-offs

CRISPRidentify gives each hit a score and label. Only 'bona fide' CRISPR
arrays (score >= 0.75) are taken into account for this benchmark.
(As authors describe in manuscript and briefly note on GitHub.)

## CRISPRDetect

### Warnings for end-users

- To find Cas genes, CRISPRDetect uses third party tools 'hmmsearch' and
'gmhmmp.pl', which should be downloaded separately. `hmmsearch` is included
with HMMer and can be installed through conda.
gmhmmp.pl, however, should be downloaded separately from the GeneMarks
package, which can be found through <https://exon.gatech.edu/license_download.cgi>.
As of 2026-11-10, the instructions are:
  - Download 'GeneMarkS v.4.30' for LINUX 64
  - extract the tarball `genemark_suite_linux_64.tar.gz`
  - locate the script `genemark_suite_linux_64/gmsuite/gmhmmp.pl`
    and move add it to your path (for example by adding it to the bin directory
    of conda environment `crisprdetect`)
  - `gmhmpp` (without extension) is also required for full functionality
  - extract the licence key `gm_key` from the separate archive and move
  it to your home directory: `~/.gm_key`

(_CRISPRDetect will run without GeneMarks and only identicy CRISPR arrays, not Cas genes._)

- When using Snakemake:
  - CRISPRDetect seems to create output files even when the program fails to run: therefore, Snakemake assumes the job finished and will happily continue. This requires manual checking!

### Recommended parameters, cut-offs

In the tool help function, it is written that a quality cutoff of 4 is standard for annotated GenBank files with cas1 and cas2 information.
A cut-off of 3 is "generally appropriate for contigs/fasta files."

We stick with the quality cut-off 3, and include all hits with score >=3.

## DefenseFinder

### Warnings for end-users

Installing DefenseFinder may require some extra setup, as noted on GitHub:
<https://github.com/mdmparis/defense-finder/issues/96#issuecomment-4377670855>
The recommended install method is listed as:

```bash
conda create --name defensefinder python=3.12 pip hmmer -c bioconda # install also hmmer in the environment
conda activate defensefinder
pip install mdmparis-defense-finder
defense-finder update
```

Defense-Finder may use too much memory when running on the complete 'positive'
dataset (>200GB). In our test, the process was killed and needed to be split
in separate input files.

## CRISPRdisco

### Warnings for end-users

- The installation with Docker is a bit of a hassle. Installation with
mamba and pip works okay.

```bash
pip install git/CRISPRdisco
```

- The tool expects for each input file to find a nucleotide (fna) and
amino acid (faa) sequence file.
- The tool expects the input file to be a single genome; the output files
do not list which contigs/sequence IDs contain the identified CRISRP arrays.
  - Therefore, CRISPRdisco cannot (practically) analyse metagenomes and
  needs to work on separate (genome) input files
