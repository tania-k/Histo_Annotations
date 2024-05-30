#!/bin/bash -l
#SBATCH -N 1 -n 4 --mem 32gb --time 5-0:0:0 --out logs/mysql.log -J mysqld
# Define program name
PROGNAME=$(basename $0)

# Load software
#module load singularity

# Define stop mysqldb
stop_mysqldb() { singularity instance stop mysqldb; }

# Set trap to ensure mysqldb is stopped
trap "stop_mysqldb; exit 130" SIGHUP SIGINT SIGTERM

# Define error handler
error_exit()
{
    stop_mysqldb
	echo "${PROGNAME}: ${1:-"Unknown Error"}" 1>&2
	exit 1
}

# Set some vars
export SINGULARITY_BINDPATH=/work/users/t/a/taniak/mysql
export SINGULARITYENV_PASACONF=/work/users/t/a/taniak/mysql/pasa.config.txt

cd ~/work/users/t/a/taniak/mysql
# Start Database
PORT=$(singularity exec --writable-tmpfs -B db/:/work/users/t/a/taniak/mysql mariadb.sif grep -oP '^port = \K\d{4}' /work/users/t/a/taniak/mysql/my.cnf | head -1)

# Update PASA DB config
echo $PORT
sed -i "s/^MYSQLSERVER.*$/MYSQLSERVER=${HOSTNAME}:${PORT}/" ${SINGULARITYENV_PASACONF}
singularity exec --writable-tmpfs -B db/:/work/users/t/a/taniak/mysql mariadb.sif /work/users/t/a/taniak/mysql/mysqld_safe
stop_mysqldb
exit 0
