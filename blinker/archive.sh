#!/bin/bash
NAME="task$1sensornet1.tar"
echo "creating the archive to $NAME"
git archive --format=tar --output=$NAME HEAD
