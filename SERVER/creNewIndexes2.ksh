#!/bin/ksh

cat ./creNewIndexes2.sql|mysql --user=mysql --password=mysql -f
