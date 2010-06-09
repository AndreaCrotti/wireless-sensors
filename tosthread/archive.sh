#!/bin/bash

[ "$1" != "" ] && echo "Please provide a task-number." && exit 1

NAME="task$1sensornet1.tar"
echo "creating the archive to $NAME"
git archive --format=tar --output=$NAME HEAD
