TYPO3 Character Set Converter
=============================

What does it do?
----------------

This is a script to convert MySQL tables from Latin1 to UTF-8.

Other than most converter scripts, it allows to change the character set definition in the schema of your tables, while the contents remain the same.
This very special action is often needed for TYPO3 sites which have been writing UTF-8 content into Latin1 tables for some time.

If needed, it can of course also convert everything, including content.

Why is this needed?
-------------------

When converting a table from one character set to another one, MySQL will always automatically convert the contents of the table as well.
Under normal conditions, this is of course a correct behaviour and should not be circumvented.

The magic of this script is only needed when the schema of a table IS already broken. Example:

* The columns of a table are declared as Latin1 according to the schema definition.
* But the content is actually UTF-8 because TYPO3 was writing UTF-8 content into this database.
* Now if you convert this table to UTF-8, the result will be double-UTF-8-encoded content.
* There is no way to make MySQL convert the table definition without converting the content at the same time.

What the script does is to convert the table in two steps:

1. From the original character set to binary
2. From binary to UTF-8

With this simple workaround, MySQL will leave the contents unchanged because binary content does not need to be converted.

Additionally to this, the script will do some more steps: Changing the character set of a table to binary will also change all varchar fields to varbinary, text fields to blob, etc. This is not intended and needs to be fixed.
The script takes care of this by restoring the original schema (except the character set definition, of course...).

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
    | character_set_server     | utf8                       |
    | character_set_system     | utf8                       |
    | character_sets_dir       | /usr/share/mysql/charsets/ |
    +--------------------------+----------------------------+
    8 rows in set (0.00 sec)

  Take a look at client, connection and results character sets and make sure that they match. (The others don't really matter since they most likely apply to newly created databases or tables only.)
  Compare this with $TYPO3_CONF_VARS['BE']['forceCharset'] in your TYPO3 localconf.php.
* If all use Latin1 and $TYPO3_CONF_VARS['BE']['forceCharset'] is set to "utf-8", then your setup is most likely affected by the mentioned problem, and needs to be fixed as explained below (convert only the scheme but no content).
* If all use Latin1, you can make a normal conversion (scheme and content). For this to work, set CONVERT_DATA=1 at the beginning of the script and run it like explained below.
* If all use UTF-8, then there is most likely nothing more for you to do.
* In all cases, you will need to change $TYPO3_CONF_VARS['BE']['forceCharset'] to "utf-8" at the end of the process (except when using TYPO3 4.7 or later which is forced to use UTF-8).

How to use
----------

1. Download the script
2. Optionally: Edit the database credentials and set which tables need to be changed
3. Run the script

  ::

    $ ./typo3-charset-converter.sh
    # Alternative
    $ ./typo3-charset-converter.sh /path/to/typo3conf/localconf.php

In the 2nd example, the charset converter tries to read the database credentials automatically from localconf.php.
Backup dumps of each table will be created in the current working directory.

Having questions or feedback? Let me know at michael.stucki@typo3.org.
