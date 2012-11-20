#!/bin/bash

for i in ${WORKSPACE}/*
do
	echo remove $i
	chown -R akolesov $i
	chmod -R 777 $i
done

