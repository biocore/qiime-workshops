# Basic commands

## Demultiplexing your sequence files and doing quality control on the sequences

```
split_libraries.py -m study_103_mapping_file.txt -f study_103.fna -q study_103.qual -o split_libraries/
```

Note that this was already performed for the workshop. You can download the necessary files for the next steps from ftp://thebeast.colorado.edu/pub/QIIME-workshop/isme15.tgz

## Picking OTU against a reference.

First we need to create a parameters file that forces reverse matching of the sequences

```
echo -e "pick_otus:enable_rev_strand_match\tTrue\npick_otus:max_accepts\t1\npick_otus:max_rejects\t8\npick_otus:stepwords\t8\npick_otus:word_length\t8" > pick_params.txt
```

Then run pick using that parameters file:

```
pick_open_reference_otus.py -i input/study_103_split_library_seqs.fna -r gg_13_8_otus/rep_set/97_otus.fasta -o ucrc_0.97 -aO 4 -p pick_params.txt --prefilter_percent_id 0.0
```

## Perform core diversity analysis

```
core_diversity_analyses.py -i ucrc_0.97/otu_table.biom -o core.300 -m inputs/study_103_mapping_file.txt -e 300 -t gg_13_8_otus/trees/97_otus.tree -a -O 4
```
