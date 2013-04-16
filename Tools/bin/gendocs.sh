#!/bin/sh

#  gendocs.sh
#  Cumulus
#
#  Created by John Clayton on 10/9/12.
#  Copyright (c) 2012 Fivesquare Software, LLC. All rights reserved.


appledoc="${SRCROOT}/Tools/bin/appledoc"
docpath="${SRCROOT}/Docs/API"

echo "Documenting Cumulus version ${VERSION}"


$appledoc --project-name=Cumulus --project-version=$VERSION --project-company='Fivesquare Software' --company-id='com.fivesquaresoftware' --docset-install-path $docpath -o $docpath --no-repeat-first-par --index-desc "${SRCROOT}/README.md" --ignore '.m' --ignore '*+Private.h' --ignore '*+Protected.h' --include "${SRCROOT}/Docs/faq.md" --include "${SRCROOT}/Docs/howto.md" --keep-undocumented-objects --keep-undocumented-members --print-information-block-titles  --crossref-format "#?%@" "${SRCROOT}/Source"