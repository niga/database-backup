#!/bin/sh

DATE=`date -d "yesterday" +"%Y-%m-%d"`
DIR=%backups path%

HOSTUSER=%ssh user name%
HOSTNAME=%ssh host%

DBBASE=%database name%
DBUSER=%database user%
DBPASS=%database password%

echo "Create dir $DIR$DATE"
mkdir -p $DIR$DATE

for TABLE in $(ssh -p 222 $HOSTUSER@$HOSTNAME -C "mysql -B -s -u$DBUSER -p$DBPASS $DBBASE -e 'show tables'")
do
    echo "Create dump for table $TABLE"
	ssh -p 222 $HOSTUSER@$HOSTNAME -C "mysqldump -u$DBUSER -p$DBPASS $DBBASE $TABLE | gzip -c" > $DIR$DATE/$TABLE.sql.gz
done

echo "Create full archive"
tar -czvf $DIR/$DATE.sql.tar.gz $DIR$DATE

echo "Remove dir $DIR$DATE"
rm -rf $DIR$DATE

echo "Finished"


