#!/bin/bash

# Colors for better output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}Setting up PostgreSQL database for BIRD-SQL Mini-Dev project...${NC}"

# Check if PostgreSQL is installed
if ! command -v psql &> /dev/null; then
    echo -e "${RED}PostgreSQL is not installed or not in the PATH.${NC}"
    echo -e "${YELLOW}Please install PostgreSQL first:${NC}"
    echo -e "  - For macOS: brew install postgresql"
    echo -e "  - For Ubuntu: apt-get install postgresql postgresql-contrib"
    echo -e "  - For CentOS/RHEL: yum install postgresql-server"
    echo -e "  - Or download from https://www.postgresql.org/download/"
    exit 1
fi

# Check if the SQL file exists
if [ ! -f "llm/mini_dev_data/minidev/MINIDEV_postgresql/BIRD_dev.sql" ]; then
    echo -e "${RED}❌ PostgreSQL SQL file not found at llm/mini_dev_data/minidev/MINIDEV_postgresql/BIRD_dev.sql${NC}"
    echo -e "${YELLOW}Please make sure you've downloaded and extracted the Mini-Dev dataset correctly.${NC}"
    exit 1
fi

# Get PostgreSQL credentials
echo -e "${YELLOW}Please provide your PostgreSQL credentials:${NC}"
read -p "Username (default: postgres): " pg_user
pg_user=${pg_user:-postgres}
read -s -p "Password (default: postgres): " pg_password
pg_password=${pg_password:-postgres}
echo ""
read -p "Host (default: localhost): " pg_host
pg_host=${pg_host:-localhost}
read -p "Port (default: 5432): " pg_port
pg_port=${pg_port:-5432}

# Test the connection
echo -e "${BLUE}Testing PostgreSQL connection...${NC}"
if PGPASSWORD="$pg_password" psql -h "$pg_host" -p "$pg_port" -U "$pg_user" -c "SELECT 'Connection successful' AS connection_test;" &> /dev/null; then
    echo -e "${GREEN}✅ Connected successfully to PostgreSQL!${NC}"
else
    echo -e "${RED}❌ Failed to connect to PostgreSQL with the provided credentials.${NC}"
    echo -e "${YELLOW}Please check your PostgreSQL installation and credentials.${NC}"
    exit 1
fi

# Create the database
echo -e "${BLUE}Creating the database (lowercase 'bird')...${NC}"

# First try to drop if it exists (ignore errors)
PGPASSWORD="$pg_password" psql -h "$pg_host" -p "$pg_port" -U "$pg_user" -c "DROP DATABASE IF EXISTS bird;" &> /dev/null

# Create the database (lowercase)
if PGPASSWORD="$pg_password" psql -h "$pg_host" -p "$pg_port" -U "$pg_user" -c "CREATE DATABASE bird;" &> /dev/null; then
    echo -e "${GREEN}✅ Created database 'bird' successfully!${NC}"
else
    echo -e "${RED}❌ Failed to create the database. Please make sure you have the necessary permissions.${NC}"
    exit 1
fi

# Import the SQL file
echo -e "${BLUE}Importing SQL file into the PostgreSQL database. This may take a while...${NC}"

PGPASSWORD="$pg_password" psql -h "$pg_host" -p "$pg_port" -U "$pg_user" -d "bird" -f "llm/mini_dev_data/minidev/MINIDEV_postgresql/BIRD_dev.sql" &> /dev/null

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ PostgreSQL database setup completed successfully!${NC}"
else
    echo -e "${RED}❌ Failed to import the SQL file. Check the error message above.${NC}"
    exit 1
fi

# Update the connection details in table_schema.py
echo -e "${BLUE}Updating connection details in table_schema.py...${NC}"

# Construct the connection string
conn_string="\"dbname=bird user=$pg_user host=$pg_host password=$pg_password port=$pg_port\""

# Update the file
sed -i '' "s|psycopg2\.connect(.*)|psycopg2.connect($conn_string)|g" llm/src/table_schema.py

echo -e "${GREEN}✅ Connection details updated in table_schema.py${NC}"
echo -e "${GREEN}PostgreSQL setup complete!${NC}"
echo -e "${YELLOW}You can now use the PostgreSQL dialect for testing.${NC}" 