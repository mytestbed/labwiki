#!/bin/bash
#
# Script dumping an OML database to SQL text and storing it into IRODS.
# Copyright 2012-2013 National ICT Australia (NICTA), Australia
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
irodsHost=221.199.209.240
irodsPort=1247
export irodsHost irodsPort

#BACKEND=sqlite
SQLITEDATAPATH=/var/lib/oml2
BACKEND=postgresql
PGDATAPATH=oml@10.129.128.53:5432

LOGFILE=oml2-irods-dumper.log
function log ()
{
	echo "$@" >&2
	echo "$@" >> ${LOGFILE}
}

IPUT=iput
SQLITE3=sqlite3
PGDUMP=pg_dump

CONT=0
while [ $CONT = 0 ] ; do
	case "$1" in
		--id)
			log "WARN	--id should be --domain"
			;&
		--domain)
			shift
			DOMAIN=$1
			;;
		--token)
			shift
			ITICKET=$1
			;;
		--path)
			shift
			IPATH=$1
			;;
		"")
			;;
		*)
			log "WARN	Unknown parameter '$1'"
			;;
	esac
	shift
	CONT=$?
done

if [ -z "${DOMAIN}" -o -z "${ITICKET}" -o -z "${IPATH}" ]; then
	log "ERROR	All three parameters (--domain DOMAIN --token ITICKET --path IPATH)"
	exit 1
fi

case ${BACKEND} in
	sqlite)
		DB="file:${SQLITEDATAPATH}/${DOMAIN}.sq3"
		;;
	postgresql)
		DB="postgresql://${PGDATAPATH}/${DOMAIN}"
		;;
	*)
		log "ERROR	Unknown DB backend '${BACKEND}'"
		exit 1
		;;
esac

case "${DB}" in
	file:*)
		DBNAME=${DB/file:/}
		DBFILE=/tmp/${DBNAME//\/}.`date +%Y-%m-%d_%H:%M:%S%z`.sqlite.sql
		log "INFO	Dumping SQLite3 DB ${DBNAME} as ${DBFILE} and pushing to iRODS"
		${SQLITE3} ${DBNAME} .dump > ${DBFILE}
		;;
	postgresql://*)
		# Separate the components of the URI by gradually eating them off the TMP variable
		TMP="${DB/postgresql:\/\//}"
		USER=${TMP/@*/}
		TMP=${TMP/${USER}@/}
		HOST=${TMP/:*/}
		TMP=${TMP/${HOST}:/}
		PORT=${TMP/\/*/}
		TMP=${TMP/${PORT}\//}
		DBNAME=${TMP}
		DBFILE=/tmp/${DBNAME}.`date +%Y-%m-%d_%H:%M:%S%z`.pg.sql
		log "INFO	Dumping PostgreSQL DB ${DBNAME} as ${DBFILE} and pushing to iRODS"
		log "CMD: ${PGDUMP} -O -U ${USER} -h ${HOST} -p ${PORT} ${DBNAME} > ${DBFILE}"

		${PGDUMP} -O -U ${USER} -h ${HOST} -p ${PORT} ${DBNAME} > ${DBFILE}
		;;
	*)
		log "ERROR	Don't know how to handle ${DB}"
		;;
esac
log "INFO	Creating experiment directory first irods://irodsHost:irodsPort${IPATH}"
imkdir ${IPATH}
log "INFO	Pushing ${DBFILE} to irods://irodsHost:irodsPort${IPATH}"
${IPUT} ${DBFILE} ${IPATH}/
rm ${DBFILE}
