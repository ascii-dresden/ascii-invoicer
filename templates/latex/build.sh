#!/bin/bash

pdflatex ascii-angebot.tex
pdflatex ascii-rechnung.tex

rm *.log *.aux
