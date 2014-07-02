#!/bin/bash

[ -d ~/Desktop/ram ] || mkdir ~/Desktop/ram && sudo mount -t tmpfs none ~/Desktop/ram && df

mkdir ~/Desktop/ram/spec_projects
mkdir ~/Desktop/ram/templates
cp ../templates/blank.yml ~/Desktop/ram/templates/

