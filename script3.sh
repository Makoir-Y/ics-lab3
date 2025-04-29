#!/bin/bash

if [ $# -ne 1 ]; then
    echo "Use the script like it: $0 /path/to/directory"
    exit 1
fi

dir="$1"
echo "Search in a given folder: $dir"

tempfile=$(mktemp)

find "$dir" -type f -print0 | xargs -0 md5sum | sort > "$tempfile"

duplicates=$(awk '{print $1}' "$tempfile" | uniq -d)

total_found=0
total_deleted=0

for hash in $duplicates; do
    mapfile -t files < <(grep "^$hash" "$tempfile" | cut -d' ' -f3- | sed 's/^ *//' | sort)

    echo "Duplicate files found:"
    for file in "${files[@]}"; do
        echo "$file"
    done

    read -p "Want to delete duplicates while keeping the oldest file? (y/n): " answer
    if [[ "$answer" == "y" ]]; then
        oldest_file="${files[0]}"
        for file in "${files[@]}"; do
            if [[ "$file" -ot "$oldest_file" ]]; then
                oldest_file="$file"
            fi
        done

        for file in "${files[@]}"; do
            if [[ "$file" != "$oldest_file" ]]; then
                rm -f "$file" && ((total_deleted++))
            fi
        done
        echo "Saved file: $oldest_file"
    fi
    ((total_found+=${#files[@]}))
done

echo "Count of all duplicates: $total_found"
echo "Count of deleted duplicates: $total_deleted"

rm -f "$tempfile"
