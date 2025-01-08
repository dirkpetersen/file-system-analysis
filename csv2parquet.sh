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
    DEST="."
else
    # If last argument is a directory, use it as destination
    if [ -d "${!#}" ]; then
        DEST="${!#}"
        # Remove last argument from $@
        set -- "${@:1:$(($#-1))}"
    else
        DEST="."
    fi
fi

# Create temporary directory in /dev/shm for current user
TEMP_DIR="/dev/shm/$USER"
mkdir -p "$TEMP_DIR"

# Create destination directory if it doesn't exist
mkdir -p "$DEST"

# Validate inputs exist
for SRC in "$@"; do
    if [ ! -e "$SRC" ]; then
        echo "Error: '$SRC' does not exist"
        exit 1
    fi
done

# Set DuckDB pragmas
PRAGMAS=""

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
        if ! [ -f "${DEST}/${FILEBASE}.parquet" ]; then
            echo "Processing ${FILENAME}..."
            
            # Convert to UTF-8 and optionally clean with sed
            printf "  Converting / cleaning ${FILEBASE} ... "
            iconv -f ISO-8859-1 -t UTF-8 "$FILE" > "${TEMP_FILE}"
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
}

if [ -d "$1" ]; then
    echo "Processing directory: $1"
    for FILE in "$1"/*.csv; do
        process_file "$FILE"
    done
else
    for FILE in "$@"; do
        process_file "$FILE"
    done
fi



# Cleanup temporary directory if empty
rmdir "$TEMP_DIR" 2>/dev/null || true

echo "Conversion process completed!"
