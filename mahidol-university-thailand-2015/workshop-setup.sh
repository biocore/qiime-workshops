#!/usr/bin/env bash
set -ex
sudo mkdir -p --mode a+rwx /mnt/workshop/cli /mnt/temp
sed -i -e's?temp_dir\t.*$?temp_dir\t/mnt/temp/?' /qiime_software/qiime_config
cd /mnt/workshop
wget https://github.com/biocore/qiime-workshops/raw/master/mahidol-university-thailand-2015/commands/workshop-exercises.ipynb -O workshop-exercises.ipynb
