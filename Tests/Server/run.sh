#!/bin/sh

#  run.sh
#  RESTClient
#
#  Created by John Clayton on 9/10/11.
#  Copyright (c) 2011 Fivesquare Software, LLC. All rights reserved.


action=$1

if [ $action == 'start' ]; then
	if [ ! -f log/thin.pid ]; then
		bundle exec thin -R config.ru --port 4567 --pid log/thin.pid --daemonize --debug $action
	else
		echo "Already running"
	fi
fi

if [ $action == 'restart' ]; then
	if [ ! -f log/thin.pid ]; then
		bundle exec thin -R config.ru --port 4567 --pid log/thin.pid --daemonize --debug start
	else
		# restart is way too slow
		bundle exec thin -R config.ru --pid log/thin.pid stop
		bundle exec thin -R config.ru --port 4567 --pid log/thin.pid --daemonize --debug start
	fi
fi


if [ $action == 'stop' ]; then
	if [ -f log/thin.pid ]; then
		bundle exec thin -R config.ru --pid log/thin.pid $action
	else
		echo "Not running"
	fi
fi


