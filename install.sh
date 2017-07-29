#!/bin/bash
#
# Buggy but should do about 99% of the work for you.
# Notice anything off, open a issue
#


#Check is user is root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi


function escape_slashes {
    sed 's/\//\\\//g' 
}

function change_line {
    local OLD_LINE_PATTERN=$1; shift
    local NEW_LINE=$1; shift
    local FILE=$1

    local NEW=$(echo "${NEW_LINE}" | escape_slashes)
    sed -i .bak '/'"${OLD_LINE_PATTERN}"'/s/.*/'"${NEW}"'/' "${FILE}"
    mv "${FILE}.bak" /tmp/
}


#Move to the /root directory
cd /root
#Create a temp directory for holding the downloaded files
mkdir ./temp
#Move to temp
cd /temp

echo "Updating"
yum -y update > /dev/null
echo "Installing Packages needed to Compile"
yum install -y wget curl nano gcc-c++ pcre-devel zlib-devel make unzip openssl-devel gcc libxml2-devel bzip2-devel curl-devel gd-devel mysql-devel libaio-devel unzip > /dev/null

echo "Downloading Software Packages"
wget http://nginx.org/download/nginx-1.13.3.tar.gz > /dev/null
wget http://php.net/distributions/php-7.1.7.tar.gz > /dev/null
wget https://resources.mybb.com/downloads/mybb_1812.zip > /dev/null

echo "Compiling Software Packages. Note this can take a while (Hours if you don't have a fast CPU)"
tar -xvzf nginx-1.13.3.tar.gz > /dev/null
cd nginx-1.13.3
./configure > /dev/null
make j4 > /dev/null
make install > /dev/null
echo "Nginx Installed Successfully"

#Move back to temp directory
cd /root/temp

#Begin Install PHP
tar -xvzf php-7.1.7.tar.gz > /dev/null
cd php-7.1.7
./configure --enable-fpm --with-pdo-mysql --with-zlib --with-bz2 --enable-zip --with-openssl --with-mhash --with-curl --with-gd --with-jpeg-dir --with-png-dir --enable-ftp --enable-exif --with-freetype-dir --enable-calendar --enable-soap --enable-mbstring --with-libxml-dir=/usr/lib --with-mysqli > /dev/null
make -j4 > /dev/null
make install > /dev/null
php.ini-production /usr/local/lib/php.ini

cd /usr/local/etc/ && cp -rf php-fpm.conf.default php-fpm.conf

#Adjust the NONE to the local directory
change_line "include=NONE/etc/php-fpm.d/*.conf" "include=/usr/local/etc/php-fpm.d/*.conf" php-fpm.conf

cd php-fpm.d

cp -fr www.conf.default www.conf

echo "PHP 7.1.7 Successfully Installed"

#Back to temp directory
cd /root/temp

#Begin installing MyBB
echo "Setting Up MyBB"
unzip mybb_1812.zip > /dev/null
cd Upload

#Remove index.html from /usr/local/nginx/html
rm -rf /usr/local/nginx/html/index.html

#Move Directory to /usr/local/nginx/html/
cp -rf ./* /usr/local/nginx/html/

cd /usr/local/nginx/html/inc/

mv config.default.php config.php

cd ..

chmod 666 ./inc/config.php ./inc/settings.php
chmod 666 ./inc/languages/english/*.php ./inc/languages/english/admin/*.php
chmod 777 ./cache/ ./cache/themes/ ./uploads/ ./uploads/avatars/ ./admin/backups/

echo "MyBB Installation Complete"

echo "Adjusting Firewall Permissions"
firewall-cmd --permanent --zone=public --add-service=http > /dev/null
firewall-cmd --reload > /dev/null

echo "Cleaning Up Install"

cd /root
rm -rf ./temp
