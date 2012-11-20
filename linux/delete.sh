#!/bin/bash

for i in ${WORKSPACE}/*
do
	echo remove $i
	chown -R akolesov $i
	chmod -R 777 $i
done

for i in /remote/arctools/akolesov/jenkins/linux_3.2_default/*
do
    echo remove $i
    chown -R akolesov $i
    chmod -R 777 $i
done

