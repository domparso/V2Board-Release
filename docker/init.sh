#!/bin/bash


# set -e

ADMIN_REPOURL="${ADMIN_REPOURL:-https://github.com/v2board/v2board-admin.git}"
USER_REPOURL="${USER_REPOURL:-https://github.com/v2board/v2board-user.git}"

SLEEK_REPOURL="${SLEEK_REPOURL:-https://github.com/binglog/V2b-Theme-Sleek.git}"
ARGON_REPOURL="${SLEEK_REPOURL:-https://github.com/BobCoderS9/Bob-Theme-Argon.git}"

APPHOME=/app
PHPPATH=/opt/bitnami/php/bin/php
BACKUPPATH=/opt/bitnami/backup
CONFIG_FILE=.env

DEPLOY_MODE=false
THEME_MODEL=v2board
THEME_TAG=


is_empty_dir(){ 
	return `ls -A $1|wc -w`
}

# copy php-fpm config
if is_empty_dir "/opt/bitnami/php/etc"; then
	cp -R /opt/bitnami/php/etc.default/* /opt/bitnami/php/etc/*
fi

# 创建网站目录

cd $APPHOME

if [[ "$REINSTALL" != "false" ]]; then
	# 备份
	if [[ "$REINSTALL" == "save" ]]; then
		rm -rf $BACKUPPATH/*
		cp -r .env $BACKUPPATH/
	fi
	rm -rf *
	# 删除隐藏文件
	find /app -type d -name .\* | xargs rm -rf 
	find /app -type f -name .\* | xargs rm -rf 
fi

if [[ "`ls -A ${APPHOME}`" = "" ]]; then 
	echo "创建网站目录"
	
	if [[ $REPOVISI = "public" && -n $REPOURL ]]; then
		git clone --depth=1 -b $BRANCH $REPOURL .
	else
		tmp=(`echo $REPOURL | tr ':' ' '`)
		tmp1=`echo ${tmp[1]} | cut -b 3-`
		if [[ $GITREPO = "gitlab" && -n $TOKEN ]]; then
			# url=https://oauth2:${TOKEN}@${REPOURL}
			url=${tmp[0]} + ':' + "oauth2:${TOKEN}@" + tmp1
		else
			url=${tmp[0]} + ':' + "${TOKEN}@" + tmp1
		fi
		git clone --depth=1 -b $BRANCH $url .
	fi

	# git config core.filemode false
	# && cp .env.example $CONFIG_FILE
	chmod -R 777 * \
	&& echo "创建网站目录完成"

	mkdir -p logs \
	&& echo -e "$DB_HOST\n$DB_DATABASE\n$DB_USERNAME\n$DB_PASSWORD\n$ADMIN_MAIL\n" | sh init.sh | tee -a logs/init.log \
	&& cat logs/init.log

	if [[ "$REINSTALL" == "save" ]]; then
		rm -rf ./config
		cp -r $BACKUPPATH/.env ./
	else
		# write config
		# -e "s/DB_HOST=localhost/DB_HOST=$DB_HOST/g" \
		# -e "s/DB_DATABASE=laravel/DB_DATABASE=$DB_DATABASE/g" \
		# -e "s/DB_USERNAME=root/DB_USERNAME=$DB_USERNAME/g" \
		# -e "s/DB_PASSWORD=123456/DB_PASSWORD=$DB_PASSWORD/g"
		echo "写入配置..."
		sed -i -e "s/APP_NAME=V2Board/APP_NAME=$APP_NAME/g" \
		-e "s|APP_URL=http://localhost|APP_URL=$BASEURL|g" \
		-e "s/REDIS_HOST=127.0.0.1/REDIS_HOST=$REDIS_HOST/g" \
		-e "s/REDIS_PASSWORD=null/REDIS_PASSWORD=$REDIS_PASSWORD/g" \
		$CONFIG_FILE

		if [[ -n "$APP_ENV" ]]; then
			sed -i -e "s/APP_ENV=local/APP_ENV=$APP_ENV/g" $CONFIG_FILE
		fi

		if [[ -n "$APP_DEBUG" ]]; then
			sed -i -e "s/APP_DEBUG=false/APP_DEBUG=$APP_DEBUG/g" $CONFIG_FILE
		fi

		if [[ -n "$DB_TYPE" ]]; then
			sed -i -e "s/DB_CONNECTION=mysql/DB_CONNECTION=$DB_TYPE/g" $CONFIG_FILE
		fi

		if [[ -n "$DB_PORT" ]]; then
			sed -i -e "s/DB_PORT=3306/DB_PORT=$DB_PORT/g" $CONFIG_FILE
		fi

		if [[ -n "$REDIS_PORT" ]]; then
			sed -i -e "s/REDIS_PORT=6379/REDIS_PORT=$REDIS_PORT/g" $CONFIG_FILE
		fi
	fi

	if [[ $THEME_MODEL = "sleek" ]]; then
		cd $APPHOME/public/theme \
		&& wget -O wget -O Theme-Sleek.zip https://github.com/binglog/V2b-Theme-Sleek/releases/download/$THEME_TAG/Theme-Sleek.zip \
		&& unzip Theme-Sleek.zip \
		&& rm -rf Theme-Sleek.zip
	else if [[ $THEME_MODEL != "argon" ]]; then
		cd $APPHOME/public/theme \
		&& wget -O Bob-Theme-Argon.zip https://github.com/BobCoderS9/Bob-Theme-Argon/archive/refs/tags/$THEME_TAG.zip \
		&& unzip Bob-Theme-Argon.zip \
		&& rm -rf Bob-Theme-Argon.zip \
		&& mv Bob-Theme-Argon* Bob-Theme-Argon
	else
	
	fi

	# 站点初始化设置
	echo "站点初始化设置"
else
	echo "网站目录不为空"
	sh init.sh
fi

# 计划任务
echo "添加计划任务"
crontab -l > cron.tmp
echo "*/1 * * * * $PHPPATH $APPHOME/artisan Schedule:run" >> cron.tmp
crontab cron.tmp
rm cron.tmp

echo "站点初始化设置完成"

