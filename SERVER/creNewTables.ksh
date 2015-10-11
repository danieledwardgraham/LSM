#!/bin/ksh

cat ./creNewTables.sql|mysql --user=mysql --password=mysql -f
