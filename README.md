# Dokku Directus Scripts

This repository contains two scripts for facilitating the deployment and deletion of a Directus instance on Dokku.

## Prerequisites

- You should have Dokku installed and configured on your server.

## Usage

### Deploying a Directus Instance

To deploy a Directus instance, you can use the `deploy-directus.sh` script. You can run it remotely from this repository with the following command:

```bash
bash <(curl -s https://raw.githubusercontent.com/Mounir-mk/directus-dokku-deployment/main/deploy.sh)
```

The script will prompt you for the necessary information for the deployment, including the app name, admin email and password, and whether you want to use Postgres and Redis.

### Deleting a Directus Instance

If you wish to delete a Directus instance that you have deployed with the deployment script, you can use the destroy.sh script. You can run it remotely from this repository with the following command:

```bash
bash <(curl -s https://raw.githubusercontent.com/Mounir-mk/directus-dokku-deployment/main/destroy.sh)
```

The script will ask for confirmation before deleting the app and associated services.

## WARNING

These scripts are provided as-is and without warranty. They are intended for use on a fresh Dokku installation. If you have existing apps or services on your Dokku instance, these scripts may cause issues. Please use with caution.
