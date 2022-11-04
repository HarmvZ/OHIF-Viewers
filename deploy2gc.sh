#!/bin/bash

SCRIPT_DIR=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)
DIST_DIR=${SCRIPT_DIR}/platform/viewer/dist
GC_SCRIPT_DIR=${SCRIPT_DIR}/../rse-grand-challenge-private/app/grandchallenge/core/static/js/ohif
GC_TEMPLATE_FILE=${SCRIPT_DIR}/../rse-grand-challenge-private/app/grandchallenge/curie/templates/curie/ohif.html
ENV_FILE=${SCRIPT_DIR}/platform/viewer/.env
CONFIG_FILE=${SCRIPT_DIR}/platform/viewer/public/config/grandchallenge.js

# Edit config and env files to contain correct production paths
sed -i 's#PUBLIC_URL=/[^\n]*#PUBLIC_URL=/thispathwillbereplaced/#gi' "$ENV_FILE"
sed -i "s#routerBasename: [^,]*#routerBasename: '/curie/ohif/'#gi" "$CONFIG_FILE"
sed -i "s#window.DICOMWEB_BASE_URL = [^\n]*#window.DICOMWEB_BASE_URL = '/';#gi" "$CONFIG_FILE"

(cd $SCRIPT_DIR; yarn run build) # Build deployment files
rm -rf $GC_SCRIPT_DIR # Clean script dir
cp -a $DIST_DIR $GC_SCRIPT_DIR # Copy dist files

# Reset config and env files
sed -i 's#PUBLIC_URL=/[^\n]*#PUBLIC_URL=/#gi' "$ENV_FILE"
sed -i "s#routerBasename: [^,]*#routerBasename: '/'#gi" "$CONFIG_FILE"
sed -i "s#window.DICOMWEB_BASE_URL = [^\n]*#window.DICOMWEB_BASE_URL = 'https://gc.localhost/';#gi" "$CONFIG_FILE"

# Create html template file with django templated static urls
echo "{% load static %}" > $GC_TEMPLATE_FILE
sed -r 's/(["'\''])\/thispathwillbereplaced\/([^"'\'']*)\1/\1{% static "js\/ohif\/\2" %}\1/gi' ${DIST_DIR}/index.html >> $GC_TEMPLATE_FILE

# Replace public path with static url in other dist js files
# for file in ${GC_SCRIPT_DIR}/sw.js; do
  # sed -i "s#'/thispathwillbereplaced/#window.PUBLIC_URL + '#gi" "$file"
# done
for file in ${GC_SCRIPT_DIR}/*.js; do
  sed -i 's#thispathwillbereplaced#static/js/ohif#gi' "$file"
done
for file in ${GC_SCRIPT_DIR}/*.json; do
  sed -i 's#/assets/#/static/js/ohif/assets/#gi' "$file"
done
