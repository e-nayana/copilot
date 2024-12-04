#!/bin/bash

if [ "$#" -ne 2 ]; then
    usage
fi

base_path=$1
repository_name=$2


csv_file="./service_reg.csv"


if [ ! -f "$csv_file" ]; then
    echo "CSV file not found in the current directory"
    exit 1
fi

# Extract the Application Tags for the given repository name
app_tags=$(awk -F, -v repo="$repository_name" 'BEGIN {IGNORECASE=1} {
    if ($1 == repo) {
        tag = $3;
        for (i = 4; i <= NF; i++) {
            tag = tag "," $i;
        }
        gsub(/"/, "", tag);
        print tag;
        exit;
    }
}' "$csv_file")


if [ -z "$app_tags" ]; then
    echo "No matching repository found in the CSV file"
    exit 1
fi


echo "Identified tags: ${app_tags}"


k8s_file="${base_path}/.kubernetes/patch/k8s.yml"
k8s_file_test="${base_path}/.kubernetes/patch/k8s-test.yml"


if [ ! -f "$k8s_file" ]; then
    echo "k8s.yml file not found at ${k8s_file}"
    exit 1
fi

if [ ! -f "$k8s_file_test" ]; then
    echo "k8s.yml file not found at ${k8s_file_test} and ignored"
fi


PROPERTY="applications.mybudget.com.au/tags"

# Check if the property exists in the file
if grep -q "$PROPERTY" "$k8s_file"; then
  echo "Property exists in the .yml file."
else
  echo "Property does not exist in the .yml file."
  exit 1
fi

# Update the annotations in the k8s.yml file
sed -i.bak -E "s#(applications\.mybudget\.com\.au/tags:).*#\1 ${app_tags}#" "$k8s_file"

if [ -f "$k8s_file_test" ]; then
    sed -i.bak -E "s#(applications\.mybudget\.com\.au/tags:).*#\1 ${app_tags}#" "$k8s_file_test"
fi


echo "Updated the annotations in ${k8s_file}"


rm -f "${k8s_file}.bak"
rm -f "${k8s_file_test}.bak"
