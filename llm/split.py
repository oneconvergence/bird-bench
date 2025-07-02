#!/usr/bin/env python3
"""
Usage:
  python split.py [--input /path/to/dev.sql] [--output /path/to/db_splits] [--postgres]

If --postgres is given:
  - For each db_id, create a PostgreSQL-compatible .sql file (e.g., dev_postgres_<db_id>.sql) in the output folder, converting backticks to double quotes and fixing LIMIT syntax.
If --postgres is not given:
  - Perform the original SQLite-based splitting.

Defaults:
  --input: '../../dev_data/dev_20240627/dev.sql'
  --output: '../../dev_data/db_splits'
"""
import argparse
import json
import os
import re
import shutil
from collections import defaultdict

# Paths
json_path = '/Users/apple/developement/bird_bench_shiva/bird-bench/llm/dev_data/dev_20240627/dev.json'
sql_path = '/Users/apple/developement/bird_bench_shiva/bird-bench/llm/dev_data/dev_20240627/dev.sql'
out_root = './db_splits'

# Load data
with open(json_path) as f:
    data = json.load(f)
with open(sql_path) as f:
    sqls = [l.strip() for l in f]

dbs = set(d['db_id'] for d in data)
os.makedirs(out_root, exist_ok=True)

# Group by db
db2json, db2sql = {}, {}
for i, d in enumerate(data):
    db2json.setdefault(d['db_id'], []).append(dict(d, id=i))
for i, l in enumerate(sqls):
    db = l.split('\t')[-1]
    db2sql.setdefault(db, []).append({'id': i, 'sql': l})

# Write per-db files
for db in dbs:
    db_dir = f'{out_root}/{db}'
    os.makedirs(db_dir, exist_ok=True)
    with open(f'{db_dir}/dev_{db}.json', 'w') as f:
        json.dump(db2json[db], f, indent=2)
    with open(f'{db_dir}/dev_{db}.sql', 'w') as f:
        f.writelines([s['sql'] + '\n' for s in db2sql.get(db, [])])

print(f"Split complete. Output in {out_root}/<db_id>/dev_<db_id>.json and .sql")

# Add your original split logic here (for SQLite)
def split_sqlite(input_path, output_dir):
    print(f"[INFO] Splitting SQLite ground truth: {input_path} -> {output_dir}")
    # ...

# New: Split dev.sql into per-db PostgreSQL-compatible .sql files
def split_postgres_per_db(input_path, output_dir):
    print(f"[INFO] Splitting and converting {input_path} into PostgreSQL-compatible .sql files per db in {output_dir}")
    os.makedirs(output_dir, exist_ok=True)
    db_queries = defaultdict(list)
    # Load dev_tables.json for schema info
    dev_tables_path = os.path.join(os.path.dirname(input_path), 'dev_tables.json')
    if not os.path.exists(dev_tables_path):
        dev_tables_path = os.path.join(os.path.dirname(os.path.dirname(input_path)), 'dev_tables.json')
    with open(dev_tables_path) as f:
        dev_tables = json.load(f)
    dbid2schema = {d['db_id']: d for d in dev_tables}
    # Load dev.json for question splits
    dev_json_path = input_path.replace('.sql', '.json')
    with open(dev_json_path) as f:
        dev_data = json.load(f)
    db2json = defaultdict(list)
    for i, d in enumerate(dev_data):
        db2json[d['db_id']].append(dict(d, id=i))
    # Split SQLs
    with open(input_path, 'r') as infile:
        for line in infile:
            if '\t' in line:
                sql, db_id = line.rsplit('\t', 1)
                db_id = db_id.strip()
            else:
                continue  # skip malformed lines
            # Convert backticks to double quotes
            sql = sql.replace('`', '"')
            # Fix LIMIT x, y to LIMIT y OFFSET x
            sql = re.sub(r'LIMIT\s+(\d+)\s*,\s*(\d+)', r'LIMIT \2 OFFSET \1', sql)
            # Remove trailing semicolons and whitespace
            sql = sql.strip().rstrip(';')
            db_queries[db_id].append(f"{sql}\t{db_id}")
    for db_id, queries in db_queries.items():
        out_file = os.path.join(output_dir, f'dev_postgres_{db_id}.sql')
        with open(out_file, 'w') as f:
            f.writelines(q + '\n' for q in queries)
        print(f"[INFO] Wrote {len(queries)} queries to {out_file}")
    # Optionally, also write the JSON as before (for eval compatibility)
    for db_id in db2json:
        if db_id in dbid2schema:
            schema = dbid2schema[db_id]
            for entry in db2json[db_id]:
                entry['table_names'] = schema['table_names_original']
                entry['column_names'] = schema['column_names_original']
            json_out_file = os.path.join(output_dir, f'dev_postgres_{db_id}.json')
            with open(json_out_file, 'w') as jf:
                json.dump(db2json[db_id], jf, indent=2)
            print(f"[INFO] Wrote PostgreSQL-compatible JSON to {json_out_file}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('--input', type=str, help='Path to dev.sql (default: ../../dev_data/dev_20240627/dev.sql)')
    parser.add_argument('--output', type=str, help='Output folder for splits (default: ../../dev_data/db_splits)')
    parser.add_argument('--postgres', action='store_true', help='Convert to PostgreSQL-compatible SQL and split for PostgreSQL evaluation')
    args = parser.parse_args()

    if args.postgres:
        split_postgres_per_db(args.input, args.output)
    else:
        os.makedirs(args.output, exist_ok=True)
        split_sqlite(args.input, args.output)