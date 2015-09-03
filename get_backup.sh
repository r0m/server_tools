#!/bin/sh

# server name must exist in .ssh/config
SRVLIST="serv1 serv2"
DATE_TODAY=`date +%Y%m%d`

for UN in $SRVLIST
do
    BACKUP_ARCHIVE="${UN}_backup_${DATE_TODAY}.tar.gz"
    MD5SUM_ARCHIVE="${UN}_backup_${DATE_TODAY}.md5"
    BACKUP_DIR="$HOME/backup/vm_${UN}"
    # ToDo check if rsync command is ok (with $?) and after erase archive on server
    # else exit in error exit 1
    echo $HOME/.ssh/config
    CHECK_EXIST=`ssh $UN "if [ -e ~/backup/${BACKUP_ARCHIVE} ] && [ -e ~/backup/${MD5SUM_ARCHIVE} ] ; then echo 0; else echo 1; fi"`
    if [ $CHECK_EXIST -eq 0 ];
    then
	rsync -avz -e "ssh -F $HOME/.ssh/config" $UN:~/backup/${BACKUP_ARCHIVE} ${BACKUP_DIR}
	rsync -avz -e "ssh -F $HOME/.ssh/config" $UN:~/backup/${MD5SUM_ARCHIVE} ${BACKUP_DIR}

	ssh $UN "rm -f ~/backup/$BACKUP_ARCHIVE ~/backup/$MD5SUM_ARCHIVE"

	if [ -f "${BACKUP_DIR}/$MD5SUM_ARCHIVE" ]; then
	    cat ${BACKUP_DIR}/$MD5SUM_ARCHIVE >> ${BACKUP_DIR}/md5sum.txt
	    rm -f ${BACKUP_DIR}/$MD5SUM_ARCHIVE
	fi
    
	find ${BACKUP_DIR}/ -name "${UN}_backup_*.tar.gz" -mtime +10 -exec rm -f {} \;
    
	LIST_ARCHIVE=`cat ${BACKUP_DIR}/md5sum.txt | sed -e 's/ \+/ /g' | cut -d' ' -f2`
	for ARCHI in $LIST_ARCHIVE
	do
	    if [ ! -f "${BACKUP_DIR}/$ARCHI" ]; then
		sed -e "/$ARCHI/d" -i ${BACKUP_DIR}/md5sum.txt
	    fi
	done
    else
	echo "Error no available backup on $UN"
    fi
done
