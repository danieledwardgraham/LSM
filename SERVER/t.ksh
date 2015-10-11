#!/bin/ksh
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/home/dgraham/mysql-server/mysql-5.1.37-linux-i686-icc-glibc23/lib
export LD_RUN_PATH=/home/dgraham/mysql-server/mysql-5.1.37-linux-i686-icc-glibc23/lib
./LSMserver.pl &
