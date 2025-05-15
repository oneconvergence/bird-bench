#!/bin/bash

echo "===== SQLite Evaluation for BIRD-SQL Mini-Dev ====="

# 1. Update run_gpt.sh to use SQLite dialect
echo "Updating run_gpt.sh to use SQLite dialect..."
sed -i '' 's/sql_dialect=.*/sql_dialect='\''SQLite'\''/' llm/run/run_gpt.sh
sed -i '' 's/mini_dev_mysql.json/mini_dev_sqlite.json/' llm/run/run_gpt.sh
echo "✅ Updated run_gpt.sh to use SQLite dialect"

# 2. Run the inference script
echo "Running inference with SQLite dialect..."
cd llm/run
chmod +x run_gpt.sh
./run_gpt.sh
cd ../..

# 3. Run the evaluation script
echo "Running evaluation on SQLite predictions..."
cd evaluation
chmod +x run_evaluation.sh
./run_evaluation.sh
cd ..

echo "===== SQLite Evaluation Complete =====" 