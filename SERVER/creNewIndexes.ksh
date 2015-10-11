#!/bin/ksh

cat ./creNewIndexes.sql|mysql --user=mysql --password=mysql -f
