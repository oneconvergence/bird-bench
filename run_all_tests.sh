#!/bin/bash

# BIRD-SQL Mini-Dev All Tests Runner
# This script runs SQLite, MySQL, and PostgreSQL tests in sequence

# Colors for better output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Custom API Configuration - IMPORTANT: Replace these with your own values
API_KEY="your-api-key-here"  # REPLACE with your actual OpenAI API key
MODEL_NAME="gpt-4-turbo"  # Using GPT-4 Turbo model
API_BASE="https://api.openai.com"  # Using OpenAI's standard API endpoint

# Number of questions to test (0 for all 500 questions)
NUM_QUESTIONS=5  # Setting to 5 for quick testing

# Check if config file exists and load it
CONFIG_FILE=".api_config"
if [ -f "$CONFIG_FILE" ]; then
    echo -e "${BLUE}Loading API configuration from $CONFIG_FILE...${NC}"
    source "$CONFIG_FILE"
else
    # Prompt for API credentials if not found in a config file
    echo -e "${YELLOW}No API configuration file found. Please enter your API credentials:${NC}"
    read -p "API Key: " API_KEY
    read -p "Model Name: " MODEL_NAME
    read -p "API Base URL (default: https://api.openai.com): " input_api_base
    API_BASE=${input_api_base:-"https://api.openai.com"}
    
    # Ask if user wants to save the configuration
    read -p "Save this configuration for future use? (y/n): " save_config
    if [[ "$save_config" == "y" ]]; then
        echo "API_KEY=\"$API_KEY\"" > "$CONFIG_FILE"
        echo "MODEL_NAME=\"$MODEL_NAME\"" >> "$CONFIG_FILE"
        echo "API_BASE=\"$API_BASE\"" >> "$CONFIG_FILE"
        chmod 600 "$CONFIG_FILE"  # Restrict access to the config file
        echo -e "${GREEN}Configuration saved to $CONFIG_FILE${NC}"
        echo -e "${YELLOW}Note: Add $CONFIG_FILE to your .gitignore to avoid committing API credentials${NC}"
    fi
fi

# Setup base environment
setup_environment() {
    echo -e "${BLUE}Setting up environment...${NC}"
    
    # Create necessary directories
    mkdir -p llm/exp_result/sql_output
    mkdir -p llm/exp_result/sql_output_kg
    mkdir -p eval_result
    
    # Update API configuration in gpt_request.py
    sed -i '' "s|api_base = .*|api_base = \"$API_BASE\"|g" llm/src/gpt_request.py
    
    # Update API configuration in run_gpt.sh
    sed -i '' "s|YOUR_API_KEY=.*|YOUR_API_KEY='$API_KEY'|g" llm/run/run_gpt.sh
    sed -i '' "s|engine=.*|engine='$MODEL_NAME'|g" llm/run/run_gpt.sh
    
    # Set number of questions to evaluate
    if [ $NUM_QUESTIONS -gt 0 ]; then
        sed -i '' "s|test_question_limit=.*|test_question_limit=$NUM_QUESTIONS|g" llm/run/run_gpt.sh
        echo -e "${YELLOW}Testing mode: Only evaluating $NUM_QUESTIONS questions${NC}"
    else
        sed -i '' "s|test_question_limit=.*|test_question_limit=0|g" llm/run/run_gpt.sh
        echo -e "${GREEN}Running full evaluation with all 500 questions${NC}"
    fi
    
    echo -e "${GREEN}✓ Environment setup complete${NC}"
}

# Run SQLite test (no database setup required)
run_sqlite_test() {
    echo -e "\n${BLUE}========== RUNNING SQLITE EVALUATION ==========${NC}"
    
    # Configure for SQLite
    sed -i '' "s|sql_dialect=.*|sql_dialect='SQLite'|g" llm/run/run_gpt.sh
    sed -i '' "s|mini_dev_.*\.json|mini_dev_sqlite.json|g" llm/run/run_gpt.sh
    
    echo -e "${GREEN}✓ Updated configuration for SQLite${NC}"
    
    # Run inference
    echo -e "${BLUE}Running inference with SQLite...${NC}"
    cd llm/run
    chmod +x run_gpt.sh
    ./run_gpt.sh
    cd ../..
    
    # Run evaluation
    echo -e "${BLUE}Running evaluation for SQLite...${NC}"
    cd evaluation
    chmod +x run_evaluation.sh
    ./run_evaluation.sh
    cd ..
    
    # Copy results to a specific file
    cp eval_result/predict_mini_dev_${MODEL_NAME}_*.txt eval_result/sqlite_results.txt 2>/dev/null || true
    
    echo -e "${GREEN}✓ SQLite evaluation complete${NC}"
}

# Run MySQL test with automatic setup
run_mysql_test() {
    echo -e "\n${BLUE}========== RUNNING MYSQL EVALUATION ==========${NC}"
    
    # Configure for MySQL
    sed -i '' "s|sql_dialect=.*|sql_dialect='MySQL'|g" llm/run/run_gpt.sh
    sed -i '' "s|mini_dev_.*\.json|mini_dev_mysql.json|g" llm/run/run_gpt.sh
    
    echo -e "${GREEN}✓ Updated configuration for MySQL${NC}"
    
    # Setup MySQL database
    echo -e "${BLUE}Setting up MySQL database...${NC}"
    chmod +x setup_mysql.sh
    ./setup_mysql.sh
    
    # Run inference
    echo -e "${BLUE}Running inference with MySQL...${NC}"
    cd llm/run
    chmod +x run_gpt.sh
    ./run_gpt.sh
    cd ../..
    
    # Run evaluation
    echo -e "${BLUE}Running evaluation for MySQL...${NC}"
    cd evaluation
    chmod +x run_evaluation.sh
    ./run_evaluation.sh
    cd ..
    
    # Copy results to a specific file
    cp eval_result/predict_mini_dev_${MODEL_NAME}_*.txt eval_result/mysql_results.txt 2>/dev/null || true
    
    echo -e "${GREEN}✓ MySQL evaluation complete${NC}"
}

# Run PostgreSQL test with automatic setup
run_postgresql_test() {
    echo -e "\n${BLUE}========== RUNNING POSTGRESQL EVALUATION ==========${NC}"
    
    # Configure for PostgreSQL
    sed -i '' "s|sql_dialect=.*|sql_dialect='PostgreSQL'|g" llm/run/run_gpt.sh
    sed -i '' "s|mini_dev_.*\.json|mini_dev_postgresql.json|g" llm/run/run_gpt.sh
    
    echo -e "${GREEN}✓ Updated configuration for PostgreSQL${NC}"
    
    # Setup PostgreSQL database
    echo -e "${BLUE}Setting up PostgreSQL database...${NC}"
    chmod +x setup_postgresql.sh
    ./setup_postgresql.sh
    
    # Run inference
    echo -e "${BLUE}Running inference with PostgreSQL...${NC}"
    cd llm/run
    chmod +x run_gpt.sh
    ./run_gpt.sh
    cd ../..
    
    # Run evaluation
    echo -e "${BLUE}Running evaluation for PostgreSQL...${NC}"
    cd evaluation
    chmod +x run_evaluation.sh
    ./run_evaluation.sh
    cd ..
    
    # Copy results to a specific file
    cp eval_result/predict_mini_dev_${MODEL_NAME}_*.txt eval_result/postgresql_results.txt 2>/dev/null || true
    
    echo -e "${GREEN}✓ PostgreSQL evaluation complete${NC}"
}

# Check if a database can connect
check_database() {
    db_type=$1
    python -c "
import sys
try:
    if '$db_type' == 'mysql':
        import pymysql
        pymysql.connect(host='localhost', user='root', password='MyNewPassword', database='BIRD', port=3306)
        sys.exit(0)
    elif '$db_type' == 'postgresql':
        import psycopg2
        psycopg2.connect('dbname=bird user=postgres host=localhost password=postgres port=5432')
        sys.exit(0)
except Exception as e:
    print(f'Error connecting to $db_type: {e}')
    sys.exit(1)
"
    return $?
}

# Main function
main() {
    echo -e "${BLUE}==================================================${NC}"
    echo -e "${BLUE}      BIRD-SQL Mini-Dev All Tests Runner          ${NC}"
    echo -e "${BLUE}==================================================${NC}"
    echo -e "${YELLOW}Running tests with:${NC}"
    echo -e "${YELLOW}API Base: ${NC}${API_BASE}"
    echo -e "${YELLOW}Model: ${NC}${MODEL_NAME}"
    echo -e "${YELLOW}API Key: ${NC}${API_KEY:0:3}...${API_KEY: -3}"  # Only show first and last 3 chars for security
    
    # Setup base environment
    setup_environment
    
    # Ask which dialects to test
    echo -e "\n${BLUE}Which SQL dialects would you like to test?${NC}"
    echo -e "1) SQLite only (works without database installation)"
    echo -e "2) MySQL only (requires MySQL database)"
    echo -e "3) PostgreSQL only (requires PostgreSQL database)"
    echo -e "4) All dialects"
    echo -e "5) SQLite and MySQL"
    echo -e "6) SQLite and PostgreSQL"
    read -p "Enter your choice (1-6): " choice
    
    case $choice in
        1)
            run_sqlite_test
            ;;
        2)
            if check_database mysql; then
                run_mysql_test
            else
                echo -e "${RED}MySQL database connection failed. Please install MySQL and run setup_mysql.sh first.${NC}"
                exit 1
            fi
            ;;
        3)
            if check_database postgresql; then
                run_postgresql_test
            else
                echo -e "${RED}PostgreSQL database connection failed. Please install PostgreSQL and run setup_postgresql.sh first.${NC}"
                exit 1
            fi
            ;;
        4)
            run_sqlite_test
            if check_database mysql; then
                run_mysql_test
            else
                echo -e "${RED}Skipping MySQL tests - database connection failed${NC}"
            fi
            if check_database postgresql; then
                run_postgresql_test
            else
                echo -e "${RED}Skipping PostgreSQL tests - database connection failed${NC}"
            fi
            ;;
        5)
            run_sqlite_test
            if check_database mysql; then
                run_mysql_test
            else
                echo -e "${RED}Skipping MySQL tests - database connection failed${NC}"
            fi
            ;;
        6)
            run_sqlite_test
            if check_database postgresql; then
                run_postgresql_test
            else
                echo -e "${RED}Skipping PostgreSQL tests - database connection failed${NC}"
            fi
            ;;
        *)
            echo -e "${RED}Invalid choice. Running SQLite test only.${NC}"
            run_sqlite_test
            ;;
    esac
    
    # Final summary
    echo -e "\n${BLUE}==================================================${NC}"
    echo -e "${GREEN}All tests completed!${NC}"
    echo -e "${BLUE}Results saved to:${NC}"
    ls -1 eval_result/*_results.txt 2>/dev/null || echo -e "${RED}No result files found${NC}"
    echo -e "${BLUE}==================================================${NC}"
}

# Run the main function
main 