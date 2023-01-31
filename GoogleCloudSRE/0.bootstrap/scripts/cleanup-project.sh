#!/bin/bash

# Usage:
# bash scripts/cleanup-project.sh

# Resource Group name updated by  validate-requirements.sh
DELETE_PROJECT=

echo ""
echo ""
read -p "- 🧹 Deployment Cleanup (y/n)? " answer
    case ${answer:0:1} in
    y|Y )
        echo -e "\e[31m»»» 🧹 Cleanup Deployment...\e[0m\n"
        echo -e "\e[31m\t 💣 Deleting Project - $DELETE_PROJECT...\e[0m\n"

    ;;
    * )
        echo -e "\e[31m»»»  🚫 Cleanup Skipped...\e[0m\n"
        exit
    ;;
esac