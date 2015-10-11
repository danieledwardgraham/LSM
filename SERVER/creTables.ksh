#!/bin/ksh

cat ./creTables.sql|mysql --user=mysql --password=mysql -f
