#!/bin/bash

# List of files to process
FILES=(
  "../.github/actions/build-alpine/action.yml"
  "../.github/actions/build-alpine/entrypoint.sh"
  "../.github/workflows/alpine-cli.yml"
)

# Path to the output file
OUTPUT_FILE="./content_of_files.log"

# Clear the output file if it already exists
> "$OUTPUT_FILE"

# Loop through each file
for file in "${FILES[@]}"; do
  if [[ -f "$file" ]]; then
    FULL_PATH="$(realpath "$file")"
    {
      echo "[$FULL_PATH]"
      echo '```log'
      cat "$file"
      echo '```'
      echo    # empty line for separation
    } >> "$OUTPUT_FILE"
  else
    echo "Warning: File not found: $file" >&2
  fi
done

echo -e "\nContent written to: $OUTPUT_FILE\n"
