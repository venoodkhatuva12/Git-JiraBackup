#!/bin/sh
DBUSER="user"
DBPASS="password"
JIRA_HOME=/jira/jira-data/data/
CONFLUENCE_HOME=/jira/jira-data/plugins/
BACKUPDIR=/jira/jira-backup/jiradata/
if [ ! -d ${BACKUPDIR} ]; then
  mkdir ${BACKUPDIR}
else
  rm -rf ${BACKUPDIR}/*
fi
# Push all commands into a subshell, so that everything is
# done between the db lock
(
  # Write-Lock database, db is still readable, but not writable
  echo "FLUSH TABLES WITH READ LOCK;"
  # Dump each database except default databases into separate sql files
  for i in $(mysql --user=${DBUSER} --password=${DBPASS} -e 'SHOW DATABASES' | grep -Ev '(Database|*_schema|test|mysql)'); do
    mysqldump --user=${DBUSER} --password=${DBPASS} -Q -c -C --add-drop-table --events --quick ${i} | gzip -c > $BACKUPDIR/${i}.$(date +%F).sql.gz 2>/dev/null
  done
  tar czf ${BACKUPDIR}/application-backup.$(date +%F).tgz ${JIRA_HOME} ${CONFLUENCE_HOME} ${BACKUPDIR}/*.gz
  # Unlock database
  echo "UNLOCK TABLES;"
) | mysql --user=${DBUSER} --password=${DBPASS}

cd $BACKUPDIR
/usr/local/bin/s3cmd put application-backup.$(date +%F).tgz  s3://url.com.$(date +%F).tgz
/usr/local/bin/s3cmd put jiradb.$(date +%F).sql.gz  s3://url.com.$(date +%F).sql.gz
/usr/local/bin/s3cmd put stash.$(date +%F).sql.gz  s3://url.com.$(date +%F).sql.gz

exit 0
