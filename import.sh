#!/bin/bash
set -eux

DATA_PATH=${2:-/opt/aoc_sql}
DATA_FILE=${3:-data.txt}

DB_NAME="aoc${1}"

createdb $DB_NAME || true
psql -c "CREATE TABLE IF NOT EXISTS input (id SERIAL, line TEXT);" $DB_NAME
psql -c "COPY input(line) FROM '${DATA_PATH}/${1}/${DATA_FILE}'" $DB_NAME
