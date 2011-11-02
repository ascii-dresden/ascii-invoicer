#!/bin/bash

pdflatex "$1"

rm *.log
rm *.aux
