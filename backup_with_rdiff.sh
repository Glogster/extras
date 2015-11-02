#!/bin/bash

SERVERNAME=$1
MAILTO="Glogster Backup <backups@glogster.com>"
LOGFILE="/var/log/backup.log"
LOCK="/opt/backup/lock.$SERVERNAME"
TARGETS="/opt/backup/targets"
LOCALDESTDIR="/mnt/backup"
KEEP='14D'
SENDMAIL=n

date +"Subject: Backup $SERVERNAME log (%Y-%m-%d)" > $LOGFILE
echo -e "From: Backup <backups@glogstergroup.com>" >>$LOGFILE
echo -e "To: $MAILTO\n" >>$LOGFILE

if [ -f "$LOCK" ]; then
	date +"##### %Y-%m-%d %T %a : Backup error: Previous backup still running. #####" >> $LOGFILE
	SENDMAIL=y
elif ! mountpoint -q "$LOCALDESTDIR"; then
	date +"##### %Y-%m-%d %T %a : Backup error: Local directory is not mounted. #####" >> $LOGFILE
	SENDMAIL=y
else

	touch "$LOCK"

	date +"##### %Y-%m-%d %T %a : Backup begin #####" >> $LOGFILE
	echo -e "\n" >>$LOGFILE


	rdiff-backup  --force -v2 --exclude-symbolic-links --print-statistics \
	             --include-globbing-filelist $TARGETS --exclude / \
	             / $LOCALDESTDIR >>$LOGFILE 2>&1

	echo -e "\n" >>$LOGFILE

	rdiff-backup -v3 --force --remove-older-than $KEEP $LOCALDESTDIR >>$LOGFILE 2>&1

	echo -e "\n" >>$LOGFILE
	date +"##### %Y-%m-%d %T %a : Backup end #####" >> $LOGFILE

	rm -f "$LOCK"

fi

echo -e "\n" >>$LOGFILE
date +"##### %Y-%m-%d %T %a : Backup end #####" >> $LOGFILE

if [ $SENDMAIL = "y" ]; then
	/usr/sbin/sendmail -t < $LOGFILE
fi

exit 0
