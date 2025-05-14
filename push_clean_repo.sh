#!/bin/bash

# BIRD-SQL Mini-Dev Push Clean Repository Script
# This script cleans up the repository and pushes it to a remote GitHub repository

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}==================================================${NC}"
echo -e "${BLUE}      BIRD-SQL Mini-Dev Repository Cleanup        ${NC}"
echo -e "${BLUE}==================================================${NC}"

# Run the cleanup script
echo -e "${BLUE}Running cleanup script...${NC}"
chmod +x cleanup.sh
./cleanup.sh

# Verify the remote repository
echo -e "${BLUE}Checking Git configuration...${NC}"
if ! git remote -v | grep -q origin; then
  echo -e "${YELLOW}No remote repository configured.${NC}"
  read -p "Enter your GitHub repository URL (e.g., https://github.com/username/mini_dev.git): " repo_url
  git remote add origin "$repo_url"
  echo -e "${GREEN}Remote repository added: $repo_url${NC}"
else
  echo -e "${GREEN}Remote repository already configured:${NC}"
  git remote -v
fi

# Ask for confirmation
echo -e "${YELLOW}This will push changes to the remote repository.${NC}"
read -p "Are you sure you want to continue? (y/n): " confirm
if [[ "$confirm" != "y" ]]; then
  echo -e "${RED}Operation cancelled.${NC}"
  exit 1
fi

# Add new files
echo -e "${BLUE}Adding files to Git...${NC}"
git add .

# Commit changes
echo -e "${BLUE}Committing changes...${NC}"
read -p "Enter a commit message: " commit_message
if [[ -z "$commit_message" ]]; then
  commit_message="Clean repository structure"
fi
git commit -m "$commit_message"

# Push to remote
echo -e "${BLUE}Pushing to remote repository...${NC}"
git push -u origin main || git push -u origin master

echo -e "${GREEN}Repository has been cleaned and pushed!${NC}"
echo -e "${BLUE}==================================================${NC}"

# Display next steps
echo -e "${BLUE}Next steps:${NC}"
echo -e "1. Verify your repository on GitHub"
echo -e "2. Update your README.md with actual repo URLs"
echo -e "3. Set up GitHub Pages if desired"
echo -e "${BLUE}==================================================${NC}" 