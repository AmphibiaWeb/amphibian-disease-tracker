#!/bin/sh
chown www-data:www-data .
chown -R www-data:www-data *
find . -type f | xargs chmod 664
find ./bin -type f | xargs chmod 775
find . -type d | xargs chmod 775
find . -type d | xargs chmod +s
umask 0002
