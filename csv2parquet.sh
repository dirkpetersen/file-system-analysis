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
    echo "Usage: $0 <source_dir> [destination_dir]"
    exit 1
fi

# Set source and destination directories
SRC="$1"
if [ $# -eq 1 ]; then
    DEST="$1"
else
    DEST="$2"
fi

# Validate source directory exists
if [ ! -d "$SRC" ]; then
    echo "Error: Source directory '$SRC' does not exist"
    exit 1
fi

# Create destination directory if it doesn't exist
mkdir -p "$DEST"

# Create temporary directory in /dev/shm for current user
TEMP_DIR="/dev/shm/$USER"
mkdir -p "$TEMP_DIR"

# Set DuckDB pragmas
PRAGMAS=""

# Process files in a single loop
echo "Starting CSV to Parquet conversion process..."
echo "Source directory: $SRC"
echo "Destination directory: $DEST"

for FILE in "$SRC"/*.csv; do
    if [ -f "$FILE" ]; then
        FILENAME=$(basename "$FILE")
        FILEBASE="${FILENAME%.*}"
        TEMP_FILE="${TEMP_DIR}/${FILENAME}"
        
        # Only process if parquet doesn't exist
        if ! [ -f "${DEST}/${FILEBASE}.parquet" ]; then
            echo "Processing ${FILENAME}..."
            
            # Convert to UTF-8 and optionally clean with sed
            printf "  Converting / cleaning ${FILEBASE} ... "
            iconv -f ISO-8859-1 -t UTF-8 "$FILE" > "$TEMP_FILE"
            # Potentially replace strings in the path 
            #sed -E 's#/string1/#/#g; s#/string2/#/#g' > "$TEMP_FILE"
            echo "Done."
            
            # Convert to parquet
            printf "  Converting ${FILEBASE} to parquet... "
            duckdb -s "${PRAGMAS} COPY (SELECT * FROM \
                read_csv_auto('${TEMP_FILE}', \
                ignore_errors=true, header=true)) TO \
                '${DEST}/${FILEBASE}.parquet';"
            echo "Done."
            
            # Remove temporary file immediately
            rm -f "$TEMP_FILE"
        else
            echo "Skipping ${FILENAME} - parquet file already exists"
        fi
    fi
done

# Cleanup temporary directory if empty
rmdir "$TEMP_DIR" 2>/dev/null || true

echo "Conversion process completed!"
