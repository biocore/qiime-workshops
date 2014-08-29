# Overview
In this tutorial we will work through the analysis of soil microbial community data using [QIIME 1.8.0](www.qiime.org) and [PICRUSt 1.0.0](picrust.github.io). In order to focus on QIIME's diversity analyses, we've already run all of the steps in the *Data preparation commands* section for you, and you can download the results [here](ftp://thebeast.colorado.edu/pub/QIIME-workshop/isme15.tgz). However, you can run those commands yourself if you'd like to experiment or gain experience with them.

# Data preparation commands

## Demultiplexing your sequence files and doing quality control on the sequences

```
export GGDIR=/home/ubuntu/qiime_software/gg_otus-13_8-release/
```

```
split_libraries.py -m study_103_mapping_file.txt -f study_103.fna -q study_103.qual -o slout/
```

Note that this was already performed for the workshop. You can download the necessary files for the next steps from ftp://thebeast.colorado.edu/pub/QIIME-workshop/isme15.tgz

## Picking OTU against a reference.

First we need to create a parameters file that forces reverse matching of the sequences, and which uses the *fast* uclust paramters. These parameter settings are the defaults in QIIME 1.8.0-dev and later, for the reasons discussed in [this paper](https://peerj.com/articles/545/).

```
echo -e "pick_otus:enable_rev_strand_match\tTrue\npick_otus:max_accepts\t1\npick_otus:max_rejects\t8\npick_otus:stepwords\t8\npick_otus:word_length\t8" > params.txt
```

Then run ``pick_open_reference_otus.py`` using that parameters file, and suppressing the pre-filtering step (also default in QIIME 1.8.0-dev):

```
pick_open_reference_otus.py -i slout/study_103_split_library_seqs.fna -r  $GGDIR/rep_set/97_otus.fasta -o ucrss -aO 4 -p params.txt --prefilter_percent_id 0.0
```

## Perform core diversity analysis

```
core_diversity_analyses.py -i ucrss/otu_table_mc2_w_tax_no_pynast_failures.biom -o cd_even300 -m map.txt -e 300 -t $GGDIR/trees/97_otus.tree -a -O 4
```

Add categorical analyses to completed ``core_diversity_analyses.py`` results:

```
core_diversity_analyses.py -i ucrss/otu_table_mc2_w_tax_no_pynast_failures.biom -o cd_even300 -m map.txt -e 300 -t $GGDIR/trees/97_otus.tree -a -O 4 --recover_from_failure -c CategoricalPH
```

# PICRUSt commands

```
cd ucrss
```

## Filter to just the Greengenes OTUs

```
filter_otus_from_otu_table.py -i otu_table_mc2_w_tax_no_pynast_failures.biom -o closed_reference_otu_table.biom --negate_ids_to_exclude -e $GG_TAXONOMY
```

## Normalize by 16S copy number

```
normalize_by_copy_number.py -i closed_reference_otu_table.biom -o closed_reference_otu_table_normed.biom
```

## Predict metagenomes

```
predict_metagenomes.py -i closed_reference_otu_table_normed.biom -o  predicted_metagenome.biom -a predicted_metagenome.acc.txt
```

## First quick pass on analyzing results

Using [data_hacks](https://github.com/bitly/data_hacks), we can take a quick peek at the quality of the prediction:

```bash
$ cut -f 3 predicted_metagenome.acc.txt | histogram.py
invalid line 'Value\n'
# NumSamples = 89; Min = 0.10; Max = 0.25
# Mean = 0.178570; Variance = 0.001080; SD = 0.032865; Median 0.177516
# each * represents a count of 1
    0.0964 -     0.1115 [     4]: ****
    0.1115 -     0.1266 [     1]: *
    0.1266 -     0.1416 [     4]: ****
    0.1416 -     0.1567 [    15]: ***************
    0.1567 -     0.1718 [    15]: ***************
    0.1718 -     0.1869 [    15]: ***************
    0.1869 -     0.2019 [    14]: **************
    0.2019 -     0.2170 [     9]: *********
    0.2170 -     0.2321 [     5]: *****
    0.2321 -     0.2472 [     7]: *******
```

```
categorize_by_function.py -i predicted_metagenome.biom -c "KEGG_Pathways" -l 2 -o predicted_metagenome_L2.biom
```

```
summarize_taxa_through_plots.py -i predicted_metagenome_L2.biom -p picrust_summarize_params.txt -o plots_at_level2
```

## Beta diversity

First, lets figure out what a reasonable rarefaction level is

biom summarize-table -i predicted_metagenome.biom -o predicted_metagenome.biom.stats

Now lets rarefy the table, compute beta diversity using Bray Curtis (as we do not have a phylogenetic tree to relate genes) and produce a PCoA plot.

```
single_rarefaction.py -d 229540 -i predicted_metagenome.biom -o predicted_metagenome_even229540.biom
```

```
beta_diversity.py -m bray_curtis -i predicted_metagenome_even229540.biom -o bdiv_bc
```

```
principal_coordinates.py -i bdiv_bc/bray_curtis_predicted_metagenome_even229540.txt -o bdiv_bc/bray_curtis_otu_predicted_metagenome_even229540_pc.txt
```

```
make_emperor.py -i bdiv_bc/bray_curtis_otu_predicted_metagenome_even229540_pc.txt -o bdiv_bc/emperor -m ../map.txt
```
