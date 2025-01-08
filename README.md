# file-system-analysis

Learn details about the file metadata in your Posix file systems

## Installing Tools


### Install Pwalk to gather raw data

```
git clone https://github.com/fizwit/filesystem-reporting-tools
cd filesystem-reporting-tools
gcc -pthread pwalk.c exclude.c fileProcess.c -o pwalk
cp pwalk ~/bin # or cp pwalk ~/.local/bin
```

### Install Duckdb to convert and analyse data 

```
cd ~/bin # or cd ~/.local/bin
curl --fail --location --progress-bar --output duckdb_cli-linux-amd64.zip https://github.com/duckdb/duckdb/releases/download/v1.1.3/duckdb_cli-linux-amd64.zip && unzip duckdb_cli-linux-amd64.zip && rm duckdb_cli-linux-amd64.zip
```

### Install Aider to generate SQL and code

```
curl -LsSf https://aider.chat/install.sh | sh
echo "export OPENAI_API_KEY=${OPENAI_API_KEY}" >> ~/.apikeys
echo "export ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}" >> ~/.apikeys
source ~/.apikeys
```

## Getting and converting data 

 
create CSV files using pwalk, one per root folder  

```
pwalk --NoSnap --header /myfolder > output-file.csv
```

put all csv files in one folder and convert them to Parquet 

```
./csv2parquet.sh <csv-folder>
```

## Analyse file system data 


### Use existing reports 

For our tests we will run against the testdata folder that has some pwalk output files, you cna also use the files you might have already created. 

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

The most important DuckDB feature to understand is that you do not need to import all files into a single DB for analysis, you can simply run something like a data count against all parquet files in the test folder: 

```

duckdb -s "select count(*) from './testdata/*.parquet'"
┌──────────────┐
│ count_star() │
│    int64     │
├──────────────┤
│        35929 │
└──────────────┘
```

Now let's take some of the pre-canned SQL reports and try them. The easiest one is file-extension-summary.sql which will test us how many GiB each of our file types has and what percentage of the total that is:

```
./report.sh ./testdata/ ./sql/file-extension-summary.sql 

fileExt,pct,GiB
vhdx,97.2,830.871
txt,1.3,11.265
jpg,0.7,6.053
pkg,0.3,2.815
dat,0.2,1.858
```

If you check the `report.sh` script, you can see that we created an environment variable `PWALK_TABLE`, e.g. `export PWALK_TABLE="${PFOLDER}/*.parquet"`. This environment variable can be set to a single file or to a wildcard representing many files. All files need to have the same data structure. Then we use the envsubst command to replace the variable ${PWALK_TABLE} in each of the SQL files in the sql/ sub folder.


Now let's see who has some huge amount of data that can be deleted or archived, for this we try the hotspots-large-folders.sql. 

```
./report.sh ./testdata/ ./sql/hotspots-large-folders.sql | head -4

User,AccD,ModD,GiB,MiBAvg,Folder,Group,TiB,FileCount,DirSize
65534,531,531,57.086,3247.547,/home/dsimsb/groups/dcback/research.computing/Thursday/WindowsImageBackup/XXXXXXX/Backup 2023-07-27 081513,65534,0.056,18,61295395408
65534,533,533,57.074,3246.88,/home/dsimsb/groups/dcback/research.computing/Tuesday/WindowsImageBackup/XXXXXXX/Backup 2023-07-25 081513,65534,0.056,18,61282812496
65534,534,534,57.066,3246.436,/home/dsimsb/groups/dcback/research.computing/Monday/WindowsImageBackup/XXXXXXX/Backup 2023-07-24 081512,65534,0.056,18,61274423888
```

AccD in the first line means this data (57 GiB) has not been accessed or modified (ModD) in 531 days. 

### Design new reports 


