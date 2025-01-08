#! /bin/bash

SQLFILE=$1
PFOLDER=$2

export PWALK_TABLE="${PFOLDER}/*.parquet"

duckdb < <(envsubst < ${SQLFILE})

