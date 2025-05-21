#!/bin/sh
# Substitui $PORT no nginx.conf.template e inicia o nginx

envsubst '$PORT' < /etc/nginx/conf.d/default.conf.template > /etc/nginx/conf.d/default.conf
nginx -g 'daemon off;'