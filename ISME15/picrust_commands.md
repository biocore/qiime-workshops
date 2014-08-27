# PICRUSt commands

## Filter to just the Greengenes OTUs

`filter_otus_from_otu_table.py -i otu_table_mc2_w_tax.biom -o otu_table_mc2_w_tax_gg.biom --negate_ids_to_exclude -e $GG_TAXONOMY`

## Normalize by 16S copy number

`normalize_by_copy_number.py -i otu_table_mc2_w_tax_gg.biom -o otu_table_mc2_w_tax_gg_normed.biom`

## Predict metagenomes

`predict_metagenomes.py -i otu_table_mc2_w_tax_gg_normed.biom -o otu_table_mc2_w_tax_gg_pred.biom -a otu_table_mc2_w_tax_gg_pred.acc.txt`

## First quick pass on analyzing results

Using [data_hacks](https://github.com/bitly/data_hacks), we can take a quick peek at the quality of the prediction:

```bash
$ cut -f 3 otu_table_mc2_w_tax_gg_pred.acc.txt | histogram.py
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

`categorize_by_function.py -i otu_table_mc2_w_tax_gg_pred.biom -c "KEGG_Pathways" -l 2 -o otu_table_mc2_w_tax_gg_pred_L2.biom`

`summarize_taxa_through_plots.py -i otu_table_mc2_w_tax_gg_pred_L2.biom -p picrust_summarize_params.txt -o plots_at_level2`

## Beta diversity

First, lets figure out what a reasonable rarefaction level is

`biom summarize-table -i otu_table_mc2_w_tax_gg_pred.biom -o otu_table_mc2_w_tax_gg_pred.biom.stats`

Now lets rarefy the table, compute beta diversity using Bray Curtis (as we do not have a phylogenetic tree to relate genes) and produce a PCoA plot.

`single_rarefaction.py -d 229540 -i otu_table_mc2_w_tax_gg_pred.biom -o otu_table_mc2_w_tax_gg_pred_even229540.biom`

`beta_diversity.py -m bray_curtis -i otu_table_mc2_w_tax_gg_pred_even229540.biom -o bdiv_bc`

`principal_coordinates.py -i bdiv_bc/bray_curtis_otu_table_mc2_w_tax_gg_pred_even229540.txt -o bdiv_bc/bray_curtis_otu_table_mc2_w_tax_gg_pred_even229540_pc.txt`

`make_emperor.py -i bdiv_bc/bray_curtis_otu_table_mc2_w_tax_gg_pred_even229540_pc.txt -o bdiv_bc/bray_curtis_otu_table_mc2_w_tax_gg_pred_even229540_emp -m ../input/study_103_mapping_file.txt`
