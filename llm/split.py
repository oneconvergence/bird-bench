import json
import os

# Paths
json_path = './dev_data/dev_20240627/dev.json'
sql_path = './dev_data/dev_20240627/dev.sql'
out_root = './dev_data/db_splits'

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