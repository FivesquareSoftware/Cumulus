#!/bin/sh

#  run.sh
#  RESTClient
#
#  Created by John Clayton on 9/10/11.
#  Copyright (c) 2011 Fivesquare Software, LLC. All rights reserved.

# Controls both the standard and SSL versions of the test service
# Send start, restart or stop

action=$1

PORT='4567'
SSL_PORT='4543'

PID='log/thin.pid'
LOG='log/thin.log'

SSL_PID='log/thin-ssl.pid'
SSL_LOG='log/thin-ssl.log'


if [ $action == 'start' ]; then
	if [ ! -f $PID ]; then
		bundle exec thin -R config.ru --port $PORT --pid $PID --log $LOG --daemonize --debug start
	else
		echo "Already running"
	fi
	if [ ! -f $SSL_PID ]; then
		bundle exec thin --ssl -R config.ru --port $SSL_PORT --pid $SSL_PID  --log $SSL_LOG --daemonize --debug start
	else
		echo "Already running (SSL)"
	fi
fi

if [ $action == 'restart' ]; then
	if [ -f $PID ]; then
		# restart is way too slow
		bundle exec thin -R config.ru --pid $PID stop
	fi
	bundle exec thin -R config.ru --port $PORT --pid $PID  --log $LOG --daemonize --debug start

	if [ -f $SSL_PID ]; then
		# restart is way too slow
		bundle exec thin -R config.ru --pid $SSL_PID stop
	fi
	bundle exec thin --ssl -R config.ru --port $SSL_PORT --pid $SSL_PID --log $SSL_LOG --daemonize --debug start
fi


if [ $action == 'stop' ]; then
	if [ -f $PID ]; then
		bundle exec thin -R config.ru --pid $PID  stop
	else
		echo "Not running"
	fi
	if [ -f $SSL_PID ]; then
		bundle exec thin -R config.ru --pid $SSL_PID stop
	else
		echo "Not running (SSL)"
	fi
fi


