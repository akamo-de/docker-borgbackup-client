# Dockerized Backup Client using Borg and OpenSSH

## Introduction
An easy way to run borg backup in a container with isolated SSH server. This is the client container. The use case is adding this container to your docker-compose.yml. So you can add volumes to be backed up to the client and in addition you can add a mysql/mariadb configuration.

## Software

 * [borg backup](https://borgbackup.readthedocs.io/): Backup software that is doing the actual software
 * [ed25519](https://ed25519.cr.yp.to/): Curve25519 is an elliptic curve offering 128 bits of security (256 bits key size); used within the SSH server

## Setup

### Mysql/MariaDB

If you need to backup a database as well, you can add the server and credentials to the configuration and the container will frequently make a dump of your database (before each backup). Typically a DB in your docker-compose environment is to be backuped that way.

To enable the container the backup, a backup user in your DB is required. This can be done for example like this:

~~~

CREATE USER 'dbbackup'@'%'
    IDENTIFIED BY 'topSecretDBPassword';

GRANT SELECT, SHOW VIEW, LOCK TABLES, RELOAD, REPLICATION CLIENT, SHOW DATABASES
        ON *.* TO 'dbbackup'@'%';

FLUSH PRIVILEGES;
~~~

The backups are created in `/backup/db/<database-name>/<table>.(schema.sql|data.sql|log)` (inside the container).

Each **`<filename>.schema.sql`** file contains the Schema of the related table, table, the **`<filename>.data.sql`** obviously contains the data and the **`<filename>.log`** contains the log output of the dump process.



### Docker-Compose:

> Add this to you docker-compose.yml file. The following template may be changed on your demand:

~~~
version: '2'
services:
    my-borg-backup-client:
    container_name: my-borg-backup-client
    image: akamo/borgbackup-client:latest
    restart: always
    environment:
      BACKUP_MYSQL: db-server
      BACKUP_MYSQL_PORT: 3306
      BACKUP_MYSQL_USER: dbbackup
      BACKUP_MYSQL_PASS: topSecretDBPassword
      BACKUP_MYSQL_INCLUDE_DB:
      BACKUP_MYSQL_EXCLUDE_DB:
      BACKUP_DESTINATION_SSH_SERVER: server.running.borg.as.server.org
      BACKUP_DESTINATION_SSH_PORT: 12345
      BACKUP_DESTINATION_SSH_LOCATION: ~
      BACKUP_DESTINATION_SSH_USER: backup
      BACKUP_DESTINATION_SSH_KEY: "asdfghjklqwertzuiyxcvbnm=="
      BACKUP_DESTINATION_BORG_PASSPHRASE: borgSecretOfRepo
      BACKUP_JOB_CRON_DEFINITION: '5	1	*	*	*'
    volumes:
      - /srv/production/fileserver:/backup/data/files:ro
      - /srv/production/webserver:/backup/data/web:ro
    external_links:
      - db-server:db-server
~~~

Changing the environment may affect the following behaviour:

**BACKUP_MYSQL**: This is the host of the database server. Actually this should be a docker-compose service name of the database container (like 'my-borg-backup-client' for this backup service), because within a composed envionment you can always talk to the service names directly (optional, if mysql/mariadb backups are required).

**BACKUP_MYSQL_PORT**: If DB mysql/mariadb are required, the client requires the server port of the database here (optional).

**BACKUP_MYSQL_USER**: If DB mysql/mariadb are required, here is the user name for the database required (optional).

**BACKUP_MYSQL_PASS**: If DB mysql/mariadb are required, here is the password for the database required (optional).

**BACKUP_MYSQL_INCLUDE_DB**: If DB mysql/mariadb are required and this value should be a space separated list if databases to be dumped before each backup. If empty, all databases are selected (optional).

**BACKUP_MYSQL_EXCLUDE_DB**: If DB mysql/mariadb are required and this value should be a space separated list if databases to be skipped while dumping before each backup. This list reduces the **BACKUP_MYSQL_INCLUDE_DB** list (optional).

**BACKUP_DESTINATION_SSH_SERVER**: This value is defining the borg backup destination host. Typically this may run the [docker-borgbackup-server](https://github.com/akamo-de/docker-borgbackup-server) and has its ssh backup port forwareded (required).

**BACKUP_DESTINATION_SSH_PORT**: This value is defining the borg backup destination port. If you run a standard borg installation, this is your ssh server port. If your are running a [docker-borgbackup-server](https://github.com/akamo-de/docker-borgbackup-server) (recommended), this is the published port of the ssh service of that container (required).

**BACKUP_DESTINATION_SSH_LOCATION**: This value is defining the borg backup destination location. If you run a standard borg installation, this value points to the repo in the backup users home (`~repo/` for example). If your are running a [docker-borgbackup-server](https://github.com/akamo-de/docker-borgbackup-server) (recommended), the repo location is the home directory (`~`)(required).

**BACKUP_DESTINATION_SSH_USER**: This value is defining the borg backup destination user. If you run a standard borg installation, this value is the username on your server (`mybackupuser` for example). If your are running a [docker-borgbackup-server](https://github.com/akamo-de/docker-borgbackup-server) (recommended), the user is always `backup`(required).

**BACKUP_DESTINATION_SSH_KEY**: This is the base64 coded and compressed private key of the backup user for ssh authentication. On a standard borg installation, create it this way (as backup user): `cat ~/.ssh/id_rsa | gzip | base64 -w0`. Using the [docker-borgbackup-server](https://github.com/akamo-de/docker-borgbackup-server) a key for each backup destination container is generated and a ready to use string stored on the destination host here: `/path/to/local/persistance/directory/backup_id_enc` (required).

**BACKUP_DESTINATION_BORG_PASSPHRASE**: Here is the password exptected that was used during creation of the borg repository (not the ssh password!). If you are using [docker-borgbackup-server](https://github.com/akamo-de/docker-borgbackup-server), this is the key provided using **BORG_PASSPHRASE** on the server or (unless deleted) inside this file: `/path/to/local/persistance/directory/borg_pwd` (required).

**BACKUP_JOB_CRON_DEFINITION**: This expects the cron configuration for the execution of the backup jobs (Minute, Hour, DayOfMonth, Month, DayOfWeek). The example `5	1	*	*   *` means every day at 01:05 (AM).

### Hint how to use volumes

The backup in the container is creating a backup for everything that is mounted inside `/backup`. The folder db (`/backup/db`) is reserved as the DB dumps are stored here. So it is a good idea to mount volumes that should be included as subfolder of `/backup/data`. Mounting them read-only is sufficient for backup.


If you need support - please ask [us](https://akamo.de).
