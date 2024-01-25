# php-fpm 
# php-fpm 

ARG PHP_VERSION=7.4.33

FROM bitnami/php-fpm:$PHP_VERSION as base

LABEL \
	maintainer="Domparso <domparso@hotmail.com>" \
	org.opencontainers.image.authors="Domparso"

RUN apt-get update \
	&& apt-get install -y git wget bzip2 build-essential php7.4-dev libxml2 libxml2-dev \
	&& rm -rf /var/lib/apt/lists/*

# download php
RUN cd /tmp \
	&& wget https://www.php.net/distributions/php-7.4.33.tar.bz2 \
	&& tar -xvf php-7.4.33.tar.bz2

# php-fileinfo
RUN cd /tmp/php-7.4.33/ext/fileinfo/ \
	&& phpize \
	&& ./configure --with-php-config=/opt/bitnami/php/bin/php-config \
	&& make && make install
#	&& sed -i "s@;extension=fileinfo@extension=fileinfo@g" /opt/bitnami/php/etc/php.ini

# php-opcache
RUN cd /tmp/php-7.4.33/ext/opcache/ \
	&& phpize \
	&& ./configure --with-php-config=/opt/bitnami/php/bin/php-config \
	&& make && make install \
#	&& sed -i s@/;zend_extension=opcache/@/zend_extension=opcache/@g /opt/bitnami/php/etc/php.ini \
#	&& echo "zend_extension=opcache" >> /opt/bitnami/php/etc/php.ini
	&& sed -i -e "s@;opcache.file_cache=@opcache.file_cache=/tmp@g" \
	-e "s@opcache.interned_strings_buffer = 8@opcache.interned_strings_buffer = 64\nopcache.jit=on\\nopcache.jit_buffer_size=256M@g" \
	-e "s@opcache.max_accelerated_files = 4000@opcache.max_accelerated_files = 65535@g" \
	-e "s@opcache.memory_consumption = 128@opcache.memory_consumption = 512@g" \
	-e "s@;opcache.validate_permission=0@opcache.validate_permission=on@g" \
	-e "s@;opcache.validate_root=0@opcache.validate_root=on@g" \
	/opt/bitnami/php/etc/php.ini

# php-redis
RUN cd /tmp \
	&& wget https://pecl.php.net/get/redis-5.3.7.tgz \
	&& tar zxvf redis-5.3.7.tgz \
	&& cd redis-5.3.7 \
	&& phpize \
	&& ./configure --with-php-config=/opt/bitnami/php/bin/php-config \
	&& make && make install \
	&& echo "extension=redis.so" >> /opt/bitnami/php/etc/php.ini

# php config
RUN sed -i -e "s@;curl.cainfo =@/etc/ssl/certs/ca-certificates.crt@g" \
	-e "s@;openssl.cafile=@openssl.cafile=/etc/ssl/certs/ca-certificates.crt@g" \
	-e "s@date.timezone = UTC@date.timezone = PRC@g" \
	-e "s@display_errors = Off@display_errors = On@g" \
	-e "s@max_execution_time = 30@max_execution_time = 300@g" \
	-e "s@;error_log = syslog@error_log = /opt/bitnami/php/logs/error.log@g" \
	/opt/bitnami/php/etc/php.ini

# php-fpm config
# RUN sed -i -e "s@log_level = warning@log_level = debug@g" \
# 	/opt/bitnami/php/etc/php-fpm.confa

# 禁用一些危险的 PHP Function # proc_open,proc_get_status
RUN sed -i -e 's@^disable_functions.*@disable_functions = passthru,exec,system,chroot,chgrp,chown,shell_exec,ini_alter,ini_restore,dl,readlink,symlink,popepassthru,stream_socket_server,fsocket,popen@' \
	/opt/bitnami/php/etc/php.ini

FROM bitnami/php-fpm:$PHP_VERSION 

RUN apt-get update \
	&& apt-get install -y git unzip wget cron systemctl rsyslog xz-utils supervisor expect \
	&& rm -rf /var/lib/apt/lists/*

# 时间同步
RUN cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

# 开启cron日志
# RUN sed -i s@/#cron.*/@/cron.*/@g /etc/rsyslog.conf

COPY --from=base /opt/bitnami /opt/bitnami
COPY --from=base /opt/bitnami/php/etc /opt/bitnami/php/etc.default

COPY supervisor.conf /etc/supervisor/conf.d/v2board.conf

COPY init.sh /usr/local/bin/init.sh
RUN chmod +x /usr/local/bin/init.sh

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
