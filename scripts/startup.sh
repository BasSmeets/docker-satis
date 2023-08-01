#!/bin/bash
set -e

STEP="START"
echo "----------------------------------------------------------------"
echo "                STARTUP SCRIPT: START                           "
echo "----------------------------------------------------------------"
echo ""

function end_of_script() {
  result=$?

  if [ "0" != "${result}" ]; then
    echo ""
    echo "!!! ERROR !!!"
  fi
  echo ""
  echo "-----------------------------------------------------------"
  echo "     STARTUP SCRIPT: FINISHED AT STEP '${STEP}' WITH CODE: $result"
  echo "-----------------------------------------------------------"
  echo ""
  trap - INT TERM EXIT QUIT

  exit 0;
}
trap 'end_of_script' INT TERM EXIT QUIT

# Reset
Color_Off='\033[0m'       # Text Reset

# Regular Colors
Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow

DEFAULT_CRONTAB_FREQUENCY="0 * * * *" # once an hour
DEFAULT_CRONTAB_FREQUENCY_ESCAPED=$(printf '%s\n' "${DEFAULT_CRONTAB_FREQUENCY}" | sed 's/[[\.*^$/]/\\&/g')

[[ -z "${CRONTAB_FREQUENCY}" ]] && CRONTAB_FREQUENCY="$DEFAULT_CRONTAB_FREQUENCY"
CRONTAB_FREQUENCY_ESCAPED=$(printf '%s\n' "${CRONTAB_FREQUENCY}" | sed 's/[[\.*^$/]/\\&/g')

STEP="CRONTAB"
if [[ ${CRONTAB_FREQUENCY} == -1 ]]; then
  echo " >>> No Cron, removing crontab file"
  test -e /etc/cron.d/satis-cron && rm -rf /etc/cron.d/satis-cron && ls -alh /etc/cron.d
else
  echo " >>> Crontab frequency set to: ${CRONTAB_FREQUENCY}"
  sed -i "s/${DEFAULT_CRONTAB_FREQUENCY_ESCAPED}/${CRONTAB_FREQUENCY_ESCAPED}/g" /etc/cron.d/satis-cron
  echo " >>> Replacing ${DEFAULT_CRONTAB_FREQUENCY_ESCAPED} BY ${CRONTAB_FREQUENCY_ESCAPED}"
  cat /etc/cron.d/satis-cron | grep "${CRONTAB_FREQUENCY_ESCAPED}" && echo "CRONTAB REPLACE OK"
fi

STEP="SSH"
touch ${USER_HOME}/.ssh/known_hosts

if [[ -f /var/tmp/sshconf ]]; then
    echo " >>> Copying host ssh config from /var/tmp/sshconf to ${USER_HOME}/.ssh/config"
    cp /var/tmp/sshconf "${USER_HOME}/.ssh/config"
fi

echo " >>> Creating the correct known_hosts file"
for _DOMAIN in ${PRIVATE_REPO_DOMAIN_LIST} ; do
    IFS=':' read -a arr <<< "${_DOMAIN}"
    if [[ "${#arr[@]}" == "2" ]]; then
        port="${arr[1]}"
        ssh-keyscan -t rsa,dsa, -p "${port}" ${arr[0]} >> ${USER_HOME}/.ssh/known_hosts
    else
        ssh-keyscan -t rsa,dsa ${_DOMAIN} >> ${USER_HOME}/.ssh/known_hosts
    fi
done

echo " >>> Copy ssh key to directory and assign permissions"
cp /tmp/id_rsa "${USER_HOME}/.ssh/id_rsa" && chmod 600 "${USER_HOME}/.ssh/id_rsa"

STEP="FIRST BUILD"
if [[ ! -f /satisfy/public/packages.json ]]; then
  /satisfy/bin/satis build --working-dir=/satisfy/ --skip-errors --no-ansi -vv
fi



STEP="END"

exit 0