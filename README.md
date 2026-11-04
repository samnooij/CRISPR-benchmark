# CRISPR-Cas benchmark

A benchmark of bioinformatics tools for the identification of CRISPR-Cas defence systems
in genome sequences of prokaryotes.

## Index

1. [Tools tested](#tools-to-test)
2. [Datasets](#datasets)
  - [CCTyper](#cctyper)
  - [Campylobacter](#campylobacter)
  - [CRISPR-negative](#crispr-negative-genomes)
  - [Single spacer arrays](#single-crispr-spacer)
  - [Type II-C](#type-ii-c)
3. [Licence](#licence)
4. [Citation](#citation)

## Tools to test

For the test, we include tools that take genomes as input
(FASTA files with draft/complete genome sequences), and identify
CRISPR and/or Cas sequences as output.
Tools we propose to include are:

- [x] CCTyper (version 1.8.0 (old) and 1.9.0+ (faster))
- [ ] CRISPRidentify (adapted v1.2.1)
- [x] CRISPRDetect (no license, Otago NZ - try installing first, ask for licence if it works;
  install dependencies with mamba, download GeneMarkS from exon.gatech.edu)
- [x] CRISPRCasFinder (install dependencies through Pixi; use Perl script from GitHub)
- [x] CRISPRclassify (no license, North Carolina State U  - Rodolphe Barrangou emailed permission on 7 April 2026)
- [x] PADLOC
- [x] DefenseFinder
- [ ] CRISPRdisco
- [x] CCTK (CRISPR Comparison Toolkit)
- [ ] CRISPRCasStack (no license, Harbin CN - try installing first)
- [ ] EVO2?
- [x] CRISPRscape

(Checked boxes indicates successful installation.)

## Datasets

### CCTyper

In the publication of CRISPRCasTyper (DOI:
[10.1101/2020.05.15.097824](https://doi.org/10.1101/2020.05.15.097824)),
two publications are referenced containing manually curated genomes with
CRISPR-Cas arrays. These are: Makarova et al. 2020 (DOI:
[10.1038/s41579-019-0299-x](https://doi.org/10.1038/s41579-019-0299-x)),
and Pinilla-Redondo et al. 2020 (DOI:
[10.1093/nar/gkz1197](https://doi.org/10.1093/nar/gkz1197)).

This set contains 31 subtypes/variants.

The Pinilla-Redondo set contains the new type IV arrays,
in a total of 807 genomes. (This set has 883 CRISPR loci:
genomes may have up to 3 loci.)

The Makarova set contains 4,911 genomes with 6,127 CRISPR loci.
(The highest number of annotated CRISPR subtypes per genome is 6!)

Together, these contain 5,717 unique genomes with 7,010 CRISPR loci.
Of these, 5,680 were successfully downloaded using `ncbi-datasets datasets download`.
That means 37 genomes were not downloaded.

These **5,680 genomes** represent 6,953 / 7,010 loci (99.2%).

### Campylobacter

Besides curated genomes, we also include a 'real-world test' dataset
using genomes from our species of interest: _Campylobacter jejuni/coli_.
This includes a random subset of **5,000 genomes** from the AllTheBacteria
assemblies (mixed _Campylobacter coli_ n = 1,374 and _C. jejuni_ n = 3,626).
(This number has been selected to be in the same order of magnitude as the
'[CCTyper](#cctyper)' or Makarova 2019/Pinilla-Redondo 2020 dataset.)

To do:

- compare genomes with ANI: create heatmap/dendrogram

### CRISPR negative genomes

As a negative control dataset, we have collected curated genomes from the
[CRISPRCasdb](https://crisprcas.i2bc.paris-saclay.fr/MainDb/StrainList)
database that have no known CRISPR arrays. That allows us to calculate
the true negative rate (TNR) of tools.
This dataset contains 1,000 genomes randomly selected on 4 August 2026.

### Single CRISPR spacer

CRISPR arrays may have only a single CRISPR spacer, which could still
be relevant for your research question. Bioinformatics tools such as
CCTyper and CRISPRidentify set the detection threshold at 2 or more spacers
to limit the number of false positive detections. To test the sensitivity
of CRISPR detection tools for genomes with a single CRISPR spacer, we
have selected genomes from CRISPRCasdb that have only one CRISPR spacer.

This dataset contains **61 genome sequences** (59 chromosomes and 2 plasmids).

### Type II-C

_Campylobacter_ contains primarily subtype II-C CRISPR-Cas. Hence, we
have a special interest in this subtype. In two studies dedicated to
CRISPR subtype II-C,
([Liao2022](https://doi.org/10.1038/s41564-022-01074-3) and
[Fuessner2025](https://doi.org/10.1093/femsml/uqaf007)),
the authors describe a dataset with **643 sequences** of
organisms containing a type II-C CRISPR-Cas system. These comprise
complete genomes as well as separate contigs frmo short-read, shotgun
sequenced isolates. As such, the length of these sequences is variable.
Within this dataset are 97 sequences that are also part of the 'CCTyper'
dataset; 546 are novel.
This dataset is used as an extra sensitivity test for type II-C.

## Subsets

Some of the datasets contain sequences that are too short to reliably
predict gene (open reading frames) with Prodigal (< 100kb). Therefore,
tools such as PADLOC cannot successfully analyse them. To enable their
analysis anyway, we have made subsets of those datasets that contain
only the sequences that are longer than 100kb. That is, one (1) sequence
is removed from the 'single CRISPR spacer' set, and 166 from the II-C
dataset (leaving 477 sequences longer than 100kb, of which 97 are
part of the 'Makarova2019' or 'CCTyper' dataset, 380 are not).

## Licence

This project is licensed under the [BSD 3-clause licence](LICENSE).

## Citation

To cite this project, please see its [citation file](CITATION.cff).
