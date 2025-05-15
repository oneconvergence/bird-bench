# BIRD-SQL Mini-Dev Workflows

This document explains the key workflows and scripts available in the BIRD-SQL Mini-Dev project.

## Repository Structure

After cleanup, the repository has the following structure:

```
mini_dev/
├── check_setup.py              # Environment verification script
├── cleanup.sh                  # Repository cleanup script
├── CONTRIBUTING.md             # Contribution guidelines
├── evaluation/                 # Evaluation code
│   └── run_evaluation.sh       # Main evaluation script
├── .github/                    # GitHub templates
├── .gitignore                  # Git ignore rules
├── llm/                        # LLM inference code
│   ├── run/                    # Scripts to run inference
│   │   └── run_gpt.sh          # Main inference script
│   └── src/                    # Source code
│       ├── gpt_request.py      # API interaction code
│       ├── prompt.py           # Prompt templates
│       └── table_schema.py     # Database connection settings
├── push_clean_repo.sh          # Script to push cleaned repo
├── README.md                   # Project documentation
├── requirements.txt            # Python dependencies
├── run_all_tests.sh            # All-in-one testing script
├── run_sqlite_eval.sh          # SQLite evaluation helper
├── setup_mysql.sh              # MySQL database setup
├── setup_postgresql.sh         # PostgreSQL database setup
└── WORKFLOW.md                 # This file
```

## Core Workflows

### 1. Initial Setup

The initial setup process involves:

```bash
# Clone the repository
git clone https://github.com/yourusername/mini_dev.git
cd mini_dev

# Install dependencies
pip install -r requirements.txt

# Download and extract the dataset
wget https://bird-bench.oss-cn-beijing.aliyuncs.com/minidev.zip
mkdir -p llm/mini_dev_data
unzip minidev.zip -d llm/mini_dev_data/

# Verify setup
python check_setup.py
```

The `check_setup.py` script verifies:
- Required Python packages
- Database connections (if configured)
- Required dataset files
- API configuration

### 2. Configure Your Model

Edit the API configuration in `run_all_tests.sh`:

```bash
# Custom API Configuration 
API_KEY="your-api-key"              # Your API key
MODEL_NAME="your-model-name"        # Model name (e.g., gpt-4-turbo)
API_BASE="https://your-endpoint.com" # Base URL for your API
```

### 3. SQLite Testing Workflow

The simplest workflow uses SQLite, which requires no database server:

```bash
# Option 1: Using the all-in-one script
./run_all_tests.sh
# Then select option 1 (SQLite only)

# Option 2: Manual step-by-step
cd llm/run
chmod +x run_gpt.sh
./run_gpt.sh  # Generates SQL with your model

cd ../../evaluation
chmod +x run_evaluation.sh
./run_evaluation.sh  # Evaluates the generated SQL
```

### 4. MySQL Testing Workflow

For MySQL testing:

```bash
# Setup MySQL database
chmod +x setup_mysql.sh
./setup_mysql.sh

# Option 1: Using the all-in-one script
./run_all_tests.sh
# Then select option 2 (MySQL only)

# Option 2: Manual step-by-step
# First, edit llm/run/run_gpt.sh to set sql_dialect='MySQL'
cd llm/run
./run_gpt.sh

cd ../../evaluation
./run_evaluation.sh
```

The `setup_mysql.sh` script:
- Checks if MySQL is installed
- Tries multiple authentication methods
- Creates the BIRD database
- Imports the database schema and data

### 5. PostgreSQL Testing Workflow

For PostgreSQL testing:

```bash
# Setup PostgreSQL database
chmod +x setup_postgresql.sh
./setup_postgresql.sh

# Option 1: Using the all-in-one script
./run_all_tests.sh
# Then select option 3 (PostgreSQL only)

# Option 2: Manual step-by-step
# First, edit llm/run/run_gpt.sh to set sql_dialect='PostgreSQL'
cd llm/run
./run_gpt.sh

cd ../../evaluation
./run_evaluation.sh
```

The `setup_postgresql.sh` script:
- Checks if PostgreSQL is installed
- Creates a lowercase 'bird' database
- Imports the database schema and data

### 6. Testing All Dialects

To run tests on all dialects:

```bash
./run_all_tests.sh
# Then select option 4 (All dialects)
```

This will:
1. Run the SQLite workflow
2. Check if MySQL is configured and run it if available
3. Check if PostgreSQL is configured and run it if available
4. Save results for each dialect separately

### 7. Repository Maintenance

Two scripts help with repository maintenance:

1. `cleanup.sh` - Removes unnecessary files:
   ```bash
   chmod +x cleanup.sh
   ./cleanup.sh
   ```
   This removes:
   - Security-sensitive files (passwords, API keys)
   - Generated output files (exp_result/, eval_result/)
   - Large database files (*.sqlite, SQL dumps)
   - Cache files (__pycache__/, .ipynb_checkpoints/)

2. `push_clean_repo.sh` - Cleans and pushes to GitHub:
   ```bash
   chmod +x push_clean_repo.sh
   ./push_clean_repo.sh
   ```
   This script:
   - Runs the cleanup script
   - Verifies Git remote configuration
   - Commits and pushes changes

## Understanding Results

Evaluation results are saved in `eval_result/` with three key metrics:

1. **Execution Accuracy (EX)** - Percentage of correct SQL queries
2. **Reward-based Valid Efficiency Score (R-VES)** - Efficiency metric
3. **Soft F1-Score** - Similarity of result tables

## Troubleshooting

Common issues and solutions:

1. **API Connection Issues**:
   - Verify API key, model name, and endpoint
   - Check the API URL format in `llm/src/gpt_request.py`

2. **Database Connection Issues**:
   - For MySQL: Run `setup_mysql.sh` and follow the prompts
   - For PostgreSQL: Run `setup_postgresql.sh` and follow the prompts

3. **Missing Files**:
   - Run `python check_setup.py` to verify file locations
   - Re-download and extract the dataset if needed

4. **ONLY_FULL_GROUP_BY Error** (MySQL):
   - Execute the SQL command from `check_setup.py` to disable this mode 