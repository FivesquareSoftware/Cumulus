#!/bin/sh

#  gendocs.sh
#  Cumulus
#
#  Created by John Clayton on 10/9/12.
#  Copyright (c) 2012 Fivesquare Software, LLC. All rights reserved.


appledoc="${SRCROOT}/Tools/bin/appledoc"
docpath="${BUILT_PRODUCTS_DIR}"
srcpath="${SRCROOT}/Source"
version=`git describe --abbrev=0 --tags`
docset_name="Cumulus-${version}"

echo "Documenting Cumulus"
echo "version '${VERSION}'"
echo "srcpath '$srcpath'"
echo "docpath '$docpath'"


$appledoc \
--project-name=$docset_name --project-version=$version --project-company='Fivesquare Software' --company-id='com.fivesquaresoftware' \
--ignore '.m' --ignore '*+Private.h' --ignore '*+Protected.h' \
--index-desc "${SRCROOT}/Docs/API/index.md" --no-repeat-first-par --keep-undocumented-objects --keep-undocumented-members --print-information-block-titles  --crossref-format "#?%@" \
--exit-threshold 2 \
-o $docpath \
$srcpath

