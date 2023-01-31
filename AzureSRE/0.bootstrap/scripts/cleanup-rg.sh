#!/bin/bash

# Usage:
# bash scripts/cleanup-rg.sh

# Resource Group name updated by  validate-requirements.sh
DELETE_RG=

echo ""
echo ""
read -p "- 🧹 Deployment Cleanup (y/n)? " answer
    case ${answer:0:1} in
    y|Y )
        echo -e "\e[31m»»» 🧹 Cleanup Deployment...\e[0m\n"
        echo -e "\e[31m\t 💣 Deleting Resource Group - $DELETE_RG...\e[0m\n"
        az group delete --name $DELETE_RG
    ;;
    * )
        echo -e "\e[31m»»»  🚫 Cleanup Skipped...\e[0m\n"
        exit
    ;;
esac