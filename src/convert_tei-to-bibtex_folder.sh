#!/bin/bash
# change into the script directory
current_dir=$(dirname "${BASH_SOURCE[0]}")
# set a root directory for the repository, relative to this script
root_dir="$current_dir/.."
cd $root_dir && pwd # change into root directory
# set input directory
read -p "Please enter path to folder with TEI/XML files: " -r input_dir
# set output relative to input
output_dir="$input_dir/_output/"
# path to XSLT stylesheet
xslt_dir="$root_dir/xslt"
xslt_file="$xslt_dir/convert_tei-to-bibtex_bibl.xsl"

echo "Convert tei:bibl and tei:biblStruct from TEI/XML files in $input_dir to BibTeX"
for file in $input_dir/*.xml # iterate over all files in the input directory
do
    echo "Applying XSLT to $file"
    saxon -s:"$file" -xsl:$xslt_file \
    p_mods-simple-persnames=true \
    p_github-action=true \
    p_verbose=true \
    p_debug=false \
    p_output-folder="$output_dir"
done