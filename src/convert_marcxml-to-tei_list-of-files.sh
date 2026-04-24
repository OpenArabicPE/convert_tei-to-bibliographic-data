#!/bin/bash
# the code for reading the input CSV was adapted from https://linuxsimply.com/bash-scripting-tutorial/input-output/input/read-csv/
# change into the script directory
current_dir=$(dirname "${BASH_SOURCE[0]}")
cd $current_dir && pwd
# path to XSLT stylesheet
XSLT="../xslt/convert_marc-xml-to-tei_file.xsl"
# path to CSV. Note that the IDs for the files should be in the first column
dirBase="/Users/Shared/BachUni/BachBibliothek/GitHub/Sihafa/sihafa_data/bibliographic-data/sources/nloi"
CSV="$dirBase/conversion_failure.csv"
# set output directory: use absolute paths or something relative to this script
dirIn="$dirBase/marcxml"
dirOut="$dirIn/_output"

# read CSV into an array
# tail -n +2: start reading from the second line
# cut -d ',' -f1: specify the delimiter and select the first column
# sed 's/"//g': remove the quotes from the content
IDs=( $(tail -n +2 $CSV | cut -d ',' -f1 | sed 's/"//g') )


# iterate over the array and do something
for ID in "${IDs[@]}"; do
    file="$ID.mrcx"
    echo "process $file"
    saxon -s:"$dirIn/$file" -xsl:$XSLT \
    p_stand-alone=false p_verbose=false p_debug=false \
    p_output-folder="$dirOut/"
done