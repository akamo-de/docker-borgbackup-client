#!/bin/sh

export ERROR=0

if [ -n "$BACKUP_MYSQL" ]; then
echo "export MYSQL_HOST='$BACKUP_MYSQL'" > /etc/mysqlbackup_env
echo "export MYSQL_PORT='$BACKUP_MYSQL_PORT'" >> /etc/mysqlbackup_env
echo "export MYSQL_USER='$BACKUP_MYSQL_USER'" >> /etc/mysqlbackup_env
echo "export MYSQL_PASS='$BACKUP_MYSQL_PASS'" >> /etc/mysqlbackup_env
echo "export MYSQL_INCLUDE_DB='$BACKUP_MYSQL_INCLUDE_DB'" >> /etc/mysqlbackup_env
echo "export MYSQL_EXCLUDE_DB='$BACKUP_MYSQL_EXCLUDE_DB'" >> /etc/mysqlbackup_env
chmod 400 /etc/mysqlbackup_env
fi

if [ -z "$BACKUP_DESTINATION_SSH_SERVER" ]; then
	export ERROR=1
fi

if [ -z "$BACKUP_DESTINATION_SSH_PORT" ]; then
	export BACKUP_DESTINATION_SSH_PORT=22
fi

if [ -z "$BACKUP_DESTINATION_SSH_LOCATION" ]; then
	export BACKUP_DESTINATION_SSH_LOCATION='~'
fi

if [ -z "$BACKUP_DESTINATION_SSH_USER" ]; then
	export BACKUP_DESTINATION_SSH_USER=backup
fi

if [ -z "$BACKUP_DESTINATION_SSH_KEY" ]; then
	export ERROR=1
fi

if [ -z "$BACKUP_DESTINATION_BORG_PASSPHRASE" ]; then
	export ERROR=1
fi
if [ -z "$BACKUP_BORG_KEEP_SECONDLY" ]; then
	export BACKUP_BORG_KEEP_SECONDLY=0
fi
if [ -z "$BACKUP_BORG_KEEP_MINUTELY" ]; then
	export BACKUP_BORG_KEEP_MINUTELY=0
fi
if [ -z "$BACKUP_BORG_KEEP_HOURLY" ]; then
	export BACKUP_BORG_KEEP_HOURLY=0
fi
if [ -z "$BACKUP_BORG_KEEP_DAILY" ]; then
	export BACKUP_BORG_KEEP_DAILY=0
fi
if [ -z "$BACKUP_BORG_KEEP_WEEKLY" ]; then
	export BACKUP_BORG_KEEP_WEEKLY=0
fi
if [ -z "$BACKUP_BORG_KEEP_MONTHLY" ]; then
	export BACKUP_BORG_KEEP_MONTHLY=0
fi
if [ -z "$BACKUP_BORG_KEEP_YEARLY" ]; then
	export BACKUP_BORG_KEEP_YEARLY=0
fi
if [ -z "$BACKUP_JOB_CRON_DEFINITION" ]; then
	export BACKUP_JOB_CRON_DEFINITION='0	3	*	*	*'
fi

if [ "$ERROR" -eq "0" ]; then
echo "$BACKUP_DESTINATION_SSH_KEY" | base64 -d |gunzip > /etc/id_rsa_backup
chmod 400 /etc/id_rsa_backup
echo "${BACKUP_JOB_CRON_DEFINITION}       /usr/bin/backup_job.sh" >> /etc/crontabs/root
echo "export BORG_REPO=\"ssh://$BACKUP_DESTINATION_SSH_USER@$BACKUP_DESTINATION_SSH_SERVER:$BACKUP_DESTINATION_SSH_PORT/$BACKUP_DESTINATION_SSH_LOCATION\"" > /etc/borgbackup_env
echo "export BORG_RSH=\"ssh -i /etc/id_rsa_backup -o StrictHostKeyChecking=no\"" >> /etc/borgbackup_env
echo "export BORG_PASSPHRASE='$BACKUP_DESTINATION_BORG_PASSPHRASE'" >> /etc/borgbackup_env
echo "export KEEP_SECONDLY=$BACKUP_BORG_KEEP_SECONDLY" >> /etc/borgbackup_env
echo "export KEEP_MINUTELY=$BACKUP_BORG_KEEP_MINUTELY" >> /etc/borgbackup_env
echo "export KEEP_HOURLY=$BACKUP_BORG_KEEP_HOURLY" >> /etc/borgbackup_env
echo "export KEEP_DAILY=$BACKUP_BORG_KEEP_DAILY" >> /etc/borgbackup_env
echo "export KEEP_WEEKLY=$BACKUP_BORG_KEEP_WEEKLY" >> /etc/borgbackup_env
echo "export KEEP_MONTHLY=$BACKUP_BORG_KEEP_MONTHLY" >> /etc/borgbackup_env
echo "export KEEP_YEARLY=$BACKUP_BORG_KEEP_YEARLY" >> /etc/borgbackup_env
fi

mkdir -p /var/run/supervisor
chmod 777 /var/run/supervisor
/usr/bin/supervisord -c /etc/supervisord.conf
