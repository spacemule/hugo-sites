#!/bin/bash

declare -a FILES=( $(find . -iname "*.png") )

for FILE in "${FILES[@]}"
do
	NEWFILE=`echo $FILE | sed "s/png$/webp/"`
	convert $FILE $NEWFILE
done
exit 0
