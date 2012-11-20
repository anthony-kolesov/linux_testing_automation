#!/bin/bash

for i in ${WORKSPACE}/*
do
	echo remove $i
	rm -rf $i
done

