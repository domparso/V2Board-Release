#!/bin/bash


set -e

APPHOME=/app

if [ -f /usr/local/bin/init.sh ]; then
	/usr/local/bin/init.sh \
	&& mv /usr/local/bin/init.sh /usr/local/bin/init.sh.bak \
	&& mkdir $APPHOME/storage/framework/cache/data
fi

# start php-fpm: master process (/opt/bitnami/php/etc/php-fpm.conf)
# /opt/bitnami/php/sbin/php-fpm

chmod 777 -R $APPHOME

systemctl start cron

supervisord -c /etc/supervisor/supervisord.conf

php-fpm -F --pid /opt/bitnami/php/tmp/php-fpm.pid -y /opt/bitnami/php/etc/php-fpm.conf

