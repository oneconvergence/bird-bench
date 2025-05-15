#!/bin/bash

# BIRD-SQL Mini-Dev Repository Cleanup Script
# This script removes unnecessary files from the repository

echo "Cleaning up the BIRD-SQL Mini-Dev repository..."

# Remove working_mysql_password.txt (security risk)
if [ -f "working_mysql_password.txt" ]; then
  echo "Removing working_mysql_password.txt (security risk)"
  rm working_mysql_password.txt
fi

# Remove any API config files
if [ -f ".api_config" ]; then
  echo "Removing .api_config (security risk)"
  rm .api_config
fi

# Remove exp_result directories (large results files)
if [ -d "exp_result" ]; then
  echo "Removing exp_result/ directory"
  rm -rf exp_result
fi

if [ -d "llm/exp_result" ]; then
  echo "Removing llm/exp_result/ directory"
  rm -rf llm/exp_result
fi

# Remove eval_result directory (output files)
if [ -d "eval_result" ]; then
  echo "Removing eval_result/ directory"
  rm -rf eval_result
fi

# Create empty directories to maintain structure
mkdir -p llm/exp_result/sql_output
mkdir -p llm/exp_result/sql_output_kg
mkdir -p eval_result

# Remove any SQLite database files (large and can be downloaded)
echo "Removing SQLite database files (*.sqlite)"
find . -name "*.sqlite" -delete

# Remove any MySQL/PostgreSQL dumps (large and can be regenerated)
echo "Removing SQL dump files (large)"
find . -name "BIRD_dev.sql" -size +10M -delete

# Remove any Jupyter notebook checkpoints
echo "Removing Jupyter notebook checkpoints"
find . -name ".ipynb_checkpoints" -type d -exec rm -rf {} +

# Remove any __pycache__ directories
echo "Removing Python cache directories"
find . -name "__pycache__" -type d -exec rm -rf {} +
find . -name "*.pyc" -delete

# Create a .gitkeep file in empty directories to maintain structure
find . -type d -empty -exec touch {}/.gitkeep \;

echo "Creating standard GitHub templates"

# Create a simple PR template
mkdir -p .github/PULL_REQUEST_TEMPLATE
cat << EOF > .github/PULL_REQUEST_TEMPLATE/pull_request_template.md
## Description
<!-- Describe your changes in detail -->

## Related Issue
<!-- Reference any related issues -->

## Motivation and Context
<!-- Why is this change needed? What problem does it solve? -->

## Testing
<!-- Describe how you tested your changes -->

## Checklist
- [ ] I have read the CONTRIBUTING.md document
- [ ] My code follows the code style of this project
- [ ] I have added or updated relevant documentation
- [ ] I have tested my changes with all SQL dialects
EOF

# Create a simple issue template
mkdir -p .github/ISSUE_TEMPLATE
cat << EOF > .github/ISSUE_TEMPLATE/bug_report.md
---
name: Bug report
about: Create a report to help us improve
title: ''
labels: bug
assignees: ''
---

## Describe the bug
<!-- A clear and concise description of what the bug is -->

## To Reproduce
Steps to reproduce the behavior:
1. ...
2. ...
3. ...

## Expected behavior
<!-- What you expected to happen -->

## Actual behavior
<!-- What actually happened -->

## Screenshots
<!-- If applicable, add screenshots to help explain your problem -->

## Environment
- OS: [e.g. macOS, Ubuntu]
- Python version:
- Database version(s):
EOF

cat << EOF > .github/ISSUE_TEMPLATE/feature_request.md
---
name: Feature request
about: Suggest an idea for this project
title: ''
labels: enhancement
assignees: ''
---

## Is your feature request related to a problem? Please describe
<!-- A clear and concise description of what the problem is -->

## Describe the solution you'd like
<!-- A clear and concise description of what you want to happen -->

## Describe alternatives you've considered
<!-- A clear and concise description of any alternative solutions or features you've considered -->

## Additional context
<!-- Add any other context or screenshots about the feature request here -->
EOF

echo "Cleanup complete!"
echo "Remember to add any specific files you want to keep before committing." 