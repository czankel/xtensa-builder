#!/bin/bash
if [ $# -ne 1 -a $# -ne 2 ]
then
	echo "Usage: `basename $0` {component} {directory}"
	exit 65
fi

COMPONENT=$1
DIRECTORY=$1

if [ $# -eq 2 ]
then
	DIRECTORY=$2
fi

echo Building $COMPONENT in $DIRECTORY
sh builder/$COMPONENT.sh $DIRECTORY
