#!/bin/sh
# this script is based on https://help.ubuntu.com/lts/serverguide/backup-shellscripts.html

if [ $(id -u) != 0 ]; then
    echo "You must launch this in root mode" 1>&2
    exit 1
fi

TMP_DBDIR="/tmp/databases"
DATATOBCKP="$TMP_DBDIR folder1 folder2 file1 file2"
BCKP_USER="sshuser"
BCKP_DIR="/home/${BCKP_USER}/backup"
BCKP_NAME=`cat /etc/hostname`_backup_`date +%Y%m%d`
MYSQL_CONFIG="/etc/mysql/debian.cnf"
DBTOBCKP=`mysql --defaults-file=$MYSQL_CONFIG -Nse "show databases;" | grep -vP "(information_schema|mysql|performance_schema)"`
TARGET=${BCKP_DIR}/${BCKP_NAME}

if [ -e "${TARGET}.tar.gz" ] || [ -e "${TARGET}.md5" ];
then
    rm -rf ${TARGET}.tar.gz ${TARGET}.md5
fi

mkdir -p $TMP_DBDIR
for DB in $DBTOBCKP
do
    mysqldump --defaults-file=$MYSQL_CONFIG $DB > $TMP_DBDIR/${DB}_backup_`date +%Y%m%d`.sql
done

tar --exclude='*~' -czPf ${TARGET}.tar.gz $DATATOBCKP
chown -R ${BCKP_USER}: ${TARGET}.tar.gz

cd ${BCKP_DIR}
md5sum ${BCKP_NAME}.tar.gz > ${BCKP_NAME}.md5
chown ${BCKP_USER}: ${BCKP_NAME}.md5
cd - > /dev/null

rm -rf $TMP_DBDIR
