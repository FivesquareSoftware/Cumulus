#!/bin/sh

#  gendocs.sh
#  Cumulus
#
#  Created by John Clayton on 10/9/12.
#  Copyright (c) 2012 Fivesquare Software, LLC. All rights reserved.


appledoc="${SRCROOT}/Tools/bin/appledoc"
docpath="${SRCROOT}/Docs/API/"
srcpath="${SRCROOT}/Source"

echo "Documenting Cumulus"
echo "version '${VERSION}'"
echo "srcpath '$srcpath'"
echo "docpath '$docpath'"


$appledoc \
--project-name=Cumulus --project-version=$VERSION --project-company='Fivesquare Software' --company-id='com.fivesquaresoftware' \
--ignore '.m' --ignore '*+Private.h' --ignore '*+Protected.h' \
--index-desc "${SRCROOT}/Docs/API/index.md" --no-repeat-first-par --keep-undocumented-objects --keep-undocumented-members --print-information-block-titles  --crossref-format "#?%@" \
--exit-threshold 2 \
--docset-install-path $docpath  -o $docpath \
$srcpath

