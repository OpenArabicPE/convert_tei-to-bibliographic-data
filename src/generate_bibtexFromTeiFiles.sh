#!/bin/bash
# change into the script directory
current_dir=$(dirname "${BASH_SOURCE[0]}")
cd $current_dir && pwd
# set a root directory for the repository, relative to this script
root_dir=".."
# set input directory relative to the root directory
input_dir="example-data/tei/dhd"
# path to XSLT stylesheet
xslt_file="xslt/convert_tei-to-bibtex_filedesc.xsl" #https://openarabicpe.github.io/convert_tei-to-bibliographic-data/
cd $root_dir # change into root directory
echo "Extract bibliographic data from all TEI/XML files in $input_dir directory and convert them to BibTeX"
for file in $input_dir/*.xml # iterate over all files in the input directory
do
    echo "Applying XSLT to $file"
    saxon -s:"$file" -xsl:$xslt_file \
    p_github-action=true \
    p_output-folder=''
done