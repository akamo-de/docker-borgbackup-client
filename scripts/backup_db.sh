#!/bin/sh
# MYSQL_HOST
# MYSQL_PORT
# MYSQL_USER
# MYSQL_PASS
# MYSQL_INCLUDE_DB
# MYSQL_EXCLUDE_DB

export BACKUPDIR="/backup/db"
export DUMP_EXT='.data.sql'
export SCHEMA_EXT='.schema.sql'
export LOG_EXT='.log'

if [ -f /etc/mysqlbackup_env ]
then
. /etc/mysqlbackup_env
# remove old backup (if any)
find "$BACKUPDIR" -maxdepth 1 -mindepth 1 -type d -exec rm -rf {} \;


if [ -z "$MYSQL_INCLUDE_DB" ]
then
  DBS="$(echo "show databases" | /usr/bin/mysql -LN -u $MYSQL_USER -p$MYSQL_PASS -h $MYSQL_HOST --port=$MYSQL_PORT)"
else
  DBS="$(echo $MYSQL_INCLUDE_DB)"
fi

for DB in $DBS
do
  echo "$MYSQL_EXCLUDE_DB" | grep -qw "$DB" && continue

  mkdir -p "$BACKUPDIR/$DB"
  echo "show tables" | /usr/bin/mysql -LN -u $MYSQL_USER -p$MYSQL_PASS -h $MYSQL_HOST --port=$MYSQL_PORT $DB| while read TABLE
  do
    SCHAMA_OUT="$(/usr/bin/mysqldump --no-data -u $MYSQL_USER -p$MYSQL_PASS -h $MYSQL_HOST --port=$MYSQL_PORT $DB $TABLE -r "$BACKUPDIR/$DB/$TABLE$SCHEMA_EXT" 2>&1)"
    SCHEMA_RETURN="$?"
    DATA_OUT="$(/usr/bin/mysqldump --no-create-info --no-create-db --compact --skip-triggers -u $MYSQL_USER -p$MYSQL_PASS -h $MYSQL_HOST --port=$MYSQL_PORT $DB $TABLE -r "$BACKUPDIR/$DB/$TABLE$DUMP_EXT" 2>&1)"
    DATA_RETURN="$?"
    echo "############ $(date) $DB/$TABLE SCHEMA DUMP ############" > "$BACKUPDIR/$DB/$TABLE$LOG_EXT"
    echo "$SCHAMA_OUT" >> "$BACKUPDIR/$DB/$TABLE$LOG_EXT"
    echo "" >> "$BACKUPDIR/$DB/$TABLE$LOG_EXT"
    echo "mysqldump returned $SCHEMA_RETURN" >> "$BACKUPDIR/$DB/$TABLE$LOG_EXT"
    echo "" >> "$BACKUPDIR/$DB/$TABLE$LOG_EXT"
    echo "" >> "$BACKUPDIR/$DB/$TABLE$LOG_EXT"
    echo "############ $(date) $DB/$TABLE DATA DUMP ############" >> "$BACKUPDIR/$DB/$TABLE$LOG_EXT"
    echo "$DATA_OUT" >> "$BACKUPDIR/$DB/$TABLE$LOG_EXT"
    echo "" >> "$BACKUPDIR/$DB/$TABLE$LOG_EXT"
    echo "mysqldump returned $DATA_RETURN" >> "$BACKUPDIR/$DB/$TABLE$LOG_EXT"
  done
done

fi
