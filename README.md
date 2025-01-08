# File System Analysis

Analyze file metadata in your POSIX file systems

## Installing Tools


### Install PWalk to Gather Raw Data

```bash
git clone https://github.com/fizwit/filesystem-reporting-tools
cd filesystem-reporting-tools
gcc -pthread pwalk.c exclude.c fileProcess.c -o pwalk
cp pwalk ~/bin  # or ~/.local/bin
```

### Install DuckDB to Convert and Analyze Data 

```bash
cd ~/bin  # or ~/.local/bin
curl --fail --location --progress-bar --output duckdb_cli-linux-amd64.zip \
    https://github.com/duckdb/duckdb/releases/download/v1.1.3/duckdb_cli-linux-amd64.zip && \
    unzip duckdb_cli-linux-amd64.zip && \
    rm duckdb_cli-linux-amd64.zip
```

### Install Aider to generate SQL and code

```
curl -LsSf https://aider.chat/install.sh | sh
echo "export OPENAI_API_KEY=${OPENAI_API_KEY}" >> ~/.apikeys
echo "export ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}" >> ~/.apikeys
source ~/.apikeys
```

## Data Collection and Conversion

### Create CSV Files
Use PWalk to generate one CSV file per root folder:

```bash
pwalk --NoSnap --header /myfolder > output-file.csv
```

### Convert to Parquet Format
Place all CSV files in one folder and convert them to Parquet format:

```bash
./csv2parquet.sh <csv-folder>
```

## Analyze File System Data

### Using Existing Reports 

For testing, we'll use the sample data in the `testdata` folder containing PWalk output files. You can also use your own generated files.

```
$  ./csv2parquet.sh ./testdata
Starting CSV to Parquet conversion process...
Destination directory: /home/dp/gh/file-system-analysis/testdata
Processing directory: /home/dp/gh/file-system-analysis/testdata
Converting backups.csv to UTF-8... Done.
Converting backups.csv to backups.parquet ... Done.
Converting imagedata.csv to UTF-8... Done.
Converting imagedata.csv to imagedata.parquet ... Done.
Converting installers.csv to UTF-8... Done.
Converting installers.csv to installers.parquet ... Done.
Conversion process completed!
```

The key advantage of DuckDB is that it doesn't require importing files into a database. You can query Parquet files directly, for example:

```

duckdb -s "select count(*) from './testdata/*.parquet'"
┌──────────────┐
│ count_star() │
│    int64     │
├──────────────┤
│        35929 │
└──────────────┘
```

Let's try some of the pre-built SQL reports. The simplest is `file-extension-summary.sql`, which shows the size in GiB and percentage of total storage for each file type:

```
./report.sh ./testdata/ ./sql/file-extension-summary.sql 

fileExt,pct,GiB
vhdx,97.2,830.871
txt,1.3,11.265
jpg,0.7,6.053
pkg,0.3,2.815
dat,0.2,1.858
```

The `report.sh` script sets up an environment variable `PWALK_TABLE` (e.g., `export PWALK_TABLE="${PFOLDER}/*.parquet"`). This variable can point to a single file or use wildcards to include multiple files. Note that all files must share the same structure. The script uses `envsubst` to replace `${PWALK_TABLE}` in SQL files within the `sql/` directory.


To identify large folders that might be candidates for deletion or archival, use `hotspots-large-folders.sql`:

```
./report.sh ./testdata/ ./sql/hotspots-large-folders.sql | head -4

User,AccD,ModD,GiB,MiBAvg,Folder,Group,TiB,FileCount,DirSize
65534,531,531,57.086,3247.547,/home/dsimsb/groups/dcback/research.computing/Thursday/WindowsImageBackup/XXXXXXX/Backup 2023-07-27 081513,65534,0.056,18,61295395408
65534,533,533,57.074,3246.88,/home/dsimsb/groups/dcback/research.computing/Tuesday/WindowsImageBackup/XXXXXXX/Backup 2023-07-25 081513,65534,0.056,18,61282812496
65534,534,534,57.066,3246.436,/home/dsimsb/groups/dcback/research.computing/Monday/WindowsImageBackup/XXXXXXX/Backup 2023-07-24 081512,65534,0.056,18,61274423888
```

In the output, `AccD` shows the days since last access (e.g., 531 days for the 57 GiB folder), while `ModD` shows days since last modification.

### Design new reports 


