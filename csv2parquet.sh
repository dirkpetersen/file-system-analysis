#! /bin/bash

# converts many pwalk output files to parquet using duckdb

# Check for required command
if ! command -v duckdb &> /dev/null; then
    echo "Error: duckdb command not found in PATH"
    echo "Please install duckdb or add it to your PATH"
    exit 1
fi

# Check arguments
if [ $# -eq 0 ] || [ $# -gt 2 ]; then
    echo "Usage: $0 <source_dir> [destination_dir]"
    exit 1
fi

# Set source and destination to absolute paths
SRC=$(realpath "$1")
DEST=$(realpath "${2:-.}")  # Use second arg if provided, otherwise use current directory

# Validate source is a directory
if [ ! -d "$SRC" ]; then
    echo "Error: '$SRC' is not a directory"
    exit 1
fi

# Create temporary directory in /dev/shm for current user
TEMP_DIR="/dev/shm/$USER"
mkdir -p "$TEMP_DIR"

# Create destination directory if it doesn't exist
mkdir -p "$DEST"

# Set DuckDB pragmas for better performance
PRAGMAS=""
#PRAGMAS="PRAGMA memory_limit='4GB'; PRAGMA threads=4;"

# Start process
echo "Starting CSV to Parquet conversion process..."
echo "Destination directory: $DEST"

# Process all files in directory
echo "Processing directory: $SRC"
for FILE in $(ls -1 ${SRC}); do
    FILEBASE="${FILE%.*}"
    if [[ "${FILE##*.}" == "csv" ]]; then
        if ! [[ -f "${SRC}/${FILEBASE}.parquet" ]]; then
            echo "Converting ${FILE} to ${FILEBASE}.parquet ... "
            duckdb -s "${PRAGMAS} COPY (SELECT * FROM \
                read_csv_auto('"${SRC}/${FILE}"', \
                ignore_errors=true, header=true)) TO \
                '"${SRC}/${FILEBASE}.parquet"';"
            echo "Done."
        fi
    fi
done

echo "Conversion process completed!"
