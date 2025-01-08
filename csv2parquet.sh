#! /bin/bash

# converts many pwalk output files to parquet using duckdb

# Check for required command
if ! command -v duckdb &> /dev/null; then
    echo "Error: duckdb command not found in PATH"
    echo "Please install duckdb or add it to your PATH"
    exit 1
fi

# Check if at least one argument is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <source_dir|files...> [destination_dir]"
    exit 1
fi

# Set source and destination
if [ $# -eq 1 ]; then
    SRC=$1
    DEST="."
else
    SRC=$1
    DEST="${@: -1}"
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

# Function to process a single file
process_file() {
    local FILE="$1"
    if [[ "$FILE" == *.csv ]]; then
        FILENAME=$(basename "$FILE")
        FILEBASE="${FILENAME%.*}"
        TEMP_FILE="${TEMP_DIR}/${FILENAME}"
        
        # Only process if parquet doesn't exist
        if ! [[ -f "${DEST}/${FILEBASE}.parquet" ]]; then
            echo "Processing ${FILENAME}..."
            
            # Convert to UTF-8 and optionally clean with sed
            printf "  Converting / cleaning ${FILEBASE} ... "
            iconv -f ISO-8859-1 -t UTF-8 "$FILE" > "${TEMP_FILE}"
            # Potentially replace strings in the path 
            #sed -E 's#/string1/#/#g; s#/string2/#/#g' > "$TEMP_FILE"
            echo "Done."
            
            # Convert to parquet
            printf "  Converting ${FILEBASE} to parquet... "
            if ! duckdb -s "${PRAGMAS} COPY (SELECT * FROM \
                read_csv_auto('${TEMP_FILE}', \
                ignore_errors=true, header=true)) TO \
                '${DEST}/${FILEBASE}.parquet' (FORMAT 'parquet');" 2>&1; then
                echo "Failed!"
                echo "Error converting ${FILENAME} to parquet"
                rm -f "$TEMP_FILE"
                return 1
            fi
            echo "Done."
            
            # Remove temporary file immediately
            rm -f "$TEMP_FILE"
        else
            echo "Skipping ${FILENAME} - parquet file already exists"
        fi
    fi
}

# Process files based on input type
if [ -d "$SRC" ]; then
    echo "Processing directory: $SRC"
    for FILE in "$SRC"/*.csv; do
        if [ -f "$FILE" ]; then  # Check if file exists (handles no matches)
            process_file "$FILE"
        fi
    done
else
    # Process individual files
    for FILE in "${@:1:$(($#-1))}"; do
        if [ -f "$FILE" ]; then
            process_file "$FILE"
        else
            echo "Error: '$FILE' does not exist or is not a file"
        fi
    done
fi

# Cleanup temporary directory if empty
rmdir "$TEMP_DIR" 2>/dev/null || true

echo "Conversion process completed!"
