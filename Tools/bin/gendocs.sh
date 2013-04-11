#!/bin/sh

#  gendocs.sh
#  Cumulus
#
#  Created by John Clayton on 10/9/12.
#  Copyright (c) 2012 Fivesquare Software, LLC. All rights reserved.


appledoc="${SRCROOT}/Tools/bin/appledoc"
docpath="${SRCROOT}/Docs/API"

echo "Documenting Cumulus version ${VERSION}"


$appledoc --project-name=Cumulus --project-version=$VERSION --project-company='Fivesquare Software' --company-id='com.fivesquaresoftware' --docset-install-path $docpath  -o $docpath "${SRCROOT}/Source"