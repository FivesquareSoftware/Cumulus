#!/bin/sh

#  setup.sh
#  RESTClient
#
#  Created by John Clayton on 10/16/11.
#  Copyright (c) 2011 Fivesquare Software, LLC. All rights reserved.

ROOT=`dirname __FILE__`

sudo gem install bundle
bundle install --path "$ROOT/vendor/bundle"