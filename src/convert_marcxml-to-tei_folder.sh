#!/bin/bash
# change into the script directory
current_dir=$(dirname "${BASH_SOURCE[0]}")
cd $current_dir && pwd
# set a root directory for the repository, relative to this script
root_dir=".."
# set input directory relative to current directory
input_dir="$root_dir/example-data/MARC"
output_dir=$input_dir
# path to XSLT stylesheet relativ to this script
xslt_file="$current_dir/../xslt/convert_marc-xml-to-tei_file.xsl"
#cd $root_dir # change into root directory
echo "Convert all MARC/XML files in $input_dir directory and convert them to TEI/XML"
for file in $input_dir/*.mrcx # iterate over all files in the input directory
do
    echo "Applying XSLT to $file"
    saxon -s:"$file" -xsl:$xslt_file \
    -warnings:"silent" \
    p_stand-alone=false \
    p_verbose=false p_debug=true \
    p_ignore-existing-files=true \
    p_output-folder="$output_dir/_output/"
    echo "~~~~~~"
done