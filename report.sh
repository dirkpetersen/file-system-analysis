#! /bin/bash

PFOLDER=$1
SQLFILE=$2

export PWALK_TABLE="${PFOLDER}/*.parquet"

duckdb --csv < <(envsubst < ${SQLFILE})

