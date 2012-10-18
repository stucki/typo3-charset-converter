#!/bin/bash

# Configuration
MYSQL_USERNAME=
MYSQL_PASSWORD=
MYSQL_HOSTNAME=
MYSQL_DATABASE=

#TABLES="table1 table2 ..."
TABLES="*"

# Parse parameters, if any
CONFIG=$1

# Set this to 1 to change the table content and not only the scheme.
# Otherwise, content is converted to binary in between which makes MySQL forget about conversion of data.
# CONVERT_DATA=0: <source charset> => binary => UTF-8
# CONVERT_DATA=1: <source charset> => UTF-8
CONVERT_DATA=0

# Wrapper for mysqldump
do_mysqldump() {
	TABLE=$1
	ADDITIONAL_PARAMETERS=$2
	mysqldump $ADDITIONAL_PARAMETERS --skip-lock-tables -u $MYSQL_USERNAME -p$MYSQL_PASSWORD -h $MYSQL_HOSTNAME $MYSQL_DATABASE $TABLE
	return $?
}

# Wrapper for the mysql client
do_mysql() {
	QUERY=$1
	echo "$QUERY" | mysql -u $MYSQL_USERNAME -p$MYSQL_PASSWORD -h $MYSQL_HOSTNAME --skip-column-names $MYSQL_DATABASE
	return $?
}

# Read MySQL credentials from a TYPO3 configuration file
match_against_typo3() {
	CONFIG=$1

	# Match "typo_db" configuration lines and strip everything except the name and value parts
	TMPVAL=$(grep "typo_db" $CONFIG | sed "s/\"/'/g; s/';.*/'/g" | grep -v "typo_db_extTableDef_script")

	# Assign values, only use the last match
	MYSQL_USERNAME=$(echo "$TMPVAL" | grep "typo_db_user" | tail -n 1 | cut -d\' -f 2)
	MYSQL_PASSWORD=$(echo "$TMPVAL" | grep "typo_db_pass" | tail -n 1 | cut -d\' -f 2)
	MYSQL_HOSTNAME=$(echo "$TMPVAL" | grep "typo_db_host" | tail -n 1 | cut -d\' -f 2)
	MYSQL_DATABASE=$(echo "$TMPVAL" | grep -v "typo_db_"  | tail -n 1 | cut -d\' -f 2)
}


if [ -n "$CONFIG" ] && [ -f "$CONFIG" ]; then
	case $(basename $CONFIG) in
		"localconf.php")
			match_against_typo3 $CONFIG
		;;
	esac
fi

if [ -z "$TABLES" ] || [ -z "$MYSQL_DATABASE" ]; then
	echo "Error: Configuration is missing. Please change the settings at the beginning of this file."
	exit 1
fi

if [ "$TABLES" = "*" ]; then
	TABLES=$(do_mysql "SHOW TABLES LIKE '%';")
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

	# First, convert all CHAR fields into VARCHAR due to an ugly bug(?) in MySQL which
	# results in empty CHAR fields to become HEX(0000)
	# (happens reproducibly in TYPO3 be_users.lang for example)
	cat ${TABLE}_schema.sql | sed "s/,$//" | grep "^  " | egrep -v "KEY|FULLTEXT" | while read LINE; do
		# Skip all lines except "char" fields
		echo $LINE | grep -qi " char" || continue

		# Convert the fields into varchar(). This will be changed back again to
		# char() at the end of this script.
		LINE=$(echo $LINE | sed "s/ char/ varchar/")

		COLUMN=$(echo "$LINE" | awk '{print $1}')
		#echo "Converting $COLUMN..."
		do_mysql "ALTER TABLE $TABLE MODIFY $LINE;"
	done

	# Perform a two-step conversion via binary charset to avoid conversion of the data

	if [ $CONVERT_DATA = 0 ]; then
		#echo -en "to binary... \t"
		do_mysql "ALTER TABLE $TABLE CONVERT TO CHARACTER SET binary;"
	fi

	#echo -en "to utf8... \t"
	do_mysql "ALTER TABLE $TABLE CONVERT TO CHARACTER SET utf8;"

	echo "done."

	echo "Fix the schema..."

	# Fix the schema (varbinary => vartext etc.)
	cat ${TABLE}_schema.sql | sed "s/,$//" | grep "^  " | egrep -v "KEY|FULLTEXT" | while read LINE; do
		# Make sure that columns don't use a different character set than the rest of the table
		LINE=$(echo "$LINE" | sed "s/ \(CHARACTER SET\|COLLATE\) [^ ]*//g")

		COLUMN=$(echo "$LINE" | awk '{print $1}')
		#echo "Converting $COLUMN..."
		do_mysql "ALTER TABLE $TABLE MODIFY $LINE;"
	done
done
