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

Since writing SQL can be a bit tiresome if you don't do it every day, we want to use an LLM for. We put instructions (aka. System Prompt) for the LLM into the CONVENTIONS.md file. You can paste those into ChatGPT, Claude or another LLM along with your request and ask for it to design your sql query but it is more efficient to check out this repository and use `aider.chat`. 

```
git clone git@github.com:dirkpetersen/file-system-analysis.git
```

or if you have not configured your ssh key for Github yet 

```
git clone https://github.com/dirkpetersen/file-system-analysis.git
```

switch to the git repos and prepare your aider global settings by alias 

```
cd file-system-analysis
alias aider='aider --dark-mode --vim --cache-prompts'
```

Let's say you want to design a new SQL file that is stored in the `sql` subfolder. We want to get a list of duplicate files. This can be a complex problem but we would like to query for files that have the same file name and file size and are stored in different folders. Let's start our aider prompt with the CONVENTIONS.md file in read-only mode because we do not want aider to change it, this is what we get: 


```
aider --read CONVENTIONS.md sql/duplicates.sql
──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
Creating empty file /home/dp/gh/file-system-analysis/sql/duplicates.sql
Aider v0.70.0
Main model: claude-3-5-sonnet-20241022 with diff edit format, prompt cache, infinite output
Weak model: claude-3-5-haiku-20241022
Git repo: .git with 12 files
Repo-map: using 1024 tokens, files refresh
Added sql/duplicates.sql to the chat.
──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
Readonly: CONVENTIONS.md
Editable: sql/duplicates.sql
>

```

Now paste these instrunctions at the prompt 

```
Write a SQL query that finds all duplicate files across the entire file system. A duplicate is defined as a file that has the same filename stored in different folders and has the same size in both locations. To be clear: We are looking for multiple files with the same filename and size but stored in different folders.
```

but default we are getting a response from claude: 

```

I'll create a SQL query to find duplicate files based on filename and size across different folders. I'll follow the conventions
from CONVENTIONS.md, including using '${PWALK_TABLE}' and proper quoting of fields.

sql/duplicates.sql


 <<<<<<< SEARCH
 =======
 -- Find duplicate files (same filename and size) stored in different folders
 WITH file_info AS (
     SELECT
         substring(filename, length(filename) - strpos(reverse(filename), '/') + 2) AS file_name,
         filename AS full_path,
         st_size,
         pw_fcount
     FROM '${PWALK_TABLE}'
     WHERE pw_fcount = -1  -- Only include files, not directories
     AND st_size > 0      -- Exclude empty files
 )
 SELECT
     f1.file_name,
     f1.st_size,
     GROUP_CONCAT(f1.full_path, '\n') AS duplicate_locations,
     COUNT(*) AS occurrence_count
 FROM file_info f1
 GROUP BY f1.file_name, f1.st_size
 HAVING COUNT(*) > 1
 ORDER BY f1.st_size DESC, f1.file_name;
 >>>>>>> REPLACE


This query:

 1 Creates a CTE to extract just the filename (without path) and other relevant details
 2 Only includes actual files (pw_fcount = -1) and non-empty files
 3 Groups by filename and size to find duplicates
 4 Shows the full paths where duplicates are found using GROUP_CONCAT
 5 Orders results by size (largest first) and then filename
```

and testing this query, we get:

```
./report.sh ./testdata/ sql/duplicates.sql
file_name,st_size,duplicate_locations,occurrence_count
proof.msi,2109440,/home/dsimsb/groups/RDNFTS/Office/Office 2016 Professional/proofing.en-us/proof.fr/proof.msi\n/home/dsimsb/groups/RDNFTS/Office/Office 2016 Professional/proofing.en-us/proof.es/proof.msi,2
branding.xml,336313,/home/dsimsb/groups/RDNFTS/Office/Office 2016 Professional/office.en-us/branding.xml\n/home/dsimsb/groups/RDNFTS/Office/Office 2016 Professional/access.en-us/access.en-us/branding.xml,2
.DS_Store,6148,/home/dsimsb/groups/RDNFTS/.DS_Store\n/home/dsimsb/groups/RDNFTS/Tools/.DS_Store,2
setup.xml,1795,/home/dsimsb/groups/RDNFTS/Office/Office 2016 Professional/publisher.en-us/setup.xml\n/home/dsimsb/groups/RDNFTS/Office/Office 2016 Professional/infopath.en-us/setup.xml,2
proof.xml,1665,/home/dsimsb/groups/RDNFTS/Office/Office 2016 Professional/proofing.en-us/proof.fr/proof.xml\n/home/dsimsb/groups/RDNFTS/Office/Office 2016 Professional/proofing.en-us/proof.es/proof.xml,2
OHSURDNCert.p7b,1336,/home/dsimsb/groups/RDNFTS/Tools/certinstall/OHSURDNCert.p7b\n/home/dsimsb/groups/RDNFTS/Tools/certinstall2/certinstall/OHSURDNCert.p7b,2
certinstall.bat,82,/home/dsimsb/groups/RDNFTS/Tools/certinstall/certinstall.bat\n/home/dsimsb/groups/RDNFTS/Tools/certinstall2/certinstall/certinstall.bat,2
```

You can also force aider to use other models such as 

```
aider --4o --read CONVENTIONS.md sql/duplicates.sql
aider --o1 --read CONVENTIONS.md sql/duplicates.sql
aider --deepseek --read CONVENTIONS.md sql/duplicates.sql
```

but the latest Claude seems to be one of the most capable models as of early 2025 