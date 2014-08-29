# Overview
In this tutorial we will work through the analysis of soil microbial community data using [QIIME 1.8.0](http://www.qiime.org) and [PICRUSt 1.0.0](http://picrust.github.io). In order to focus on QIIME's diversity analyses, we've already run all of the steps in the *Data preparation commands* section for you, and you can download the results [here](ftp://thebeast.colorado.edu/pub/QIIME-workshop/isme15.tgz). However, you can run those commands yourself if you'd like to experiment or gain experience with them.

The data used in this workshop were originally published in [Lauber et al. 2009](http://www.ncbi.nlm.nih.gov/pubmed/19502440).

# Setup: we'll work through these steps together

For the hands-on components of this workshop, you'll be working on one of four Amazon Web Services (AWS) instances. The addresses for these are:
 1. ``ec2-23-23-12-228.compute-1.amazonaws.com``
 2. ``ec2-54-166-179-4.compute-1.amazonaws.com``
 3. ``ec2-54-166-205-154.compute-1.amazonaws.com``
 4. ``ec2-54-227-172-8.compute-1.amazonaws.com``

During the workshop, we'll distrubte a key for connecting to these instances called ``qiime_isme15.pem``. To connect to the fourth of these instances, you'd run:

```
chmod 400 qiime_isme15.pem
ssh -i qiime_isme15.pem ubuntu@ec2-54-227-172-8.compute-1.amazonaws.com
```

After logging in to an instance, you'll need to download the data that we're going to work with during the workshop to a personal directory. To do this, you should run:

```
mkdir <your-name>
cd <your-name>
wget ftp://thebeast.colorado.edu/pub/QIIME-workshop/isme15.tgz
tar -xzf isme15.tgz
cd isme15
```

We'll use Cyberduck to transfer files back and forth between our instances and local machines. You can find our notes on working with [Cyberduck here](http://qiime.org/tutorials/working_with_aws.html#working-with-cyberduck).

# Data preparation commands

## Demultiplexing your sequence files and doing quality control on the sequences

```
export GGDIR=/home/ubuntu/qiime_software/gg_otus-13_8-release/
export PICRUSTDIR=/home/ubuntu/qiime_software/picrust-data/
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
filter_otus_from_otu_table.py -i otu_table_mc2_w_tax_no_pynast_failures.biom -o closed_reference_otu_table.biom --negate_ids_to_exclude -e $GGDIR/taxonomy/97_otu_taxonomy.txt
```

## Normalize by 16S copy number

```
normalize_by_copy_number.py -i closed_reference_otu_table.biom -o closed_reference_otu_table_normed.biom -c $PICRUSTDIR/16S_13_5_precalculated.tab.gz
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

# Advanced processing steps

## Sorting and re-plotting OTU tables:

* Sort OTU table by PH
```
sort_otu_table.py -i cd_even300/table_mc300.biom -o table.PH_sorted.biom -m map.txt -s PH
```
* Taxa summary plots on the sorted table
```
summarize_taxa_through_plots.py -i table.PH_sorted.biom -o taxa.PH_sorted
```
## Procrustes analyses:

* Get rid of samples with less than 200 sequences
```
filter_samples_from_otu_table.py -i ucrss/otu_table_mc2_w_tax_no_pynast_failures.biom -o table_mc200.biom -n 200
```
* Rarefy at 200 seqs/sample
```
single_rarefaction.py -i table_mc200.biom -o table_even200.biom -d 200
```
* Perform beta diversity
```
beta_diversity_through_plots.py -i table_even200.biom -o bdiv_even200/ -m map.txt -t /home/ubuntu/qiime_software/gg_otus-13_8-release//trees/97_otus.tree
```
* Transform coordinates
```
transform_coordinate_matrices.py -i bdiv_even200/unweighted_unifrac_pc.txt,cd_even300/bdiv_even300/unweighted_unifrac_pc.txt -r 100 -o procrustes
```
* Plot
```
make_emperor.py -i procrustes/ -o procrustes/plots/ -m map.txt -c
```

## Supervised learning

* Multiple rarefactions
```
multiple_rarefactions_even_depth.py -i cd_even300/table_mc300.biom -o mul_rar.300/ -d 300
```
* Supervised learning on rarefied tables
```
supervised_learning.py -i mul_rar.300/ -m map.txt -c ENV_FEATURE -o sup_learn -w sup_learn/collated_results.txt -e cv5
```
