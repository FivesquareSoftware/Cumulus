#!/bin/sh

#  gendocs.sh
#  RESTClient
#
#  Created by John Clayton on 10/9/12.
#  Copyright (c) 2012 Fivesquare Software, LLC. All rights reserved.

echo ${VERSION}

"${SRCROOT}/Tools/bin/appledoc" --project-name=RESTClient --project-version="${VERSION}" --project-company='Fivesquare Software' --company-id='com.fivesquaresoftware' --docset-install-path "${SRCROOT}/Docs/API" -o "${SRCROOT}/Docs/API" "${SRCROOT}/Source"