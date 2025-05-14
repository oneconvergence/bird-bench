#!/usr/bin/env python3
"""
This script checks the setup of the BIRD-SQL Mini-Dev project.
It verifies the database connections and configuration.
"""

import os
import sys
import sqlite3
import json
import importlib.util
import subprocess
from pathlib import Path

def check_imports():
    """Check if the required packages are installed."""
    required_packages = [
        "openai", "numpy", "psycopg2", "pymysql", "pydantic", 
        "tqdm", "func_timeout", "requests", "httpx", "cryptography"
    ]
    missing_packages = []
    
    for package in required_packages:
        spec = importlib.util.find_spec(package)
        if spec is None:
            missing_packages.append(package)
    
    if missing_packages:
        print(f"WARNING: Missing packages: {', '.join(missing_packages)}")
        print("Install them using: pip install " + " ".join(missing_packages))
        return False
    else:
        print("✅ All required packages are installed.")
        return True

def check_sqlite_databases():
    """Check if the SQLite databases are accessible."""
    db_root_path = "llm/mini_dev_data/minidev/MINIDEV/dev_databases/"
    
    if not os.path.exists(db_root_path):
        print(f"❌ Database directory not found: {db_root_path}")
        return False
    
    # Check if at least one database exists
    databases = os.listdir(db_root_path)
    if not databases:
        print(f"❌ No databases found in {db_root_path}")
        return False
    
    print(f"✅ Found {len(databases)} database directories")
    
    # Try to connect to one random SQLite database
    for db_dir in databases:
        db_path = os.path.join(db_root_path, db_dir, f"{db_dir}.sqlite")
        if os.path.exists(db_path):
            try:
                conn = sqlite3.connect(db_path)
                cursor = conn.cursor()
                cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
                tables = cursor.fetchall()
                conn.close()
                print(f"✅ Successfully connected to SQLite database: {db_path}")
                print(f"   Tables found: {len(tables)}")
                return True
            except Exception as e:
                print(f"❌ Failed to connect to SQLite database {db_path}: {str(e)}")
                return False
    
    print("❌ No SQLite database files found.")
    return False

def check_evaluation_files():
    """Check if the evaluation files are accessible."""
    # Check required JSON files
    json_files = [
        "llm/mini_dev_data/minidev/MINIDEV/mini_dev_sqlite.json",
        "llm/mini_dev_data/minidev/MINIDEV/mini_dev_mysql.json",
        "llm/mini_dev_data/minidev/MINIDEV/mini_dev_postgresql.json"
    ]
    
    all_files_exist = True
    for json_file in json_files:
        if os.path.exists(json_file):
            try:
                with open(json_file, 'r') as f:
                    data = json.load(f)
                    print(f"✅ {json_file} is valid JSON with {len(data)} records")
            except Exception as e:
                print(f"❌ Failed to parse {json_file}: {str(e)}")
                all_files_exist = False
        else:
            print(f"❌ {json_file} not found")
            all_files_exist = False
    
    # Check required SQL files
    sql_files = [
        "llm/mini_dev_data/minidev/MINIDEV/mini_dev_sqlite_gold.sql",
        "llm/mini_dev_data/minidev/MINIDEV/mini_dev_mysql_gold.sql",
        "llm/mini_dev_data/minidev/MINIDEV/mini_dev_postgresql_gold.sql"
    ]
    
    for sql_file in sql_files:
        if os.path.exists(sql_file):
            print(f"✅ {sql_file} exists")
        else:
            print(f"❌ {sql_file} not found")
            all_files_exist = False
            
    # Check setup SQL files
    setup_files = [
        "llm/mini_dev_data/minidev/MINIDEV_mysql/BIRD_dev.sql",
        "llm/mini_dev_data/minidev/MINIDEV_postgresql/BIRD_dev.sql"
    ]
    
    for setup_file in setup_files:
        if os.path.exists(setup_file):
            print(f"✅ {setup_file} exists")
        else:
            print(f"❌ {setup_file} not found")
            all_files_exist = False
    
    return all_files_exist

def check_mysql_connection():
    """Try to connect to MySQL database."""
    try:
        import pymysql
        try:
            conn = pymysql.connect(
                host="localhost",
                user="root",
                password="root",  # Change this to your MySQL password
                database="BIRD",
                port=3306,
            )
            cursor = conn.cursor()
            cursor.execute("SHOW TABLES")
            tables = cursor.fetchall()
            conn.close()
            print(f"✅ Successfully connected to MySQL database")
            print(f"   Tables found: {len(tables)}")
            
            # Check for ONLY_FULL_GROUP_BY mode
            conn = pymysql.connect(
                host="localhost",
                user="root",
                password="root",
                database="BIRD",
                port=3306,
            )
            cursor = conn.cursor()
            cursor.execute("SELECT @@GLOBAL.sql_mode")
            sql_mode = cursor.fetchone()[0]
            conn.close()
            
            if "ONLY_FULL_GROUP_BY" in sql_mode:
                print("⚠️  WARNING: ONLY_FULL_GROUP_BY mode is enabled in MySQL.")
                print("   This might cause issues with some queries.")
                print("   To disable it, run the following commands in MySQL:")
                print(f"   SET GLOBAL sql_mode='{sql_mode.replace('ONLY_FULL_GROUP_BY', '').replace(',,', ',').strip(',')}'")
            
            # Check a specific database to verify it's correctly set up
            try:
                conn = pymysql.connect(
                    host="localhost",
                    user="root",
                    password="root",
                    database="BIRD",
                    port=3306,
                )
                cursor = conn.cursor()
                cursor.execute("SELECT COUNT(*) FROM financial.district")
                count = cursor.fetchone()[0]
                conn.close()
                print(f"✅ Successfully queried financial.district table, found {count} rows")
                return True
            except Exception as e:
                print(f"⚠️  Could not query financial.district table: {str(e)}")
                print("   This may indicate that the database is not fully set up")
                return False
                
        except Exception as e:
            print(f"❌ Failed to connect to MySQL database: {str(e)}")
            print("   Check your MySQL connection settings in llm/src/table_schema.py")
            return False
    except ImportError:
        print("❌ pymysql package not found. Install it using: pip install pymysql")
        return False

def check_postgresql_connection():
    """Try to connect to PostgreSQL database."""
    try:
        import psycopg2
        try:
            # Try lowercase "bird" first (most common case)
            try:
                conn = psycopg2.connect(
                    "dbname=bird user=postgres host=localhost password=postgres port=5432"
                )
                cursor = conn.cursor()
                cursor.execute("SELECT tablename FROM pg_catalog.pg_tables WHERE schemaname='public'")
                tables = cursor.fetchall()
                conn.close()
                print(f"✅ Successfully connected to PostgreSQL database (lowercase 'bird')")
                print(f"   Tables found: {len(tables)}")
                
                # Update the connection string in table_schema.py if needed
                with open("llm/src/table_schema.py", "r") as f:
                    content = f.read()
                if "dbname=BIRD" in content:
                    print("⚠️  Warning: table_schema.py has uppercase BIRD database name, but your database is lowercase")
                    print("   You might need to update the connection string in llm/src/table_schema.py")
                
                # Check a specific database to verify it's correctly set up
                try:
                    conn = psycopg2.connect(
                        "dbname=bird user=postgres host=localhost password=postgres port=5432"
                    )
                    cursor = conn.cursor()
                    cursor.execute("SELECT COUNT(*) FROM financial.district")
                    count = cursor.fetchone()[0]
                    conn.close()
                    print(f"✅ Successfully queried financial.district table, found {count} rows")
                    return True
                except Exception as e:
                    print(f"⚠️  Could not query financial.district table: {str(e)}")
                    print("   This may indicate that the database is not fully set up")
                    return False
                    
            except Exception as lowercase_e:
                # If lowercase fails, try uppercase
                try:
                    conn = psycopg2.connect(
                        "dbname=BIRD user=postgres host=localhost password=postgres port=5432"
                    )
                    cursor = conn.cursor()
                    cursor.execute("SELECT tablename FROM pg_catalog.pg_tables WHERE schemaname='public'")
                    tables = cursor.fetchall()
                    conn.close()
                    print(f"✅ Successfully connected to PostgreSQL database (uppercase 'BIRD')")
                    print(f"   Tables found: {len(tables)}")
                    
                    # Check a specific database to verify it's correctly set up
                    try:
                        conn = psycopg2.connect(
                            "dbname=BIRD user=postgres host=localhost password=postgres port=5432"
                        )
                        cursor = conn.cursor()
                        cursor.execute("SELECT COUNT(*) FROM financial.district")
                        count = cursor.fetchone()[0]
                        conn.close()
                        print(f"✅ Successfully queried financial.district table, found {count} rows")
                        return True
                    except Exception as e:
                        print(f"⚠️  Could not query financial.district table: {str(e)}")
                        print("   This may indicate that the database is not fully set up")
                        return False
                        
                except Exception as uppercase_e:
                    raise Exception(f"Failed with both lowercase and uppercase database names: {lowercase_e}, {uppercase_e}")
                
        except Exception as e:
            print(f"❌ Failed to connect to PostgreSQL database: {str(e)}")
            print("   Check your PostgreSQL connection settings in llm/src/table_schema.py")
            return False
    except ImportError:
        print("❌ psycopg2 package not found. Install it using: pip install psycopg2-binary")
        return False

def check_setup_scripts():
    """Check if the setup scripts exist and are executable."""
    setup_scripts = [
        "setup_mysql.sh",
        "setup_postgresql.sh"
    ]
    
    all_scripts_ok = True
    for script in setup_scripts:
        if os.path.exists(script):
            if os.access(script, os.X_OK):
                print(f"✅ {script} exists and is executable")
            else:
                print(f"⚠️  {script} exists but is not executable. Run: chmod +x {script}")
                all_scripts_ok = False
        else:
            print(f"❌ {script} not found")
            all_scripts_ok = False
    
    return all_scripts_ok

def check_api_config():
    """Check if the API configuration is set up."""
    api_config_file = "llm/run/run_gpt.sh"
    
    if not os.path.exists(api_config_file):
        print(f"❌ API configuration file not found: {api_config_file}")
        return False
    
    with open(api_config_file, 'r') as f:
        content = f.read()
        
    if "YOUR_API_KEY='iai-3crlWUmXc2DtT18evldwse29pRatZnYsSijsz8WTeKc4j3JK'" in content:
        print("✅ API key is configured in run_gpt.sh")
    else:
        print("⚠️  API key may not be configured in run_gpt.sh")
        print("   Please check and update your API key if needed")
    
    if "engine='inf-2-0-32b-sql'" in content:
        print("✅ Model engine is configured in run_gpt.sh")
    else:
        print("⚠️  Model engine may not be configured in run_gpt.sh")
        print("   Please check and update your model engine if needed")
    
    return True

def main():
    """Run all checks."""
    print("====== BIRD-SQL Mini-Dev Setup Check ======")
    
    all_checks_passed = True
    
    print("\n1. Checking required packages...")
    if not check_imports():
        all_checks_passed = False
    
    print("\n2. Checking API configuration...")
    if not check_api_config():
        all_checks_passed = False
    
    print("\n3. Checking setup scripts...")
    if not check_setup_scripts():
        all_checks_passed = False
    
    print("\n4. Checking SQLite databases...")
    if not check_sqlite_databases():
        all_checks_passed = False
    
    print("\n5. Checking evaluation files...")
    if not check_evaluation_files():
        all_checks_passed = False
    
    print("\n6. Checking MySQL connection...")
    mysql_ok = check_mysql_connection()
    if not mysql_ok:
        all_checks_passed = False
    
    print("\n7. Checking PostgreSQL connection...")
    pg_ok = check_postgresql_connection()
    if not pg_ok:
        all_checks_passed = False
    
    print("\n====== Setup Check Complete ======")
    
    if not all_checks_passed:
        print("\n⚠️  Some checks failed. Please review the issues above.")
    
    if not mysql_ok:
        print("\nTo set up MySQL database:")
        print("1. Install MySQL if not already installed")
        print("2. Run the setup script: ./setup_mysql.sh")
        print("3. If you encounter issues, you may need to manually update the connection settings")
        print("   in llm/src/table_schema.py")
    
    if not pg_ok:
        print("\nTo set up PostgreSQL database:")
        print("1. Install PostgreSQL if not already installed")
        print("2. Run the setup script: ./setup_postgresql.sh")
        print("3. If you encounter issues, you may need to manually update the connection settings")
        print("   in llm/src/table_schema.py")
    
    if all_checks_passed:
        print("\n✅ All checks passed! Your setup is complete.")
        print("You can now run the experiments with any of the SQL dialects (SQLite, MySQL, PostgreSQL).")
    else:
        print("\nRecommendations:")
        print("- If you're just getting started, stick with SQLite as it doesn't require a database server")
        print("- For MySQL and PostgreSQL, make sure the database server is running and the BIRD database exists")
        print("- Update the connection details in llm/src/table_schema.py if needed")

if __name__ == "__main__":
    main() 