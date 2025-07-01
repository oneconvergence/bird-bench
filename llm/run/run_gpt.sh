eval_path="./../dev_data/dev_20240627/dev.json"
db_root_path="./../dev_data/dev_20240627/dev_databases"
dev_path='./output/'
use_knowledge='True'
mode='dev' # dev, train, mini_dev
cot='True'

# Replace with your API key - must have access to the model specified below
# WARNING: The script will fail if you don't replace this placeholder!
YOUR_API_KEY='' # Add your API key here before running

# Model name - this is used to construct the API URL in format:
# https://your-endpoint.com/MODEL_NAME/v1
# The model name should match what your API provider expects
# Examples: gpt-4-turbo, meta-llama-3-70b-instruct, mistral-large, claude-3-opus
# WARNING: Keep the model name without spaces or special characters
engine='inf-2-0-32b-sql' # Replace with your model name

# Choose the number of threads to run in parallel, 1 for single thread
num_threads=1

# Choose the SQL dialect to run, e.g. SQLite, MySQL, PostgreSQL
# PLEASE NOTE: You have to setup the database information in table_schema.py 
# if you want to run the evaluation script using MySQL or PostgreSQL
sql_dialect='SQLite'

# For testing purposes, set this to a small number like 10
# Set to 0 or remove to process all questions
test_question_limit=5

# Choose the output path for the generated SQL queries
data_output_path='./exp_result/sql_output/'
data_kg_output_path='./exp_result/sql_output_kg/'

# Create directories if they don't exist
mkdir -p ${data_output_path}
mkdir -p ${data_kg_output_path}

# Process only a limited number of questions if test_question_limit is set
if [ -n "$test_question_limit" ] && [ "$test_question_limit" -gt 0 ]; then
  echo "TESTING MODE: Processing only $test_question_limit questions"
  # Create a temporary JSON file with limited questions
  python3 -c "
import json
data = json.load(open('${eval_path}', 'r'))
limited_data = data[:$test_question_limit]
json.dump(limited_data, open('/tmp/mini_dev_sqlite.json', 'w'))
print(f'Created temporary file with {len(limited_data)} questions')
"
  actual_eval_path="/tmp/mini_dev_sqlite.json"
else
  # Use the original path for full evaluation
  actual_eval_path="${eval_path}"
fi

echo "Generate SQL with model: $engine, threads: $num_threads, knowledge: $use_knowledge, chain of thought: $cot"
python3 -u ../src/gpt_request.py \
  --db_root_path ${db_root_path} \
  --api_key ${YOUR_API_KEY} \
  --mode ${mode} \
  --engine ${engine} \
  --eval_path ${actual_eval_path} \
  --data_output_path ${data_kg_output_path} \
  --use_knowledge ${use_knowledge} \
  --chain_of_thought ${cot} \
  --num_processes ${num_threads} \
  --sql_dialect ${sql_dialect}
