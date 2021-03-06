#!/usr/bin/env bash

cd "$(dirname "$0")"

if [ ! -f config.sh ]; then
    echo "File config.sh not found!"
    exit 1
fi

source config.sh

function getDatabases {
    if [ -z ${SSH_HOST_NAME+x} ] || [ -z "$SSH_HOST_NAME" ];  then
        echo $(mysql -h$DB_HOSTNAME -u$DB_USERNAME -p$DB_PASSWORD -e "SHOW DATABASES;" | tr -d "| " | grep -v Database)
    else
        echo $(ssh -p 222 $SSH_HOST_USER@$SSH_HOST_NAME -C "mysql -h$DB_HOSTNAME -u$DB_USERNAME -p$DB_PASSWORD -e "SHOW DATABASES;" | tr -d "| " | grep -v Database")
    fi
}

function getTables {
    if [ -z ${SSH_HOST_NAME+x} ] || [ -z "$SSH_HOST_NAME" ];  then
        echo $(mysql -B -s -h$DB_HOSTNAME -u$DB_USERNAME -p$DB_PASSWORD ${1} -e 'show tables')
    else
        echo $(ssh -p 222 $SSH_HOST_USER@$SSH_HOST_NAME -C "mysql -B -s -h$DB_HOSTNAME -u$DB_USERNAME -p$DB_PASSWORD ${1} -e 'show tables'")
    fi
}

function dumpTable {
    if in_array "$database.$table"; then
        echo "Create dump for table $database.$table without data"
        params=" --no-data"
    else
        echo "Create dump for table $database.$table with data"
        params=""
    fi

    if [ -z ${SSH_HOST_NAME+x} ] || [ -z "$SSH_HOST_NAME" ];  then
        $(mysqldump -h$DB_HOSTNAME -u$DB_USERNAME -p$DB_PASSWORD $params $database $table | gzip -c > $DIR$database/$DATE/$table.sql.gz)
    else
        $(ssh -p 222 $SSH_HOST_USER@$SSH_HOST_NAME -C "mysqldump -h$DB_HOSTNAME -u$DB_USERNAME -p$DB_PASSWORD $params $database $table | gzip -c" > $DIR$database/$DATE/$table.sql.gz)
    fi
}

in_array() {
    local needle=${1}

    for i in ${EXCLUDE[@]}; do
        if [ $i == $needle ]; then
            return 0
        fi
    done
    return 1
}

DATE=`date +"%Y-%m-%d"`

for database in $(getDatabases)
do
    if [ "$database" == "information_schema" ] \
    || [ "$database" == "performance_schema" ] \
    || [ "$database" == "mysql" ] ; then
        continue
    fi

    echo "Dumping database: $database"

    if [ ! -d "$DIR$database/$DATE" ]; then
        echo "Create directory: $DIR$database/$DATE"
        mkdir -p "$DIR$database/$DATE"
    fi

    for table in $(getTables $database)
    do
        dumpTable
    done

    echo "Create full archive"
    tar -czf $DIR$database/$DATE.sql.tar.gz $DIR$database/$DATE > /dev/null
    echo "Remove dir $DIR$database/$DATE"
    rm -rf $DIR$database/$DATE
done

echo "Finished"
