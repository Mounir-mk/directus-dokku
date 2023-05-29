#!/bin/bash
set -e

# Script introduction and user agreement
echo "This script is meant for a Directus instance deployment with Dokku."
echo "Do you want to continue? (yes/no)"
read CONTINUE_SCRIPT

if [ "$CONTINUE_SCRIPT" != "yes" ]; then
    echo "Aborting script..."
    exit 1
fi

# Ask for user input
echo "Enter the name of the app:"
read APP_NAME

echo "Enter admin email:"
read ADMIN_EMAIL

echo "Enter admin password:"
read -s ADMIN_PASSWORD

echo "Do you want to use a postgres database instead of sqlite 3? (yes/no)"
read USE_POSTGRES

echo "Do you want to use redis for caching? (yes/no)"
read USE_REDIS

echo "Do you want to set up an email service? (yes/no)"
read SETUP_EMAIL_SERVICE

# Create app
echo "Creating app..."
dokku apps:create $APP_NAME
echo "App created successfully!"

# Setup proxy ports
echo "Setting up proxy ports..."
dokku proxy:ports-add $APP_NAME http:80:8055
dokku proxy:ports-remove $APP_NAME http:80:5000
echo "Proxy ports set up successfully!"

# Setup storage
echo "Mounting a volume for uploads..."
mkdir -p /var/lib/dokku/data/storage/$APP_NAME-uploads
chown -R dokku:dokku /var/lib/dokku/data/storage/$APP_NAME-uploads
dokku storage:mount $APP_NAME /var/lib/dokku/data/storage/$APP_NAME-uploads:/directus/uploads
echo "Volume mounted successfully!"

# Setup Postgres if user chose to
if [ "$USE_POSTGRES" = "yes" ]; then
    # Check if postgres plugin exists
    if [ ! -d "/var/lib/dokku/plugins/available/postgres" ]; then
        echo "Postgres plugin not present, downloading it..."
        sudo dokku plugin:install https://github.com/dokku/dokku-postgres.git postgres
    fi

    dokku postgres:create $APP_NAME-db
    dokku postgres:link $APP_NAME-db $APP_NAME --no-restart "false"

    PG_URL="$(dokku config:get $APP_NAME DATABASE_URL)"
    DB_USER=$(echo $PG_URL | cut -d':' -f2 | sed 's|//||g')
    DB_PASSWORD=$(echo $PG_URL | cut -d':' -f3 | cut -d'@' -f1)
    DB_HOST=$(echo $PG_URL | cut -d'@' -f2 | cut -d':' -f1)
    DB_PORT=$(echo $PG_URL | cut -d':' -f4 | cut -d'/' -f1)
    DB_DATABASE=$(echo $PG_URL | cut -d'/' -f4)

    # Set the Postgres config variables
    dokku config:set --no-restart $APP_NAME \
        DB_CLIENT=pg \
        DB_HOST=$DB_HOST \
        DB_PORT=$DB_PORT \
        DB_USER=$DB_USER \
        DB_PASSWORD=$DB_PASSWORD \
        DB_DATABASE=$DB_DATABASE
fi

# Setup Redis if user chose to
if [ "$USE_REDIS" = "yes" ]; then
    # Check if redis plugin exists
    if [ ! -d "/var/lib/dokku/plugins/available/redis" ]; then
        echo "Redis plugin not present, downloading it..."
        sudo dokku plugin:install https://github.com/dokku/dokku-redis.git redis
    fi

    dokku redis:create $APP_NAME-cache
    dokku redis:link $APP_NAME-cache $APP_NAME --no-restart "false"

    REDIS_URL="$(dokku config:get $APP_NAME REDIS_URL)"

    # Set the Redis config variables
    dokku config:set --no-restart $APP_NAME \
        CACHE_REDIS=$REDIS_URL \
        CACHE_ENABLED=true \
        CACHE_STORE=redis
fi

# Setup email service if user chose to
if [ "$SETUP_EMAIL_SERVICE" = "yes" ]; then
    echo "Enter your SMTP host:"
    read SMTP_HOST

    echo "Enter your SMTP port:"
    read SMTP_PORT

    echo "Enter your SMTP user:"
    read SMTP_USER

    echo "Enter your SMTP password:"
    read -s SMTP_PASSWORD

    # Set the email config variables
    dokku config:set --no-restart $APP_NAME \
        EMAIL_FROM="$ADMIN_EMAIL" \
        EMAIL_TRANSPORT="smtp" \
        EMAIL_SMTP_HOST="$SMTP_HOST" \
        EMAIL_SMTP_PORT="$SMTP_PORT" \
        EMAIL_SMTP_USER="$SMTP_USER" \
        EMAIL_SMTP_PASSWORD="$SMTP_PASSWORD"
fi

# Set the remaining config variables
KEY=$(uuidgen)
SECRET=$(uuidgen)

dokku docker-options:add $APP_NAME deploy "\
-e KEY=$KEY \
-e SECRET=$SECRET \
-e ADMIN_EMAIL=$ADMIN_EMAIL \
-e ADMIN_PASSWORD=$ADMIN_PASSWORD \
"

# Deploy the app
dokku git:from-image $APP_NAME directus/directus

echo "App deployed successfully!"
