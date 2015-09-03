#!/bin/sh

MD5_FILE="md5sum.txt"
BCKP_DIR=$HOME/backup_folder
LIST_BACKUP_DIR=`find $HOME/backup_folder/ -name "$MD5_FILE" -exec dirname {} \;`

for UN in $LIST_BACKUP_DIR
do
    if [ -f "$UN/md5sum.txt" ]; then
	cd $UN
	md5sum -c $MD5_FILE
	cd - > /dev/null
    fi
done
