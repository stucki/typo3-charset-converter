TYPO3 Character Set Converter
=============================

This is a script to convert MySQL tables from latin1 to utf8 without actually converting the contents.
This is often needed for TYPO3 sites which have been writing UTF-8 content into Latin1 tables.

Important: How to check if this is needed
-----------------------------------------
The procedure becomes necessary while converting a site to use UTF-8 entirely. Please note that this is the default behaviour for new installations since TYPO3 4.5.

To be sure if you need this tool, check the following points:

* What is your client character set?

  It is recommended to run TYPO3 with the following settings:

  ::

    mysql> SHOW VARIABLES LIKE '%character_set%';
    +--------------------------+----------------------------+
    | Variable_name            | Value                      |
    +--------------------------+----------------------------+
    | character_set_client     | utf8                       |
    | character_set_connection | utf8                       |
    | character_set_database   | utf8                       |
    | character_set_filesystem | binary                     |
    | character_set_results    | utf8                       |
    | character_set_server     | latin1                     |
    | character_set_system     | utf8                       |
    | character_sets_dir       | /usr/share/mysql/charsets/ |
    +--------------------------+----------------------------+
    8 rows in set (0.00 sec)

  Take a look at client, connection and results character sets and make sure that they match.
  Compare this with $TYPO3_CONF_VARS['BE']['forceCharset'] in your TYPO3 localconf.php.
* If all use latin1, you can simply convert the database with standard MySQL tools:

  ::

    mysql> ALTER DATABASE mydatabase CONVERT TO CHARACTER SET utf8;

* If all use utf8, then there is most likely nothing more for you to do.
* If forceCharset is set to "utf-8" but the database is using latin1, then your setup is most likely affected and needs to be fixed as explained below.
* In all cases, you will need to change $TYPO3_CONF_VARS['BE']['forceCharset'] to 'utf-8' at the end of the process (except when using TYPO3 4.7 or later which is forced to using UTF-8).

How to use
----------

1. Download the script
2. Edit the database credentials and set which tables need to be changed
3. Run the script

  ::

    $ ./typo3-charset-converter.sh

Backup dumps of each table will be created in the current working directory.

Having questions or feedback? Let me know at michael.stucki@typo3.org.
