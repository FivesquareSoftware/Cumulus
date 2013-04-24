#!/bin/sh

#  gendocs.sh
#  Cumulus
#
#  Created by John Clayton on 10/9/12.
#  Copyright (c) 2012 Fivesquare Software, LLC. All rights reserved.


appledoc="${SRCROOT}/Tools/bin/appledoc"
docpath="${SRCROOT}/Docs/API"
srcpath="${SRCROOT}/Source"

echo "Documenting Cumulus version ${VERSION}"


$appledoc --project-name=Cumulus --project-version=$VERSION --project-company='Fivesquare Software' --company-id='com.fivesquaresoftware' --docset-install-path $docpath -o $docpath --no-repeat-first-par --index-desc "${SRCROOT}/Docs/API/index.md" --ignore '.m' --ignore '*+Private.h' --ignore '*+Protected.h' --keep-undocumented-objects --keep-undocumented-members --print-information-block-titles  --crossref-format "#?%@" --exit-threshold 2 "${SRCROOT}/Source"

