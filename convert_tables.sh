#!/bin/bash

# Configuration
MYSQL_USERNAME=
MYSQL_PASSWORD=
MYSQL_HOSTNAME=
MYSQL_DATABASE=

#TABLES="table1 table2 ..."
TABLES=

# Wrapper for mysqldump
do_mysqldump() {
	TABLE=$1
	ADDITIONAL_PARAMETERS=$2
	mysqldump $ADDITIONAL_PARAMETERS -u $MYSQL_USERNAME -p$MYSQL_PASSWORD -h $MYSQL_HOSTNAME $MYSQL_DATABASE $TABLE
	return $?
}

# Wrapper for the mysql client
do_mysql() {
	QUERY=$1
	echo "$QUERY" | mysql -u $MYSQL_USERNAME -p$MYSQL_PASSWORD -h $MYSQL_HOSTNAME $MYSQL_DATABASE
	return $?
}


if [ -z "$TABLES" ] || [ -z $MYSQL_DATABASE]; then
	echo "Error: Configuration is missing. Please change the settings at the beginning of this file."
	exit 1
fi

for TABLE in $TABLES; do
	echo -en "Dump table $TABLE... \t"

	# Make a dump of the schema
	#echo -en "dumping schema... \t"
	do_mysqldump $TABLE --no-data > ${TABLE}_schema.sql
	# Make a dump of the whole tables (skip-extended-insert results in 1 line per record)
	#echo -en "dumping data... \t"
	do_mysqldump $TABLE --skip-extended-insert > ${TABLE}.sql

	echo "done."

	echo -en "Convert table $TABLE... \t"

	# Perform a two-step conversion via binary charset to avoid conversion of the data
	#echo -en "to binary... \t"
	do_mysql "ALTER TABLE $TABLE CONVERT TO CHARACTER SET binary;"
	#echo -en "to utf8... \t"
	do_mysql "ALTER TABLE $TABLE CONVERT TO CHARACTER SET utf8;"

	echo "done."

	echo "Fix the schema..."

	# Fix the schema (varbinary => vartext etc.)
	cat ${TABLE}_schema.sql | sed "s/,$//" | grep "^  " | grep -v "KEY" | while read LINE; do
		COLUMN=$(echo "$LINE" | awk '{print $1}')
		#echo "Converting $COLUMN..."
		do_mysql "ALTER TABLE $TABLE MODIFY $LINE;"
	done
done
