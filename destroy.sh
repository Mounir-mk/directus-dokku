#!/bin/bash
set -e

# Script introduction and user agreement
echo "This script is meant for a Directus instance deletion inside Dokku."
echo "This script will delete the app, the database, the cache and the uploads folder."
echo "Do you want to continue? (yes/no)"
read CONTINUE_SCRIPT

if [ "$CONTINUE_SCRIPT" != "yes" ]; then
    echo "Aborting script..."
    exit 1
fi

# Ask for user input
echo "Enter the name of the app:"
read APP_NAME

# Delete app

dokku apps:destroy $APP_NAME
dokku postgres:destroy $APP_NAME-db
dokku redis:destroy $APP_NAME-cache

rm -rf /var/lib/dokku/data/storage/$APP_NAME-uploads

echo "App deleted successfully!"
