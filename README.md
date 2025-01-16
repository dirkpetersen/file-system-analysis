# File System Analysis

Analyze file metadata in your POSIX file systems 

- [File System Analysis](#file-system-analysis)
  - [Installing Tools](#installing-tools)
    - [Install PWalk to Gather Raw Data](#install-pwalk-to-gather-raw-data)
    - [Install DuckDB to Convert and Analyze Data](#install-duckdb-to-convert-and-analyze-data)
    - [Install Aider to generate SQL and code](#install-aider-to-generate-sql-and-code)
  - [Data Collection and Conversion](#data-collection-and-conversion)
    - [Create CSV Files](#create-csv-files)
    - [Convert to Parquet Format](#convert-to-parquet-format)
  - [Analyze File System Data](#analyze-file-system-data)
    - [Using Existing Reports](#using-existing-reports)
    - [Using user and group names instead of uid and gid](#using-user-and-group-names-instead-of-uid-and-gid)
    - [Design new reports](#design-new-reports)


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

If you do not have OpenAI or Anthropic API keys you can also use AWS Bedrock (Your AWS account manager must assingn you the role `AWSBedrockFullAccess` and must also request once access to each of the models in the AWS console)

## Data Collection and Conversion

### Create CSV Files
Run PWalk as root to generate one CSV file per root folder:

```bash
sudo pwalk --NoSnap --header /myfolder > output-file.csv
```

### Convert to Parquet Format
Place all CSV files in one folder and convert them to Parquet format:

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

## Analyze File System Data


### Using Existing Reports 

For testing, we'll use the sample data in the `testdata` folder 

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

You can also merge all the parquet files into a single file 

```sql
duckdb -s "COPY (SELECT * FROM read_parquet('./testdata/*.parquet')) TO 'output_merged.parquet' (FORMAT PARQUET);"
```

This has perhaps 2 disadvantages: 

- **Difficulty querying a subset of files**: When dealing with a large number of files, creating a subset becomes more challenging. A practical workaround is to create a new folder, add symbolic links to the desired subset of files, and point DuckDB to this folder containing the symlinks.

- **Performance considerations with many files**: Using multiple smaller files can often be faster because DuckDB can more effectively parallelize the I/O operations across them.


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

### Using user and group names instead of uid and gid 

File systems store user and group information as numeric IDs (UIDs and GIDs) in their metadata rather than human-readable names. While PWalk maintains this numeric format for performance reasons, we can create a mapping to the actual user and group names in a post-processing step.
Let's first extract all unique UIDs and GIDs (`distinct`) found in our file system scan by running these commands, which will create two separate CSV files:

```
duckdb --csv -s "SELECT DISTINCT UID FROM './testdata/*.parquet';" > uids.csv
duckdb --csv -s "SELECT DISTINCT GID FROM './testdata/*.parquet';" > gids.csv
```

Then you use `mk-users-groups-csv.py` to create a `users.csv` and a `groups.csv` file. When you encounter an 'Unknown' UID or GID in the results, it indicates one of several potential scenarios:

- The user or group account has been deleted from your AIM system, but files owned by them still exist
- The files were transferred from another system where these UIDs/GIDs were valid
- The user/group was never properly set up in your AIM system

```
./mk-users-groups-csv.py
.
.
Processed UID: 109, User: Unknown
Processed UID: 105, User: Unknown
Processed UID: 116, User: Unknown
```

Now let's try the `orphaned.sql` query that uses sql `left joins` to link with users.csv and group.csv. It will show files and folders where either the user or the group is 'Unknown'. You can also modify the query to return files where both the User and the Group are unknown.

```
./report.sh ./testdata/ ./sql/orphaned.sql | head -4

User,UID,Group,GID,ModTime,filename
nobody,65534,Unknown,100113,2022-05-16 17:10:39,/home/dsimsb/groups/derm_image_data/Raidshare2/IPTC2021
nobody,65534,Unknown,100113,2022-05-09 13:38:25,/home/dsimsb/groups/derm_image_data/Raidshare2/Merlin
nobody,65534,Unknown,100113,2022-05-09 13:38:08,/home/dsimsb/groups/derm_image_data/Raidshare2/IPTCX
```

The query also uses the the COALESCE function that replaces a NULL value with a predetermined value 'Unknown'. You also see that you can easily combine Parquet files with CSV files in a single query.

### Design new reports 

Writing SQL can feel daunting if it’s not something you do regularly. To make the process easier, we use a Large Language Model (LLM). The instructions for the LLM, also known as the system prompt, are stored in the CONVENTIONS.md file. You can copy these instructions and use them with tools like ChatGPT, Claude, or other LLMs to help design your SQL query. However, a more efficient approach is to check out this git repository and use the `aider.chat` tool directly:

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
alias aider='aider --cache-prompts --dark-mode --vim --multiline'
```

Let's say you want to create a new query using a SQL file located in the sql subfolder. Your goal is to identify duplicate files. While this can be a complex task, we’ll simplify it by focusing on files that share the same name and size, even though they are stored in different directories.
To begin, let’s prompt Aider with the `CONVENTIONS.md` file in read-only mode, ensuring it remains unchanged. Here's the aider console we get: 


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

Now paste these instructions at the prompt:

```
Write a SQL query that finds all duplicate files across the entire file system. A duplicate is defined as a file that has the same filename stored in different folders and has the same size in both locations. To be clear: We are looking for multiple files with the same filename and size but stored in different folders.
```

by default we are getting a response from claude: 

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
./report.sh ./testdata/ sql/duplicates.sql | head -4
file_name,st_size,duplicate_locations,occurrence_count
proof.msi,2109440,/home/dsimsb/groups/RDNFTS/Office/Office 2016 Professional/proofing.en-us/proof.fr/proof.msi\n/home/dsimsb/groups/RDNFTS/Office/Office 2016 Professional/proofing.en-us/proof.es/proof.msi,2
branding.xml,336313,/home/dsimsb/groups/RDNFTS/Office/Office 2016 Professional/office.en-us/branding.xml\n/home/dsimsb/groups/RDNFTS/Office/Office 2016 Professional/access.en-us/access.en-us/branding.xml,2
.DS_Store,6148,/home/dsimsb/groups/RDNFTS/.DS_Store\n/home/dsimsb/groups/RDNFTS/Tools/.DS_Store,2
```

You can also force aider to use other models such as 

```
aider --4o --read CONVENTIONS.md sql/duplicates.sql
aider --o1 --read CONVENTIONS.md sql/duplicates.sql
aider --deepseek --read CONVENTIONS.md sql/duplicates.sql
```

but the latest Anthropic Claude seems to be one of the most capable models as of early 2025 and `aider.chat` uses it by default. To use Claude through AWS you launch it like this: 

```
aider --model bedrock/us.anthropic.claude-3-5-sonnet-20241022-v2:0 --read CONVENTIONS.md sql/duplicates.sql
```