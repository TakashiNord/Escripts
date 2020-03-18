#!/bin/bash

#DATE=`date`

service php-fpm restart
service mysqld restart
service nginx restart
service elasticsearch restart

service supervisord restart