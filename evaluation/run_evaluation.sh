# DO NOT CHANGE THIS
db_root_path='../llm/mini_dev_data/minidev/MINIDEV/dev_databases/'
num_cpus=16
meta_time_out=30.0
# DO NOT CHANGE THIS

# ************************* #
# Path to your predicted SQL file - update this with your output file path
predicted_sql_path='../llm/exp_result/sql_output_kg/predict_mini_dev_**YOUR_MODEL_NAME**_cot_SQLite.json'
# predicted_sql_path='../llm/exp_result/sql_output_kg/predict_mini_dev_**YOUR_MODEL_NAME**_cot_PostgreSQL.json'
# predicted_sql_path='../llm/exp_result/sql_output_kg/predict_mini_dev_**YOUR_MODEL_NAME**_cot_MySQL.json'

# Choose the SQL dialect you used for generation
sql_dialect="SQLite" # ONLY Modify this - options: "SQLite", "PostgreSQL", "MySQL"
# ************************* #

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




echo "starting to compare with knowledge for ex, sql_dialect: ${sql_dialect}"
python3 -u ./evaluation_ex.py --db_root_path ${db_root_path} --predicted_sql_path ${predicted_sql_path}  \
--ground_truth_path ${ground_truth_path} --num_cpus ${num_cpus} --output_log_path ${output_log_path} \
--diff_json_path ${diff_json_path} --meta_time_out ${meta_time_out}  --sql_dialect ${sql_dialect}



# echo "starting to compare with knowledge for R-VES, sql_dialect: ${sql_dialect}"
# python3 -u ./evaluation_ves.py --db_root_path ${db_root_path} --predicted_sql_path ${predicted_sql_path}  \
# --ground_truth_path ${ground_truth_path} --num_cpus ${num_cpus}  --output_log_path ${output_log_path} \
# --diff_json_path ${diff_json_path} --meta_time_out ${meta_time_out}  --sql_dialect ${sql_dialect}


# echo "starting to compare with knowledge for soft-f1, sql_dialect: ${sql_dialect}"
# python3 -u ./evaluation_f1.py --db_root_path ${db_root_path} --predicted_sql_path ${predicted_sql_path}  \
# --ground_truth_path ${ground_truth_path} --num_cpus ${num_cpus}  --output_log_path ${output_log_path} \
# --diff_json_path ${diff_json_path} --meta_time_out ${meta_time_out}   --sql_dialect ${sql_dialect}