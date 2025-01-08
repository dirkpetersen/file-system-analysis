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



