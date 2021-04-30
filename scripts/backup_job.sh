#!/bin/sh

# first - do the DB backup (if confgured)
/usr/bin/backup_db.sh

# now to the borg backup
/usr/bin/borg_backup.sh


exit 0
