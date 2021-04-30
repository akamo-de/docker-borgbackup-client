#!/bin/sh

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

if [ -f /etc/borgbackup_env ]
then
. /etc/borgbackup_env

/usr/bin/borg create                \
    --verbose                       \
    --filter AME                    \
    --list                          \
    --stats                         \
    --show-rc                       \
    --compression lzma              \
    --exclude-caches                \
    ::'BACKUP-{now}'                \
    /backup/data

backup_exit=$?

export KEEP_POLICY=""

if [ "$KEEP_SECONDLY" -gt "0" ]; then
  export KEEP_POLICY="$KEEP_POLICY --keep-secondly $KEEP_SECONDLY"
fi
if [ "$KEEP_MINUTELY" -gt "0" ]; then
  export KEEP_POLICY="$KEEP_POLICY --keep-minutely $KEEP_MINUTELY"
fi
if [ "$KEEP_HOURLY" -gt "0" ]; then
  export KEEP_POLICY="$KEEP_POLICY --keep-hourly $KEEP_HOURLY"
fi
if [ "$KEEP_DAILY" -gt "0" ]; then
  export KEEP_POLICY="$KEEP_POLICY --keep-daily $KEEP_DAILY"
fi
if [ "$KEEP_WEEKLY" -gt "0" ]; then
  export KEEP_POLICY="$KEEP_POLICY --keep-weekly $KEEP_WEEKLY"
fi
if [ "$KEEP_MONTHLY" -gt "0" ]; then
  export KEEP_POLICY="$KEEP_POLICY --keep-monthly $KEEP_MONTHLY"
fi
if [ "$KEEP_YEARLY" -gt "0" ]; then
  export KEEP_POLICY="$KEEP_POLICY --keep-yearly $KEEP_YEARLY"
fi

if [ -z "$KEEP_POLICY" ]; then
  ## default
  export KEEP_POLICY='--keep-daily 7 --keep-weekly 4 --keep-monthly 6'
fi

/usr/bin/borg prune                 \
    --list                          \
    --prefix 'BACKUP-'              \
    --show-rc                       \
    $KEEP_POLICY

prune_exit=$?

fi
