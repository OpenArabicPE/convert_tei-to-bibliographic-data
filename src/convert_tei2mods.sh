#!/bin/bash
# change into the script directory
current_dir=$(dirname "${BASH_SOURCE[0]}")
cd $current_dir && pwd
root_dir=".."
# set input directory relative to current directory
input_dir="example-data/tei/dhd"
# path to XSLT stylesheet
xslt_file="xslt/convert_tei-to-mods_filedesc.xsl"
cd $root_dir # change into root directory
echo "Extract bibliographic data from all TEI/XML files in $input_dir directory and convert them to MODS/XML"
for file in $input_dir/*.xml # iterate over all files in the input directory
do
    echo "Applying XSLT to $file"
    saxon -s:"$file" -xsl:$xslt_file p_github-action=true
done