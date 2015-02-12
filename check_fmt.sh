#!/bin/bash

UNFMTD_FILES_DIFF=`find . -name "*.go" -not -path './_vendor*' | xargs -L1 gofmt -d`
if [ -n "$UNFMTD_FILES_DIFF" ]; then
  echo -e "ERROR: You need to gofmt the following files: \n$UNFMTD_FILES_DIFF"
  exit 1
else
  echo "INFO: All files are gofmt'd!"
  exit 0
fi
