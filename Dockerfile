FROM alpine:3.13
LABEL Maintainer="Mario Lombardo <ml@akamo.de>" \
      Description="Lightweight container for backup data and database"

# Install packages and remove default server definition
RUN apk --no-cache add supervisor borgbackup openssh-client dcron mariadb-client

# Configure supervisord
COPY config/supervisord.conf /etc/supervisord.conf
COPY scripts/init.sh /init.sh
COPY scripts/backup_db.sh /usr/bin/backup_db.sh
COPY scripts/borg_backup.sh /usr/bin/borg_backup.sh
COPY scripts/backup_job.sh /usr/bin/backup_job.sh

# Setup document root
RUN mkdir -p /backup/config
RUN mkdir -p /backup/data
RUN mkdir -p /backup/db

# Let supervisord start cron
CMD ["/init.sh"]

# Configure a healthcheck to validate that everything is up&running
HEALTHCHECK --timeout=10s CMD /usr/bin/supervisorctl status || exit 1
