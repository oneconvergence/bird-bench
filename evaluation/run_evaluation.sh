#!/bin/bash

# DO NOT CHANGE THIS
db_root_path='../llm/mini_dev_data/minidev/MINIDEV/dev_databases/'
num_cpus=16
meta_time_out=30.0
# DO NOT CHANGE THIS

# Get the engine name from run_gpt.sh
engine_line=$(grep "engine=" ../llm/run/run_gpt.sh)
engine_name=$(echo "$engine_line" | cut -d'=' -f2 | tr -d "'" | tr -d '"')

# Choose the SQL dialect from run_gpt.sh or use default
sql_dialect_line=$(grep "sql_dialect=" ../llm/run/run_gpt.sh)
sql_dialect=$(echo "$sql_dialect_line" | cut -d'=' -f2 | tr -d "'" | tr -d '"')

# Get chain of thought setting
cot_line=$(grep "cot=" ../llm/run/run_gpt.sh)
cot=$(echo "$cot_line" | cut -d'=' -f2 | tr -d "'" | tr -d '"')

echo "Looking for prediction file from model: $engine_name with dialect: $sql_dialect"

# Determine correct file pattern based on chain of thought setting
cot_suffix=""
if [ "$cot" == "True" ]; then
  cot_suffix="_cot"
fi

# Use the correct path format with proper case for SQL dialect
predicted_sql_path="../llm/run/exp_result/sql_output_kg/predict_mini_dev_${engine_name}${cot_suffix}_${sql_dialect}.json"

# Convert SQL dialect to proper case for display
echo "Using prediction file: $predicted_sql_path"
echo "Using SQL dialect: $sql_dialect"

# DO NOT CHANGE THIS
# Extract the base filename without extension
base_name=$(basename "$predicted_sql_path" .json)
# Define the output log path
output_log_path="../eval_result/${base_name}.txt"
mkdir -p "../eval_result"

case $sql_dialect in
  "SQLite")
    diff_json_path="../llm/mini_dev_data/minidev/MINIDEV/mini_dev_sqlite.json"
    ground_truth_path="../llm/mini_dev_data/minidev/MINIDEV/mini_dev_sqlite_gold.sql"
    ;;
  "PostgreSQL")
    diff_json_path="../llm/mini_dev_data/minidev/MINIDEV/mini_dev_postgresql.json"
    ground_truth_path="../llm/mini_dev_data/minidev/MINIDEV/mini_dev_postgresql_gold.sql"
    ;;
  "MySQL")
    diff_json_path="../llm/mini_dev_data/minidev/MINIDEV/mini_dev_mysql.json"
    ground_truth_path="../llm/mini_dev_data/minidev/MINIDEV/mini_dev_mysql_gold.sql"
    ;;
  *)
    echo "Invalid SQL dialect: $sql_dialect"
    exit 1
    ;;
esac
# DO NOT CHANGE THIS

# Output the set paths
echo "Differential JSON Path: $diff_json_path"
echo "Ground Truth Path: $ground_truth_path"
echo "Predicted SQL Path: $predicted_sql_path"

# Check if prediction file exists
if [ ! -f "$predicted_sql_path" ]; then
  echo "ERROR: Predicted SQL file not found at: $predicted_sql_path"
  echo "Please check if the file exists and the path is correct"
  echo "Available prediction files:"
  find ../llm/run/exp_result/sql_output_kg -name "predict_mini_dev_*.json" | sort
  exit 1
fi

# Check that the JSON file can be parsed
if ! python3 -c "import json; json.load(open('$predicted_sql_path'))" &>/dev/null; then
  echo "ERROR: The prediction file exists but is not valid JSON"
  echo "This suggests that the API calls might have failed or the script was interrupted"
  echo "Please check the file contents and re-run the inference script if needed"
  exit 1
fi

echo "Starting to compare with knowledge for ex, sql_dialect: ${sql_dialect}"
python3 -u ./evaluation_ex.py --db_root_path ${db_root_path} --predicted_sql_path ${predicted_sql_path} \
--ground_truth_path ${ground_truth_path} --num_cpus ${num_cpus} --output_log_path ${output_log_path} \
--diff_json_path ${diff_json_path} --meta_time_out ${meta_time_out} --sql_dialect ${sql_dialect}


echo "Starting to compare with knowledge for R-VES, sql_dialect: ${sql_dialect}"
python3 -u ./evaluation_ves.py --db_root_path ${db_root_path} --predicted_sql_path ${predicted_sql_path} \
--ground_truth_path ${ground_truth_path} --num_cpus ${num_cpus} --output_log_path ${output_log_path} \
--diff_json_path ${diff_json_path} --meta_time_out ${meta_time_out} --sql_dialect ${sql_dialect}


echo "Starting to compare with knowledge for soft-f1, sql_dialect: ${sql_dialect}"
python3 -u ./evaluation_f1.py --db_root_path ${db_root_path} --predicted_sql_path ${predicted_sql_path} \
--ground_truth_path ${ground_truth_path} --num_cpus ${num_cpus} --output_log_path ${output_log_path} \
--diff_json_path ${diff_json_path} --meta_time_out ${meta_time_out} --sql_dialect ${sql_dialect}