#! /usr/bin/env bash
#
#  Get the reports from the app_usage app and send them through email.
#
set -eu
source pcf-platform/azure/scripts/set-env.sh

cf login --skip-ssl-validation -u $USER -p $PASSWORD -a https://api.sys.${CF_BASE_DOMAIN} -o $ORG -s $SPACE

echo -e "\nGetting app usage information...\n"
curl "https://app-usage.sys.${CF_BASE_DOMAIN}/system_report/app_usages" -k --silent -H "authorization: `cf oauth-token`" > out/app_usages.json

echo -e "\nGetting service usage information...\n"
curl "https://app-usage.sys.${CF_BASE_DOMAIN}/system_report/service_usages" -k --silent -H "authorization: `cf oauth-token`" > out/service_usages.json

echo -e "\n\nLong term overview app usage:\n"
cat out/app_usages.json | jq -r '.monthly_reports[] | (.year|tostring) + "-" + (.month|tostring) + " : " + (.average_app_instances|tostring)' | cut -d. -f1

echo -e "\napp_usages:\n"
cat out/app_usages.json | jq .

echo -e "\nservice_usages:\n"
cat out/service_usages.json | jq .

# combine the two in an array:
cat out/app_usages.json out/service_usages.json | jq -s . > out/app_service_usages.json

echo "Someorg PCF combined app_usages and service_usages report for env ${PCFENV}" > out/app_service_usages-subject.txt

echo -e "MIME-version: 1.0\nContent-Type: application/json; charset=\"UTF-8\"" > out/headers
