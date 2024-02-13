#!/bin/bash
NOTIFICATION_SLACK_HOOK_URL="$NOTIFICATION_SLACK_HOOK_URL"
NOTIFICATION_SLACK_IDENTIFIER="$NOTIFICATION_SLACK_IDENTIFIER"
# #### $1=EXIT_CODE (After running backup routine)
# #### $2=DB_TYPE (Type of Backup)
# #### $3=DB_HOST (Backup Host)
# #### #4=DB_NAME (Name of Database backed up
# #### $5=BACKUP START TIME (Seconds since Epoch)
# #### $6=BACKUP FINISH TIME (Seconds since Epoch)
# #### $7=BACKUP TOTAL TIME (Seconds between Start and Finish)
# #### $8=BACKUP FILENAME (Filename)
# #### $9=BACKUP FILESIZE
# #### $10=HASH (If CHECKSUM enabled)
# #### $11=MOVE_EXIT_CODE
EXIT_CODE=$1
DB_TYPE=$2
DB_HOST=$3
DB_NAME=$4
BACKUP_START_TIME=$5
BACKUP_FINISH_TIME=$6
BACKUP_TOTAL_TIME=$7
BACKUP_FILENAME=$8
BACKUP_FILESIZE=$9
HASH=${10}
MOVE_EXIT_CODE=${11}

# Construire le message JSON
message="{\"text\":\"ATTENTION! le fichier : ${BACKUP_FILENAME} ne fait que ${BACKUP_FILESIZE} octets, la backup est sûrement VIDE.\",\"username\": \"${NOTIFICATION_SLACK_IDENTIFIER}\"}"

# Envoyer la notification à Slack si en dessous de 50bytes
if [ $BACKUP_FILESIZE -lt 50 ];
then
  curl -X POST -H "Content-Type: application/json" -d "$message" $NOTIFICATION_SLACK_HOOK_URL
fi
