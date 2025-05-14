#!/bin/bash

# Colors for better output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}Setting up MySQL database for BIRD-SQL Mini-Dev project...${NC}"

# Check if MySQL is installed
if ! command -v mysql &> /dev/null; then
    echo -e "${RED}MySQL is not installed or not in the PATH.${NC}"
    echo -e "${YELLOW}Please install MySQL first:${NC}"
    echo -e "  - For macOS: brew install mysql"
    echo -e "  - For Ubuntu: apt-get install mysql-server"
    echo -e "  - For CentOS/RHEL: yum install mysql-server"
    echo -e "  - Or download from https://dev.mysql.com/downloads/mysql/"
    exit 1
fi

# Get MySQL credentials
echo -e "${YELLOW}Please provide your MySQL credentials:${NC}"
read -p "Username (default: root): " mysql_user
mysql_user=${mysql_user:-root}

# Try to determine the appropriate way to authenticate
mysql_password=""
mysql_password_set=false

echo -e "${BLUE}Attempting to connect to MySQL using various authentication methods...${NC}"

# Method 1: Connecting without credentials (socket authentication)
echo -e "${YELLOW}Method 1: Connecting without credentials (socket authentication)...${NC}"
if mysql -u $mysql_user -e "SELECT 'Connection successful' AS ''" &> /dev/null; then
    echo -e "${GREEN}✅ Connected successfully without a password!${NC}"
    mysql_connection="mysql -u $mysql_user"
    mysql_password_set=true
else
    echo -e "${RED}❌ Could not connect without credentials.${NC}"
fi

# Method 2: Try with empty password
if [ "$mysql_password_set" = false ]; then
    echo -e "${YELLOW}Method 2: Connecting as $mysql_user with no password...${NC}"
    if mysql -u $mysql_user -p"" -e "SELECT 'Connection successful' AS ''" &> /dev/null; then
        echo -e "${GREEN}✅ Connected successfully with empty password!${NC}"
        mysql_connection="mysql -u $mysql_user -p\"\""
        mysql_password=""
        mysql_password_set=true
    else
        echo -e "${RED}❌ Could not connect as $mysql_user without password.${NC}"
    fi
fi

# Method 3: Ask for password
if [ "$mysql_password_set" = false ]; then
    echo -e "${YELLOW}Method 3: Custom credentials...${NC}"
    read -s -p "Password: " mysql_password
    echo ""
    
    if mysql -u $mysql_user -p"$mysql_password" -e "SELECT 'Connection successful' AS ''" &> /dev/null; then
        echo -e "${GREEN}✅ Connected successfully with password!${NC}"
        mysql_connection="mysql -u $mysql_user -p\"$mysql_password\""
        mysql_password_set=true
    else
        echo -e "${RED}❌ Could not connect with the provided credentials.${NC}"
        echo -e "${RED}Please check your MySQL installation and credentials.${NC}"
        exit 1
    fi
fi

# Create the database if it doesn't exist
echo -e "${BLUE}Creating BIRD database if it doesn't exist...${NC}"
eval "$mysql_connection -e 'CREATE DATABASE IF NOT EXISTS BIRD;'"

# Import SQL file
echo -e "${BLUE}Importing SQL file into the BIRD database. This may take a while...${NC}"

# Check if the SQL file exists
if [ ! -f "llm/mini_dev_data/minidev/MINIDEV_mysql/BIRD_dev.sql" ]; then
    echo -e "${RED}❌ MySQL SQL file not found at llm/mini_dev_data/minidev/MINIDEV_mysql/BIRD_dev.sql${NC}"
    echo -e "${YELLOW}Please make sure you've downloaded and extracted the Mini-Dev dataset correctly.${NC}"
    exit 1
fi

# Import the SQL file
eval "$mysql_connection BIRD < llm/mini_dev_data/minidev/MINIDEV_mysql/BIRD_dev.sql"

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to import SQL file. Please check the error message above.${NC}"
    exit 1
fi

echo -e "${GREEN}MySQL database setup completed successfully!${NC}"

# Update connection details in table_schema.py
echo -e "${BLUE}Updating connection details in table_schema.py...${NC}"
sed -i '' "s/password=\"[^\"]*\"/password=\"$mysql_password\"/" llm/src/table_schema.py
sed -i '' "s/user=\"[^\"]*\"/user=\"$mysql_user\"/" llm/src/table_schema.py

echo -e "${GREEN}You can now use the MySQL dialect for testing.${NC}"

# Check SQL mode
echo -e "${BLUE}Checking SQL mode...${NC}"
sql_mode=$(eval "$mysql_connection -e 'SELECT @@GLOBAL.sql_mode;' -N")

if [[ $sql_mode == *"ONLY_FULL_GROUP_BY"* ]]; then
    echo -e "${YELLOW}ONLY_FULL_GROUP_BY mode is enabled. This might cause issues with some queries.${NC}"
    echo -e "${BLUE}Attempting to disable ONLY_FULL_GROUP_BY mode...${NC}"
    
    # Remove ONLY_FULL_GROUP_BY from sql_mode
    new_sql_mode=$(echo $sql_mode | sed 's/ONLY_FULL_GROUP_BY,\?//g' | sed 's/,,/,/g' | sed 's/^,//g' | sed 's/,$//g')
    
    eval "$mysql_connection -e \"SET GLOBAL sql_mode='$new_sql_mode';\""
    
    # Verify the change
    updated_sql_mode=$(eval "$mysql_connection -e 'SELECT @@GLOBAL.sql_mode;' -N")
    if [[ $updated_sql_mode != *"ONLY_FULL_GROUP_BY"* ]]; then
        echo -e "${GREEN}✅ Successfully disabled ONLY_FULL_GROUP_BY mode!${NC}"
    else
        echo -e "${RED}❌ Failed to disable ONLY_FULL_GROUP_BY mode. Some queries may fail.${NC}"
    fi
fi

echo -e "${GREEN}MySQL setup complete!${NC}" 